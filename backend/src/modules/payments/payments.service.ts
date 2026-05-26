import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PaymentMethod, PaymentState, MembershipState } from '@prisma/client';
import { IsString, IsArray, IsNumber, IsPositive } from 'class-validator';

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

    // Buscar el socio por DNI
    const member = await this.prisma.user.findFirst({
      where: {
        dni: dto.memberDni,
        tenant_id: tenantId,
      },
    });

    if (!member) {
      throw new NotFoundException('Socio no registrado.');
    }

    // Buscar si hay items de membresía en el carrito (ej: "Mensual Plata")
    const membershipItem = dto.cartItems.find(
      (item) => item.name.toLowerCase().includes('mensual') || item.name.toLowerCase().includes('trimestral'),
    );

    let createdMembership = null;
    let createdPayment = null;

    if (membershipItem) {
      // Registrar membresía directamente activa
      const planNombre = membershipItem.name;
      let duracionDias = 30;
      if (planNombre.toLowerCase().includes('trimestral')) {
        duracionDias = 90;
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

      // Crear Pago Aprobado
      let metodo: PaymentMethod = PaymentMethod.CASH;
      if (dto.paymentMethod.toLowerCase() === 'yape') {
        metodo = PaymentMethod.MANUAL_YAPE;
      } else if (dto.paymentMethod.toLowerCase() === 'plin') {
        metodo = PaymentMethod.MANUAL_PLIN;
      } else if (dto.paymentMethod.toLowerCase() === 'tarjeta') {
        metodo = PaymentMethod.GATEWAY;
      }

      createdPayment = await this.prisma.payment.create({
        data: {
          tenant_id: tenantId,
          membership_id: createdMembership.id,
          registrado_por_id: cashierId,
          monto: dto.total,
          metodo: metodo,
          estado: PaymentState.APPROVED,
        },
      });

      // Activar socio
      await this.prisma.user.update({
        where: { id: member.id },
        data: { estado: 'ACTIVE' },
      });
    }

    return {
      success: true,
      message: 'Venta registrada con éxito.',
      membership: createdMembership,
      payment: createdPayment,
    };
  }
}
