import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('reports')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('audit-logs')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async getAuditLogs(@Req() req: any) {
    const tenantId = req.user.tenantId;
    return this.reportsService.getAuditLogs(tenantId);
  }
}
