import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { CreateSaasPlanDto, UpdateSaasPlanDto } from './dto/saas-plan.dto';
import { SaasPlansService } from './saas-plans.service';

@Controller('saas-plans')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class SaasPlansController {
  constructor(private readonly saasPlansService: SaasPlansService) {}

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  list(@Query('includeInactive') includeInactive?: string) {
    return this.saasPlansService.list(includeInactive === 'true');
  }

  @Post()
  @Roles(Role.SUPER_ADMIN)
  create(@Body() dto: CreateSaasPlanDto) {
    return this.saasPlansService.create(dto);
  }

  @Patch(':code')
  @Roles(Role.SUPER_ADMIN)
  update(@Param('code') code: string, @Body() dto: UpdateSaasPlanDto) {
    return this.saasPlansService.update(code, dto);
  }

  @Delete(':code')
  @Roles(Role.SUPER_ADMIN)
  deactivate(@Param('code') code: string) {
    return this.saasPlansService.deactivate(code);
  }
}
