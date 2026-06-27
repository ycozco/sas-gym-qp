import {
  CanActivate,
  ExecutionContext,
  Injectable,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { RedisService } from '../services/redis.service';

@Injectable()
export class RateLimitingGuard implements CanActivate {
  private readonly logger = new Logger(RateLimitingGuard.name);

  // Umbral: 5 intentos fallidos consecutivos
  private readonly MAX_ATTEMPTS = 5;
  // Ventana de tiempo de intentos: 15 minutos
  private readonly WINDOW_SECONDS = 900;
  // Bloqueo: 15 minutos
  private readonly BLOCK_SECONDS = 900;

  constructor(private readonly redisService: RedisService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const http = context.switchToHttp();
    const req = http.getRequest();
    const res = http.getResponse();

    const path = req.path || req.url;
    const isLogin = path.includes('/auth/login') && req.method === 'POST';

    if (!isLogin) {
      return true;
    }

    const ip = this.getClientIp(req);
    const email = (req.body?.email || '').trim().toLowerCase();

    // 1. Verificar si el IP o el usuario están bloqueados
    const ipBlockKey = `rate:block:ip:${ip}`;
    const emailBlockKey = `rate:block:email:${email}`;

    const isIpBlocked = await this.redisService.exists(ipBlockKey);
    const isEmailBlocked = email
      ? await this.redisService.exists(emailBlockKey)
      : 0;

    if (isIpBlocked || isEmailBlocked) {
      this.logger.warn(
        `Intento de login denegado: IP ${ip} o Email ${email} bloqueados temporalmente.`,
      );
      throw new HttpException(
        'Demasiados intentos fallidos. Por seguridad, el acceso ha sido bloqueado por 15 minutos.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 2. Registrar el listener para evaluar el resultado del login
    res.on('finish', async () => {
      const statusCode = res.statusCode;

      if (statusCode === 200 || statusCode === 201) {
        // Login exitoso: Resetear los contadores de fallos
        const ipFailKey = `rate:fail:ip:${ip}`;
        const emailFailKey = `rate:fail:email:${email}`;
        await this.redisService.del(ipFailKey);
        if (email) {
          await this.redisService.del(emailFailKey);
        }
        this.logger.log(
          `Login exitoso para ${email} desde IP ${ip}. Contadores reseteados.`,
        );
      } else if (statusCode === 401 || statusCode === 403) {
        // Login fallido: Incrementar contadores
        const ipFailKey = `rate:fail:ip:${ip}`;
        const ipAttempts = await this.redisService.incrWithTtl(
          ipFailKey,
          this.WINDOW_SECONDS,
        );

        let emailAttempts = 0;
        if (email) {
          const emailFailKey = `rate:fail:email:${email}`;
          emailAttempts = await this.redisService.incrWithTtl(
            emailFailKey,
            this.WINDOW_SECONDS,
          );
        }

        this.logger.warn(
          `Intento de login fallido desde IP ${ip} (intento ${ipAttempts}) para email ${email} (intento ${emailAttempts})`,
        );

        // Si sobrepasan el máximo de intentos, aplicar bloqueo
        if (ipAttempts >= this.MAX_ATTEMPTS) {
          await this.redisService.set(ipBlockKey, '1', this.BLOCK_SECONDS);
          this.logger.error(
            `IP ${ip} bloqueada por 15 minutos debido a ${ipAttempts} fallos consecutivos.`,
          );
        }

        if (email && emailAttempts >= this.MAX_ATTEMPTS) {
          await this.redisService.set(emailBlockKey, '1', this.BLOCK_SECONDS);
          this.logger.error(
            `Usuario ${email} bloqueado por 15 minutos debido a ${emailAttempts} fallos consecutivos.`,
          );
        }
      }
    });

    return true;
  }

  private getClientIp(req: any): string {
    const forwarded = req.headers['x-forwarded-for'];
    if (typeof forwarded === 'string') {
      return forwarded.split(',')[0].trim();
    }
    return req.ip || req.socket?.remoteAddress || 'unknown';
  }
}
