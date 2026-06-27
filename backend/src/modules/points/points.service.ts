import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PointsService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── RESUMEN GENERAL DEL TENANT ──────────────────────────────────
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
      availablePoints: balances.reduce(
        (sum, row) => sum + row.puntos_disponibles,
        0,
      ),
      earnedPoints: balances.reduce(
        (sum, row) => sum + row.puntos_totales_ganados,
        0,
      ),
      redeemedPoints: balances.reduce(
        (sum, row) => sum + row.puntos_totales_canjeados,
        0,
      ),
      exchanges,
      movements,
    };
  }

  // ─── CATÁLOGO DE CANJES ───────────────────────────────────────────
  async catalog(tenantId: string) {
    const [products, memberships] = await Promise.all([
      this.prisma.pointsProduct.findMany({
        where: { activo: true, tenant_id: tenantId },
        orderBy: [{ destacado: 'desc' }, { precio_puntos: 'asc' }],
      }),
      this.prisma.pointsMembership.findMany({
        where: { activo: true, tenant_id: tenantId },
        orderBy: [{ destacada: 'desc' }, { precio_puntos: 'asc' }],
      }),
    ]);

    return { products, memberships };
  }

  // ─── RESUMEN PERSONAL DEL MIEMBRO ─────────────────────────────────
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

  // ─── CONFIGURACIÓN DE PUNTOS DEL TENANT ──────────────────────────
  async getConfig(tenantId: string) {
    const config = await this.prisma.pointsConfig.findUnique({
      where: { tenant_id: tenantId },
    });
    if (!config) {
      return {
        tenant_id: tenantId,
        activo: false,
        puntos_por_sol: 1.0,
        minimo_para_canje: 100,
        puntos_expiran: false,
        dias_expiracion: 365,
      };
    }
    return config;
  }

  async updateConfig(
    tenantId: string,
    dto: {
      activo?: boolean;
      puntosPorSol?: number;
      minCanje?: number;
      vencimientoDias?: number | null;
    },
  ) {
    const data: Record<string, unknown> = {};
    if (dto.activo !== undefined) data.activo = dto.activo;
    if (dto.puntosPorSol !== undefined)
      data.puntos_por_sol = Number(dto.puntosPorSol);
    if (dto.minCanje !== undefined)
      data.minimo_para_canje = Number(dto.minCanje);
    if (dto.vencimientoDias !== undefined) {
      data.puntos_expiran = dto.vencimientoDias !== null;
      if (dto.vencimientoDias !== null) {
        data.dias_expiracion = Number(dto.vencimientoDias);
      }
    }

    return this.prisma.pointsConfig.upsert({
      where: { tenant_id: tenantId },
      create: {
        tenant_id: tenantId,
        activo: dto.activo ?? false,
        puntos_por_sol: Number(dto.puntosPorSol ?? 1),
        minimo_para_canje: Number(dto.minCanje ?? 100),
        puntos_expiran: dto.vencimientoDias !== null,
        dias_expiracion: dto.vencimientoDias ?? 365,
      },
      update: data,
    });
  }

  // ─── LEADERBOARD ──────────────────────────────────────────────────
  async leaderboard(tenantId: string, limit = 10) {
    const balances = await this.prisma.pointsBalance.findMany({
      where: { usuario: { tenant_id: tenantId } },
      include: {
        usuario: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            foto_url: true,
          },
        },
      },
      orderBy: { puntos_totales_ganados: 'desc' },
      take: Math.min(limit, 50),
    });

    return balances.map((b, idx) => ({
      rank: idx + 1,
      userId: b.usuario_id,
      nombre: `${b.usuario.nombre} ${b.usuario.apellido ?? ''}`.trim(),
      fotoUrl: b.usuario.foto_url,
      puntosDisponibles: b.puntos_disponibles,
      puntosTotales: b.puntos_totales_ganados,
      puntosCanjeados: b.puntos_totales_canjeados,
    }));
  }

  // ─── AGREGAR PUNTOS MANUALMENTE (ADMIN) ───────────────────────────
  async adminAddPoints(
    tenantId: string,
    dto: {
      userId: string;
      puntos: number;
      descripcion: string;
    },
  ) {
    if (!Number.isInteger(dto.puntos) || dto.puntos <= 0) {
      throw new BadRequestException('Los puntos deben ser un entero positivo.');
    }

    // Verificar que el usuario pertenece al tenant
    const user = await this.prisma.user.findFirst({
      where: { id: dto.userId, tenant_id: tenantId },
    });
    if (!user)
      throw new NotFoundException('Usuario no encontrado en este gimnasio.');

    const balance = await this.prisma.pointsBalance.upsert({
      where: { usuario_id: dto.userId },
      create: {
        usuario_id: dto.userId,
        puntos_disponibles: dto.puntos,
        puntos_totales_ganados: dto.puntos,
        puntos_totales_canjeados: 0,
      },
      update: {
        puntos_disponibles: { increment: dto.puntos },
        puntos_totales_ganados: { increment: dto.puntos },
      },
    });

    await this.prisma.pointsMovement.create({
      data: {
        tenant_id: tenantId,
        usuario_id: dto.userId,
        tipo: 'ajuste_manual',
        cantidad: dto.puntos,
        saldo_anterior: balance.puntos_disponibles - dto.puntos,
        saldo_nuevo: balance.puntos_disponibles,
        descripcion: dto.descripcion,
      },
    });

    return { success: true, balance };
  }

  // ─── REDIMIR PUNTOS (MEMBER) ──────────────────────────────────────
  async redeem(
    userId: string,
    tenantId: string,
    dto: {
      tipo: 'producto' | 'membresia';
      itemId: string;
      cantidad?: number;
      notas?: string;
    },
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
        where: { id: dto.itemId, activo: true, tenant_id: tenantId },
      });
      if (!product)
        throw new NotFoundException('Producto de puntos no encontrado.');
      if (product.stock > 0 && product.stock < quantity) {
        throw new BadRequestException('No hay stock suficiente para el canje.');
      }
      pointsCost = product.precio_puntos * quantity;
      productId = product.id;
      description = `Canje de producto: ${product.nombre}`;
    } else {
      const membership = await this.prisma.pointsMembership.findFirst({
        where: { id: dto.itemId, activo: true, tenant_id: tenantId },
      });
      if (!membership)
        throw new NotFoundException('Membresía de puntos no encontrada.');
      if (membership.stock > 0 && membership.stock < quantity) {
        throw new BadRequestException(
          'No hay stock suficiente para este canje.',
        );
      }
      pointsCost = membership.precio_puntos * quantity;
      membershipId = membership.id;
      description = `Canje de membresía: ${membership.nombre}`;
    }

    if (balance.puntos_disponibles < pointsCost) {
      throw new BadRequestException(
        'Puntos insuficientes para realizar el canje.',
      );
    }

    const nextBalance = balance.puntos_disponibles - pointsCost;

    return this.prisma.$transaction(async (tx) => {
      const exchange = await tx.pointsExchange.create({
        data: {
          tenant_id: tenantId,
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
          tenant_id: tenantId,
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
          data: { stock: { decrement: quantity } },
        });
      }

      if (membershipId) {
        const mem = await tx.pointsMembership.findUnique({
          where: { id: membershipId },
        });
        if (mem && mem.stock > 0) {
          await tx.pointsMembership.update({
            where: { id: membershipId },
            data: { stock: { decrement: quantity } },
          });
        }
      }

      return {
        success: true,
        exchange,
        balance: {
          ...balance,
          puntos_disponibles: nextBalance,
          puntos_totales_canjeados:
            balance.puntos_totales_canjeados + pointsCost,
        },
      };
    });
  }
}
