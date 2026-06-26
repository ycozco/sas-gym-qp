# Ejecucion del plan de revision seguridad, dependencias y despliegue

Fecha: 2026-06-03

## Cambios ejecutados

### Base de datos y seed

- Se elimino el arranque destructivo con `prisma db push --force-reset`.
- Se elimino el seed automatico del arranque Docker.
- Se agregaron scripts backend:
  - `npm run prisma:generate`
  - `npm run db:push`
  - `npm run migrate:deploy`
  - `npm run seed:local`
  - `npm run db:setup:local`
- `infra/docker/compose.local.yml` ejecuta `npm run db:setup:local && npm run start:dev`.
- El seed queda como accion manual para datos locales, no como parte del arranque.

### Seguridad backend

- Se agrego `backend/src/core/config/env.ts` para cargar `.env` local y exigir variables criticas.
- Se elimino fallback hardcoded de `JWT_SECRET`.
- Se elimino fallback hardcoded de `HUELLA_SECRET_KEY`.
- CORS HTTP queda restringido por `CORS_ORIGINS`.
- WebSocket queda restringido por `CORS_ORIGINS`.
- WebSocket ya no acepta token por query string; usa `handshake.auth.token`.
- Logs WebSocket ya no imprimen email ni tenant.
- `/uploads` queda deshabilitado por defecto y solo se expone si `PUBLIC_UPLOADS_ENABLED=true`.
- Usuarios creados por POS ya no usan `password_hash: 'none'`; reciben hash bcrypt aleatorio no-login.
- Dockerfile backend ahora arranca con `npm run start:prod` por defecto.

### Configuracion

- Se agrego `.env.example` en la raiz.
- Se agrego `backend/.env.example`.
- Los Compose vigentes usan variables desde `.env` / plantillas de entorno para no repetir secretos en el YAML.

### Dependencias

- `npm audit --audit-level=moderate`: 0 vulnerabilidades.
- Se actualizaron dependencias backend patch/minor:
  - `eslint` a `10.4.1`
  - `ts-loader` a `9.6.0`
  - `typescript-eslint` a `8.60.1`
- Se actualizo Flutter:
  - `image` a `4.9.1`
  - lockfile actualizo tambien transitorias resolubles como `dbus` y `xml`.

## Verificacion ejecutada

```powershell
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml build api
cd backend
npm audit --audit-level=moderate
npm outdated
npm run build
npm run test
cd ../mobile_app
flutter pub outdated
flutter pub get
flutter analyze
flutter test
```

Resultados:

- `docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config`: OK.
- `docker compose --env-file .env.local.example -f infra/docker/compose.local.yml build api`: OK.
- `npm audit --audit-level=moderate`: 0 vulnerabilidades.
- `npm run build`: OK.
- `npm run test`: OK, 2 suites / 6 tests.
- `flutter analyze`: OK.
- `flutter test`: OK, 14 tests.

## Pendientes relevantes

### Dependencias

- Backend:
  - `@prisma/client` y `prisma`: `6.19.3` -> `7.8.0`. Requiere migracion planificada y pruebas de Prisma.
  - Prisma advierte que `package.json#prisma` sera removido en Prisma 7; mover seed/config a `prisma.config.ts`.
  - `otplib`: `12.0.1` -> `13.4.1`. Requiere validar compatibilidad TOTP.
  - Docker build muestra advertencias de paquetes transitorios/deprecados asociados a `otplib` 12 y `glob`.
- Flutter:
  - Direct dependencies: actualizadas.
  - Quedan transitorias bloqueadas por constraints de paquetes padre.
  - `qr` 3 -> 4 y `flutter_secure_storage_*` tienen saltos pendientes via dependencias transitivas.

### Seguridad y funcionalidad

- Crear fixtures reales de datos de prueba en vez de depender del seed historico.
- Agregar endpoint o herramienta local para generar QRs reales de prueba desde secretos en BD.
- Proteger descargas de comprobantes/observaciones con endpoints autenticados por tenant.
- Validar magic bytes de uploads.
- Agregar rate limiting en login/forgot-password/asistencia.
- Implementar transacciones Prisma e idempotencia en pagos/caja/membresias.
- Separar compose dev/staging/prod.
- Preparar migraciones Prisma reales para reemplazar `db:push` en staging/prod.
