# Guia de despliegue

## Objetivo

Documentar como levantar SaaaS GYM en local, como desplegar cada parte manualmente y que revisar antes de llevar el sistema a un entorno productivo.

## Prerrequisitos

Para despliegue local completo:

- Docker Desktop o Docker Engine con Compose.
- Puertos libres: `3000`, `8383`, `8282`, `5432`.

Para ejecucion manual:

- Node.js compatible con el backend NestJS.
- NPM.
- Flutter compatible con Dart `^3.12.0`.
- PostgreSQL 15 o superior.

## Despliegue local completo con Docker Compose

Desde la raiz del proyecto:

```powershell
cd D:\proyectos\sas_gym
docker compose up --build
```

Servicios definidos:

| Servicio | Contenedor | Funcion | Puerto |
|---|---|---|---|
| `db` | `gymsmart-postgres` | PostgreSQL | `127.0.0.1:5432` |
| `api` | `gymsmart-api` | NestJS API | `3000` |
| `frontend-web` | `sas_gym_flutter_web` | Flutter web servido por Nginx | `8383` |
| `web` | `sas_gym_frontend` | Hub estatico, mockups y docs | `8282` |
| `test-client` | `gymsmart-test-client` | Cliente curl aislado | sin puerto publico |

Validar estado:

```powershell
docker compose ps
```

Revisar logs:

```powershell
docker compose logs api
docker compose logs frontend-web
docker compose logs web
```

URLs esperadas:

- API: `http://localhost:3000`
- Flutter web: `http://localhost:8383`
- Hub/mockups/docs: `http://localhost:8282`

## Advertencia sobre datos de desarrollo

El servicio `api` del Compose raiz ejecuta:

```sh
npx prisma db push --force-reset && npx prisma generate && npx prisma db seed && npm run start:dev
```

Esto recrea el esquema y datos de desarrollo. No usar `--force-reset` en produccion.

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

```powershell
docker compose up --build db api
```

### Solo Flutter web

```powershell
docker compose up --build frontend-web
```

### Solo hub/mockups

```powershell
docker compose up web
```

## Validacion posterior al despliegue

1. Confirmar contenedores:

```powershell
docker compose ps
```

2. Confirmar API:

```powershell
curl http://localhost:3000
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

```powershell
docker compose logs api
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
