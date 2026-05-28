import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { UpdateAnnouncementDto } from './dto/update-announcement.dto';

@Injectable()
export class AnnouncementsService {
  constructor(private readonly prisma: PrismaService) {}

  async findActive(tenantId: string) {
    return this.prisma.announcement.findMany({
      where: {
        tenant_id: tenantId,
        activo: true,
      },
      orderBy: {
        created_at: 'desc',
      },
    });
  }

  async findAll(tenantId: string) {
    return this.prisma.announcement.findMany({
      where: {
        tenant_id: tenantId,
      },
      orderBy: {
        created_at: 'desc',
      },
    });
  }

  async findOne(id: string, tenantId: string) {
    const announcement = await this.prisma.announcement.findFirst({
      where: {
        id,
        tenant_id: tenantId,
      },
    });
    if (!announcement) {
      throw new NotFoundException('Anuncio no encontrado');
    }
    return announcement;
  }

  async create(tenantId: string, authorId: string, dto: CreateAnnouncementDto) {
    return this.prisma.announcement.create({
      data: {
        tenant_id: tenantId,
        autor_id: authorId,
        titulo: dto.titulo,
        descripcion: dto.descripcion,
        imagen_url: dto.imagen_url,
        severidad: dto.severidad ?? 'INFO',
      },
    });
  }

  async update(id: string, tenantId: string, dto: UpdateAnnouncementDto) {
    const announcement = await this.findOne(id, tenantId);
    return this.prisma.announcement.update({
      where: {
        id: announcement.id,
      },
      data: {
        titulo: dto.titulo ?? announcement.titulo,
        descripcion: dto.descripcion ?? announcement.descripcion,
        imagen_url: dto.imagen_url ?? announcement.imagen_url,
        activo: dto.activo ?? announcement.activo,
        severidad: dto.severidad ?? announcement.severidad,
      },
    });
  }

  async toggle(id: string, tenantId: string) {
    const announcement = await this.findOne(id, tenantId);
    return this.prisma.announcement.update({
      where: {
        id: announcement.id,
      },
      data: {
        activo: !announcement.activo,
      },
    });
  }
}
