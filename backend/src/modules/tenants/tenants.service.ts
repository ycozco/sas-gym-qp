import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SaasGateway } from '../../core/gateways/saas.gateway';
import { UpdateTenantSettingsDto } from './dto/tenant-settings.dto';

@Injectable()
export class TenantsService {
  constructor(
    private prisma: PrismaService,
    private saasGateway: SaasGateway,
  ) {}

  async getAllTenants() {
    return this.prisma.tenant.findMany({
      orderBy: { created_at: 'desc' },
    });
  }

  async getTenantSettings(id: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id },
    });
    if (!tenant) {
      throw new NotFoundException('Tenant no encontrado.');
    }
    return tenant;
  }

  async updateTenantSettings(id: string, dto: UpdateTenantSettingsDto) {
    await this.getTenantSettings(id);

    return this.prisma.tenant.update({
      where: { id },
      data: {
        nombre: dto.nombre?.trim(),
        logo_url:
          dto.logoUrl === undefined ? undefined : dto.logoUrl.trim() || null,
        direccion:
          dto.direccion === undefined
            ? undefined
            : dto.direccion.trim() || null,
        telefono:
          dto.telefono === undefined ? undefined : dto.telefono.trim() || null,
        horario:
          dto.horario === undefined ? undefined : dto.horario.trim() || null,
        descripcion:
          dto.descripcion === undefined
            ? undefined
            : dto.descripcion.trim() || null,
        redes_sociales: dto.redesSociales as Prisma.InputJsonValue | undefined,
        color_primario: dto.colorPrimario,
        color_secundario: dto.colorSecundario,
        color_acento: dto.colorAcento,
        dias_gracia: dto.diasGracia,
        dias_alerta_vencimiento: dto.diasAlertaVencimiento,
      },
    });
  }

  async toggleTenantStatus(id: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id },
    });

    if (!tenant) {
      throw new NotFoundException('Tenant no encontrado.');
    }

    const nextState = !tenant.activo;

    const updated = await this.prisma.tenant.update({
      where: { id },
      data: { activo: nextState },
    });

    if (nextState === false) {
      this.saasGateway.emitTenantSuspended(id);
    }

    return updated;
  }
}
