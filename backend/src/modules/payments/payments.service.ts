import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  PaymentMethod,
  PaymentState,
  MembershipState,
  Role,
  UserState,
} from '@prisma/client';
import {
  IsString,
  IsArray,
  IsNumber,
  IsPositive,
  IsOptional,
} from 'class-validator';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcryptjs';

export interface PosCartItem {
  id?: string;
  productId?: string;
  planId?: string;
  name: string;
  type?: string;
  price: number;
  unitPrice?: number;
  qty: number;
}

export interface PosPaymentInput {
  metodo: string;
  monto: number;
}

export class ChargePosDto {
  @IsString()
  memberDni: string;

  @IsArray()
  cartItems: PosCartItem[];

  @IsNumber()
  @IsPositive()
  total: number;

  @IsString()
  paymentMethod: string;

  @IsOptional()
  @IsArray()
  payments?: PosPaymentInput[];
}

@Injectable()
export class PaymentsService {
  constructor(private prisma: PrismaService) {}

  private createQrSecret(): string {
    return randomBytes(32).toString('base64url');
  }

  private async createNoLoginPasswordHash(): Promise<string> {
    return bcrypt.hash(randomBytes(32).toString('base64url'), 10);
  }

  async uploadReceipt(
    userId: string,
    tenantId: string,
    monto: number,
    metodoStr: string,
    planNombre: string,
    filename: string,
  ) {
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

  async getPendingPayments(tenantId: string) {
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

  async getMemberPayments(userId: string, tenantId: string) {
    return this.prisma.payment.findMany({
      where: {
        tenant_id: tenantId,
        membership: { user_id: userId },
      },
      include: {
        membership: true,
      },
      orderBy: { timestamp: 'desc' },
      take: 50,
    });
  }

  async resolvePayment(
    paymentId: string,
    tenantId: string,
    status: 'APPROVED' | 'REJECTED',
    comments?: string,
  ) {
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

    const nextState =
      status === 'APPROVED' ? PaymentState.APPROVED : PaymentState.REJECTED;

    // Actualizar pago
    const updatedPayment = await this.prisma.payment.update({
      where: { id: paymentId },
      data: { estado: nextState },
    });

    // Actualizar membresía correspondiente
    let updatedMembership = null;
    if (payment.membership_id) {
      const membershipState =
        status === 'APPROVED'
          ? MembershipState.ACTIVE
          : MembershipState.EXPIRED;

      const today = new Date();
      const expirationDate = new Date();
      expirationDate.setDate(
        today.getDate() + payment.membership.duracion_dias,
      );

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
      resolutionComments: comments?.trim() || null,
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

    const activeCaja = await this.prisma.caja.findFirst({
      where: {
        cajero_id: cashierId,
        tenant_id: user.tenant_id,
        estado: 'abierta',
      },
    });

    return Boolean(activeCaja);
  }

  async processPOSCharge(
    cashierId: string,
    tenantId: string,
    dto: ChargePosDto,
  ) {
    const isShiftActive = await this.checkShiftSession(cashierId);
    if (!isShiftActive) {
      throw new BadRequestException(
        'Turno no iniciado o finalizado para este cajero.',
      );
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
          password_hash: await this.createNoLoginPasswordHash(),
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
          password_hash: await this.createNoLoginPasswordHash(),
          rol: Role.MEMBER,
          estado: UserState.ACTIVE,
          qr_secret: this.createQrSecret(),
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
        item.planId ||
        item.name.toLowerCase().includes('mensual') ||
        item.name.toLowerCase().includes('trimestral') ||
        item.name.toLowerCase().includes('pase') ||
        item.name.toLowerCase().includes('día') ||
        item.name.toLowerCase().includes('dia'),
    );

    let createdMembership = null;

    if (membershipItem) {
      // Registrar membresía directamente activa
      const planId: string | null = membershipItem.planId ?? null;
      let planNombre = membershipItem.name;
      let duracionDias = 30;
      let monto = membershipItem.price * membershipItem.qty;
      if (planId) {
        const plan = await this.prisma.membershipPlan.findFirst({
          where: { id: planId, tenant_id: tenantId, activo: true },
        });
        if (!plan) {
          throw new BadRequestException(
            'Plan de membresia no encontrado o inactivo.',
          );
        }
        planNombre = plan.nombre;
        duracionDias = plan.duracion_dias;
        monto = plan.precio * membershipItem.qty;
      } else if (planNombre.toLowerCase().includes('trimestral')) {
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
          plan_id: planId,
          plan_nombre: planNombre,
          duracion_dias: duracionDias,
          monto,
          estado: MembershipState.ACTIVE,
          fecha_inicio: new Date(),
          fecha_vencimiento: new Date(
            Date.now() + duracionDias * 24 * 60 * 60 * 1000,
          ),
        },
      });
    }

    // Registrar pagos (soporte para único y mixto)
    const productItems = dto.cartItems.filter(
      (item) => item.type === 'product' || item.productId,
    );
    let productSale = null;
    if (productItems.length > 0) {
      const subtotal = productItems.reduce(
        (sum, item) =>
          sum +
          Number(item.unitPrice ?? item.price ?? 0) * Number(item.qty ?? 1),
        0,
      );
      const sale = await this.prisma.productSale.create({
        data: {
          tenant_id: tenantId,
          referencia: `POS-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
          cajero_id: cashierId,
          cliente_id: member.id,
          caja_id: activeCaja.id,
          subtotal,
          descuento: Math.max(0, subtotal - dto.total),
          total: dto.total,
          estado: 'completada',
          notas: 'Venta POS web/app',
        },
      });

      for (const item of productItems) {
        const product = await this.prisma.product.findFirst({
          where: {
            id: item.productId ?? item.id,
            tenant_id: tenantId,
            es_visible: true,
            estado: { not: 'inactivo' },
          },
        });
        if (!product) {
          throw new BadRequestException(`Producto no encontrado: ${item.name}`);
        }
        const qty = Number(item.qty ?? 1);
        const unitPrice = Number(
          item.unitPrice ?? item.price ?? product.precio_venta,
        );
        const nextStock = Math.max(0, product.stock_actual - qty);
        await this.prisma.productSaleDetail.create({
          data: {
            sale_id: sale.id,
            producto_id: product.id,
            cantidad: qty,
            precio_unitario: unitPrice,
            subtotal: unitPrice * qty,
          },
        });
        await this.prisma.inventoryMovement.create({
          data: {
            producto_id: product.id,
            tipo: 'salida',
            cantidad: qty,
            stock_anterior: product.stock_actual,
            stock_actual: nextStock,
            sale_id: sale.id,
            usuario_id: cashierId,
            motivo: 'Venta POS',
          },
        });
        await this.prisma.product.update({
          where: { id: product.id },
          data: {
            stock_actual: nextStock,
            veces_vendido: { increment: qty },
            ultima_venta: new Date(),
            estado: nextStock <= 0 ? 'agotado' : product.estado,
          },
        });
      }
      productSale = sale;
    }

    const pagosArray =
      dto.payments && dto.payments.length > 0
        ? dto.payments
        : [{ metodo: dto.paymentMethod, monto: dto.total }];

    let primaryPayment = null;
    for (let i = 0; i < pagosArray.length; i++) {
      const p = pagosArray[i];
      let metodoEnum: PaymentMethod = PaymentMethod.CASH;
      const mUpper = p.metodo.toUpperCase();
      if (mUpper === 'YAPE' || mUpper === 'MANUAL_YAPE')
        metodoEnum = PaymentMethod.MANUAL_YAPE;
      else if (mUpper === 'PLIN' || mUpper === 'MANUAL_PLIN')
        metodoEnum = PaymentMethod.MANUAL_PLIN;
      else if (mUpper === 'TARJETA' || mUpper === 'GATEWAY' || mUpper === 'POS')
        metodoEnum = PaymentMethod.POS;
      else if (mUpper === 'TRANSFER') metodoEnum = PaymentMethod.TRANSFER;

      // El token de venta único se asocia al primer pago
      const token =
        i === 0
          ? `POS_${Date.now()}_${Math.floor(Math.random() * 1000)}`
          : null;

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

      if (productSale) {
        await this.prisma.productPaymentMethodDetail.create({
          data: {
            sale_id: productSale.id,
            metodo: p.metodo,
            monto: p.monto,
          },
        });
      }

      // Registrar movimiento de ingreso en la caja (siempre se registra para que la caja cuadre)
      const descItems = dto.cartItems
        .map((c) => `${c.qty}x ${c.name}`)
        .join(', ');
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
      productSale,
    };
  }

  async getCajaSales(cashierId: string, tenantId: string) {
    const activeCaja = await this.prisma.caja.findFirst({
      where: { cajero_id: cashierId, tenant_id: tenantId, estado: 'abierta' },
    });
    if (!activeCaja) {
      return { caja: null, membershipPayments: [], productSales: [] };
    }
    const [membershipPayments, productSales] = await Promise.all([
      this.prisma.payment.findMany({
        where: { caja_id: activeCaja.id, tenant_id: tenantId },
        include: {
          membership: { include: { user: true } },
          registrado_por: true,
        },
        orderBy: { timestamp: 'desc' },
      }),
      this.prisma.productSale.findMany({
        where: { caja_id: activeCaja.id, tenant_id: tenantId },
        include: {
          cliente: true,
          cajero: true,
          details: { include: { producto: true } },
          payment_methods: true,
        },
        orderBy: { fecha_venta: 'desc' },
      }),
    ]);
    return { caja: activeCaja, membershipPayments, productSales };
  }

  async requestVoid(cashierId: string, tenantId: string, id: string) {
    const payment = await this.prisma.payment.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!payment) throw new NotFoundException('Pago no encontrado.');
    await this.prisma.auditLog.create({
      data: {
        tenant_id: tenantId,
        actor_id: cashierId,
        actor_name: 'Caja',
        rol: 'CAJA',
        accion: 'Solicitud de anulacion',
        entidad: 'Payment',
        detalles: { status: 'requested', entidad_id: id },
      },
    });
    return {
      success: true,
      message: 'Solicitud de anulacion enviada al administrador.',
    };
  }

  async resolveVoid(tenantId: string, id: string, approved: boolean) {
    const payment = await this.prisma.payment.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!payment) throw new NotFoundException('Pago no encontrado.');
    if (!approved) return { success: true, message: 'Anulacion rechazada.' };
    const updated = await this.prisma.payment.update({
      where: { id },
      data: { estado: PaymentState.REJECTED },
    });
    return { success: true, message: 'Pago anulado.', payment: updated };
  }
}
