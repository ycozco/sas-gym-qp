# Variables de entorno

## Archivos

- `.env.local.example`: valores de desarrollo versionables.
- `.env.production.example`: plantilla productiva sin secretos reales.
- `.env`: archivo real ignorado por Git.

## Variables principales

| Variable | Uso | Local | Produccion | Secreta | Versionable |
| --- | --- | --- | --- | --- | --- |
| `NODE_ENV` | Modo de ejecucion | `development` | `production` | No | Si |
| `DB_NAME` | Nombre de base de datos | `sasgym_dev` | `sasgym_prod` | No | Si |
| `DB_USER` | Usuario PostgreSQL | `sasgym_user` | `sasgym_user` | No | Si |
| `DB_PASSWORD` | Password PostgreSQL | Demo local | Real fuerte | Si | Solo placeholder |
| `DATABASE_URL` | Conexion Prisma | Postgres local compose | Postgres interno compose | Si | Solo placeholder |
| `REDIS_PASSWORD` | Password Redis | Vacio local | Real fuerte | Si | Solo placeholder |
| `JWT_SECRET` | Firma de tokens | Demo local | Real fuerte | Si | Solo placeholder |
| `JWT_REFRESH_SECRET` | Firma refresh token legado/futuro | Demo local | Real fuerte | Si | Solo placeholder |
| `JWT_ACCESS_TTL` | TTL access token usado por backend | `15m` | `15m` | No | Si |
| `JWT_REFRESH_DAYS` | Dias refresh token usados por backend | `7` | `7` | No | Si |
| `HUELLA_SECRET_KEY` | Secreto de datos biometricos | Demo local | Real fuerte | Si | Solo placeholder |
| `API_BASE_URL` | URL publica/API para clientes | `http://localhost:3000/api/v1` | HTTPS publico | No | Si |
| `WS_URL` | URL WebSocket | `ws://localhost:3001` | WSS publico | No | Si |
| `APP_URL` | URL PWA | `http://localhost:8383` | HTTPS publico | No | Si |
| `ADMIN_URL` | URL admin | `http://localhost:8282/web/index.html` | HTTPS publico | No | Si |
| `CORS_ORIGINS` | Origenes permitidos | Localhost | Dominios publicos | No | Si |
| `EXTERNAL_PROXY_NETWORK` | Red Docker de NPM externo | No aplica | Nombre real de red | No | Si |

## Frontend

Flutter debe recibir URLs con `--dart-define`, especialmente `API_BASE_URL`. El APK productivo no debe apuntar a `localhost`, `127.0.0.1` ni `10.0.2.2`.
