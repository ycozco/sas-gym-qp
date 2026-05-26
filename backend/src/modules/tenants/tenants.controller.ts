import { Controller, Get, Post, Param, UseGuards } from '@nestjs/common';
import { TenantsService } from './tenants.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('tenants')
@UseGuards(AuthGuard, RolesGuard)
export class TenantsController {
  constructor(private readonly tenantsService: TenantsService) {}

  @Get()
  @Roles(Role.SUPER_ADMIN)
  async getAllTenants() {
    return this.tenantsService.getAllTenants();
  }

  @Post(':id/toggle')
  @Roles(Role.SUPER_ADMIN)
  async toggleTenantStatus(@Param('id') id: string) {
    return this.tenantsService.toggleTenantStatus(id);
  }
}
