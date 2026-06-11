import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
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

  async memberSummary(userId: string, tenantId: string) {
    const [balance, exchanges, movements] = await Promise.all([
      this.prisma.pointsBalance.findUnique({
        where: { usuario_id: userId },
      }),
      this.prisma.pointsExchange.findMany({
        where: { usuario_id: userId, usuario: { tenant_id: tenantId } },
        include: { producto: true, membresia_puntos: true },
        orderBy: { fecha_canje: 'desc' },
        take: 20,
      }),
      this.prisma.pointsMovement.findMany({
        where: { usuario_id: userId, usuario: { tenant_id: tenantId } },
        orderBy: { created_at: 'desc' },
        take: 20,
      }),
    ]);

    return {
      balance: balance ?? {
        usuario_id: userId,
        puntos_disponibles: 0,
        puntos_totales_ganados: 0,
        puntos_totales_canjeados: 0,
      },
      exchanges,
      movements,
    };
  }

  async redeem(
    userId: string,
    tenantId: string,
    dto: { tipo: 'producto' | 'membresia'; itemId: string; cantidad?: number; notas?: string },
  ) {
    const quantity = Math.max(1, Number(dto.cantidad ?? 1));
    const balance = await this.prisma.pointsBalance.findUnique({
      where: { usuario_id: userId },
    });
    if (!balance) {
      throw new BadRequestException('El usuario no tiene saldo de puntos.');
    }

    let pointsCost = 0;
    let productId: string | null = null;
    let membershipId: string | null = null;
    let description = '';

    if (dto.tipo === 'producto') {
      const product = await this.prisma.pointsProduct.findFirst({
        where: { id: dto.itemId, activo: true },
      });
      if (!product) throw new NotFoundException('Producto de puntos no encontrado.');
      if (product.stock > 0 && product.stock < quantity) {
        throw new BadRequestException('No hay stock suficiente para el canje.');
      }
      pointsCost = product.precio_puntos * quantity;
      productId = product.id;
      description = `Canje de producto: ${product.nombre}`;
    } else {
      const membership = await this.prisma.pointsMembership.findFirst({
        where: { id: dto.itemId, activo: true },
      });
      if (!membership) throw new NotFoundException('Membresía de puntos no encontrada.');
      if (membership.stock > 0 && membership.stock < quantity) {
        throw new BadRequestException('No hay stock suficiente para este canje.');
      }
      pointsCost = membership.precio_puntos * quantity;
      membershipId = membership.id;
      description = `Canje de membresía: ${membership.nombre}`;
    }

    if (balance.puntos_disponibles < pointsCost) {
      throw new BadRequestException('Puntos insuficientes para realizar el canje.');
    }

    const nextBalance = balance.puntos_disponibles - pointsCost;

    return this.prisma.$transaction(async (tx) => {
      const exchange = await tx.pointsExchange.create({
        data: {
          usuario_id: userId,
          tipo: dto.tipo,
          producto_id: productId,
          membresia_puntos_id: membershipId,
          cantidad: quantity,
          puntos_utilizados: pointsCost,
          estado: 'completado',
          notas: dto.notas?.trim() || null,
          fecha_procesado: new Date(),
          fecha_entregado: new Date(),
        },
        include: {
          producto: true,
          membresia_puntos: true,
        },
      });

      await tx.pointsBalance.update({
        where: { usuario_id: userId },
        data: {
          puntos_disponibles: nextBalance,
          puntos_totales_canjeados: { increment: pointsCost },
        },
      });

      await tx.pointsMovement.create({
        data: {
          usuario_id: userId,
          tipo: 'canje',
          cantidad: pointsCost,
          saldo_anterior: balance.puntos_disponibles,
          saldo_nuevo: nextBalance,
          descripcion: description,
          canje_id: exchange.id,
        },
      });

      if (productId) {
        await tx.pointsProduct.update({
          where: { id: productId },
          data: {
            stock: {
              decrement: quantity,
            },
          },
        });
      }

      if (membershipId) {
        const membership = await tx.pointsMembership.findUnique({
          where: { id: membershipId },
        });
        if (membership && membership.stock > 0) {
          await tx.pointsMembership.update({
            where: { id: membershipId },
            data: {
              stock: {
                decrement: quantity,
              },
            },
          });
        }
      }

      return {
        success: true,
        exchange,
        balance: {
          ...balance,
          puntos_disponibles: nextBalance,
          puntos_totales_canjeados: balance.puntos_totales_canjeados + pointsCost,
        },
      };
    });
  }
}
