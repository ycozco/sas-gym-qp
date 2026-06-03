import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PaymentMethod, PaymentState, MembershipState, Role, UserState } from '@prisma/client';
import { IsString, IsArray, IsNumber, IsPositive, IsOptional } from 'class-validator';

export class ChargePosDto {
  @IsString()
  memberDni: string;

  @IsArray()
  cartItems: any[];

  @IsNumber()
  @IsPositive()
  total: number;

  @IsString()
  paymentMethod: string;

  @IsOptional()
  @IsArray()
  payments?: any[];
}

@Injectable()
export class PaymentsService {
  constructor(private prisma: PrismaService) {}

  async uploadReceipt(
    userId: string,
    tenantId: string,
    monto: number,
    metodoStr: string,
    planNombre: string,
    filename: string,
  ): Promise<any> {
    // 1. Determinar duración en días según el plan
    let duracionDias = 30;
    if (planNombre.toLowerCase().includes('trimestral')) {
      duracionDias = 90;
    } else if (planNombre.toLowerCase().includes('anual')) {
      duracionDias = 365;
    }

    // 2. Crear membresía en estado PENDING
    const membership = await this.prisma.membership.create({
      data: {
        tenant_id: tenantId,
        user_id: userId,
        plan_nombre: planNombre,
        duracion_dias: duracionDias,
        monto: monto,
        estado: MembershipState.PENDING,
      },
    });

    // 3. Mapear método de pago
    let metodo: PaymentMethod = PaymentMethod.CASH;
    if (metodoStr.toLowerCase() === 'yape') {
      metodo = PaymentMethod.MANUAL_YAPE;
    } else if (metodoStr.toLowerCase() === 'plin') {
      metodo = PaymentMethod.MANUAL_PLIN;
    } else if (metodoStr.toLowerCase() === 'tarjeta') {
      metodo = PaymentMethod.GATEWAY;
    }

    // 4. Crear Payment en estado PENDING
    const payment = await this.prisma.payment.create({
      data: {
        tenant_id: tenantId,
        membership_id: membership.id,
        monto: monto,
        metodo: metodo,
        estado: PaymentState.PENDING,
        comprobante_url: `/uploads/receipts/${filename}`,
      },
    });

    return {
      message: 'Comprobante subido y en espera de verificación.',
      payment,
      membership,
    };
  }

  async getPendingPayments(tenantId: string): Promise<any[]> {
    return this.prisma.payment.findMany({
      where: {
        tenant_id: tenantId,
        estado: PaymentState.PENDING,
      },
      include: {
        membership: {
          include: {
            user: true,
          },
        },
      },
      orderBy: {
        timestamp: 'desc',
      },
    });
  }

  async resolvePayment(
    paymentId: string,
    tenantId: string,
    status: 'APPROVED' | 'REJECTED',
    comments?: string,
  ): Promise<any> {
    const payment = await this.prisma.payment.findFirst({
      where: {
        id: paymentId,
        tenant_id: tenantId,
      },
      include: {
        membership: true,
      },
    });

    if (!payment) {
      throw new NotFoundException('El pago especificado no existe.');
    }

    const nextState = status === 'APPROVED' ? PaymentState.APPROVED : PaymentState.REJECTED;

    // Actualizar pago
    const updatedPayment = await this.prisma.payment.update({
      where: { id: paymentId },
      data: { estado: nextState },
    });

    // Actualizar membresía correspondiente
    let updatedMembership = null;
    if (payment.membership_id) {
      const membershipState = status === 'APPROVED' ? MembershipState.ACTIVE : MembershipState.EXPIRED;
      
      const today = new Date();
      const expirationDate = new Date();
      expirationDate.setDate(today.getDate() + payment.membership.duracion_dias);

      updatedMembership = await this.prisma.membership.update({
        where: { id: payment.membership_id },
        data: {
          estado: membershipState,
          fecha_inicio: status === 'APPROVED' ? today : null,
          fecha_vencimiento: status === 'APPROVED' ? expirationDate : null,
        },
      });

      // Si se aprueba, también nos aseguramos de activar el estado general del usuario
      if (status === 'APPROVED') {
        await this.prisma.user.update({
          where: { id: payment.membership.user_id },
          data: { estado: 'ACTIVE' },
        });
      }
    }

    return {
      payment: updatedPayment,
      membership: updatedMembership,
    };
  }

  async checkShiftSession(cashierId: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: cashierId },
    });

    if (!user) return false;
    
    // Si es Admin o SuperAdmin, tiene permiso completo sin restricción de turno
    if (user.rol === 'SUPER_ADMIN' || user.rol === 'ADMIN') {
      return true;
    }

    // Para cajero, validamos el turno (06:00 - 14:00 es el turno activo simulado)
    const localTime = new Date();
    const hourStr = new Intl.DateTimeFormat('es-PE', {
      timeZone: 'America/Lima',
      hour: 'numeric',
      hour12: false,
    }).format(localTime);
    
    const currentHour = parseInt(hourStr, 10);

    // Verificamos si la hora actual está dentro del turno 06:00 a 14:00 (6 a 13 inclusive)
    if (currentHour >= 6 && currentHour < 14) {
      return true;
    }

    return false;
  }

  async processPOSCharge(cashierId: string, tenantId: string, dto: ChargePosDto): Promise<any> {
    const isShiftActive = await this.checkShiftSession(cashierId);
    if (!isShiftActive) {
      throw new BadRequestException('Turno no iniciado o finalizado para este cajero.');
    }

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

    // Buscar el socio por DNI
    let member = await this.prisma.user.findFirst({
      where: {
        dni: dto.memberDni,
        tenant_id: tenantId,
      },
    });

    if (!member && dto.memberDni === 'ANONIMO') {
      member = await this.prisma.user.create({
        data: {
          tenant_id: tenantId,
          nombre_completo: 'Cliente Anónimo',
          dni: 'ANONIMO',
          email: `anonimo-${tenantId}@sasgym.com`,
          password_hash: 'none',
          rol: Role.MEMBER,
          estado: UserState.ACTIVE,
        },
      });
    }

    if (!member) {
      member = await this.prisma.user.create({
        data: {
          tenant_id: tenantId,
          nombre_completo: `Socio DNI ${dto.memberDni}`,
          dni: dto.memberDni,
          email: `dni-${dto.memberDni}-${tenantId}@sasgym.com`,
          password_hash: 'none',
          rol: Role.MEMBER,
          estado: UserState.ACTIVE,
        },
      });
      await this.prisma.memberProfile.create({
        data: {
          user_id: member.id,
          nickname: `Socio_${dto.memberDni}`,
          modo_activo: true,
        },
      });
    }

    // Buscar si hay items de membresía en el carrito (mensual, trimestral, pase diario)
    const membershipItem = dto.cartItems.find(
      (item) =>
        item.name.toLowerCase().includes('mensual') ||
        item.name.toLowerCase().includes('trimestral') ||
        item.name.toLowerCase().includes('pase') ||
        item.name.toLowerCase().includes('día') ||
        item.name.toLowerCase().includes('dia'),
    );

    let createdMembership = null;

    if (membershipItem) {
      // Registrar membresía directamente activa
      const planNombre = membershipItem.name;
      let duracionDias = 30;
      if (planNombre.toLowerCase().includes('trimestral')) {
        duracionDias = 90;
      } else if (
        planNombre.toLowerCase().includes('pase') ||
        planNombre.toLowerCase().includes('día') ||
        planNombre.toLowerCase().includes('dia')
      ) {
        duracionDias = 1;
      }

      createdMembership = await this.prisma.membership.create({
        data: {
          tenant_id: tenantId,
          user_id: member.id,
          plan_nombre: planNombre,
          duracion_dias: duracionDias,
          monto: membershipItem.price * membershipItem.qty,
          estado: MembershipState.ACTIVE,
          fecha_inicio: new Date(),
          fecha_vencimiento: new Date(Date.now() + duracionDias * 24 * 60 * 60 * 1000),
        },
      });
    }

    // Registrar pagos (soporte para único y mixto)
    const pagosArray = dto.payments && dto.payments.length > 0
      ? dto.payments
      : [{ metodo: dto.paymentMethod, monto: dto.total }];

    let primaryPayment = null;
    for (let i = 0; i < pagosArray.length; i++) {
      const p = pagosArray[i];
      let metodoEnum: PaymentMethod = PaymentMethod.CASH;
      const mUpper = p.metodo.toUpperCase();
      if (mUpper === 'YAPE' || mUpper === 'MANUAL_YAPE') metodoEnum = PaymentMethod.MANUAL_YAPE;
      else if (mUpper === 'PLIN' || mUpper === 'MANUAL_PLIN') metodoEnum = PaymentMethod.MANUAL_PLIN;
      else if (mUpper === 'TARJETA' || mUpper === 'GATEWAY' || mUpper === 'POS') metodoEnum = PaymentMethod.POS;
      else if (mUpper === 'TRANSFER') metodoEnum = PaymentMethod.TRANSFER;

      // El token de venta único se asocia al primer pago
      const token = i === 0 ? `POS_${Date.now()}_${Math.floor(Math.random() * 1000)}` : null;

      if (createdMembership) {
        const payment = await this.prisma.payment.create({
          data: {
            tenant_id: tenantId,
            membership_id: createdMembership.id,
            registrado_por_id: cashierId,
            monto: p.monto,
            metodo: metodoEnum,
            estado: PaymentState.APPROVED,
            caja_id: activeCaja.id,
            venta_token: token,
          },
        });
        if (i === 0) primaryPayment = payment;
      }

      // Registrar movimiento de ingreso en la caja (siempre se registra para que la caja cuadre)
      const descItems = dto.cartItems.map((c) => `${c['qty']}x ${c['name']}`).join(', ');
      await this.prisma.movimientoCaja.create({
        data: {
          caja_id: activeCaja.id,
          tipo: 'ingreso',
          monto: p.monto,
          descripcion: `Venta POS (${p.metodo.toLowerCase()}): ${descItems} - Socio: ${member.nombre_completo}`,
        },
      });
    }

    // Activar socio si compró membresía
    if (createdMembership) {
      await this.prisma.user.update({
        where: { id: member.id },
        data: { estado: 'ACTIVE' },
      });
    }

    return {
      success: true,
      message: 'Venta registrada con éxito.',
      membership: createdMembership,
      payment: primaryPayment,
    };
  }
}
