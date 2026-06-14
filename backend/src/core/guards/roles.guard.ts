import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { ROLES_KEY } from '../decorators/roles.decorator';

/**
 * RolesGuard — verifica que el usuario autenticado tenga alguno de los
 * roles indicados por el decorador @Roles(...). El SUPER_ADMIN siempre
 * tiene acceso sin importar los roles requeridos.
 *
 * Uso:
 *   @UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
 *   @Roles(Role.ADMIN, Role.CAJERO)
 *   async myEndpoint() {}
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    // Sin restricción de roles → permite el acceso (siempre que esté autenticado)
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();
    if (!user) {
      throw new ForbiddenException('Usuario no autenticado.');
    }

    // SUPER_ADMIN tiene acceso transversal — bypass siempre
    if (user.rol === Role.SUPER_ADMIN) {
      return true;
    }

    const hasRole = requiredRoles.some((role) => user.rol === role);
    if (!hasRole) {
      const roleList = requiredRoles.join(', ');
      throw new ForbiddenException(
        `Acceso denegado: se requiere uno de los siguientes roles: [${roleList}].`,
      );
    }

    return true;
  }
}
