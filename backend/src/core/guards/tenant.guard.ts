import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import type { AuthenticatedRequest } from '../types/authenticated-request';

@Injectable()
export class TenantGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  async canActivate(executionContext: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      executionContext.getHandler(),
      executionContext.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const request = executionContext
      .switchToHttp()
      .getRequest<AuthenticatedRequest>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Usuario no autenticado.');
    }

    const tenantIdHeader = request.headers['x-tenant-id'];
    if (!tenantIdHeader) {
      throw new BadRequestException('El encabezado X-Tenant-ID es requerido.');
    }
    if (typeof tenantIdHeader !== 'string') {
      throw new BadRequestException('El encabezado X-Tenant-ID es invalido.');
    }

    if (user.rol === Role.SUPER_ADMIN) {
      request.user.tenantId = tenantIdHeader;
      request.tenantId = tenantIdHeader;
    } else {
      if (user.tenantId !== tenantIdHeader) {
        throw new ForbiddenException(
          'Acceso denegado: El inquilino (Tenant) no coincide con tu suscripcion activa.',
        );
      }
      request.tenantId = tenantIdHeader;
    }

    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantIdHeader },
    });

    if (!tenant || !tenant.activo) {
      throw new ForbiddenException(
        'Acceso denegado: Gimnasio / Suscripcion suspendida.',
      );
    }

    return true;
  }
}
