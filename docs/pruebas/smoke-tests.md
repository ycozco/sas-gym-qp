# Smoke tests

## Local

```bash
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config
```

Cuando los servicios esten arriba:

```bash
curl http://localhost:3000/api/v1
curl http://localhost:8383
curl http://localhost:8282
```

## Produccion sin desplegar

```bash
docker compose --env-file .env.production.example -f infra/docker/compose.prod.yml config
```

Verificar que el compose productivo no publique puertos para PostgreSQL ni Redis.
