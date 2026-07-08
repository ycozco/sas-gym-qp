import {
  CallHandler,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { from, lastValueFrom, Observable } from 'rxjs';
import { RedisService } from '../services/redis.service';

interface CachedResponse {
  status: number;
  body: unknown;
}

function parseCachedResponse(value: string): CachedResponse {
  const parsed: unknown = JSON.parse(value);
  if (!parsed || typeof parsed !== 'object')
    throw new Error('Respuesta idempotente invalida.');
  const record = parsed as Record<string, unknown>;
  if (typeof record.status !== 'number')
    throw new Error('Estado idempotente invalido.');
  return { status: record.status, body: record.body };
}

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor<
  unknown,
  unknown
> {
  private readonly logger = new Logger(IdempotencyInterceptor.name);
  private readonly TTL_SECONDS = 86400;

  constructor(private readonly redisService: RedisService) {}

  intercept(
    context: ExecutionContext,
    next: CallHandler<unknown>,
  ): Observable<unknown> {
    const req = context.switchToHttp().getRequest<Request>();
    const header = req.headers['idempotency-key'];
    const key = Array.isArray(header) ? header[0] : header;

    if (req.method !== 'POST' || !key) return next.handle();
    return from(this.handleIdempotency(key, context, next));
  }

  private async handleIdempotency(
    key: string,
    context: ExecutionContext,
    next: CallHandler<unknown>,
  ): Promise<unknown> {
    const redisKey = `idem:${key}`;

    let acquired: string | null;
    try {
      acquired = await this.redisService
        .getClient()
        .set(redisKey, 'IN_PROGRESS', 'EX', this.TTL_SECONDS, 'NX');
    } catch (err: any) {
      this.logger.warn(
        `Redis disconnected, bypassing idempotency check: ${err.message || err}`,
      );
      return lastValueFrom(next.handle());
    }

    if (acquired! === 'OK') {
      this.logger.log(
        `Clave de idempotencia adquirida: ${key}. Procesando petición.`,
      );
      try {
        const result = await lastValueFrom(next.handle());
        const response = context.switchToHttp().getResponse<Response>();
        const cachedData: CachedResponse = {
          status: response.statusCode || HttpStatus.CREATED,
          body: result,
        };
        try {
          await this.redisService.set(
            redisKey,
            JSON.stringify(cachedData),
            this.TTL_SECONDS,
          );
        } catch (e: any) {
          this.logger.warn(
            `Failed to cache response in Redis: ${e.message || e}`,
          );
        }
        return result;
      } catch (error: unknown) {
        try {
          await this.redisService.del(redisKey);
        } catch (e: any) {
          this.logger.warn(
            `Failed to delete idempotency key in Redis: ${e.message || e}`,
          );
        }
        this.logger.warn(
          `Petición fallida para clave ${key}. Clave liberada para reintentos.`,
        );
        throw error;
      }
    }

    let stored: string | null;
    try {
      stored = await this.redisService.get(redisKey);
    } catch (e: any) {
      this.logger.warn(
        `Failed to read idempotency key in Redis: ${e.message || e}`,
      );
      return lastValueFrom(next.handle());
    }

    if (stored! === 'IN_PROGRESS') {
      throw new HttpException(
        'Hay otra transacción idéntica en proceso. Por favor, espere.',
        HttpStatus.CONFLICT,
      );
    }
    if (stored) {
      const cached = parseCachedResponse(stored);
      context.switchToHttp().getResponse<Response>().status(cached.status);
      return cached.body;
    }
    throw new HttpException(
      'Error al procesar la clave de idempotencia.',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }
}
