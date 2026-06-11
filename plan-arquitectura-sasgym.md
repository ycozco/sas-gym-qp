# Plan de Arquitectura y Despliegue — SAS Gym
## sas-gym.qpsecure.cloud

> **Alcance:** Este documento cubre la arquitectura del sistema, arquitectura de despliegue, operación y seguridad del proyecto SAS Gym (GymSmart / CodeFit).  
> **Stack:** NestJS · Flutter · React · PostgreSQL · Redis · Docker  
> **Entorno MVP:** VPS Hostinger — `sas-gym.qpsecure.cloud`  
> **Versión:** 1.0 — Junio 2026

---

## Índice

**Arquitectura del Sistema**
1. [Visión general y componentes](#1-vision-general)
2. [Módulos principales](#2-modulos)
3. [Arquitectura SaaS y multitenancy](#3-multitenancy)

**Arquitectura de Despliegue**
4. [Infraestructura y diagrama de despliegue](#4-infraestructura)
5. [DNS y subdominios](#5-dns)
6. [Docker Compose](#6-docker-compose)
7. [Redes Docker](#7-redes)
8. [SSL](#8-ssl)

**Operación y Seguridad**
9. [Seguridad](#9-seguridad)
10. [Base de datos y migraciones](#10-base-de-datos)
11. [Backups y recuperación](#11-backups)
12. [Monitoreo y observabilidad](#12-monitoreo)
13. [Recursos de infraestructura](#13-recursos)

**Evolución Futura**
14. [CI/CD — Fase posterior](#14-cicd)

**Anexos (Herramientas de Desarrollo)**
- [A — Graphify](#anexo-a-graphify)
- [B — Obsidian](#anexo-b-obsidian)
- [C — Claude Code MCP](#anexo-c-claude-code)

---

---

# PARTE I — ARQUITECTURA DEL SISTEMA

---

## 1. Visión general y componentes {#1-vision-general}

### Diagrama lógico de componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTES                                 │
│                                                                 │
│   ┌──────────────────┐         ┌──────────────────────┐        │
│   │  Flutter Mobile  │         │    React Web Admin   │        │
│   │  (iOS / Android) │         │  admin.sas-gym.*     │        │
│   └────────┬─────────┘         └──────────┬───────────┘        │
└────────────┼──────────────────────────────┼────────────────────┘
             │ HTTPS / WSS                  │ HTTPS
             ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  NGINX PROXY MANAGER                            │
│         (SSL termination · routing · CORS)                      │
└──────┬──────────────────────────────────┬───────────────────────┘
       │                                  │
       ▼                                  ▼
┌─────────────┐                  ┌─────────────────┐
│  NestJS API │                  │ WebSocket        │
│  :3000      │◄────────────────►│ Gateway :3001   │
│  REST       │   Redis pub/sub  │ (saas.gateway)  │
└──────┬──────┘                  └────────┬─────────┘
       │                                  │
       └──────────────┬───────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   ┌─────────────┐        ┌─────────────┐
   │ PostgreSQL  │        │    Redis    │
   │ :5432       │        │    :6379    │
   │ (datos)     │        │ (cache/WS)  │
   └─────────────┘        └─────────────┘
```

### Responsabilidades por componente

| Componente | Responsabilidad | Tecnología |
|---|---|---|
| **Flutter Mobile** | UI para Practicante, Entrenador, Administrador. Consume API REST y WebSocket. | Flutter / Dart |
| **React Web Admin** | Panel de gestión para Administrador y SuperAdmin. Dashboard, reportes, configuración del gym. | React / JSX |
| **NestJS API** | Lógica de negocio, autenticación JWT, RBAC, multitenancy, validación de DTOs. | NestJS / Node.js v24 |
| **WebSocket Gateway** | Comunicación en tiempo real: check-in de miembros, alertas de pago, notificaciones. | NestJS Gateway / Socket.IO |
| **PostgreSQL** | Persistencia principal. Un esquema por tenant (aislamiento de datos). | PostgreSQL 16 |
| **Redis** | Sesiones, caché de tokens, pub/sub para WebSocket, rate limiting futuro. | Redis 7 |
| **Nginx Proxy Manager** | Reverse proxy con UI, SSL automático vía Let's Encrypt, routing por subdominio. | NPM + Docker |

### Flujo general de comunicación

```
1. Cliente Flutter / Web Admin
   → HTTPS request a Nginx Proxy Manager
   → Nginx rutea al contenedor correcto según subdominio
   → NestJS valida JWT + tenant_id + rol
   → Consulta PostgreSQL o Redis
   → Responde JSON

2. Eventos en tiempo real
   → Cliente abre conexión WSS a ws.sas-gym.*
   → NestJS Gateway valida token en handshake
   → Redis pub/sub distribuye eventos entre instancias
   → Gateway emite al cliente suscrito
```

---

## 2. Módulos principales {#2-modulos}

```
backend/src/
├── core/
│   ├── guards/       auth.guard.ts       ← Valida JWT en cada request
│   ├── decorators/   public.decorator.ts ← Marca rutas sin auth
│   │                 roles.decorator.ts  ← Define roles requeridos
│   │                 tenant-id.decorator.ts ← Inyecta tenant del JWT
│   └── gateways/     saas.gateway.ts     ← WebSocket principal
│
├── auth/             Login, register, refresh, logout
├── members/          CRUD miembros del gym
├── payments/         Pagos Yape/Plin, historial
├── routines/         Rutinas de entrenamiento
└── tenants/          Configuración del gym (tenant)
```

| Módulo | Endpoints clave | Roles con acceso |
|---|---|---|
| **Auth** | login, refresh, logout | Público (login) · Todos (refresh) |
| **Members** | CRUD /members | Entrenador, Administrador |
| **Payments** | /payments, /payments/yape/verify | Administrador |
| **Routines** | CRUD /routines | Entrenador, Administrador |
| **Tenants** | /tenants/me, /tenants/me/stats | Administrador, SuperAdmin |

---

## 3. Arquitectura SaaS y Multitenancy {#3-multitenancy}

### Estrategia de aislamiento

Cada gymnasium registrado en la plataforma es un **tenant independiente**. El aislamiento se implementa mediante `tenant_id` en cada tabla de datos. Ningún usuario puede acceder a datos de otro tenant, sin excepción.

```
┌─────────────────────────────────────────────┐
│              PostgreSQL                      │
│                                             │
│  ┌──────────────────┐  ┌──────────────────┐ │
│  │  tenant_id: abc  │  │  tenant_id: xyz  │ │
│  │  Gym "FitMax"    │  │  Gym "IronBody"  │ │
│  │  members         │  │  members         │ │
│  │  payments        │  │  payments        │ │
│  │  routines        │  │  routines        │ │
│  └──────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────┘
```

### Flujo de tenant_id

```
JWT emitido en login
  └── payload: { sub: userId, role: "admin", tenant_id: "abc123" }
        └── @TenantId() decorator extrae tenant_id del JWT
              └── Cada query incluye WHERE tenant_id = :tenantId
```

### Roles y permisos

| Rol | Acceso | Restricción |
|---|---|---|
| **Practicante** | Ver sus rutinas, ver su historial de pagos | Solo sus propios datos |
| **Entrenador** | Ver y crear rutinas, ver miembros de su tenant | Solo su tenant |
| **Administrador** | CRUD completo de su gym | Solo su tenant |
| **SuperAdmin** | Acceso a todos los tenants, configuración global | Sin restricción de tenant |

### Riesgos de fuga entre tenants

| Riesgo | Mitigación |
|---|---|
| Query sin filtro de tenant | `@TenantId()` obligatorio en servicios; revisión en auditoría |
| Token de un tenant usado en otro | `tenant_id` embebido en JWT y verificado en guard |
| SuperAdmin expuesto accidentalmente | Rol SuperAdmin solo creado por CLI en base de datos |
| Logs mezclados entre tenants | `tenant_id` incluido en cada entrada de log |

---

---

# PARTE II — ARQUITECTURA DE DESPLIEGUE

---

## 4. Infraestructura y diagrama de despliegue {#4-infraestructura}

### Diagrama real del VPS

```
╔═══════════════════════════════════════════════════════════════╗
║              VPS Hostinger (16 GB RAM · 200 GB SSD)          ║
║                                                               ║
║  ┌─────────────────────────────────────────────────────────┐  ║
║  │  RED PÚBLICA (proxy_net)                                │  ║
║  │                                                         │  ║
║  │  ┌──────────────────────────────────────────────────┐   │  ║
║  │  │  Nginx Proxy Manager   :80 / :443 / :81(admin)  │   │  ║
║  │  └────────┬─────────────────────┬───────────────────┘   │  ║
║  │           │                     │                        │  ║
║  │    ┌──────▼──────┐     ┌────────▼────────┐              │  ║
║  │    │  API NestJS │     │ WebSocket       │              │  ║
║  │    │  :3000      │     │ Gateway :3001   │              │  ║
║  │    └──────┬──────┘     └────────┬────────┘              │  ║
║  └───────────┼────────────────────-┼────────────────────── ┘  ║
║              │                     │                           ║
║  ┌───────────┼─────────────────────┼───────────────────────┐  ║
║  │  RED PRIVADA (backend_net)       │                       │  ║
║  │           │                     │                        │  ║
║  │    ┌──────▼─────────────────────▼──────┐                │  ║
║  │    │         PostgreSQL :5432           │                │  ║
║  │    │         Redis      :6379           │                │  ║
║  │    │   (sin acceso desde Internet)      │                │  ║
║  │    └───────────────────────────────────┘                │  ║
║  └──────────────────────────────────────────────────────── ┘  ║
╚═══════════════════════════════════════════════════════════════╝
```

### Flujo de request completo

```
Internet
   ↓ HTTPS :443
Nginx Proxy Manager         ← SSL termination, routing por subdominio
   ↓ HTTP interno
NestJS API :3000            ← Autenticación JWT, RBAC, lógica de negocio
   ↓
PostgreSQL :5432            ← Datos persistentes (red privada)
Redis :6379                 ← Caché, sesiones (red privada)
```

---

## 5. DNS y subdominios {#5-dns}

### Estrategia DNS

Registros en Cloudflare (o proveedor DNS de qpsecure.cloud):

```dns
; Registro raíz
sas-gym.qpsecure.cloud          A      <IP_VPS>

; Wildcard — cubre todos los subdominios actuales y futuros
*.sas-gym.qpsecure.cloud        A      <IP_VPS>
```

**Cuándo usar wildcard vs registros individuales:**
- **Wildcard `*.`** — úsalo cuando todos los subdominios apuntan al mismo VPS. Simplifica la gestión.
- **Registros individuales** — solo si un subdominio apunta a una IP diferente (ej. CDN, servidor secundario).

### Tabla de subdominios

| Subdominio | Puerto interno | Servicio | Fase | Estado |
|---|---|---|---|---|
| `api.sas-gym.qpsecure.cloud` | `:3000` | NestJS API REST | MVP | ✅ Activo |
| `ws.sas-gym.qpsecure.cloud` | `:3001` | WebSocket Gateway | MVP | ✅ Activo |
| `admin.sas-gym.qpsecure.cloud` | `:4000` | React Web Admin | Fase 2 | 🔜 Pendiente |
| `app.sas-gym.qpsecure.cloud` | `:4001` | Flutter Web PWA | Fase 3 | 🔜 Pendiente |
| `npm.sas-gym.qpsecure.cloud` | `:81` | Nginx Proxy Manager UI | Operación | 🔒 Restringido |

> **Nota:** `npm.sas-gym.qpsecure.cloud:81` debe estar protegido por IP allowlist o VPN. Nunca exponer públicamente.

---

## 6. Docker Compose {#6-docker-compose}

### 6.1 `docker-compose.local.yml` — Desarrollo

Incluye todos los servicios necesarios para desarrollo local, **incluyendo Graphify** (herramienta de desarrollo, ver Anexo A).

```yaml
# docker-compose.local.yml
# Uso: docker compose -f docker-compose.local.yml up -d

version: "3.9"

services:

  postgres:
    image: postgres:16-alpine
    container_name: sasgym_postgres_dev
    environment:
      POSTGRES_DB: sasgym_dev
      POSTGRES_USER: sasgym_user
      POSTGRES_PASSWORD: devpassword123
    ports:
      - "5432:5432"      # Expuesto en dev para herramientas como DBeaver
    volumes:
      - sasgym_pgdata_dev:/var/lib/postgresql/data
    networks:
      - sasgym_backend_dev

  redis:
    image: redis:7-alpine
    container_name: sasgym_redis_dev
    ports:
      - "6379:6379"      # Expuesto en dev para Redis Insight
    volumes:
      - sasgym_redisdata_dev:/data
    networks:
      - sasgym_backend_dev

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: sasgym_api_dev
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development
      PORT: 3000
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: sasgym_dev
      DB_USER: sasgym_user
      DB_PASSWORD: devpassword123
      REDIS_HOST: redis
      REDIS_PORT: 6379
      JWT_SECRET: dev_jwt_secret_change_in_prod
      JWT_EXPIRES_IN: 60m
      JWT_REFRESH_SECRET: dev_refresh_secret
      JWT_REFRESH_EXPIRES_IN: 30d
    volumes:
      - ./backend/src:/app/src    # Hot reload en desarrollo
    depends_on:
      - postgres
      - redis
    networks:
      - sasgym_backend_dev
      - sasgym_public_dev

  ws:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: sasgym_ws_dev
    ports:
      - "3001:3001"
    environment:
      NODE_ENV: development
      PORT: 3001
      WS_MODE: "true"
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: sasgym_dev
      DB_USER: sasgym_user
      DB_PASSWORD: devpassword123
      REDIS_HOST: redis
      REDIS_PORT: 6379
      JWT_SECRET: dev_jwt_secret_change_in_prod
    depends_on:
      - api
    networks:
      - sasgym_backend_dev
      - sasgym_public_dev

  # ── Graphify: SOLO DESARROLLO — ver Anexo A ──────────────
  graphify:
    build:
      context: ./graphify
      dockerfile: Dockerfile
    container_name: sasgym_graphify_dev
    ports:
      - "7331:7331"      # MCP SSE — solo localhost
    volumes:
      - ./:/code:ro
      - ./graphify/graphify-out:/output
    environment:
      GRAPHIFY_WATCH: "true"
      GRAPHIFY_INCLUDE: "backend,mobile_app,web_admin,arquitectura"
      GRAPHIFY_EXCLUDE: "dist,node_modules,.dart_tool,build,graphify-out"
    networks:
      - sasgym_public_dev

volumes:
  sasgym_pgdata_dev:
  sasgym_redisdata_dev:

networks:
  sasgym_backend_dev:
    driver: bridge
    internal: true
  sasgym_public_dev:
    driver: bridge
```

---

### 6.2 `docker-compose.production.yml` — Producción

**Solo servicios productivos.** Sin Graphify, sin Obsidian, sin herramientas de desarrollo.

```yaml
# docker-compose.production.yml
# Uso: docker compose -f docker-compose.production.yml --env-file .env up -d --build

version: "3.9"

services:

  # ─── Nginx Proxy Manager ────────────────────────────────────
  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: sasgym_npm
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "81:81"          # UI admin — proteger por IP o VPN
    volumes:
      - sasgym_npm_data:/data
      - sasgym_npm_letsencrypt:/etc/letsencrypt
    networks:
      - sasgym_proxy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:81/api/"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ─── PostgreSQL ─────────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: sasgym_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - sasgym_pgdata:/var/lib/postgresql/data
    networks:
      - sasgym_backend        # SOLO red privada — sin acceso externo
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ─── Redis ──────────────────────────────────────────────────
  redis:
    image: redis:7-alpine
    container_name: sasgym_redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - sasgym_redisdata:/data
    networks:
      - sasgym_backend        # SOLO red privada
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # ─── NestJS API ─────────────────────────────────────────────
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: sasgym_api
    restart: unless-stopped
    expose:
      - "3000"           # Solo visible dentro de Docker, NPM accede por red
    environment:
      NODE_ENV: production
      PORT: 3000
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRES_IN: ${JWT_EXPIRES_IN}
      JWT_REFRESH_SECRET: ${JWT_REFRESH_SECRET}
      JWT_REFRESH_EXPIRES_IN: ${JWT_REFRESH_EXPIRES_IN}
      APP_URL: https://api.sas-gym.qpsecure.cloud
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - sasgym_backend
      - sasgym_proxy

  # ─── WebSocket Gateway ──────────────────────────────────────
  ws:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: sasgym_ws
    restart: unless-stopped
    expose:
      - "3001"
    environment:
      NODE_ENV: production
      PORT: 3001
      WS_MODE: "true"
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      - api
    networks:
      - sasgym_backend
      - sasgym_proxy

volumes:
  sasgym_npm_data:
  sasgym_npm_letsencrypt:
  sasgym_pgdata:
  sasgym_redisdata:

networks:
  sasgym_proxy:
    driver: bridge        # Red pública — NPM + API + WS
  sasgym_backend:
    driver: bridge
    internal: true        # Red privada — PostgreSQL + Redis sin internet
```

---

## 7. Redes Docker {#7-redes}

| Red | Nombre | Tipo | Servicios | Acceso a Internet |
|---|---|---|---|---|
| **Pública** | `sasgym_proxy` | bridge | NPM, API, WS | Sí (rutea a exterior vía NPM) |
| **Privada** | `sasgym_backend` | bridge + internal | API, WS, PostgreSQL, Redis | ❌ No |

**Regla:** PostgreSQL y Redis **solo** pertenecen a `sasgym_backend`. Nunca tienen puerto publicado al host ni pertenecen a `sasgym_proxy`.

```
Internet → NPM (proxy) → API/WS (proxy + backend) → PostgreSQL/Redis (backend only)
```

---

## 8. SSL {#8-ssl}

### Nginx Proxy Manager gestiona SSL automáticamente

No se requiere Certbot manual. NPM emite y renueva certificados vía Let's Encrypt con un clic desde su UI en `:81`.

**Pasos en la UI de NPM:**

```
1. Abrir https://npm.sas-gym.qpsecure.cloud:81
2. Proxy Hosts → Add Proxy Host
3. Por cada subdominio:
   - Domain: api.sas-gym.qpsecure.cloud
   - Forward Host: sasgym_api (nombre del contenedor)
   - Forward Port: 3000
   - SSL tab → Request a new SSL Certificate
   - Enable: Force SSL, HTTP/2, HSTS
4. Repetir para ws.* → sasgym_ws:3001
```

**Para subdominios futuros:** el wildcard `*.sas-gym.qpsecure.cloud` ya apunta al VPS por DNS; solo hay que agregar el Proxy Host en NPM y solicitar el certificado.

**Renovación:** automática. NPM renueva 30 días antes de expirar sin intervención manual.

---

---

# PARTE III — OPERACIÓN Y SEGURIDAD

---

## 9. Seguridad {#9-seguridad}

### 9.1 Implementado en MVP

| Capa | Mecanismo | Archivo |
|---|---|---|
| **HTTPS** | TLS 1.2/1.3 vía NPM | Nginx Proxy Manager |
| **Autenticación** | JWT con expiración corta (15m) | `auth.guard.ts` |
| **Refresh Token** | Token rotativo, almacenado en Redis | `auth/` module |
| **RBAC** | Roles por JWT, `@Roles()` decorator | `roles.decorator.ts` |
| **Multitenancy** | `tenant_id` en JWT + query filter | `tenant-id.decorator.ts` |
| **Rutas públicas** | `@Public()` decorator explícito | `public.decorator.ts` |
| **Validación de DTOs** | `ValidationPipe` global con `whitelist: true` | `main.ts` |
| **Secretos** | Variables de entorno, nunca en repositorio | `.env.production` |

### 9.2 Configuración recomendada en `main.ts`

```typescript
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,          // Elimina propiedades no declaradas en DTO
  forbidNonWhitelisted: true, // Rechaza requests con propiedades extra
  transform: true,          // Transforma tipos automáticamente
}));

app.use(helmet());          // Headers de seguridad HTTP
app.enableCors({
  origin: [
    'https://admin.sas-gym.qpsecure.cloud',
    'https://app.sas-gym.qpsecure.cloud',
  ],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Authorization', 'Content-Type', 'X-Tenant-ID'],
});
```

### 9.3 Mejoras futuras (priorizadas)

| Prioridad | Mejora | Descripción |
|---|---|---|
| Alta | **Rate limiting** | `@nestjs/throttler` — limitar intentos de login |
| Alta | **Logs de auditoría** | Registrar quién hizo qué y cuándo, con tenant_id |
| Media | **Logs centralizados** | Loki + Grafana o similar |
| Media | **2FA** | Segundo factor para Administrador y SuperAdmin |
| Baja | **WAF** | Cloudflare WAF en capa DNS |

### 9.4 Reglas críticas de seguridad

```
✗ NUNCA hacer query sin filtro WHERE tenant_id = :tenantId
✗ NUNCA commitear .env o secretos al repositorio
✗ NUNCA exponer puertos de PostgreSQL o Redis al exterior
✗ NUNCA crear usuarios SuperAdmin desde la API pública
✓ SIEMPRE validar JWT antes de acceder a datos
✓ SIEMPRE usar @Public() explícitamente para rutas sin auth
✓ SIEMPRE incluir tenant_id en los logs
```

---

## 10. Base de datos y migraciones {#10-base-de-datos}

### Arquitectura PostgreSQL

```
PostgreSQL 16
├── Base de datos: sasgym_prod
│   ├── schema: public
│   │   ├── tenants          ← Registro de gyms
│   │   ├── users            ← Usuarios con tenant_id
│   │   ├── members          ← Miembros con tenant_id
│   │   ├── payments         ← Pagos con tenant_id
│   │   ├── routines         ← Rutinas con tenant_id
│   │   └── migrations       ← Historial de migraciones
```

### Persistencia

Datos persistidos en volumen Docker `sasgym_pgdata`. El contenedor puede reiniciarse sin pérdida de datos.

### Migraciones con TypeORM

```bash
# Generar migración tras cambio en entidad
docker exec sasgym_api npm run migration:generate -- src/migrations/NombreCambio

# Aplicar migraciones pendientes
docker exec sasgym_api npm run migration:run

# Revertir última migración (rollback)
docker exec sasgym_api npm run migration:revert

# Ver migraciones aplicadas
docker exec sasgym_api npm run migration:show
```

### Estrategia de actualización de esquema

```
Desarrollo  → migration:generate (auto desde entidades)
Staging     → migration:run (aplicar y verificar)
Producción  → migration:run en ventana de mantenimiento
             → Si falla → migration:revert inmediato
```

**Regla:** nunca usar `synchronize: true` en producción. Solo `migrations`.

---

## 11. Backups y recuperación {#11-backups}

### Estrategia de backups

| Tipo | Frecuencia | Retención | Herramienta |
|---|---|---|---|
| **Diario** | 02:00 AM hora Perú | 7 días | pg_dump + cron |
| **Semanal** | Domingo 03:00 AM | 4 semanas | pg_dump + cron |
| **Mensual** | Día 1 de cada mes | 3 meses | pg_dump + cron |

### Script de backup — `/opt/sasgym/scripts/backup.sh`

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/sasgym/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="sasgym_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

# Dump comprimido
docker exec sasgym_postgres pg_dump \
  -U "${DB_USER}" \
  "${DB_NAME}" | gzip > "${BACKUP_DIR}/${FILENAME}"

echo "Backup creado: ${FILENAME}"

# Limpieza: eliminar backups diarios de más de 7 días
find "$BACKUP_DIR" -name "sasgym_*.sql.gz" -mtime +7 -delete

echo "Limpieza completada"
```

```bash
# Crontab en el VPS
0 2 * * * /opt/sasgym/scripts/backup.sh >> /var/log/sasgym-backup.log 2>&1
```

### Restauración

```bash
# Restaurar desde backup
gunzip -c /opt/sasgym/backups/sasgym_20260601_020000.sql.gz | \
  docker exec -i sasgym_postgres psql -U "${DB_USER}" "${DB_NAME}"
```

**Prueba periódica de restauración:** ejecutar el procedimiento de restauración en un entorno de staging mensualmente para verificar que los backups son válidos.

---

## 12. Monitoreo y observabilidad {#12-monitoreo}

### Health checks por servicio

| Servicio | Health Check | URL / Comando |
|---|---|---|
| **API** | Endpoint `/health` | `GET https://api.sas-gym.qpsecure.cloud/health` |
| **WebSocket** | Ping del gateway | Verificar conexión WSS |
| **PostgreSQL** | `pg_isready` | Definido en docker-compose |
| **Redis** | `redis-cli ping` | Definido en docker-compose |
| **NPM** | UI accesible | `GET http://localhost:81/api/` |

### Uptime Kuma — monitoreo continuo

Agregar al `docker-compose.production.yml`:

```yaml
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: sasgym_uptime
    restart: unless-stopped
    ports:
      - "3002:3001"      # UI en :3002 del host
    volumes:
      - sasgym_uptime_data:/app/data
    networks:
      - sasgym_proxy
```

Configurar en la UI de Uptime Kuma:
- Monitor HTTP: `https://api.sas-gym.qpsecure.cloud/health` cada 60s
- Monitor TCP: `localhost:5432` (PostgreSQL)
- Monitor TCP: `localhost:6379` (Redis)
- Notificaciones: email o Telegram al fallar

### Logs Docker

```bash
# Ver logs en tiempo real
docker compose -f docker-compose.production.yml logs -f api
docker compose -f docker-compose.production.yml logs -f ws

# Últimas 100 líneas de un servicio
docker logs sasgym_api --tail=100

# Logs con timestamp
docker logs sasgym_api --timestamps --tail=200
```

---

## 13. Recursos de infraestructura {#13-recursos}

### Estimación de consumo MVP

| Servicio | RAM estimada | CPU | Disco |
|---|---|---|---|
| NestJS API | ~200 MB | bajo | — |
| WebSocket Gateway | ~150 MB | bajo-medio | — |
| PostgreSQL | ~300 MB | bajo | ~5 GB/año |
| Redis | ~50 MB | mínimo | — |
| Nginx Proxy Manager | ~100 MB | mínimo | — |
| Uptime Kuma | ~50 MB | mínimo | — |
| **Total estimado** | **~850 MB** | bajo | ~5 GB/año |

### Requisitos del VPS

| Tier | RAM | CPU | Disco | Aplica |
|---|---|---|---|---|
| **Mínimo** | 2 GB | 1 vCPU | 20 GB | Solo MVP básico |
| **Recomendado** | 4 GB | 2 vCPU | 40 GB | MVP con margen |
| **Disponible** | 16 GB | 4+ vCPU | 200 GB | VPS Hostinger actual |

El VPS Hostinger de 16 GB actual tiene amplio margen para el MVP y las fases 2 y 3.

**Justificación de Hostinger para MVP:** costo predecible, panel de control simple, soporte a Docker nativo, ubicación en Latinoamérica reduce latencia desde Perú.

---

---

# PARTE IV — EVOLUCIÓN FUTURA

---

## 14. CI/CD — Fase posterior {#14-cicd}

> ⚠️ Esta sección describe el objetivo futuro. **No aplica al MVP actual.**

### Pipeline objetivo

```
Developer → git push → GitHub
                          ↓
                    GitHub Actions
                          ↓
                    Docker Build & Test
                          ↓
                    Docker Registry
                    (ghcr.io o Docker Hub)
                          ↓
                    SSH deploy al VPS
                    docker compose pull
                    docker compose up -d
```

### Workflow base (referencia futura)

```yaml
# .github/workflows/backend.yml (objetivo futuro)
name: Deploy Backend

on:
  push:
    branches: [main]
    paths: [backend/**]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & push image
        run: |
          docker build -t ghcr.io/tu-usuario/sasgym-api:latest ./backend
          docker push ghcr.io/tu-usuario/sasgym-api:latest
      - name: Deploy en VPS
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /opt/sasgym
            docker compose -f docker-compose.production.yml pull api
            docker compose -f docker-compose.production.yml up -d api
```

Los workflows `backend.yml`, `flutter.yml`, `integration.yml` y `web-smoke.yml` ya existen en `.github/workflows/`. Activar el deploy automático es la siguiente fase tras estabilizar el MVP.

---

---

# ANEXOS — HERRAMIENTAS DE DESARROLLO

> ⚠️ **Las herramientas de los Anexos A, B y C NO forman parte del entorno productivo.**  
> Se usan exclusivamente en desarrollo local para: auditoría de código, navegación del codebase, documentación y análisis arquitectónico.  
> No deben aparecer en `docker-compose.production.yml`.

---

## Anexo A — Graphify {#anexo-a-graphify}

### Objetivo

Graphify convierte el codebase de `sas_gym` en un grafo de conocimiento queryable. Permite a Claude Code (Fable 5) navegar ~3,700 archivos sin leerlos todos en cada sesión, reduciendo el consumo de tokens en hasta 70×.

### Limitaciones

- Solo para desarrollo local
- El grafo debe regenerarse al hacer cambios estructurales grandes
- No envía código a servidores externos (procesamiento local)

### Instalación

```bash
pip install graphifyy
graphify install       # Integra hooks con Claude Code
```

### Estructura de archivos

```
D:\proyectos\sas_gym\
└── graphify\
    ├── Dockerfile
    ├── docker-compose.yml     ← Solo incluido en docker-compose.local.yml
    └── graphify-out\          ← Agregar a .gitignore
        ├── graph.json
        ├── graph.html
        └── GRAPH_REPORT.md
```

### `graphify/Dockerfile`

```dockerfile
FROM python:3.12-slim
WORKDIR /workspace
RUN apt-get update && apt-get install -y git nodejs npm \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir graphifyy
VOLUME ["/code"]
VOLUME ["/output"]
EXPOSE 7331
CMD ["sh", "-c", "graphify /code --output /output --serve --port 7331"]
```

### Uso con Claude Code

El servidor MCP de Graphify corre en `localhost:7331`. Claude Code se conecta automáticamente si `settings.json` está configurado (ver Anexo C).

Comandos disponibles en sesión:

```
/graphify query auth              ← Buscar nodos relacionados a auth
/graphify path auth.guard payments ← Trazar ruta entre módulos
/graphify explain saas.gateway    ← Explicar un componente
```

### Primera ejecución

```bash
cd D:\proyectos\sas_gym\graphify
docker compose up -d
docker compose logs -f graphify    # Esperar "MCP server listening on :7331"
```

---

## Anexo B — Obsidian {#anexo-b-obsidian}

### Objetivo

Visualizar el grafo generado por Graphify como un vault de Obsidian. Útil para entender clusters del sistema (auth, payments, multitenancy) de forma visual.

### Uso

1. Descargar [Obsidian](https://obsidian.md/) (gratuito)
2. Abrir `graphify/graphify-out/` como vault
3. Activar la vista de grafo (`Ctrl+G`)

### Limitaciones

- Solo visualización — no modifica código
- Requiere que Graphify haya generado el output con `GRAPHIFY_OBSIDIAN=true`
- No tiene integración directa con el backend productivo

### Instalar plugin MCP (opcional)

Para que Claude Desktop también acceda al vault:

```json
// %APPDATA%\Claude\claude_desktop_config.json
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["mcp-remote", "http://localhost:22360/sse"]
    }
  }
}
```

---

## Anexo C — Claude Code y MCP {#anexo-c-claude-code}

### Objetivo

Configurar Claude Code (extensión VS Code oficial) para usar el grafo de Graphify como contexto, reduciendo iteraciones y consumo de cuota especialmente con Fable 5.

### `.claude/settings.json`

```json
{
  "mcpServers": {
    "graphify": {
      "type": "sse",
      "url": "http://localhost:7331/sse",
      "description": "Knowledge graph de sas_gym"
    }
  },
  "hooks": {
    "SessionStart": [
      {
        "command": "cat graphify/graphify-out/GRAPH_REPORT.md 2>/dev/null || echo '[Graphify no activo] Correr: cd graphify && docker compose up -d'"
      }
    ]
  }
}
```

### `CLAUDE.md` — instrucciones de sesión

```markdown
# sas_gym — SaaS Gym Management

## Stack
- Backend: NestJS (Node.js v24) · PostgreSQL · Redis
- Mobile: Flutter/Dart — roles: Practicante, Entrenador, Administrador
- Web Admin: React/JSX
- Infra: Docker + Nginx Proxy Manager en VPS Hostinger

## Rutas clave
- Guards/Auth: backend/src/core/guards/
- Decorators:  backend/src/core/decorators/
- WS Gateway:  backend/src/core/gateways/saas.gateway.ts
- Features Flutter: mobile_app/lib/features/
- Web Admin: web_admin/
- Docs arquitectura: arquitectura/ (01–09)

## Knowledge Graph
- MCP activo en: http://localhost:7331/sse
- SIEMPRE consultar el grafo antes de leer archivos individuales
- /graphify query <término> para búsqueda semántica

## Convenciones críticas
- Multitenancy: NUNCA query sin WHERE tenant_id = :tenantId
- Auth: JWT + RBAC. @Public() explícito para rutas abiertas
- Secretos: siempre desde .env, nunca hardcodeados
- Pagos: Yape / Plin (no Stripe, no tarjetas internacionales)

## Dominio MVP
- API: https://api.sas-gym.qpsecure.cloud
- WS:  wss://ws.sas-gym.qpsecure.cloud
- Docs: https://api.sas-gym.qpsecure.cloud/docs
```

### Selección de modelo por tarea

| Tarea | Modelo recomendado | Razón |
|---|---|---|
| Auditoría de seguridad completa | **Fable 5** | Largo contexto, no pierde el hilo |
| Implementar fix puntual | **Opus 4.8** | Balance costo/calidad |
| Refactor simple, renombrar | **Sonnet 4.6** | Rápido y económico |
| Preguntas rápidas, búsquedas | **Haiku 4.5** | Mínimo consumo de cuota |

### Prompt inicial para sesión de auditoría con Fable 5

```
Eres auditor de seguridad senior del proyecto sas_gym.
Graphify MCP está activo en localhost:7331.

Antes de leer archivos, consulta:
  /graphify query auth
  /graphify query tenant isolation
  /graphify path auth.guard payments

Audita en orden:
1. God nodes de seguridad según el grafo (alta centralidad)
2. Flujo JWT: emisión → validación → refresh → revocación
3. Tenant isolation: ¿todos los endpoints filtran por tenant_id?
4. Guards: ¿hay endpoints @Public() que no deberían serlo?
5. WebSocket gateway: ¿autentica el handshake?
6. Plan priorizado: CRÍTICO / ALTO / MEDIO / BAJO

Solo el plan. Sin codificar todavía.
Máximo 3 lecturas de archivos directos; resto vía Graphify.
```

---

## Checklist final de despliegue MVP

```
INFRAESTRUCTURA
[ ] DNS wildcard *.sas-gym.qpsecure.cloud → IP VPS configurado
[ ] VPS con Docker y Docker Compose instalados
[ ] docker-compose.production.yml en /opt/sasgym/
[ ] .env.production en /opt/sasgym/ (NO en repo)

NGINX PROXY MANAGER
[ ] NPM levantado y accesible en :81
[ ] Proxy Host para api.sas-gym.qpsecure.cloud → sasgym_api:3000
[ ] Proxy Host para ws.sas-gym.qpsecure.cloud → sasgym_ws:3001
[ ] SSL emitido y Force SSL activado en ambos

DEPLOY
[ ] docker compose -f docker-compose.production.yml up -d --build
[ ] docker compose ps → todos los servicios "Up (healthy)"
[ ] docker exec sasgym_api npm run migration:run
[ ] curl https://api.sas-gym.qpsecure.cloud/health → {"status":"ok"}
[ ] Swagger accesible en /docs

SEGURIDAD
[ ] PostgreSQL sin puerto expuesto al host
[ ] Redis sin puerto expuesto al host
[ ] NPM admin (:81) protegido por IP allowlist
[ ] .env.production con contraseñas de 32+ caracteres

CLIENTES
[ ] Flutter build con --dart-define=PRODUCTION=true
[ ] web_admin/config.js apuntando a producción
[ ] Probar login desde Flutter en dispositivo real
[ ] Probar WebSocket desde Flutter

MONITOREO
[ ] Uptime Kuma configurado con alertas
[ ] Backup cron activo: crontab -l | grep backup
[ ] Script de backup probado manualmente
```
