import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Req,
  Query,
  Param,
  UseGuards,
} from '@nestjs/common';
import { MembersService } from './members.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { IsOptional, IsString, MinLength } from 'class-validator';

class FreezeMembershipDto {
  @IsString()
  @MinLength(5)
  razon: string;

  @IsOptional()
  @IsString()
  fecha_fin?: string; // ISO date string YYYY-MM-DD
}

@Controller('members')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class MembersController {
  constructor(private readonly membersService: MembersService) {}

  // ─── WORKOUT ─────────────────────────────────────────────────────
  @Post('workout-log')
  @Roles(Role.MEMBER)
  async saveWorkoutLog(@Req() req: any, @Body() dto: any) {
    return this.membersService.saveWorkoutLog(
      req.user.sub,
      req.user.tenantId,
      dto,
    );
  }

  // ─── LISTADO DE MIEMBROS PAGINADO POR CURSOR ──────────────────────
  @Get()
  @Roles(Role.ADMIN, Role.CAJA)
  async findAll(
    @Req() req: any,
    @Query('limit') limit?: string,
    @Query('cursor') cursor?: string,
  ) {
    const parsedLimit = limit ? parseInt(limit, 10) : 20;
    return this.membersService.findAll(req.user.tenantId, parsedLimit, cursor);
  }

  // ─── BÚSQUEDA ────────────────────────────────────────────────────
  @Get('search')
  @Roles(Role.ADMIN, Role.CAJA)
  async search(@Req() req: any, @Query('q') query: string) {
    return this.membersService.searchMembers(req.user.tenantId, query);
  }

  // ─── TRAINER ─────────────────────────────────────────────────────
  @Get('assigned')
  @Roles(Role.TRAINER)
  async assigned(@Req() req: any) {
    return this.membersService.assignedMembers(req.user.sub, req.user.tenantId);
  }

  // ─── CONGELAMIENTO DE MEMBRESÍAS ─────────────────────────────────

  /** Congelar membresía */
  @Post('memberships/:membershipId/freeze')
  @Roles(Role.ADMIN)
  async freeze(
    @Req() req: any,
    @Param('membershipId') membershipId: string,
    @Body() dto: FreezeMembershipDto,
  ) {
    return this.membersService.freezeMembership(
      membershipId,
      req.user.tenantId,
      dto,
    );
  }

  /** Descongelar membresía (extiende fecha automáticamente) */
  @Delete('memberships/:membershipId/freeze')
  @Roles(Role.ADMIN)
  async unfreeze(@Req() req: any, @Param('membershipId') membershipId: string) {
    return this.membersService.unfreezeMembership(
      membershipId,
      req.user.tenantId,
    );
  }

  /** Historial de congelamientos de una membresía */
  @Get('memberships/:membershipId/freeze-history')
  @Roles(Role.ADMIN)
  async freezeHistory(
    @Req() req: any,
    @Param('membershipId') membershipId: string,
  ) {
    return this.membersService.freezeHistory(membershipId, req.user.tenantId);
  }
}
