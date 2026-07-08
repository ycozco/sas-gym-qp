import type { Role } from '@prisma/client';
import type { Request } from 'express';

export interface AuthenticatedUser {
  sub: string;
  email: string;
  rol: Role;
  tenantId: string;
  tokenType: 'access';
  nombre_completo?: string;
}

export interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
  tenantId?: string;
}
