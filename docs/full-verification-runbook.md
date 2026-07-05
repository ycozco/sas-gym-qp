# Verificacion Integral

Runner reproducible para validar `sas_gym` en frontend, backend, Docker, endpoints y seguridad.

## Comando principal

```powershell
cd d:\proyectos\sas_gym
node scripts\full-verification.mjs
```

## Modos utiles

```powershell
node scripts\full-verification.mjs --skip-flutter
node scripts\full-verification.mjs --skip-backend
node scripts\full-verification.mjs --skip-docker
node scripts\full-verification.mjs --skip-security
node scripts\full-verification.mjs --keep-stack
```

## Qué ejecuta

- `docker compose config` y `docker compose -f docker-compose.dev.yml config`
- Backend: `npm ci`, Prisma, lint, build, unit tests, e2e
- Flutter: `flutter pub get`, `flutter analyze`, format check, tests, build web
- Panel web: `node scripts/web-smoke-check.mjs`
- Integración: `docker compose up --build -d` + `node scripts/integration-smoke.mjs`
- Seguridad HTTP: login, `/auth/me`, refresh/logout, cross-tenant, rate limiting, idempotencia, uploads adulterados
- Evidencia auxiliar: logs Docker e inspección de contenedores

## Artifacts

Cada ejecución crea una carpeta en `.artifacts/verification-<timestamp>/` con:

- `summary.md`: bitácora resumida
- `summary.json`: salida estructurada
- `*.log`: salida de cada comando o suite
- `security-http.log`: traza de checks HTTP

## Criterio de lectura

- `OK`: el check pasó.
- `FAIL`: el check falló y queda como hallazgo.
- Los hallazgos se clasifican en `critical`, `high` o `medium`.

## Notas actuales

- La verificación de biometría en tiempo real se cubre por la spec `biometric-handshake.gateway.spec.ts`.
- El check de uploads adulterados está diseñado para detectar si el backend sigue aceptando archivos por mimetype sin validar `magic bytes`.
- El check de rate limiting observa el comportamiento externo del login; sirve aunque coexistían capas de bloqueo distintas.
