# Contexto de la app SaaaS GYM

## Resumen general

Este workspace contiene dos superficies principales del producto:

1. Un prototipo web de alta fidelidad en `sas_Gym_high/`.
2. Una app Flutter en `flutter_app/` que porta las vistas y la lógica de roles.

Es un producto **SaaS multi-inquilino**: una instancia aislada por gimnasio.
El sistema define **5 roles**:

| Rol | Descripción |
|---|---|
| **Super Administrador** | Gestiona la plataforma SaaS completa: creación de gimnasios e instancias multi-tenant. |
| **Administrador** | Administra la operación completa del gimnasio: miembros, pagos, anuncios, productos y auditoría. |
| **Caja** | Realiza operaciones limitadas de cobro, asistencia y validación de ingreso. |
| **Entrenador** | Gestiona rutinas, ejercicios, seguimiento y progreso de los miembros asignados. |
| **Miembro** | Usuario final del gimnasio que utiliza rutinas, registra progreso y administra su membresía. |

Notas de diseño:

- Caja y Admin **no son equivalentes**: Caja tiene operación limitada y logs de
  solo lectura; Admin conserva gestión total, cuentas de caja y auditoría global.
- El **Super Administrador es asimétrico entre plataformas**: en **web** tiene un
  back-office SaaS completo (gimnasios, planes); en **móvil** su vista es mínima
  — únicamente listar los clientes (gimnasios) y si están activos o no.
- Los otros 4 roles (Admin, Caja, Entrenador, Miembro) son **consistentes en web
  y móvil**.

## Estructura del workspace

- `docker-compose.yml`: sirve el prototipo web desde Nginx.
- `sas_Gym_high/`: prototipo web original en HTML, CSS, React/Babel.
- `flutter_app/`: port en Flutter con vistas por rol, datos mock y despliegue propio.
- `mockups_section.md`: notas de mockups y secciones de diseño.
- `planificacion.md`: planificación general.
- `planificacion_designthinking.md`: planificación de diseño / design thinking.

## Prototipo web (`sas_Gym_high`)

### Entrada y carga

- `index.html` carga los scripts del prototipo y ya incluye `data.jsx` antes de las pantallas de rol.
- `app.jsx` contiene el selector principal de roles y el panel de tweaks.
- `data.jsx` centraliza datos compartidos para evitar depender de variables accidentales del scope global. Expone `PRODUCTS` y `ALL_MEMBERS` en `window` y se carga antes de `member/trainer/admin/caja`.

### Roles en web

- `member.jsx`: experiencia del socio.
- `trainer.jsx`: experiencia del entrenador.
- `caja.jsx`: operación limitada de caja.
- `admin.jsx`: panel administrativo completo.

### Estado funcional importante

- Caja y Admin usan datos compartidos explícitos.
- Caja expone cobros, asistencia, ventas, productos, usuarios con baja lógica y logs de solo lectura.
- Admin expone CRUD total, cuentas de caja, productos y auditoría global.

## App Flutter (`flutter_app`)

### Objetivo

La app Flutter es un port funcional del prototipo web, con foco en:

- Mantener los cuatro roles.
- Separar Caja de Admin de forma clara.
- Tener una base de UI reutilizable.
- Poder correr en Windows y en web.
- Tener preview por Docker en `http://localhost:8282`.

### Archivos clave

- `lib/main.dart`: punto de entrada; ejecuta `runApp(SasGymApp())`.
- `lib/app.dart`: shell principal de la app y selector de roles.
- `lib/theme/app_theme.dart`: tema Material 3 (esquema claro, fondo crema, semilla `0xFF0E0E10`).
- `lib/models/gym_models.dart`: modelos compartidos y enums de roles.
- `lib/data/gym_seed.dart`: datos mock de todas las vistas.
- `lib/widgets/app_shell.dart`: componentes visuales reutilizables.
- `lib/screens/member_screen.dart`: vista del usuario.
- `lib/screens/trainer_screen.dart`: vista del entrenador.
- `lib/screens/cashier_screen.dart`: vista de caja con navegación interna.
- `lib/screens/admin_screen.dart`: vista de admin con navegación interna.

### Diseño de roles en Flutter

#### Usuario

- Home con hero card, métricas, agenda semanal, ejercicios, anuncios y progreso.

#### Entrenador

- Panel con miembros asignados, librería de ejercicios, progreso y estadísticas mini.

#### Caja

- Inicio con turno activo y resumen del turno.
- Escaneo de asistencia.
- Cobro rápido.
- Ventas del turno.
- Más opciones con catálogo y logs.
- Logs de solo lectura.
- Baja lógica de usuarios.
- Operación limitada frente a Admin.

#### Admin

- Dashboard principal.
- Usuarios con gestión total.
- Escáner administrativo.
- Cuentas de caja.
- Productos con CRUD total.
- Auditoría global.

### Componentes compartidos

`app_shell.dart` contiene helpers reutilizables para no repetir UI:

- `RoleSurface`
- `RoleTabs`
- `SectionHeader`
- `MetricTile`
- `ActionTile`
- `StatusPill`
- `LogTile`
- `RoleNavBar`
- `RoleNavItem`

## Datos y modelos

### Modelos principales

`gym_models.dart` define:

- `GymRole`
- `RolePalette`
- `MetricItem`
- `WorkoutDay`
- `ExerciseItem`
- `Announcement`
- `MemberRecord`
- `ProductItem`
- `AuditEntry`
- `CashierAccount`
- `ShiftWindow`

### Datos mock principales

`gym_seed.dart` contiene:

- Paletas visuales por rol.
- Métricas de usuario, entrenador, caja y admin.
- Semana de entrenamiento y lista de ejercicios.
- Anuncios del gimnasio.
- Lista de miembros para entrenador y admin.
- Catálogo de productos.
- Cuentas de caja.
- Logs de caja y auditoría global.
- Ventana de turno activa de caja.

## Despliegue y contenedores

### Hub de navegación (web)

- `docker-compose.yml` (raíz) levanta Nginx en `http://localhost:8282`.
- Sirve el **hub de navegación** (`index.html` de la raíz): desde ahí se entra
  a `sas_Gym_high/` (app móvil) y `crosshero_web_high/` (panel web admin).
- Monta solo el hub, los dos prototipos y los `.md` de documentación — **no**
  expone `crosshero-gym/` (con `.env`, credenciales y backups) ni el resto del
  workspace.
- Cambiar los volúmenes exige recrear el contenedor: `docker-compose up -d`
  (Compose detecta el cambio y recrea `sas_gym_frontend`).

### Flutter

- `flutter_app/Dockerfile` compila Flutter web y sirve el resultado con Nginx.
- `flutter_app/docker-compose.yml` publica la app en `http://localhost:8282`.

### Conflicto de puerto (importante)

Los dos `docker-compose.yml` mapean el mismo puerto del host (`8282:80`):

- `docker-compose.yml` (raíz) → prototipo web.
- `flutter_app/docker-compose.yml` → app Flutter.

No pueden levantarse a la vez. Hay que correr **uno u otro**, o cambiar el
puerto del host en uno de los archivos si se quieren ambos en paralelo.

### Comandos útiles

Desde la raíz del workspace:

```powershell
docker-compose up -d
```

Desde `flutter_app/`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter run -d chrome
docker compose up --build -d
```

## Validación realizada

Verificado en sesiones previas (no re-ejecutado en la última revisión del contexto):

- `flutter analyze` pasaba sin errores.
- `flutter test` pasaba (`test/widget_test.dart`).
- El prototipo web sigue cargando después de separar los datos compartidos.
- El contenedor de la web (`docker-compose.yml` raíz, Nginx) expone el diseño en el puerto 8282.

Sin verificar todavía:

- Build del contenedor Flutter. `flutter_app/Dockerfile` usa la imagen
  `ghcr.io/cirruslabs/flutter:3.24.5`, pero `pubspec.yaml` exige Dart
  `sdk: ^3.12.0`. El Flutter local instalado es 3.44.0. La imagen 3.24.5
  trae un Dart anterior a 3.12.0, así que `flutter pub get` dentro del
  contenedor probablemente falle: hay que subir la etiqueta de la imagen
  base a una que cumpla la restricción del SDK antes de confiar en ese build.

## Estado actual

La app ya está en una base funcional y compilable. Lo más importante del estado actual es:

- Caja y Admin están separados funcionalmente.
- Flutter ya no es un contador genérico; es una app de roles.
- El port de Caja y Admin es más cercano al prototipo web que el scaffold inicial.

## Pendientes naturales

Si se quiere seguir refinando el port, los siguientes pasos son los más útiles:

1. Corregir la imagen base del `flutter_app/Dockerfile` para que cumpla `sdk: ^3.12.0` y validar el build del contenedor Flutter.
2. Hacer la misma fidelidad visual y funcional para Usuario y Entrenador.
3. Añadir navegación más específica dentro de cada pantalla si se necesita más detalle.
4. Conectar acciones simuladas con formularios o diálogos de confirmación.
5. Ajustar aún más el estilo visual para igualar el prototipo web por vista.

## Nota de entorno

En este equipo no había emuladores Android configurados al momento de revisar el entorno, así que la vista móvil local depende de crear un AVD en Android Studio o usar Windows/web para la previsualización.
