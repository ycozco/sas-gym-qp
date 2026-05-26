import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SaasGateway } from '../../core/gateways/saas.gateway';

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
