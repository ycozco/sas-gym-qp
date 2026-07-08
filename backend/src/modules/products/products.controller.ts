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
import { ProductsService, UpsertProductDto } from './products.service';

@Controller('products')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  @Roles(Role.ADMIN, Role.CAJA)
  list(
    @Req() req: AuthenticatedRequest,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.productsService.list(
      req.user.tenantId,
      includeInactive === 'true',
    );
  }

  @Post()
  @Roles(Role.ADMIN)
  create(@Req() req: AuthenticatedRequest, @Body() dto: UpsertProductDto) {
    return this.productsService.create(req.user.tenantId, dto);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: Partial<UpsertProductDto>,
  ) {
    return this.productsService.update(req.user.tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(Role.ADMIN)
  deactivate(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.productsService.deactivate(req.user.tenantId, id);
  }
}
