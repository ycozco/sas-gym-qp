import { Controller, Get } from '@nestjs/common';
import { MembershipState, ProductEstado, Role } from '@prisma/client';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';

const DEFAULT_SUPER_TENANT_ID = '11111111-1111-4111-8111-111111111111';
const DEFAULT_PRESENTATION_TENANT_IDS = [
  '22222222-2222-4222-8220-000000000001',
  '22222222-2222-4222-8221-000000000002',
  '22222222-2222-4222-8222-000000000003',
  '22222222-2222-4222-8223-000000000004',
] as const;

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  health() {
    return {
      status: 'ok',
      service: process.env.WS_MODE === 'true' ? 'ws' : 'api',
      environment: process.env.NODE_ENV || 'development',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('health/readiness')
  async readiness() {
    const expectedTenantIds = DEFAULT_PRESENTATION_TENANT_IDS.map(
      (fallbackId, index) =>
        process.env[`PRESENTATION_TENANT_${index + 1}_ID`] || fallbackId,
    );
    const superTenantId =
      process.env.PRESENTATION_SUPER_TENANT_ID || DEFAULT_SUPER_TENANT_ID;

    const [superAdmins, seededTenants] =
      await Promise.all([
        this.prisma.user.count({ where: { rol: Role.SUPER_ADMIN } }),
        this.prisma.tenant.findMany({
          where: { id: { in: expectedTenantIds }, activo: true },
          include: {
            usuarios: {
              select: {
                rol: true,
              },
            },
            membership_plans: {
              where: { activo: true },
              select: { id: true },
            },
            products: {
              where: { es_visible: true, estado: ProductEstado.activo },
              select: { id: true },
            },
            schedules: {
              where: { activo: true },
              select: { id: true },
            },
            diet_plans: {
              where: { activo: true },
              select: { id: true },
            },
            memberships: {
              where: { estado: MembershipState.ACTIVE },
              select: { id: true },
            },
          },
        }),
      ]);

    const tenantsById = new Map(seededTenants.map((tenant) => [tenant.id, tenant]));
    const perTenantChecks = expectedTenantIds.map((tenantId) => {
      const tenant = tenantsById.get(tenantId);
      const roles = new Set(tenant?.usuarios.map((user) => user.rol) ?? []);
      return {
        tenantId,
        found: Boolean(tenant),
        admin: roles.has(Role.ADMIN),
        cashier: roles.has(Role.CAJA),
        trainer: roles.has(Role.TRAINER),
        member: roles.has(Role.MEMBER),
        membershipPlans: (tenant?.membership_plans.length ?? 0) > 0,
        products: (tenant?.products.length ?? 0) > 0,
        schedules: (tenant?.schedules.length ?? 0) > 0,
        diets: (tenant?.diet_plans.length ?? 0) > 0,
        activeMemberships: (tenant?.memberships.length ?? 0) > 0,
      };
    });

    const completeCommercialTenants = perTenantChecks.filter(
      (tenant) =>
        tenant.found &&
        tenant.admin &&
        tenant.cashier &&
        tenant.trainer &&
        tenant.member &&
        tenant.membershipPlans &&
        tenant.products &&
        tenant.schedules &&
        tenant.diets &&
        tenant.activeMemberships,
    ).length;

    const checks = {
      superTenant:
        (await this.prisma.tenant.count({
          where: { id: superTenantId, activo: true },
        })) > 0,
      superAdmin: superAdmins > 0,
      commercialTenants:
        completeCommercialTenants === expectedTenantIds.length,
    };
    const ready = Object.values(checks).every(Boolean);

    return {
      status: ready ? 'ready' : 'not_ready',
      checks,
      counts: {
        expectedCommercialTenants: expectedTenantIds.length,
        completeCommercialTenants,
        superAdmins,
      },
      tenants: perTenantChecks,
      service: process.env.WS_MODE === 'true' ? 'ws' : 'api',
      timestamp: new Date().toISOString(),
    };
  }
}
