import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { RoutinesService } from './routines.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

class CreateExerciseDto {
  @IsString()
  nombre: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsString()
  grupoMuscular: string;

  @IsOptional()
  @IsString()
  imagenUrl?: string;

  @IsOptional()
  @IsString()
  animacionUrl?: string;
}

class RoutineTemplateExerciseDto {
  @IsUUID()
  exerciseId: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  orden?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  series?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  repeticiones?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  pesoSugeridoKg?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  descansoSeg?: number;
}

class CreateRoutineTemplateDto {
  @IsString()
  nombre: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RoutineTemplateExerciseDto)
  ejercicios: RoutineTemplateExerciseDto[];
}

class AssignRoutineDto {
  @IsUUID()
  memberUserId: string;

  @IsUUID()
  templateId: string;

  @IsOptional()
  @IsObject()
  agendaSemanal?: Record<string, string>;

  @IsOptional()
  @IsBoolean()
  publicada?: boolean;
}

@Controller('routines')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class RoutinesController {
  constructor(private readonly routinesService: RoutinesService) {}

  @Get('active')
  @Roles(Role.MEMBER)
  async getActiveRoutine(@Req() req: any) {
    const userId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.routinesService.getActiveRoutine(userId, tenantId);
  }

  @Get('trainer/exercises')
  @Roles(Role.TRAINER, Role.ADMIN)
  async listExercises(@Req() req: any) {
    return this.routinesService.listExercises(req.user.sub, req.user.tenantId);
  }

  @Post('trainer/exercises')
  @Roles(Role.TRAINER, Role.ADMIN)
  async createExercise(@Req() req: any, @Body() dto: CreateExerciseDto) {
    return this.routinesService.createExercise(
      req.user.sub,
      req.user.tenantId,
      dto,
    );
  }

  @Get('trainer/templates')
  @Roles(Role.TRAINER, Role.ADMIN)
  async listTemplates(@Req() req: any) {
    return this.routinesService.listTemplates(req.user.sub, req.user.tenantId);
  }

  @Post('trainer/templates')
  @Roles(Role.TRAINER, Role.ADMIN)
  async createTemplate(@Req() req: any, @Body() dto: CreateRoutineTemplateDto) {
    return this.routinesService.createTemplate(
      req.user.sub,
      req.user.tenantId,
      dto,
    );
  }

  @Post('trainer/assign')
  @Roles(Role.TRAINER, Role.ADMIN)
  async assignRoutine(@Req() req: any, @Body() dto: AssignRoutineDto) {
    return this.routinesService.assignRoutine(
      req.user.sub,
      req.user.tenantId,
      dto,
    );
  }

  @Get('trainer/progress')
  @Roles(Role.TRAINER, Role.ADMIN)
  async getTrainerProgress(@Req() req: any) {
    return this.routinesService.getTrainerProgress(
      req.user.sub,
      req.user.tenantId,
    );
  }
}
