import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('AuthService', () => {
  let service: AuthService;
  let prisma: jest.Mocked<Partial<PrismaService>>;
  let jwtService: jest.Mocked<Partial<JwtService>>;

  beforeEach(() => {
    prisma = {
      refreshTokenSession: {
        create: jest.fn().mockResolvedValue({}),
      } as any,
      auditLog: {
        create: jest.fn().mockResolvedValue({}),
      } as any,
    };
    jwtService = {
      signAsync: jest.fn().mockResolvedValue('access-token'),
    };
    service = new AuthService(
      prisma as PrismaService,
      jwtService as JwtService,
    );
  });

  it('registra auditoria de login exitoso sin exponer credenciales ni tokens', async () => {
    const result = await service.login(
      {
        id: 'user-1',
        email: 'trainer1.surco@test.sasgym.com',
        rol: 'TRAINER',
        tenant_id: 'tenant-1',
        nombre_completo: 'Trainer Test',
        theme_preference: null,
      },
      {
        ip: '192.168.1.20',
        userAgent: 'Flutter test',
      },
    );

    expect(result.accessToken).toBe('access-token');
    expect(prisma.auditLog?.create).toHaveBeenCalledWith({
      data: {
        tenant_id: 'tenant-1',
        actor_id: 'user-1',
        actor_name: 'trainer1.surco@test.sasgym.com',
        rol: 'TRAINER',
        accion: 'LOGIN',
        entidad: 'AUTH',
        detalles: {
          ip: '192.168.1.20',
          userAgent: 'Flutter test',
        },
      },
    });
  });
});
