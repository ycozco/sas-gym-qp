import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const tenant = await prisma.tenant.findFirst({
    where: { nombre: 'SaasGym Surco Prime' },
  });
  if (!tenant) throw new Error('Tenant Surco no encontrado.');

  const plan = await prisma.membershipPlan.findFirst({
    where: { tenant_id: tenant.id, nombre: 'Plan Mensual Oro' },
  });
  if (!plan) throw new Error('Plan Mensual Oro no encontrado.');

  const existingMembership = await prisma.membership.findFirst({
    where: { tenant_id: tenant.id, plan_id: plan.id },
    orderBy: { created_at: 'asc' },
  });
  if (!existingMembership) throw new Error('Membresia snapshot no encontrada.');

  const oldMembershipMonto = existingMembership.monto;
  const updatedPrice = 165;

  await prisma.membershipPlan.update({
    where: { id: plan.id },
    data: { precio: updatedPrice },
  });

  const unchangedMembership = await prisma.membership.findUnique({
    where: { id: existingMembership.id },
  });
  if (!unchangedMembership) throw new Error('Membresia existente no encontrada.');

  const member = await prisma.user.findFirst({
    where: {
      tenant_id: tenant.id,
      rol: 'MEMBER',
    },
    orderBy: { created_at: 'desc' },
  });
  if (!member) throw new Error('Socio para nueva venta no encontrado.');

  const newMembership = await prisma.membership.create({
    data: {
      tenant_id: tenant.id,
      user_id: member.id,
      plan_id: plan.id,
      plan_nombre: plan.nombre,
      duracion_dias: plan.duracion_dias,
      monto: updatedPrice,
      estado: 'ACTIVE',
      fecha_inicio: new Date(),
      fecha_vencimiento: new Date(Date.now() + plan.duracion_dias * 86400000),
    },
  });

  await prisma.membership.delete({ where: { id: newMembership.id } });

  console.log(
    JSON.stringify(
      {
        tenant: tenant.nombre,
        planId: plan.id,
        oldMembershipBefore: oldMembershipMonto,
        oldMembershipAfter: unchangedMembership.monto,
        updatedPlanPrice: updatedPrice,
        newMembershipMonto: newMembership.monto,
        snapshotPreserved: oldMembershipMonto === unchangedMembership.monto,
        newSaleUsesEditedPlan: newMembership.monto === updatedPrice,
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
