import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

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

    const request = executionContext.switchToHttp().getRequest();
    const user = request.user;
    
    if (!user) {
      throw new ForbiddenException('Usuario no autenticado.');
    }

    // El Super Admin tiene acceso transversal y se le permite saltar este check
    if (user.rol === Role.SUPER_ADMIN) {
      return true;
    }

    const tenantIdHeader = request.headers['x-tenant-id'];
    if (!tenantIdHeader) {
      throw new BadRequestException('El encabezado X-Tenant-ID es requerido.');
    }

    const userTenantId = user.tenantId || user.tenant_id;
    if (userTenantId !== tenantIdHeader) {
      throw new ForbiddenException(
        'Acceso denegado: El inquilino (Tenant) no coincide con tu suscripción activa.',
      );
    }

    // Verificar en la base de datos que el inquilino esté activo
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantIdHeader },
    });

    if (!tenant || !tenant.activo) {
      throw new ForbiddenException(
        'Acceso denegado: Gimnasio / Suscripción suspendida.',
      );
    }

    return true;
  }
}
