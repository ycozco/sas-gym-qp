# docs/migration/03-graphify-baseline.md — Análisis de Grafo y Línea Base de Graphify

Este documento consolida el análisis estructural inicial del repositorio SASGYM realizado con la herramienta local **Graphify**, detallando las dependencias, flujos y relaciones críticas extraídas directamente de las declaraciones del código.

---

## 1. Evidencias de Consultas Realizadas en el Grafo

A partir de la ejecución de `graphify update` y consultas locales al grafo, se extraen las siguientes respuestas estructurales:

### 📑 A. ¿Qué componentes dependen directa o indirectamente de `GymState`?
*   **Origen:** [gym_state.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/data/gym_state.dart) es un `ChangeNotifier` que actúa como el monolito de estado de la aplicación Flutter.
*   **Resultados de búsqueda en Grafo (348 nodos encontrados):**
    *   *Bootstrap de la App:* [main.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/main.dart) inicializa el `GymStateProvider` envolviendo todo el árbol de widgets.
    *   *Vistas y Pantallas Móviles:*
        *   [trainer_screen.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/trainer/screens/trainer_screen.dart) (pantalla del entrenador).
        *   [cashier_home_page.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/cashier/widgets/cashier_home_page.dart) (consola del cajero).
        *   [admin_caja_audit_page.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/admin/widgets/admin_caja_audit_page.dart) (auditoría de caja).
        *   [member_home_page.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/member/widgets/member_home_page.dart) (pantalla principal del socio).
        *   [login_screen.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/auth/screens/login_screen.dart) (pantalla de autenticación).
    *   *Widgets de Dominio:*
        *   [full_qr_view.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/member/widgets/full_qr_view.dart) (pantalla de QR).
        *   [pay_membership_view.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/member/widgets/pay_membership_view.dart) (pasarela de pagos local).
        *   [caja_dialogs.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/cashier/widgets/caja_dialogs.dart) (apertura y arqueo de caja).
    *   *Pruebas de Smoke:* Suite de pruebas completa en `test/smoke/*` (`role_routing_test.dart`, `app_boot_test.dart`, `mobile_security_flags_test.dart`) instancian y configuran `GymState` para simular estados.

### 🔌 B. ¿Cómo se conecta la aplicación Flutter con el backend?
*   **Cliente Base:** La conexión se centraliza a través del cliente HTTP [api_client.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/core/network/api_client.dart).
*   **Dependencia en Grafo:**
    *   [api_client.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/core/network/api_client.dart) utiliza el paquete de red `dio` (`package:dio/dio.dart`).
    *   `GymState` importa y mantiene una instancia persistente de `ApiClient` para despachar todas las llamadas a endpoints (`/auth/login`, `/attendance/verify`, `/payments`, `/routines`, etc.).
    *   El token de autenticación (JWT) obtenido tras el login exitoso se guarda en `SecureStorage` y se inyecta en la cabecera `Authorization: Bearer <token>` de cada petición HTTP saliente.

### 🔑 C. ¿Qué componentes participan en autenticación, JWT, refresh tokens y TOTP?
*   **Backend NestJS:**
    *   [auth.controller.ts](file:///d:/proyectos/sas_gym/backend/src/modules/auth/auth.controller.ts) y [auth.service.ts](file:///d:/proyectos/sas_gym/backend/src/modules/auth/auth.service.ts) exponen `/auth/login` y `/auth/refresh`.
    *   [PrismaService](file:///d:/proyectos/sas_gym/backend/src/prisma/prisma.service.ts) interactúa con las tablas `User` y `RefreshTokenSession` para verificar credenciales y sesiones.
    *   [AttendanceService](file:///d:/proyectos/sas_gym/backend/src/modules/attendance/attendance.service.ts) importa `totp` de `otplib` para la validación del código QR de acceso.
*   **Cliente Móvil (Flutter):**
    *   [login_screen.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/features/auth/screens/login_screen.dart) colecta credenciales y llama al método `login` de `GymState`.
    *   `secure_storage.dart` almacena el token JWT.
    *   `otp` de `pubspec.yaml` calcula el código TOTP dinámico en local usando la clave secreta del usuario.

### 📡 D. ¿Qué conecta Socket.IO con Redis y el flujo de asistencia?
*   **Backend NestJS:**
    *   [saas.gateway.ts](file:///d:/proyectos/sas_gym/backend/src/core/gateways/saas.gateway.ts) define el `@WebSocketGateway` para interactuar en tiempo real con Socket.IO.
    *   El servicio de asistencia [AttendanceService](file:///d:/proyectos/sas_gym/backend/src/modules/attendance/attendance.service.ts) despacha eventos de check-in (`attendance_registered`) en tiempo real al administrador de la sala del tenant respectivo en el gateway.
    *   El gateway usa `PrismaService` y `RedisService` como mecanismo PubSub e intercomunicación distribuida.

### 🏢 E. ¿Cómo se determina el tenant o gimnasio en cada solicitud?
*   **Filtro HTTP (NestJS):**
    *   Se utiliza el interceptor/guard personalizado `TenantGuard` (o lógica de filtro similar).
    *   En usuarios autenticados, el guard decodifica la cabecera JWT y extrae `req.user.tenantId`.
    *   Para peticiones públicas (por ejemplo, registro de nuevos socios), se utiliza la cabecera `X-Tenant-ID`.
    *   El `tenantId` derivado se inyecta en las consultas de Prisma a través del controlador para restringir las transacciones al alcance exclusivo de dicho inquilino.

---

## 2. Tratamiento de Confianza del Grafo
A partir de la inspección de relaciones del reporte de Graphify:
1.  **Relaciones EXTRACTED (Evidencia Primaria):**
    *   `GymState --calls--> ApiClient` (Extraído: llamadas directas HTTP de red).
    *   `AppModule --imports--> CoreServicesModule` (Extraído: inyección de servicios comunes).
2.  **Relaciones INFERRED (Verificadas en Código):**
    *   `AdminApp() --calls--> useRouter()` (Inferencia del mockup).
    *   `wWinMain() --calls--> CreateAndAttachConsole()` (Inferencia de inicialización de Windows runner).
3.  **Relaciones AMBIGUOUS (Descartadas de Acción Directa):**
    *   Ninguna detectada con criticidad en el bootstrap principal.
