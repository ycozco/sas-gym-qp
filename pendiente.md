# Listado de Pendientes y Hoja de Ruta — SaaaS GYM

Este documento consolida las tareas y mejoras pendientes necesarias para llevar el ecosistema **SaaaS GYM** a un estado 100% productivo, seguro y de alta disponibilidad.

---

## 🐳 1. Infraestructura y Docker (Producción)

- [ ] **Segregación de Manifiestos Docker Compose**:
  - [ ] Crear `docker-compose.dev.yml` que incorpore montajes en vivo (`bind mounts`), volúmenes anónimos para dependencias de Node, y soporte para `docker compose watch`.
  - [ ] Crear `docker-compose.prod.yml` que prescinda de montajes, configure las variables en modo producción (`NODE_ENV=production`) y use la compilación limpia de [Dockerfile.prod](file:///d:/proyectos/sas_gym/backend/Dockerfile.prod).
- [ ] **Restricción de Recursos de RAM y CPU**:
  - [ ] Definir bloques `deploy.resources.limits` (ej. `memory: 1024M`, `cpus: '1.0'`) y `reservations` en `docker-compose.prod.yml`.
  - [ ] Configurar la variable de entorno `NODE_OPTIONS=--max-old-space-size=768` en el contenedor de NestJS para optimizar el recolector de basura del motor V8.
- [ ] **Integración de Migraciones en CI/CD**:
  - [ ] Reemplazar la ejecución de `npx prisma db push` en el script de arranque por `npx prisma migrate deploy` para asegurar transiciones de esquema sin pérdida de datos en producción.

---

## 🔒 2. Seguridad y Backend (NestJS + Prisma)

- [ ] **Bloqueo de IPs Distribuido (Redis)**:
  - [ ] Reemplazar el middleware in-memory actual que almacena intentos de login fallidos por un adaptador basado en **Redis** (`ioredis`) para permitir el escalado horizontal de réplicas NestJS detrás de un proxy.
- [ ] **Actualización del ORM y dependencias**:
  - [ ] Migrar Prisma de `6.x` a `7.x` adaptando el formato de configuración a `prisma.config.ts`.
  - [ ] Actualizar la librería `otplib` (2FA/TOTP) a la versión `13.x` y certificar compatibilidad del algoritmo HMAC de los códigos de acceso para miembros.
- [ ] **Paginación Basada en Cursor (Cursor-Based)**:
  - [ ] Modificar los endpoints de auditoría en `reports.service.ts` y listados de socios en `members.service.ts` para usar paginación por cursor en lugar de offset.
- [ ] **Seguridad de Archivos (Uploads)**:
  - [ ] Conectar el validador binario `FileValidatorService` a los endpoints de subida para verificar firmas binarias (*magic bytes*) de recibos e imágenes incidentales.
  - [ ] Retirar almacenamiento en disco local del servidor y migrar la subida hacia servicios S3-compatible (ej. AWS S3, Cloudflare R2) con URLs firmadas temporalmente.
- [ ] **Idempotencia Financiera en API**:
  - [ ] Implementar el interceptor `idempotency.interceptor.ts` usando Redis para cachear temporalmente solicitudes de cobros de caja/POS que contengan la cabecera `Idempotency-Key`.

---

## 📱 3. Aplicación Móvil (Flutter / Dart)

- [ ] **Refactorización de Estado (Migración a Riverpod)**:
  - [ ] Desmantelar la clase monolítica `GymState` (ChangeNotifier) y dividir la lógica en proveedores independientes (`AuthProvider`, `RoutineProvider`, `BillingProvider`, `SchedulesProvider`, `PointsProvider`) del paquete `flutter_riverpod`.
- [ ] **Desacoplamiento Estricto de Capas**:
  - [ ] Limpiar los archivos en `lib/models/domain/` removiendo cualquier importación a librerías visuales (`material.dart`, clases de `Color`, `IconData` o `Gradient`), garantizando DTOs puros testeables en unit tests aislados.
- [ ] **Manejo de Reintentos e Idempotencia**:
  - [ ] Asegurar que la cola de sincronización fuera de línea (`sync_queue_box`) anexe llaves de idempotencia únicas a peticiones en tránsito financiero.
  - [ ] Implementar límites de reintentos (*max retries*) y tiempo de vida útil (TTL) para elementos encolados pendientes de red.
- [ ] **Distribución y Firmado (Android)**:
  - [ ] Configurar variables de firmado seguro (`key.properties`) y Keystores release fuera del control de versiones.
  - [ ] Definir identificadores de paquete finales (`applicationId = com.sasgym.app`) diferenciados por ambiente (dev, staging, prod).

---

## 🎛️ 4. Integración de Hardware y Control de Acceso (IoT)

- [ ] **Gateway WebSockets de Torniquetes**:
  - [ ] Extender el gateway Socket.io en `SaaSGateway` para manejar la recepción de eventos de lectura de huellas digitales de dispositivos IoT.
  - [ ] Validar los payloads binarios mediante decoradores de `class-validator` en `biometric-handshake.dto.ts`.
  - [ ] Implementar el canal de eventos reactivos para instruir al hardware físico la apertura de la compuerta (`OPEN_GATE`).
