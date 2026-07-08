import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CrmService {
  constructor(private readonly prisma: PrismaService) {}

  async listLeads(tenantId: string) {
    return this.prisma.lead.findMany({
      where: { tenant_id: tenantId },
      orderBy: { created_at: 'desc' },
    });
  }

  async createLead(tenantId: string, data: any) {
    return this.prisma.lead.create({
      data: {
        tenant_id: tenantId,
        nombre: data.nombre,
        email: data.email || null,
        celular: data.celular || null,
        origen: data.origen || 'Recomendado',
        estado: data.estado || 'Nuevo',
        notas: data.notas || null,
      },
    });
  }

  async updateLead(tenantId: string, id: string, data: any) {
    const existing = await this.prisma.lead.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!existing) {
      throw new NotFoundException('Lead no encontrado.');
    }
    return this.prisma.lead.update({
      where: { id },
      data: {
        nombre: data.nombre !== undefined ? data.nombre : existing.nombre,
        email: data.email !== undefined ? data.email : existing.email,
        celular: data.celular !== undefined ? data.celular : existing.celular,
        origen: data.origen !== undefined ? data.origen : existing.origen,
        estado: data.estado !== undefined ? data.estado : existing.estado,
        notas: data.notas !== undefined ? data.notas : existing.notas,
      },
    });
  }

  async deleteLead(tenantId: string, id: string) {
    const existing = await this.prisma.lead.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!existing) {
      throw new NotFoundException('Lead no encontrado.');
    }
    return this.prisma.lead.delete({
      where: { id },
    });
  }

  async listCampaigns(tenantId: string) {
    return this.prisma.campaign.findMany({
      where: { tenant_id: tenantId },
      orderBy: { created_at: 'desc' },
    });
  }

  async createCampaign(tenantId: string, data: any) {
    return this.prisma.campaign.create({
      data: {
        tenant_id: tenantId,
        nombre: data.nombre,
        descripcion: data.descripcion || '',
        canal: data.canal || 'Push',
        estado: 'Programada',
        alcance: 0,
      },
    });
  }

  async sendCampaign(tenantId: string, id: string) {
    const existing = await this.prisma.campaign.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!existing) {
      throw new NotFoundException('Campaña no encontrada.');
    }

    // Calcular alcance estimado basado en miembros + leads
    const [memberCount, leadCount] = await Promise.all([
      this.prisma.user.count({
        where: { tenant_id: tenantId, rol: 'MEMBER', estado: 'ACTIVE' },
      }),
      this.prisma.lead.count({ where: { tenant_id: tenantId } }),
    ]);

    const totalReach = memberCount + leadCount;

    return this.prisma.campaign.update({
      where: { id },
      data: {
        estado: 'Finalizada',
        alcance: totalReach,
        fecha_envio: new Date(),
      },
    });
  }
}
