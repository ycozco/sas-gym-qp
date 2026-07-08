import {
  MembershipState,
  PaymentMethod,
  PaymentState,
  PrismaClient,
  ProductSaleEstado,
  Role,
  ThemePreference,
  UserState,
  AccessMethod,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

type PlanDef = {
  name: string;
  days: number;
  price: number;
};

type MemberStatus = 'ACTIVE' | 'GRACE' | 'EXPIRED' | 'PENDING' | 'SUSPENDED';

const gyms = [
  {
    code: 'surco',
    name: 'SaasGym Cayma Prime',
    address: 'Av. Ejercito 1009, Cayma, Arequipa',
    phone: '987654101',
    plan: 'PRO',
  },
  {
    code: 'miraflores',
    name: 'SaasGym Yanahuara Fit',
    address: 'Av. Ejercito 704, Yanahuara, Arequipa',
    phone: '987654102',
    plan: 'PRO',
  },
  {
    code: 'sanborja',
    name: 'SaasGym Cercado Performance',
    address: 'Calle San Francisco 315, Cercado, Arequipa',
    phone: '987654103',
    plan: 'ENTERPRISE',
  },
  {
    code: 'lince',
    name: 'SaasGym Cerro Colorado 24/7',
    address: 'Av. Aviacion 602, Cerro Colorado, Arequipa',
    phone: '987654104',
    plan: 'BASIC',
  },
  {
    code: 'callao',
    name: 'SaasGym Bustamante Strong',
    address: 'Av. Dolores 121, Jose Luis Bustamante y Rivero, Arequipa',
    phone: '987654105',
    plan: 'PRO',
  },
];

const plans: PlanDef[] = [
  { name: 'Plan Mensual Plata', days: 30, price: 120 },
  { name: 'Plan Mensual Oro', days: 30, price: 150 },
  { name: 'Plan Trimestral Platinium', days: 90, price: 400 },
  { name: 'Plan Semestral Elite', days: 180, price: 720 },
  { name: 'Pase por un Dia', days: 1, price: 25 },
];

const firstNames = [
  'Lucia',
  'Diego',
  'Rosa',
  'Ana',
  'Pedro',
  'Valeria',
  'Jorge',
  'Camila',
  'Renato',
  'Mariana',
  'Luis',
  'Sandra',
  'Mateo',
  'Fiorella',
  'Carlos',
  'Andrea',
  'Miguel',
  'Paola',
  'Alonso',
  'Gabriela',
];

const lastNames = [
  'Quispe',
  'Fernandez',
  'Castro',
  'Torres',
  'Mendieta',
  'Salas',
  'Paredes',
  'Rojas',
  'Vargas',
  'Chavez',
  'Lopez',
  'Reyes',
  'Mendoza',
  'Benavides',
  'Huaman',
  'Cordova',
  'Soto',
  'Aguilar',
  'Nunez',
  'Campos',
];

const goals = [
  'Hipertrofia',
  'Perdida de grasa',
  'Fuerza maxima',
  'Recomposicion corporal',
  'Resistencia funcional',
  'Rehabilitacion',
  'Tonificacion',
  'Acondicionamiento general',
];

function addDays(base: Date, days: number): Date {
  const date = new Date(base);
  date.setDate(date.getDate() + days);
  return date;
}

function dni(tenantIndex: number, sequence: number): string {
  return `${tenantIndex + 1}${sequence.toString().padStart(7, '0')}`;
}

async function resetDatabase() {
  await prisma.pointsMovement.deleteMany();
  await prisma.pointsExchange.deleteMany();
  await prisma.pointsMembership.deleteMany();
  await prisma.pointsProduct.deleteMany();
  await prisma.pointsBalance.deleteMany();
  await prisma.pointsConfig.deleteMany();

  await prisma.inventoryMovement.deleteMany();
  await prisma.productSaleDetail.deleteMany();
  await prisma.productPaymentMethodDetail.deleteMany();
  await prisma.productSale.deleteMany();
  await prisma.product.deleteMany();
  await prisma.productCategory.deleteMany();

  await prisma.fingerprintAttendance.deleteMany();
  await prisma.fingerprint.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.movimientoCaja.deleteMany();
  await prisma.caja.deleteMany();
  await prisma.attendance.deleteMany();

  await prisma.booking.deleteMany();
  await prisma.schedule.deleteMany();
  await prisma.seriesLog.deleteMany();
  await prisma.workoutSession.deleteMany();
  await prisma.routineAssignment.deleteMany();
  await prisma.routineExercise.deleteMany();
  await prisma.routineTemplate.deleteMany();
  await prisma.exercise.deleteMany();

  await prisma.announcement.deleteMany();
  await prisma.auditLog.deleteMany();
  await prisma.observation.deleteMany();
  await prisma.membership.deleteMany();
  await prisma.membershipPlan.deleteMany();
  await prisma.memberProfile.deleteMany();
  await prisma.trainerProfile.deleteMany();
  await prisma.refreshTokenSession.deleteMany();
  await prisma.user.deleteMany();
  await prisma.tenant.deleteMany();
  await prisma.saasPlan.deleteMany();
}

function membershipDates(status: MemberStatus, plan: PlanDef, now: Date) {
  if (status === 'ACTIVE') {
    const start = addDays(now, -Math.min(20, plan.days - 1));
    return {
      start,
      end: addDays(start, plan.days),
      state: MembershipState.ACTIVE,
    };
  }
  if (status === 'GRACE') {
    const start = addDays(now, -plan.days - 1);
    return { start, end: addDays(now, -1), state: MembershipState.GRACE };
  }
  if (status === 'EXPIRED') {
    const start = addDays(now, -plan.days - 18);
    return { start, end: addDays(now, -18), state: MembershipState.EXPIRED };
  }
  if (status === 'PENDING') {
    return { start: null, end: null, state: MembershipState.PENDING };
  }
  const start = addDays(now, -12);
  return {
    start,
    end: addDays(start, plan.days),
    state: MembershipState.SUSPENDED,
  };
}

async function main() {
  const isProduction = process.env.NODE_ENV === 'production';
  const existingTenants = await prisma.tenant.count();
  const existingUsers = await prisma.user.count();

  if (isProduction) {
    if (existingTenants > 0 || existingUsers > 0) {
      console.log(
        `Seed de producción omitido para evitar duplicados. Tenants existentes: ${existingTenants}, usuarios existentes: ${existingUsers}.`,
      );
      return;
    }
    console.log(
      'Ejecutando seed productivo inicial con dataset operativo de SaasGym...',
    );
  }

  if (!isProduction) {
    console.log('Iniciando el sembrado de datos (Seed Realista)...');
    await resetDatabase();
  }

  const passwordHash = {
    admin: await bcrypt.hash('admin_secure_pass', 10),
    trainer: await bcrypt.hash('trainer_secure_pass', 10),
    cashier: await bcrypt.hash('caja_secure_pass', 10),
    member: await bcrypt.hash('member_secure_pass', 10),
    super: await bcrypt.hash('super_secure_pass', 10),
  };

  const now = new Date();
  let totalUsers = 0;
  let totalMemberships = 0;
  let totalCajas = 0;

  // Sembrar los planes SaaS para evitar conflictos de llave foránea
  console.log('Sembrando planes SaaS...');
  await prisma.saasPlan.upsert({
    where: { code: 'BASIC' },
    update: {},
    create: {
      code: 'BASIC',
      nombre: 'Plan Básico',
      precio_mensual: 29.0,
      limite_usuarios: 500,
      caracteristicas: 'Acceso QR, control de caja simple, reporte básico',
    },
  });

  await prisma.saasPlan.upsert({
    where: { code: 'PRO' },
    update: {},
    create: {
      code: 'PRO',
      nombre: 'Plan Profesional',
      precio_mensual: 59.0,
      limite_usuarios: 1500,
      caracteristicas: 'Acceso biométrico, caja móvil, soporte premium, reporte avanzado',
    },
  });

  await prisma.saasPlan.upsert({
    where: { code: 'ENTERPRISE' },
    update: {},
    create: {
      code: 'ENTERPRISE',
      nombre: 'Plan Enterprise',
      precio_mensual: 119.0,
      limite_usuarios: 9999,
      caracteristicas: 'Soporte 24/7, multitenant central, integraciones custom, reportes analytics',
    },
  });

  const superTenant = await prisma.tenant.create({
    data: {
      nombre: 'SaasGym Network',
      plan_saas: 'ENTERPRISE',
      activo: true,
      direccion: 'Av. Ejercito 1030, Cayma, Arequipa',
      telefono: '999000000',
      horario: 'Administracion central',
      descripcion:
        'Tenant central para superadmin y operacion de la red SaasGym.',
    },
  });

  await prisma.user.create({
    data: {
      tenant_id: superTenant.id,
      email: 'superadmin@test.sasgym.com',
      password_hash: passwordHash.super,
      rol: Role.SUPER_ADMIN,
      nombre_completo: 'Super Admin Demo',
      dni: '90000000',
      estado: UserState.ACTIVE,
    },
  });
  totalUsers += 1;

  for (let tenantIndex = 0; tenantIndex < gyms.length; tenantIndex++) {
    const gym = gyms[tenantIndex];
    const tenant = await prisma.tenant.create({
      data: {
        nombre: gym.name,
        logo_url: null,
        direccion: gym.address,
        telefono: gym.phone,
        horario: 'Lun-Vie 06:00-22:00, Sab 08:00-18:00, Dom 09:00-13:00',
        descripcion: `Sede demo ${gym.name} con sala de maquinas, zona funcional y caja activa.`,
        redes_sociales: {
          instagram: `@${gym.code}_sasgym`,
          whatsapp: gym.phone,
        },
        plan_saas: gym.plan,
        activo: true,
      },
    });

    const admins = [];
    for (let i = 1; i <= 2; i++) {
      admins.push(
        await prisma.user.create({
          data: {
            tenant_id: tenant.id,
            email: `admin${i}.${gym.code}@test.sasgym.com`,
            password_hash: passwordHash.admin,
            rol: Role.ADMIN,
            nombre_completo: `Admin ${i} ${gym.name.replace('SaasGym ', '')}`,
            dni: dni(tenantIndex, 100 + i),
            celular: `9${tenantIndex + 1}00${i}1111`,
            estado: UserState.ACTIVE,
            theme_preference:
              i === 1 ? ThemePreference.SYSTEM : ThemePreference.DARK,
          },
        }),
      );
      totalUsers++;
    }

    const tenantPlans = [];
    for (let i = 0; i < plans.length; i++) {
      const plan = plans[i];
      tenantPlans.push(
        await prisma.membershipPlan.create({
          data: {
            tenant_id: tenant.id,
            nombre: plan.name,
            descripcion:
              plan.days === 1
                ? 'Acceso por un dia para invitados o regularizacion rapida.'
                : `Membresia de ${plan.days} dias para entrenamiento integral.`,
            duracion_dias: plan.days,
            precio: plan.price,
            color: ['#2F6BFF', '#D2FF3A', '#7A5AE0', '#00B85C', '#FF7A1A'][i],
            orden: i + 1,
            activo: true,
            created_by_id: admins[0].id,
          },
        }),
      );
    }

    const trainers = [];
    for (let i = 1; i <= 5; i++) {
      const trainerUser = await prisma.user.create({
        data: {
          tenant_id: tenant.id,
          email: `trainer${i}.${gym.code}@test.sasgym.com`,
          password_hash: passwordHash.trainer,
          rol: Role.TRAINER,
          nombre_completo: `${firstNames[(i + tenantIndex) % firstNames.length]} Coach ${lastNames[(i + 3) % lastNames.length]}`,
          dni: dni(tenantIndex, 200 + i),
          celular: `9${tenantIndex + 2}10${i}2222`,
          estado: UserState.ACTIVE,
        },
      });
      const profile = await prisma.trainerProfile.create({
        data: {
          user_id: trainerUser.id,
          especialidad: [
            'Funcional',
            'Hipertrofia',
            'Fuerza',
            'Movilidad',
            'Cross training',
          ][i - 1],
          anos_experiencia: 3 + i,
          certificaciones: `Certificacion Nivel ${i}, Primeros Auxilios`,
          biografia:
            'Entrenador demo con seguimiento semanal y evaluaciones mensuales.',
        },
      });
      trainers.push(profile);
      totalUsers++;
    }

    const cashiers = [];
    for (let i = 1; i <= 3; i++) {
      const cashier = await prisma.user.create({
        data: {
          tenant_id: tenant.id,
          email: `caja${i}.${gym.code}@test.sasgym.com`,
          password_hash: passwordHash.cashier,
          rol: Role.CAJA,
          nombre_completo: `Caja ${i} ${lastNames[(tenantIndex + i) % lastNames.length]}`,
          dni: dni(tenantIndex, 300 + i),
          celular: `9${tenantIndex + 3}20${i}3333`,
          estado: UserState.ACTIVE,
        },
      });
      cashiers.push(cashier);
      totalUsers++;
    }

    const cajas = [];
    for (let i = 0; i < cashiers.length; i++) {
      const apertura = 150 + tenantIndex * 20 + i * 50;
      const caja = await prisma.caja.create({
        data: {
          tenant_id: tenant.id,
          cajero_id: cashiers[i].id,
          fecha_apertura: addDays(now, i === 0 ? 0 : -i),
          fecha_cierre: i === 0 ? null : addDays(now, -i),
          monto_apertura: apertura,
          monto_cierre_efectivo: i === 0 ? null : apertura + 360 + i * 40,
          monto_cierre_transferencia: i === 0 ? null : 220 + i * 30,
          monto_cierre_yape: i === 0 ? null : 180 + i * 35,
          monto_cierre_pos: i === 0 ? null : 260 + i * 45,
          total_ventas_efectivo: 0,
          total_ventas_transferencia: 0,
          total_ventas_yape: 0,
          total_ventas_pos: 0,
          total_ingresos: apertura,
          diferencia: i === 0 ? 0 : i === 1 ? 0 : -8,
          observaciones:
            i === 0
              ? 'Caja abierta de turno actual.'
              : 'Cierre cuadrado con arqueo de prueba.',
          estado: i === 0 ? 'abierta' : 'cerrada',
        },
      });
      await prisma.movimientoCaja.create({
        data: {
          caja_id: caja.id,
          tipo: 'ingreso',
          monto: apertura,
          descripcion: 'Apertura de caja - saldo inicial',
        },
      });
      cajas.push(caja);
      totalCajas++;
    }

    const catBebidas = await prisma.productCategory.create({
      data: {
        tenant_id: tenant.id,
        nombre: `Bebidas ${gym.code}`,
        descripcion: 'Agua, hidratantes y bebidas frias',
        color: '#0066FF',
      },
    });
    const catSuplementos = await prisma.productCategory.create({
      data: {
        tenant_id: tenant.id,
        nombre: `Suplementos ${gym.code}`,
        descripcion: 'Proteinas, creatina y snacks proteicos',
        color: '#00B85C',
      },
    });

    const products = [
      await prisma.product.create({
        data: {
          tenant_id: tenant.id,
          nombre: 'Agua mineral 625ml',
          descripcion: 'Agua sin gas',
          categoria_id: catBebidas.id,
          sku: `${gym.code.toUpperCase()}-BEB-AGUA-625`,
          precio_compra: 1.2,
          precio_venta: 3,
          stock_actual: 80 + tenantIndex * 10,
          stock_minimo: 12,
        },
      }),
      await prisma.product.create({
        data: {
          tenant_id: tenant.id,
          nombre: 'Whey protein porcion',
          descripcion: 'Porcion individual post entrenamiento',
          categoria_id: catSuplementos.id,
          sku: `${gym.code.toUpperCase()}-SUP-WHEY-PORC`,
          precio_compra: 7,
          precio_venta: 12,
          stock_actual: 45 + tenantIndex * 5,
          stock_minimo: 10,
        },
      }),
    ];

    for (const product of products) {
      await prisma.inventoryMovement.create({
        data: {
          producto_id: product.id,
          tipo: 'entrada',
          cantidad: product.stock_actual,
          stock_anterior: 0,
          stock_actual: product.stock_actual,
          usuario_id: admins[0].id,
          motivo: 'Carga inicial data-test',
        },
      });
    }

    const statusCycle: MemberStatus[] = [
      'ACTIVE',
      'ACTIVE',
      'ACTIVE',
      'ACTIVE',
      'ACTIVE',
      'ACTIVE',
      'ACTIVE',
      'ACTIVE',
      'ACTIVE',
      'GRACE',
      'GRACE',
      'EXPIRED',
      'EXPIRED',
      'EXPIRED',
      'PENDING',
      'PENDING',
      'SUSPENDED',
      'ACTIVE',
      'GRACE',
      'EXPIRED',
    ];

    // Configuración de Puntos
    await prisma.pointsConfig.create({
      data: {
        tenant_id: tenant.id,
        puntos_por_sol: 1.0,
        minimo_para_canje: 100,
        puntos_expiran: false,
      },
    });

    for (let i = 0; i < 20; i++) {
      const status = statusCycle[i];
      const plan = plans[(i + tenantIndex) % plans.length];
      const tenantPlan = tenantPlans[(i + tenantIndex) % tenantPlans.length];
      const first = firstNames[(i + tenantIndex * 2) % firstNames.length];
      const last = lastNames[(i + tenantIndex * 3) % lastNames.length];

      const memberUser = await prisma.user.create({
        data: {
          tenant_id: tenant.id,
          email: `socio${(i + 1).toString().padStart(2, '0')}.${gym.code}@test.sasgym.com`,
          password_hash: passwordHash.member,
          rol: Role.MEMBER,
          nombre_completo: `${first} ${last}`,
          dni: dni(tenantIndex, 400 + i + 1),
          celular: `9${tenantIndex + 4}${(4000000 + i * 137).toString().slice(0, 7)}`,
          estado:
            status === 'SUSPENDED' ? UserState.SUSPENDED : UserState.ACTIVE,
          qr_secret: `${gym.code}_${i + 1}_secure_totp_secret_key_2026`,
          theme_preference:
            i % 3 === 0
              ? ThemePreference.SYSTEM
              : i % 3 === 1
                ? ThemePreference.LIGHT
                : ThemePreference.DARK,
        },
      });
      totalUsers++;

      await prisma.memberProfile.create({
        data: {
          user_id: memberUser.id,
          trainer_id: trainers[i % trainers.length].id,
          nickname: `${first}${i + 1}`,
          modo_activo: status !== 'SUSPENDED',
          peso_kg: 54 + ((i * 3) % 42),
          altura_cm: 156 + ((i * 4) % 34),
          objetivo: goals[i % goals.length],
          lesiones: i % 7 === 0 ? 'Molestia lumbar leve reportada' : null,
          medidas_json: {
            cintura: 68 + (i % 12),
            pecho: 86 + (i % 18),
            cadera: 88 + (i % 16),
          },
        },
      });

      if (status !== 'SUSPENDED') {
        await prisma.dietPlan.create({
          data: {
            tenant_id: tenant.id,
            member_id: memberUser.id,
            trainer_id: trainers[i % trainers.length].user_id,
            peso_objetivo_kg: 58 + ((i * 2) % 32),
            calorias_objetivo: 1900 + (i % 6) * 120,
            proteinas_g: 110 + (i % 5) * 8,
            carbohidratos_g: 190 + (i % 6) * 18,
            grasas_g: 55 + (i % 4) * 6,
            comidas: [
              {
                hora: '07:30',
                nombre: 'Desayuno',
                alimentos: 'Avena, huevos y fruta de temporada',
                calorias: 520,
              },
              {
                hora: '12:45',
                nombre: 'Almuerzo',
                alimentos: 'Pollo, arroz integral y ensalada',
                calorias: 720,
              },
              {
                hora: '17:30',
                nombre: 'Pre entrenamiento',
                alimentos: 'Yogurt griego con granola',
                calorias: 330,
              },
              {
                hora: '21:00',
                nombre: 'Cena',
                alimentos: 'Pescado, camote y vegetales',
                calorias: 560,
              },
            ],
            sugerencias:
              'Plan base cargado desde la BD. Ajustar por progreso semanal y tolerancia alimentaria.',
            activo: true,
          },
        });
      }

      const dates = membershipDates(status, plan, now);
      const discount = i % 6 === 0 ? 10 : 0;
      const paid =
        status === 'PENDING'
          ? Math.round(plan.price * 0.5)
          : status === 'SUSPENDED'
            ? plan.price
            : Math.round(plan.price * (1 - discount / 100));
      const pending = Math.max(0, plan.price - paid);

      const membership = await prisma.membership.create({
        data: {
          tenant_id: tenant.id,
          user_id: memberUser.id,
          plan_id: tenantPlan.id,
          plan_nombre: plan.name,
          duracion_dias: plan.days,
          monto: plan.price,
          estado: dates.state,
          fecha_inicio: dates.start,
          fecha_vencimiento: dates.end,
          descuento_porcentaje: discount,
          descuento_monto: 0,
          precio_pagado: paid,
          monto_pendiente: pending,
          pago_completo: pending === 0,
          congelada: status === 'SUSPENDED',
        },
      });
      totalMemberships++;

      // Vincular caja activa
      const caja = cajas[i % cajas.length];
      const paymentState =
        status === 'PENDING' ? PaymentState.PENDING : PaymentState.APPROVED;

      const method = [
        PaymentMethod.CASH,
        PaymentMethod.MANUAL_YAPE,
        PaymentMethod.POS,
        PaymentMethod.TRANSFER,
      ][i % 4];

      await prisma.payment.create({
        data: {
          tenant_id: tenant.id,
          membership_id: membership.id,
          registrado_por_id: cashiers[i % cashiers.length].id,
          monto: paid,
          metodo: method,
          estado: paymentState,
          caja_id: caja.id,
          venta_token: `${gym.code}-${i + 1}-${membership.id}`,
          timestamp: addDays(now, -Math.min(25, i + tenantIndex)),
        },
      });

      await prisma.movimientoCaja.create({
        data: {
          caja_id: caja.id,
          tipo: 'ingreso',
          monto: paid,
          descripcion: `Venta membresia: ${plan.name} - ${first} ${last}`,
        },
      });

      const totals: Record<string, { increment: number }> = {};
      if (method === PaymentMethod.CASH)
        totals.total_ventas_efectivo = { increment: paid };
      if (method === PaymentMethod.MANUAL_YAPE)
        totals.total_ventas_yape = { increment: paid };
      if (method === PaymentMethod.POS)
        totals.total_ventas_pos = { increment: paid };
      if (method === PaymentMethod.TRANSFER)
        totals.total_ventas_transferencia = { increment: paid };

      await prisma.caja.update({
        where: { id: caja.id },
        data: {
          ...totals,
          total_ingresos: { increment: paid },
        },
      });

      // Crear saldo de puntos inicial
      await prisma.pointsBalance.create({
        data: {
          usuario_id: memberUser.id,
          puntos_disponibles: 100,
          puntos_totales_ganados: 100,
          puntos_totales_canjeados: 0,
        },
      });

      // --- SIMULACIÓN DE ASISTENCIAS ACTIVAS HOY (QR y Huella) ---
      // Registrar ingresos "hoy" para algunos de los socios activos
      if (status === 'ACTIVE' && i % 3 === 0) {
        // Asistencia QR
        await prisma.attendance.create({
          data: {
            tenant_id: tenant.id,
            user_id: memberUser.id,
            timestamp: now,
            metodo_acceso: AccessMethod.QR_ADMIN,
          },
        });

        // Asistencia biométrica (Huella)
        const activeHuella = await prisma.fingerprint.create({
          data: {
            usuario_id: memberUser.id,
            dedo: 'pulgar_der',
            datos_huella: 'U01HQVNFUl9GSU5HRVJQUklOVF9URU1QTEFURV9EQVRB',
            hash_verificacion: 'SHA256_HASH_VERIFY_SIMULATION',
            activa: true,
          },
        });

        await prisma.fingerprintAttendance.create({
          data: {
            usuario_id: memberUser.id,
            huella_id: activeHuella.id,
            fecha_entrada: now,
            ip_origen: '192.168.1.15',
            dispositivo_id: 'ZKTECO-SURCO-01',
          },
        });
      }

      // --- SIMULACIÓN DE MULTIPLES VENTAS DE PRODUCTOS DESDE CAJA ---
      // Crear algunas compras de bebidas o suplementos en caja
      if (i % 5 === 0) {
        const prod = products[i % products.length];
        const cant = (i % 3) + 1;
        const totalVenta = prod.precio_venta * cant;
        const refVenta = `SALE-${gym.code.toUpperCase()}-${i}-${now.getTime()}`;

        const productSale = await prisma.productSale.create({
          data: {
            tenant_id: tenant.id,
            referencia: refVenta,
            cajero_id: cashiers[i % cashiers.length].id,
            cliente_id: memberUser.id,
            caja_id: caja.id,
            subtotal: totalVenta,
            descuento: 0,
            total: totalVenta,
            estado: ProductSaleEstado.completada,
            fecha_venta: now,
          },
        });

        await prisma.productSaleDetail.create({
          data: {
            sale_id: productSale.id,
            producto_id: prod.id,
            cantidad: cant,
            precio_unitario: prod.precio_venta,
            subtotal: totalVenta,
          },
        });

        await prisma.productPaymentMethodDetail.create({
          data: {
            sale_id: productSale.id,
            metodo: 'efectivo',
            monto: totalVenta,
          },
        });

        // Registrar movimiento de stock
        await prisma.inventoryMovement.create({
          data: {
            producto_id: prod.id,
            tipo: 'salida',
            cantidad: cant,
            stock_anterior: prod.stock_actual,
            stock_actual: prod.stock_actual - cant,
            sale_id: productSale.id,
            usuario_id: cashiers[i % cashiers.length].id,
            motivo: 'Venta Caja Registradora',
          },
        });

        // Actualizar stock real
        await prisma.product.update({
          where: { id: prod.id },
          data: {
            stock_actual: { decrement: cant },
            veces_vendido: { increment: cant },
          },
        });

        // Registrar ingreso de efectivo en la caja
        await prisma.movimientoCaja.create({
          data: {
            caja_id: caja.id,
            tipo: 'ingreso',
            monto: totalVenta,
            descripcion: `Venta Producto: ${prod.nombre} (${cant} und) - ${first} ${last}`,
          },
        });

        await prisma.caja.update({
          where: { id: caja.id },
          data: {
            total_ventas_efectivo: { increment: totalVenta },
            total_ingresos: { increment: totalVenta },
          },
        });
      }
    }

    const classSchedules = [
      {
        nombre_clase: 'Funcional AM',
        descripcion: 'Clase funcional de alta energia para socios activos.',
        dia_semana: [1, 3, 5],
        hora_inicio: '07:00',
        hora_fin: '08:00',
        cupo_maximo: 18,
      },
      {
        nombre_clase: 'Spinning Noon',
        descripcion:
          'Sesion de cardio guiada para resistencia y quema calorica.',
        dia_semana: [2, 4],
        hora_inicio: '12:30',
        hora_fin: '13:15',
        cupo_maximo: 16,
      },
      {
        nombre_clase: 'Yoga Recovery',
        descripcion:
          'Bloque de movilidad y recuperacion con foco post entrenamiento.',
        dia_semana: [2, 6],
        hora_inicio: '19:00',
        hora_fin: '20:00',
        cupo_maximo: 20,
      },
    ];

    for (let i = 0; i < classSchedules.length; i++) {
      const schedule = classSchedules[i];
      await prisma.schedule.create({
        data: {
          tenant_id: tenant.id,
          trainer_id: trainers[i % trainers.length].user_id,
          ...schedule,
        },
      });
    }

    for (let i = 0; i < 3; i++) {
      await prisma.announcement.create({
        data: {
          tenant_id: tenant.id,
          autor_id: admins[i % admins.length].id,
          titulo: [
            'Mantenimiento de equipos',
            'Clase funcional gratis',
            'Promocion renovacion',
          ][i],
          descripcion: [
            'La zona de poleas tendra mantenimiento preventivo de 14:00 a 16:00.',
            'Clase funcional abierta para socios activos este sabado a las 09:00.',
            'Renueva antes de vencer y recibe evaluacion corporal sin costo.',
          ][i],
          severidad: ['WARNING', 'INFO', 'INFO'][i],
          activo: true,
        },
      });
    }

    await prisma.auditLog.create({
      data: {
        tenant_id: tenant.id,
        actor_id: admins[0].id,
        actor_name: admins[0].nombre_completo,
        rol: 'ADMIN',
        accion: 'CREATE',
        entidad: 'DataTest',
        detalles: {
          message: 'Carga data-test creada con logs de asistencias y ventas',
          members: 20,
          admins: 2,
          trainers: 5,
          cashiers: 3,
        },
      },
    });
  }

  console.log(
    `Sembrado finalizado: tenants=${gyms.length + 1}, gyms=${gyms.length}, users=${totalUsers}, memberships=${totalMemberships}, cajas=${totalCajas}`,
  );
}

main()
  .catch((e) => {
    console.error('Error al correr el seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
