import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const gyms = await prisma.tenant.findMany({
    select: { id: true, nombre: true, plan_saas: true }
  });
  console.log('=== GIMNASIOS / TENANTS ===');
  console.log(JSON.stringify(gyms, null, 2));

  const trainers = await prisma.user.findMany({
    where: { rol: 'TRAINER' },
    select: {
      email: true,
      nombre_completo: true,
      dni: true,
      celular: true,
      tenant: { select: { nombre: true } }
    }
  });
  console.log('\n=== ENTRENADORES ===');
  console.log(JSON.stringify(trainers, null, 2));

  const cashiers = await prisma.user.findMany({
    where: { rol: 'CAJA' },
    select: {
      email: true,
      nombre_completo: true,
      dni: true,
      celular: true,
      tenant: { select: { nombre: true } }
    }
  });
  console.log('\n=== CAJEROS ===');
  console.log(JSON.stringify(cashiers, null, 2));
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
