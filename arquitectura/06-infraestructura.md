# Infraestructura

## Docker Compose vigentes

La configuracion Docker vigente vive solo en `infra/docker/`:

- `infra/docker/compose.local.yml`: desarrollo local.
- `infra/docker/compose.prod.yml`: produccion/preproduccion.
- `infra/docker/compose.tools.yml`: herramientas opcionales.

Los Compose antiguos de raiz, backend y mobile fueron eliminados para evitar ambiguedad operativa.

## Puertos

| Servicio | Puerto |
|---|---|
| API NestJS | `3000` |
| Flutter web | `8383` |
| Hub estatico/mockups/docs | `8282` |
| PostgreSQL | `127.0.0.1:5432` |

## Redes

El Compose local separa redes:

- `sasgym_backend_local`: PostgreSQL, Redis, API y WS.
- `sasgym_public_local`: API, WS, Flutter web y admin web.

## Persistencia

PostgreSQL usa el volumen `sasgym_pgdata_local`.

Importante: el comando de la API local ejecuta:

```sh
npm run db:setup:local && npm run start:dev
```

El seed local es manual y resetea la BD local:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml exec api npm run seed:local
```

Usarlo solo para inicializar o reiniciar datos demo. El arranque normal no debe resembrar ventas ni cambiar fechas.

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

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
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

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml build app-web
```

## Riesgos de infraestructura actual (Entorno AS-IS)

- La fuente unica de Docker Compose esta en `infra/docker/`.
- Existen carpetas generadas de desarrollo (`node_modules`, `dist`, `build`, etc.) que no deben versionarse.
- Los secretos en Compose deben venir de archivos `.env` no versionados.

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
        server app-web:80;
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

### Configuración del Compose de Producción

La fuente unica de configuracion productiva es `infra/docker/compose.prod.yml`. No duplicar YAML productivo en documentos; cualquier cambio debe hacerse en el archivo Compose vigente y luego documentarse de forma resumida.
