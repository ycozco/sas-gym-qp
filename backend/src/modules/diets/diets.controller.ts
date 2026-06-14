import {
  Body,
  Controller,
  Delete,
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
import { CreateDietPlanDto, UpdateDietPlanDto } from './dto/diet.dto';
import { DietsService } from './diets.service';

@Controller('diets')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class DietsController {
  constructor(private readonly dietsService: DietsService) {}

  @Post()
  @Roles(Role.ADMIN, Role.TRAINER)
  async create(@Req() req: any, @Body() dto: CreateDietPlanDto) {
    const tenantId = req.user.tenantId;
    const trainerId = req.user.rol === Role.TRAINER ? req.user.sub : null;
    return this.dietsService.create(tenantId, trainerId, dto);
  }

  @Get()
  @Roles(Role.ADMIN, Role.TRAINER)
  async list(@Req() req: any, @Query('memberId') memberId?: string) {
    const tenantId = req.user.tenantId;
    return this.dietsService.findAll(tenantId, memberId);
  }

  @Get('me')
  @Roles(Role.MEMBER)
  async getMyDiet(@Req() req: any) {
    const memberId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.dietsService.findActiveForMember(memberId, tenantId);
  }

  @Patch(':id')
  @Roles(Role.ADMIN, Role.TRAINER)
  async update(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateDietPlanDto,
  ) {
    const tenantId = req.user.tenantId;
    return this.dietsService.update(tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(Role.ADMIN, Role.TRAINER)
  async deactivate(@Req() req: any, @Param('id') id: string) {
    const tenantId = req.user.tenantId;
    return this.dietsService.deactivate(tenantId, id);
  }
}
