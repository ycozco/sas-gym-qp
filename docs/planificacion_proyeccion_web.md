# Planificacion de proyeccion web / backend / sistema - SaaaS GYM

## Objetivo

Definir la planificacion para evolucionar el sistema web/backend de SaaaS GYM hacia una plataforma segura, testeable y desplegable. Incluye API NestJS, PostgreSQL, Flutter web, hub de mockups/docs y contenedores locales.

Este documento complementa `proyeccion.md`, que contiene los hallazgos tecnicos y de seguridad ordenados por criticidad.

## Entorno local disponible

El proyecto ya cuenta con Docker Compose en la raiz:

```powershell
docker compose up --build
```

Servicios principales:

| Servicio | Contenedor | Uso | URL / Puerto |
|---|---|---|---|
| `db` | `gymsmart-postgres` | PostgreSQL local | `127.0.0.1:5432` |
| `api` | `gymsmart-api` | Backend NestJS | `http://localhost:3000` |
| `frontend-web` | `sas_gym_flutter_web` | Flutter web compilado | `http://localhost:8383` |
| `web` | `sas_gym_frontend` | Hub, docs y mockups | `http://localhost:8282` |
| `test-client` | `gymsmart-test-client` | Cliente curl aislado | Red `external-test-net` |

Comandos utiles:

```powershell
docker compose ps
docker compose logs api
docker compose logs frontend-web
docker compose logs web
```

Nota critica: el Compose actual ejecuta `prisma db push --force-reset`, por lo que debe tratarse como entorno de desarrollo/pruebas, no produccion.

## Meta web-sistema

Convertir el backend y sistema web en una plataforma segura y desplegable: API NestJS, base PostgreSQL, Flutter web, hub de mockups/docs y contenedores endurecidos.

## Fase W0 - Estabilizacion del entorno local

Objetivo: usar los contenedores locales como entorno reproducible de desarrollo.

Tareas:

- Levantar entorno con `docker compose up --build`.
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
- Crear `docker-compose.dev.yml` y `docker-compose.prod.yml`.
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

- Mantener `web` como hub local en `8282`.
- Mantener `frontend-web` como app Flutter web en `8383`.
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
docker compose up --build
docker compose ps
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
- Revisar logs con `docker compose logs api`.

Cliente aislado:

```powershell
docker compose exec test-client curl http://api:3000/api/v1
```

## Entregables esperados

- Backend compila y prueba.
- Compose dev levanta API, DB, Flutter web y hub.
- Compose prod/staging no usa `force-reset`.
- Flujo caja/pagos/auditoria funciona contra API real.
- Politicas de seguridad aplicadas por ambiente.
