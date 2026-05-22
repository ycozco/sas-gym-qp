# 🏋️ GymSmart — Planificación Técnica Integral
## Desarrollo CrossHero como Base + Extensiones Personalizadas

> **Proyecto:** SAS GYM — GymSmart
> **Enfoque:** Construir todo lo que CrossHero ofrece como base, luego desarrollar lo que falta
> **Stack:** Flutter (móvil) · NestJS + Prisma (backend) · PostgreSQL (DB)
> **Arquitectura:** SaaS Multi-tenant
> **Fecha:** Mayo 2026

---

## 1. Visión General del Producto

GymSmart es un sistema de gestión integral para gimnasios pequeños y medianos (<100 usuarios activos por instancia). El desarrollo parte de **implementar todas las funcionalidades que CrossHero ya tiene consolidadas** como núcleo del sistema, y sobre esa base se construyen los **módulos diferenciadores** que CrossHero no cubre o cubre de forma incompleta para el mercado peruano.

```
╔══════════════════════════════════════════════════════════════════╗
║              GYMSMART — ARQUITECTURA DE PRODUCTO                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  CAPA 1 — BASE CROSSHERO (Replicar y adaptar)                   ║
║  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            ║
║  │ Auth & Roles │ │  Membresías  │ │  Asistencia  │            ║
║  │  (Multi-rol) │ │  y Pagos     │ │  y Acceso    │            ║
║  └──────────────┘ └──────────────┘ └──────────────┘            ║
║  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            ║
║  │  Reservas y  │ │  Biblioteca  │ │  Perfiles y  │            ║
║  │  Horarios    │ │  Ejercicios  │ │  Dashboards  │            ║
║  └──────────────┘ └──────────────┘ └──────────────┘            ║
║                                                                  ║
║  CAPA 2 — EXTENSIONES PERSONALIZADAS (Lo que falta)             ║
║  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            ║
║  │  Asistente   │ │  Pasarelas   │ │  Multi-vista │            ║
║  │  Virtual     │ │  Peruanas    │ │  Privacidad  │            ║
║  │  (Rutinas)   │ │  Yape/Plin   │ │  por Rol     │            ║
║  └──────────────┘ └──────────────┘ └──────────────┘            ║
║  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            ║
║  │  Esfuerzo    │ │ Observaciones│ │  QR Dinámico │            ║
║  │  Real        │ │ con Foto     │ │  de Acceso   │            ║
║  └──────────────┘ └──────────────┘ └──────────────┘            ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 2. Roles del Sistema (completos)

| Rol | Descripción | Acceso App |
|---|---|---|
| **Super-Admin** | Gestiona el back-office SaaS global, crea instancias de gimnasios | Web Admin Panel |
| **Administrador** | Gestiona su instancia: cobros, asistencia, usuarios, anuncios | App Flutter (admin) |
| **Caja / Recepción** | Sub-rol del Admin: cobros + control de acceso únicamente | App Flutter (caja) |
| **Entrenador** | Gestiona ejercicios, rutinas y seguimiento técnico de sus asignados | App Flutter (trainer) |
| **Usuario** | Entrena, paga, genera su QR de acceso | App Flutter (member) |

---

Nota: Mapeo detallado de roles a vistas y mockups disponible en `planificacion_designthinking.md` sección 1.4 (Roles del Sistema). Mantener ambos documentos sincronizados cuando se modifiquen permisos.


## 3. Funcionalidades Completas — CrossHero Base + Extensiones

### 3.1 MÓDULO A — Autenticación y Gestión de Usuarios
*(CrossHero base + adaptaciones)*

#### A.1 Autenticación
| Feature | Origen | Descripción |
|---|---|---|
| Login con email/contraseña | CrossHero base | Validación de credenciales, generación de JWT |
| "Recordarme" / Inicio automático | CrossHero base | Token de larga duración encriptado (`flutter_secure_storage`) |
| Recuperación de contraseña | CrossHero base | Envío de link seguro al correo electrónico |
| Cierre de sesión | CrossHero base | Invalidación del token en servidor (blacklist) |
| Multi-tenant routing | CrossHero base | Cada gimnasio tiene su `tenant_id` aislado |

#### A.2 Gestión de Usuarios
| Feature | Origen | Descripción |
|---|---|---|
| Registro de usuario (auto) | CrossHero base | Estado "Pendiente de Pago" hasta confirmar membresía |
| Registro de usuario (manual por Admin) | CrossHero base | Admin registra directamente desde su panel |
| Asignación Entrenador → Usuario (1:1) | Extensión | CrossHero permite N:N; aquí la relación es 1 Entrenador : N Usuarios |
| Baja lógica (Soft Delete) | CrossHero base | Estado "Inactivo", datos históricos preservados |
| Activación/reactivación de usuarios | CrossHero base | Cambia estado, restaura acceso |
| Búsqueda y filtros de usuarios | CrossHero base | Por nombre, DNI, estado membresía |
| Invitación de entrenadores por email | CrossHero base | Link seguro para registro inicial |

#### A.3 Perfiles (Multi-vista — Extensión clave)
| Feature | Origen | Descripción |
|---|---|---|
| Perfil Empresa/Gimnasio | CrossHero base | Logo, nombre, horario, teléfono, redes sociales |
| Perfil Profesional Entrenador | CrossHero base | Foto, especialidad, experiencia, certificaciones |
| Vista Privada del Usuario | CrossHero base | Correo, DNI, celular (solo el usuario) |
| Vista Operativa del Usuario | Extensión | Solo Admin: nombre, DNI, estado membresía, entrenador asignado |
| Vista Técnica del Usuario | Extensión | Solo Entrenador asignado: peso, lesiones, objetivo, historial |
| Vista Social del Usuario | Extensión | Foto/nickname, toggle Activo/Inactivo (visible para otros usuarios) |
| Vista Física Privada del Usuario | Extensión | Fotos Antes/Después, medidas corporales (solo el usuario) |

---

### 3.2 MÓDULO B — Control de Asistencia y Acceso
*(CrossHero base + extensión QR dinámico)*

| Feature | Origen | Descripción |
|---|---|---|
| Registro de ingreso al gimnasio | CrossHero base | Log con timestamp por usuario |
| Escaneo desde celular del Admin/Caja | CrossHero base | Cámara del dispositivo + biblioteca `mobile_scanner` |
| Validación en tiempo real de membresía | CrossHero base | Verifica estado al momento del escaneo |
| Respuesta visual de acceso (verde/rojo) | Extensión | Fullscreen verde = concedido, rojo = denegado + alerta al Admin |
| QR dinámico generado por el usuario | Extensión | QR con `member_id + tenant_id + timestamp` (rotación dinámica) |
| Soporte cámara fija en entrada (hardware) | Extensión | Endpoint REST que recibe identificador del escáner autónomo |
| Margen de gracia de 1 día post-vencimiento | Extensión | Configuración por instancia de gimnasio |
| Alerta push al Admin si membresía vencida | Extensión | Notificación en tiempo real via FCM |
| Log diario de ingresos | CrossHero base | Listado paginado con filtros de fecha |
| Registro único de ingreso por día | Extensión | Previene doble conteo si el usuario entra y sale varias veces |

---

### 3.3 MÓDULO C — Gestión de Pagos y Membresías
*(CrossHero base + pasarelas peruanas)*

| Feature | Origen | Descripción |
|---|---|---|
| Creación y gestión de planes/membresías | CrossHero base | Mensual, trimestral, anual — configuración por Admin |
| Registro de pago en efectivo | CrossHero base | Admin/Caja registra monto + confirma recepción |
| Cálculo automático de fecha de vencimiento | CrossHero base | Suma duración del plan a la fecha de pago |
| Historial de pagos por usuario | CrossHero base | Timeline de todos los pagos registrados |
| Estados de membresía | CrossHero base | ACTIVO / VENCIDO / PENDIENTE / GRACIA / INACTIVO |
| Cobro online por pasarela (Culqi / Izipay) | Extensión | CrossHero usa Stripe; GymSmart usa pasarelas peruanas |
| Generación de QR Yape/Plin desde pasarela | Extensión | QR dinámico de cobro en pantalla del usuario |
| Webhook de confirmación de pago automática | Extensión | Pasarela notifica al backend, membresía se actualiza sola |
| Acreditación manual (upload screenshot) | Extensión | Usuario sube comprobante → Admin aprueba/rechaza |
| Notificación push 7 días antes del vencimiento | Extensión | Cron job diario evaluando fechas |
| Recordatorio push diario post-vencimiento | Extensión | Cron job, hasta que el estado cambie a ACTIVO |
| Banner en app si notificaciones deshabilitadas | Extensión | Fallback: alerta visual en home del usuario |
| Correo de respaldo si push deshabilitado | Extensión | SMTP template para recordatorio de vencimiento |
| Dashboard de caja (ingresos del día) | Extensión | Resumen: efectivo, online, pendientes del día |

---

### 3.4 MÓDULO D — Reservas y Horarios
*(CrossHero base)*

| Feature | Origen | Descripción |
|---|---|---|
| Definición de clases/horarios por Admin | CrossHero base | Nombre de clase, entrenador, días, hora, cupo máximo |
| Reserva de clase por usuario | CrossHero base | Ver disponibilidad + reservar lugar |
| Cancelación de reserva | CrossHero base | Dentro de ventana de tiempo configurable |
| Lista de espera automática | CrossHero base | Si clase llena, usuario entra a espera |
| Notificación de lugar disponible | CrossHero base | Push cuando un lugar se libera |
| Asistencia a clase (check-in en clase) | CrossHero base | Confirmación de presencia en clase reservada |
| Historial de reservas del usuario | CrossHero base | Clases tomadas, canceladas, no asistidas |
| Calendario semanal del gimnasio | CrossHero base | Vista pública de todos los horarios disponibles |

> **Nota:** Las clases grupales con reserva son la forma de operar de CrossHero. GymSmart las mantiene disponibles. La agenda semanal personalizada 1:1 (por entrenador) es la **extensión** para usuarios con entrenador asignado.

---

### 3.5 MÓDULO E — Rutinas, Agenda y Asistente Virtual
*(CrossHero base + Extensión asistente)*

#### E.1 Biblioteca de Ejercicios
| Feature | Origen | Descripción |
|---|---|---|
| CRUD de ejercicios por Entrenador | CrossHero base | Nombre, descripción, grupo muscular |
| Upload de imagen demostrativa | CrossHero base | Foto estática del ejercicio |
| Upload de animación GIF/WebM | Extensión | CrossHero usa imágenes estáticas; GymSmart usa GIF/WebM animado |
| Caché versionada de animaciones | Extensión | URL con `?v=N`, invalida caché al editar |
| Categorización por grupo muscular | CrossHero base | Pecho, Espalda, Piernas, Hombros, Bíceps, Tríceps, Core, etc. |
| Búsqueda y filtrado en biblioteca | CrossHero base | Por nombre y grupo muscular |

#### E.2 Plantillas y Asignación de Rutinas
| Feature | Origen | Descripción |
|---|---|---|
| Creación de plantillas de rutina | CrossHero base | Colección de ejercicios con series, reps, peso sugerido, descanso |
| Asignación de rutina a usuario | CrossHero base | Entrenador vincula plantilla a su alumno |
| Personalización de plantilla por alumno | Extensión | El entrenador ajusta series/pesos según lesiones u objetivos específicos |
| Agenda semanal personalizada (1:1) | Extensión | Entrenador define qué rutina toca cada día para cada usuario |
| Publicación de rutina al usuario | CrossHero base | Rutina disponible en la app del usuario tras publicar |

#### E.3 Asistente Virtual de Entrenamiento (Extensión completa)
| Feature | Origen | Descripción |
|---|---|---|
| Vista de agenda semanal en app usuario | Extensión | Lunes-Domingo con grupo muscular del día |
| Inicio de entrenamiento del día | Extensión | Un toque → lanza el asistente paso a paso |
| Visualización animación del ejercicio | Extensión | GIF/WebM cargado desde caché |
| Contador de series y progreso | Extensión | "Serie 2 de 4" con barra de progreso |
| Peso sugerido por el entrenador | Extensión | Visible en pantalla durante la ejecución |
| Temporizador de descanso automático | Extensión | Cuenta regresiva circular, vibración al terminar |
| Registro de esfuerzo real | Extensión | Usuario ingresa peso real y reps reales por serie |
| Marcado "Entrenamiento Completado" | Extensión | Guarda sesión en historial |
| Historial de sesiones por usuario | Extensión | Visible para el Entrenador en Vista Técnica |
| Progreso gráfico (esfuerzo en el tiempo) | Extensión | Gráfica de peso levantado por ejercicio a lo largo del tiempo |

---

### 3.6 MÓDULO F — Comunicación Interna
*(CrossHero base + extensión observaciones)*

| Feature | Origen | Descripción |
|---|---|---|
| Publicación de anuncios por Admin | CrossHero base | Título, descripción, imagen opcional |
| Feed de anuncios para usuarios | CrossHero base | Visible en pantalla de inicio (banner + lista) |
| Notificación push de nuevo anuncio | CrossHero base | Alerta a todos los usuarios de la instancia |
| Creación de observación con foto | Extensión | Usuario o Entrenador reporta problema con evidencia fotográfica |
| Buzón de observaciones (Admin) | Extensión | Vista global consolidada de todas las observaciones |
| Compresión automática de foto antes de upload | Extensión | Max 2MB, 1080px, comprimido en cliente |

---

### 3.7 MÓDULO G — Reportes y Dashboard
*(CrossHero base + extensiones analíticas)*

| Feature | Origen | Descripción |
|---|---|---|
| Dashboard Admin: asistencia hoy | CrossHero base | Conteo de ingresos del día |
| Dashboard Admin: membresías activas/vencidas | CrossHero base | Resumen del estado del gym |
| Dashboard Admin: ingresos del mes | CrossHero base | Total cobrado + pendientes |
| Reporte de asistencia por período | CrossHero base | Filtro por semana, mes, usuario |
| Reporte de pagos y cobros | CrossHero base | Historial detallado con método de pago |
| Estadísticas de retención de clientes | Extensión | % usuarios que renuevan vs. abandonan |
| Progreso físico del usuario (Admin ve solo operativo) | Extensión | Admin ve estado de membresía, no datos físicos |
| Progreso técnico por usuario (Entrenador) | Extensión | Gráficas de esfuerzo real por ejercicio en el tiempo |

---

### 3.8 MÓDULO H — Notificaciones y Automatización
*(Extensión completa sobre la base de CrossHero)*

| Feature | Origen | Descripción |
|---|---|---|
| Push notifications base | CrossHero base | FCM para mensajes generales |
| Notificación vencimiento membresía (-7 días) | Extensión | Cron job diario |
| Recordatorio diario post-vencimiento | Extensión | Cron job, hasta que pague |
| Alerta de acceso denegado al Admin | Extensión | Push en tiempo real cuando usuario con membresía vencida intenta ingresar |
| Notificación de pago confirmado | Extensión | Push al usuario cuando Admin registra pago o pasarela confirma |
| Notificación de nuevo anuncio | CrossHero base | Push masivo a todos los usuarios de la instancia |
| Notificación de lugar disponible en clase | CrossHero base | Push a lista de espera |

---

## 4. Arquitectura del Sistema

### 4.1 Diagrama de Capas

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENTES (Flutter App)                        │
│  ┌───────────┐  ┌────────────────┐  ┌──────────────────────┐   │
│  │ App Admin │  │  App Entrenador │  │    App Usuario   │   │
│  │  / Caja   │  │                │  │                      │   │
│  └─────┬─────┘  └───────┬────────┘  └──────────┬───────────┘   │
└────────┼────────────────┼──────────────────────┼───────────────┘
         │                │                      │
         └────────────────┼──────────────────────┘
                          │ HTTPS / REST API
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (NestJS)                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  API Gateway + Auth Middleware (JWT + tenant_id guard)   │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │  Auth    │ │ Members  │ │Payments  │ │    Routines      │   │
│  │  Module  │ │ Module   │ │ Module   │ │    Module        │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │Attendance│ │Schedules │ │ Notif.   │ │   Observations   │   │
│  │  Module  │ │ Module   │ │ Module   │ │    Module        │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Prisma ORM (acceso a BD)                    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         │                │                      │
         ▼                ▼                      ▼
┌──────────────┐  ┌───────────────┐  ┌──────────────────────────┐
│  PostgreSQL  │  │  Cloudinary / │  │  Firebase (FCM)           │
│  Multi-tenant│  │  S3 Storage   │  │  Push Notifications       │
│  (tenant_id) │  │  (fotos/GIFs) │  └──────────────────────────┘
└──────────────┘  └───────────────┘
```

### 4.2 Estrategia Multi-tenant

```
Opción elegida: tenant_id en todas las tablas (Row-Level Security)

Ventajas para un SaaS de inicio:
  ✅ Base de datos única (menor costo operativo)
  ✅ Migraciones de schema más simples
  ✅ Escalabilidad horizontal sin complejidad de routing

Reglas de implementación:
  1. TODOS los queries incluyen WHERE tenant_id = :tenantId
  2. Middleware de NestJS extrae tenant_id del JWT en cada request
  3. Ningún endpoint opera sin tenant_id validado
  4. Super-Admin tiene un tenant_id especial ('PLATFORM') para operaciones globales
```

### 4.3 Estructura del Proyecto Flutter (Feature-First)

```
gym_smart_app/
├── lib/
│   ├── core/
│   │   ├── auth/
│   │   │   ├── auth_provider.dart
│   │   │   ├── jwt_service.dart
│   │   │   └── role_guard.dart
│   │   ├── network/
│   │   │   ├── api_client.dart            # Dio + interceptors
│   │   │   ├── tenant_interceptor.dart    # Agrega tenant_id a headers
│   │   │   └── auth_interceptor.dart      # Refresco de JWT automático
│   │   ├── storage/
│   │   │   ├── secure_storage.dart        # JWT (flutter_secure_storage)
│   │   │   └── local_cache.dart           # Hive (rutinas offline)
│   │   ├── theme/
│   │   │   ├── app_theme.dart             # Dark theme principal
│   │   │   ├── colors.dart                # Paleta de colores
│   │   │   └── typography.dart            # Inter font scales
│   │   └── router/
│   │       ├── app_router.dart            # go_router
│   │       └── route_guards.dart          # Guards por rol
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/                      # Repository + API calls
│   │   │   ├── domain/                    # Use cases
│   │   │   └── presentation/             # Screens + providers
│   │   │       ├── login_screen.dart
│   │   │       ├── forgot_password_screen.dart
│   │   │       └── auth_provider.dart
│   │   │
│   │   ├── dashboard/                     # Por rol (Admin / Trainer / Member)
│   │   │
│   │   ├── members/                       # Gestión de usuarios (Admin)
│   │   │   └── presentation/
│   │   │       ├── members_list_screen.dart
│   │   │       ├── member_detail_screen.dart
│   │   │       ├── member_profile_admin_view.dart  # Vista operativa
│   │   │       └── assign_trainer_screen.dart
│   │   │
│   │   ├── profile/                       # Perfiles multi-vista
│   │   │   └── presentation/
│   │   │       ├── gym_profile_screen.dart
│   │   │       ├── trainer_profile_screen.dart
│   │   │       ├── member_private_view.dart
│   │   │       ├── member_social_view.dart
│   │   │       ├── member_technical_view.dart     # Solo entrenador
│   │   │       └── member_physical_view.dart      # Solo usuario
│   │   │
│   │   ├── attendance/
│   │   │   └── presentation/
│   │   │       ├── scanner_screen.dart             # Admin/Caja: escanear
│   │   │       ├── attendance_log_screen.dart      # Log del día
│   │   │       └── qr_member_screen.dart           # Usuario: su QR
│   │   │
│   │   ├── payments/
│   │   │   └── presentation/
│   │   │       ├── membership_status_screen.dart   # Usuario
│   │   │       ├── pay_online_screen.dart          # WebView pasarela
│   │   │       ├── manual_accreditation_screen.dart
│   │   │       ├── register_cash_payment_screen.dart # Caja
│   │   │       └── approve_accreditation_screen.dart # Admin
│   │   │
│   │   ├── schedules/                     # Horarios y reservas (CrossHero)
│   │   │   └── presentation/
│   │   │       ├── schedule_calendar_screen.dart
│   │   │       ├── book_class_screen.dart
│   │   │       └── my_bookings_screen.dart
│   │   │
│   │   ├── routines/
│   │   │   └── presentation/
│   │   │       ├── exercise_library_screen.dart
│   │   │       ├── create_exercise_screen.dart
│   │   │       ├── assign_routine_screen.dart
│   │   │       ├── weekly_agenda_screen.dart       # Usuario: mi agenda
│   │   │       └── workout_assistant_screen.dart   # Asistente virtual
│   │   │
│   │   ├── observations/
│   │   │   └── presentation/
│   │   │       ├── create_observation_screen.dart
│   │   │       └── observations_inbox_screen.dart  # Admin: buzón global
│   │   │
│   │   ├── announcements/
│   │   │   └── presentation/
│   │   │       ├── announcements_feed_screen.dart
│   │   │       └── create_announcement_screen.dart # Admin
│   │   │
│   │   └── reports/
│   │       └── presentation/
│   │           ├── admin_dashboard_screen.dart
│   │           └── trainer_progress_screen.dart
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── gym_button.dart
│   │   │   ├── gym_card.dart
│   │   │   ├── role_badge.dart
│   │   │   ├── membership_status_chip.dart
│   │   │   ├── exercise_gif_player.dart        # Caché versionada
│   │   │   ├── rest_timer_widget.dart          # Temporizador circular
│   │   │   └── qr_display_widget.dart
│   │   └── models/
│   │       ├── user.dart
│   │       ├── membership.dart
│   │       ├── routine.dart
│   │       └── exercise.dart
│   │
│   └── main.dart
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
└── pubspec.yaml
```

---

## 5. Modelo de Datos Completo (Prisma Schema)

```prisma
// ─── MULTI-TENANT ────────────────────────────────────────────────
model Tenant {
  id              String   @id @default(uuid())
  nombre          String
  logo_url        String?
  direccion       String?
  telefono        String?
  horario         String?
  descripcion     String?
  redes_sociales  Json?
  plan_saas       String   @default("BASIC")  // BASIC | PRO | ENTERPRISE
  activo          Boolean  @default(true)
  created_at      DateTime @default(now())
  usuarios        User[]
  memberships     Membership[]
  attendances     Attendance[]
  exercises       Exercise[]
  schedules       Schedule[]
  announcements   Announcement[]
  observations    Observation[]
}

// ─── USUARIOS ────────────────────────────────────────────────────
model User {
  id              String   @id @default(uuid())
  tenant_id       String
  tenant          Tenant   @relation(fields: [tenant_id], references: [id])
  email           String
  password_hash   String
  rol             Role     @default(MEMBER)
  nombre_completo String
  dni             String?
  celular         String?
  foto_url        String?
  estado          UserState @default(PENDING)
  refresh_token   String?
  created_at      DateTime @default(now())
  updated_at      DateTime @updatedAt

  // Relaciones según rol
  trainer_profile    TrainerProfile?
  member_profile     MemberProfile?
  memberships        Membership[]
  payments_registered Payment[] @relation("RegisteredBy")
  attendances        Attendance[]

  @@unique([tenant_id, email])
  @@unique([tenant_id, dni])
}

enum Role {
  SUPER_ADMIN
  ADMIN
  CAJA
  TRAINER
  MEMBER
}

enum UserState {
  ACTIVE
  INACTIVE
  PENDING
  SUSPENDED
}

// ─── PERFILES ────────────────────────────────────────────────────
model TrainerProfile {
  id              String  @id @default(uuid())
  user_id         String  @unique
  user            User    @relation(fields: [user_id], references: [id])
  especialidad    String?
  anos_experiencia Int?
  certificaciones String?
  biografia       String?
  // Relaciones
  assigned_members MemberProfile[]
  exercises       Exercise[]
  routine_assignments RoutineAssignment[]
}

model MemberProfile {
  id                  String   @id @default(uuid())
  user_id             String   @unique
  user                User     @relation(fields: [user_id], references: [id])
  trainer_id          String?
  trainer             TrainerProfile? @relation(fields: [trainer_id], references: [id])

  // Vista Social
  nickname            String?
  modo_activo         Boolean  @default(true)

  // Vista Técnica (solo entrenador ve)
  peso_kg             Float?
  altura_cm           Float?
  objetivo            String?
  lesiones            String?

  // Vista Física (solo el usuario ve)
  medidas_json        Json?    // { cintura: 80, cadera: 95, pecho: 100 }
  fotos_comparativas  String[] // URLs de fotos Antes/Después

  workout_sessions    WorkoutSession[]
  routine_assignments RoutineAssignment[]
}

// ─── MEMBRESÍAS Y PAGOS ──────────────────────────────────────────
model Membership {
  id              String          @id @default(uuid())
  tenant_id       String
  tenant          Tenant          @relation(fields: [tenant_id], references: [id])
  user_id         String
  user            User            @relation(fields: [user_id], references: [id])
  plan_nombre     String          // "Mensual", "Trimestral"
  duracion_dias   Int             // 30, 90, 365
  monto           Float
  estado          MembershipState @default(PENDING)
  fecha_inicio    DateTime?
  fecha_vencimiento DateTime?
  payments        Payment[]
  created_at      DateTime        @default(now())
  updated_at      DateTime        @updatedAt
}

enum MembershipState {
  ACTIVE
  EXPIRED
  PENDING
  GRACE      // Dentro del día de gracia
  SUSPENDED
}

model Payment {
  id                  String        @id @default(uuid())
  tenant_id           String
  membership_id       String
  membership          Membership    @relation(fields: [membership_id], references: [id])
  registrado_por_id   String?
  registrado_por      User?         @relation("RegisteredBy", fields: [registrado_por_id], references: [id])
  monto               Float
  metodo              PaymentMethod
  estado              PaymentState  @default(APPROVED)
  comprobante_url     String?       // Para acreditación manual
  referencia_externa  String?       // ID de transacción de la pasarela
  timestamp           DateTime      @default(now())
}

enum PaymentMethod {
  CASH
  GATEWAY      // Culqi / Izipay
  MANUAL_YAPE  // Acreditación manual Yape
  MANUAL_PLIN  // Acreditación manual Plin
}

enum PaymentState {
  PENDING
  APPROVED
  REJECTED
}

// ─── ASISTENCIA ──────────────────────────────────────────────────
model Attendance {
  id            String   @id @default(uuid())
  tenant_id     String
  tenant        Tenant   @relation(fields: [tenant_id], references: [id])
  user_id       String
  user          User     @relation(fields: [user_id], references: [id])
  timestamp     DateTime @default(now())
  metodo_acceso AccessMethod @default(QR_ADMIN)
}

enum AccessMethod {
  QR_AUTONOMOUS  // Cámara fija
  QR_ADMIN       // Admin escaneó desde celular
  MANUAL_ADMIN   // Admin registró manualmente
}

// ─── RESERVAS Y HORARIOS (CrossHero) ─────────────────────────────
model Schedule {
  id              String   @id @default(uuid())
  tenant_id       String
  tenant          Tenant   @relation(fields: [tenant_id], references: [id])
  trainer_id      String
  nombre_clase    String
  descripcion     String?
  dia_semana      Int[]    // [1,3,5] = Lunes, Miércoles, Viernes
  hora_inicio     String   // "08:00"
  hora_fin        String   // "09:00"
  cupo_maximo     Int
  activo          Boolean  @default(true)
  bookings        Booking[]
}

model Booking {
  id          String        @id @default(uuid())
  schedule_id String
  schedule    Schedule      @relation(fields: [schedule_id], references: [id])
  user_id     String
  fecha       DateTime      // Fecha específica de la clase
  estado      BookingState  @default(CONFIRMED)
  created_at  DateTime      @default(now())
}

enum BookingState {
  CONFIRMED
  CANCELLED
  WAITLIST
  ATTENDED
}

// ─── EJERCICIOS Y RUTINAS ────────────────────────────────────────
model Exercise {
  id                String   @id @default(uuid())
  tenant_id         String
  tenant            Tenant   @relation(fields: [tenant_id], references: [id])
  trainer_id        String
  trainer           TrainerProfile @relation(fields: [trainer_id], references: [id])
  nombre            String
  descripcion       String?
  grupo_muscular    String
  imagen_url        String?
  animacion_url     String?  // GIF o WebM
  animacion_version Int      @default(1)  // Incrementar para invalidar caché
  activo            Boolean  @default(true)
  created_at        DateTime @default(now())
}

model RoutineTemplate {
  id              String    @id @default(uuid())
  tenant_id       String
  trainer_id      String
  nombre          String
  descripcion     String?
  ejercicios      RoutineExercise[]
  assignments     RoutineAssignment[]
  created_at      DateTime  @default(now())
}

model RoutineExercise {
  id                String          @id @default(uuid())
  template_id       String
  template          RoutineTemplate @relation(fields: [template_id], references: [id])
  exercise_id       String
  orden             Int
  series            Int
  repeticiones      Int
  peso_sugerido_kg  Float?
  descanso_seg      Int             @default(60)
}

model RoutineAssignment {
  id              String          @id @default(uuid())
  tenant_id       String
  member_id       String
  member          MemberProfile   @relation(fields: [member_id], references: [id])
  trainer_id      String
  trainer         TrainerProfile  @relation(fields: [trainer_id], references: [id])
  template_id     String
  template        RoutineTemplate @relation(fields: [template_id], references: [id])
  agenda_semanal  Json            // { "MON": "template_id", "WED": "template_id", ... }
  publicada       Boolean         @default(false)
  created_at      DateTime        @default(now())
}

model WorkoutSession {
  id              String        @id @default(uuid())
  tenant_id       String
  member_id       String
  member          MemberProfile @relation(fields: [member_id], references: [id])
  template_id     String
  fecha           DateTime      @default(now())
  estado          SessionState  @default(IN_PROGRESS)
  series_log      SeriesLog[]
}

enum SessionState {
  IN_PROGRESS
  COMPLETED
  SKIPPED
}

model SeriesLog {
  id              String         @id @default(uuid())
  session_id      String
  session         WorkoutSession @relation(fields: [session_id], references: [id])
  exercise_id     String
  serie_numero    Int
  peso_real_kg    Float?
  reps_reales     Int?
  completada      Boolean        @default(true)
  timestamp       DateTime       @default(now())
}

// ─── OBSERVACIONES Y ANUNCIOS ────────────────────────────────────
model Observation {
  id          String   @id @default(uuid())
  tenant_id   String
  tenant      Tenant   @relation(fields: [tenant_id], references: [id])
  author_id   String
  autor_rol   Role
  texto       String
  foto_url    String?
  revisado    Boolean  @default(false)
  created_at  DateTime @default(now())
}

model Announcement {
  id          String   @id @default(uuid())
  tenant_id   String
  tenant      Tenant   @relation(fields: [tenant_id], references: [id])
  autor_id    String
  titulo      String
  descripcion String
  imagen_url  String?
  activo      Boolean  @default(true)
  created_at  DateTime @default(now())
}
```

---

## 6. APIs REST — Endpoints Principales

### Auth
```
POST   /auth/login                     # Login, retorna JWT + refreshToken
POST   /auth/refresh                   # Renueva JWT usando refreshToken
POST   /auth/logout                    # Invalida token en servidor
POST   /auth/forgot-password           # Envía email de recuperación
POST   /auth/reset-password            # Cambia contraseña con token del email
POST   /auth/register                  # Registro de usuario (auto)
```

### Users / Members
```
GET    /users                          # Lista usuarios (paginada, filtros)
GET    /users/:id                      # Detalle de usuario
PATCH  /users/:id                      # Actualizar perfil
DELETE /users/:id                      # Baja lógica (soft delete)
POST   /users/:id/assign-trainer       # Asignar entrenador a usuario
GET    /users/:id/profile/technical    # Vista técnica (solo trainer asignado)
GET    /users/:id/profile/physical     # Vista física (solo el propio usuario)
```

### Memberships & Payments
```
GET    /memberships/:userId            # Membresía activa del usuario
POST   /memberships                    # Crear nueva membresía
PATCH  /memberships/:id/status         # Actualizar estado manualmente
POST   /payments/cash                  # Registrar pago en efectivo (Caja)
POST   /payments/gateway/create        # Generar QR/link de cobro (Culqi/Izipay)
POST   /payments/gateway/webhook       # Webhook de confirmación de pasarela
POST   /payments/manual/upload         # Usuario sube screenshot
PATCH  /payments/:id/approve           # Admin aprueba acreditación manual
PATCH  /payments/:id/reject            # Admin rechaza acreditación
GET    /payments/history/:userId       # Historial de pagos
```

### Attendance
```
POST   /attendance/scan                # Validar QR/DNI, registrar ingreso
GET    /attendance/today               # Log de asistencia del día
GET    /attendance/member/:userId      # Historial de asistencia del usuario
GET    /attendance/stats               # Estadísticas (por período)
GET    /members/:id/qr                 # Genera / retorna QR dinámico del usuario
```

### Schedules & Bookings (CrossHero)
```
GET    /schedules                      # Horarios de clases del gimnasio
POST   /schedules                      # Crear clase (Admin)
PUT    /schedules/:id                  # Editar clase
DELETE /schedules/:id                  # Eliminar clase
POST   /bookings                       # Reservar clase (usuario)
DELETE /bookings/:id                   # Cancelar reserva
GET    /bookings/my                    # Mis reservas (usuario)
```

### Exercises & Routines
```
GET    /exercises                      # Biblioteca de ejercicios
POST   /exercises                      # Crear ejercicio (con upload animación)
PUT    /exercises/:id                  # Editar + incrementar versión caché
DELETE /exercises/:id                  # Eliminar (soft)
POST   /routines/templates             # Crear plantilla de rutina
GET    /routines/templates             # Listar plantillas del entrenador
PUT    /routines/templates/:id         # Editar plantilla
POST   /routines/assign                # Asignar rutina + agenda a usuario
GET    /routines/my-agenda             # Agenda semanal del usuario
POST   /routines/sessions/start        # Iniciar sesión de entrenamiento
POST   /routines/sessions/:id/log      # Registrar serie (esfuerzo real)
POST   /routines/sessions/:id/complete # Marcar sesión como completada
GET    /routines/sessions/:userId      # Historial de sesiones (entrenador)
```

### Observations & Announcements
```
POST   /observations                   # Crear observación (con foto)
GET    /observations                   # Buzón global (solo Admin)
PATCH  /observations/:id/reviewed      # Marcar como revisada
POST   /announcements                  # Publicar anuncio
GET    /announcements                  # Feed de anuncios de la instancia
DELETE /announcements/:id              # Eliminar anuncio
```

---

## 7. Stack Tecnológico Completo

### Flutter (App Móvil)
```yaml
sdk: '>=3.0.0 <4.0.0'

dependencies:
  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^13.2.0

  # Networking
  dio: ^5.4.3
  retrofit: ^4.1.0

  # Seguridad & Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  hive_flutter: ^1.1.0

  # QR & Cámara
  mobile_scanner: ^4.0.1
  qr_flutter: ^4.1.0
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0

  # Media & Cache
  cached_network_image: ^3.3.1
  flutter_cache_manager: ^3.3.1

  # Notificaciones
  firebase_messaging: ^14.7.15
  flutter_local_notifications: ^17.0.0

  # Pagos
  webview_flutter: ^4.7.0

  # UI / Gráficas
  fl_chart: ^0.67.0
  shimmer: ^3.0.0
  lottie: ^3.1.0
  percent_indicator: ^4.2.3
  intl: ^0.19.0

  # Dev Tools
  build_runner: ^2.4.9
  retrofit_generator: ^8.1.0
  hive_generator: ^2.0.1
```

### NestJS (Backend)
```json
{
  "dependencies": {
    "@nestjs/core": "^10.0.0",
    "@nestjs/common": "^10.0.0",
    "@nestjs/jwt": "^10.2.0",
    "@nestjs/passport": "^10.0.3",
    "@nestjs/schedule": "^4.0.2",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/config": "^3.2.0",
    "passport": "^0.7.0",
    "passport-jwt": "^4.0.1",
    "@prisma/client": "^5.14.0",
    "bcryptjs": "^2.4.3",
    "firebase-admin": "^12.1.1",
    "axios": "^1.7.2",
    "multer": "^1.4.5",
    "sharp": "^0.33.4",
    "nodemailer": "^6.9.13",
    "class-validator": "^0.14.1",
    "class-transformer": "^0.5.1"
  }
}
```

---

## 8. Plan de Sprints Detallado

### 📦 Sprint 0 — Infraestructura y Setup (Semana 0)

**Backend:**
- [ ] Inicializar proyecto NestJS con arquitectura modular
- [ ] Configurar Prisma + PostgreSQL (schema inicial)
- [ ] Configurar variables de entorno (.env, ConfigModule)
- [ ] Middleware global: `tenant_id` extractor del JWT
- [ ] Configurar Firebase Admin SDK
- [ ] Setup Docker Compose (postgres + app backend)
- [ ] CI/CD básico (GitHub Actions → build + lint)

**Flutter:**
- [ ] Inicializar proyecto Flutter con clean architecture
- [ ] Configurar `go_router` con estructura de rutas por rol
- [ ] Configurar Riverpod + providers base
- [ ] Configurar `flutter_secure_storage` para JWT
- [ ] Configurar Dio + interceptors (auth + tenant)
- [ ] Setup Firebase para FCM
- [ ] Primer build funcional en dispositivo físico Android

---

### 📦 Sprint 1 — Auth + Multi-tenant (Semanas 1-2)
*Equivalente CrossHero: módulo de autenticación*

**Backend:**
- [ ] Módulo Auth: login, registro, logout, JWT refresh
- [ ] Guard global de tenant + rol (`@Roles()`, `@TenantId()`)
- [ ] Módulo Tenants: CRUD de instancias de gimnasio (Super-Admin)
- [ ] Endpoint `/auth/forgot-password` + `/auth/reset-password`
- [ ] Token blacklist en memoria (Redis o DB)

**Flutter:**
- [ ] Pantalla Login (email + contraseña + "Recordarme")
- [ ] Pantalla Recuperar contraseña
- [ ] AuthProvider con Riverpod (estado de sesión global)
- [ ] Routing condicional post-login (redirige según `rol`)
- [ ] Logout con invalidación de token en servidor
- [ ] Scaffold base de home para cada rol (Admin / Trainer / Member / Caja)

---

### 📦 Sprint 2 — Perfiles y Gestión de Usuarios (Semanas 3-4)
*Equivalente CrossHero: gestión de usuarios y perfiles*

**Backend:**
- [ ] Módulo Users: CRUD completo con guards de rol
- [ ] Endpoint Vista Técnica (solo entrenador asignado)
- [ ] Endpoint Vista Física (solo propio usuario)
- [ ] Validación DNI único por tenant
- [ ] Upload de foto de perfil (Cloudinary/S3 + compresión con Sharp)
- [ ] Asignación Entrenador → Usuario
- [ ] Baja lógica (soft delete, campo `estado = INACTIVE`)

**Flutter:**
- [ ] Pantalla: Lista de usuarios (Admin) con búsqueda + filtros
- [ ] Pantalla: Detalle usuario → Vista Operativa (Admin)
- [ ] Pantalla: Vista Técnica (Entrenador — solo sus asignados)
- [ ] Pantalla: Perfil propio del Usuario (multi-tab: Privado / Social / Físico)
- [ ] Pantalla: Perfil Empresa/Gimnasio (Admin edita, todos ven)
- [ ] Pantalla: Perfil Entrenador (edición propia)
- [ ] Pantalla: Asignar entrenador (Admin)
- [ ] Flujo: Registro de usuario (auto + manual Admin)
- [ ] Flujo: Dar de baja con confirmación

---

### 📦 Sprint 3 — Pagos y Control de Asistencia (Semanas 5-7)
*Equivalente CrossHero: membresías + pagos + control de acceso*

**Backend:**
- [ ] Módulo Memberships: CRUD, estados, cálculo de vencimiento
- [ ] Módulo Payments: efectivo, gateway, webhook Culqi/Izipay, acreditación manual
- [ ] Integración Culqi o Izipay: generación de QR/link de cobro
- [ ] Webhook handler de confirmación de pago (actualiza membresía automáticamente)
- [ ] Módulo Attendance: validar QR, registrar ingreso, log diario
- [ ] Endpoint: Generar QR dinámico del usuario (`member_id + tenant_id + ts`)
- [ ] Endpoint: Soporte cámara fija (recibe identificador externo)
- [ ] Margen de gracia de 1 día (configurable por tenant)
- [ ] Cron job: notificación 7 días antes del vencimiento
- [ ] Cron job: recordatorio diario post-vencimiento
- [ ] Push FCM: alerta a Admin cuando acceso denegado

**Flutter:**
- [ ] Pantalla: Escáner QR/DNI fullscreen (Admin/Caja) — `mobile_scanner`
- [ ] Feedback visual: Verde (acceso concedido) / Rojo (denegado) con animación
- [ ] Pantalla: Log de ingresos del día (Admin/Caja)
- [ ] Pantalla: QR dinámico del usuario (fullscreen, `qr_flutter`)
- [ ] Pantalla: Estado de membresía (Usuario) con progress bar días restantes
- [ ] Pantalla: Pagar online → WebView pasarela (Culqi/Izipay QR o link)
- [ ] Pantalla: Acreditar pago manual (upload screenshot, `image_picker`)
- [ ] Pantalla: Registrar pago efectivo (Admin/Caja)
- [ ] Pantalla: Aprobar/rechazar acreditación manual (Admin)
- [ ] Configuración FCM y push notifications

---

### 📦 Sprint 4 — Reservas y Horarios (Semana 8)
*CrossHero base: horarios y reservas de clases*

**Backend:**
- [ ] Módulo Schedules: CRUD de clases con cupo y horario
- [ ] Módulo Bookings: reservar, cancelar, lista de espera automática
- [ ] Lógica de cupo: si clase llena → entra a lista de espera
- [ ] Notificación push cuando se libera un lugar de lista de espera
- [ ] Registro de asistencia a clase (check-in en clase específica)

**Flutter:**
- [ ] Pantalla: Calendario semanal del gimnasio (todos los horarios)
- [ ] Pantalla: Reservar clase (ver disponibilidad + confirmar)
- [ ] Pantalla: Mis reservas (historial + próximas)
- [ ] Pantalla: Gestión de clases (Admin: crear/editar/eliminar)
- [ ] Push notification: lugar disponible en lista de espera

---

### 📦 Sprint 5 — Rutinas, Biblioteca y Asistente Virtual (Semanas 9-11)
*CrossHero base (biblioteca + asignación) + Extensión (asistente virtual)*

**Backend:**
- [ ] Módulo Exercises: CRUD con upload GIF/WebM (Cloudinary/S3), versionado de caché
- [ ] Módulo RoutineTemplates: CRUD con lista de ejercicios + configuración por serie
- [ ] Módulo RoutineAssignments: asignar plantilla + agenda semanal personalizada
- [ ] Módulo WorkoutSessions: iniciar sesión, log de series, completar sesión
- [ ] Endpoint: Historial de sesiones por usuario (para entrenador)
- [ ] Endpoint: Agenda semanal del usuario (qué rutina toca hoy)

**Flutter:**
- [ ] Pantalla: Biblioteca de ejercicios (Entrenador) — lista con thumbnail GIF
- [ ] Pantalla: Crear/Editar ejercicio (Entrenador) — upload GIF/WebM con `flutter_image_compress`
- [ ] `ExerciseGifPlayer`: widget con caché versionada (`flutter_cache_manager`)
- [ ] Pantalla: Crear plantilla de rutina (Entrenador) — drag & drop orden de ejercicios
- [ ] Pantalla: Asignar rutina a usuario + configurar agenda semanal
- [ ] Pantalla: Mi Agenda Semanal (Usuario) — vista Lunes-Domingo con rutina del día
- [ ] Pantalla: **Asistente Virtual** (Usuario):
  - [ ] Header: nombre rutina + N ejercicios
  - [ ] GIF del ejercicio en tiempo real (cacheado)
  - [ ] Indicador serie actual: "Serie 2 de 4"
  - [ ] Peso sugerido por el entrenador
  - [ ] Botón "Serie Completada" → activa temporizador
  - [ ] `RestTimerWidget`: temporizador circular cuenta regresiva con vibración al llegar a 0
  - [ ] Botón "Ajustar Esfuerzo" → modal para ingresar peso real + reps reales
  - [ ] Avance automático al siguiente ejercicio / serie
  - [ ] Pantalla de finalización "¡Entrenamiento Completado! 💪"
- [ ] Pantalla: Vista Técnica Entrenador (historial de sesiones + gráfica de progreso)
- [ ] Gráfica de progreso por ejercicio (`fl_chart`)

---

### 📦 Sprint 6 — Observaciones, Anuncios y Reportes (Semanas 12-13)
*CrossHero base (anuncios) + Extensiones (observaciones + dashboard)*

**Backend:**
- [ ] Módulo Observations: crear con foto (upload S3), buzón global del Admin
- [ ] Módulo Announcements: crear/publicar/eliminar, feed por instancia
- [ ] Módulo Reports: estadísticas de asistencia, ingresos, retención
- [ ] Endpoint: Dashboard Admin (resumen en tiempo real)

**Flutter:**
- [ ] Pantalla: Crear observación (texto + foto, compresión automática antes de upload)
- [ ] Pantalla: Buzón de Observaciones (Admin) — lista con miniaturas, fullscreen en tap
- [ ] Pantalla: Crear anuncio (Admin) — título + descripción + imagen opcional
- [ ] Pantalla: Feed de anuncios (Usuario/Entrenador) — banner destacado + lista
- [ ] Pantalla: Dashboard Admin — cards con métricas en tiempo real
- [ ] Pantalla: Reportes (gráficas de asistencia y pagos por período)

---

### 📦 Sprint 7 — Polish, Testing y Deploy (Semanas 14-15)

- [ ] Dark theme finalizado con todos los componentes
- [ ] Shimmer loading en todas las listas y cards
- [ ] Mensajes de error y estados vacíos diseñados
- [ ] Validaciones de formularios (DNI peruano 8 dígitos, email, celular)
- [ ] Compresión de imágenes verificada < 2MB en todos los uploads
- [ ] Testing unitario: use cases y repositories
- [ ] Testing de widget: pantallas críticas (login, escáner, asistente)
- [ ] Testing de integración: flujo completo ingreso → pago → entrenamiento
- [ ] Testing en dispositivos Android reales (gama baja y media)
- [ ] Optimización de performance (splash screen, lazy loading de rutas)
- [ ] Build APK de producción + firma
- [ ] Deploy backend en VPS / Railway / Render
- [ ] Configuración de dominio y SSL

---

## 9. Comparativa CrossHero vs GymSmart

| Módulo | CrossHero | GymSmart | Diferencia |
|---|---|---|---|
| Auth y roles | ✅ Multi-rol + JWT | ✅ Igual + sub-rol Caja | Se agrega rol `CAJA` con permisos limitados |
| Gestión de miembros | ✅ Completo | ✅ + Vista multi-rol (4 vistas por usuario) | CrossHero no tiene segmentación tan granular de privacidad |
| Membresías | ✅ Planes y estados | ✅ + Gracia 1 día + alertas automáticas | CrossHero tiene alertas básicas |
| Pagos | ✅ Stripe (tarjetas) | ✅ Culqi/Izipay (Yape/Plin) + acreditación manual | Pasarelas del mercado peruano |
| Control de acceso | ✅ Check-in app | ✅ + QR dinámico usuario + cámara fija hardware | CrossHero no tiene QR generado por el usuario |
| Reservas/Horarios | ✅ Clases grupales con cupo y lista de espera | ✅ Igual | Paridad completa |
| Biblioteca ejercicios | ✅ Imagen estática | ✅ + GIF/WebM animado + caché versionada | CrossHero no tiene animaciones |
| Asignación rutinas | ✅ Asignación básica | ✅ + Agenda semanal personalizada 1:1 | CrossHero no tiene agenda día por día |
| Asistente virtual | ❌ No tiene | ✅ GIF + temporizador + esfuerzo real | Funcionalidad nueva completa |
| Historial esfuerzo | ❌ No tiene | ✅ Series por sesión + gráficas de progreso | Funcionalidad nueva completa |
| Observaciones | ❌ No tiene | ✅ Con foto + buzón Admin | Funcionalidad nueva completa |
| Anuncios/Feed | ✅ Básico | ✅ + Push notification masiva + imagen | Extensión del módulo base |
| Reportes | ✅ Básicos | ✅ + Retención + progreso técnico | Extensión con analítica adicional |
| Multi-tenant | ✅ Por organización | ✅ tenant_id en todas las tablas | Misma estrategia, implementación propia |

---

## 10. Checklist de Pantallas — Verificación de Completitud

### Admin / Caja
- [ ] Login y recuperación de contraseña
- [ ] Dashboard principal (métricas en tiempo real)
- [ ] Lista de usuarios (búsqueda + filtros)
- [ ] Detalle usuario (Vista Operativa)
- [ ] Asignar entrenador a usuario
- [ ] Dar de baja usuario (soft delete)
- [ ] Escáner QR/DNI de ingreso
- [ ] Log de asistencia del día
- [ ] Registrar pago en efectivo
- [ ] Aprobar/rechazar acreditación manual
- [ ] Gestión de clases/horarios (CRUD)
- [ ] Buzón de observaciones (global)
- [ ] Crear y publicar anuncio
- [ ] Configuración perfil del gimnasio
- [ ] Reportes de asistencia y pagos

### Entrenador
- [ ] Lista de usuarios asignados
- [ ] Vista Técnica de usuario
- [ ] Historial de sesiones del usuario + gráfica progreso
- [ ] Biblioteca de ejercicios (lista + thumbnails)
- [ ] Crear/editar ejercicio (upload GIF/WebM)
- [ ] Crear/editar plantilla de rutina
- [ ] Asignar rutina + agenda semanal a usuario
- [ ] Crear observación (texto + foto)
- [ ] Feed de anuncios
- [ ] Perfil profesional (edición)

### Usuario
- [ ] Home con feed de anuncios
- [ ] Agenda semanal personalizada
- [ ] Asistente virtual de entrenamiento (GIF + temporizador + esfuerzo real)
- [ ] Pantalla de finalización de entrenamiento
- [ ] Estado de membresía (días restantes + progress bar)
- [ ] Pagar online (WebView pasarela)
- [ ] Acreditar pago manual (upload screenshot)
- [ ] QR dinámico de acceso (fullscreen)
- [ ] Calendario de clases grupales + reservar
- [ ] Mis reservas
- [ ] Crear observación
- [ ] Perfil: datos privados
- [ ] Perfil: vista social (toggle Activo/Inactivo)
- [ ] Perfil: vista física (fotos A/D, medidas)
