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
import {
  CreateMembershipPlanDto,
  UpdateMembershipPlanDto,
} from './dto/membership-plan.dto';
import { MembershipPlansService } from './membership-plans.service';

@Controller('membership-plans')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class MembershipPlansController {
  constructor(
    private readonly membershipPlansService: MembershipPlansService,
  ) {}

  @Get()
  @Roles(Role.ADMIN, Role.CAJA, Role.TRAINER, Role.MEMBER, Role.SUPER_ADMIN)
  async list(
    @Req() req: any,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.membershipPlansService.list(
      req.user.tenantId,
      includeInactive === 'true' &&
        (req.user.rol === Role.ADMIN || req.user.rol === Role.SUPER_ADMIN),
    );
  }

  @Post()
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async create(@Req() req: any, @Body() dto: CreateMembershipPlanDto) {
    return this.membershipPlansService.create(
      req.user.tenantId,
      req.user.sub,
      dto,
    );
  }

  @Patch(':id')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async update(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateMembershipPlanDto,
  ) {
    return this.membershipPlansService.update(req.user.tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async deactivate(@Req() req: any, @Param('id') id: string) {
    return this.membershipPlansService.deactivate(req.user.tenantId, id);
  }
}
