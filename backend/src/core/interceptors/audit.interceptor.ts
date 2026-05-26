import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly prisma: PrismaService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body } = request;

    return next.handle().pipe(
      tap(async () => {
        // Interceptamos solo métodos de escritura exitosos
        if (['POST', 'PATCH', 'DELETE', 'PUT'].includes(method)) {
          const user = request.user;
          if (user && !url.includes('/auth/login') && !url.includes('/auth/forgot-password')) {
            try {
              // Determinar la entidad a partir de la URL
              let entidad = 'DESCONOCIDA';
              const cleanUrl = url.split('?')[0]; // ignorar query params
              const parts = cleanUrl.split('/');
              if (parts.length > 2) {
                entidad = parts[parts.length - 2] || parts[parts.length - 1];
              }

              // Sanitizar body recursivamente si contiene contraseñas o tokens
              const sanitizeDeep = (obj: any): any => {
                if (obj === null || typeof obj !== 'object') {
                  return obj;
                }
                if (Array.isArray(obj)) {
                  return obj.map(sanitizeDeep);
                }
                const sanitized: any = {};
                for (const key of Object.keys(obj)) {
                  const lowerKey = key.toLowerCase();
                  if (
                    lowerKey.includes('pass') ||
                    lowerKey.includes('secret') ||
                    lowerKey.includes('token') ||
                    lowerKey.includes('hash') ||
                    lowerKey.includes('key')
                  ) {
                    sanitized[key] = '********';
                  } else {
                    sanitized[key] = sanitizeDeep(obj[key]);
                  }
                }
                return sanitized;
              };

              const sanitizedBody = sanitizeDeep(body);

              await this.prisma.auditLog.create({
                data: {
                  tenant_id: user.tenantId || 'global',
                  actor_id: user.sub || 'system',
                  actor_name: user.email || 'Usuario',
                  rol: user.rol || 'MEMBER',
                  accion: method,
                  entidad: entidad.toUpperCase(),
                  detalles: sanitizedBody,
                },
              });
            } catch (e) {
              console.error('Error al registrar log de auditoría:', e);
            }
          }
        }
      }),
    );
  }
}
