import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { createHash, randomBytes } from 'crypto';
import { ThemePreference, UserState } from '@prisma/client';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { getRefreshTokenDays } from '../../core/config/env';

export interface AuthRequestMeta {
  ip?: string;
  userAgent?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async validateUser(emailOrDni: string, pass: string): Promise<any> {
    // Buscar al usuario por email o DNI usando consultas parametrizadas seguras de Prisma
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: emailOrDni }, { dni: emailOrDni }],
      },
    });

    if (!user) {
      throw new UnauthorizedException('Credenciales incorrectas.');
    }

    // Verificar si el inquilino (gimnasio) existe y está activo
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: user.tenant_id },
    });

    if (!tenant) {
      throw new UnauthorizedException(
        'El gimnasio asociado a tu cuenta no existe.',
      );
    }

    if (!tenant.activo) {
      throw new UnauthorizedException(
        'El gimnasio (Tenant) se encuentra temporalmente inactivo o suspendido por administración.',
      );
    }

    // Verificar el estado del usuario
    if (user.estado !== UserState.ACTIVE) {
      let statusMsg = 'Tu usuario no está activo.';
      if (user.estado === UserState.PENDING) {
        statusMsg =
          'Tu usuario está pendiente de activación por administración.';
      } else if (user.estado === UserState.SUSPENDED) {
        statusMsg = 'Tu cuenta ha sido suspendida.';
      } else if (user.estado === UserState.INACTIVE) {
        statusMsg = 'Tu cuenta está inactiva.';
      }
      throw new UnauthorizedException(statusMsg);
    }

    // Validar contraseña
    const isMatch = await bcrypt.compare(pass, user.password_hash);
    if (!isMatch) {
      throw new UnauthorizedException('Credenciales incorrectas.');
    }

    // Excluir hash de contraseña
    const { password_hash, ...result } = user;
    return result;
  }

  async login(user: any, meta: AuthRequestMeta = {}) {
    const payload = {
      sub: user.id,
      email: user.email,
      rol: user.rol,
      tenantId: user.tenant_id,
      tokenType: 'access',
    };
    const refreshToken = await this.createRefreshSession(user.id, meta);
    const accessToken = await this.jwtService.signAsync(payload);
    await this.recordLoginAudit(user, meta);

    return {
      token: accessToken,
      accessToken,
      refreshToken,
      tenantId: user.tenant_id,
      user: {
        id: user.id,
        email: user.email,
        rol: user.rol,
        nombreCompleto: user.nombre_completo,
        themePreference: this.themePreferenceToWire(user.theme_preference),
      },
    };
  }

  async refresh(refreshToken: string, meta: AuthRequestMeta = {}) {
    if (!refreshToken) {
      throw new UnauthorizedException('No se proporciono refresh token.');
    }
    const tokenHash = this.hashRefreshToken(refreshToken);
    const session = await this.prisma.refreshTokenSession.findUnique({
      where: { token_hash: tokenHash },
      include: { user: true },
    });

    if (!session || session.revoked_at || session.expires_at <= new Date()) {
      throw new UnauthorizedException('Refresh token invalido o expirado.');
    }

    const tenant = await this.prisma.tenant.findUnique({
      where: { id: session.user.tenant_id },
    });
    if (!tenant?.activo || session.user.estado !== UserState.ACTIVE) {
      await this.revokeRefreshToken(refreshToken);
      throw new UnauthorizedException('Sesion no autorizada.');
    }

    const nextRefreshToken = await this.createRefreshSession(
      session.user.id,
      meta,
    );
    const nextHash = this.hashRefreshToken(nextRefreshToken);
    const replacement = await this.prisma.refreshTokenSession.findUnique({
      where: { token_hash: nextHash },
      select: { id: true },
    });

    await this.prisma.refreshTokenSession.update({
      where: { id: session.id },
      data: {
        revoked_at: new Date(),
        replaced_by_id: replacement?.id,
      },
    });

    const accessPayload = {
      sub: session.user.id,
      email: session.user.email,
      rol: session.user.rol,
      tenantId: session.user.tenant_id,
      tokenType: 'access',
    };
    const accessToken = await this.jwtService.signAsync(accessPayload);
    return {
      token: accessToken,
      accessToken,
      refreshToken: nextRefreshToken,
      tenantId: session.user.tenant_id,
    };
  }

  async revokeRefreshToken(refreshToken?: string) {
    if (!refreshToken) return { revoked: false };
    const tokenHash = this.hashRefreshToken(refreshToken);
    const session = await this.prisma.refreshTokenSession.findUnique({
      where: { token_hash: tokenHash },
    });
    if (!session || session.revoked_at) return { revoked: false };
    await this.prisma.refreshTokenSession.update({
      where: { id: session.id },
      data: { revoked_at: new Date() },
    });
    return { revoked: true };
  }

  async getUserProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        trainer_profile: true,
        member_profile: true,
        memberships: {
          orderBy: { fecha_vencimiento: 'desc' },
          take: 1,
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('Usuario no encontrado.');
    }
    const { password_hash, ...result } = user;
    const memberProfile = result.member_profile
      ? {
          ...result.member_profile,
          qr_secret: result.qr_secret,
          qrSecret: result.qr_secret,
        }
      : result.member_profile;

    return {
      ...result,
      themePreference: this.themePreferenceToWire(result.theme_preference),
      theme_preference: this.themePreferenceToWire(result.theme_preference),
      member_profile: memberProfile,
    };
  }

  async updatePreferences(
    userId: string,
    preferencesDto: UpdatePreferencesDto,
  ) {
    const userData: any = {};
    if (preferencesDto.themeMode !== undefined) {
      userData.theme_preference = this.themePreferenceFromWire(
        preferencesDto.themeMode,
      );
    }

    if (
      preferencesDto.themeMode === undefined &&
      preferencesDto.trainingVisible === undefined
    ) {
      throw new BadRequestException(
        'No se enviaron preferencias para actualizar.',
      );
    }

    const select = {
      id: true,
      theme_preference: true,
      member_profile: {
        select: {
          modo_activo: true,
        },
      },
    };

    const updated =
      Object.keys(userData).length > 0
        ? await this.prisma.user.update({
            where: { id: userId },
            data: userData,
            select,
          })
        : await this.prisma.user.findUniqueOrThrow({
            where: { id: userId },
            select,
          });

    if (preferencesDto.trainingVisible !== undefined) {
      await this.prisma.memberProfile.updateMany({
        where: { user_id: userId },
        data: { modo_activo: preferencesDto.trainingVisible },
      });
      if (updated.member_profile) {
        updated.member_profile.modo_activo = preferencesDto.trainingVisible;
      }
    }

    return {
      id: updated.id,
      themePreference: this.themePreferenceToWire(updated.theme_preference),
      theme_preference: this.themePreferenceToWire(updated.theme_preference),
      trainingVisible:
        preferencesDto.trainingVisible ?? updated.member_profile?.modo_activo,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const userUpdates: any = {};
    if (dto.nombreCompleto !== undefined)
      userUpdates.nombre_completo = dto.nombreCompleto.trim();
    if (dto.celular !== undefined) userUpdates.celular = dto.celular.trim();

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: userUpdates,
      include: { member_profile: true },
    });

    if (user.member_profile) {
      const profileUpdates: any = {};
      if (dto.nickname !== undefined) profileUpdates.nickname = dto.nickname;
      if (dto.pesoKg !== undefined) profileUpdates.peso_kg = dto.pesoKg;
      if (dto.alturaCm !== undefined) profileUpdates.altura_cm = dto.alturaCm;
      if (dto.objetivo !== undefined) profileUpdates.objetivo = dto.objetivo;
      if (dto.lesiones !== undefined) profileUpdates.lesiones = dto.lesiones;
      if (dto.medidasJson !== undefined)
        profileUpdates.medidas_json = dto.medidasJson;

      if (Object.keys(profileUpdates).length > 0) {
        await this.prisma.memberProfile.update({
          where: { user_id: userId },
          data: profileUpdates,
        });
      }
    }

    return this.getUserProfile(userId);
  }

  private themePreferenceFromWire(value: string): ThemePreference {
    if (value === 'light') return ThemePreference.LIGHT;
    if (value === 'dark') return ThemePreference.DARK;
    return ThemePreference.SYSTEM;
  }

  private themePreferenceToWire(
    value?: ThemePreference | null,
  ): 'system' | 'light' | 'dark' {
    if (value === ThemePreference.LIGHT) return 'light';
    if (value === ThemePreference.DARK) return 'dark';
    return 'system';
  }

  private async createRefreshSession(userId: string, meta: AuthRequestMeta) {
    const refreshToken = randomBytes(48).toString('base64url');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + getRefreshTokenDays());

    await this.prisma.refreshTokenSession.create({
      data: {
        user_id: userId,
        token_hash: this.hashRefreshToken(refreshToken),
        user_agent: meta.userAgent,
        ip_address: meta.ip,
        expires_at: expiresAt,
      },
    });

    return refreshToken;
  }

  private async recordLoginAudit(user: any, meta: AuthRequestMeta) {
    try {
      await this.prisma.auditLog.create({
        data: {
          tenant_id: user.tenant_id,
          actor_id: user.id,
          actor_name: user.email,
          rol: user.rol,
          accion: 'LOGIN',
          entidad: 'AUTH',
          detalles: {
            ip: meta.ip ?? null,
            userAgent: meta.userAgent ?? null,
          },
        },
      });
    } catch (error) {
      console.error('Error al registrar login en auditoría:', error);
    }
  }

  private hashRefreshToken(refreshToken: string) {
    return createHash('sha256').update(refreshToken).digest('hex');
  }
}
