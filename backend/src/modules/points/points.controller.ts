import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { PointsService } from './points.service';
import { IsIn, IsInt, IsOptional, IsString, IsUUID, Min } from 'class-validator';
import { Type } from 'class-transformer';

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

  @Get('me')
  @Roles(Role.MEMBER)
  async mySummary(@Req() req: any) {
    return this.pointsService.memberSummary(req.user.sub, req.user.tenantId);
  }

  @Post('redeem')
  @Roles(Role.MEMBER)
  async redeem(@Req() req: any, @Body() dto: RedeemPointsDto) {
    return this.pointsService.redeem(req.user.sub, req.user.tenantId, dto);
  }
}
