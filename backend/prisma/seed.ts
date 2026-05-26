import { PrismaClient, Role, UserState, MembershipState } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Iniciando el sembrado de datos (Seed)...');

  // Limpiar base de datos
  await prisma.auditLog.deleteMany();
  await prisma.observation.deleteMany();
  await prisma.seriesLog.deleteMany();
  await prisma.workoutSession.deleteMany();
  await prisma.routineAssignment.deleteMany();
  await prisma.routineExercise.deleteMany();
  await prisma.routineTemplate.deleteMany();
  await prisma.exercise.deleteMany();

  // Eliminar puntos y canjes
  await prisma.pointsMovement.deleteMany();
  await prisma.pointsExchange.deleteMany();
  await prisma.pointsMembership.deleteMany();
  await prisma.pointsProduct.deleteMany();
  await prisma.pointsBalance.deleteMany();
  await prisma.pointsConfig.deleteMany();

  // Eliminar ventas de productos e inventario
  await prisma.inventoryMovement.deleteMany();
  await prisma.productSaleDetail.deleteMany();
  await prisma.productPaymentMethodDetail.deleteMany();
  await prisma.productSale.deleteMany();
  await prisma.product.deleteMany();
  await prisma.productCategory.deleteMany();

  // Eliminar huellas
  await prisma.fingerprintAttendance.deleteMany();
  await prisma.fingerprint.deleteMany();

  // Eliminar pagos y cajas
  await prisma.payment.deleteMany();
  await prisma.movimientoCaja.deleteMany();
  await prisma.caja.deleteMany();

  await prisma.attendance.deleteMany();
  await prisma.membership.deleteMany();
  await prisma.memberProfile.deleteMany();
  await prisma.trainerProfile.deleteMany();
  await prisma.user.deleteMany();
  await prisma.tenant.deleteMany();

  console.log('Base de datos limpia.');

  // 1. Crear Tenants
  const tenantActivoId = '77777777-7777-7777-7777-777777777777';
  const tenantActivo = await prisma.tenant.create({
    data: {
      id: tenantActivoId,
      nombre: 'Gym Smart Surco',
      plan_saas: 'PRO',
      activo: true,
      direccion: 'Av. El Polo 123, Surco, Lima',
      telefono: '999999999',
      horario: 'Lunes a Viernes 6am - 10pm, Sábados 8am - 2pm',
      descripcion: 'Sede principal con equipamiento premium y CrossFit zone.',
    },
  });

  const tenantSuspendidoId = '88888888-8888-8888-8888-888888888888';
  await prisma.tenant.create({
    data: {
      id: tenantSuspendidoId,
      nombre: 'Gym Test Suspendido',
      plan_saas: 'BASIC',
      activo: false,
      direccion: 'Av. Larco 456, Miraflores',
      telefono: '988888888',
      horario: 'Lunes a Sábado 6am - 9pm',
      descripcion: 'Sede de pruebas suspendida por falta de pago.',
    },
  });

  console.log('Tenants creados.');

  // Hashear contraseñas genéricas
  const salt = await bcrypt.genSalt(10);
  const hashSuperAdmin = await bcrypt.hash('super_secure_pass', salt);
  const hashAdmin = await bcrypt.hash('admin_secure_pass', salt);
  const hashCaja = await bcrypt.hash('caja_secure_pass', salt);
  const hashTrainer = await bcrypt.hash('trainer_secure_pass', salt);
  const hashMember = await bcrypt.hash('member_secure_pass', salt);

  // 2. Crear Usuarios en el Tenant Activo

  // Super Admin
  const superAdmin = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'superadmin@gymsmart.com',
      password_hash: hashSuperAdmin,
      rol: Role.SUPER_ADMIN,
      nombre_completo: 'Super Administrador',
      dni: '00000000',
      estado: UserState.ACTIVE,
    },
  });

  // Admin
  const admin = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'admin@gymsmart.com',
      password_hash: hashAdmin,
      rol: Role.ADMIN,
      nombre_completo: 'Mateo Salas',
      dni: '12345678',
      estado: UserState.ACTIVE,
    },
  });

  // Caja
  const caja = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'caja@gymsmart.com',
      password_hash: hashCaja,
      rol: Role.CAJA,
      nombre_completo: 'Cajero Juan',
      dni: '87654321',
      estado: UserState.ACTIVE,
    },
  });

  // Entrenador
  const trainer = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'entrenador@gymsmart.com',
      password_hash: hashTrainer,
      rol: Role.TRAINER,
      nombre_completo: 'Carlos Mendoza',
      dni: '55555555',
      estado: UserState.ACTIVE,
    },
  });

  // Crear Trainer Profile
  const trainerProfile = await prisma.trainerProfile.create({
    data: {
      user_id: trainer.id,
      especialidad: 'CrossFit y Halterofilia',
      anos_experiencia: 5,
      certificaciones: 'CrossFit L2, USAW Level 1',
      biografia: 'Entrenador dedicado a mejorar la fuerza y acondicionamiento general.',
    },
  });

  // Miembro
  const member = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'miembro@gymsmart.com',
      password_hash: hashMember,
      rol: Role.MEMBER,
      nombre_completo: 'Mateo Salas Socio',
      dni: '11111111',
      estado: UserState.ACTIVE,
      qr_secret: '11111111_secure_totp_secret_key_2026',
    },
  });

  // Crear Member Profile asignando al entrenador Carlos Mendoza
  await prisma.memberProfile.create({
    data: {
      user_id: member.id,
      trainer_id: trainerProfile.id,
      nickname: 'MateoS',
      modo_activo: true,
      peso_kg: 78.5,
      altura_cm: 175.0,
      objetivo: 'Ganar masa muscular e incrementar RM de Back Squat',
      lesiones: 'Molestia leve en rodilla izquierda (sin restricción médica)',
      medidas_json: { cintura: 82, cadera: 96, pecho: 102 },
    },
  });

  const today = new Date();
  const nextMonth = new Date();
  nextMonth.setMonth(today.getMonth() + 1);

  await prisma.membership.create({
    data: {
      tenant_id: tenantActivoId,
      user_id: member.id,
      plan_nombre: 'Mensual Plata',
      duracion_dias: 30,
      monto: 120.0,
      estado: MembershipState.ACTIVE,
      fecha_inicio: today,
      fecha_vencimiento: nextMonth,
    },
  });

  // ─── SOCIOS ADICIONALES PARA ALINEAR CON EL FRONTEND ───────────────
  
  // Lucía Fernández
  const luciaUser = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'lucia@gymsmart.com',
      password_hash: hashMember,
      rol: Role.MEMBER,
      nombre_completo: 'Lucía Fernández',
      dni: '22222222',
      estado: UserState.ACTIVE,
      qr_secret: '22222222_secure_totp_secret_key_2026',
    },
  });
  await prisma.memberProfile.create({
    data: {
      user_id: luciaUser.id,
      trainer_id: trainerProfile.id,
      nickname: 'LuciaF',
      modo_activo: true,
      peso_kg: 62.1,
      altura_cm: 164.0,
      objetivo: 'Pérdida grasa',
    },
  });
  await prisma.membership.create({
    data: {
      tenant_id: tenantActivoId,
      user_id: luciaUser.id,
      plan_nombre: 'Trimestral Platinium',
      duracion_dias: 90,
      monto: 400.0,
      estado: MembershipState.ACTIVE,
      fecha_inicio: today,
      fecha_vencimiento: nextMonth,
    },
  });

  // Diego Castro (Membresía Expirada)
  const diegoUser = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'diego@gymsmart.com',
      password_hash: hashMember,
      rol: Role.MEMBER,
      nombre_completo: 'Diego Castro',
      dni: '11223344',
      estado: UserState.ACTIVE,
      qr_secret: '11223344_secure_totp_secret_key_2026',
    },
  });
  await prisma.memberProfile.create({
    data: {
      user_id: diegoUser.id,
      trainer_id: trainerProfile.id,
      nickname: 'DiegoC',
      modo_activo: true,
      peso_kg: 89.2,
      altura_cm: 182.0,
      objetivo: 'Fuerza máx.',
    },
  });
  const pastStartDate = new Date();
  pastStartDate.setDate(today.getDate() - 35);
  const pastEndDate = new Date();
  pastEndDate.setDate(today.getDate() - 5);
  await prisma.membership.create({
    data: {
      tenant_id: tenantActivoId,
      user_id: diegoUser.id,
      plan_nombre: 'Mensual Plata',
      duracion_dias: 30,
      monto: 120.0,
      estado: MembershipState.EXPIRED,
      fecha_inicio: pastStartDate,
      fecha_vencimiento: pastEndDate,
    },
  });

  // Rosa Mendieta (Activa)
  const rosaUser = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'rosa@gymsmart.com',
      password_hash: hashMember,
      rol: Role.MEMBER,
      nombre_completo: 'Rosa Mendieta',
      dni: '44332211',
      estado: UserState.ACTIVE,
      qr_secret: '44332211_secure_totp_secret_key_2026',
    },
  });
  await prisma.memberProfile.create({
    data: {
      user_id: rosaUser.id,
      trainer_id: trainerProfile.id,
      nickname: 'RosaM',
      modo_activo: true,
      peso_kg: 55.4,
      altura_cm: 158.0,
      objetivo: 'Tonificación',
    },
  });
  await prisma.membership.create({
    data: {
      tenant_id: tenantActivoId,
      user_id: rosaUser.id,
      plan_nombre: 'Mensual Plata',
      duracion_dias: 30,
      monto: 120.0,
      estado: MembershipState.ACTIVE,
      fecha_inicio: today,
      fecha_vencimiento: nextMonth,
    },
  });

  // Ana Torres (En día de gracia)
  const anaUser = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'ana@gymsmart.com',
      password_hash: hashMember,
      rol: Role.MEMBER,
      nombre_completo: 'Ana Torres',
      dni: '55667788',
      estado: UserState.ACTIVE,
      qr_secret: '55667788_secure_totp_secret_key_2026',
    },
  });
  await prisma.memberProfile.create({
    data: {
      user_id: anaUser.id,
      trainer_id: trainerProfile.id,
      nickname: 'AnaT',
      modo_activo: true,
      peso_kg: 58.0,
      altura_cm: 160.0,
      objetivo: 'Mensual',
    },
  });
  const graceStartDate = new Date();
  graceStartDate.setDate(today.getDate() - 31);
  const graceEndDate = new Date();
  graceEndDate.setDate(today.getDate() - 1);
  await prisma.membership.create({
    data: {
      tenant_id: tenantActivoId,
      user_id: anaUser.id,
      plan_nombre: 'Mensual Oro',
      duracion_dias: 30,
      monto: 150.0,
      estado: MembershipState.GRACE,
      fecha_inicio: graceStartDate,
      fecha_vencimiento: graceEndDate,
    },
  });

  // Pedro Quispe (Inactivo - Baja lógica)
  const pedroUser = await prisma.user.create({
    data: {
      tenant_id: tenantActivoId,
      email: 'pedro@gymsmart.com',
      password_hash: hashMember,
      rol: Role.MEMBER,
      nombre_completo: 'Pedro Quispe',
      dni: '99887766',
      estado: UserState.INACTIVE,
      qr_secret: '99887766_secure_totp_secret_key_2026',
    },
  });
  await prisma.memberProfile.create({
    data: {
      user_id: pedroUser.id,
      trainer_id: trainerProfile.id,
      nickname: 'PedroQ',
      modo_activo: false,
      peso_kg: 73.0,
      altura_cm: 170.0,
      objetivo: 'Rehabilitación',
    },
  });
  await prisma.membership.create({
    data: {
      tenant_id: tenantActivoId,
      user_id: pedroUser.id,
      plan_nombre: 'Mensual Plata',
      duracion_dias: 30,
      monto: 120.0,
      estado: MembershipState.EXPIRED,
      fecha_inicio: pastStartDate,
      fecha_vencimiento: pastEndDate,
    },
  });


  // 3. Crear Ejercicios de Prueba
  const exercise1 = await prisma.exercise.create({
    data: {
      tenant_id: tenantActivoId,
      trainer_id: trainerProfile.id,
      nombre: 'Press de banca',
      descripcion: 'Acostado en banco plano, empujar la barra verticalmente hacia arriba.',
      grupo_muscular: 'Pecho',
    },
  });

  const exercise2 = await prisma.exercise.create({
    data: {
      tenant_id: tenantActivoId,
      trainer_id: trainerProfile.id,
      nombre: 'Sentadilla con barra',
      descripcion: 'Barra sobre trapecios, descender flexionando rodillas hasta 90 grados.',
      grupo_muscular: 'Piernas',
    },
  });

  // 4. Crear Plantilla de Rutina
  const template = await prisma.routineTemplate.create({
    data: {
      tenant_id: tenantActivoId,
      trainer_id: trainerProfile.id,
      nombre: 'Rutina A: Fuerza General',
      descripcion: 'Enfoque en ganancia de fuerza e hipertrofia básica.',
    },
  });

  // Asociar ejercicios a la plantilla
  await prisma.routineExercise.create({
    data: {
      template_id: template.id,
      exercise_id: exercise1.id,
      orden: 1,
      series: 4,
      repeticiones: 8,
      peso_sugerido_kg: 60.0,
      descanso_seg: 90,
    },
  });

  await prisma.routineExercise.create({
    data: {
      template_id: template.id,
      exercise_id: exercise2.id,
      orden: 2,
      series: 4,
      repeticiones: 6,
      peso_sugerido_kg: 80.0,
      descanso_seg: 120,
    },
  });

  // 5. Crear Asignación de Rutina para el Socio Mateo
  const memberProfileObj = await prisma.memberProfile.findUnique({
    where: { user_id: member.id },
  });

  if (memberProfileObj) {
    await prisma.routineAssignment.create({
      data: {
        tenant_id: tenantActivoId,
        member_id: memberProfileObj.id,
        trainer_id: trainerProfile.id,
        template_id: template.id,
        agenda_semanal: {
          LUN: template.nombre,
          MAR: 'Descanso',
          MIÉ: template.nombre,
          JUE: 'Descanso',
          VIE: template.nombre,
          SÁB: 'Descanso',
          DOM: 'Descanso',
        },
        publicada: true,
      },
    });
  }

  // 6. Crear Caja de prueba para el Cajero Juan
  const cajaActiva = await prisma.caja.create({
    data: {
      tenant_id: tenantActivoId,
      cajero_id: caja.id,
      monto_apertura: 200.0,
      total_ingresos: 200.0,
      estado: 'abierta',
      fecha_apertura: new Date(),
    },
  });

  await prisma.movimientoCaja.create({
    data: {
      caja_id: cajaActiva.id,
      tipo: 'ingreso',
      monto: 200.0,
      descripcion: 'Apertura de caja - Saldo inicial',
    },
  });

  // 7. Crear Configuración y Catálogo de Productos
  const catBebidas = await prisma.productCategory.create({
    data: {
      tenant_id: tenantActivoId,
      nombre: 'Bebidas',
      descripcion: 'Bebidas rehidratantes y agua',
      color: '#007bff',
    },
  });

  const catSuplementos = await prisma.productCategory.create({
    data: {
      tenant_id: tenantActivoId,
      nombre: 'Suplementos',
      descripcion: 'Proteínas, creatinas y pre-entrenos',
      color: '#28a745',
    },
  });

  const catAccesorios = await prisma.productCategory.create({
    data: {
      tenant_id: tenantActivoId,
      nombre: 'Accesorios',
      descripcion: 'Shakers, toallas y straps',
      color: '#ffc107',
    },
  });

  const prodAgua = await prisma.product.create({
    data: {
      tenant_id: tenantActivoId,
      nombre: 'Agua Mineral 625ml',
      descripcion: 'Agua sin gas baja en sodio',
      categoria_id: catBebidas.id,
      sku: 'BEB-AGUA-01',
      precio_compra: 1.0,
      precio_venta: 2.50,
      stock_actual: 50,
      stock_minimo: 5,
    },
  });

  const prodWhey = await prisma.product.create({
    data: {
      tenant_id: tenantActivoId,
      nombre: 'Proteína Whey Premium 1kg',
      descripcion: 'Proteína aislada de suero de leche sabor chocolate',
      categoria_id: catSuplementos.id,
      sku: 'SUP-WHEY-01',
      precio_compra: 85.0,
      precio_venta: 130.00,
      stock_actual: 15,
      stock_minimo: 3,
    },
  });

  // Registrar movimientos iniciales de inventario
  await prisma.inventoryMovement.create({
    data: {
      producto_id: prodAgua.id,
      tipo: 'entrada',
      cantidad: 50,
      stock_anterior: 0,
      stock_actual: 50,
      usuario_id: admin.id,
      motivo: 'Inventario inicial de apertura',
    },
  });

  await prisma.inventoryMovement.create({
    data: {
      producto_id: prodWhey.id,
      tipo: 'entrada',
      cantidad: 15,
      stock_anterior: 0,
      stock_actual: 15,
      usuario_id: admin.id,
      motivo: 'Inventario inicial de apertura',
    },
  });

  // 8. Configuración del Sistema de Puntos y Fidelización
  await prisma.pointsConfig.create({
    data: {
      puntos_por_sol: 1.0,
      minimo_para_canje: 100,
      puntos_expiran: false,
    },
  });

  await prisma.pointsBalance.create({
    data: {
      usuario_id: member.id,
      puntos_disponibles: 150,
      puntos_totales_ganados: 150,
      puntos_totales_canjeados: 0,
    },
  });

  await prisma.pointsMovement.create({
    data: {
      usuario_id: member.id,
      tipo: 'ingreso',
      cantidad: 150,
      saldo_anterior: 0,
      saldo_nuevo: 150,
      descripcion: 'Puntos de bienvenida y membresía inicial',
    },
  });

  await prisma.pointsProduct.create({
    data: {
      nombre: 'Toalla microfibra GymSmart',
      descripcion: 'Toalla absorbente ideal para secar sudor durante el entrenamiento',
      precio_puntos: 80,
      stock: 25,
    },
  });

  await prisma.pointsMembership.create({
    data: {
      nombre: 'Membresía 7 días Gratis',
      descripcion: 'Cupón para extender tu membresía actual 7 días sin costo',
      precio_puntos: 120,
      duracion_dias: 7,
      stock: 0, // ilimitado
    },
  });

  console.log('Caja, productos, inventario y sistema de puntos de prueba creados.');
  console.log('Usuarios, perfiles, membresías, ejercicios y rutinas de prueba creados.');
  console.log('Sembrado de datos finalizado con éxito.');
}

main()
  .catch((e) => {
    console.error('Error al correr el seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
