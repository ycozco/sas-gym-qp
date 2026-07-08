import type { AuthenticatedRequest } from '../../core/types/authenticated-request';
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { CrmService } from './crm.service';
import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

class CreateLeadDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  celular?: string;

  @IsString()
  @IsOptional()
  origen?: string;

  @IsString()
  @IsOptional()
  estado?: string;

  @IsString()
  @IsOptional()
  notas?: string;
}

class UpdateLeadDto {
  @IsString()
  @IsOptional()
  nombre?: string;

  @IsString()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  celular?: string;

  @IsString()
  @IsOptional()
  origen?: string;

  @IsString()
  @IsOptional()
  estado?: string;

  @IsString()
  @IsOptional()
  notas?: string;
}

class CreateCampaignDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsOptional()
  descripcion?: string;

  @IsString()
  @IsNotEmpty()
  canal: string;
}

@Controller('crm')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class CrmController {
  constructor(private readonly crmService: CrmService) {}

  @Get('leads')
  @Roles(Role.ADMIN)
  async listLeads(@Req() req: AuthenticatedRequest) {
    return this.crmService.listLeads(req.user.tenantId);
  }

  @Post('leads')
  @Roles(Role.ADMIN)
  async createLead(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateLeadDto,
  ) {
    return this.crmService.createLead(req.user.tenantId, dto);
  }

  @Patch('leads/:id')
  @Roles(Role.ADMIN)
  async updateLead(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdateLeadDto,
  ) {
    return this.crmService.updateLead(req.user.tenantId, id, dto);
  }

  @Delete('leads/:id')
  @Roles(Role.ADMIN)
  async deleteLead(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.crmService.deleteLead(req.user.tenantId, id);
  }

  @Get('campaigns')
  @Roles(Role.ADMIN)
  async listCampaigns(@Req() req: AuthenticatedRequest) {
    return this.crmService.listCampaigns(req.user.tenantId);
  }

  @Post('campaigns')
  @Roles(Role.ADMIN)
  async createCampaign(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateCampaignDto,
  ) {
    return this.crmService.createCampaign(req.user.tenantId, dto);
  }

  @Post('campaigns/:id/send')
  @Roles(Role.ADMIN)
  async sendCampaign(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.crmService.sendCampaign(req.user.tenantId, id);
  }
}
