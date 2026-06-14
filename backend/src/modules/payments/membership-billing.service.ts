import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PaymentMethod, PaymentState, MembershipState } from '@prisma/client';
import { MembershipPlansService } from '../membership-plans/membership-plans.service';
import {
  IsString,
  IsNumber,
  IsUUID,
  IsOptional,
  IsArray,
  ValidateNested,
  IsPositive,
  Min,
  Max,
  IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';

export class PaymentMethodDto {
  @IsString()
  metodo: string; // CASH | TRANSFER | MANUAL_YAPE | MANUAL_PLIN | POS | GATEWAY

  @IsNumber()
  @IsPositive()
  monto: number;
}

export class RegisterMembershipSaleDto {
  @IsUUID()
  userId: string;

  @IsOptional()
  @IsUUID()
  planId?: string;

  @IsOptional()
  @IsString()
  planNombre?: string;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  duracionDias?: number;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  monto?: number; // Precio base del plan

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  descuentoPorcentaje?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  descuentoMonto?: number;

  @IsUUID()
  ventaToken: string; // UUID obligatorio del cliente

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaymentMethodDto)
  pagos: PaymentMethodDto[];

  @IsOptional()
  @IsDateString()
  fechaInicio?: string; // YYYY-MM-DD

  @IsOptional()
  @IsDateString()
  fechaVencimiento?: string; // YYYY-MM-DD

  @IsOptional()
  @IsString()
  observaciones?: string;
}

@Injectable()
export class MembershipBillingService {
  constructor(
    private prisma: PrismaService,
    private membershipPlansService: MembershipPlansService,
  ) {}

  async registerMembershipSale(
    cashierId: string,
    tenantId: string,
    dto: RegisterMembershipSaleDto,
  ) {
    const {
      userId,
      planId,
      descuentoPorcentaje = 0,
      descuentoMonto = 0,
      ventaToken,
      pagos,
      fechaInicio,
      fechaVencimiento,
      observaciones = '',
    } = dto;

    let planNombre = dto.planNombre?.trim();
    let duracionDias = dto.duracionDias;
    let monto = dto.monto;

    if (planId) {
      const plan = await this.membershipPlansService.findActiveForSale(
        tenantId,
        planId,
      );
      planNombre = plan.nombre;
      duracionDias = plan.duracion_dias;
      monto = plan.precio;
    }

    if (!planNombre || !duracionDias || monto === undefined || monto === null) {
      throw new BadRequestException(
        'Debes seleccionar un plan valido o enviar nombre, duracion y monto.',
      );
    }

    if (!ventaToken) {
      throw new BadRequestException(
        'El token de venta (ventaToken) es obligatorio.',
      );
    }

    // 1. ===== PREVENCIÓN DE DOBLE SUBMIT (UUID Check) =====
    const existingPayment = await this.prisma.payment.findFirst({
      where: {
        venta_token: ventaToken,
      },
    });

    if (existingPayment) {
      throw new BadRequestException(
        'Esta venta ya fue registrada recientemente. Por favor espera unos segundos.',
      );
    }

    // 2. ===== PREVENCIÓN DE DOBLE SUBMIT (5 Seconds identical transaction check) =====
    // Obtener caja abierta para el cajero
    const activeCaja = await this.prisma.caja.findFirst({
      where: {
        cajero_id: cashierId,
        tenant_id: tenantId,
        estado: 'abierta',
      },
    });

    if (!activeCaja) {
      throw new BadRequestException('El cajero no tiene una caja abierta.');
    }

    const fiveSecondsAgo = new Date(Date.now() - 5000);
    const recentDuplicate = await this.prisma.membership.findFirst({
      where: {
        user_id: userId,
        tenant_id: tenantId,
        plan_nombre: planNombre,
        created_at: {
          gte: fiveSecondsAgo,
        },
        payments: {
          some: {
            caja_id: activeCaja.id,
            estado: PaymentState.APPROVED,
          },
        },
      },
    });

    if (recentDuplicate) {
      throw new BadRequestException(
        'Venta duplicada detectada. Ya se registró una venta similar hace poco.',
      );
    }

    // 3. ===== VALIDACIONES Y CÁLCULO DE DESCUENTOS =====
    if (descuentoPorcentaje < 0 || descuentoPorcentaje > 100) {
      throw new BadRequestException(
        'El porcentaje de descuento debe estar entre 0 y 100.',
      );
    }
    if (descuentoMonto < 0) {
      throw new BadRequestException(
        'El descuento en monto no puede ser negativo.',
      );
    }

    let precioFinal = monto;
    if (descuentoPorcentaje > 0) {
      precioFinal -= monto * (descuentoPorcentaje / 100);
    }
    if (descuentoMonto > 0) {
      precioFinal -= descuentoMonto;
    }
    precioFinal = Math.max(0, precioFinal);

    if (!pagos || pagos.length === 0) {
      throw new BadRequestException(
        'Debes ingresar al menos un método de pago.',
      );
    }

    const totalPagado = pagos.reduce((sum, p) => sum + p.monto, 0);
    if (totalPagado <= 0) {
      throw new BadRequestException(
        'El monto total de pago debe ser mayor a cero.',
      );
    }

    const pagoCompleto = totalPagado >= precioFinal;
    const montoPendiente = Math.max(0, precioFinal - totalPagado);

    // 4. ===== CONFIGURACIÓN DE FECHAS =====
    let startDt = new Date();
    if (fechaInicio) {
      startDt = new Date(fechaInicio);
      startDt.setHours(0, 0, 0, 0);
    } else {
      startDt.setHours(0, 0, 0, 0);
    }

    let endDt = new Date(startDt);
    if (fechaVencimiento) {
      endDt = new Date(fechaVencimiento);
      endDt.setHours(23, 59, 59, 999);
    } else {
      endDt.setDate(startDt.getDate() + duracionDias);
      endDt.setHours(23, 59, 59, 999);
    }

    // Buscar el socio receptor
    const member = await this.prisma.user.findFirst({
      where: {
        id: userId,
        tenant_id: tenantId,
      },
    });

    if (!member) {
      throw new NotFoundException('Socio no encontrado.');
    }

    // 5. ===== CREAR MEMBRESÍA Y PAGOS (Transacciones de Caja) =====
    const membership = await this.prisma.membership.create({
      data: {
        tenant_id: tenantId,
        user_id: userId,
        plan_id: planId ?? null,
        plan_nombre: planNombre,
        duracion_dias: duracionDias,
        monto: monto,
        descuento_porcentaje: descuentoPorcentaje,
        descuento_monto: descuentoMonto,
        precio_pagado: totalPagado,
        monto_pendiente: montoPendiente,
        pago_completo: pagoCompleto,
        estado: MembershipState.ACTIVE,
        fecha_inicio: startDt,
        fecha_vencimiento: endDt,
      },
    });

    // Registrar cada sub-pago (pago mixto)
    for (let i = 0; i < pagos.length; i++) {
      const p = pagos[i];
      // El primer pago obtiene el token original del cliente.
      // Los pagos siguientes obtienen tokens generados para cumplir la restricción @unique
      const token = i === 0 ? ventaToken : `${ventaToken}_part_${i}`;

      let metodoEnum: PaymentMethod = PaymentMethod.CASH;
      const mLower = p.metodo.toUpperCase();
      if (mLower === 'TRANSFER') metodoEnum = PaymentMethod.TRANSFER;
      else if (mLower === 'MANUAL_YAPE') metodoEnum = PaymentMethod.MANUAL_YAPE;
      else if (mLower === 'MANUAL_PLIN') metodoEnum = PaymentMethod.MANUAL_PLIN;
      else if (mLower === 'POS') metodoEnum = PaymentMethod.POS;
      else if (mLower === 'GATEWAY') metodoEnum = PaymentMethod.GATEWAY;

      const payment = await this.prisma.payment.create({
        data: {
          tenant_id: tenantId,
          membership_id: membership.id,
          registrado_por_id: cashierId,
          monto: p.monto,
          metodo: metodoEnum,
          estado: PaymentState.APPROVED,
          caja_id: activeCaja.id,
          venta_token: token,
        },
      });

      // Registrar movimiento de ingreso en la caja
      await this.prisma.movimientoCaja.create({
        data: {
          caja_id: activeCaja.id,
          tipo: 'ingreso',
          monto: p.monto,
          descripcion: `Venta membresía (${p.metodo.toLowerCase()}): ${planNombre} - ${member.nombre_completo}`,
        },
      });
    }

    // Asegurar que el socio quede activo en el sistema
    await this.prisma.user.update({
      where: { id: userId },
      data: { estado: 'ACTIVE' },
    });

    // 6. ===== ACUMULACIÓN DE PUNTOS =====
    let puntosGanados = 0;
    try {
      puntosGanados = await this.accumulatePoints(
        userId,
        tenantId,
        totalPagado,
        `Compra de membresía: ${planNombre}`,
      );
    } catch (err) {
      console.error('Error al acumular puntos de fidelización:', err);
    }

    return {
      success: true,
      membershipId: membership.id,
      montoPagado: totalPagado,
      montoPendiente: montoPendiente,
      pagoCompleto: pagoCompleto,
      puntosGanados,
    };
  }

  private async accumulatePoints(
    userId: string,
    tenantId: string,
    totalPagado: number,
    descripcion: string,
  ): Promise<number> {
    // Obtener la configuración activa de puntos
    const config = await this.prisma.pointsConfig.findFirst({
      where: { activo: true },
    });

    const factor = config ? config.puntos_por_sol : 1.0;
    const puntos = Math.floor(totalPagado * factor);

    if (puntos <= 0) return 0;

    // Buscar o inicializar balance de puntos del usuario
    let balance = await this.prisma.pointsBalance.findUnique({
      where: { usuario_id: userId },
    });

    if (!balance) {
      balance = await this.prisma.pointsBalance.create({
        data: {
          usuario_id: userId,
          puntos_disponibles: 0,
          puntos_totales_ganados: 0,
        },
      });
    }

    const saldoAnterior = balance.puntos_disponibles;
    const saldoNuevo = saldoAnterior + puntos;

    // Actualizar balance
    await this.prisma.pointsBalance.update({
      where: { id: balance.id },
      data: {
        puntos_disponibles: saldoNuevo,
        puntos_totales_ganados: balance.puntos_totales_ganados + puntos,
      },
    });

    // Registrar movimiento de puntos
    await this.prisma.pointsMovement.create({
      data: {
        tenant_id: tenantId,
        usuario_id: userId,
        tipo: 'ingreso',
        cantidad: puntos,
        saldo_anterior: saldoAnterior,
        saldo_nuevo: saldoNuevo,
        descripcion: descripcion,
      },
    });

    return puntos;
  }
}
