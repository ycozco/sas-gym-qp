import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role } from '@prisma/client';

@Injectable()
export class ObservationsService {
  constructor(private prisma: PrismaService) {}

  async createObservation(
    userId: string,
    tenantId: string,
    role: Role,
    texto: string,
    filename?: string,
  ) {
    return this.prisma.observation.create({
      data: {
        tenant_id: tenantId,
        author_id: userId,
        autor_rol: role,
        texto: texto,
        foto_url: filename ? `/uploads/observations/${filename}` : null,
      },
    });
  }

  async getObservations(tenantId: string) {
    return this.prisma.observation.findMany({
      where: { tenant_id: tenantId },
      orderBy: { created_at: 'desc' },
    });
  }
}
