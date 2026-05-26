import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { totp } from 'otplib';
import { AccessMethod, MembershipState } from '@prisma/client';

@Injectable()
export class AttendanceService {
  private usedTokens = new Set<string>();

  constructor(private prisma: PrismaService) {
    // Configurar la ventana de tolerancia a ±1 paso de 30 segundos (total 90 segundos)
    totp.options = { step: 30, window: 1 };
  }

  async verifyQrToken(dni: string, token: string, tenantId: string): Promise<any> {
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
          take: 1,
        },
      },
    });

    if (!user) {
      return {
        verdict: 'RED',
        reason: 'Socio no registrado en este gimnasio.',
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

    // 3. Verificar el token TOTP usando la clave secreta
    const secret = user.qr_secret || (user.dni + '_secure_totp_secret_key_2026');
    
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
    const latestMembership = user.memberships[0];

    if (!latestMembership) {
      return {
        verdict: 'RED',
        reason: 'El socio no cuenta con ninguna membresía registrada.',
        member: {
          fullName: user.nombre_completo,
          status: 'PENDIENTE',
        },
      };
    }

    const state = latestMembership.estado;

    if (state === MembershipState.EXPIRED || state === MembershipState.SUSPENDED) {
      return {
        verdict: 'RED',
        reason: state === MembershipState.EXPIRED ? 'Membresía vencida.' : 'Membresía suspendida.',
        member: {
          fullName: user.nombre_completo,
          status: state,
          expiresAt: latestMembership.fecha_vencimiento,
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
      },
    };
  }
}
