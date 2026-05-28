# PLAN DE EJECUCIÓN ARQUITECTÓNICA Y SEGMENTACIÓN DE REPOSITORIO — GYMSMART (SaaS GYM)

**Preparado por**: Principal Software Architect & Migration Lead  
**Fecha de Publicación**: Mayo 2026  
**Documento**: Plan de Ejecución e Infraestructura de Producción (TO-BE)  
**Estado**: Aprobado para Implementación Incremental  

---

## A. EXECUTIVE TECHNICAL SUMMARY (Resumen Ejecutivo)

El proyecto **GymSmart** representa la evolución comercial y técnica de la plataforma multi-tenant *CrossHero*. Se concibe como una plataforma **SaaS Multi-Tenant lógica (Single Database, Shared Schema)** que da servicio a múltiples franquicias e inquilinos individuales de gimnasios mediante cinco roles de usuario diferenciados. 

El presente plan traza el camino crítico para estabilizar el sistema actual, estructurar una arquitectura modular tolerante a fallos, robustecer el aislamiento de datos a nivel de base de datos, y garantizar que la infraestructura sea escalable horizontalmente (Stateless Ready) mediante contenedores de **Docker**, caché e intercomunicación con **Redis**, y un proxy inverso robusto bajo **Nginx**.

El objetivo no es rehacer el sistema desde cero, sino realizar refactorizaciones dirigidas que erradiquen las debilidades críticas identificadas y organicen el repositorio de forma sostenible.

---

## B. CURRENT ARCHITECTURE ASSESSMENT (Evaluación AS-IS)

La auditoría técnica del estado actual de GymSmart revela la siguiente situación:

### 1. Nivel de Madurez Arquitectónica
*   **Backend (NestJS v11 + Prisma ORM + PostgreSQL)**: Estructurado modularmente por lógica de negocio, pero altamente acoplado a nivel de persistencia. El uso de Prisma es correcto, pero carece de interceptores automáticos de aislamiento de datos.
*   **Frontend (Flutter 3.44 + Dart SDK ^3.12)**: Código compilable en Windows/Web. Presenta una alta fidelidad visual en roles de Caja y Admin, pero depende de un archivo controlador gigante (`gym_state.dart`) que mezcla responsabilidades.
*   **Infraestructura (Docker Compose Básico)**: Configurado para servir los mockups estáticos en el puerto `8282` y la API en el `3000`. No está optimizado para producción.

### 2. Fortalezas Reales
*   **Seguridad del Tenant en Request**: El `TenantGuard` realiza validación cruzada estricta entre el header `X-Tenant-ID` y el `tenantId` embebido en el JWT, previniendo accesos cruzados maliciosos en la capa HTTP.
*   **Separación de Redes en Docker**: La base de datos corre aislada de la red pública mediante `internal-net`, limitando los vectores de ataque externos.
*   **Modelado Completo**: Las entidades Prisma cubren de manera robusta los flujos financieros, inventario, asistencia biométrica, turnos y fidelización de usuarios.

### 3. Vulnerabilidades Críticas de Seguridad y Rendimiento
*   **Fuga de Datos Multi-Tenant**: Dependencia absoluta de que el desarrollador escriba manualmente `where: { tenant_id }` en cada query de Prisma. Si un desarrollador omite este filtro en un nuevo endpoint, se filtrará información confidencial a otros gimnasios.
*   **Monolitismo en Flutter State**: `gym_state.dart` de 50KB sobrecarga el loop de pintado de Flutter. Cualquier cambio en un log de caja fuerza el repintado de pantallas de rutinas de miembros si no se segmentan los ChangeNotifiers o providers.
*   **Bloqueo de Hilo en Audit Log**: La recursión profunda `sanitizeDeep` en `AuditInterceptor` puede degradar severamente el rendimiento de la API en payloads masivos (ej. matrices de rutinas o reportes anuales).
*   **WebSockets Acoplados al Proceso**: La falta de un backend broker (Redis) limita el escalado a un solo contenedor API, impidiendo el balanceo de carga moderno.

---

## C. TARGET ARCHITECTURE (Arquitectura Objetivo TO-BE)

La arquitectura objetivo establece un modelo **totalmente desacoplado, seguro y preparado para escalado horizontal**:

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

### 1. Flujo de Comunicaciones y Responsabilidades
1.  **Nginx**: Captura todas las peticiones HTTPS y conexiones de WebSockets en los puertos `80/443`. Realiza la terminación SSL y las reenvía por la red interna pública de Docker a los nodos activos de la API en el puerto `3000`.
2.  **API Nodes (NestJS)**: Contenedores totalmente stateless. La autenticación y la información del tenant se leen del token JWT y se propagan en el contexto asíncronamente.
3.  **Redis**:
    *   Sincroniza los estados de WebSockets mediante `@socket.io/redis-adapter` para que los mensajes emitidos por el Nodo A lleguen a clientes conectados al Nodo B.
    *   Maneja tokens de idempotencia para la creación de cobros y compras POS.
4.  **PostgreSQL**: Mantiene la base de datos centralizada con el esquema compartido. Los accesos son interceptados por una Extensión de Prisma que fuerza el tenant a nivel de base de datos.
5.  **Object Storage (S3 / MinIO)**: Almacena de manera distribuida las imágenes de observaciones, logs y archivos adjuntos de usuarios, evitando la dependencia local en disco.

---

## D. REPOSITORY SEGMENTATION (Plan de Segmentación)

Para consolidar la modularidad y escalabilidad de los servicios, se reorganizará el repositorio como un Monorepo estructurado que permita compilar, desplegar y mantener los servicios de forma limpia.

### 1. Distribución y Responsabilidades por Carpeta

```
sas_gym/ (Raíz del Repositorio)
├── .env.example              # Definición de variables de entorno para desarrollo
├── docker-compose.yml        # Configuración de servicios e infraestructura para producción
├── docker-compose.dev.yml    # Configuración de Docker para desarrollo y tweaks rápidos
│
├── backend/                  # Monolito Modular NestJS
│   ├── Dockerfile            # Compilación multi-etapa para entornos de producción
│   ├── package.json
│   ├── src/
│   │   ├── main.ts           # Punto de arranque y bootstrapping de la API
│   │   ├── app.module.ts     # Carga de módulos de negocio globales
│   │   │
│   │   ├── core/             # Componentes transversales del sistema (Core Layer)
│   │   │   ├── decorators/   # Decoradores custom (ej. @TenantId, @Roles)
│   │   │   ├── gateways/     # Capa Realtime (WebSockets - Socket.io)
│   │   │   ├── guards/       # Filtros de Acceso (Auth, Tenant, Roles)
│   │   │   └── interceptors/ # Interceptores (Audit con profundidad controlada, Idempotency)
│   │   │
│   │   ├── prisma/           # Prisma Service y Prisma Client Extensions (Aislamiento Multi-tenant)
│   │   │   ├── prisma.service.ts
│   │   │   └── extensions/
│   │   │
│   │   └── modules/          # Bounded Contexts (Lógica de Negocio Pura)
│   │       ├── auth/         # Autenticación, JWT, renovación de tokens, hashes
│   │       ├── members/      # Perfiles de miembros y entrenadores, historial
│   │       ├── payments/     # Caja, turnos diarios, POS, preventa
│   │       ├── attendance/   # Código TOTP, asistencia biométrica, huellas
│   │       ├── routines/     # Biblioteca de ejercicios y rutinas
│   │       ├── schedules/    # Agendamiento de clases grupales y reservas
│   │       ├── observations/ # Registro de observaciones y fotos de mantenimiento
│   │       ├── announcements/# Anuncios globales y envío FCM
│   │       └── reports/      # Consultas analíticas (asistencia, aforo, POS)
│   └── prisma/
│       ├── schema.prisma     # Definición del esquema PostgreSQL centralizado
│       └── seed.ts           # Semilla de datos de prueba
│
├── mobile_app/               # Aplicación Flutter Multi-Rol
│   ├── pubspec.yaml          # Gestión de dependencias
│   ├── Dockerfile            # Compilación multi-stage para web
│   ├── lib/
│   │   ├── main.dart         # Inicialización de la aplicación y carga de Providers
│   │   ├── app.dart          # Shell base y enrutador del selector de roles
│   │   │
│   │   ├── core/             # Base técnica compartida (Core Layer)
│   │   │   ├── network/      # Cliente Dio configurado e interceptores de red
│   │   │   ├── storage/      # SecureStorage y base de datos local Hive
│   │   │   ├── theme/        # Tema global Material 3
│   │   │   └── utils/        # Funciones auxiliares y formateadores
│   │   │
│   │   ├── features/         # Vistas y Lógica de Negocio por Dominio (Feature-Driven)
│   │   │   ├── auth/         # login_screen, auth_provider
│   │   │   ├── cashier/      # cashier_screen, cashier_provider, pos_cart
│   │   │   ├── member/       # member_screen, workout_log_provider
│   │   │   ├── trainer/      # trainer_screen, members_assigned_provider
│   │   │   ├── superadmin/   # client_list_screen, saas_provider
│   │   │   └── admin/        # admin_dashboard, audit_logs_provider
│   │   │
│   │   ├── models/           # Definición de estructuras de datos (Entities)
│   │   └── widgets/          # Componentes visuales reutilizables (UI Layer)
│   │
│   └── test/                 # Test unitarios y de widgets
│
├── mockups/                  # Prototipos interactivos y documentación visual
│   ├── mobile/               # Mockup del socio en React / CSS
│   └── web/                  # Mockup del back-office administrativo web
│
├── infra/                    # Configuración de la Infraestructura en la Nube / Servidor
│   ├── nginx/                # Servidor Web & Reverse Proxy
│   │   ├── nginx.conf        # Configuración de TLS, enrutado de API y proxying de WS
│   │   └── ssl/              # Certificados de seguridad locales y de staging
│   └── redis/
│       └── redis.conf        # Configuración de persistencia y límites de memoria
│
└── docs/                     # Documentación del Proyecto
    ├── architecture/         # Decisiones de diseño y diagramas
    └── decisions/            # Architecture Decision Records (ADRs)
```

---

## E. INFRASTRUCTURE STRATEGY (Estrategia de Infraestructura)

Para garantizar la fiabilidad del sistema en producción se definen los siguientes lineamientos:

### 1. Base de Datos PostgreSQL
*   **Pool de Conexiones**: Prisma Client no cuenta con un connection pooler nativo para entornos de alta concurrencia. Se debe acotar el pool a nivel de variable de conexión agregando el query parameter `connection_limit=15` en la URL de producción.
*   **Alta Disponibilidad**: Para despliegues a gran escala, se requerirá un proxy de base de datos como **PgBouncer** colocado entre NestJS y PostgreSQL para reciclar conexiones de manera eficiente.

### 2. Almacenamiento Persistente (Object Storage)
*   Para evitar la pérdida de archivos adjuntos y fotos al destruir contenedores de la API, se debe refactorizar el servicio de carga.
*   **Staging/Desarrollo**: Se levanta un contenedor local de **MinIO** compatible con el SDK de AWS S3.
*   **Producción**: Uso de un Bucket en **AWS S3** o Cloudinary con URLs firmadas temporalmente para la visualización segura de archivos.

### 3. Networking y Seguridad de Puertos
*   El único puerto expuesto al exterior será el puerto **443** (HTTPS) y **80** (HTTP redirect) del contenedor Nginx.
*   Los contenedores de `api`, `redis` y `db` operarán exclusivamente dentro de la red interna de Docker (`internal-net`), impidiendo cualquier escaneo de puertos o inyecciones externas directas.

---

## F. DOCKER & NGINX STRATEGY

### 1. Dockerfile de NestJS Optimizado para Producción
El Dockerfile actual inicia en modo desarrollo. Se debe migrar a un flujo multi-etapa para producción que reduzca el tamaño de la imagen y elimine las vulnerabilidades de desarrollo:

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

# Se ejecuta con node directo, sin nodemon ni ts-node
CMD ["node", "dist/main.js"]
```

### 2. Configuración de Orquestación (`docker-compose.yml`)
Configuración corregida para el entorno de producción que inyecta Redis y Nginx, eliminando la destrucción de datos:

```yaml
version: '3.8'

services:
  # Base de Datos Relacional
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

  # Servidor de Estado / Caché / Pub-Sub
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

  # API Backend (Nodos Stateless)
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

  # Frontend Web App compilado
  frontend-web:
    build:
      context: ./mobile_app
      dockerfile: Dockerfile
    container_name: gymsmart-flutter-web
    restart: unless-stopped
    networks:
      - public-net

  # Nginx Reverse Proxy y SSL
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

### 3. Nginx Reverse Proxy Config (`nginx.conf`)
Reglas de enrutamiento para soportar WebSockets y HTTPS seguro en el proxy:

```nginx
events { worker_connections 1024; }

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    # Rate Limiting: Máximo 60 peticiones por minuto por IP para la API
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=60r/m;

    upstream backend_api {
        server api:3000;
    }

    upstream frontend_flutter {
        server frontend-web:80;
    }

    # Redirección HTTP a HTTPS
    server {
        listen 80;
        server_name app.gymsmart.com;
        return 301 https://$host$request_uri;
    }

    # Servidor HTTPS
    server {
        listen 443 ssl;
        server_name app.gymsmart.com;

        ssl_certificate /etc/nginx/ssl/gymsmart.crt;
        ssl_certificate_key /etc/nginx/ssl/gymsmart.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # Cabeceras de protección básicas
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;

        # Enrutamiento de la API REST con Rate Limiting
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

        # Enrutamiento de WebSockets (Socket.io)
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

        # Enrutamiento del Frontend (Flutter Web)
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

---

## G. REDIS & REALTIME STRATEGY

### 1. Sincronización horizontal de WebSockets
Para soportar el balanceo de carga, se migrará `SaasGateway` para que Socket.io use un bus distribuido.
*   **Dependencia**: `@socket.io/redis-adapter` y `ioredis`.
*   **Flujo**: Cuando se emita un evento de suspensión de inquilino (`tenant_suspended`), Socket.io publicará el mensaje en Redis. Redis propagará el mensaje a todos los nodos API activos, quienes lo transmitirán a los clientes conectados a sus respectivos procesos.

### 2. Idempotencia en Cobros y Transacciones Financieras
Para evitar cobros duplicados en el POS ante cortes de red:
1.  El POS (Flutter) genera un identificador único UUIDv4 (`venta_token`) para cada solicitud de pago.
2.  Al llegar a la API, el interceptor `IdempotencyInterceptor` intenta registrar el `venta_token` en Redis con un comando atómico `SET venta_token "processing" EX 300 NX` (expira en 5 minutos y falla si ya existe).
3.  Si Redis retorna nulo, la API aborta la solicitud con un error `409 Conflict`.
4.  Si se completa el procesamiento con éxito, se actualiza el estado a `completed`. Si falla, se remueve el token para permitir reintentos válidos.

---

## H. FLUTTER MODULARIZATION PLAN (Refactorización)

Para desmantelar la estructura monolítica del estado actual en Flutter, se implementará la modularización basada en Riverpod.

### 1. Fragmentación de `gym_state.dart`
El actual ChangeNotifier masivo será fragmentado en proveedores especializados con scopes limitados:

```
gym_state.dart (God-Class)
     │
     ├──► authProvider (StateNotifier / Autenticación, JWT, checkAuth)
     ├──► cashierProvider (StateNotifier / Turnos de caja, ventas de membresías, arqueo)
     ├──► memberProvider (Notifier / Rutinas, entrenadores, progreso)
     ├──► announcementsProvider (Notifier / Anuncios locales, notificaciones masivas)
     └──► offlineCacheProvider (Manejo de almacenamiento en Hive)
```

### 2. Ejemplo de Implementación Modular de Riverpod
Definición de proveedores especializados y aislamiento del estado de autenticación:

```dart
// lib/features/auth/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final LoggedInUser? user;
  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, LoggedInUser? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  AuthNotifier(this._api) : super(AuthState());

  Future<bool> login(String email, String password, String tenantId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.dio.post('/auth/login', 
        data: {'email': email, 'password': password},
        options: Options(headers: {'X-Tenant-ID': tenantId})
      );
      final token = response.data['token'];
      await SecureStorage.saveToken(token);
      await SecureStorage.saveTenantId(tenantId);
      
      // Obtener perfil tras Login exitoso
      final profileRes = await _api.dio.get('/auth/me');
      final user = LoggedInUser.fromJson(profileRes.data);
      state = AuthState(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, error: 'Credenciales inválidas');
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiClient());
});
```

### 3. Aislamiento del WebSocket a nivel de UI
La conexión al socket se inicializa reactivamente al detectar que el estado de `authProvider` tiene un usuario autenticado activo. Ningún widget se suscribe al socket de forma directa; lo hacen a través de un `announcementsProvider` que actualiza su estado cuando el socket inyecta notificaciones push.

---

## I. BACKEND STABILIZATION PLAN (Estabilización)

### 1. Refactorización del Repositorio de Persistencia (Decoupling)
Actualmente, los servicios inyectan directamente `PrismaService` y ejecutan consultas SQL/Prisma en el cuerpo de la función. Esto acopla la lógica de negocio a la base de datos PostgreSQL.
*   **Estrategia**: Definir repositorios por dominio (ej. `MembersRepository`, `PaymentsRepository`) como clases intermedias para aislar las consultas complejas y permitir el mockeo en pruebas unitarias de manera limpia.

### 2. Sanitización Profunda Segura (Audit Loop Resolution)
Para solucionar el potencial bloqueo de la API por la recursión profunda del `AuditInterceptor`, se implementará un límite estricto de profundidad en la recursión (Depth Boundary):

```typescript
const sanitizeDeep = (obj: any, currentDepth = 0, maxDepth = 3): any => {
  if (obj === null || typeof obj !== 'object' || currentDepth >= maxDepth) {
    return typeof obj === 'object' && obj !== null ? '[Object Max Depth Exceeded]' : obj;
  }
  
  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeDeep(item, currentDepth + 1, maxDepth));
  }
  
  const sanitized: any = {};
  for (const key of Object.keys(obj)) {
    const lowerKey = key.toLowerCase();
    if (['pass', 'secret', 'token', 'hash', 'key'].some(kw => lowerKey.includes(kw))) {
      sanitized[key] = '********';
    } else {
      sanitized[key] = sanitizeDeep(obj[key], currentDepth + 1, maxDepth);
    }
  }
  return sanitized;
};
```

---

## J. DEPENDENCY MODERNIZATION PLAN (Actualización de Librerías)

Clasificación de actualizaciones de dependencias requeridas para producción:

### 1. Backend Dependencies
*   `@nestjs/common` / `@nestjs/core` (v11.0.1): **SAFE UPDATE** (Ya se encuentra en la versión mayor más reciente, mantener paridad).
*   `@prisma/client` / `prisma` (v5.14.0): **NEEDS TESTING** (Actualizar a `v5.22.0` o `v6.x` requiere validar compatibilidad de sintaxis de queries y extensiones multi-tenant).
*   `socket.io` / `@nestjs/websockets` (v11.0.1): **SAFE UPDATE**.
*   `ioredis` / `@socket.io/redis-adapter`: **NEEDS TESTING** (Instalación de paquetes requeridos para el desacoplamiento WebSocket).

### 2. Flutter Dependencies
*   `dio` (v5.7.0): **SAFE UPDATE**.
*   `flutter_secure_storage` (v9.2.2): **SAFE UPDATE**.
*   `hive_flutter` (v1.1.0): **SAFE UPDATE**.
*   `flutter_riverpod` (Añadir nuevo): **NEEDS TESTING** (Instalación requerida para desmantelar la God-Class).

### 3. Infraestructura
*   `postgres:15-alpine`: **SAFE UPDATE** (Migrar de `postgres:15` a `postgres:16-alpine` reduce el peso de la imagen sin romper compatibilidad SQL).
*   `nginx:alpine`: **SAFE UPDATE**.
*   `redis:7-alpine`: **SAFE UPDATE**.

---

## K. OBSERVABILITY PLAN (Observabilidad)

Para detectar anomalías y garantizar la fiabilidad del servicio SaaS:

1.  **Logs Estructurados**: Implementar el logger de NestJS configurado para imprimir en formato JSON en producción. Esto facilita la indexación en herramientas de agregación de logs.
2.  **Trazabilidad del Inquilino (Tenant Tracing)**: Cada log emitido por el backend debe incluir el `tenant_id` y el `correlation_id` (generado por petición en el proxy) para agrupar todas las trazas de una misma transacción.
3.  **Monitoreo del Healthcheck**: Exponer un endpoint público `/api/v1/health` utilizando `@nestjs/terminus` para reportar el estado de salud de la base de datos PostgreSQL, la conexión a Redis y el espacio en disco.

---

## L. SECURITY HARDENING PLAN (Plan de Seguridad)

### 1. Aislamiento Automatizado de Datos en Prisma
Para erradicar la fuga de datos multi-tenant, se inyectará una extensión que aplique los filtros de manera transparente a nivel de ORM.
*   **Mecanismo**: Uso de `AsyncLocalStorage` de Node.js para encapsular el `tenantId` en el ciclo de vida de la petición.

```typescript
// prisma/extensions/multi-tenant.extension.ts
import { Prisma } from '@prisma/client';
import { AsyncLocalStorage } from 'async_hooks';

export const tenantContext = new AsyncLocalStorage<{ tenantId: string }>();

export const multiTenantExtension = Prisma.defineExtension((client) => {
  return client.$extends({
    query: {
      $allModels: {
        async $allOperations({ model, operation, args, query }) {
          const store = tenantContext.getStore();
          // Exceptuar tablas globales que no pertenecen a inquilinos específicos
          if (store?.tenantId && model !== 'Tenant' && model !== 'AuditLog' && model !== 'PointsConfig') {
            args.where = {
              ...args.where,
              tenant_id: store.tenantId,
            };
          }
          return query(args);
        },
      },
    },
  });
});
```

### 2. Mitigación de Secrets Expuestos
*   Extraer todas las credenciales de base de datos, contraseñas de Redis y firmas JWT a un archivo `.env` local.
*   Agregar `.env` en `.gitignore` para prevenir fugas accidentales al repositorio.
*   En producción, inyectar los secretos a través del almacén del proveedor cloud (Secrets Manager o variables del contenedor).

---

## M. MIGRATION PHASES (Fases de Migración)

```
[FASE 0: Gobernanza] ──► [FASE 1: Seguridad] ──► [FASE 2: Backend] ──► [FASE 3: Flutter]
                                                                            │
[FASE 7: Observab.] ◄── [FASE 6: Nginx Proxy] ◄── [FASE 5: Redis State] ◄── [FASE 4: Docker]
```

### PHASE 0 — Governance & Freeze
*   **Objetivo**: Establecer los mecanismos de control del cambio y calidad del código.
*   **Duración**: 3 días.
*   **Entregable**: Configuración de reglas de Git en el repositorio, plantillas de ADRs (Architecture Decision Records) aprobadas y branch master congelado para cambios de infraestructura previos.
*   **Rollback**: No aplica.

### PHASE 1 — Security Hardening & Tenant Isolation
*   **Objetivo**: Garantizar la impenetrabilidad lógica de los datos entre gimnasios.
*   **Riesgo/Impacto**: Medio/Crítico.
*   **Duración**: 5 días.
*   **Entregables**: Middleware `tenantContext` funcionando y extensión `multiTenantExtension` de Prisma en producción.
*   **Rollback**: Comentar la extensión en `prisma.service.ts` y revertir al esquema de filtrado manual.

### PHASE 2 — Backend Stabilization & Idempotency
*   **Objetivo**: Estabilizar la API NestJS, agregando control de recursión en Logs de Auditoría e Idempotencia en cobros.
*   **Riesgo/Impacto**: Bajo/Alto.
*   **Duración**: 4 días.
*   **Entregables**: Interceptor de auditoría optimizado, y endpoints financieros validados.
*   **Rollback**: Revertir los interceptores modificados a las versiones anteriores utilizando Git.

### PHASE 3 — Flutter State Modularization
*   **Objetivo**: Dividir `gym_state.dart` en proveedores atómicos de Riverpod.
*   **Riesgo/Impacto**: Alto/Crítico.
*   **Duración**: 10 días.
*   **Entregables**: Aplicación compilando correctamente en modo release Web/Windows sin usar ChangeNotifier global masivo.
*   **Rollback**: Restaurar la rama de control del estado global móvil previa a la integración de Riverpod.

### PHASE 4 — Docker Productionization
*   **Objetivo**: Configurar imágenes multi-etapa y desplegar bases de datos persistentes sin riesgo de pérdida de información.
*   **Riesgo/Impacto**: Medio/Alto.
*   **Duración**: 3 días.
*   **Entregables**: Nuevo archivo `docker-compose.yml` y Dockerfile de backend optimizado.
*   **Rollback**: Volver a la versión previa del docker-compose y reiniciar contenedores antiguos.

### PHASE 5 — Redis Integration (Realtime & Cache)
*   **Objetivo**: Habilitar Redis para balancear la carga de WebSockets y manejar tokens de cobro duplicados.
*   **Riesgo/Impacto**: Bajo/Alto.
*   **Duración**: 4 días.
*   **Entregables**: Redis activo y WebSocket Adapter migrado correctamente.
*   **Rollback**: Deshabilitar el adaptador Redis en `main.ts` y restaurar el adaptador local.

### PHASE 6 — Nginx Reverse Proxy & TLS Configuration
*   **Objetivo**: Centralizar las conexiones en HTTPS (puerto 443) y configurar reglas de enrutamiento proxy unificadas.
*   **Riesgo/Impacto**: Bajo/Alto.
*   **Duración**: 3 días.
*   **Entregables**: Contenedor Nginx operando con certificados de seguridad.
*   **Rollback**: Re-exponer los puertos `3000` y `8383` temporalmente de forma pública si falla el ruteo de Nginx.

### PHASE 7 — Observability Implementation
*   **Objetivo**: Monitorear y registrar el comportamiento del sistema de producción.
*   **Riesgo/Impacto**: Bajo/Medio.
*   **Duración**: 3 días.
*   **Entregables**: Logs JSON en backend y endpoint de healthcheck operativo.
*   **Rollback**: Comentar los interceptores de logging estructurado.

---

## N. ROLLBACK STRATEGY (Plan de Contingencia)

En caso de incidentes críticos durante el despliegue de las fases de migración, se ejecutarán los siguientes procedimientos de contingencia:

1.  **Base de Datos (PostgreSQL)**:
    *   *Acción*: En caso de fallo tras ejecutar `prisma migrate deploy`, no realizar migraciones hacia atrás (*downgrade*) de forma automática en producción.
    *   *Procedimiento*: Restaurar la última copia de seguridad automática tomada previa al despliegue, montándola en un volumen limpio.
2.  **Despliegue del Backend (API)**:
    *   *Acción*: Fallos de compilación de contenedores o caídas súbitas en tiempo de ejecución.
    *   *Procedimiento*: Mantener la versión anterior de la imagen del contenedor etiquetada como `:rollback` en el registro. Ejecutar `docker compose set-image` a la versión previa de manera inmediata.
3.  **Aplicación Móvil (Flutter)**:
    *   *Acción*: Crashes en producción tras la fragmentación de estados de Riverpod.
    *   *Procedimiento*: En la versión Web, vaciar la caché de Nginx para forzar la carga de la versión anterior. En la versión Windows/Móvil, desplegar de inmediato un Hotfix revertiendo los cambios de Riverpod en la rama paralela `hotfix/vX.Y.Z-rollback`.

---

## O. GOVERNANCE RULES (Gobernanza Técnica)

*   **Definition of Done (DoD) para PRs**:
    *   El código debe pasar `npm run lint` o `flutter analyze` sin advertencias críticas.
    *   Todo cambio en base de datos debe estar documentado en un archivo migration SQL de Prisma.
    *   Cualquier endpoint nuevo debe verificar multi-tenancy usando la extensión automatizada de Prisma o, en su defecto, poseer una justificación documentada de por qué es transversal (ej. Super Admin).
*   **Branching Model**:
    *   `main`: Producción, estable, código desplegado en contenedores de producción.
    *   `staging`: Entorno de validación y QA.
    *   `feature/*` / `bugfix/*`: Ramas de desarrollo temporal que requieren aprobación de Reviewers antes de unificarse.

---

## P. RECOMMENDED FINAL REPOSITORY STRUCTURE

Mapa detallado del repositorio una vez completadas las fases de reorganización:

```
sas_gym/
├── .env.example
├── docker-compose.yml
├── docker-compose.dev.yml
│
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── prisma/
│   │   ├── schema.prisma
│   │   ├── migrations/
│   │   └── seed.ts
│   └── src/
│       ├── main.ts
│       ├── app.module.ts
│       ├── core/
│       │   ├── decorators/
│       │   ├── gateways/
│       │   │   └── saas.gateway.ts
│       │   ├── guards/
│       │   │   ├── auth.guard.ts
│       │   │   ├── roles.guard.ts
│       │   │   └── tenant.guard.ts
│       │   └── interceptors/
│       │       ├── audit.interceptor.ts
│       │       └── idempotency.interceptor.ts
│       ├── prisma/
│       │   ├── prisma.service.ts
│       │   └── extensions/
│       │       └── multi-tenant.extension.ts
│       └── modules/
│           ├── auth/
│           ├── members/
│           ├── payments/
│           ├── attendance/
│           └── ...
│
├── mobile_app/
│   ├── Dockerfile
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── app.dart
│       ├── core/
│       │   ├── network/
│       │   │   └── api_client.dart
│       │   ├── storage/
│       │   │   └── secure_storage.dart
│       │   └── theme/
│       │       └── app_theme.dart
│       ├── features/
│       │   ├── auth/
│       │   │   ├── auth_provider.dart
│       │   │   └── login_screen.dart
│       │   ├── cashier/
│       │   │   ├── cashier_provider.dart
│       │   │   └── cashier_screen.dart
│       │   └── ...
│       ├── models/
│       │   └── gym_models.dart
│       └── widgets/
│           └── app_shell.dart
│
├── mockups/
│   ├── mobile/
│   └── web/
│
└── infra/
    ├── nginx/
    │   ├── nginx.conf
    │   └── ssl/
    └── redis/
        └── redis.conf
```

---

## Q. INFORME DE MIGRACIÓN DE LIBRERÍAS (UPGRADE REPORT)

Se ha realizado una auditoría exhaustiva de versiones de todas las dependencias del backend (Node.js/NestJS) y del frontend móvil (Flutter), ejecutando exitosamente la descarga e instalación local de los paquetes compatibles más recientes para erradicar brechas de seguridad y optimizar el rendimiento.

A continuación se detalla la correspondencia de versiones:

### 1. Dependencias Backend (NestJS / Prisma)

*   **@eslint/js**
    *   Librería Usada: `9.39.4`
    *   Librería Actual: `10.0.1` (Definido como `^10.0.1`)
*   **@nestjs/common**
    *   Librería Usada: `11.1.23`
    *   Librería Actual: `11.1.24` (Definido como `^11.1.24`)
*   **@nestjs/core**
    *   Librería Usada: `11.1.23`
    *   Librería Actual: `11.1.24` (Definido como `^11.1.24`)
*   **@nestjs/platform-express**
    *   Librería Usada: `11.1.23`
    *   Librería Actual: `11.1.24` (Definido como `^11.1.24`)
*   **@nestjs/websockets**
    *   Librería Usada: `11.1.23`
    *   Librería Actual: `11.1.24` (Definido como `^11.1.24`)
*   **@nestjs/platform-socket.io**
    *   Librería Usada: `11.1.23`
    *   Librería Actual: `11.1.24` (Definido como `^11.1.24`)
*   **@nestjs/testing**
    *   Librería Usada: `11.1.23`
    *   Librería Actual: `11.1.24` (Definido como `^11.1.24`)
*   **@prisma/client**
    *   Librería Usada: `5.14.0`
    *   Librería Actual: `7.8.0` (Definido como `^7.8.0`)
*   **prisma**
    *   Librería Usada: `5.14.0`
    *   Librería Actual: `7.8.0` (Definido como `^7.8.0`)
*   **otplib**
    *   Librería Usada: `12.0.1`
    *   Librería Actual: `13.4.0` (Definido como `^13.4.0`)
*   **@types/multer**
    *   Librería Usada: `1.4.13`
    *   Librería Actual: `2.1.0` (Definido como `^2.1.0`)
*   **@types/node**
    *   Librería Usada: `24.12.4`
    *   Librería Actual: `25.9.1` (Definido como `^25.9.1`)
*   **eslint**
    *   Librería Usada: `9.39.4`
    *   Librería Actual: `10.4.0` (Definido como `^10.4.0`)
*   **eslint-plugin-prettier**
    *   Librería Usada: `5.5.5`
    *   Librería Actual: `5.5.6` (Definido como `^5.5.6`)
*   **typescript**
    *   Librería Usada: `5.9.3`
    *   Librería Actual: `6.0.3` (Definido como `^6.0.3`)
*   **typescript-eslint**
    *   Librería Usada: `8.59.4`
    *   Librería Actual: `8.60.0` (Definido como `^8.60.0`)

### 2. Dependencias Frontend (Flutter)

*   **connectivity_plus**
    *   Librería Usada: `6.1.5`
    *   Librería Actual: `7.1.1` (Definido como `^7.1.1`)
*   **file_picker**
    *   Librería Usada: `8.3.7`
    *   Librería Actual: `11.0.2` (Definido como `^11.0.2`)
*   **flutter_secure_storage**
    *   Librería Usada: `9.2.4`
    *   Librería Actual: `10.3.1` (Definido como `^10.3.1`)
*   **image**
    *   Librería Usada: `4.8.0`
    *   Librería Actual: `4.8.0` (Mantenida en `^4.8.0` para evitar conflicto de versionado en la dependencia transitiva `meta: 1.18.0` exigida por el SDK de Flutter actual)

---

## R. DIRECTIVA DE EJECUCIÓN Y PRUEBAS EN CONTENEDORES

Se establece explícitamente como estándar del proyecto que **todas las ejecuciones de servicio, procesos de prueba unitaria, testing relacional y simulaciones del entorno se deben realizar bajo el despliegue contenerizado (Docker Compose)**. 

No se permite la ejecución nativa en la máquina host para pruebas de integración o de ejecución regular de la aplicación, garantizando que el comportamiento del runtime (versiones de Node, empaquetado Prisma, red interna aislada y persistencia) sea 100% equivalente al de producción y mitigando discrepancias de dependencias del sistema operativo.