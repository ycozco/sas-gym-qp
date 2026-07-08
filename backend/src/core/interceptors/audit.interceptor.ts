import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import type { Request } from 'express';
import { Observable, tap } from 'rxjs';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedRequest } from '../types/authenticated-request';

type JsonValue =
  | string
  | number
  | boolean
  | null
  | JsonValue[]
  | { [key: string]: JsonValue };
type AuditedRequest = Omit<AuthenticatedRequest, 'body'> &
  Request<unknown, unknown, unknown> & { body: unknown };

function sanitizeDeep(value: unknown): JsonValue {
  if (
    value === null ||
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean'
  )
    return value;
  if (Array.isArray(value)) return value.map(sanitizeDeep);
  if (value === undefined) return '';
  if (typeof value !== 'object') return '[unsupported]';

  const sanitized: Record<string, JsonValue> = {};
  for (const [key, entry] of Object.entries(value)) {
    const lowerKey = key.toLowerCase();
    sanitized[key] = ['pass', 'secret', 'token', 'hash', 'key'].some((term) =>
      lowerKey.includes(term),
    )
      ? '********'
      : sanitizeDeep(entry);
  }
  return sanitized;
}

@Injectable()
export class AuditInterceptor implements NestInterceptor<unknown, unknown> {
  constructor(private readonly prisma: PrismaService) {}

  intercept(
    context: ExecutionContext,
    next: CallHandler<unknown>,
  ): Observable<unknown> {
    const request = context.switchToHttp().getRequest<AuditedRequest>();

    return next.handle().pipe(
      tap(() => {
        void this.recordAudit(request);
      }),
    );
  }

  private async recordAudit(request: AuditedRequest): Promise<void> {
    const { method, url, body, user } = request;
    if (!['POST', 'PATCH', 'DELETE', 'PUT'].includes(method)) return;
    if (url.includes('/auth/login') || url.includes('/auth/forgot-password'))
      return;

    try {
      const cleanUrl = url.split('?')[0];
      const parts = cleanUrl.split('/').filter(Boolean);
      const entidad = parts.at(-2) ?? parts.at(-1) ?? 'DESCONOCIDA';
      const details = body === undefined ? {} : sanitizeDeep(body);
      await this.prisma.auditLog.create({
        data: {
          tenant_id: user.tenantId || 'global',
          actor_id: user.sub || 'system',
          actor_name: user.email || 'Usuario',
          rol: user.rol,
          accion: method,
          entidad: entidad.toUpperCase(),
          detalles: details === null ? Prisma.JsonNull : details,
        },
      });
    } catch (error: unknown) {
      console.error('Error al registrar log de auditoría:', error);
    }
  }
}
