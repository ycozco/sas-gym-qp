import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { RoutinesService } from './routines.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('routines')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class RoutinesController {
  constructor(private readonly routinesService: RoutinesService) {}

  @Get('active')
  @Roles(Role.MEMBER)
  async getActiveRoutine(@Req() req: any) {
    const userId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.routinesService.getActiveRoutine(userId, tenantId);
  }
}
