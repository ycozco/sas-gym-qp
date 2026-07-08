process.env.TZ = 'America/Lima';
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

  // ─── SEGURIDAD HTTP ────────────────────────────────────────────────
  const isProd = process.env.NODE_ENV === 'production';

  app.use(
    helmet({
      contentSecurityPolicy: isProd
        ? {
            directives: {
              defaultSrc: ["'self'"],
              styleSrc: ["'self'", "'unsafe-inline'"],
              imgSrc: ["'self'", 'data:', 'blob:'],
              fontSrc: ["'self'"],
              scriptSrc: ["'self'"],
              connectSrc: ["'self'"],
              frameSrc: ["'none'"],
            },
          }
        : false, // Desactivado en dev para facilitar depuración
      hsts: isProd ? { maxAge: 31536000, includeSubDomains: true } : false,
      crossOriginEmbedderPolicy: false, // Compatible con Flutter WebView
    }),
  );

  app.use(securityBlockMiddleware);

  // ─── UPLOADS ESTÁTICOS ────────────────────────────────────────────
  if (getOptionalEnv('PUBLIC_UPLOADS_ENABLED', 'false') === 'true') {
    app.use('/uploads', express.static(join(process.cwd(), 'uploads')));
  }

  // ─── FRONTEND ESTÁTICO UNIFICADO (LANDING, ADMIN Y WEBAPP) ────────
  const publicPath = join(process.cwd(), 'public');
  app.use('/admin', express.static(join(publicPath, 'admin')));
  app.use('/app', express.static(join(publicPath, 'app')));
  app.use('/', express.static(join(publicPath, 'landing')));

  // ─── PREFIJO GLOBAL ───────────────────────────────────────────────
  app.setGlobalPrefix('api/v1');

  // ─── CORS ─────────────────────────────────────────────────────────
  app.enableCors({
    origin: getCorsOrigins(),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Tenant-ID',
      'X-Request-ID',
    ],
  });

  // ─── VALIDACIÓN GLOBAL ────────────────────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);

  const env = process.env.NODE_ENV || 'development';
  console.log(`
  ╔════════════════════════════════════════════╗
  ║   SaaSGYM API — ${env.toUpperCase().padEnd(26)}║
  ║   Entorno: ${env.padEnd(32)}║
  ║   Puerto:  ${String(port).padEnd(32)}║
  ║   Ruta:    /api/v1                         ║
  ╚════════════════════════════════════════════╝
  `);
}
void bootstrap();
