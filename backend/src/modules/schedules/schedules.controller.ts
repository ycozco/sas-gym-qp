import type { AuthenticatedRequest } from '../../core/types/authenticated-request';
import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Patch,
  Delete,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { SchedulesService } from './schedules.service';
import {
  IsDateString,
  IsOptional,
  IsString,
  IsNotEmpty,
  IsNumber,
  IsArray,
  IsBoolean,
} from 'class-validator';

class BookingDto {
  @IsOptional()
  @IsDateString()
  fecha?: string;
}

class CreateScheduleDto {
  @IsString()
  @IsNotEmpty()
  nombre_clase: string;

  @IsString()
  @IsOptional()
  descripcion?: string;

  @IsString()
  @IsNotEmpty()
  trainer_id: string;

  @IsArray()
  @IsNumber({}, { each: true })
  dia_semana: number[];

  @IsString()
  @IsNotEmpty()
  hora_inicio: string;

  @IsString()
  @IsNotEmpty()
  hora_fin: string;

  @IsNumber()
  cupo_maximo: number;
}

class UpdateScheduleDto {
  @IsString()
  @IsOptional()
  nombre_clase?: string;

  @IsString()
  @IsOptional()
  descripcion?: string;

  @IsString()
  @IsOptional()
  trainer_id?: string;

  @IsArray()
  @IsOptional()
  @IsNumber({}, { each: true })
  dia_semana?: number[];

  @IsString()
  @IsOptional()
  hora_inicio?: string;

  @IsString()
  @IsOptional()
  hora_fin?: string;

  @IsNumber()
  @IsOptional()
  cupo_maximo?: number;

  @IsBoolean()
  @IsOptional()
  activo?: boolean;
}

@Controller('schedules')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class SchedulesController {
  constructor(private readonly schedulesService: SchedulesService) {}

  @Get()
  @Roles(Role.ADMIN, Role.CAJA, Role.TRAINER, Role.MEMBER)
  async list(@Req() req: AuthenticatedRequest) {
    return this.schedulesService.list(
      req.user.tenantId,
      req.user.sub,
      req.user.rol,
    );
  }

  @Post(':id/book')
  @Roles(Role.MEMBER)
  async book(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: BookingDto,
  ) {
    return this.schedulesService.book(
      req.user.sub,
      req.user.tenantId,
      id,
      dto.fecha,
    );
  }

  @Post(':id/cancel')
  @Roles(Role.MEMBER)
  async cancel(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: BookingDto,
  ) {
    return this.schedulesService.cancel(
      req.user.sub,
      req.user.tenantId,
      id,
      dto.fecha,
    );
  }

  @Get('trainers')
  @Roles(Role.ADMIN)
  async listTrainers(@Req() req: AuthenticatedRequest) {
    return this.schedulesService.listTrainers(req.user.tenantId);
  }

  @Post()
  @Roles(Role.ADMIN)
  async create(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateScheduleDto,
  ) {
    return this.schedulesService.create(req.user.tenantId, dto);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  async update(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdateScheduleDto,
  ) {
    return this.schedulesService.update(req.user.tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(Role.ADMIN)
  async delete(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.schedulesService.delete(req.user.tenantId, id);
  }
}
