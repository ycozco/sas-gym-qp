import { Controller, Get } from '@nestjs/common';
import { Role } from '@prisma/client';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';

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
    const requiredTenants = Number(process.env.PRESENTATION_TENANT_COUNT || 4);
    const [tenantCount, superAdmins, products, plans, schedules] =
      await Promise.all([
        this.prisma.tenant.count({ where: { activo: true } }),
        this.prisma.user.count({ where: { rol: Role.SUPER_ADMIN } }),
        this.prisma.product.count(),
        this.prisma.membershipPlan.count(),
        this.prisma.schedule.count(),
      ]);

    const checks = {
      tenants: tenantCount >= requiredTenants,
      superAdmin: superAdmins > 0,
      products: products > 0,
      membershipPlans: plans > 0,
      schedules: schedules > 0,
    };
    const ready = Object.values(checks).every(Boolean);

    return {
      status: ready ? 'ready' : 'not_ready',
      checks,
      counts: {
        tenantCount,
        superAdmins,
        products,
        membershipPlans: plans,
        schedules,
      },
      requiredTenants,
      service: process.env.WS_MODE === 'true' ? 'ws' : 'api',
      timestamp: new Date().toISOString(),
    };
  }
}
