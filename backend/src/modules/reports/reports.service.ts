import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async getAuditLogs(tenantId: string) {
    return this.prisma.auditLog.findMany({
      where: { tenant_id: tenantId },
      orderBy: { timestamp: 'desc' },
      take: 100,
    });
  }

  async getDashboard(tenantId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const nextWeek = new Date();
    nextWeek.setDate(nextWeek.getDate() + 7);

    const [
      activeMembers,
      expiredSoon,
      memberships,
      paymentsToday,
      productSalesToday,
      activeCaja,
    ] = await Promise.all([
      this.prisma.user.count({
        where: { tenant_id: tenantId, rol: 'MEMBER', estado: 'ACTIVE' },
      }),
      this.prisma.membership.count({
        where: {
          tenant_id: tenantId,
          fecha_vencimiento: { gte: today, lte: nextWeek },
        },
      }),
      this.prisma.membership.count({ where: { tenant_id: tenantId } }),
      this.prisma.payment.findMany({
        where: {
          tenant_id: tenantId,
          timestamp: { gte: today },
          estado: 'APPROVED',
        },
      }),
      this.prisma.productSale.findMany({
        where: {
          tenant_id: tenantId,
          fecha_venta: { gte: today },
          estado: 'completada',
        },
      }),
      this.prisma.caja.findFirst({
        where: { tenant_id: tenantId, estado: 'abierta' },
        include: { cajero: true },
      }),
    ]);

    const paymentsTotal = paymentsToday.reduce((sum, p) => sum + p.monto, 0);
    const productsTotal = productSalesToday.reduce(
      (sum, s) => sum + s.total,
      0,
    );
    return {
      activeMembers,
      expiredSoon,
      memberships,
      paymentsToday: paymentsToday.length,
      productSalesToday: productSalesToday.length,
      revenueToday: paymentsTotal + productsTotal,
      activeCaja,
    };
  }
}
