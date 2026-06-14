import { Controller, Get, Req, Query, UseGuards } from '@nestjs/common';
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
  async getAuditLogs(
    @Req() req: any,
    @Query('limit') limit?: string,
    @Query('cursor') cursor?: string,
  ) {
    const tenantId = req.user.tenantId;
    const parsedLimit = limit ? parseInt(limit, 10) : 20;
    return this.reportsService.getAuditLogs(tenantId, parsedLimit, cursor);
  }

  @Get('dashboard')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async getDashboard(@Req() req: any) {
    return this.reportsService.getDashboard(req.user.tenantId);
  }
}
