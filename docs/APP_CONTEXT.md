# Contexto de la app SaaaS GYM

## Resumen general

Este workspace contiene dos superficies principales del producto:

1. Un prototipo web de alta fidelidad en `mockups/mobile/`.
2. Una app Flutter en `mobile_app/` que porta las vistas y la lÃ³gica de roles.

Es un producto **SaaS multi-inquilino**: una instancia aislada por gimnasio.
El sistema define **5 roles**:

| Rol | DescripciÃ³n |
|---|---|
| **Super Administrador** | Gestiona la plataforma SaaS completa: creaciÃ³n de gimnasios e instancias multi-tenant. |
| **Administrador** | Administra la operaciÃ³n completa del gimnasio: miembros, pagos, anuncios, productos y auditorÃ­a. |
| **Caja** | Realiza operaciones limitadas de cobro, asistencia y validaciÃ³n de ingreso. |
| **Entrenador** | Gestiona rutinas, ejercicios, seguimiento y progreso de los miembros asignados. |
| **Miembro** | Usuario final del gimnasio que utiliza rutinas, registra progreso y administra su membresÃ­a. |

Notas de diseÃ±o:

- Caja y Admin **no son equivalentes**: Caja tiene operaciÃ³n limitada y logs de
  solo lectura; Admin conserva gestiÃ³n total, cuentas de caja y auditorÃ­a global.
- El **Super Administrador es asimÃ©trico entre plataformas**: en **web** tiene un
  back-office SaaS completo (gimnasios, planes); en **mÃ³vil** su vista es mÃ­nima
  â€” Ãºnicamente listar los clientes (gimnasios) y si estÃ¡n activos o no.
- Los otros 4 roles (Admin, Caja, Entrenador, Miembro) son **consistentes en web
  y mÃ³vil**.

## Estructura del workspace

- `docker-compose.yml`: sirve el prototipo web desde Nginx.
- `mockups/mobile/` (antes `mockups/mobile/`): prototipo web original en HTML, CSS, React/Babel.
- `mobile_app/` (antes `mobile_app/`): port en Flutter con vistas por rol, datos mock y despliegue propio.
- `mockups_section.md`: notas de mockups y secciones de diseÃ±o.
- `planificacion.md`: planificaciÃ³n general.
- `planificacion_designthinking.md`: planificaciÃ³n de diseÃ±o / design thinking.

## Prototipo web (`mockups/mobile`)

### Entrada y carga

- `index.html` carga los scripts del prototipo y ya incluye `data.jsx` antes de las pantallas de rol.
- `app.jsx` contiene el selector principal de roles y el panel de tweaks.
- `data.jsx` centraliza datos compartidos para evitar depender de variables accidentales del scope global. Expone `PRODUCTS` y `ALL_MEMBERS` en `window` y se carga antes de `member/trainer/admin/caja`.

### Roles en web

- `member.jsx`: experiencia del socio.
- `trainer.jsx`: experiencia del entrenador.
- `caja.jsx`: operaciÃ³n limitada de caja.
- `admin.jsx`: panel administrativo completo.

### Estado funcional importante

- Caja y Admin usan datos compartidos explÃ­citos.
- Caja expone cobros, asistencia, ventas, productos, usuarios con baja lÃ³gica y logs de solo lectura.
- Admin expone CRUD total, cuentas de caja, productos y auditorÃ­a global.

## App Flutter (`mobile_app`)

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
- `lib/screens/cashier_screen.dart`: vista de caja con navegaciÃ³n interna.
- `lib/screens/admin_screen.dart`: vista de admin con navegaciÃ³n interna.

### DiseÃ±o de roles en Flutter

#### Usuario

- Home con hero card, mÃ©tricas, agenda semanal, ejercicios, anuncios y progreso.

#### Entrenador

- Panel con miembros asignados, librerÃ­a de ejercicios, progreso y estadÃ­sticas mini.

#### Caja

- Inicio con turno activo y resumen del turno.
- Escaneo de asistencia.
- Cobro rÃ¡pido.
- Ventas del turno.
- MÃ¡s opciones con catÃ¡logo y logs.
- Logs de solo lectura.
- Baja lÃ³gica de usuarios.
- OperaciÃ³n limitada frente a Admin.

#### Admin

- Dashboard principal.
- Usuarios con gestiÃ³n total.
- EscÃ¡ner administrativo.
- Cuentas de caja.
- Productos con CRUD total.
- AuditorÃ­a global.

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
- MÃ©tricas de usuario, entrenador, caja y admin.
- Semana de entrenamiento y lista de ejercicios.
- Anuncios del gimnasio.
- Lista de miembros para entrenador y admin.
- CatÃ¡logo de productos.
- Cuentas de caja.
- Logs de caja y auditorÃ­a global.
- Ventana de turno activa de caja.

## Despliegue y contenedores

### Hub de navegaciÃ³n (web)

- `docker-compose.yml` (raÃ­z) levanta Nginx en `http://localhost:8282`.
- Sirve el **hub de navegaciÃ³n** (`index.html` de la raÃ­z): desde ahÃ­ se entra
  a `mockups/mobile/` (app mÃ³vil) y `mockups/web/` (panel web admin).
- Monta solo el hub, los dos prototipos y los `.md` de documentaciÃ³n â€” **no**
  expone `proyecto_antiguo/` (con `.env`, credenciales y backups) ni el resto del
  workspace.
- Cambiar los volÃºmenes exige recrear el contenedor: `docker-compose up -d`
  (Compose detecta el cambio y recrea `sas_gym_frontend`).

### Flutter

- `mobile_app/Dockerfile` compila Flutter web y sirve el resultado con Nginx.
- `mobile_app/docker-compose.yml` publica la app en `http://localhost:8383`.

### Conflicto de puerto (Solucionado)

El puerto de la app Flutter se configurÃ³ en `8383`, mientras que el hub de navegaciÃ³n y mockups estÃ¡ticos corre en `8282`. Se pueden ejecutar en paralelo.

### Comandos Ãºtiles

Desde la raÃ­z del workspace:

```powershell
docker-compose up -d
```

Desde `mobile_app/`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter run -d chrome
docker compose up --build -d
```

## ValidaciÃ³n realizada

Verificado en sesiones previas (no re-ejecutado en la Ãºltima revisiÃ³n del contexto):

- `flutter analyze` pasaba sin errores.
- `flutter test` pasaba (`test/widget_test.dart`).
- El prototipo web sigue cargando despuÃ©s de separar los datos compartidos.
- El contenedor de la web (`docker-compose.yml` raÃ­z, Nginx) expone el diseÃ±o en el puerto 8282.

Sin verificar todavÃ­a:

- Build del contenedor Flutter. `mobile_app/Dockerfile` usa la imagen
  `ghcr.io/cirruslabs/flutter:3.24.5`, pero `pubspec.yaml` exige Dart
  `sdk: ^3.12.0`. El Flutter local instalado es 3.44.0. La imagen 3.24.5
  trae un Dart anterior a 3.12.0, asÃ­ que `flutter pub get` dentro del
  contenedor probablemente falle: hay que subir la etiqueta de la imagen
  base a una que cumpla la restricciÃ³n del SDK antes de confiar en ese build.

## Estado actual

La app ya estÃ¡ en una base funcional y compilable. Lo mÃ¡s importante del estado actual es:

- Caja y Admin estÃ¡n separados funcionalmente.
- Flutter ya no es un contador genÃ©rico; es una app de roles.
- El port de Caja y Admin es mÃ¡s cercano al prototipo web que el scaffold inicial.

## Pendientes naturales

Si se quiere seguir refinando el port, los siguientes pasos son los mÃ¡s Ãºtiles:

1. Corregir la imagen base del `mobile_app/Dockerfile` para que cumpla `sdk: ^3.12.0` y validar el build del contenedor Flutter. (Solucionado usando Flutter 3.44.0)
2. Hacer la misma fidelidad visual y funcional para Usuario y Entrenador.
3. AÃ±adir navegaciÃ³n mÃ¡s especÃ­fica dentro de cada pantalla si se necesita mÃ¡s detalle.
4. Conectar acciones simuladas con formularios o diÃ¡logos de confirmaciÃ³n.
5. Ajustar aÃºn mÃ¡s el estilo visual para igualar el prototipo web por vista.

## Nota de entorno

En este equipo no habÃ­a emuladores Android configurados al momento de revisar el entorno, asÃ­ que la vista mÃ³vil local depende de crear un AVD en Android Studio o usar Windows/web para la previsualizaciÃ³n.


