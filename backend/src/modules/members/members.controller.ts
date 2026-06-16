import { Controller, Post, Get, Body, Req, Query, UseGuards } from '@nestjs/common';
import { MembersService } from './members.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('members')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class MembersController {
  constructor(private readonly membersService: MembersService) {}

  @Post('workout-log')
  @Roles(Role.MEMBER)
  async saveWorkoutLog(@Req() req: any, @Body() dto: any) {
    const userId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.membersService.saveWorkoutLog(userId, tenantId, dto);
  }

  @Get('search')
  @Roles(Role.ADMIN, Role.CAJA)
  async search(@Req() req: any, @Query('q') query: string) {
    const tenantId = req.user.tenantId;
    return this.membersService.searchMembers(tenantId, query);
  }

  @Get('assigned')
  @Roles(Role.TRAINER)
  async assigned(@Req() req: any) {
    return this.membersService.assignedMembers(req.user.sub, req.user.tenantId);
  }
}
