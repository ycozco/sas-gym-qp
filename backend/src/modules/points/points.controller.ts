import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { PointsService } from './points.service';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';

class RedeemPointsDto {
  @IsIn(['producto', 'membresia'])
  tipo: 'producto' | 'membresia';

  @IsUUID()
  itemId: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  cantidad?: number;

  @IsOptional()
  @IsString()
  notas?: string;
}

class UpdatePointsConfigDto {
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true')
  activo?: boolean;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  puntosPorSol?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  minCanje?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  vencimientoDias?: number | null;
}

class AdminAddPointsDto {
  @IsUUID()
  userId: string;

  @IsInt()
  @Min(1)
  puntos: number;

  @IsString()
  descripcion: string;
}

@Controller('points')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class PointsController {
  constructor(private readonly pointsService: PointsService) {}

  // ─── ENDPOINTS PÚBLICOS PARA EL TENANT ───────────────────────────

  /** Resumen general de puntos (ADMIN/CAJERO) */
  @Get('summary')
  @Roles(Role.ADMIN, Role.CAJA)
  async summary(@Req() req: any) {
    return this.pointsService.summary(req.user.tenantId);
  }

  /** Catálogo de productos y membresías canjeables */
  @Get('catalog')
  @Roles(Role.ADMIN, Role.CAJA, Role.MEMBER)
  async catalog(@Req() req: any) {
    return this.pointsService.catalog(req.user.tenantId);
  }

  /** Ranking de miembros por puntos */
  @Get('leaderboard')
  @Roles(Role.ADMIN, Role.CAJA, Role.MEMBER)
  async leaderboard(
    @Req() req: any,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.pointsService.leaderboard(req.user.tenantId, limit ?? 10);
  }

  /** Configuración de puntos del tenant */
  @Get('config')
  @Roles(Role.ADMIN)
  async getConfig(@Req() req: any) {
    return this.pointsService.getConfig(req.user.tenantId);
  }

  /** Actualizar configuración de puntos */
  @Put('config')
  @Roles(Role.ADMIN)
  async updateConfig(@Req() req: any, @Body() dto: UpdatePointsConfigDto) {
    return this.pointsService.updateConfig(req.user.tenantId, dto);
  }

  /** Agregar puntos manualmente a un usuario (Admin) */
  @Post('admin/add')
  @Roles(Role.ADMIN)
  async adminAdd(@Req() req: any, @Body() dto: AdminAddPointsDto) {
    return this.pointsService.adminAddPoints(req.user.tenantId, dto);
  }

  // ─── ENDPOINTS PARA EL MIEMBRO ────────────────────────────────────

  /** Mi saldo y movimientos de puntos */
  @Get('me')
  @Roles(Role.MEMBER)
  async mySummary(@Req() req: any) {
    return this.pointsService.memberSummary(req.user.sub, req.user.tenantId);
  }

  /** Canjear puntos por producto o membresía */
  @Post('redeem')
  @Roles(Role.MEMBER)
  async redeem(@Req() req: any, @Body() dto: RedeemPointsDto) {
    return this.pointsService.redeem(req.user.sub, req.user.tenantId, dto);
  }
}
