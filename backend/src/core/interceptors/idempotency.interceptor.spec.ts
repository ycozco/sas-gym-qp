import { ExecutionContext, CallHandler, HttpException, HttpStatus } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { of, throwError } from 'rxjs';
import { IdempotencyInterceptor } from './idempotency.interceptor';
import { RedisService } from '../services/redis.service';

describe('IdempotencyInterceptor', () => {
  let interceptor: IdempotencyInterceptor;
  let redisService: jest.Mocked<Partial<RedisService>>;
  let mockRedisClient: any;

  beforeEach(async () => {
    mockRedisClient = {
      set: jest.fn(),
    };

    redisService = {
      getClient: jest.fn().mockReturnValue(mockRedisClient),
      get: jest.fn(),
      set: jest.fn(),
      del: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        IdempotencyInterceptor,
        {
          provide: RedisService,
          useValue: redisService,
        },
      ],
    }).compile();

    interceptor = module.get<IdempotencyInterceptor>(IdempotencyInterceptor);
  });

  const createMockContext = (
    method: string,
    headers: any = {},
  ): ExecutionContext => {
    const req = {
      method,
      headers,
    };

    const res = {
      statusCode: 200,
      status: jest.fn().mockImplementation(function(this: any, code: number) {
        this.statusCode = code;
        return this;
      }),
    };

    return {
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => res,
      }),
    } as unknown as ExecutionContext;
  };

  const createMockHandler = (result: any = 'success_response'): CallHandler => {
    return {
      handle: () => of(result),
    };
  };

  it('debe ignorar peticiones que no son POST', async () => {
    const context = createMockContext('GET', { 'idempotency-key': 'key123' });
    const handler = createMockHandler();

    const result = await interceptor.intercept(context, handler).toPromise();
    expect(result).toBe('success_response');
    expect(redisService.getClient).not.toHaveBeenCalled();
  });

  it('debe ignorar peticiones POST sin cabecera idempotency-key', async () => {
    const context = createMockContext('POST', {});
    const handler = createMockHandler();

    const result = await interceptor.intercept(context, handler).toPromise();
    expect(result).toBe('success_response');
    expect(redisService.getClient).not.toHaveBeenCalled();
  });

  it('debe procesar primera petición, guardarla en Redis y retornar respuesta original', async () => {
    mockRedisClient.set.mockResolvedValue('OK'); // Lock adquirido
    const context = createMockContext('POST', { 'idempotency-key': 'key123' });
    const handler = createMockHandler('payment_done');

    const result = await interceptor.intercept(context, handler).toPromise();

    expect(result).toBe('payment_done');
    expect(mockRedisClient.set).toHaveBeenCalledWith('idem:key123', 'IN_PROGRESS', 'NX', 'EX', 86400);
    expect(redisService.set).toHaveBeenCalledWith(
      'idem:key123',
      JSON.stringify({ status: 200, body: 'payment_done' }),
      86400,
    );
  });

  it('debe liberar clave en Redis si la ejecución de la petición falla', async () => {
    mockRedisClient.set.mockResolvedValue('OK');
    const context = createMockContext('POST', { 'idempotency-key': 'key_fail' });
    const handler = {
      handle: () => throwError(() => new Error('Db Error')),
    };

    await expect(interceptor.intercept(context, handler).toPromise()).rejects.toThrow('Db Error');
    expect(redisService.del).toHaveBeenCalledWith('idem:key_fail');
  });

  it('debe lanzar conflicto (409) si hay una petición concurrente en curso', async () => {
    mockRedisClient.set.mockResolvedValue(null); // No adquirió el lock (ya existe)
    redisService.get.mockResolvedValue('IN_PROGRESS');

    const context = createMockContext('POST', { 'idempotency-key': 'key_locked' });
    const handler = createMockHandler();

    await expect(interceptor.intercept(context, handler).toPromise()).rejects.toThrow(
      new HttpException(
        'Hay otra transacción idéntica en proceso. Por favor, espere.',
        HttpStatus.CONFLICT,
      ),
    );
  });

  it('debe retornar directamente respuesta en caché si la clave fue resuelta anteriormente', async () => {
    mockRedisClient.set.mockResolvedValue(null); // No adquirió
    const cachedResponse = {
      status: 201,
      body: 'previous_cached_result',
    };
    redisService.get.mockResolvedValue(JSON.stringify(cachedResponse));

    const context = createMockContext('POST', { 'idempotency-key': 'key_cached' });
    const res = context.switchToHttp().getResponse() as any;
    const handler = createMockHandler('should_not_run_this');

    const result = await interceptor.intercept(context, handler).toPromise();

    expect(result).toBe('previous_cached_result');
    expect(res.status).toHaveBeenCalledWith(201);
  });
});
