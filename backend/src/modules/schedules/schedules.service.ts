import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SchedulesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(tenantId: string) {
    return this.prisma.schedule.findMany({
      where: { tenant_id: tenantId, activo: true },
      include: {
        bookings: true,
      },
      orderBy: [{ hora_inicio: 'asc' }, { nombre_clase: 'asc' }],
    });
  }
}
