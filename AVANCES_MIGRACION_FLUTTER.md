# Registro de Avances: Migración y Calidad de Código en Flutter

Este documento detalla y fecha el nuevo avance en la portabilidad de los mockups detallados del prototipo `sas_Gym_high` (React) a la aplicación nativa en Flutter (`flutter_app`), asegurando la trazabilidad con los requerimientos funcionales (RF) y no funcionales (RNF).

---

## 📅 Información del Avance
- **Fecha de Registro**: 21 de Mayo de 2026 (23:17 Local Time)
- **Autor**: Antigravity AI Pair Programmer
- **Estado de Compilación**: 100% Exitoso (`No issues found!`)
- **Herramientas de Validación**: `flutter analyze`

---

## 🛠️ Detalle de Archivos Modificados y Refactorizaciones

A continuación se detalla la matriz de cambios técnicos aplicados sobre la base de código de Flutter para erradicar las advertencias estáticas e implementar soluciones de interfaz alineadas con el diseño premium:

| Archivo Modificado | Tipo de Cambio | Advertencias Resueltas | Detalle de la Implementación |
|---|---|---|---|
| [`lib/screens/member_screen.dart`](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/member_screen.dart) | Refactorización Visual y Técnica | `deprecated_member_use`, `unused_local_variable`, `use_build_context_synchronously` | 1. Se eliminaron variables sin usar (`state` y `params`).<br>2. Se migró `activeColor` a `activeThumbColor` en el Switch de visibilidad social.<br>3. Se resolvió la brecha asincrónica de `BuildContext` al capturar `ScaffoldMessengerState` en una variable local previo al retardo de simulación.<br>4. Se sustituyó el control obsoleto y genérico `RadioListTile` por tarjetas táctiles personalizadas (`Card` + `InkWell` + selector de estado circular). |
| [`lib/screens/trainer_screen.dart`](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/trainer_screen.dart) | Limpieza de Código | `unused_import`, `dead_code` | 1. Se removió el import inactivo de `dart:async`.<br>2. Se eliminó la variable local no utilizada `hideNav` y el bloque condicional muerto derivado de ella, simplificando la función de renderizado de la pila de historial. |
| [`lib/screens/cashier_screen.dart`](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/cashier_screen.dart) | Estandarización y Limpieza | `unused_import`, `non_constant_identifier_names` | 1. Se eliminaron imports inactivos de `dart:async` y `shared_widgets.dart`.<br>2. Se estandarizó el helper de estadísticas POS de `_POSStatBox` a `_posStatBox` para ajustarse estrictamente a las convenciones de lowerCamelCase de Dart. |
| [`lib/screens/admin_screen.dart`](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/admin_screen.dart) | Ajuste de Deprecaciones y Optimización | `deprecated_member_use`, `prefer_final_fields` | 1. Se migró la propiedad `activeColor` a `activeThumbColor` en los interruptores.<br>2. Se reemplazó el atributo de selección obsoleto `value` por `initialValue` en los campos dropdown de formulario.<br>3. Se eliminó la variable de estado inactiva `_isScannerLaserMoving`, inyectando el valor constante `true` directamente al widget de simulación de escaneo. |
| [`lib/screens/superadmin_screen.dart`](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/superadmin_screen.dart) | Corrección de API | `deprecated_member_use` | Se cambió el color de activación (`activeColor` deprecado) por la propiedad `activeThumbColor` en el interruptor de bloqueo instantáneo SaaS por cliente. |

---

## 🎨 Trazabilidad con Requerimientos y Mockups

Este avance tiene un impacto directo en los requerimientos del sistema y consolida la coherencia técnica del prototipo:

1. **RF 3.2 y RF 3.3 (Pagos y Renovaciones)**:
   - *Impacto*: Al sustituir `RadioListTile` por tarjetas táctiles personalizadas en la pantalla de renovación del socio (`_PayMembershipView`), se optimiza la usabilidad para "manos sudadas" (cumpliendo con el **RNF 1**).
   - *Trazabilidad*: La vista interactiva de selección de planes en la app de Flutter se conecta directamente con el flujo de subida de comprobantes manuales del mockup React de `sas_Gym_high`.

2. **RF 2.2 y RF 2.3 (Asistencia y Control de Acceso)**:
   - *Impacto*: La simplificación de la animación y el paso del control constante del láser del escáner en el Administrador asegura un rendimiento fluido sin renderizados redundantes (**RNF 2**).

3. **Mantenimiento y Estándares de la Plataforma**:
   - *Trazabilidad*: Toda la trazabilidad descrita en [TRAZABILIDAD_VISTAS.md](file:///d:/proyectos/sas_gym/TRAZABILIDAD_VISTAS.md) se mantiene vigente y ahora es 100% válida a nivel de compilación nativa en Flutter.

---

## 🔬 Resultados de Validación Estática

Para certificar la sanidad del código, se corrió la herramienta de análisis estático oficial en el directorio de la aplicación Flutter (`flutter_app`):

```powershell
flutter analyze
```

**Resultado:**
```
Analyzing flutter_app...
No issues found!
```

> [!NOTE]
> Este estado garantiza la total ausencia de warnings de sintaxis, variables muertas o APIs deprecadas en el subproyecto Flutter, sirviendo de base sólida para la posterior integración del backend.

---

## 📋 Planeamiento Detallado de Correcciones e Implementaciones

Para consolidar la portabilidad completa y el cumplimiento de los requerimientos (RF/RNF) descritos en `TRAZABILIDAD_VISTAS.md` y `planificacion.md`, se establece el siguiente plan de acción detallado para correcciones y próximas implementaciones en la aplicación Flutter.

### 1. Correcciones de Vacíos Funcionales (Gap Resolution)

A partir de la cobertura de requerimientos y vacíos detectados, se estructuran las siguientes implementaciones correctivas:

#### 1.1 Solución al Requerimiento RF 3.6 (Banner Push Deshabilitado)
* **Objetivo**: Mostrar un banner de alerta persistente pero descartable en la pantalla de inicio del Practicante (`MemberHome` en `member_screen.dart`) si las notificaciones push del sistema están deshabilitadas a nivel de sistema operativo o permiso de la app, cumpliendo con el RNF de respaldo vía correo electrónico.
* **Componente a Implementar**: `PushDisabledBanner` en `shared_widgets.dart`.
  - Usará un check de permisos simulado a través del estado de la aplicación (`gym_state.dart`).
  - Mostrará una tarjeta de alerta con color de advertencia (`--warning-color` o naranja/amarillo premium), indicando que el recordatorio de vencimiento llegará al correo electrónico asignado.
* **Trazabilidad**: RF 3.6 / RNF 4.

#### 1.2 Interfaz de Asignación Dedicada Entrenador ↔ Practicante (RF 1.2 / CU-05)
* **Objetivo**: Reemplazar el campo de texto simple en la creación de usuario (`NewMember` en `admin_screen.dart` y `cashier_screen.dart`) por un selector interactivo tipo modal/bottom-sheet que cargue el listado de entrenadores activos con su especialidad y carga de alumnos actual.
* **Componente a Implementar**: `TrainerSelectorBottomSheet` en `admin_screen.dart` y `cashier_screen.dart`.
  - Permitirá filtrar entrenadores por especialidad (ej. CrossFit, Powerlifting, Funcional).
  - Mostrará un indicador visual de cuántos alumnos tiene asignados (ej. "Carlos M. - 12 alumnos").
* **Trazabilidad**: RF 1.2 / CU-05.

#### 1.3 Pantalla de Recuperación de Contraseña (CU-02)
* **Objetivo**: Implementar la interfaz para el flujo de restablecimiento de contraseña (`ForgotPasswordView`) en la pantalla de inicio de sesión compartida.
* **Componente a Implementar**: `ForgotPasswordView` dentro de `main.dart` / `app.dart`.
  - Campo de entrada para correo electrónico validado.
  - Envío simulado con animación de carga y confirmación visual ("Correo enviado con éxito").
* **Trazabilidad**: CU-02.

---

### 2. Implementaciones Técnicas & Funcionalidades Avanzadas

#### 2.1 Sincronización de Estado Reactiva y en Tiempo Real (RF 2.3 / RF 3.3)
* **Objetivo**: Asegurar que los cambios de estado críticos (por ejemplo, el bloqueo instantáneo del gimnasio por el SuperAdmin o la aprobación de un pago por el Admin) se propaguen inmediatamente a las pantallas de los usuarios sin necesidad de recargar de forma manual.
* **Plan de Implementación**:
  1. **Notificaciones Push / FCM**: Configurar el backend (NestJS) para enviar payloads de datos silenciosos (Silent Push Notifications) a la app de Flutter cuando ocurran eventos críticos.
  2. **WebSocket Integration**: Implementar un servicio de WebSockets (`socket_io_client`) en `core/network/websocket_service.dart` que se conecte al servidor. Al recibir eventos como `gym_suspended` o `payment_approved`, actualizará el `GymStateProvider` de forma reactiva.
  3. **Fallback Polling**: Implementar un temporizador de polling de bajo impacto (cada 30 segundos) solo para pantallas críticas (ej. pantalla de acceso QR) si la conexión WebSocket se interrumpe.
* **Trazabilidad**: RNF 2 (Rendimiento) y RNF 3 (Seguridad).

#### 2.2 QR de Acceso Dinámico y Rotativo (RF 2.2 / RNF 3)
* **Objetivo**: Aumentar la seguridad del control de accesos impidiendo que los usuarios compartan capturas de pantalla de sus códigos QR.
* **Plan de Implementación**:
  - En la vista `MemberQR` (`member_screen.dart`), integrar un algoritmo que genere una cadena de texto dinámica que cambie cada 30-60 segundos.
  - La cadena codificará: `tenant_id | member_id | timestamp | secure_hash`.
  - El hash de seguridad se calculará usando una clave secreta local (TOTP).
  - Se añadirá un indicador visual animado de tiempo restante (usando `TimerRing` modificado) para guiar al usuario sobre la caducidad del QR.
* **Trazabilidad**: RF 2.2 / RNF 3.

#### 2.3 Soporte de Caché Versionada y Modo Offline (RNF 2)
* **Objetivo**: Permitir que el Practicante acceda a sus rutinas del día y al Asistente Virtual incluso si el gimnasio tiene mala cobertura de red móvil (habitual en sótanos de gimnasios).
* **Plan de Implementación**:
  - Utilizar **Hive** o **sqflite** para almacenar localmente la rutina semanal asignada y la biblioteca de ejercicios.
  - Guardar localmente las animaciones vectoriales o de bajo peso utilizadas por `ExerciseAnim`.
  - Crear una cola de sincronización offline (`OfflineSyncQueue`): cuando el practicante completa un entrenamiento sin conexión, los logs de esfuerzo y RPE se guardan localmente y se envían automáticamente al backend tan pronto como se recupere la conexión a Internet.
* **Trazabilidad**: RNF 1 (Usabilidad) y RNF 2 (Rendimiento/Offline).

---

### 3. Matriz de Trazabilidad Técnica para el Desarrollo Flutter

| ID Requerimiento | Módulo / Componente Flutter | Estado | Plan de Validación / Testeo |
|---|---|---|---|
| **RF 1.1** | `NewMember` (Admin/Caja) | ✅ Completo | Validar que el DNI ingresado no esté duplicado y que se asigne el `tenant_id` correcto. |
| **RF 1.2** | `TrainerSelector` (Admin) | 📅 Planificado (Sprint 2) | Mockear entrenadores y verificar que la asignación actualice el perfil del practicante en tiempo real. |
| **RF 1.3** | `SoftDeleteModal` (Caja/Admin) | ✅ Completo | Verificar que el estado del usuario cambie a `inactivo` y se registre en la Bitácora de Auditoría. |
| **RF 2.1** | `AdminScanner` (Ingreso único) | ✅ Completo | Simular escaneos consecutivos del mismo usuario en el mismo día y verificar que solo se registre un ingreso. |
| **RF 2.2** | Generación de QR dinámico | 📅 Planificado (Sprint 2) | Test unitario de expiración del token QR y validación del hash criptográfico. |
| **RF 2.3** | `ScannerVerdict` & Bloqueo | ✅ Completo | Forzar estado `vencido` en un socio y verificar que el veredicto sea rojo de inmediato. |
| **RF 2.4** | Configuración de Gracia | ✅ Completo | Configurar 1 día de gracia en `AdminSettings` y validar acceso exitoso de socio vencido hace < 24 horas. |
| **RF 3.1** | `CajaCharge` (POS) | ✅ Completo | Validar que la transacción en efectivo sume al saldo del turno activo de la caja. |
| **RF 3.3** | `ApprovePayments` (Bandeja) | ✅ Completo | Subir comprobante simulado de practicante, verificar alerta visual en Admin y cambio a activo al aprobar. |
| **RF 3.6** | Banner Notificaciones Off | 📅 Planificado (Sprint 2) | Simular deshabilitación de notificaciones en el dispositivo y validar aparición del banner. |
| **RF 4.3** | `WorkoutAssistant` (Asistente) | ✅ Completo | Probar el flujo completo: cronómetro, cambio de series, vibración simulada de descanso. |
| **RF 4.4** | `LogEffortModal` (RPE) | ✅ Completo | Validar que los campos de RPE y peso real admitan decimales y persistan en el historial de rutinas. |
| **RF 5.1** | `MemberObservation` (Foto) | ✅ Completo | Simular selección de imagen de cámara y compresión de peso a menos de 2 MB previo a envío simulado. |
| **RF 5.2** | `AdminInbox` (Bandeja de Ops) | ✅ Completo | Verificar que el Admin reciba todas las observaciones de la instancia y las agrupe cronológicamente. |

---

## 🛠️ Ampliación del Plan de Migración: Backend, APIs Detalladas y Arquitectura de la App

Esta sección define formalmente las modificaciones a nivel de Backend, el diseño detallado de APIs (REST y WebSockets) y la arquitectura de consumo que se debe implementar en la aplicación Flutter para garantizar la integración completa del sistema.

### 1. Modificaciones y Extensiones sobre el Modelo de Datos de CrossHero

Para dar soporte a los requerimientos avanzados que no están cubiertos por CrossHero estándar, se deben realizar los siguientes cambios en la base de datos y modelo del backend (usando Prisma ORM en NestJS):

```prisma
// Extensiones al modelo original de CrossHero para GymSmart

model MemberRecord {
  id                    String         @id @default(uuid())
  tenantId              String         // Multi-tenant isolation
  userId                String         @unique
  dni                   String         @unique
  fullName              String
  status                MemberStatus   @default(PENDIENTE)
  gracePeriodExpiresAt  DateTime?      // RF 2.4 (Margen de gracia)
  assignedTrainerId     String?        // RF 1.2 (Relación 1:1)
  trainer               TrainerRecord? @relation(fields: [assignedTrainerId], references: [id])
  qrSecret              String         // Para generación de TOTP (RF 2.2)
  observations          Observation[]
  payments              PaymentRecord[]
  workoutLogs           WorkoutLog[]
  createdAt             DateTime       @default(now())
  updatedAt             DateTime       @updatedAt
}

model PaymentRecord {
  id             String         @id @default(uuid())
  tenantId       String
  memberId       String
  member         MemberRecord   @relation(fields: [memberId], references: [id])
  amount         Decimal        @db.Decimal(10, 2)
  method         PaymentMethod  // CASH, YAPE, PLIN, CARD
  status         PaymentStatus  @default(PENDIENTE) // PENDIENTE, APROBADO, RECHAZADO
  receiptUrl     String?        // Enlace a imagen (S3/Cloudinary) - RF 3.3
  resolvedById   String?        // Admin que aprobó/rechazó
  resolvedAt     DateTime?
  comments       String?
  createdAt      DateTime       @default(now())
}

model CashierAccount {
  id             String         @id @default(uuid())
  tenantId       String
  userId         String         @unique
  fullName       String
  shiftStartHour String         // Formato "HH:MM" (Horario de control - RNF 3)
  shiftEndHour   String         // Formato "HH:MM"
  isActive       Boolean        @default(true)
  permissions    Json           // {"canDeleteProducts": false, "canModifyPrices": true}
  sessions       CashierSession[]
}

model CashierSession {
  id             String         @id @default(uuid())
  cashierId      String
  cashier        CashierAccount @relation(fields: [cashierId], references: [id])
  openedAt       DateTime       @default(now())
  closedAt       DateTime?
  cashExpected   Decimal        @db.Decimal(10, 2)
  cashReported   Decimal?       @db.Decimal(10, 2)
  status         SessionStatus  @default(OPEN) // OPEN, CLOSED
}

model WorkoutLog {
  id             String         @id @default(uuid())
  memberId       String
  member         MemberRecord   @relation(fields: [memberId], references: [id])
  routineId      String
  exercises      Json           // [{"exerciseId": "...", "series": [{"reps": 12, "weight": 20.5, "rpe": 8}]}]
  createdAt      DateTime       @default(now())
}

enum MemberStatus {
  ACTIVO
  VENCIDO
  PENDIENTE
  GRACIA
  INACTIVO
}

enum PaymentMethod {
  CASH
  YAPE
  PLIN
  CARD
}

enum PaymentStatus {
  PENDIENTE
  APROBADO
  RECHAZADO
}

enum SessionStatus {
  OPEN
  CLOSED
}
```

---

### 2. Diseño de APIs Detalladas para el Consumo Móvil

Todos los endpoints requieren los siguientes headers de control:
* `Authorization: Bearer <JWT_TOKEN>` (Contiene el `role` y `user_id`).
* `X-Tenant-ID: <TENANT_ID>` (Asegura el aislamiento lógico multi-tenant).

#### 2.1 Autenticación y Recuperación
* **`POST /api/v1/auth/login`**
  * *Request Body:*
    ```json
    {
      "email": "mateo.salas@gmail.com",
      "password": "secret_password"
    }
    ```
  * *Response (200 OK):*
    ```json
    {
      "token": "eyJhbGciOi...",
      "tenantId": "gym-smart-surco",
      "user": {
        "id": "usr_90210",
        "email": "mateo.salas@gmail.com",
        "role": "MEMBER",
        "fullName": "Mateo Salas"
      }
    }
    ```
* **`POST /api/v1/auth/forgot-password`** (CU-02)
  * *Request Body:*
    ```json
    {
      "email": "mateo.salas@gmail.com"
    }
    ```
  * *Response (200 OK):*
    ```json
    {
      "message": "Enlace de recuperación enviado al correo registrado."
    }
    ```

#### 2.2 Gestión de Pagos Manuales (Acreditación Digital - RF 3.3)
* **`POST /api/v1/members/upload-receipt`**
  * *Request (Multipart Form Data):*
    * `amount`: `150.00`
    * `method`: `YAPE`
    * `receipt`: `[ARCHIVO_IMAGEN_COMPRIMIDO]` (Máximo 2MB - RNF 4)
  * *Response (201 Created):*
    ```json
    {
      "paymentId": "pay_55482",
      "status": "PENDIENTE",
      "message": "Comprobante subido. Pendiente de aprobación por administración."
    }
    ```
* **`GET /api/v1/admin/pending-payments`** (Bandeja de Aprobaciones del Admin)
  * *Response (200 OK):*
    ```json
    [
      {
        "id": "pay_55482",
        "member": {
          "fullName": "Mateo Salas",
          "dni": "12345678"
        },
        "amount": 150.00,
        "method": "YAPE",
        "receiptUrl": "https://storage.gymsmart.com/receipts/pay_55482.jpg",
        "createdAt": "2026-05-22T04:15:00Z"
      }
    ]
    ```
* **`POST /api/v1/admin/payments/:id/resolve`** (Aprobación/Rechazo)
  * *Request Body:*
    ```json
    {
      "status": "APROBADO", // APROBADO o RECHAZADO
      "comments": "Pago validado en cuenta BCP"
    }
    ```
  * *Response (200 OK):*
    ```json
    {
      "id": "pay_55482",
      "status": "APROBADO",
      "resolvedAt": "2026-05-22T04:19:00Z"
    }
    ```

#### 2.3 Control de Acceso mediante QR Dinámico (RF 2.2 / RF 2.3)
* **`GET /api/v1/members/qr-code`** (Generación de semilla en la App del Socio)
  * *Response (200 OK):*
    ```json
    {
      "qrSecret": "JBSWY3DPEHPK3PXP", // Semilla TOTP secreta
      "intervalSeconds": 30
    }
    ```
* **`POST /api/v1/attendance/verify`** (Verificación en el Escáner del Admin/Caja)
  * *Request Body:*
    ```json
    {
      "dni": "12345678",
      "otpToken": "582910" // Token de 6 dígitos leído del QR del socio
    }
    ```
  * *Response (200 OK - Acceso Concedido):*
    ```json
    {
      "verdict": "GREEN",
      "member": {
        "fullName": "Mateo Salas",
        "status": "ACTIVO",
        "planName": "Membresía Mensual",
        "expiresAt": "2026-06-22T00:00:00Z"
      }
    }
    ```
  * *Response (400 Bad Request - Acceso Denegado / Vencido):*
    ```json
    {
      "verdict": "RED",
      "reason": "Membresía Vencida (Venció el 2026-05-20)",
      "member": {
        "fullName": "Mateo Salas",
        "status": "VENCIDO",
        "expiresAt": "2026-05-20T00:00:00Z"
      }
    }
    ```

#### 2.4 Reportar Observación con Evidencia Fotográfica (RF 5.1)
* **`POST /api/v1/observations`**
  * *Request (Multipart Form Data):*
    * `title`: "Máquina de poleas averiada"
    * `description`: "El cable tensor de la polea alta de espalda está deshilachado."
    * `photo`: `[ARCHIVO_IMAGEN_COMPRIMIDO]` (Opcional, máx 2MB)
  * *Response (201 Created):*
    ```json
    {
      "observationId": "obs_77491",
      "status": "ABIERTA",
      "photoUrl": "https://storage.gymsmart.com/obs/obs_77491.jpg",
      "createdAt": "2026-05-22T04:20:00Z"
    }
    ```

---

### 3. Arquitectura de Consumo y Flujo de Datos en Flutter

La aplicación móvil de Flutter seguirá un patrón de arquitectura **Clean Architecture + Feature-First**, dividida en capas desacopladas que permiten mockear el backend localmente de forma inmediata y mantener lógica offline transparente:

```
               ┌───────────────────────────────┐
               │        PRESENTATION (UI)      │
               │  Screens, Widgets, Views      │
               └───────────────┬───────────────┘
                               │ Observa cambios de estado
                               ▼
               ┌───────────────────────────────┐
               │    STATE MANAGEMENT (Domain)  │
               │   ChangeNotifier / Providers  │
               └───────────────┬───────────────┘
                               │ Invoca casos de uso / Repositorios
                               ▼
               ┌───────────────────────────────┐
               │     REPOSITORIES (Domain)     │
               │   Interfaces & Data Mapping   │
               └───────────────┬───────────────┘
                               │ Decide procedencia de datos (Offline-first)
                               ▼
        ┌──────────────────────┴──────────────────────┐
        ▼                                             ▼
┌───────────────┐                             ┌───────────────┐
│ REMOTE DATA   │                             │  LOCAL DATA   │
│ Dio / Rest API│                             │Hive / SecureS.│
└───────────────┘                             └───────────────┘
```

#### 3.1 Estructura Clave de Clases para Consumo (Dio Service)

```dart
// core/network/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio) {
    dio.options.baseUrl = "https://api.gymsmart.com/api/v1";
    dio.options.connectTimeout = const Duration(milliseconds: 5000);
    dio.options.receiveTimeout = const Duration(milliseconds: 3000);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Inyección de Token y Tenant ID de forma centralizada
        final token = await SecureStorage.getToken();
        final tenantId = await SecureStorage.getTenantId();
        
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        if (tenantId != null) {
          options.headers["X-Tenant-ID"] = tenantId;
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Lógica de expiración automática de sesión y logout limpio
          AuthNotifier.forceLogout();
        }
        return handler.next(e);
      },
    ));
  }
}
```

#### 3.2 Repositorio de Membresías y Pagos (Offline-First)

```dart
// features/payments/data/member_repository.dart
import 'package:dio/dio.dart';

abstract class IMemberRepository {
  Future<PaymentStatus> uploadReceipt({required double amount, required String method, required String filePath});
  Future<List<PaymentRecord>> getLocalPaymentHistory();
}

class MemberRepositoryImpl implements IMemberRepository {
  final ApiClient apiClient;
  final LocalCache localCache; // Instancia de Hive

  MemberRepositoryImpl({required this.apiClient, required this.localCache});

  @override
  Future<PaymentStatus> uploadReceipt({required double amount, required String method, required String filePath}) async {
    try {
      final formData = FormData.fromMap({
        "amount": amount,
        "method": method,
        "receipt": await MultipartFile.fromFile(filePath, filename: "receipt.jpg"),
      });

      final response = await apiClient.dio.post("/members/upload-receipt", data: formData);
      return PaymentStatus.values.byName(response.data["status"].toString().toUpperCase());
    } catch (e) {
      // En caso de fallo de red, se encola para envío posterior (Offline Queue)
      await localCache.queueOfflineAction(
        OfflineAction(
          endpoint: "/members/upload-receipt",
          payload: {"amount": amount, "method": method, "filePath": filePath},
        ),
      );
      throw OfflineException("Sin conexión. Su recibo se enviará automáticamente al recuperar red.");
    }
  }

  @override
  Future<List<PaymentRecord>> getLocalPaymentHistory() async {
    // Si no hay red, consume de la base de datos local de Hive
    if (!await NetworkInfo.isConnected) {
      return localCache.getPayments();
    }
    try {
      final response = await apiClient.dio.get("/members/payment-history");
      final remoteList = (response.data as List).map((x) => PaymentRecord.fromJson(x)).toList();
      await localCache.savePayments(remoteList); // Guarda en caché local para offline
      return remoteList;
    } catch (e) {
      return localCache.getPayments();
    }
  }
}
```

---

### 4. Nuevas Funcionalidades Detalladas sobre CrossHero

A continuación se detalla la matriz de diferencias, mejoras funcionales y extensiones operativas que posee **GymSmart** frente a **CrossHero** estándar, con el fin de justificar la propuesta de migración y documentar cada comportamiento nuevo:

| Funcionalidad / Módulo | Comportamiento en CrossHero Estándar | Nueva Implementación en GymSmart (Flutter + NestJS) | Beneficio Operativo y Técnico |
|---|---|---|---|
| **Gestión de Caja y Turnos** | No posee módulo de POS ni de caja diario. Los cobros son registros simples. | Sistema POS integrado en la app del Cajero (`CajaCharge`). Permite apertura/cierre de turnos con saldo esperado vs. real (`CashierSession`) y limita la operación según el horario del cajero. | **RF 3.1, RNF 3.** Control total del flujo de caja, mitigando pérdidas por discrepancias de cuadre y restringiendo accesos fuera de turno. |
| **Control de Acceso Seguro** | Permite registrar ingresos usando DNI fijo o QR estático que puede ser clonado (captura de pantalla). | **QR Dinámico Rotativo** generado mediante clave criptográfica TOTP (`qrSecret`). El código QR expira y rota automáticamente cada 30 segundos en la pantalla del socio. | **RF 2.2, RNF 3.** Erradica el fraude por uso compartido de membresías. El ingreso se valida en menos de 2 segundos. |
| **Asistente de Entrenamiento** | Muestra la rutina asignada como una simple lista de texto con enlaces a fotos estáticas. | **Asistente Virtual Interactivo** (`WorkoutAssistant`). Integra animaciones vectoriales fluidas en loop (`ExerciseAnim`), control de descanso con alarma háptica (`TimerRing`) y registro directo de RPE. | **RF 4.3, RF 4.4, RNF 1.** Facilidad de uso para deportistas con "manos sudadas". Automatiza el registro de volumen real cargado por sesión. |
| **Pasarela de Pago Local** | Enfocado en mercados de EE.UU. o Europa mediante Stripe. | Integración con pasarelas de pago peruanas (Yape / Plin dinámico mediante Culqi/Izipay). | **RF 3.2.** Adaptación directa al comportamiento de pago del mercado local peruano sin recargo por tipo de cambio. |
| **Bandeja de Aprobación de Comprobantes** | No posee soporte para subir capturas y validarlas en el panel del Admin. | **Acreditación Digital Manual** (`ApprovePayments`). El socio sube captura del pago (comprimido en cliente < 2MB). El Admin valida y aprueba/rechaza en su bandeja móvil. | **RF 3.3, RNF 4.** Facilita el pago fuera de línea de forma transparente y reduce la carga administrativa de control manual de extractos bancarios. |
| **Reportes de Auditoría** | Logs de cambios limitados a nivel técnico. | **Bitácora de Auditoría en Tiempo Real** (`AdminAuditLog`). Almacena detalles de cada modificación física o lógica de datos realizada por Cajeros o Entrenadores. | **RNF 3.** Seguridad mejorada y trazabilidad estricta ante anulaciones de venta o bajas de socios. |
| **Barrera de Bloqueo Instantánea** | Solo bloquea usuarios a nivel de cuenta individual en login. | **Filtro de Suspensión Global SaaS** (`GymSuspendedBarrier`). Si un gimnasio no abona la renta del SaaS, el SuperAdmin desactiva el tenant y la app de todos los usuarios de ese gimnasio muestra inmediatamente una pantalla de bloqueo. | **Multi-tenant SaaS Control.** Permite forzar el pago de la suscripción del gimnasio a nivel de plataforma de forma inmediata. |

---

## 📅 Plan de Desarrollo por Fases, Rutas y Validación

El proyecto se estructurará en 7 fases consecutivas. Cada fase comprende una definición clara de las rutas de archivos afectadas (tanto en Flutter como en el backend NestJS), las tareas específicas de desarrollo y sus correspondientes criterios y comandos de validación/verificación.

### Fase 0: Revisión, Auditoría y Verificación de Rutas Base
* **Objetivo:** Verificar la integridad de la base de código actual de Flutter, mapear las dependencias existentes y validar que la configuración local compile sin fallos.
* **Rutas de Archivos Clave:**
  * **Flutter (`flutter_app`):**
    * [lib/main.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/main.dart) - Punto de entrada.
    * [lib/app.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/app.dart) - Configuración de rutas y barreras SaaS.
    * [lib/screens/](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/) - Directorio de vistas de todos los roles (`admin_screen.dart`, `trainer_screen.dart`, etc.).
  * **Backend (`backend`):**
    * Mapeo de la estructura de carpetas en NestJS (`src/modules/auth`, `src/modules/members`, etc.) y archivo `prisma/schema.prisma`.
* **Actividades:**
  1. Ejecución de análisis estático del frontend.
  2. Mapeo de puertos locales para desarrollo (ej. Backend puerto `3000`, Flutter simulador local).
* **Validación y Verificación:**
  * **Comando:**
    ```powershell
    cd flutter_app
    flutter analyze
    ```
  * **Criterio de Aceptación:** Salida limpia `No issues found!`. Confirmación de conexión exitosa a la base de datos PostgreSQL local via Prisma.

---

### Fase 1: Implementación del Core del Backend & Base de Datos (NestJS)
* **Objetivo:** Configurar las migraciones del modelo de datos extendido y los módulos básicos de autenticación y multi-tenancy.
* **Rutas de Archivos Clave:**
  * **Backend (`backend`):**
    * `prisma/schema.prisma` - Estructura de tablas y enums.
    * `src/modules/auth/` - Controladores y servicios de login y recuperación.
    * `src/core/guards/tenant.guard.ts` - Middleware extractor de `X-Tenant-ID`.
* **Actividades:**
  1. Ejecutar migración de base de datos con Prisma.
  2. Implementar endpoints de autenticación y lógica de encriptación de claves.
  3. Crear guards para verificar roles y `tenant_id` en NestJS.
* **Validación y Verificación:**
  * **Pruebas:**
    * Ejecutar pruebas unitarias de autenticación con Jest en NestJS.
    * Validar la restricción de datos entre tenants mediante scripts de consulta cruzada.
  * **Comando:**
    ```bash
    npm run test:cov
    ```
  * **Criterio de Aceptación:** Cobertura de pruebas en módulo Auth > 80%. Verificación de que una consulta sin `tenant_id` retorne error `400 Bad Request`.

---

### Fase 2: Integración de Autenticación y Perfiles en la App (Flutter)
* **Objetivo:** Conectar la aplicación móvil al backend para inicio de sesión, recuperación de contraseña y perfiles de usuario.
* **Rutas de Archivos Clave:**
  * **Flutter (`flutter_app`):**
    * [lib/core/network/api_client.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/core/network/api_client.dart) - Cliente HTTP Dio con interceptores.
    * [lib/core/storage/secure_storage.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/core/storage/secure_storage.dart) - Persistencia encriptada de JWT.
    * [lib/screens/member_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/member_screen.dart) - Integración de vista de perfil.
* **Actividades:**
  1. Implementar cliente `Dio` con interceptor de `X-Tenant-ID`.
  2. Conectar la vista de Login en Flutter al endpoint `/auth/login`.
  3. Desarrollar la vista interactiva `ForgotPasswordView` en `app.dart`.
* **Validación y Verificación:**
  * **Pruebas:**
    * Iniciar sesión con credenciales mockeadas en base de datos.
    * Simular token expirado y validar que el interceptor redirija al Login de forma limpia.
  * **Criterio de Aceptación:** Guardado exitoso del JWT en almacenamiento seguro. Redirección automática al rol correcto tras el login exitoso.

---

### Fase 3: Control de Acceso Mediante QR Dinámico (TOTP)
* **Objetivo:** Implementar la rotación del QR del lado del practicante y la validación en tiempo real en la pantalla del cajero/escáner, mitigando fraudes por capturas de pantalla y desincronización de hora.
* **Rutas de Archivos Clave:**
  * **Flutter (`flutter_app`):**
    * [lib/widgets/shared_widgets.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/widgets/shared_widgets.dart) - Pintado del QR (`QRPattern`) y el temporizador (`TimerRing`).
    * [lib/screens/member_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/member_screen.dart) - Vista del QR dinámico del socio.
    * [lib/screens/cashier_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/cashier_screen.dart) - Vista del escáner y veredicto.
  * **Backend (`backend`):**
    * `src/modules/attendance/` - Controlador de verificación de TOTP.
* **Actividades e Ingeniería Aterrizada:**
  1. **Generación TOTP en Cliente:** Implementar algoritmo local de generación TOTP en la app utilizando la clave `qrSecret` del socio y la hora local, refrescando el token cada 30 segundos sincronizado con la animación circular `TimerRing`.
  2. **Ventanilla de Tolerancia del Reloj (Desfase de Hora):** Configurar el validador del backend (`POST /attendance/verify`) para que admita un **factor de desfase de ±1 intervalo** de tolerancia (ventana total de 90 segundos: 30s anterior, 30s actual y 30s posterior). Esto absorbe discrepancias de reloj entre el celular del socio y el servidor sin rechazar accesos válidos.
  3. **Conexión de Veredictos:** Acoplar el resultado del backend con la vista fullscreen de `ScannerVerdict` para conceder o denegar ingreso con sonido o vibración háptica.
* **Validación y Verificación:**
  * **Pruebas:**
    * Modificar la hora local del celular de prueba desfasándola 25 segundos y validar que el escáner del cajero aún acepte el ingreso.
    * Desfasar la hora del celular 2 minutos (fuera de la ventana de tolerancia) y comprobar que el veredicto sea rojo de inmediato.
  * **Criterio de Aceptación:** Latencia de respuesta en verificación de QR ≤ 2 segundos. Aceptación del token QR desfasado dentro de la tolerancia de ±1 paso (30s) y rechazo inmediato si excede dicho margen.

---

### Fase 4: Módulo de Caja, POS y Acreditación de Pagos
* **Objetivo:** Habilitar el registro de cobros en efectivo/digitales, apertura/cierre de turnos de caja y el flujo de aprobación de comprobantes con compresión de medios optimizada.
* **Rutas de Archivos Clave:**
  * **Flutter (`flutter_app`):**
    * [lib/screens/cashier_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/cashier_screen.dart) - Cobros POS y control de turno.
    * [lib/screens/admin_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/admin_screen.dart) - Aprobación de comprobantes.
    * [lib/screens/member_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/member_screen.dart) - Carga de recibo.
  * **Backend (`backend`):**
    * `src/modules/payments/` - Módulo de transacciones.
* **Actividades e Ingeniería Aterrizada:**
  1. **Compresión Automática de Comprobante:** Integrar el plugin `flutter_image_compress` en la pantalla de carga del socio (`_PayMembershipView`). Toda imagen seleccionada de la galería o cámara será comprimida a formato JPEG, calidad 80%, y resolución máxima de 1920x1080 píxeles. Esto asegura que los comprobantes subidos pesen estrictamente < 2MB (RF 3.3 / RNF 4) reduciendo el uso de storage en el backend y el consumo de red del socio.
  2. **Bandeja de Aprobaciones:** Implementar la actualización del listado de la bandeja de entrada del Administrador mediante WebSocket o polling activo.
  3. **Restricción de Operación POS:** Configurar el guard del backend para verificar que el cajero que inicia la transacción pertenezca al turno abierto en `CashierSession` y esté en su horario programado.
* **Validación y Verificación:**
  * **Pruebas:**
    * Intentar realizar una venta POS con una cuenta de cajero fuera de su turno establecido y comprobar que NestJS devuelva un error HTTP 403.
    * Seleccionar una captura de pantalla de comprobante de 6MB en la app del socio, verificar que la compresión del cliente la reduzca a <1.2MB antes de subirla y validar la recepción correcta en S3/Cloudinary.
  * **Criterio de Aceptación:** Al aprobar el comprobante desde la cuenta de Administrador, el estado del practicante cambia inmediatamente a `ACTIVO` y su QR dinámico se desbloquea en tiempo real.

---

### Fase 5: Biblioteca de Ejercicios y Asistente Virtual (RPE y Timer)
* **Objetivo:** Conectar la biblioteca de ejercicios animada del entrenador con la agenda semanal y el asistente virtual interactivo del socio, garantizando redundancia total ante desconexión de red.
* **Rutas de Archivos Clave:**
  * **Flutter (`flutter_app`):**
    * [lib/screens/trainer_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/trainer_screen.dart) - Editor y asignador de rutinas.
    * [lib/screens/member_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/member_screen.dart) - Asistente virtual paso a paso y modal de esfuerzo (RPE).
  * **Backend (`backend`):**
    * `src/modules/routines/` - Rutinas y logs de esfuerzo.
* **Actividades e Ingeniería Aterrizada:**
  1. **Persistencia y Caché Local:** Usar cajas de `Hive` para almacenar localmente las rutinas del usuario y la biblioteca de ejercicios mapeados.
  2. **Monitoreo de Red con Connectivity:** Integrar el plugin `connectivity_plus` en Flutter. Configurar un event listener que monitorice los cambios de estado de red (`Wifi/Cellular/None`).
  3. **Cola de Envío Offline:** Si el socio finaliza su entrenamiento sin red, los logs se guardan en la tabla local de Hive `OfflineSyncQueue`. En cuanto el listener de conectividad detecte la restauración de Internet, se disparará una tarea en segundo plano que consume la cola y envía de forma secuencial cada registro al endpoint `/members/workout-log` del backend.
* **Validación y Verificación:**
  * **Pruebas:**
    * Colocar el dispositivo en Modo Avión, iniciar entrenamiento, registrar 4 series de ejercicio con sus pesos y RPE en la vista del socio y presionar "Finalizar". Verificar que la UI muestre el aviso "Guardado localmente". 
    * Reactivar la conexión a Internet y verificar mediante la consola del backend la recepción íntegra del log del socio sin duplicados.
  * **Criterio de Aceptación:** Sincronización transparente de la cola en segundo plano al recuperar red, sin interacción requerida por el usuario y con confirmación visual de sincronizado en el timeline.

---

### Fase 6: Observaciones, Auditoría y Desactivación SaaS Global
* **Objetivo:** Habilitar el buzón de observaciones técnicas, el registro de auditoría transversal y el bloqueo instantáneo multi-tenant.
* **Rutas de Archivos Clave:**
  * **Flutter (`flutter_app`):**
    * [lib/screens/superadmin_screen.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/screens/superadmin_screen.dart) - Activación/Desactivación de tenants.
    * [lib/app.dart](file:///d:/proyectos/sas_gym/flutter_app/lib/app.dart) - Widget global `GymSuspendedBarrier`.
  * **Backend (`backend`):**
    * `src/modules/observations/` - Gestión de reportes.
    * `src/core/middleware/audit.middleware.ts` - Log de auditoría.
* **Actividades e Ingeniería Aterrizada:**
  1. **Compresión en Observaciones:** Aplicar la misma compresión automática JPEG con `flutter_image_compress` a la evidencia fotográfica de las fallas mecánicas reportadas por practicantes.
  2. **Intercepción de Auditoría:** Implementar un middleware global en NestJS que intercepte toda petición de modificación de base de datos (`POST`, `PATCH`, `DELETE`) de los módulos de POS, Caja y Miembros, guardando de forma asíncrona un registro con el ID del actor, tipo de acción, entidad afectada y cuerpo de cambios en la tabla de auditoría.
  3. **WebSocket SaaS Blocking Event:** Al pulsar el interruptor de bloqueo en la vista de `SuperAdminApp`, emitir un evento WebSocket global a la sala del tenant afectado.
* **Validación y Verificación:**
  * **Pruebas:**
    * Cambiar el estado de un tenant a `inactivo` desde la vista del SuperAdmin.
    * Comprobar que en menos de 1 segundo todas las apps móviles activas bajo ese tenant muestren la pantalla de suspensión global, bloqueando cualquier otra acción.
    * Realizar modificaciones físicas de un producto en el POS y verificar que la base de datos registre el log en la tabla de auditoría con la firma del cajero activo.
  * **Criterio de Aceptación:** Bloqueo inmediato y completo de la interfaz de usuario de todas las cuentas asociadas al tenant suspendido. Trazabilidad del 100% de operaciones de escritura en caja en la base de datos.

