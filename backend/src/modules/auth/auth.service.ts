import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { UserState } from '@prisma/client';

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
        OR: [
          { email: emailOrDni },
          { dni: emailOrDni },
        ],
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
      throw new UnauthorizedException('El gimnasio asociado a tu cuenta no existe.');
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
        statusMsg = 'Tu usuario está pendiente de activación por administración.';
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

  async login(user: any) {
    const payload = {
      sub: user.id,
      email: user.email,
      rol: user.rol,
      tenantId: user.tenant_id,
    };

    return {
      token: await this.jwtService.signAsync(payload),
      tenantId: user.tenant_id,
      user: {
        id: user.id,
        email: user.email,
        rol: user.rol,
        nombreCompleto: user.nombre_completo,
      },
    };
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
    return result;
  }
}
