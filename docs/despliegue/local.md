# Desarrollo local

## Objetivo

Levantar SAS Gym en local sin Nginx Proxy Manager y sin depender de infraestructura externa.

## Preparacion

```bash
cp .env.local.example .env
```

En PowerShell:

```powershell
Copy-Item .env.local.example .env
```

## Levantar servicios

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Servicios previstos:

- API NestJS: `http://localhost:3000/api/v1`
- Flutter Web/PWA: `http://localhost:8383`
- Admin web/hub: `http://localhost:8282`
- PostgreSQL local: `localhost:5432`
- Redis local: `localhost:6379`

## Validacion

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml config
curl http://localhost:3000/api/v1
```

## Notas

- Local puede publicar puertos.
- Los secretos locales deben ser valores de desarrollo.
- No usar este compose como despliegue productivo.
