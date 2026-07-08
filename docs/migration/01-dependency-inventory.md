# docs/migration/01-dependency-inventory.md — Inventario de Dependencias del Ecosistema

Este documento detalla el inventario tecnológico completo de SASGYM extraído de los archivos de manifiesto ([package.json](file:///d:/proyectos/sas_gym/backend/package.json), [pubspec.yaml](file:///d:/proyectos/sas_gym/mobile_app/pubspec.yaml)), Dockerfiles y archivos compose.

---

## 1. Backend API (NestJS + Prisma)

### Lenguajes y Runtimes
*   **Runtime:** Node.js v20 (Dockerfile base: `node:20-alpine`) -> *Objetivo de migración: Node.js v24 LTS*.
*   **Lenguaje:** TypeScript `v6.0.3` (tsconfig target: ES2022).

### Framework y Dependencias Principales (package.json)
| Dependencia | Versión Declarada | Uso en Proyecto |
| :--- | :--- | :--- |
| `@nestjs/common` | `^11.1.24` | Módulo base NestJS |
| `@nestjs/core` | `^11.1.24` | Núcleo del framework |
| `@nestjs/platform-express` | `^11.1.24` | Servidor HTTP HTTP subyacente |
| `@nestjs/platform-socket.io` | `^11.1.24` | Integración WebSocket Gateway |
| `@nestjs/websockets` | `^11.1.24` | Gateways bidireccionales |
| `@nestjs/jwt` | `^11.0.2` | Emisión y validación de tokens JWT |
| `@nestjs/throttler` | `^6.5.0` | Limitador de peticiones (Rate Limit) |
| `@prisma/client` | `^6.19.3` | ORM - Generador de consultas Postgres |
| `ioredis` | `^5.11.1` | Cliente para base de datos Redis |
| `otplib` | `^12.0.1` | Autenticación TOTP 2FA (QR de accesos) -> *Objetivo: ^13.0.0* |
| `bcryptjs` | `^3.0.3` | Hashing seguro de contraseñas |
| `helmet` | `^8.2.0` | Cabeceras HTTP de seguridad |
| `class-validator` | `^0.15.1` | Validación estructural de DTOs |
| `class-transformer` | `^0.5.1` | Transformación de DTOs y serialización |
| `@aws-sdk/client-s3` | `^3.1068.0` | Carga de archivos y fotos a AWS S3 / MinIO |
| `@aws-sdk/s3-request-presigner`| `^3.1068.0` | Generador de URLs prefirmadas de S3 |
| `rxjs` | `^7.8.1` | Librería reactiva NestJS |

### Dependencias de Desarrollo (devDependencies)
| Dependencia | Versión Declarada | Uso en Proyecto |
| :--- | :--- | :--- |
| `prisma` | `^6.19.3` | CLI y generador de migraciones del ORM |
| `jest` | `^30.0.0` | Framework de pruebas |
| `ts-jest` | `^29.2.5` | Transformador TS para Jest |
| `typescript` | `^6.0.3` | Compilador TypeScript |

---

## 2. Aplicación Móvil (Flutter / Dart)

### Runtimes y SDKs
*   **Flutter SDK:** `>=3.44.0` (imagen docker `ghcr.io/cirruslabs/flutter:3.44.0`).
*   **Dart SDK:** `^3.12.0` (indicado en pubspec).

### Dependencias de la Aplicación (pubspec.yaml)
| Dependencia | Versión Declarada | Uso en Proyecto |
| :--- | :--- | :--- |
| `flutter_riverpod` | `^2.5.1` | Gestor de estado modular reactivo (Fase 5) |
| `dio` | `^5.7.0` | Cliente de peticiones HTTP/REST a la API |
| `flutter_secure_storage` | `^10.3.1` | Almacenamiento seguro del token JWT de sesión |
| `hive` | `^2.2.3` | Motor NoSQL local rápido para caché offline |
| `hive_flutter` | `^1.1.0` | Enlaces UI para Hive local |
| `socket_io_client` | `^3.1.5` | Suscripción WebSocket para alertas de check-in |
| `otp` | `^3.1.2` | Generador de TOTP para el código QR dinámico |
| `qr_flutter` | `^4.1.0` | Renderizador visual del código QR |
| `image` | `^4.9.1` | Compresión y manipulación de imágenes |
| `image_picker` | `^1.2.2` | Selección de imágenes de perfil desde cámara/galería |
| `connectivity_plus` | `^7.1.1` | Detección del estado de red |
| `google_fonts` | `^8.1.0` | Fuentes personalizadas (Outfit, Inter) |
| `cupertino_icons` | `^1.0.8` | Iconos de estilo iOS |

---

## 3. Panel Administrativo Web (`web_admin`)

Actualmente no está contenerizado formalmente ni empaquetado. Sus dependencias son en tiempo de ejecución cargadas vía CDN:

| Recurso | Versión Cargada | Origen | Uso en Proyecto |
| :--- | :--- | :--- | :--- |
| `react` | `18.3.1` | unpkg.com | Librería de componentes reactivos |
| `react-dom` | `18.3.1` | unpkg.com | Renderizador React en el DOM |
| `@babel/standalone`| `7.29.0` | unpkg.com | Compilador JSX en tiempo de ejecución |

*   **Objetivo de migración (Fase 4):**
    *   `react` y `react-dom` `^18.3.1` instalados localmente.
    *   `vite` `^6.0.0` y `@vitejs/plugin-react` `^4.0.0` como herramientas de construcción.
    *   `socket.io-client` `^4.8.0` instalado localmente.
    *   Eliminación completa de llamadas a Babel Standalone y CDNs.

---

## 4. Contenedores e Infraestructura

*   **Base de datos:** `postgres:16-alpine` (PostgreSQL v16).
*   **Caché:** `redis:7-alpine` (Redis v7).
*   **Servidor Web (Admin):** `nginx:alpine` (Nginx para servir archivos estáticos plano).
*   **Redes locales:** `sasgym_backend_local` (bridge), `sasgym_public_local` (bridge).
*   **Red productiva de proxy:** Red externa vinculada a Nginx Proxy Manager mediante la variable `${EXTERNAL_PROXY_NETWORK}`.
