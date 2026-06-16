import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { PointsService } from './points.service';

@Controller('points')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class PointsController {
  constructor(private readonly pointsService: PointsService) {}

  @Get('summary')
  @Roles(Role.ADMIN, Role.CAJA, Role.MEMBER)
  async summary(@Req() req: any) {
    return this.pointsService.summary(req.user.tenantId);
  }

  @Get('catalog')
  @Roles(Role.ADMIN, Role.CAJA, Role.MEMBER)
  async catalog() {
    return this.pointsService.catalog();
  }
}
