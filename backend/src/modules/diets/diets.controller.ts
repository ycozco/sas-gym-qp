import type { AuthenticatedRequest } from '../../core/types/authenticated-request';
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
  async create(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateDietPlanDto,
  ) {
    const tenantId = req.user.tenantId;
    return this.dietsService.create(
      tenantId,
      {
        userId: req.user.sub,
        role: req.user.rol,
      },
      dto,
    );
  }

  @Get()
  @Roles(Role.ADMIN, Role.TRAINER)
  async list(
    @Req() req: AuthenticatedRequest,
    @Query('memberId') memberId?: string,
  ) {
    const tenantId = req.user.tenantId;
    return this.dietsService.findAll(
      tenantId,
      {
        userId: req.user.sub,
        role: req.user.rol,
      },
      memberId,
    );
  }

  @Get('me')
  @Roles(Role.MEMBER)
  async getMyDiet(@Req() req: AuthenticatedRequest) {
    const memberId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.dietsService.findActiveForMember(memberId, tenantId);
  }

  @Patch(':id')
  @Roles(Role.ADMIN, Role.TRAINER)
  async update(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdateDietPlanDto,
  ) {
    const tenantId = req.user.tenantId;
    return this.dietsService.update(
      tenantId,
      id,
      {
        userId: req.user.sub,
        role: req.user.rol,
      },
      dto,
    );
  }

  @Delete(':id')
  @Roles(Role.ADMIN, Role.TRAINER)
  async deactivate(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    const tenantId = req.user.tenantId;
    return this.dietsService.deactivate(tenantId, id, {
      userId: req.user.sub,
      role: req.user.rol,
    });
  }
}
