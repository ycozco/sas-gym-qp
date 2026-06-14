import { applyDecorators, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { AuthGuard } from '../guards/auth.guard';
import { TenantGuard } from '../guards/tenant.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from './roles.decorator';

/**
 * Decorador compuesto @Auth() que aplica en una sola línea:
 *   1. AuthGuard (valida JWT Bearer)
 *   2. TenantGuard (valida X-Tenant-ID y que el tenant esté activo)
 *   3. RolesGuard (valida que el rol del usuario coincide con los requeridos)
 *
 * Uso:
 *   @Auth()                     // Solo autenticación + tenant
 *   @Auth(Role.ADMIN)           // Solo ADMIN o SUPER_ADMIN
 *   @Auth(Role.ADMIN, Role.CAJERO)  // ADMIN, CAJERO, o SUPER_ADMIN
 */
export const Auth = (...roles: Role[]) => {
  const decorators = [UseGuards(AuthGuard, TenantGuard, RolesGuard)];
  if (roles.length > 0) {
    decorators.push(Roles(...roles));
  }
  return applyDecorators(...decorators);
};
