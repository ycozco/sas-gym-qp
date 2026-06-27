import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { from, Observable } from 'rxjs';
import { lastValueFrom } from 'rxjs';
import { RedisService } from '../services/redis.service';

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  private readonly logger = new Logger(IdempotencyInterceptor.name);
  private readonly TTL_SECONDS = 86400; // 24 horas

  constructor(private readonly redisService: RedisService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const http = context.switchToHttp();
    const req = http.getRequest();
    const res = http.getResponse();

    const idempotencyKey =
      req.headers['idempotency-key'] || req.headers['Idempotency-Key'];

    if (req.method !== 'POST' || !idempotencyKey) {
      return next.handle();
    }

    return from(
      this.handleIdempotency(idempotencyKey as string, context, next),
    );
  }

  private async handleIdempotency(
    key: string,
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<any> {
    const redisKey = `idem:${key}`;
    const redis = this.redisService.getClient();

    // Intentar adquirir de forma atómica el estado "IN_PROGRESS"
    // NX: Solo si no existe
    // EX: Expiración en segundos
    const acquired = await (redis as any).set(
      redisKey,
      'IN_PROGRESS',
      'NX',
      'EX',
      this.TTL_SECONDS,
    );

    if (acquired === 'OK') {
      // Primera vez que se recibe esta clave: Procesar la petición
      this.logger.log(
        `Clave de idempotencia adquirida: ${key}. Procesando petición.`,
      );
      try {
        const result = await lastValueFrom(next.handle());

        // Guardar resultado exitoso en Redis
        const httpResponse = context.switchToHttp().getResponse();
        const cachedData = {
          status: httpResponse.statusCode || HttpStatus.CREATED,
          body: result,
        };

        await this.redisService.set(
          redisKey,
          JSON.stringify(cachedData),
          this.TTL_SECONDS,
        );
        return result;
      } catch (err) {
        // Si la petición falla, liberamos la clave para permitir reintentos
        await this.redisService.del(redisKey);
        this.logger.warn(
          `Petición fallida para clave ${key}. Clave liberada para reintentos.`,
        );
        throw err;
      }
    } else {
      // La clave ya existe en Redis (duplicada o ya resuelta)
      const stored = await this.redisService.get(redisKey);

      if (stored === 'IN_PROGRESS') {
        // Petición idéntica concurrente en curso
        this.logger.warn(
          `Intento concurrente detectado para clave ${key}. Retornando HTTP 409.`,
        );
        throw new HttpException(
          'Hay otra transacción idéntica en proceso. Por favor, espere.',
          HttpStatus.CONFLICT,
        );
      }

      if (stored) {
        // Petición resuelta anteriormente. Retornar el resultado en caché.
        this.logger.log(
          `Clave de idempotencia resuelta anteriormente: ${key}. Retornando caché.`,
        );
        const cached = JSON.parse(stored);
        const res = context.switchToHttp().getResponse();
        res.status(cached.status);
        return cached.body;
      }

      // Fallback si por alguna razón no hay valor
      throw new HttpException(
        'Error al procesar la clave de idempotencia.',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
