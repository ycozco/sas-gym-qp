import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PointsService {
  constructor(private readonly prisma: PrismaService) {}

  async summary(tenantId: string) {
    const [balances, exchanges, movements] = await Promise.all([
      this.prisma.pointsBalance.findMany({
        where: { usuario: { tenant_id: tenantId } },
      }),
      this.prisma.pointsExchange.findMany({
        where: { usuario: { tenant_id: tenantId } },
        include: { usuario: true, producto: true, membresia_puntos: true },
        orderBy: { fecha_canje: 'desc' },
        take: 20,
      }),
      this.prisma.pointsMovement.findMany({
        where: { usuario: { tenant_id: tenantId } },
        orderBy: { created_at: 'desc' },
        take: 20,
      }),
    ]);

    return {
      usersWithPoints: balances.length,
      availablePoints: balances.reduce((sum, row) => sum + row.puntos_disponibles, 0),
      earnedPoints: balances.reduce((sum, row) => sum + row.puntos_totales_ganados, 0),
      redeemedPoints: balances.reduce((sum, row) => sum + row.puntos_totales_canjeados, 0),
      exchanges,
      movements,
    };
  }

  async catalog() {
    const [products, memberships] = await Promise.all([
      this.prisma.pointsProduct.findMany({
        where: { activo: true },
        orderBy: [{ destacado: 'desc' }, { precio_puntos: 'asc' }],
      }),
      this.prisma.pointsMembership.findMany({
        where: { activo: true },
        orderBy: [{ destacada: 'desc' }, { precio_puntos: 'asc' }],
      }),
    ]);

    return { products, memberships };
  }
}
