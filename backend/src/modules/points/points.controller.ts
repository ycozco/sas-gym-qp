import type { AuthenticatedRequest } from '../../core/types/authenticated-request';
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
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

class CreatePointsProductDto {
  @IsString()
  nombre: string;

  @IsString()
  descripcion: string;

  @IsInt()
  @Min(1)
  precio_puntos: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  stock?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  stock_minimo?: number;

  @IsOptional()
  @IsBoolean()
  destacado?: boolean;
}

class UpdatePointsProductDto {
  @IsOptional()
  @IsString()
  nombre?: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  precio_puntos?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  stock?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  stock_minimo?: number;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;

  @IsOptional()
  @IsBoolean()
  destacado?: boolean;
}

class CreatePointsMembershipDto {
  @IsString()
  nombre: string;

  @IsString()
  descripcion: string;

  @IsInt()
  @Min(1)
  precio_puntos: number;

  @IsInt()
  @Min(1)
  duracion_dias: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  stock?: number;

  @IsOptional()
  @IsBoolean()
  destacada?: boolean;
}

class UpdatePointsMembershipDto {
  @IsOptional()
  @IsString()
  nombre?: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  precio_puntos?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  duracion_dias?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  stock?: number;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;

  @IsOptional()
  @IsBoolean()
  destacada?: boolean;
}

@Controller('points')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class PointsController {
  constructor(private readonly pointsService: PointsService) {}

  // ─── ENDPOINTS PÚBLICOS PARA EL TENANT ───────────────────────────

  /** Resumen general de puntos (ADMIN/CAJERO) */
  @Get('summary')
  @Roles(Role.ADMIN, Role.CAJA)
  async summary(@Req() req: AuthenticatedRequest) {
    return this.pointsService.summary(req.user.tenantId);
  }

  /** Catálogo de productos y membresías canjeables */
  @Get('catalog')
  @Roles(Role.ADMIN, Role.CAJA, Role.MEMBER)
  async catalog(@Req() req: AuthenticatedRequest) {
    return this.pointsService.catalog(req.user.tenantId);
  }

  /** Ranking de miembros por puntos */
  @Get('leaderboard')
  @Roles(Role.ADMIN, Role.CAJA, Role.MEMBER)
  async leaderboard(
    @Req() req: AuthenticatedRequest,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.pointsService.leaderboard(req.user.tenantId, limit ?? 10);
  }

  /** Configuración de puntos del tenant */
  @Get('config')
  @Roles(Role.ADMIN)
  async getConfig(@Req() req: AuthenticatedRequest) {
    return this.pointsService.getConfig(req.user.tenantId);
  }

  /** Actualizar configuración de puntos */
  @Put('config')
  @Roles(Role.ADMIN)
  async updateConfig(
    @Req() req: AuthenticatedRequest,
    @Body() dto: UpdatePointsConfigDto,
  ) {
    return this.pointsService.updateConfig(req.user.tenantId, dto);
  }

  /** Agregar puntos manualmente a un usuario (Admin) */
  @Post('admin/add')
  @Roles(Role.ADMIN)
  async adminAdd(
    @Req() req: AuthenticatedRequest,
    @Body() dto: AdminAddPointsDto,
  ) {
    return this.pointsService.adminAddPoints(req.user.tenantId, dto);
  }

  // ─── ENDPOINTS ADMIN DE GESTIÓN DEL CATÁLOGO ───────────────────────

  @Post('catalog/products')
  @Roles(Role.ADMIN)
  async createProduct(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreatePointsProductDto,
  ) {
    return this.pointsService.createProduct(req.user.tenantId, dto);
  }

  @Patch('catalog/products/:id')
  @Roles(Role.ADMIN)
  async updateProduct(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdatePointsProductDto,
  ) {
    return this.pointsService.updateProduct(req.user.tenantId, id, dto);
  }

  @Delete('catalog/products/:id')
  @Roles(Role.ADMIN)
  async deleteProduct(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.pointsService.deleteProduct(req.user.tenantId, id);
  }

  @Post('catalog/memberships')
  @Roles(Role.ADMIN)
  async createMembership(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreatePointsMembershipDto,
  ) {
    return this.pointsService.createMembership(req.user.tenantId, dto);
  }

  @Patch('catalog/memberships/:id')
  @Roles(Role.ADMIN)
  async updateMembership(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdatePointsMembershipDto,
  ) {
    return this.pointsService.updateMembership(req.user.tenantId, id, dto);
  }

  @Delete('catalog/memberships/:id')
  @Roles(Role.ADMIN)
  async deleteMembership(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.pointsService.deleteMembership(req.user.tenantId, id);
  }

  // ─── ENDPOINTS PARA EL MIEMBRO ────────────────────────────────────

  /** Mi saldo y movimientos de puntos */
  @Get('me')
  @Roles(Role.MEMBER)
  async mySummary(@Req() req: AuthenticatedRequest) {
    return this.pointsService.memberSummary(req.user.sub, req.user.tenantId);
  }

  /** Canjear puntos por producto o membresía */
  @Post('redeem')
  @Roles(Role.MEMBER)
  async redeem(@Req() req: AuthenticatedRequest, @Body() dto: RedeemPointsDto) {
    return this.pointsService.redeem(req.user.sub, req.user.tenantId, dto);
  }
}
