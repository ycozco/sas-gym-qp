# SAS Gym

SAS Gym es una plataforma SaaS para gestion de gimnasios. El producto incluye backend NestJS, app Flutter Web/PWA, panel web/admin, PostgreSQL, Redis y Docker.

El repositorio esta en fase de preparacion local: debe poder levantarse sin Nginx Proxy Manager y quedar listo para clonarse despues en un VPS donde NPM ya exista como infraestructura externa.

## Stack

- Backend: NestJS, Node.js, TypeScript.
- ORM: Prisma.
- Base de datos: PostgreSQL.
- Cache/pub-sub: Redis.
- App: Flutter Web/PWA.
- Admin web: React estatico en `web_admin/`.
- Contenedores: Docker Compose.

## Estructura principal

```text
backend/        API NestJS y Prisma
mobile_app/     Flutter Web/PWA
web_admin/      Panel web/admin estatico
docs/           Documentacion operativa y tecnica
arquitectura/   Documentacion tecnica historica/arquitectonica
infra/docker/   Compose local, productivo y herramientas
infra/scripts/  Scripts auxiliares
AGENTS.md       Guia operativa para Codex
```

## Desarrollo local

```bash
cp .env.local.example .env
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Endpoints locales previstos:

- API: `http://localhost:3000/api/v1`
- Flutter Web/PWA: `http://localhost:8383`
- Admin web/hub: `http://localhost:8282`

Guia completa: [docs/despliegue/local.md](docs/despliegue/local.md).

## Produccion preparada, sin proxy propio

El compose productivo no incluye Nginx Proxy Manager, Certbot ni certificados. API, WS, app web y admin web se conectan a una red Docker externa configurable para que un NPM ya existente haga el routing publico.

```bash
docker compose --env-file .env.production.example -f infra/docker/compose.prod.yml config
```

Guia completa: [docs/despliegue/servidor-con-npm-externo.md](docs/despliegue/servidor-con-npm-externo.md).

## Variables de entorno

Plantillas versionables:

- `.env.local.example`
- `.env.production.example`

Los `.env` reales estan ignorados por Git. Ver [docs/despliegue/variables-entorno.md](docs/despliegue/variables-entorno.md).

## Codex

Codex debe trabajar por tareas pequenas, validar antes de cambiar infraestructura y no tocar VPS, DNS, SSL ni Nginx Proxy Manager real en esta fase.

Guia: [AGENTS.md](AGENTS.md) y [docs/herramientas/codex.md](docs/herramientas/codex.md).

## Herramientas opcionales

Graphify y Obsidian son auxiliares locales. No forman parte del MVP funcional ni del compose productivo.

- [docs/herramientas/graphify.md](docs/herramientas/graphify.md)
- [docs/herramientas/obsidian.md](docs/herramientas/obsidian.md)

## Validacion rapida

```bash
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config
docker compose --env-file .env.production.example -f infra/docker/compose.prod.yml config
git diff --check
```
