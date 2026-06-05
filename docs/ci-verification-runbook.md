# CI y Verificación

Guía operativa para la validación continua de `backend`, `mobile_app` y `web_admin`.

## Workflows

### `backend.yml`

- `npm ci`
- `npm run build`
- `npm test`
- `npm run test:e2e`

Usa PostgreSQL de GitHub Actions y copia `backend/.env.example` a `backend/.env` antes de ejecutar Prisma.

### `flutter.yml`

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`

Smoke prioritarios:

- `test/smoke/ui_theme_preferences_test.dart`
- `test/smoke/mobile_security_flags_test.dart`

### `web-smoke.yml`

Valida el panel web estático sin levantar backend:

- presencia de `web_admin/index.html`
- orden esperado de bundles `shared/data/dashboards/modules/modules2/app`
- referencias a `auth/me`, `tenants/me`, `membership-plans`, `products`, `reports/dashboard`
- sincronización de `themeMode` con backend y `localStorage`

### `integration.yml`

Levanta el stack con `docker compose up --build -d` y verifica:

- health de `api`, `web`, `frontend-web`
- login por roles
- `/auth/me`, `/tenants/me`, `/auth/refresh`, `/auth/logout`
- carga web base en `http://localhost:8282/web/index.html`
- endpoints visibles: `membership-plans`, `products`, `members/assigned`, `payments/me`, `schedules`, `points/catalog`

## Comandos locales equivalentes

```powershell
cd backend
npm ci
npm run build
npm test
npm run test:e2e
```

```powershell
cd mobile_app
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

```powershell
cd d:\proyectos\sas_gym
node scripts\web-smoke-check.mjs
docker compose up --build -d
node scripts\integration-smoke.mjs
docker compose down -v
```

## Aceptación mínima por PR

- Backend verde.
- Flutter verde.
- Smoke web verde.
- Integración verde.
- Si falla integración, se publican logs de Docker y el resumen del smoke como artifacts.
