# Demo productiva local con contenedores

Este flujo deja `sas_gym` corriendo en modo `production` con datos persistentes, seed comercial idempotente y backend real para `superadmin`, `admin`, `caja`, `trainer` y `member`.

## Archivos fuente

- Productivo para servidor con proxy externo: `infra/docker/compose.prod.yml`
- Productivo local autónomo: `infra/docker/compose.prod.local.yml`
- Variables base: `.env.production.example`
- Variables locales listas para demo: `.env.production.local.example`

## URLs locales por defecto

- API: `http://localhost:3000/api/v1`
- WS: `ws://localhost:3001`
- App web/mobile: `http://localhost:8383`
- Admin web: `http://localhost:8282`

## Preparación

1. Tener Docker Desktop levantado.
2. Copiar `.env.production.local.example` a un `.env` real de trabajo.
3. Reemplazar todos los `CHANGE_ME`.
4. Si se usará el override local, ajustar estas variables si hace falta:
   - `API_BASE_URL=http://localhost:3000/api/v1`
   - `WS_URL=ws://localhost:3001`
   - `APP_URL=http://localhost:8383`
   - `ADMIN_URL=http://localhost:8282`
   - `CORS_ORIGINS=http://localhost:8383,http://localhost:8282`

## Arranque recomendado para demo local

```powershell
docker compose `
  --env-file .env.production.local.example `
  -f infra/docker/compose.prod.local.yml `
  up -d --build
```

## Verificación técnica mínima

```powershell
docker compose `
  --env-file .env.production.local.example `
  -f infra/docker/compose.prod.local.yml `
  ps
```

```powershell
Invoke-WebRequest http://localhost:3000/api/v1/health
Invoke-WebRequest http://localhost:3000/api/v1/health/readiness
```

El endpoint `health/readiness` debe devolver `status=ready` y tenants completos.

## Persistencia y reseed

- `postgres` y `redis` usan volúmenes persistentes.
- El arranque de `api` ejecuta:
  1. `npx prisma migrate deploy`
  2. `npm run data:reconcile`
  3. `node dist/main`
- El reconciliador productivo conserva los `qr_secret` ya existentes de socios demo para no romper el flujo QR tras reinicios.

## Credenciales demo de presentación

Las contraseñas salen de estas variables:

- `PRESENTATION_SUPERADMIN_PASSWORD`
- `PRESENTATION_ADMIN_PASSWORD`
- `PRESENTATION_TRAINER_PASSWORD`
- `PRESENTATION_CASHIER_PASSWORD`
- `PRESENTATION_MEMBER_PASSWORD`

Los usuarios sembrados siguen este patrón:

- `superadmin@sasgym.local`
- `admin.{gym_code}@sasgym.local`
- `trainer.{gym_code}@sasgym.local`
- `caja.{gym_code}@sasgym.local`
- `socio.{gym_code}@sasgym.local`

`gym_code` actuales:

- `cayma-prime`
- `yanahuara-fit`
- `cercado-performance`
- `cerro-colorado-247`

## Checklist funcional de demo

1. Login como `superadmin` y validar lista de tenants.
2. Login como `admin` y validar dashboard, socios, dietas, pagos y productos de una sola sede.
3. Login como `caja` y validar apertura/cierre, cobro y escaneo QR.
4. Login como `member` y validar perfil, membresía, dieta y QR dinámico.
5. Login como `trainer` y validar miembros asignados y rutina activa.
6. Reiniciar stack y repetir QR/attendance para confirmar persistencia.

## Recuperación rápida

Ver logs:

```powershell
docker compose `
  --env-file .env.production.local.example `
  -f infra/docker/compose.prod.local.yml `
  logs api ws admin-web app-web --tail 200
```

Reiniciar:

```powershell
docker compose `
  --env-file .env.production.local.example `
  -f infra/docker/compose.prod.local.yml `
  down

docker compose `
  --env-file .env.production.local.example `
  -f infra/docker/compose.prod.local.yml `
  up -d --build
```

Si `health/readiness` no llega a `ready`, revisar primero:

- migraciones Prisma
- variables `PRESENTATION_*`
- conectividad Postgres/Redis
- logs del reconciliador
