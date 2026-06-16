import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { TenantsService } from './tenants.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { UpdateTenantSettingsDto } from './dto/tenant-settings.dto';

@Controller('tenants')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class TenantsController {
  constructor(private readonly tenantsService: TenantsService) {}

  @Get('me')
  @Roles(Role.ADMIN, Role.CAJA, Role.TRAINER, Role.MEMBER, Role.SUPER_ADMIN)
  async getCurrentTenant(@Req() req: any) {
    return this.tenantsService.getTenantSettings(req.user.tenantId);
  }

  @Patch('me/settings')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async updateCurrentTenant(
    @Req() req: any,
    @Body() dto: UpdateTenantSettingsDto,
  ) {
    return this.tenantsService.updateTenantSettings(req.user.tenantId, dto);
  }

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
