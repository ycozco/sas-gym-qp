# Guia de despliegue

## Objetivo

Documentar como levantar SaaaS GYM en local, como desplegar cada parte manualmente y que revisar antes de llevar el sistema a un entorno productivo.

## Prerrequisitos

Para despliegue local completo:

- Docker Desktop o Docker Engine con Compose.
- Puertos libres: `3000`, `8383`, `8282`, `5432`.

Verificar Docker:

```powershell
docker --version
docker compose version
docker ps
```

Si `docker ps` falla, Docker no esta activo o el usuario no tiene permisos.

Para ejecucion manual:

- Node.js compatible con el backend NestJS.
- NPM.
- Flutter compatible con Dart `^3.12.0`.
- PostgreSQL 15 o superior.

## Como identificar que Compose se esta levantando

Docker Compose usa el archivo indicado con `-f`.

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Ese comando levanta el Compose local:

```text
infra/docker/compose.local.yml
```

Composes vigentes:

| Archivo | Uso |
|---|---|
| `infra/docker/compose.local.yml` | Desarrollo local |
| `infra/docker/compose.prod.yml` | Produccion/preproduccion |
| `infra/docker/compose.tools.yml` | Herramientas opcionales |

Indicadores por nombre de contenedor:

| Contenedor | Ambiente |
|---|---|
| `sasgym_api_local` | Local |
| `sasgym_postgres_local` | Local |
| `sasgym_redis_local` | Local |
| `sasgym_api` | Produccion/preproduccion |
| `sasgym_postgres` | Produccion/preproduccion |
| `sasgym_redis` | Produccion/preproduccion |

Antes de levantar, se puede revisar la configuracion final con:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml config
```

## Despliegue local de API con Docker Compose

Desde la raiz del proyecto:

```bash
cd /ruta/al/proyecto/sas-gym-qp
cp .env.local.example .env
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

La API local queda disponible en:

```text
http://localhost:3000/api/v1
```

Validar:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml ps
curl http://localhost:3000/api/v1
```

El colaborador no necesita ejecutar `npm ci` en su maquina para levantar la API. Docker construye la imagen e instala dependencias dentro del contenedor.

El arranque normal de la API local no ejecuta seed. Si la BD ya tiene datos, se conservan. Para una primera instalacion local con data de prueba, ejecutar manualmente:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml exec api npm run seed:local
```

Advertencia: `seed:local` resetea la BD local y vuelve a crear usuarios, productos, membresias y ventas demo. No usarlo como parte del uso diario.

## Despliegue local completo con Docker Compose

Desde la raiz del proyecto:

```bash
cd /ruta/al/proyecto/sas-gym-qp
cp .env.local.example .env
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Servicios definidos:

| Servicio | Contenedor | Funcion | Puerto |
|---|---|---|---|
| `postgres` | `sasgym_postgres_local` | PostgreSQL | `5432` |
| `redis` | `sasgym_redis_local` | Redis | `6379` |
| `api` | `sasgym_api_local` | NestJS API | `3000` |
| `ws` | `sasgym_ws_local` | WebSocket | `3001` |
| `app-web` | `sasgym_app_web_local` | Flutter web servido por Nginx | `8383` |
| `admin-web` | `sasgym_admin_web_local` | Hub estatico, mockups y docs | `8282` |

Validar estado:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml ps
```

Revisar logs:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml logs api
docker compose --env-file .env -f infra/docker/compose.local.yml logs app-web
docker compose --env-file .env -f infra/docker/compose.local.yml logs admin-web
```

URLs esperadas:

- API: `http://localhost:3000`
- Flutter web: `http://localhost:8383`
- Hub/mockups/docs: `http://localhost:8282`

## Advertencia sobre datos de desarrollo

El servicio `api` del Compose local ejecuta:

```sh
npm run db:setup:local && npm run start:dev
```

`db:setup:local` genera Prisma Client y sincroniza el schema con `prisma db push`. Si la base local queda incompatible y `ALLOW_TEST_DATA_RESET=true`, puede ejecutar `prisma db push --force-reset`.

Esto es solo para desarrollo local porque puede borrar datos de prueba. No usar `--force-reset` en produccion.

El seed local es manual:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml exec api npm run seed:local
```

Usarlo solo para inicializar o resetear data demo.

## API local para web y app movil

Desde la misma PC, la API local responde en:

```text
http://localhost:3000/api/v1
```

Desde un celular fisico conectado a la misma red, no usar `localhost`. Usar la IP LAN de la PC:

```bash
ip route get 1.1.1.1
```

Tomar el valor que aparece despues de `src` y formar:

```text
http://<IP_LAN_PC>:3000/api/v1
```

Para emulador Android:

```text
http://10.0.2.2:3000/api/v1
```

## APK local y ejecucion en celular

Desde la app movil:

```bash
cd /ruta/al/proyecto/sas-gym-qp/mobile_app
```

Crear APK local para celular fisico:

```bash
API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1 ./scripts/build-local-apk.sh
```

El APK queda en:

```text
mobile_app/build/app/outputs/flutter-apk/app-dev-debug.apk
```

Instalar en un celular conectado por cable:

```bash
flutter devices
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

Ejecutar directamente con Flutter:

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1 -d <DEVICE_ID>
```

## Despliegue manual del backend

1. Entrar al backend:

```powershell
cd D:\proyectos\sas_gym\backend
```

2. Instalar dependencias:

```powershell
npm install
```

3. Configurar variables de entorno:

```text
DATABASE_URL=postgresql://postgres:postgres_secure_password@localhost:5432/gymsmart?schema=public
PORT=3000
JWT_SECRET=replace_me
TZ=America/Lima
```

4. Preparar Prisma:

```powershell
npx prisma generate
```

5. Para desarrollo con reset:

```powershell
npx prisma db push --force-reset
npx prisma db seed
```

6. Compilar:

```powershell
npm run build
```

7. Ejecutar en desarrollo:

```powershell
npm run start:dev
```

8. Ejecutar en modo produccion:

```powershell
npm run start:prod
```

## Despliegue manual de Flutter web

1. Entrar a la app:

```powershell
cd D:\proyectos\sas_gym\mobile_app
```

2. Instalar dependencias:

```powershell
flutter pub get
```

3. Validar:

```powershell
flutter analyze
flutter test
```

4. Compilar web:

```powershell
flutter build web --release
```

5. Servir el contenido generado en:

```text
mobile_app/build/web
```

Puede servirse con Nginx, IIS, Apache o cualquier servidor estatico.

## Despliegue del hub y mockups

El hub estatico debe servir:

- `index.html`
- `mockups/mobile/`
- `mockups/web/`
- `docs/`

No debe servir:

- `proyecto_antiguo/`
- `.git/`
- `backend/.env`
- backups, venv, media heredada o credenciales.

En Docker Compose, esto ya esta limitado con volumenes de solo lectura:

```yaml
volumes:
  - ./index.html:/usr/share/nginx/html/index.html:ro
  - ./mockups/mobile:/usr/share/nginx/html/mockups/mobile:ro
  - ./mockups/web:/usr/share/nginx/html/mockups/web:ro
  - ./docs:/usr/share/nginx/html/docs:ro
```

## Despliegue con Docker por partes

### Solo backend y base de datos

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

### Solo Flutter web

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build app-web
```

### Solo hub/mockups

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d admin-web
```

## Validacion posterior al despliegue

1. Confirmar contenedores:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml ps
```

2. Confirmar API:

```bash
curl http://localhost:3000/api/v1
```

3. Abrir Flutter web:

```text
http://localhost:8383
```

4. Abrir hub:

```text
http://localhost:8282
```

5. Revisar logs de API:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml logs api
```

6. Verificar que PostgreSQL no este expuesto a la red publica:

```text
127.0.0.1:5432
```

## Variables de entorno relevantes

| Variable | Uso | Ejemplo desarrollo |
|---|---|---|
| `DATABASE_URL` | Conexion Prisma/PostgreSQL | `postgresql://postgres:postgres_secure_password@db:5432/gymsmart?schema=public` |
| `PORT` | Puerto API | `3000` |
| `JWT_SECRET` | Firma de tokens | `gymsmart_secure_jwt_secret_key_2026` |
| `TZ` | Zona horaria para caja y turnos | `America/Lima` |

## Recomendaciones para produccion

- Reemplazar todos los secretos de desarrollo.
- No usar `prisma db push --force-reset`.
- Usar migraciones controladas de Prisma.
- Mantener PostgreSQL en red privada.
- Servir API detras de HTTPS y reverse proxy.
- Separar variables de entorno por ambiente.
- Configurar backups automatizados de PostgreSQL.
- No exponer `proyecto_antiguo/`.
- No versionar `.env`, backups ni credenciales.
- Activar monitoreo de logs, errores y uso de recursos.
- Definir politica de retencion para `AuditLog`.

## Checklist rapido

- Docker Compose levanta sin errores.
- API responde en `3000`.
- Flutter web carga en `8383`.
- Hub estatico carga en `8282`.
- DB escucha solo en localhost.
- `proyecto_antiguo/` no esta publicado.
- Logs de API no muestran errores de Prisma.
- Variables sensibles no usan valores de desarrollo en produccion.
