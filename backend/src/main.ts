import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import helmet from 'helmet';
import { join } from 'path';
import { getCorsOrigins, getOptionalEnv } from './core/config/env';

const authFailures = new Map<string, number[]>();
const blockedIps = new Map<string, number>();
const FAILURE_WINDOW_MS = 5 * 60 * 1000;
const BLOCK_WINDOW_MS = 15 * 60 * 1000;
const MAX_FAILURES = 10;

function clientIp(req: express.Request): string {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string') return forwarded.split(',')[0].trim();
  return req.ip || req.socket.remoteAddress || 'unknown';
}

function securityBlockMiddleware(
  req: express.Request,
  res: express.Response,
  next: express.NextFunction,
) {
  const ip = clientIp(req);
  const blockedUntil = blockedIps.get(ip);
  if (blockedUntil && blockedUntil > Date.now()) {
    res.status(429).json({
      statusCode: 429,
      message: 'IP temporalmente bloqueada por intentos fallidos repetidos.',
    });
    return;
  }
  if (blockedUntil) blockedIps.delete(ip);

  res.on('finish', () => {
    if (res.statusCode !== 401 && res.statusCode !== 403) return;
    const now = Date.now();
    const failures = (authFailures.get(ip) || []).filter(
      (timestamp) => now - timestamp <= FAILURE_WINDOW_MS,
    );
    failures.push(now);
    authFailures.set(ip, failures);
    if (failures.length > MAX_FAILURES) {
      blockedIps.set(ip, now + BLOCK_WINDOW_MS);
      authFailures.delete(ip);
    }
  });

  next();
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  app.use(securityBlockMiddleware);

  // Servir archivos estáticos localmente desde la carpeta uploads
  if (getOptionalEnv('PUBLIC_UPLOADS_ENABLED', 'false') === 'true') {
    app.use('/uploads', express.static(join(process.cwd(), 'uploads')));
  }

  // Prefijo global para la API móvil y web
  app.setGlobalPrefix('api/v1');

  app.enableCors({
    origin: getCorsOrigins(),
    credentials: true,
  });

  // Validaciones globales usando class-validator
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // Elimina propiedades que no estén en el DTO
      transform: true,        // Transforma payloads a instancias de sus DTOs correspondientes
      forbidNonWhitelisted: true, // Lanza error si se envían propiedades no permitidas
    }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Servidor de SaasGym ejecutándose en: http://localhost:${port}/api/v1`);
}
bootstrap();
