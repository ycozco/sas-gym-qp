import { CallHandler, ExecutionContext } from '@nestjs/common';
import { of } from 'rxjs';
import { AuditInterceptor } from './audit.interceptor';
import { PrismaService } from '../../prisma/prisma.service';

describe('AuditInterceptor', () => {
  let interceptor: AuditInterceptor;
  let prisma: jest.Mocked<Partial<PrismaService>>;

  beforeEach(() => {
    prisma = {
      auditLog: {
        create: jest.fn().mockResolvedValue({}),
      } as any,
    };
    interceptor = new AuditInterceptor(prisma as PrismaService);
  });

  const createContext = (request: any): ExecutionContext =>
    ({
      switchToHttp: () => ({
        getRequest: () => request,
      }),
    }) as unknown as ExecutionContext;

  const handler: CallHandler = {
    handle: () => of({ ok: true }),
  };

  it('registra detalles vacios cuando la peticion no trae body', async () => {
    const request = {
      method: 'POST',
      url: '/api/v1/observations/upload',
      user: {
        tenantId: 'tenant-1',
        sub: 'user-1',
        email: 'trainer@test.sasgym.com',
        rol: 'TRAINER',
      },
    };

    await interceptor.intercept(createContext(request), handler).toPromise();
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(prisma.auditLog?.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        tenant_id: 'tenant-1',
        actor_id: 'user-1',
        accion: 'POST',
        entidad: 'OBSERVATIONS',
        detalles: {},
      }),
    });
  });

  it('sanitiza secretos en detalles de auditoria', async () => {
    const request = {
      method: 'PATCH',
      url: '/api/v1/auth/me/profile',
      body: {
        nombre: 'Test',
        nested: {
          refreshToken: 'secret-token',
        },
      },
      user: {
        tenantId: 'tenant-1',
        sub: 'user-1',
        email: 'member@test.sasgym.com',
        rol: 'MEMBER',
      },
    };

    await interceptor.intercept(createContext(request), handler).toPromise();
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(prisma.auditLog?.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        detalles: {
          nombre: 'Test',
          nested: {
            refreshToken: '********',
          },
        },
      }),
    });
  });
});
