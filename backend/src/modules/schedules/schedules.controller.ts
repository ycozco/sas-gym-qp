import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { SchedulesService } from './schedules.service';

@Controller('schedules')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class SchedulesController {
  constructor(private readonly schedulesService: SchedulesService) {}

  @Get()
  @Roles(Role.ADMIN, Role.CAJA, Role.TRAINER, Role.MEMBER)
  async list(@Req() req: any) {
    return this.schedulesService.list(req.user.tenantId);
  }
}
