import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PaymentMethod, PaymentState } from '@prisma/client';
import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class OpenCajaDto {
  @IsNumber()
  @Min(0)
  montoApertura: number;

  @IsOptional()
  @IsString()
  observaciones?: string;
}

export class CloseCajaDto {
  @IsNumber()
  @Min(0)
  montoCierreEfectivo: number;

  @IsNumber()
  @Min(0)
  montoCierreTransferencia: number;

  @IsNumber()
  @Min(0)
  montoCierreYape: number;

  @IsNumber()
  @Min(0)
  montoCierrePOS: number;

  @IsOptional()
  @IsString()
  observaciones?: string;
}

export class EgressDto {
  @IsNumber()
  @Min(0.01)
  monto: number;

  @IsString()
  motivo: string;

  @IsOptional()
  @IsString()
  metodoPago?: string; // 'efectivo' | 'transferencia' | 'yape' | 'pos'

  @IsOptional()
  @IsString()
  descripcionAdicional?: string;
}

@Injectable()
export class CashierSessionService {
  constructor(private prisma: PrismaService) {}

  async getActiveCaja(cajeroId: string, tenantId: string) {
    return this.prisma.caja.findFirst({
      where: {
        cajero_id: cajeroId,
        tenant_id: tenantId,
        estado: 'abierta',
      },
      include: {
        movimientos: true,
      },
    });
  }

  async openCaja(cajeroId: string, tenantId: string, dto: OpenCajaDto) {
    const existing = await this.getActiveCaja(cajeroId, tenantId);
    if (existing) {
      throw new BadRequestException('Ya tienes una caja abierta. Debes cerrarla antes de abrir una nueva.');
    }

    if (dto.montoApertura < 0) {
      throw new BadRequestException('El monto de apertura no puede ser negativo.');
    }

    const caja = await this.prisma.caja.create({
      data: {
        tenant_id: tenantId,
        cajero_id: cajeroId,
        monto_apertura: dto.montoApertura,
        estado: 'abierta',
        observaciones: dto.observaciones || '',
        total_ingresos: dto.montoApertura,
      },
    });

    // Registrar movimiento de apertura
    await this.prisma.movimientoCaja.create({
      data: {
        caja_id: caja.id,
        tipo: 'ingreso',
        monto: dto.montoApertura,
        descripcion: 'Apertura de caja - Saldo inicial',
      },
    });

    return caja;
  }

  async createEgress(cajeroId: string, tenantId: string, dto: EgressDto) {
    const caja = await this.getActiveCaja(cajeroId, tenantId);
    if (!caja) {
      throw new NotFoundException('No tienes una caja abierta actualmente.');
    }

    if (dto.monto <= 0) {
      throw new BadRequestException('El monto del egreso debe ser mayor a 0.');
    }

    const metodo = dto.metodoPago || 'efectivo';
    const desc = `Egreso - ${dto.motivo}${dto.descripcionAdicional ? ` (${dto.descripcionAdicional})` : ''} [metodo:${metodo}]`;

    const movimiento = await this.prisma.movimientoCaja.create({
      data: {
        caja_id: caja.id,
        tipo: 'egreso',
        monto: dto.monto,
        descripcion: desc,
      },
    });

    return movimiento;
  }

  async getCajaSessionDetails(cajeroId: string, tenantId: string) {
    const caja = await this.getActiveCaja(cajeroId, tenantId);
    if (!caja) {
      throw new NotFoundException('No tienes una caja abierta actualmente.');
    }

    // Obtener todos los pagos de membresías en esta caja que están aprobados
    const payments = await this.prisma.payment.findMany({
      where: {
        caja_id: caja.id,
        tenant_id: tenantId,
        estado: PaymentState.APPROVED,
      },
    });

    // Obtener todas las ventas de productos en esta caja que están completadas
    const productSales = await this.prisma.productSale.findMany({
      where: {
        caja_id: caja.id,
        tenant_id: tenantId,
        estado: 'completada',
      },
      include: {
        payment_methods: true,
      },
    });

    // Obtener todos los movimientos manuales
    const movements = await this.prisma.movimientoCaja.findMany({
      where: {
        caja_id: caja.id,
      },
      orderBy: {
        created_at: 'desc',
      },
    });

    // Calcular ingresos y egresos por método
    let efectivoIngreso = 0;
    let transferenciaIngreso = 0;
    let yapeIngreso = 0;
    let posIngreso = 0;

    let efectivoEgreso = 0;
    let transferenciaEgreso = 0;
    let yapeEgreso = 0;
    let posEgreso = 0;

    // 1. Sumar ingresos de membresías
    for (const p of payments) {
      if (p.metodo === PaymentMethod.CASH) {
        efectivoIngreso += p.monto;
      } else if (p.metodo === PaymentMethod.TRANSFER) {
        transferenciaIngreso += p.monto;
      } else if (p.metodo === PaymentMethod.MANUAL_YAPE || p.metodo === PaymentMethod.MANUAL_PLIN) {
        yapeIngreso += p.monto;
      } else if (p.metodo === PaymentMethod.POS || p.metodo === PaymentMethod.GATEWAY) {
        posIngreso += p.monto;
      }
    }

    // 2. Sumar ingresos de productos
    for (const sale of productSales) {
      for (const payDetail of sale.payment_methods) {
        const metodo = payDetail.metodo.toLowerCase();
        if (metodo === 'efectivo') {
          efectivoIngreso += payDetail.monto;
        } else if (metodo === 'transferencia') {
          transferenciaIngreso += payDetail.monto;
        } else if (metodo === 'yape' || metodo === 'plin') {
          yapeIngreso += payDetail.monto;
        } else if (metodo === 'pos' || metodo === 'tarjeta') {
          posIngreso += payDetail.monto;
        }
      }
    }

    // 3. Procesar egresos manuales
    for (const m of movements) {
      if (m.tipo === 'egreso') {
        const descLower = m.descripcion.toLowerCase();
        if (descLower.includes('[metodo:transferencia]')) {
          transferenciaEgreso += m.monto;
        } else if (descLower.includes('[metodo:yape]') || descLower.includes('[metodo:plin]')) {
          yapeEgreso += m.monto;
        } else if (descLower.includes('[metodo:pos]') || descLower.includes('[metodo:tarjeta]')) {
          posEgreso += m.monto;
        } else {
          efectivoEgreso += m.monto; // Por defecto efectivo
        }
      }
    }

    const totalVentasEfectivo = efectivoIngreso;
    const totalVentasTransferencia = transferenciaIngreso;
    const totalVentasYape = yapeIngreso;
    const totalVentasPOS = posIngreso;

    const netoEfectivo = totalVentasEfectivo - efectivoEgreso;
    const netoTransferencia = totalVentasTransferencia - transferenciaEgreso;
    const netoYape = totalVentasYape - yapeEgreso;
    const netoPOS = totalVentasPOS - posEgreso;

    const efectivoEsperado = caja.monto_apertura + netoEfectivo;
    const totalEsperado = netoEfectivo + netoTransferencia + netoYape + netoPOS;

    return {
      caja,
      movements,
      stats: {
        efectivo_ingreso: efectivoIngreso,
        efectivo_egreso: efectivoEgreso,
        transferencia_ingreso: transferenciaIngreso,
        transferencia_egreso: transferenciaEgreso,
        yape_ingreso: yapeIngreso,
        yape_egreso: yapeEgreso,
        pos_ingreso: posIngreso,
        pos_egreso: posEgreso,
        total_ventas_efectivo: totalVentasEfectivo,
        total_ventas_transferencia: totalVentasTransferencia,
        total_ventas_yape: totalVentasYape,
        total_ventas_pos: totalVentasPOS,
        efectivo_esperado: efectivoEsperado,
        total_esperado: totalEsperado,
      },
    };
  }

  async closeCaja(cajeroId: string, tenantId: string, dto: CloseCajaDto) {
    const details = await this.getCajaSessionDetails(cajeroId, tenantId);
    const { caja, stats } = details;

    const totalSistema = stats.efectivo_esperado + stats.total_ventas_transferencia - stats.transferencia_egreso +
      stats.total_ventas_yape - stats.yape_egreso + stats.total_ventas_pos - stats.pos_egreso;
    // O de forma equivalente: totalSistema = stats.efectivo_esperado + neto_transferencia + neto_yape + neto_pos
    // que es igual a caja.monto_apertura + stats.total_esperado

    const totalCierre = dto.montoCierreEfectivo + dto.montoCierreTransferencia + dto.montoCierreYape + dto.montoCierrePOS;
    const diferencia = totalCierre - (caja.monto_apertura + stats.total_esperado);

    const updatedCaja = await this.prisma.caja.update({
      where: { id: caja.id },
      data: {
        estado: 'cerrada',
        fecha_cierre: new Date(),
        monto_cierre_efectivo: dto.montoCierreEfectivo,
        monto_cierre_transferencia: dto.montoCierreTransferencia,
        monto_cierre_yape: dto.montoCierreYape,
        monto_cierre_pos: dto.montoCierrePOS,
        total_ventas_efectivo: stats.total_ventas_efectivo,
        total_ventas_transferencia: stats.total_ventas_transferencia,
        total_ventas_yape: stats.total_ventas_yape,
        total_ventas_pos: stats.total_ventas_pos,
        total_ingresos: stats.total_esperado + caja.monto_apertura, // Total ingresos incluye saldo inicial
        diferencia: diferencia,
        observaciones: dto.observaciones || caja.observaciones || '',
      },
    });

    return updatedCaja;
  }
}
