# Security Scan & Audit Report

Fecha: 2026-06-04

## Estado Cotejado

- JWT access token: implementado con TTL configurable por `JWT_ACCESS_TTL`, por defecto `15m`.
- Refresh token: implementado como cookie `sasgym_refresh` con `HttpOnly`, `SameSite=Strict`, `Secure` en produccion y `Max-Age` configurable por `JWT_REFRESH_DAYS`.
- Rotacion: cada `/auth/refresh` crea una nueva sesion, revoca la anterior y marca `replaced_by_id`.
- Logout: `/auth/logout` revoca el hash de refresh token y limpia cookie.
- Hash refresh token: se guarda SHA-256 del token aleatorio, nunca el token plano.
- Password hashing: se mantiene bcrypt con 10 rondas.
- Guards: `AuthGuard`, `RolesGuard` y `TenantGuard` activos.
- Validacion DTO: `ValidationPipe` global con `whitelist`, `transform` y `forbidNonWhitelisted`.
- SQLi: las consultas operativas usan Prisma ORM y tenant context.
- Helmet: activado en `main.ts`.
- Rate limiting: `@nestjs/throttler` global con 100 requests/min/IP.
- IP block: middleware in-memory bloquea 15 minutos si hay mas de 10 respuestas `401/403` en 5 minutos.
- CORS: restringido por `CORS_ORIGINS`.
- Produccion seed: `seed.ts` evita reset destructivo cuando `NODE_ENV=production`.

## Evidencia Ejecutada

- `npm run build`: OK.
- `docker compose exec -T api npm run build`: OK.
- `docker compose exec -T api npx prisma db push`: OK.
- Login real emite access token y cookie refresh `HttpOnly`/`SameSite=Strict`.
- Refresh rota token: el refresh token viejo devuelve `401`.
- Logout revoca sesion: refresh posterior devuelve `401`.
- Helmet expone headers `X-Frame-Options` y `X-Content-Type-Options`.
- Bloqueo por IP: al intento fallido 12 se devuelve `429`.

## Pendientes Para Produccion Multi-Replica

- Sustituir cache in-memory de bloqueo IP por Redis o store compartido.
- Mover secretos a secret manager del orquestador.
- Usar `migrate deploy` en produccion y no `db push`.
- Definir `CORS_ORIGINS` solo con dominios finales.
- Mantener `PUBLIC_UPLOADS_ENABLED=false` salvo proxy/CDN controlado.
