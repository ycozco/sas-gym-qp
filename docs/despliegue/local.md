# Despliegue local

## Objetivo

Levantar SAS Gym en una PC local sin Nginx Proxy Manager y sin depender de infraestructura externa.

El caso esperado es que un colaborador clone el proyecto, copie el archivo de entorno y ejecute Docker Compose. La API debe preparar PostgreSQL, Redis, Prisma y datos iniciales sin instalar Node.js ni correr `npm ci` en la maquina host.

## Prerrequisitos

### Docker

Verificar instalacion:

```bash
docker --version
docker compose version
```

Verificar que Docker este activo:

```bash
docker ps
```

Si `docker ps` falla, Docker no esta corriendo o el usuario no tiene permisos para usarlo.

### Puertos libres

Por defecto el entorno local usa estos puertos:

| Puerto | Servicio |
|---|---|
| `3000` | API |
| `3001` | WebSocket |
| `5432` | PostgreSQL local |
| `6379` | Redis local |
| `8383` | Flutter Web/PWA |
| `8282` | Admin web/hub |

Verificar si un puerto esta ocupado:

```bash
docker ps
```

En Linux tambien se puede usar:

```bash
ss -ltnp
```

Si hay conflicto, cambiar el puerto en `.env` antes de levantar Docker.

## Preparacion

```bash
cp .env.local.example .env
```

En PowerShell:

```powershell
Copy-Item .env.local.example .env
```

## Como saber que Compose estas usando

Docker Compose usa el archivo indicado por `-f`.

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Ese comando usa:

```text
infra/docker/compose.local.yml
```

En este proyecto los Compose vigentes son:

| Archivo | Uso |
|---|---|
| `infra/docker/compose.local.yml` | Desarrollo local |
| `infra/docker/compose.prod.yml` | Produccion/preproduccion |
| `infra/docker/compose.tools.yml` | Herramientas opcionales |

Para desarrollo local siempre usar:

```bash
-f infra/docker/compose.local.yml
```

Para verificar la configuracion antes de levantar:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml config
```

Los contenedores locales tienen sufijo `_local`, por ejemplo:

```text
sasgym_api_local
sasgym_postgres_local
sasgym_redis_local
```

Si ves contenedores sin `_local`, como `sasgym_api`, `sasgym_postgres` o `sasgym_redis`, corresponden al Compose productivo/preproductivo.

## Levantar solo la API local

Este es el camino recomendado cuando solo se quiere probar backend:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

Esto levanta:

- PostgreSQL.
- Redis.
- API NestJS.
- Prisma Client.
- Sincronizacion del esquema local con `prisma db push`.
- Seed de datos locales.

No se necesita ejecutar `npm ci` manualmente en la PC host. Las dependencias del backend se instalan dentro de la imagen Docker.

Validar:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml ps
curl http://localhost:3000/api/v1
```

Respuesta esperada del `curl`: HTTP `200`.

Logs de la API:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml logs -f api
```

## Levantar todo el entorno

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Servicios previstos:

- API NestJS: `http://localhost:3000/api/v1`
- Flutter Web/PWA: `http://localhost:8383`
- Admin web/hub: `http://localhost:8282`
- PostgreSQL local: `localhost:5432`
- Redis local: `localhost:6379`

## Validacion rapida

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml config
curl http://localhost:3000/api/v1
```

## Datos locales y reset

El compose local usa:

```text
ALLOW_TEST_DATA_RESET=true
```

Con esa variable, si la base local queda incompatible con el schema Prisma actual, el script `backend/scripts/setup-local-db.sh` puede ejecutar `prisma db push --force-reset`.

Esto es aceptable para desarrollo local porque puede borrar y recrear datos de prueba. No usar esta estrategia en produccion.

Para borrar todo el entorno local y empezar desde cero:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml down -v
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

## Notas

- Local puede publicar puertos.
- Los secretos locales deben ser valores de desarrollo.
- No usar este compose como despliegue productivo.
- Produccion debe usar migraciones Prisma reales con `prisma migrate deploy`.
