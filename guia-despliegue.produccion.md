# Guia de despliegue productivo - SAS Gym

## Objetivo

Definir una linea base para desplegar SAS Gym en un servidor donde Nginx Proxy Manager ya existe como infraestructura externa.

Esta guia no instala Prisma, Node, npm, Flutter ni dependencias de la aplicacion en el servidor. Todo build, migracion, seed y ejecucion de servicios debe ocurrir dentro de contenedores.

## Linea base del servidor

Requisitos minimos del host:

- Linux con Docker instalado.
- Docker Compose disponible como `docker compose`.
- Git instalado para clonar o actualizar el repositorio.
- Nginx Proxy Manager ya desplegado fuera de este proyecto.
- Red Docker externa de NPM identificada.
- DNS de subdominios apuntando al servidor.

No instalar en el host:

- Node.js para correr la app.
- npm/yarn/pnpm para dependencias de la app.
- Prisma CLI.
- Flutter SDK.
- PostgreSQL o Redis nativos para este proyecto.
- Nginx adicional dentro de SAS Gym.
- Certbot dentro de SAS Gym.

## Dominios sugeridos

Usar estos subdominios como linea base, cambiando el dominio cuando el despliegue no sea en el mismo servidor o entorno:

```text
api.<ip/dominio>
ws.<ip/dominio>
app.<ip/dominio>
admin.<ip/dominio>
```

Ejemplo con el dominio actual sugerido:

```text
api.sas-gym.qpsecure.cloud
ws.sas-gym.qpsecure.cloud
app.sas-gym.qpsecure.cloud
admin.sas-gym.qpsecure.cloud
```

Si se despliega en otro servidor o dominio, reemplazar solo `<ip/dominio>` y ajustar `.env`.

## DNS

Crear registros DNS apuntando al servidor:

```text
api.<ip/dominio>    A/AAAA o CNAME hacia el VPS
ws.<ip/dominio>     A/AAAA o CNAME hacia el VPS
app.<ip/dominio>    A/AAAA o CNAME hacia el VPS
admin.<ip/dominio>  A/AAAA o CNAME hacia el VPS
```

DNS y SSL se administran fuera de este repositorio.

## Nginx Proxy Manager externo

NPM debe existir antes de levantar el compose productivo de SAS Gym.

Identificar la red Docker donde escucha NPM:

```bash
docker network ls
```

Ese nombre se usara en:

```env
EXTERNAL_PROXY_NETWORK=<nombre_red_npm>
```

## Variables de entorno

Crear el archivo real desde la plantilla:

```bash
cp .env.production.example .env
```

Ajustar como minimo:

```env
DB_PASSWORD=<secreto_postgres>
REDIS_PASSWORD=<secreto_redis>
JWT_SECRET=<secreto_jwt>
JWT_REFRESH_SECRET=<secreto_refresh>
HUELLA_SECRET_KEY=<secreto_huella>
EXTERNAL_PROXY_NETWORK=<nombre_red_npm>

API_BASE_URL=https://api.<ip/dominio>/api/v1
WS_URL=wss://ws.<ip/dominio>
APP_URL=https://app.<ip/dominio>
ADMIN_URL=https://admin.<ip/dominio>
CORS_ORIGINS=https://app.<ip/dominio>,https://admin.<ip/dominio>
```

No versionar `.env`.

## Validar compose sin desplegar

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml config
```

Confirmar:

- No hay servicio Nginx Proxy Manager.
- No hay Certbot.
- No hay puertos `80:80`, `443:443` ni `81:81`.
- PostgreSQL y Redis no publican puertos.
- API, WS, app web y admin web usan `expose`.
- API, WS, app web y admin web estan en `proxy_external` cuando corresponde.

## Levantar servicios

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml up -d --build
```

Ver estado:

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml ps
```

## Migraciones y seed desde contenedor

No instalar Prisma en el servidor.

Ejecutar migraciones dentro del contenedor `api`:

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml exec api npx prisma migrate deploy
```

Si corresponde poblar datos iniciales:

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml exec api npx prisma db seed
```

Si el contenedor `api` aun no esta levantado, usar un contenedor temporal:

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml run --rm api npx prisma migrate deploy
```

## Proxy Hosts en NPM

Crear estos Proxy Hosts en NPM externo:

| Subdominio | Forward Hostname / IP | Puerto | SSL | WebSocket |
| --- | --- | --- | --- | --- |
| `api.<ip/dominio>` | `sasgym_api` | `3000` | Si | Opcional |
| `ws.<ip/dominio>` | `sasgym_ws` | `3001` | Si | Si |
| `app.<ip/dominio>` | `sasgym_app_web` | `80` | Si | No |
| `admin.<ip/dominio>` | `sasgym_admin_web` | `80` | Si | No |

Reemplazar `<ip/dominio>` por el dominio real del entorno.

## Validaciones posteriores

```bash
curl https://api.<ip/dominio>/api/v1
```

Abrir en navegador:

```text
https://app.<ip/dominio>
https://admin.<ip/dominio>
```

Validar WebSocket contra:

```text
wss://ws.<ip/dominio>
```

## Actualizacion de despliegue

```bash
git pull
docker compose --env-file .env -f infra/docker/compose.prod.yml up -d --build
docker compose --env-file .env -f infra/docker/compose.prod.yml exec api npx prisma migrate deploy
```

Todo se ejecuta con contenedores. El host no debe instalar dependencias de aplicacion.

## Rollback basico

1. Volver al commit anterior con Git.
2. Reconstruir contenedores.
3. Revisar logs.

```bash
git log --oneline -5
git checkout <commit_anterior>
docker compose --env-file .env -f infra/docker/compose.prod.yml up -d --build
docker compose --env-file .env -f infra/docker/compose.prod.yml logs -f api
```

No borrar volumenes de PostgreSQL o Redis durante rollback salvo decision explicita y backup verificado.
