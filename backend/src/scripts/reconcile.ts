import {
  MembershipState,
  PaymentMethod,
  PaymentState,
  PrismaClient,
  Role,
  UserState,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { randomBytes } from 'crypto';

const prisma = new PrismaClient();

const PRESENTATION_GYMS = [
  {
    code: 'cayma-prime',
    name: 'SaasGym Cayma Prime',
    address: 'Av. Ejercito 1009, Cayma, Arequipa',
    phone: '987654101',
    plan: 'PRO',
    color: '#D2FF3A',
  },
  {
    code: 'yanahuara-fit',
    name: 'SaasGym Yanahuara Fit',
    address: 'Av. Ejercito 704, Yanahuara, Arequipa',
    phone: '987654102',
    plan: 'PRO',
    color: '#FF7A00',
  },
  {
    code: 'cercado-performance',
    name: 'SaasGym Cercado Performance',
    address: 'Calle San Francisco 315, Cercado, Arequipa',
    phone: '987654103',
    plan: 'ENTERPRISE',
    color: '#00C2FF',
  },
  {
    code: 'cerro-colorado-247',
    name: 'SaasGym Cerro Colorado 24/7',
    address: 'Av. Aviacion 602, Cerro Colorado, Arequipa',
    phone: '987654104',
    plan: 'BASIC',
    color: '#A259FF',
  },
] as const;

const SAAS_PLANS = [
  {
    code: 'BASIC',
    nombre: 'Basic',
    descripcion: 'Operacion esencial para un gimnasio en crecimiento.',
    precio_mensual: 199,
    limite_usuarios: 150,
    caracteristicas: 'Caja, socios, asistencia, productos y app de socio.',
  },
  {
    code: 'PRO',
    nombre: 'Pro',
    descripcion: 'Operacion avanzada para sedes con caja y staff completo.',
    precio_mensual: 399,
    limite_usuarios: 500,
    caracteristicas: 'Todo Basic, mas rutinas, dietas, puntos y multi-rol.',
  },
  {
    code: 'ENTERPRISE',
    nombre: 'Enterprise',
    descripcion: 'Operacion multi-sede con control total y soporte preferente.',
    precio_mensual: 899,
    limite_usuarios: 5000,
    caracteristicas: 'Todo Pro, mas red SaaS, auditoria ampliada y alta escala.',
  },
] as const;

const DEFAULT_SUPER_TENANT_ID = '11111111-1111-4111-8111-111111111111';

const DEFAULT_PRESENTATION_TENANT_IDS = [
  '22222222-2222-4222-8220-000000000001',
  '22222222-2222-4222-8221-000000000002',
  '22222222-2222-4222-8222-000000000003',
  '22222222-2222-4222-8223-000000000004',
] as const;

function requireSecret(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Falta la variable obligatoria ${name} para reconciliar datos productivos.`);
  }
  return value;
}

function addDays(base: Date, days: number): Date {
  const next = new Date(base);
  next.setDate(next.getDate() + days);
  return next;
}

async function hashPasswords() {
  return {
    superadmin: await bcrypt.hash(requireSecret('PRESENTATION_SUPERADMIN_PASSWORD'), 10),
    admin: await bcrypt.hash(requireSecret('PRESENTATION_ADMIN_PASSWORD'), 10),
    trainer: await bcrypt.hash(requireSecret('PRESENTATION_TRAINER_PASSWORD'), 10),
    cashier: await bcrypt.hash(requireSecret('PRESENTATION_CASHIER_PASSWORD'), 10),
    member: await bcrypt.hash(requireSecret('PRESENTATION_MEMBER_PASSWORD'), 10),
  };
}

async function ensureSaasPlans() {
  for (const plan of SAAS_PLANS) {
    await prisma.saasPlan.upsert({
      where: { code: plan.code },
      update: {
        nombre: plan.nombre,
        descripcion: plan.descripcion,
        precio_mensual: plan.precio_mensual,
        limite_usuarios: plan.limite_usuarios,
        caracteristicas: plan.caracteristicas,
        activo: true,
      },
      create: {
        ...plan,
        activo: true,
      },
    });
  }
}

async function ensureUser(params: {
  tenantId: string;
  email: string;
  passwordHash: string;
  rol: Role;
  nombre: string;
  dni: string;
  celular: string;
  qrSecret?: string;
}) {
  const existing = await prisma.user.findUnique({
    where: {
      tenant_id_email: {
        tenant_id: params.tenantId,
        email: params.email,
      },
    },
    select: { id: true, qr_secret: true },
  });

  if (existing) {
    return prisma.user.update({
      where: { id: existing.id },
      data: {
        password_hash: params.passwordHash,
        rol: params.rol,
        nombre_completo: params.nombre,
        dni: params.dni,
        celular: params.celular,
        estado: UserState.ACTIVE,
        qr_secret: existing.qr_secret ?? params.qrSecret,
      },
    });
  }

  return prisma.user.create({
    data: {
      tenant_id: params.tenantId,
      email: params.email,
      password_hash: params.passwordHash,
      rol: params.rol,
      nombre_completo: params.nombre,
      dni: params.dni,
      celular: params.celular,
      estado: UserState.ACTIVE,
      qr_secret: params.qrSecret,
    },
  });
}

function createQrSecret(): string {
  return randomBytes(32).toString('base64url');
}

function presentationTenantId(index: number): string {
  return (
    process.env[`PRESENTATION_TENANT_${index + 1}_ID`] ||
    DEFAULT_PRESENTATION_TENANT_IDS[index]
  );
}

async function ensureSchedule(params: {
  tenantId: string;
  trainerId: string;
  nombre: string;
  dias: number[];
  inicio: string;
  fin: string;
  cupo: number;
}) {
  const existing = await prisma.schedule.findFirst({
    where: {
      tenant_id: params.tenantId,
      trainer_id: params.trainerId,
      nombre_clase: params.nombre,
      hora_inicio: params.inicio,
      hora_fin: params.fin,
    },
  });

  if (existing) {
    return prisma.schedule.update({
      where: { id: existing.id },
      data: {
        dia_semana: params.dias,
        cupo_maximo: params.cupo,
        activo: true,
      },
    });
  }

  return prisma.schedule.create({
    data: {
      tenant_id: params.tenantId,
      trainer_id: params.trainerId,
      nombre_clase: params.nombre,
      descripcion: 'Clase grupal operativa para presentacion comercial.',
      dia_semana: params.dias,
      hora_inicio: params.inicio,
      hora_fin: params.fin,
      cupo_maximo: params.cupo,
      activo: true,
    },
  });
}

async function ensureExercise(params: {
  tenantId: string;
  trainerProfileId: string;
  nombre: string;
  grupo: string;
  descripcion: string;
}) {
  const existing = await prisma.exercise.findFirst({
    where: {
      tenant_id: params.tenantId,
      trainer_id: params.trainerProfileId,
      nombre: params.nombre,
    },
  });

  if (existing) {
    return prisma.exercise.update({
      where: { id: existing.id },
      data: {
        descripcion: params.descripcion,
        grupo_muscular: params.grupo,
        activo: true,
      },
    });
  }

  return prisma.exercise.create({
    data: {
      tenant_id: params.tenantId,
      trainer_id: params.trainerProfileId,
      nombre: params.nombre,
      descripcion: params.descripcion,
      grupo_muscular: params.grupo,
      activo: true,
    },
  });
}

async function ensureTemplate(params: {
  tenantId: string;
  trainerId: string;
  nombre: string;
  exerciseIds: string[];
}) {
  const existing = await prisma.routineTemplate.findFirst({
    where: {
      tenant_id: params.tenantId,
      trainer_id: params.trainerId,
      nombre: params.nombre,
    },
    include: { ejercicios: true },
  });

  const template = existing
    ? await prisma.routineTemplate.update({
        where: { id: existing.id },
        data: {
          descripcion: 'Rutina activa de presentacion para flujo mobile.',
        },
      })
    : await prisma.routineTemplate.create({
        data: {
          tenant_id: params.tenantId,
          trainer_id: params.trainerId,
          nombre: params.nombre,
          descripcion: 'Rutina activa de presentacion para flujo mobile.',
        },
      });

  for (let index = 0; index < params.exerciseIds.length; index += 1) {
    const exerciseId = params.exerciseIds[index];
    const row = existing?.ejercicios.find((item) => item.exercise_id === exerciseId);
    if (row) {
      await prisma.routineExercise.update({
        where: { id: row.id },
        data: {
          orden: index + 1,
          series: 4,
          repeticiones: index === 0 ? 12 : 10,
          peso_sugerido_kg: index === 0 ? 40 : 25,
          descanso_seg: 75,
        },
      });
      continue;
    }

    await prisma.routineExercise.create({
      data: {
        template_id: template.id,
        exercise_id: exerciseId,
        orden: index + 1,
        series: 4,
        repeticiones: index === 0 ? 12 : 10,
        peso_sugerido_kg: index === 0 ? 40 : 25,
        descanso_seg: 75,
      },
    });
  }

  return template;
}

async function main() {
  if (process.env.NODE_ENV !== 'production') {
    console.log('Reconciliador omitido: solo se ejecuta en production.');
    return;
  }

  const hashes = await hashPasswords();
  await ensureSaasPlans();
  const now = new Date();

  const superTenant = await prisma.tenant.upsert({
    where: {
      id: process.env.PRESENTATION_SUPER_TENANT_ID || DEFAULT_SUPER_TENANT_ID,
    },
    update: {
      nombre: 'SaasGym Network',
      plan_saas: 'ENTERPRISE',
      activo: true,
      direccion: 'Av. Ejercito 1030, Cayma, Arequipa',
      telefono: '999000000',
      horario: 'Administracion central',
      descripcion: 'Tenant central de operacion y supervision comercial.',
    },
    create: {
      id: process.env.PRESENTATION_SUPER_TENANT_ID || DEFAULT_SUPER_TENANT_ID,
      nombre: 'SaasGym Network',
      plan_saas: 'ENTERPRISE',
      activo: true,
      direccion: 'Av. Ejercito 1030, Cayma, Arequipa',
      telefono: '999000000',
      horario: 'Administracion central',
      descripcion: 'Tenant central de operacion y supervision comercial.',
    },
  });

  await ensureUser({
    tenantId: superTenant.id,
    email: 'superadmin@sasgym.local',
    passwordHash: hashes.superadmin,
    rol: Role.SUPER_ADMIN,
    nombre: 'Super Admin SaasGym',
    dni: '90000000',
    celular: '900000000',
  });

  for (let index = 0; index < PRESENTATION_GYMS.length; index += 1) {
    const gym = PRESENTATION_GYMS[index];
    const tenantId = presentationTenantId(index);

    const tenant = await prisma.tenant.upsert({
      where: { id: tenantId },
      update: {
        nombre: gym.name,
        plan_saas: gym.plan,
        activo: true,
        direccion: gym.address,
        telefono: gym.phone,
        horario: 'Lun-Dom 05:30 - 23:00',
        descripcion: `Sede de presentacion ${gym.code} con flujo real de socio y caja.`,
        color_primario: '#0F1115',
        color_secundario: '#1B1F2A',
        color_acento: gym.color,
      },
      create: {
        id: tenantId,
        nombre: gym.name,
        plan_saas: gym.plan,
        activo: true,
        direccion: gym.address,
        telefono: gym.phone,
        horario: 'Lun-Dom 05:30 - 23:00',
        descripcion: `Sede de presentacion ${gym.code} con flujo real de socio y caja.`,
        color_primario: '#0F1115',
        color_secundario: '#1B1F2A',
        color_acento: gym.color,
      },
    });

    const admin = await ensureUser({
      tenantId: tenant.id,
      email: `admin.${gym.code}@sasgym.local`,
      passwordHash: hashes.admin,
      rol: Role.ADMIN,
      nombre: `Admin ${gym.name}`,
      dni: `${index + 1}0000001`,
      celular: `90000010${index}`,
    });

    const trainer = await ensureUser({
      tenantId: tenant.id,
      email: `trainer.${gym.code}@sasgym.local`,
      passwordHash: hashes.trainer,
      rol: Role.TRAINER,
      nombre: `Trainer ${gym.name}`,
      dni: `${index + 1}0000002`,
      celular: `90000020${index}`,
    });

    const cashier = await ensureUser({
      tenantId: tenant.id,
      email: `caja.${gym.code}@sasgym.local`,
      passwordHash: hashes.cashier,
      rol: Role.CAJA,
      nombre: `Caja ${gym.name}`,
      dni: `${index + 1}0000003`,
      celular: `90000030${index}`,
    });

    const member = await ensureUser({
      tenantId: tenant.id,
      email: `socio.${gym.code}@sasgym.local`,
      passwordHash: hashes.member,
      rol: Role.MEMBER,
      nombre: `Socio Demo ${gym.name}`,
      dni: `${index + 1}0000004`,
      celular: `90000040${index}`,
      qrSecret: createQrSecret(),
    });

    const trainerProfile = await prisma.trainerProfile.upsert({
      where: { user_id: trainer.id },
      update: {
        especialidad: 'Fuerza y recomposicion corporal',
        anos_experiencia: 7,
        certificaciones: 'NSCA CPT',
        biografia: 'Entrenador principal del dataset comercial.',
      },
      create: {
        user_id: trainer.id,
        especialidad: 'Fuerza y recomposicion corporal',
        anos_experiencia: 7,
        certificaciones: 'NSCA CPT',
        biografia: 'Entrenador principal del dataset comercial.',
      },
    });

    const memberProfile = await prisma.memberProfile.upsert({
      where: { user_id: member.id },
      update: {
        trainer_id: trainerProfile.id,
        nickname: `demo-${gym.code}`,
        peso_kg: 78,
        altura_cm: 174,
        objetivo: 'Hipertrofia',
        lesiones: 'Sin lesiones activas.',
      },
      create: {
        user_id: member.id,
        trainer_id: trainerProfile.id,
        nickname: `demo-${gym.code}`,
        peso_kg: 78,
        altura_cm: 174,
        objetivo: 'Hipertrofia',
        lesiones: 'Sin lesiones activas.',
      },
    });

    const monthlyPlan = await prisma.membershipPlan.upsert({
      where: {
        tenant_id_nombre: {
          tenant_id: tenant.id,
          nombre: 'Plan Mensual Pro',
        },
      },
      update: {
        descripcion: 'Plan mensual principal para la presentacion.',
        duracion_dias: 30,
        precio: 149,
        color: gym.color,
        orden: 1,
        activo: true,
      },
      create: {
        tenant_id: tenant.id,
        created_by_id: admin.id,
        nombre: 'Plan Mensual Pro',
        descripcion: 'Plan mensual principal para la presentacion.',
        duracion_dias: 30,
        precio: 149,
        color: gym.color,
        orden: 1,
        activo: true,
      },
    });

    await prisma.membershipPlan.upsert({
      where: {
        tenant_id_nombre: {
          tenant_id: tenant.id,
          nombre: 'Plan Trimestral Elite',
        },
      },
      update: {
        descripcion: 'Plan trimestral para renovacion comercial.',
        duracion_dias: 90,
        precio: 399,
        color: '#FFFFFF',
        orden: 2,
        activo: true,
      },
      create: {
        tenant_id: tenant.id,
        created_by_id: admin.id,
        nombre: 'Plan Trimestral Elite',
        descripcion: 'Plan trimestral para renovacion comercial.',
        duracion_dias: 90,
        precio: 399,
        color: '#FFFFFF',
        orden: 2,
        activo: true,
      },
    });

    const activeMembership = await prisma.membership.findFirst({
      where: {
        tenant_id: tenant.id,
        user_id: member.id,
        estado: MembershipState.ACTIVE,
      },
    });

    const membership =
      activeMembership ||
      (await prisma.membership.create({
        data: {
          tenant_id: tenant.id,
          user_id: member.id,
          plan_id: monthlyPlan.id,
          plan_nombre: monthlyPlan.nombre,
          duracion_dias: monthlyPlan.duracion_dias,
          monto: monthlyPlan.precio,
          precio_pagado: monthlyPlan.precio,
          monto_pendiente: 0,
          pago_completo: true,
          estado: MembershipState.ACTIVE,
          fecha_inicio: addDays(now, -7),
          fecha_vencimiento: addDays(now, 23),
        },
      }));

    const paymentRef = `presentation-membership-${tenant.id}`;
    const existingPayment = await prisma.payment.findFirst({
      where: {
        tenant_id: tenant.id,
        membership_id: membership.id,
        referencia_externa: paymentRef,
      },
    });
    if (!existingPayment) {
      await prisma.payment.create({
        data: {
          tenant_id: tenant.id,
          membership_id: membership.id,
          registrado_por_id: cashier.id,
          monto: monthlyPlan.precio,
          metodo: PaymentMethod.CASH,
          estado: PaymentState.APPROVED,
          referencia_externa: paymentRef,
          timestamp: addDays(now, -7),
        },
      });
    }

    const supplements = await prisma.productCategory.upsert({
      where: {
        tenant_id_nombre: {
          tenant_id: tenant.id,
          nombre: 'Suplementos',
        },
      },
      update: {
        descripcion: 'Categoria principal de suplementos.',
        color: gym.color,
        activo: true,
      },
      create: {
        tenant_id: tenant.id,
        nombre: 'Suplementos',
        descripcion: 'Categoria principal de suplementos.',
        color: gym.color,
        activo: true,
      },
    });

    await prisma.product.upsert({
      where: {
        tenant_id_sku: {
          tenant_id: tenant.id,
          sku: `WHEY-${index + 1}`,
        },
      },
      update: {
        nombre: 'Whey Protein 2lb',
        descripcion: 'Producto real para flujo de caja.',
        categoria_id: supplements.id,
        precio_compra: 110,
        precio_venta: 169,
        stock_actual: 20,
        stock_minimo: 4,
        estado: 'activo',
        es_visible: true,
      },
      create: {
        tenant_id: tenant.id,
        nombre: 'Whey Protein 2lb',
        descripcion: 'Producto real para flujo de caja.',
        categoria_id: supplements.id,
        sku: `WHEY-${index + 1}`,
        precio_compra: 110,
        precio_venta: 169,
        stock_actual: 20,
        stock_minimo: 4,
        estado: 'activo',
        es_visible: true,
      },
    });

    await prisma.pointsConfig.upsert({
      where: { tenant_id: tenant.id },
      update: {
        puntos_por_sol: 1,
        minimo_para_canje: 100,
        puntos_expiran: false,
        dias_expiracion: 365,
        activo: true,
      },
      create: {
        tenant_id: tenant.id,
        puntos_por_sol: 1,
        minimo_para_canje: 100,
        puntos_expiran: false,
        dias_expiracion: 365,
        activo: true,
      },
    });

    const benchPress = await ensureExercise({
      tenantId: tenant.id,
      trainerProfileId: trainerProfile.id,
      nombre: 'Press de banca',
      grupo: 'Pecho',
      descripcion: 'Ejercicio principal de fuerza de empuje.',
    });
    const shoulderPress = await ensureExercise({
      tenantId: tenant.id,
      trainerProfileId: trainerProfile.id,
      nombre: 'Press militar',
      grupo: 'Hombros',
      descripcion: 'Trabajo de hombros para rutina activa.',
    });
    const template = await ensureTemplate({
      tenantId: tenant.id,
      trainerId: trainerProfile.id,
      nombre: 'Push Demo',
      exerciseIds: [benchPress.id, shoulderPress.id],
    });

    const assignment = await prisma.routineAssignment.findFirst({
      where: {
        tenant_id: tenant.id,
        member_id: memberProfile.id,
        template_id: template.id,
      },
    });
    if (!assignment) {
      await prisma.routineAssignment.create({
        data: {
          tenant_id: tenant.id,
          member_id: memberProfile.id,
          trainer_id: trainerProfile.id,
          template_id: template.id,
          agenda_semanal: { MON: template.id, WED: template.id, FRI: template.id },
          publicada: true,
        },
      });
    }

    const activeDiet = await prisma.dietPlan.findFirst({
      where: {
        tenant_id: tenant.id,
        member_id: member.id,
        activo: true,
      },
    });
    if (!activeDiet) {
      await prisma.dietPlan.create({
        data: {
          tenant_id: tenant.id,
          member_id: member.id,
          trainer_id: trainer.id,
          peso_objetivo_kg: 75,
          calorias_objetivo: 2350,
          proteinas_g: 180,
          carbohidratos_g: 240,
          grasas_g: 65,
          comidas: [
            { nombre: 'Desayuno', detalle: 'Avena, yogurt griego y frutas' },
            { nombre: 'Almuerzo', detalle: 'Pollo, arroz y ensalada' },
            { nombre: 'Cena', detalle: 'Tortilla de claras con camote' },
          ],
          sugerencias: 'Mantener hidratacion de 2.5L y control semanal de peso.',
          activo: true,
        },
      });
    }

    await ensureSchedule({
      tenantId: tenant.id,
      trainerId: trainer.id,
      nombre: 'Cross Training',
      dias: [1, 3, 5],
      inicio: '07:00',
      fin: '08:00',
      cupo: 16,
    });

    const announcement = await prisma.announcement.findFirst({
      where: {
        tenant_id: tenant.id,
        titulo: 'Semana de transformacion',
      },
    });
    if (!announcement) {
      await prisma.announcement.create({
        data: {
          tenant_id: tenant.id,
          autor_id: admin.id,
          titulo: 'Semana de transformacion',
          descripcion: 'Promocion activa para renovaciones y ventas en caja.',
          activo: true,
          severidad: 'INFO',
        },
      });
    }
  }

  const summary = await Promise.all(
    PRESENTATION_GYMS.map(async (gym, index) => {
      const tenantId = presentationTenantId(index);
      const [users, plans, products, schedules, diets] = await Promise.all([
        prisma.user.count({ where: { tenant_id: tenantId } }),
        prisma.membershipPlan.count({ where: { tenant_id: tenantId } }),
        prisma.product.count({ where: { tenant_id: tenantId, es_visible: true } }),
        prisma.schedule.count({ where: { tenant_id: tenantId, activo: true } }),
        prisma.dietPlan.count({ where: { tenant_id: tenantId, activo: true } }),
      ]);
      return {
        gym: gym.code,
        tenantId,
        users,
        plans,
        products,
        schedules,
        diets,
      };
    }),
  );

  console.log(
    `Reconciliacion productiva completada para ${PRESENTATION_GYMS.length} gimnasios.`,
  );
  console.table(summary);
}

void main()
  .catch((error) => {
    console.error('Fallo la reconciliacion productiva:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
