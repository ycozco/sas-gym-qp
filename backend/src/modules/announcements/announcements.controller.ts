import { Controller, Get, Post, Put, Patch, Param, Body, UseGuards, Request } from '@nestjs/common';
import { AnnouncementsService } from './announcements.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { TenantId } from '../../core/decorators/tenant-id.decorator';
import { Role } from '@prisma/client';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { UpdateAnnouncementDto } from './dto/update-announcement.dto';

@Controller('announcements')
@UseGuards(AuthGuard, RolesGuard)
export class AnnouncementsController {
  constructor(private readonly service: AnnouncementsService) {}

  @Get()
  @Roles(Role.ADMIN, Role.CAJA, Role.TRAINER, Role.MEMBER)
  async getActiveBanners(@TenantId() tenantId: string) {
    return this.service.findActive(tenantId);
  }

  @Get('all')
  @Roles(Role.ADMIN)
  async getAllBanners(@TenantId() tenantId: string) {
    return this.service.findAll(tenantId);
  }

  @Post()
  @Roles(Role.ADMIN)
  async createBanner(
    @TenantId() tenantId: string,
    @Request() req: any,
    @Body() dto: CreateAnnouncementDto
  ) {
    const authorId = req.user.sub;
    return this.service.create(tenantId, authorId, dto);
  }

  @Put(':id')
  @Roles(Role.ADMIN)
  async updateBanner(
    @Param('id') id: string,
    @TenantId() tenantId: string,
    @Body() dto: UpdateAnnouncementDto
  ) {
    return this.service.update(id, tenantId, dto);
  }

  @Patch(':id/toggle')
  @Roles(Role.ADMIN)
  async toggleActive(
    @Param('id') id: string,
    @TenantId() tenantId: string
  ) {
    return this.service.toggle(id, tenantId);
  }
}
