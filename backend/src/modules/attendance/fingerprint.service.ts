import { Injectable, UnauthorizedException, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MembershipState } from '@prisma/client';
import * as crypto from 'crypto';
import { IsString, IsOptional, IsUUID } from 'class-validator';
import { getFingerprintSecret } from '../../core/config/env';

export class RegisterFingerprintDto {
  @IsUUID()
  userId: string;

  @IsString()
  dedo: string; // e.g., 'pulgar_der', 'indice_der'

  @IsString()
  datosHuella: string; // Base64 template

  @IsString()
  signature: string; // HMAC-SHA256 signature
}

export class VerifyFingerprintDto {
  @IsString()
  tokenRegistro: string;

  @IsString()
  hashVerificacion: string;

  @IsOptional()
  @IsString()
  ipOrigen?: string;

  @IsOptional()
  @IsString()
  dispositivoId?: string;
}

@Injectable()
export class FingerprintService {
  constructor(private prisma: PrismaService) {}

  async registerFingerprint(dto: RegisterFingerprintDto) {
    const { userId, dedo, datosHuella, signature } = dto;

    const secret = getFingerprintSecret();
    
    // 1. Validar la firma HMAC-SHA256
    const message = `${userId}:${dedo}:${datosHuella}`;
    const calculatedSignature = crypto
      .createHmac('sha256', secret)
      .update(message)
      .digest('hex');

    if (calculatedSignature !== signature) {
      throw new UnauthorizedException('Firma de plantilla biométrica inválida. Acceso no autorizado.');
    }

    // 2. Calcular hash de integridad SHA256 para guardar en BD
    const hashVerificacion = crypto
      .createHash('sha256')
      .update(message)
      .digest('hex');

    // 3. Buscar si el usuario existe
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Socio no encontrado.');
    }

    // 4. Guardar o actualizar la huella (@@unique([usuario_id, dedo]))
    const fingerprint = await this.prisma.fingerprint.upsert({
      where: {
        usuario_id_dedo: {
          usuario_id: userId,
          dedo,
        },
      },
      update: {
        datos_huella: datosHuella,
        hash_verificacion: hashVerificacion,
        activa: true,
      },
      create: {
        usuario_id: userId,
        dedo,
        datos_huella: datosHuella,
        hash_verificacion: hashVerificacion,
        activa: true,
      },
    });

    return {
      success: true,
      message: `Huella del dedo ${dedo} registrada exitosamente.`,
      fingerprintId: fingerprint.id,
      hashVerificacion,
      tokenRegistro: fingerprint.token_registro,
    };
  }

  async verifyFingerprint(dto: VerifyFingerprintDto) {
    const { tokenRegistro, hashVerificacion, ipOrigen, dispositivoId } = dto;

    // 1. Buscar la huella en base de datos
    const fingerprint = await this.prisma.fingerprint.findFirst({
      where: {
        token_registro: tokenRegistro,
        hash_verificacion: hashVerificacion,
        activa: true,
      },
      include: {
        usuario: {
          include: {
            memberships: {
              orderBy: { fecha_vencimiento: 'desc' },
            },
          },
        },
      },
    });

    if (!fingerprint) {
      return {
        verdict: 'RED',
        reason: 'Huella digital no registrada o alterada.',
      };
    }

    const user = fingerprint.usuario;

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

    // 2. Verificar estado de membresía del socio
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
      m => m.estado === MembershipState.ACTIVE || m.estado === MembershipState.GRACE
    );
    
    // Si no hay activa/gracia, buscar si hay alguna pendiente
    const pending = memberships.find(m => m.estado === MembershipState.PENDING);
    
    // Si no hay pendiente, buscar si hay alguna suspendida
    const suspended = memberships.find(m => m.estado === MembershipState.SUSPENDED);
    
    // De lo contrario, usar la primera (que por el orden desc es la de vencimiento más lejano)
    const latestMembership = activeOrGrace || pending || suspended || memberships[0];

    const state = latestMembership.estado;
    if (state === MembershipState.EXPIRED || state === MembershipState.SUSPENDED || state === MembershipState.PENDING) {
      return {
        verdict: 'RED',
        reason: state === MembershipState.EXPIRED
            ? 'Membresía vencida.'
            : (state === MembershipState.PENDING
                ? 'Membresía pendiente de aprobación de pago.'
                : 'Membresía suspendida.'),
        member: {
          fullName: user.nombre_completo,
          status: state,
          expiresAt: latestMembership.fecha_vencimiento,
        },
      };
    }

    // 3. Determinar veredicto (GREEN o AMBER en día de gracia)
    let verdict = 'GREEN';
    let statusText = 'ACTIVO';
    let reason = 'Acceso biométrico concedido.';

    if (state === MembershipState.GRACE) {
      verdict = 'AMBER';
      statusText = 'GRACIA';
      reason = 'Acceso biométrico concedido en día de gracia (Regularización pendiente).';
    }

    // 4. Registrar la asistencia biométrica
    await this.prisma.fingerprintAttendance.create({
      data: {
        usuario_id: user.id,
        huella_id: fingerprint.id,
        ip_origen: ipOrigen || null,
        dispositivo_id: dispositivoId || 'ZKT-SIMULATED-01',
      },
    });

    // Registrar también en el historial general de asistencias del gimnasio
    await this.prisma.attendance.create({
      data: {
        tenant_id: user.tenant_id,
        user_id: user.id,
        metodo_acceso: 'MANUAL_ADMIN', // Marcar como ingreso administrado/validado
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
