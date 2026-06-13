import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { AdminService, UpsertUserDto } from './admin.service';

@Controller('admin')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('members')
  @Roles(Role.ADMIN, Role.CAJA)
  listMembers(
    @Req() req: any,
    @Query('q') q?: string,
    @Query('state') state?: string,
  ) {
    return this.adminService.listMembers(
      req.user.tenantId,
      q || '',
      state || 'all',
    );
  }

  @Post('members')
  createMember(@Req() req: any, @Body() dto: UpsertUserDto) {
    return this.adminService.createMember(req.user.tenantId, dto);
  }

  @Patch('members/:id')
  updateMember(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: Partial<UpsertUserDto>,
  ) {
    return this.adminService.updateMember(req.user.tenantId, id, dto);
  }

  @Post('members/:id/toggle-active')
  toggleMember(@Req() req: any, @Param('id') id: string) {
    return this.adminService.toggleMember(req.user.tenantId, id);
  }

  @Get('cashiers')
  listCashiers(@Req() req: any) {
    return this.adminService.listCashiers(req.user.tenantId);
  }

  @Post('cashiers')
  createCashier(@Req() req: any, @Body() dto: UpsertUserDto) {
    return this.adminService.createCashier(req.user.tenantId, dto);
  }

  @Patch('cashiers/:id')
  updateCashier(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: Partial<UpsertUserDto>,
  ) {
    return this.adminService.updateCashier(req.user.tenantId, id, dto);
  }

  @Post('cashiers/:id/toggle-active')
  toggleCashier(@Req() req: any, @Param('id') id: string) {
    return this.adminService.toggleCashier(req.user.tenantId, id);
  }

  @Patch('cashiers/:id/permissions')
  updatePermissions(
    @Req() req: any,
    @Param('id') id: string,
    @Body('permissions') permissions: string[],
  ) {
    return this.adminService.updateCashierPermissions(
      req.user.tenantId,
      id,
      permissions || [],
    );
  }
}
