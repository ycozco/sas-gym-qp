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
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        theme_preference: this.themePreferenceFromWire(
          preferencesDto.themeMode,
        ),
      },
      select: {
        id: true,
        theme_preference: true,
      },
    });

    return {
      id: updated.id,
      themePreference: this.themePreferenceToWire(updated.theme_preference),
      theme_preference: this.themePreferenceToWire(updated.theme_preference),
    };
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

  private hashRefreshToken(refreshToken: string) {
    return createHash('sha256').update(refreshToken).digest('hex');
  }
}
