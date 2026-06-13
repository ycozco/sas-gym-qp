import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { totp } from 'otplib';
import { AccessMethod, MembershipState } from '@prisma/client';
import { getOptionalEnv } from '../../core/config/env';

@Injectable()
export class AttendanceService {
  private usedTokens = new Set<string>();

  constructor(private prisma: PrismaService) {
    // Configurar la ventana de tolerancia a ±1 paso de 30 segundos (total 90 segundos)
    totp.options = { step: 30, window: 1 };
  }

  async simulateAccess(dni: string, tenantId: string): Promise<any> {
    const simulatorEnabled =
      getOptionalEnv('ENABLE_QR_SIMULATOR', 'false') === 'true';
    const isProduction =
      getOptionalEnv('NODE_ENV', 'development') === 'production';
    if (!simulatorEnabled || isProduction) {
      throw new ForbiddenException(
        'El simulador temporal de accesos no esta habilitado.',
      );
    }

    const user = await this.prisma.user.findFirst({
      where: {
        dni,
        tenant_id: tenantId,
      },
      select: {
        qr_secret: true,
      },
    });

    if (!user?.qr_secret) {
      return this.verifyQrToken(dni, 'SIMULATION_NO_QR_SECRET', tenantId);
    }

    const token = totp.generate(user.qr_secret);
    const result = await this.verifyQrToken(dni, token, tenantId);
    return {
      ...result,
      simulation: true,
      qrPayload: `${dni}|${token}`,
    };
  }

  async verifyQrToken(
    dni: string,
    token: string,
    tenantId: string,
  ): Promise<any> {
    if (!dni || !token) {
      throw new BadRequestException('El DNI y el Token OTP son requeridos.');
    }

    // 1. Buscar al usuario y su perfil de miembro en la base de datos
    const user = await this.prisma.user.findFirst({
      where: {
        dni: dni,
        tenant_id: tenantId,
      },
      include: {
        member_profile: true,
        memberships: {
          orderBy: { fecha_vencimiento: 'desc' },
        },
      },
    });

    if (!user) {
      return {
        verdict: 'RED',
        reason: 'DNI inválido - Usuario no registrado.',
      };
    }

    // Verificar si la cuenta del usuario está activa
    if (user.estado !== 'ACTIVE') {
      let reason = 'El socio no se encuentra activo.';
      if (user.estado === 'SUSPENDED') {
        reason = 'La cuenta del socio ha sido suspendida.';
      } else if (user.estado === 'INACTIVE') {
        reason = 'La cuenta del socio está inactiva.';
      } else if (user.estado === 'PENDING') {
        reason = 'La cuenta del socio está pendiente de activación.';
      }
      return {
        verdict: 'RED',
        reason,
        member: {
          fullName: user.nombre_completo,
          status: user.estado,
        },
      };
    }

    if (!user.member_profile) {
      return {
        verdict: 'RED',
        reason: 'El usuario no tiene un perfil de miembro activo.',
        member: {
          fullName: user.nombre_completo,
          status: user.estado,
        },
      };
    }

    // 2. Prevenir Replay Attacks
    const tokenKey = `${user.id}:${token}`;
    if (this.usedTokens.has(tokenKey)) {
      return {
        verdict: 'RED',
        reason: 'Código QR ya utilizado. Espera a que rote.',
        member: {
          fullName: user.nombre_completo,
          status: user.estado,
        },
      };
    }

    // 3. Verificar el token TOTP usando la clave secreta emitida por backend
    const secret = user.qr_secret;
    if (!secret) {
      return {
        verdict: 'RED',
        reason: 'El socio no tiene QR de acceso emitido.',
        member: {
          fullName: user.nombre_completo,
          status: user.estado,
        },
      };
    }

    const isValidToken = totp.check(token, secret);
    if (!isValidToken) {
      return {
        verdict: 'RED',
        reason: 'Código QR inválido o expirado.',
        member: {
          fullName: user.nombre_completo,
          status: user.estado,
        },
      };
    }

    // Registrar token como usado
    this.usedTokens.add(tokenKey);
    setTimeout(() => {
      this.usedTokens.delete(tokenKey);
    }, 95000);

    // 3. Verificar estado de la membresía
    const memberships = user.memberships;

    if (memberships.length === 0) {
      return {
        verdict: 'RED',
        reason: 'El socio no cuenta con ninguna membresía registrada.',
        member: {
          fullName: user.nombre_completo,
          status: 'PENDIENTE',
        },
      };
    }

    // Buscar si hay alguna membresía activa o en gracia
    const activeOrGrace = memberships.find(
      (m) =>
        m.estado === MembershipState.ACTIVE ||
        m.estado === MembershipState.GRACE,
    );

    // Si no hay activa/gracia, buscar si hay alguna pendiente
    const pending = memberships.find(
      (m) => m.estado === MembershipState.PENDING,
    );

    // Si no hay pendiente, buscar si hay alguna suspendida
    const suspended = memberships.find(
      (m) => m.estado === MembershipState.SUSPENDED,
    );

    // De lo contrario, usar la primera (que por el orden desc es la de vencimiento más lejano)
    const latestMembership =
      activeOrGrace || pending || suspended || memberships[0];

    const state = latestMembership.estado;

    const today = new Date();
    const todayClean = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );
    const expiresAt = latestMembership.fecha_vencimiento
      ? new Date(latestMembership.fecha_vencimiento)
      : null;
    let daysLeft = 0;
    if (expiresAt) {
      const expiresClean = new Date(
        expiresAt.getFullYear(),
        expiresAt.getMonth(),
        expiresAt.getDate(),
      );
      const diffTime = expiresClean.getTime() - todayClean.getTime();
      daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    }

    if (
      state === MembershipState.EXPIRED ||
      state === MembershipState.SUSPENDED ||
      state === MembershipState.PENDING
    ) {
      let reason = 'Membresía vencida.';
      if (state === MembershipState.SUSPENDED) {
        reason = 'Membresía suspendida.';
      } else if (state === MembershipState.PENDING) {
        reason = 'Membresía pendiente de aprobación de pago.';
      }
      return {
        verdict: 'RED',
        reason,
        member: {
          fullName: user.nombre_completo,
          status: state,
          planName: latestMembership.plan_nombre,
          expiresAt: latestMembership.fecha_vencimiento,
          daysLeft,
          email: user.email,
          phone: user.celular || '',
        },
      };
    }

    // Determinar veredicto (GREEN o AMBER si está en día de gracia)
    let verdict = 'GREEN';
    let statusText = 'ACTIVO';
    let reason = 'Acceso concedido.';

    if (state === MembershipState.GRACE) {
      verdict = 'AMBER';
      statusText = 'GRACIA';
      reason = 'Acceso concedido en día de gracia (Regularización pendiente).';
    }

    // 4. Registrar la asistencia físicamente en la base de datos
    await this.prisma.attendance.create({
      data: {
        tenant_id: user.tenant_id,
        user_id: user.id,
        metodo_acceso: AccessMethod.QR_ADMIN,
      },
    });

    return {
      verdict,
      reason,
      member: {
        fullName: user.nombre_completo,
        status: statusText,
        planName: latestMembership.plan_nombre,
        expiresAt: latestMembership.fecha_vencimiento,
        daysLeft,
        email: user.email,
        phone: user.celular || '',
      },
    };
  }
}
