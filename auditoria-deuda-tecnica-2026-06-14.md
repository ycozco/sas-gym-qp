# Auditoría de Deuda Técnica e Implementación de Arquitectura — SAS GYM
**Fecha:** 2026-06-14  
**Responsable:** Antigravity (Advanced Agentic Coding Partner)  
**Estado del Plan:** Parcialmente completado (Pendientes identificados en dependencias backend y desmantelamiento de estado móvil)

Este informe audita el estado actual del repositorio frente al **Plan de Implementación Detallado** y el archivo **pendiente.md** de **SAS GYM**, identificando los entregables faltantes y trazando la ruta inmediata de implementación.

---

## 📊 Resumen Ejecutivo del Estado del Proyecto

| Área / Fase | Estado | Entregables Encontrados | Brechas / Pendientes Detectados |
| :--- | :---: | :--- | :--- |
| **Fase 1: Infraestructura y DB** | **100%** | `docker-compose.dev.yml`, `docker-compose.prod.yml`, `schema.prisma` normalizado con `MembershipFreeze` y relaciones `tenant_id`. | Ninguno. |
| **Fase 2: Seguridad y Rate Limiting** | **90%** | `redis.service.ts`, `rate-limiting.guard.ts` con ioredis y bloqueo temporal por IP/Usuario. | La librería `otplib` sigue en `12.0.1`. Debe actualizarse a `13.x`. |
| **Fase 3: Idempotencia y Paginación** | **100%** | `idempotency.interceptor.ts` con Redis, paginación por cursor en `members` y logs. | Ninguno. |
| **Fase 4: Almacenamiento Seguro S3** | **100%** | `file-validator.service.ts` (magic bytes) y `s3-storage.service.ts` (AWS SDK presigned URLs). | Ninguno. |
| **Fase 5: Desacoplamiento y Flutter** | **50%** | `ios/Podfile` y configuraciones nativas de firmado. `diet_provider.dart` y `routine_provider.dart` en Riverpod. | **Monolito de estado:** `gym_state.dart` sigue existiendo como ChangeNotifier de ~2900 líneas y no ha sido segregado en `AuthProvider`, `BillingProvider`, `SchedulesProvider`, `PointsProvider`. |
| **Fase 6: Gateway IoT Biométrico** | **100%** | Sockets de entrada/salida y handshake biométrico (SHA-256) en `saas.gateway.ts`. | Ninguno. |
| **Fase 7/8/9: Puntos y Planes** | **100%** | Sincronización real de puntos, CRUD de planes SaaS, calculadora macros Mifflin-St Jeor en móvil. | Ninguno. |

---

## 🔍 Detalles de las Brechas y Gaps Técnicos

### 1. Dependencias y Versiones del Backend (Brecha de Fase 2)
* **Prisma ORM:** Actualmente en `6.19.3`. La hoja de ruta exige la migración a la versión `7.x` (estable `7.8.0` en producción) adaptando el formato de configuración mediante `prisma.config.ts` y eliminando la carga de variables automáticas por la CLI.
* **Otplib (2FA):** Actualmente en `12.0.1`. Debe ser actualizada a la versión `13.x` asegurando la compatibilidad de firmas HMAC y la generación segura de tokens en `attendance.service.ts`.

### 2. Estado Monolítico en la App Móvil (Brecha de Fase 5)
* El archivo `lib/data/gym_state.dart` concentra toda la lógica de negocio (Autenticación, Facturación, Gestión de Sede, Clases Grupales, etc.). Aunque se crearon `diet_provider.dart` y `routine_provider.dart`, la clase `GymState` sigue siendo un ChangeNotifier gigante de 88KB.
* **Acción requerida:** Desmantelar `GymState` extrayendo las siguientes features en proveedores inmutables de Riverpod:
  * `AuthProvider` (Manejo de Login, Sesión y token seguro).
  * `PointsProvider` (Puntos de fidelización e historial).
  * `SchedulesProvider` (Listado y reserva de clases grupales).
  * `BillingProvider` (Membresías, pagos y comprobantes).

---

## 🛠️ Plan de Acción Inmediato (Paso a Paso)

### Paso 1: Actualización de Dependencias Backend
1. Actualizar `package.json` de la API para usar:
   * `"prisma": "^7.8.0"` y `"@prisma/client": "^7.8.0"`
   * `"otplib": "^13.0.0"` (o versión estable correspondiente).
2. Crear `backend/prisma.config.ts` o la configuración requerida por Prisma 7.
3. Levantar contenedores y correr `npm install` en el contenedor `api`.
4. Correr la suite de pruebas unitarias de backend para certificar compatibilidad de `otplib` y del cliente Prisma.

### Paso 2: Desmantelamiento de GymState en Flutter
1. Diseñar e implementar `AuthProvider`, `PointsProvider`, `SchedulesProvider`, `BillingProvider` usando `StateNotifier` o `Notifier` de Riverpod.
2. Refactorizar las pantallas y widgets correspondientes (como login, perfil, reservas, pagos) para consumir los nuevos proveedores reactivos de Riverpod, reduciendo el acoplamiento a `GymState`.
3. Validar la compilación e integración del pipeline móvil.
