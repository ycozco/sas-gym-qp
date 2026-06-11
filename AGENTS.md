# AGENTS.md - SAS Gym

## Contexto del proyecto

SAS Gym es una plataforma SaaS para gestion de gimnasios. Incluye backend NestJS, app Flutter/PWA, panel web/admin, PostgreSQL, Redis y Docker.

La fase actual no es despliegue en VPS. La fase actual es preparar el repositorio local para dejarlo limpio, segmentado y listo para clonacion futura en un servidor donde ya existe Nginx Proxy Manager.

## Stack principal

- Backend: NestJS, Node.js, TypeScript.
- Base de datos: PostgreSQL.
- ORM: Prisma, definido en `backend/prisma/schema.prisma`.
- Cache/pub-sub: Redis.
- Mobile/PWA: Flutter y Dart.
- Web admin: React estatico en `web_admin/`.
- Contenedores: Docker Compose.

## Reglas criticas

1. No crear ni levantar Nginx Proxy Manager dentro del proyecto.
2. No modificar configuracion real del VPS.
3. No tocar DNS ni SSL en esta fase.
4. No usar secretos reales.
5. No versionar `.env` reales.
6. No exponer PostgreSQL ni Redis en produccion.
7. No usar `docker system prune`.
8. No borrar carpetas sin revisar si estan versionadas.
9. No cambiar logica funcional sin justificarlo.
10. No mezclar refactors masivos con limpieza de infraestructura.

## Prioridad actual

Ordenar el repositorio local y dejarlo portable.

## Comandos de inspeccion inicial

```bash
git status
git branch
git ls-files | grep -E "dist/|build/|.dart_tool/|.gradle/|.env$" || true
```

En PowerShell:

```powershell
git status
git branch
git ls-files | rg "(^|/)(dist|build|\.dart_tool|\.gradle)(/|$)|(^|/)\.env$"
```

## Comandos de validacion local

```bash
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml up -d --build
curl http://localhost:3000/api/v1
```

## Comandos de validacion productiva sin desplegar

```bash
docker compose --env-file .env.production.example -f infra/docker/compose.prod.yml config
```

## Reglas de Docker

- Local puede usar `ports`.
- Produccion debe usar `expose` para API, WS, app web y admin web.
- Produccion no debe publicar PostgreSQL ni Redis.
- Produccion debe conectarse a una red externa configurable para el proxy.

## Red externa de proxy

El compose productivo usa una red externa configurable:

```yaml
proxy_external:
  external: true
  name: ${EXTERNAL_PROXY_NETWORK}
```

No asumir que el nombre real de la red en el VPS es fijo.

## Multitenancy

Para MVP, el aislamiento multitenant usa `tenant_id` por tabla. No usar esquema independiente por tenant en esta fase.

Toda consulta sensible debe filtrar por tenant.

## Prisma

El proyecto usa Prisma. Comandos esperados:

```bash
cd backend
npx prisma generate
npx prisma migrate deploy
npx prisma db seed
```

No documentar TypeORM como flujo principal.

## Graphify y Obsidian

Graphify y Obsidian son herramientas locales opcionales. No son parte del MVP funcional, no estan en el compose productivo y no deben bloquear el levantamiento local.

## Resultado esperado al terminar tareas

Entregar archivos modificados, motivo de cada cambio, comandos ejecutados, resultado de validacion, riesgos pendientes y proximos pasos recomendados.
