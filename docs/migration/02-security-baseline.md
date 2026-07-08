# docs/migration/02-security-baseline.md — Línea Base de Seguridad y Aislamiento

Este documento detalla el estado actual de la seguridad en el backend y los componentes del ecosistema SASGYM, identificando los flujos vulnerables, la mitigación de ataques y los mecanismos de autorización multitenant.

---

## 1. Autenticación y Flujo de Sesión JWT

### Diseño de Tokens
*   **Access Token:** Token JWT de vida corta (15 minutos por defecto, configurable vía `JWT_ACCESS_TTL`). Almacena de forma encriptada:
    *   `sub`: ID único del usuario.
    *   `email`: Correo del usuario.
    *   `rol`: Rol del usuario (Member, Trainer, Cashier, Admin, Superadmin).
    *   `tenantId`: Identificador del Tenant para control de multi-tenancy.
    *   `tokenType`: Fijo en `'access'`.
*   **Refresh Token:** Token aleatorio de 48 bytes generado de forma segura en formato `base64url`.
    *   *Almacenamiento:* El hash SHA-256 del refresh token se persiste en la tabla `RefreshTokenSession` en PostgreSQL junto con metadatos de IP (`ip_address`), User Agent (`user_agent`), estado de revocación y fecha de vencimiento (`expires_at` de 7 días por defecto).
    *   *Rotación:* Al renovar la sesión mediante `/auth/refresh`, el refresh token usado se revoca de forma inmediata (`revoked_at` = fecha actual) y se emite una nueva sesión con un nuevo refresh token, impidiendo ataques de replay de sesión.

---

## 2. Multi-tenancy y Aislamiento de Datos

El aislamiento de los datos se realiza a nivel lógico compartiendo esquema y filtrando por la columna `tenant_id` por fila.

### Reglas de Aislamiento Críticas
1.  **Aislamiento en API:**
    *   El `tenantId` NUNCA se confía del payload de la petición (body o query params) si se trata de un usuario autenticado. Se deriva estrictamente del payload del JWT decodificado en `req.user.tenantId` por los guards de NestJS.
    *   Todos los servicios de NestJS deben inyectar este `tenantId` en las cláusulas `where` de Prisma para aislar la consulta al tenant correspondiente.
2.  **Aislamiento en WebSockets:**
    *   El WebSocket Gateway [SaasGateway](file:///d:/proyectos/sas_gym/backend/src/core/gateways/saas.gateway.ts) autentica el token JWT enviado en el handshake.
    *   Al unirse a una sala (`join`), el cliente es suscrito únicamente a la sala correspondiente a su `tenantId` derivado del payload verificado. Los eventos en tiempo real se dirigen exclusivamente a la sala `this.server.to(tenantId)`, lo que impide fugas de datos entre inquilinos.

---

## 3. Rate Limiting y Protección de Fuerza Bruta

El sistema cuenta con un esquema de protección dual:
1.  **RateLimitingGuard (NestJS):**
    *   Guard global que utiliza Redis para persistir contadores de intentos de inicio de sesión por IP (`rate:fail:ip:<ip>`) y por email (`rate:fail:email:<email>`).
    *   Aplica un bloqueo temporal (`rate:block:ip:<ip>`) de 15 minutos tras 5 intentos fallidos consecutivos en la ruta de login.
2.  **securityBlockMiddleware (main.ts - Deuda Técnica a Corregir):**
    *   Un middleware global en Express que protege el servidor ante fallos repetidos (401/403) bloqueando IPs tras 10 intentos en una ventana de 5 minutos.
    *   *Problema:* Actualmente guarda el estado en `Map` locales en memoria. Esto consume memoria y no es distribuido.
    *   *Mitigación (Fase 6):* Migrar este middleware para que resuelva `RedisService` dinámicamente y persista el estado de bloqueo con TTL en Redis usando la llave `rate:block:global:ip:<ip>`.

---

## 4. Validación de Acceso por QR y TOTP (2FA)

*   Cada miembro tiene asignada una clave secreta única (`qr_secret`) codificada en base32 persistida en la base de datos al momento del registro.
*   **Código QR Dinámico:** La aplicación móvil genera cada 30 segundos un código TOTP basado en el algoritmo estándar HMAC-SHA1 usando el `qr_secret`.
*   **Validación de Torniquetes (Backend):**
    *   El torniquete o lector envía el DNI y el código OTP escaneado.
    *   El servicio de asistencia [AttendanceService](file:///d:/proyectos/sas_gym/backend/src/modules/attendance/attendance.service.ts) recupera el `qr_secret` del socio, valida el token mediante `otplib.totp.check()` con una tolerancia de ventana de ±1 paso (30 segundos).
    *   *Anti-Replay:* El token usado se registra temporalmente en memoria por 95 segundos (`usedTokens` Set) para impedir que el mismo QR sea escaneado varias veces dentro del mismo periodo de validez.

---

## 5. Almacenamiento en S3 y URLs Prefirmadas

*   Para evitar la exposición directa de objetos de fotos de perfil u hojas de dietas/rutinas, el bucket de AWS S3 o MinIO se configura en modo 100% privado.
*   **Generación de URLs:** El backend valida el rol y pertenencia del usuario solicitante al tenant, y genera una URL prefirmada temporal con tiempo de vida corto (ejemplo: 15 minutos) a través de `@aws-sdk/s3-request-presigner`.
*   Los nombres de los archivos se renombran de manera única (UUIDs) para evitar path traversal o enumeración de archivos en la URL del almacenamiento.
