import { ExecutionContext, HttpException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { RateLimitingGuard } from './rate-limiting.guard';
import { RedisService } from '../services/redis.service';

describe('RateLimitingGuard', () => {
  let guard: RateLimitingGuard;
  let redisService: jest.Mocked<Partial<RedisService>>;

  beforeEach(async () => {
    redisService = {
      exists: jest.fn(),
      incrWithTtl: jest.fn(),
      set: jest.fn(),
      del: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RateLimitingGuard,
        {
          provide: RedisService,
          useValue: redisService,
        },
      ],
    }).compile();

    guard = module.get<RateLimitingGuard>(RateLimitingGuard);
  });

  const createMockContext = (
    path: string,
    method: string,
    body: any,
    ip: string,
    headers: any = {},
  ): ExecutionContext => {
    const req = {
      path,
      method,
      body,
      ip,
      headers,
      socket: { remoteAddress: ip },
    };

    const res = {
      statusCode: 200,
      on: jest.fn((event, callback) => {
        // Guardamos el callback para dispararlo manualmente en el test
        (res as any)._listeners = (res as any)._listeners || {};
        (res as any)._listeners[event] = callback;
      }),
      _triggerFinish: () => {
        if ((res as any)._listeners && (res as any)._listeners['finish']) {
          (res as any)._listeners['finish']();
        }
      },
    };

    return {
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => res,
      }),
    } as unknown as ExecutionContext;
  };

  it('debe permitir peticiones que no son del endpoint /auth/login', async () => {
    const context = createMockContext(
      '/api/v1/members',
      'GET',
      {},
      '127.0.0.1',
    );
    const result = await guard.canActivate(context);
    expect(result).toBe(true);
    expect(redisService.exists).not.toHaveBeenCalled();
  });

  it('debe permitir peticiones de login si el IP y el email no están bloqueados', async () => {
    redisService.exists.mockResolvedValue(0); // 0 indica no existe (no bloqueado)

    const context = createMockContext(
      '/api/v1/auth/login',
      'POST',
      { email: 'test@gym.com' },
      '192.168.1.10',
    );
    const result = await guard.canActivate(context);

    expect(result).toBe(true);
    expect(redisService.exists).toHaveBeenCalledWith(
      'rate:block:ip:192.168.1.10',
    );
    expect(redisService.exists).toHaveBeenCalledWith(
      'rate:block:email:test@gym.com',
    );
  });

  it('debe lanzar HttpException 429 si el IP está bloqueado', async () => {
    redisService.exists.mockImplementation(async (key) => {
      if (key === 'rate:block:ip:192.168.1.10') return 1;
      return 0;
    });

    const context = createMockContext(
      '/api/v1/auth/login',
      'POST',
      { email: 'test@gym.com' },
      '192.168.1.10',
    );

    await expect(guard.canActivate(context)).rejects.toThrow(HttpException);
    await expect(guard.canActivate(context)).rejects.toThrow(
      'Demasiados intentos fallidos. Por seguridad, el acceso ha sido bloqueado por 15 minutos.',
    );
  });

  it('debe lanzar HttpException 429 si el email del usuario está bloqueado', async () => {
    redisService.exists.mockImplementation(async (key) => {
      if (key === 'rate:block:email:blocked@gym.com') return 1;
      return 0;
    });

    const context = createMockContext(
      '/api/v1/auth/login',
      'POST',
      { email: 'blocked@gym.com' },
      '192.168.1.10',
    );

    await expect(guard.canActivate(context)).rejects.toThrow(HttpException);
  });

  it('debe resetear contadores en Redis tras un login exitoso (status 200/201)', async () => {
    redisService.exists.mockResolvedValue(0);

    const context = createMockContext(
      '/api/v1/auth/login',
      'POST',
      { email: 'success@gym.com' },
      '192.168.1.10',
    );
    const res = context.switchToHttp().getResponse() as any;

    await guard.canActivate(context);

    // Simular éxito
    res.statusCode = 200;
    res._triggerFinish();

    // Esperar a que se resuelvan las llamadas asíncronas en el callback finish
    await new Promise((resolve) => setTimeout(resolve, 10));

    // Debió borrar los contadores de fallos
    expect(redisService.del).toHaveBeenCalledWith('rate:fail:ip:192.168.1.10');
    expect(redisService.del).toHaveBeenCalledWith(
      'rate:fail:email:success@gym.com',
    );
  });

  it('debe incrementar contadores y bloquear si se alcanzan los 5 intentos fallidos (status 401/403)', async () => {
    redisService.exists.mockResolvedValue(0);
    redisService.incrWithTtl.mockResolvedValue(5); // Retorna 5 en la llamada

    const context = createMockContext(
      '/api/v1/auth/login',
      'POST',
      { email: 'fail@gym.com' },
      '192.168.1.10',
    );
    const res = context.switchToHttp().getResponse() as any;

    await guard.canActivate(context);

    // Simular fallo
    res.statusCode = 401;
    res._triggerFinish();

    // Esperar a que se resuelvan las llamadas asíncronas en el callback finish
    await new Promise((resolve) => setTimeout(resolve, 10));

    // Debió incrementar
    expect(redisService.incrWithTtl).toHaveBeenCalledWith(
      'rate:fail:ip:192.168.1.10',
      900,
    );
    expect(redisService.incrWithTtl).toHaveBeenCalledWith(
      'rate:fail:email:fail@gym.com',
      900,
    );

    // Debió crear llaves de bloqueo por alcanzar 5
    expect(redisService.set).toHaveBeenCalledWith(
      'rate:block:ip:192.168.1.10',
      '1',
      900,
    );
    expect(redisService.set).toHaveBeenCalledWith(
      'rate:block:email:fail@gym.com',
      '1',
      900,
    );
  });
});
