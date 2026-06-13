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
import { SchedulesService } from './schedules.service';
import { IsDateString, IsOptional } from 'class-validator';

class BookingDto {
  @IsOptional()
  @IsDateString()
  fecha?: string;
}

@Controller('schedules')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class SchedulesController {
  constructor(private readonly schedulesService: SchedulesService) {}

  @Get()
  @Roles(Role.ADMIN, Role.CAJA, Role.TRAINER, Role.MEMBER)
  async list(@Req() req: any) {
    return this.schedulesService.list(
      req.user.tenantId,
      req.user.sub,
      req.user.rol,
    );
  }

  @Post(':id/book')
  @Roles(Role.MEMBER)
  async book(
    @Req() req: any,
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
    @Req() req: any,
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
}
