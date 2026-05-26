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
}
