# Planificacion de proyeccion web / backend / sistema - SaaaS GYM

## Objetivo

Definir la planificacion para evolucionar el sistema web/backend de SaaaS GYM hacia una plataforma segura, testeable y desplegable. Incluye API NestJS, PostgreSQL, Flutter web, hub de mockups/docs y contenedores locales.

Este documento complementa `proyeccion.md`, que contiene los hallazgos tecnicos y de seguridad ordenados por criticidad.

## Entorno local disponible

El proyecto usa Compose vigente solo desde `infra/docker/compose.local.yml`:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Servicios principales:

| Servicio | Contenedor | Uso | URL / Puerto |
|---|---|---|---|
| `postgres` | `sasgym_postgres_local` | PostgreSQL local | `localhost:5432` |
| `redis` | `sasgym_redis_local` | Redis local | `localhost:6379` |
| `api` | `sasgym_api_local` | Backend NestJS | `http://localhost:3000` |
| `app-web` | `sasgym_app_web_local` | Flutter web compilado | `http://localhost:8383` |
| `admin-web` | `sasgym_admin_web_local` | Hub, docs y mockups | `http://localhost:8282` |

Comandos utiles:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml ps
docker compose --env-file .env -f infra/docker/compose.local.yml logs api
docker compose --env-file .env -f infra/docker/compose.local.yml logs app-web
docker compose --env-file .env -f infra/docker/compose.local.yml logs admin-web
```

Nota critica: el Compose local ejecuta `npm run db:setup:local`. Si `ALLOW_TEST_DATA_RESET=true`, puede resetear datos locales incompatibles; por eso debe tratarse como entorno de desarrollo/pruebas, no produccion.

## Meta web-sistema

Convertir el backend y sistema web en una plataforma segura y desplegable: API NestJS, base PostgreSQL, Flutter web, hub de mockups/docs y contenedores endurecidos.

## Fase W0 - Estabilizacion del entorno local

Objetivo: usar los contenedores locales como entorno reproducible de desarrollo.

Tareas:

- Levantar entorno con `docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build`.
- Confirmar:
  - API en `http://localhost:3000`.
  - Flutter web en `http://localhost:8383`.
  - Hub en `http://localhost:8282`.
  - PostgreSQL en `127.0.0.1:5432`.
- Ejecutar pruebas backend:

```powershell
cd backend
npm run build
npm run test
npm run test:e2e
```

- Revisar logs del contenedor `api`.
- Identificar errores de seed, Prisma o rutas.

Criterio de salida:

- Contenedores principales levantan.
- API responde.
- Backend build/test pasa o deja lista de bloqueos concreta.

## Fase W1 - Seguridad base del backend

Objetivo: cerrar riesgos P0/P1 antes de staging.

Tareas:

- Eliminar fallbacks hardcoded de `JWT_SECRET` y `HUELLA_SECRET_KEY`.
- Exigir secretos por variables de entorno.
- Restringir CORS HTTP y WebSocket por allowlist.
- Agregar rate limiting a `/auth/login` y `/auth/forgot-password`.
- Definir expiracion de JWT.
- Implementar refresh token rotativo o documentar no alcance temporal.
- Agregar `TenantGuard` en modulos que usan tenant sin validacion completa.
- Sanitizar logs de WebSocket y backend.

Criterio de salida:

- Backend no arranca sin secretos requeridos.
- CORS solo permite origenes configurados.
- Login tiene rate limit.
- Tests cross-tenant cubren rutas sensibles.

## Fase W2 - Integridad de datos y finanzas

Objetivo: garantizar consistencia en caja, pagos, membresias y auditoria.

Tareas:

- Envolver operaciones financieras en `prisma.$transaction`.
- Exigir idempotencia en `pos-charge` y `membership-sale`.
- Revisar creacion de usuarios anonimos y evitar `password_hash: 'none'`.
- Revisar descuentos, pagos mixtos y cierre de caja.
- Hacer auditoria obligatoria para tenant toggle, apertura/cierre de caja, pagos, egresos, membresias y usuarios.
- Agregar pruebas E2E para doble submit y caja.

Criterio de salida:

- Una venta no se duplica por reintentos.
- Caja no queda descuadrada por fallos intermedios.
- Auditoria registra operaciones criticas.

## Fase W3 - Uploads y privacidad

Objetivo: proteger comprobantes, observaciones e imagenes.

Tareas:

- Dejar de servir `/uploads` como carpeta publica.
- Crear endpoints autenticados para descargar archivos por tenant.
- Validar magic bytes, no solo mimetype declarado.
- Reescribir extension segun tipo real.
- Almacenar archivos fuera del webroot.
- Definir retencion de comprobantes y observaciones.

Criterio de salida:

- No hay URL publica directa a comprobantes.
- Archivos solo se consultan con JWT y tenant valido.
- Subidas invalidas son rechazadas.

## Fase W4 - Contenedores productivos

Objetivo: separar Compose dev de Compose prod/staging.

Tareas:

- Crear Dockerfile backend productivo:
  - multi-stage;
  - `npm ci`;
  - solo dependencias productivas;
  - `node dist/main`;
  - usuario no-root.
- Mantener `infra/docker/compose.local.yml` e `infra/docker/compose.prod.yml` como fuentes unicas.
- Reemplazar `prisma db push --force-reset` por `prisma migrate deploy` en prod.
- Remover volumen `./backend:/app` en prod.
- Usar secrets externos.
- Agregar healthchecks para API y frontend.
- Agregar limites de recursos si aplica.
- Mantener PostgreSQL en red privada.

Criterio de salida:

- Entorno dev conserva rapidez.
- Entorno prod no borra datos.
- API corre compilada y sin watch mode.

## Fase W5 - Web frontend y hub

Objetivo: ordenar las superficies web para QA y demostracion.

Tareas:

- Mantener `admin-web` como hub local en `8282`.
- Mantener `app-web` como app Flutter web en `8383`.
- Documentar rutas:
  - `/mockups/web/`
  - `/mockups/mobile/`
  - `/docs/`
- No montar `proyecto_antiguo/`.
- Agregar cabeceras basicas de seguridad en Nginx si se prepara entorno staging.

Criterio de salida:

- Hub permite navegar mockups/docs sin exponer archivos sensibles.
- Flutter web consume API segun ambiente.

## Pruebas usando contenedores locales

Arranque:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
docker compose --env-file .env -f infra/docker/compose.local.yml ps
```

Backend:

```powershell
cd backend
npm run build
npm run test
npm run test:e2e
```

Integracion:

- Abrir `http://localhost:3000`.
- Abrir `http://localhost:8383`.
- Abrir `http://localhost:8282`.
- Revisar logs con `docker compose --env-file .env -f infra/docker/compose.local.yml logs api`.

Cliente aislado:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml exec api curl http://localhost:3000/api/v1
```

## Entregables esperados

- Backend compila y prueba.
- Compose local levanta API, DB, Redis, Flutter web y hub.
- Compose prod/staging no usa `force-reset`.
- Flujo caja/pagos/auditoria funciona contra API real.
- Politicas de seguridad aplicadas por ambiente.
