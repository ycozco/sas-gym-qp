# Validacion completa local - 2026-06-16

## Alcance

Validacion ejecutada en el repositorio local `sas-gym-qp`, sin tocar VPS, DNS, SSL ni Nginx Proxy Manager. Las tareas de backend se ejecutaron desde contenedores Docker.

## Cambios aplicados para subsanar fallos/advertencias

- Backend Redis: `RedisService` ahora respeta `REDIS_HOST`, `REDIS_PORT` y `REDIS_PASSWORD` cuando no existe `REDIS_URL`. Esto evita intentos de conexion a `localhost:6379` dentro del contenedor.
- Backend Docker: `backend/Dockerfile` y `backend/Dockerfile.prod` pasan de Node 20 a Node 22 para alinear local/CI y eliminar el warning AWS SDK por version de Node.
- Prisma: se migro `package.json#prisma` a `backend/prisma.config.ts` y se excluyo ese archivo del build TypeScript.
- Flutter: se eliminaron issues de `flutter analyze`, deprecaciones aplicables con `dart fix`, imports no usados y tests con imports incorrectos.
- Flutter web: `mobile_app/Dockerfile` y `.github/workflows/flutter.yml` usan `--no-wasm-dry-run` para evitar el warning wasm de una dependencia transitoria.
- Web smoke: `scripts/web-smoke-check.mjs` valida la estructura real segmentada bajo `web_admin/src/features`.

## Resultados

| Comando | Resultado |
| --- | --- |
| `docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config` | PASO |
| `docker compose --env-file .env.production.example -f infra/docker/compose.prod.yml config` | PASO |
| `docker compose --env-file .env.local.example -f infra/docker/compose.local.yml up -d --build` | PASO tras liberar puertos ocupados por contenedores antiguos |
| `curl -i http://localhost:3000/api/v1` | PASO, `200 OK`, `Hello World!` |
| `curl -I http://localhost:8383` | PASO, `200 OK` |
| `curl -I http://localhost:8282` | PASO, `200 OK` |
| `flutter analyze` | PASO, `No issues found` |
| `flutter test` | PASO, `34 tests passed` |
| `flutter build web --release --no-wasm-dry-run --dart-define=APP_ENV=ci --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://localhost:3000/api/v1` | PASO |
| `docker compose --env-file .env.local.example -f infra/docker/compose.local.yml exec api npm run build` | PASO |
| `docker compose --env-file .env.local.example -f infra/docker/compose.local.yml exec api npm test -- --runInBand` | PASO, 9 suites / 43 tests |
| `docker compose --env-file .env.local.example -f infra/docker/compose.local.yml exec api npm run test:e2e -- --runInBand` | PASO, 1 suite / 1 test |
| `docker run --rm -v /home/elvis/GymApp/sas-gym-qp:/workspace -w /workspace node:22-alpine node scripts/web-smoke-check.mjs` | PASO |
| `git diff --check` | PASO |

## Observaciones durante la ejecucion

- Fue necesario detener contenedores antiguos que ocupaban `3000`, `8282` y `8383`: `gymsmart-api`, `sas_gym_frontend`, `sas_gym_flutter_web`.
- Fue necesario recrear `admin-web` para que Docker publicara correctamente `8282`.
- `npm install` durante build informa deprecaciones/auditoria en dependencias transitorias y/o upgrades mayores (`otplib`, `glob`, `inflight`, vulnerabilidades de audit). No se aplico `npm audit fix --force` porque puede introducir cambios mayores de comportamiento.
- `npx prisma generate` ya no emite la deprecacion de `package.json#prisma`. Mantiene aviso informativo de version mayor disponible de Prisma.

## Pendientes manuales

- Validacion manual completa de SyncQueue en celular fisico con un socio que tenga rutina activa asignada.
- Confirmacion funcional end-to-end de deduplicacion persistente en backend para `/members/workout-log` usando `X-Idempotency-Key`.
- Pruebas exploratorias de negocio en Web Admin: snapshot de membresias, caja chica/idempotencia desde UI, y aislamiento multitenant mediante manipulacion de IDs/tokens.
- Revision visual humana de Light/Dark/System en pantallas criticas con criterio WCAG AA.
