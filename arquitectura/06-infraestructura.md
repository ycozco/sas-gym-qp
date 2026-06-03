# Infraestructura

## Docker Compose raiz

El archivo principal es `docker-compose.yml` en la raiz. Define:

- `db`: PostgreSQL 15.
- `api`: NestJS API.
- `frontend-web`: build web de Flutter servido por Nginx.
- `flutter-ci`: target para `flutter analyze` y `flutter test`.
- `web`: hub estatico de mockups y docs.
- `test-client`: contenedor curl aislado para pruebas externas.

## Puertos

| Servicio | Puerto |
|---|---|
| API NestJS | `3000` |
| Flutter web | `8383` |
| Hub estatico/mockups/docs | `8282` |
| PostgreSQL | `127.0.0.1:5432` |

## Redes

El Compose raiz separa redes:

- `internal-net`: red interna para base de datos y API. Esta marcada como `internal`.
- `public-net`: red publica para API, Flutter web y hub estatico.
- `external-test-net`: red para simular clientes fuera de la red interna.

## Persistencia

PostgreSQL usa el volumen `postgres_data`.

Importante: el comando de la API en Compose ejecuta:

```sh
npx prisma db push --force-reset && npx prisma generate && npx prisma db seed && npm run start:dev
```

Esto esta orientado a desarrollo. Puede reiniciar el esquema y los datos.

## Contenedor Flutter

`mobile_app/Dockerfile` tiene targets:

- `deps`: instala dependencias Flutter.
- `ci`: corre `flutter analyze` y `flutter test`.
- `build`: compila Flutter web release.
- `runtime`: sirve `build/web` con Nginx.

La imagen base actual es `ghcr.io/cirruslabs/flutter:3.44.0`, coherente con el requerimiento de Dart `^3.12.0` indicado en `pubspec.yaml`.

## Hub estatico

El servicio `web` de Compose monta:

- `index.html`
- `mockups/mobile`
- `mockups/web`
- `docs`

No monta `proyecto_antiguo/`, lo cual es correcto porque esa carpeta contiene backups, entorno virtual, media y archivos sensibles/historicos.

## Comandos de operacion local

Raiz:

```powershell
docker compose up --build
```

Backend:

```powershell
cd backend
npm run build
npm run test
npm run start:dev
```

Flutter:

```powershell
cd mobile_app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

CI Flutter via Docker:

```powershell
docker compose build flutter-ci
```

## Riesgos de infraestructura actual (Entorno AS-IS)

- El `backend/docker-compose.yml` separado expone PostgreSQL de forma pública. En producción debe usarse una red privada interna.
- Existen carpetas generadas de desarrollo (`node_modules`, `dist`, `build`, etc.) que no deben versionarse.
- Los secretos en docker-compose se definen inline. En producción deben extraerse a variables de entorno externas.

---

## Arquitectura Objetivo (Entorno TO-BE de Producción)

Para garantizar la alta disponibilidad, escalado horizontal y seguridad, se establece la siguiente infraestructura de producción desacoplada:

```mermaid
graph TD
    %% Red Externa
    subgraph Red_Externa [Red Pública / Clientes]
        Flutter[App Móvil / Web / Windows]
        Admin[Panel Web Administrativo]
        Zk[Hardware Biométrico Zk]
    end

    %% Capa DMZ (Proxy)
    subgraph Red_DMZ [Capa de Entrada / Proxy Inverso]
        Nginx[Nginx Reverse Proxy / SSL-TLS]
    end

    %% Capa de Aplicación (Stateless Nodes)
    subgraph Red_App [Capa de Cómputo / API Stateless]
        Nest_A[NestJS API Node A]
        Nest_B[NestJS API Node B]
    end

    %% Capa de Datos e Infraestructura de Estado
    subgraph Red_Datos [Capa de Estado e Infraestructura]
        Redis[(Redis Cluster / Cache & PubSub)]
        Postgres[(PostgreSQL Master DB)]
        S3[(Object Storage / S3 / MinIO)]
    end

    %% Conectividad
    Flutter & Admin & Zk -->|HTTPS / WSS| Nginx
    Nginx -->|Balanceo Round-Robin (3000)| Nest_A
    Nginx -->|Balanceo Round-Robin (3000)| Nest_B
    
    Nest_A & Nest_B -->|Prisma Client| Postgres
    Nest_A & Nest_B -->|Socket.io Redis Adapter| Redis
    Nest_A & Nest_B -->|AWS SDK Client| S3
```

### Componentes de la Arquitectura de Producción

1.  **Nginx (Gateway)**: Captura peticiones HTTP/S y WebSocket en puertos 80/443. Aplica terminación SSL-TLS, cabeceras de protección de seguridad y Rate Limiting (máximo 60 peticiones por minuto por IP para la API).
2.  **NestJS Stateless API**: Los nodos de cómputo no guardan estado local en disco ni memoria. Reciben la autenticación validando el JWT firmado de forma asíncrona.
3.  **Redis (Estado Realtime e Idempotencia)**:
    *   *Sincronización horizontal de WebSockets*: Socket.io usa `@socket.io/redis-adapter` para difundir eventos entre nodos (ej: alertar suspensiones).
    *   *Idempotencia financiera*: Control de cobros en caja registrando un token único (`venta_token`) en Redis con un comando atómico `SET token "processing" EX 300 NX` para evitar cobros dobles por fallos de red.
4.  **PostgreSQL (Database)**: Motor relacional persistente.
5.  **Object Storage (S3 / MinIO)**: Almacén de archivos de observaciones y comprobantes de pago subidos por usuarios, eliminando la dependencia de almacenamiento en el sistema de archivos del contenedor local.

---

## Estrategia de Contenedores para Producción

### Dockerfile del Backend (NestJS Multi-Etapa)

```dockerfile
# --- ETAPA 1: Construcción y Compilación ---
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

# --- ETAPA 2: Instalación de Dependencias de Producción ---
FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --only=production
RUN npx prisma generate

# --- ETAPA 3: Imagen de Ejecución Ligera ---
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### Nginx Configuration (`nginx.conf` de Producción)

```nginx
events { worker_connections 1024; }

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=60r/m;

    upstream backend_api {
        server api:3000;
    }

    upstream frontend_flutter {
        server frontend-web:80;
    }

    server {
        listen 80;
        server_name app.gymsmart.com;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name app.gymsmart.com;

        ssl_certificate /etc/nginx/ssl/gymsmart.crt;
        ssl_certificate_key /etc/nginx/ssl/gymsmart.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;

        location /api/v1/ {
            limit_req zone=api_limit burst=20 nodelay;
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Tenant-ID $http_x_tenant_id;
        }

        location /socket.io/ {
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_read_timeout 86400;
        }

        location / {
            proxy_pass http://frontend_flutter;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

### Configuración del Compose de Producción (`docker-compose.yml`)

```yaml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: gymsmart-postgres
    restart: always
    environment:
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: gymsmart
    ports:
      - "127.0.0.1:5432:5432" # Solo mantenimiento local
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - internal-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres} -d gymsmart"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: gymsmart-redis
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    networks:
      - internal-net
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 5s
      timeout: 3s
      retries: 3

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: gymsmart-api
    restart: on-failure
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/gymsmart?schema=public&connection_limit=15
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - TZ=America/Lima
      - PORT=3000
    command: sh -c "npx prisma migrate deploy && node dist/main.js"
    networks:
      - internal-net
      - public-net

  frontend-web:
    build:
      context: ./mobile_app
      dockerfile: Dockerfile
    container_name: gymsmart-flutter-web
    restart: unless-stopped
    networks:
      - public-net

  gateway:
    image: nginx:alpine
    container_name: gymsmart-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./infra/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./infra/nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - api
      - frontend-web
    networks:
      - public-net

networks:
  internal-net:
    driver: bridge
    internal: true
  public-net:
    driver: bridge

volumes:
  postgres_data:
```
