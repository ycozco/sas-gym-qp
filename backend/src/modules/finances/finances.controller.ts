import type { AuthenticatedRequest } from '../../core/types/authenticated-request';
import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from '../../core/decorators/roles.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { FinancesService } from './finances.service';
import { IsString, IsNotEmpty, IsNumber, IsOptional } from 'class-validator';

class CreateExpenseDto {
  @IsNumber()
  monto: number;

  @IsString()
  @IsNotEmpty()
  descripcion: string;

  @IsString()
  @IsOptional()
  categoria?: string;

  @IsString()
  @IsOptional()
  fecha?: string;

  @IsString()
  @IsOptional()
  metodo_pago?: string;
}

class GeneratePayrollDto {
  @IsString()
  @IsNotEmpty()
  trainer_id: string;

  @IsNumber()
  monto_sueldo: number;

  @IsNumber()
  mes: number;

  @IsNumber()
  anio: number;
}

@Controller('finances')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class FinancesController {
  constructor(private readonly financesService: FinancesService) {}

  @Get('summary')
  @Roles(Role.ADMIN)
  async summary(@Req() req: AuthenticatedRequest) {
    return this.financesService.summary(req.user.tenantId);
  }

  @Get('expenses')
  @Roles(Role.ADMIN)
  async listExpenses(@Req() req: AuthenticatedRequest) {
    return this.financesService.listExpenses(req.user.tenantId);
  }

  @Post('expenses')
  @Roles(Role.ADMIN)
  async createExpense(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateExpenseDto,
  ) {
    return this.financesService.createExpense(req.user.tenantId, dto);
  }

  @Get('payroll')
  @Roles(Role.ADMIN)
  async listPayroll(@Req() req: AuthenticatedRequest) {
    return this.financesService.listPayroll(req.user.tenantId);
  }

  @Post('payroll')
  @Roles(Role.ADMIN)
  async generatePayroll(
    @Req() req: AuthenticatedRequest,
    @Body() dto: GeneratePayrollDto,
  ) {
    return this.financesService.generatePayroll(req.user.tenantId, dto);
  }

  @Post('payroll/:id/pay')
  @Roles(Role.ADMIN)
  async payPayroll(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.financesService.payPayroll(req.user.tenantId, id);
  }
}
