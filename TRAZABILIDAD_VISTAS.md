# Leyenda de vistas y trazabilidad — SaaaS GYM (prototipo `sas_Gym_high`)

Documento de referencia que mapea **cada vista del prototipo web** con los
requerimientos del SRS, la matriz de privacidad y los casos de uso.

Fuentes: `Especificación de requerimientos.pdf` (SRS v2.0), `Casos de uso.pdf`
(CU v2.0), `Matriz de privacidad de datos y acceso.pdf` (v2.0).

---

## 1. Convenciones (leyenda)

### Roles del sistema

| Rol en el prototipo | Actor SRS | Archivo | App raíz |
|---|---|---|---|
| `member` | Practicante | [sas_Gym_high/member.jsx](sas_Gym_high/member.jsx) | `MemberApp` |
| `trainer` | Entrenador | [sas_Gym_high/trainer.jsx](sas_Gym_high/trainer.jsx) | `TrainerApp` |
| `caja` | — (refinamiento operativo del Administrador) | [sas_Gym_high/caja.jsx](sas_Gym_high/caja.jsx) | `CajaApp` |
| `admin` | Administrador | [sas_Gym_high/admin.jsx](sas_Gym_high/admin.jsx) | `AdminApp` |
| `superadmin` | Super-Administrador (plataforma SaaS) | [sas_Gym_high/superadmin.jsx](sas_Gym_high/superadmin.jsx) | `SuperAdminApp` |

> **Nota:** el SRS v2.0 define 4 roles: Super-Administrador, Administrador,
> Entrenador y Practicante. El prototipo **no implementa Super-Admin** y
> **añade `caja`** como sub-rol del Administrador con operación limitada,
> horario asignado y log de auditoría. La columna "Actor SRS" lo refleja.

### Códigos de requerimiento

- **RF x.y** — Requerimiento Funcional (SRS §4, módulos M4.1–M4.5).
- **RNF x** — Requerimiento No Funcional (SRS §5).
- **CU-xx** — Caso de Uso (v2.0).

### Accesos (matriz de privacidad)

`L` Lectura · `E` Escritura · `C` Creación · `Propio` solo datos del propio
usuario · `Asignados` solo usuarios vinculados · `No` sin acceso.

### Ubicación de una vista

`archivo › función › ruta` — la **ruta** es el `id` que recibe `go(id)` en el
router del rol. **Acceso** indica desde dónde se llega: pestaña de `BottomNav`,
sub-pantalla o modal.

---

## 2. Resumen de requerimientos

### Funcionales (SRS v2.0)

| Módulo | RF | Descripción |
|---|---|---|
| M4.1 Usuarios | RF 1.1 | Registro de practicante (auto / manual por Admin) |
| | RF 1.2 | Asignación Entrenador↔Practicante (solo Admin) |
| | RF 1.3 | Baja lógica (soft delete, solo Admin) |
| M4.2 Asistencia | RF 2.1 | Registro único de ingreso |
| | RF 2.2 | Escaneo cámara fija (DNI/QR) o manual desde celular |
| | RF 2.3 | Bloqueo + alerta al Admin si membresía vencida |
| | RF 2.4 | Margen de gracia de 1 día |
| M4.3 Pagos | RF 3.1 | Registro de pago en efectivo (Admin) |
| | RF 3.2 | Pago online vía pasarela (QR Yape/Plin) |
| | RF 3.3 | Acreditación manual digital (subir comprobante) |
| | RF 3.4 | Aviso en app 7 días antes del vencimiento |
| | RF 3.5 | Recordatorio diario tras vencimiento |
| | RF 3.6 | Banner de alerta si las push están deshabilitadas |
| M4.4 Rutinas | RF 4.1 | Biblioteca de ejercicios y plantillas (Entrenador) |
| | RF 4.2 | Personalizar plantilla + definir agenda semanal |
| | RF 4.3 | Asistente virtual (animación, series, descanso) |
| | RF 4.4 | Marcar "completado" + registrar esfuerzo real |
| M4.5 Comunicación | RF 5.1 | Crear observaciones con evidencia fotográfica |
| | RF 5.2 | Buzón consolidado de observaciones (solo Admin) |
| | RF 5.3 | Crear y publicar anuncios (Admin) |

### No funcionales

| RNF | Descripción |
|---|---|
| RNF 1 | Usabilidad: asistente optimizado para uso rápido / manos sudadas |
| RNF 2 | Rendimiento: validación de ingreso ≤ 2 s; animaciones cacheadas y versionadas |
| RNF 3 | Seguridad: tokens encriptados, invalidación en logout, aislamiento multi-tenant |
| RNF 4 | Almacenamiento: imágenes ≤ 2 MB / 1080 px, compresión en frontend |

---

## 3. Vistas del rol Practicante (`member.jsx`)

`BottomNav`: Inicio · Agenda · **Acceso** (FAB) · Membresía · Perfil

| Vista | Función › ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Inicio | `MemberHome` › `home` | nav Inicio | RF 3.4, RF 5.3, RF 4.3 (entrada) | Feed de anuncios (L); estado de membresía (L Propio) |
| Agenda semanal | `MemberAgenda` › `agenda` | nav Agenda | RF 4.2, CU-15 (entrada) | Asignación de rutinas (L Propia) |
| Asistente de entrenamiento | `WorkoutAssistant` › `assistant` | sub-pantalla (full screen) | **RF 4.3, RF 4.4, CU-15**, RNF 1 | Registro de esfuerzo real (L/E Propio) |
| — Ajustar esfuerzo | `LogEffortModal` | modal en `assistant` | RF 4.4, CU-15 (FA esfuerzo real) | Peso/reps reales (E Propio) |
| Mi acceso (QR) | `MemberQR` › `qr` | nav Acceso (FAB) | RF 2.2, CU-08 | Genera QR Propio; rota cada 60 s (RNF 2/3) |
| Mi membresía | `MemberMembership` › `pay` | nav Membresía | RF 3.4, CU-08/10 (entrada) | Estado de pagos (L Propio) |
| Pagar membresía | `MemberPayOnline` › `payOnline` | sub-pantalla de `pay` | **RF 3.2, RF 3.3, CU-10, CU-11**, RNF 4 | Sube comprobante (≤ 2 MB) |
| Mi perfil | `MemberProfile` › `profile` | nav Perfil | CU-07, CU-03 (logout) | Datos privados / Vista Social / Vista Física (L/E Propio); switch Modo Activo |
| Clases grupales | `MemberBookings` › `bookings` | acción rápida | *Sin RF directo* — funcionalidad extra del prototipo | — |
| Reportar observación | `MemberObservation` › `observation` | acción rápida | **RF 5.1, CU-16**, RNF 4 | Creación (Propias) |
| Notificaciones | `MemberNotifications` › `notifications` | icono campana | RF 3.4, RF 3.5, RF 5.3, CU-12 | Reutilizada también por `caja` y `admin` |

---

## 4. Vistas del rol Entrenador (`trainer.jsx`)

`BottomNav`: Alumnos · Ejercicios · Rutinas · Progreso · Perfil

| Vista | Función › ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Alumnos | `TrainerHome` › `home` | nav Alumnos | RF 1.2 (consumo) | Lista de practicantes (L Asignados) |
| Vista técnica del alumno | `TrainerMemberDetail` › `memberDetail` | desde lista | **RF 3.6, RF 4.2** (entrada), CU-14 | Vista Técnica + esfuerzo real (L Asignados) |
| Biblioteca de ejercicios | `TrainerLibrary` › `library` | nav Ejercicios | **RF 4.1, CU-13** | Ejercicios/plantillas (L/E/C Entrenador) |
| Nuevo / editar ejercicio | `CreateExercise` › `createExercise` / `editExercise` | desde biblioteca | **RF 4.1, CU-13**, RNF 2, RNF 4 | Sube animación GIF/WebM (≤ 2 MB, versionada) |
| Plantillas de rutina | `TrainerRoutines` › `routines` | nav Rutinas | RF 4.2, CU-14 | Plantillas (L/E/C) |
| Editar rutina | `EditRoutine` › `editRoutine` | desde plantillas | RF 4.2, CU-14 | Personaliza series/peso/descanso |
| Asignar rutina + agenda | `AssignRoutine` › `assignRoutine` | desde rutina/alumno | **RF 4.2, CU-14** | Define agenda semanal (E Asignados) |
| Progreso técnico | `TrainerStats` › `stats` | nav Progreso | RF 3.6, CU-14 (insumo) | Esfuerzo real (L Asignados) |
| Mi perfil profesional | `TrainerProfile` › `profile` | nav Perfil | CU-07, CU-03 (logout) | Perfil Profesional (L/E Propio) |

---

## 5. Vistas del rol Caja (`caja.jsx`)

`BottomNav`: Inicio · Asistencia · **Cobrar** (FAB) · Ventas · Más
Operación limitada del Administrador: **toda acción genera log de auditoría**
y la cuenta solo opera dentro de su horario asignado (RNF 3).

| Vista | Función › ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Inicio (turno) | `CajaHome` › `home` | nav Inicio | RF 3.1/3.2 (resumen), RF 2.1 (resumen) | Saldo del turno; log propio (L Propio) |
| Asistencia / escáner | `AdminScanner` › `scan` | nav Asistencia | **RF 2.2, RF 2.3, CU-08** | Validación de ingreso (componente compartido con Admin) |
| Registrar cobro | `CajaCharge` › `charge` | nav Cobrar (FAB) | **RF 3.1, RF 3.2, CU-09** | Cobra membresías y productos |
| Ventas del turno | `CajaSales` › `sales` | nav Ventas | Soporte operativo (log solo lectura) | Ventas (L Propio); anulación → Admin |
| Más | `CajaMore` › `more` | nav Más | hub de navegación | Lista de permisos del cajero |
| Catálogo de productos | `CajaProducts` › `products` | desde Más | RF (alta/precio limitado) | Crear/precio sí; eliminar → Admin |
| Nuevo producto | `NewProduct` › `newProduct` | desde catálogo | Alta de producto **con log** | Acción auditada (cajero_id) |
| Ajustar producto | `EditProduct` › `editProduct` | desde catálogo | Solo precio/stock | Cambios estructurales → Admin |
| Usuarios del gym | `CajaMembers` › `members` | desde Más | **RF 1.1** | Registrar/editar (L/E Datos de Registro) |
| Editar usuario | `CajaMemberEdit` › `memberEdit` | desde lista | **RF 1.1, RF 1.3, CU-06** | Baja lógica sí; eliminación física → Admin |
| — Confirmar baja lógica | `SoftDeleteModal` | modal en `memberEdit` | **RF 1.3, CU-06** | Soft delete; queda en log |
| Nuevo usuario | `NewMember` › `newMember` | desde Usuarios | **RF 1.1, CU-04** | Componente compartido con Admin |
| Mi historial de acciones | `CajaMyLogs` › `myLogs` | desde Más | Trazabilidad (visible al Admin) | Log propio (solo lectura) |
| Asistencias del día | `CajaAttendanceLog` › `attendanceLog` | desde Más | **RF 2.1, CU-08** | Log de ingresos (solo lectura) |
| Notificaciones | `MemberNotifications` › `notifications` | icono campana | RF 3.4/3.5, CU-12 | Vista reutilizada |

---

## 6. Vistas del rol Administrador (`admin.jsx`)

`BottomNav`: Inicio · Usuarios · **Escanear** (FAB) · Caja · Más

| Vista | Función › ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Dashboard | `AdminHome` › `home` | nav Inicio | RF 3.3, RF 5.2, RF 2.3 (bandeja) | Resumen de instancia (multi-tenant) |
| Usuarios | `AdminMembers` › `members` | nav Usuarios | RF 1.1 (entrada) | Vista Operativa (L/E Admin) |
| Detalle de usuario | `AdminMemberDetail` › `memberDetail` | desde lista | RF 1.3, RF 3.1, CU-07 | Vista Operativa: nombre, DNI, estado, entrenador. **Admin NO ve datos médicos** |
| Nuevo usuario | `NewMember` › `newMember` | desde Usuarios | **RF 1.1, CU-04** | Campo "Entrenador asignado" → RF 1.2 (parcial) |
| Escáner + veredicto | `AdminScanner` / `ScannerVerdict` › `scan` | nav Escanear (FAB) | **RF 2.2, RF 2.3, RF 2.4, CU-08**, RNF 2 | Acceso Concedido / Denegado |
| Caja (día) | `AdminCash` › `cash` | nav Caja | RF 3.1 (resumen) | Ingresos del día (L/E Admin) |
| Registrar cobro | `CashRegister` › `cashRegister` | desde Caja / detalle | **RF 3.1, CU-09** | Efectivo; botón se deshabilita sin usuario |
| Aprobar pagos | `ApprovePayments` › `approvePayments` | desde bandeja / Más | **RF 3.3, CU-11** | Revisa comprobante y aprueba acreditación |
| Más | `AdminMore` › `more` | nav Más | hub de navegación | — |
| Buzón de observaciones | `AdminInbox` › `inbox` | desde Más | **RF 5.2, CU-17** | Lectura Global + evidencias (solo Admin) |
| Nuevo aviso | `NewAnnouncement` › `newAnnouncement` | desde Más / acción rápida | **RF 5.3, CU-18** | Creación de anuncios; toggle push |
| Clases y horarios | `AdminClasses` › `classes` | desde Más | *Sin RF directo* — extra del prototipo | — |
| Reportes | `AdminReports` › `reports` | desde Más | Soporte de gestión (retención, ingresos) | — |
| Configuración del gym | `AdminSettings` › `settings` | desde Más | CU-07 (Perfil Empresa), RF 2.4 (día de gracia) | Perfil Empresa (L/E Admin) |
| Cuentas de Caja | `AdminCashiers` › `cashiers` | desde Más | Gestión del sub-rol `caja` (extra) | — |
| Nuevo cajero | `NewCashier` › `newCashier` | desde Cuentas de Caja | Crea cuenta con horario + permisos | Define alcance operativo del cajero |
| Editar cajero | `EditCashier` › `editCashier` | desde Cuentas de Caja | Edita turno; ve acciones del cajero | Enlaza al log de auditoría |
| Entrenadores | `AdminTrainers` › `trainers` | desde Más | RF 1.2 (contexto) | Gestión de Usuarios (E/Ejecución Admin) |
| Log de auditoría | `AdminAuditLog` › `auditLog` | desde Más | Trazabilidad global Caja/Trainer | RNF 3 (seguridad / rendición de cuentas) |
| Productos (CRUD) | `AdminProducts` › `adminProducts` | desde Más | CRUD completo de inventario | — |
| Editar producto | `EditAdminProduct` › `editAdminProduct` | desde Productos | CRUD + **eliminación física** | Zona crítica solo Admin; queda en log |
| Notificaciones | `MemberNotifications` › `notifications` | icono campana | RF 3.4/3.5, CU-12 | Vista reutilizada |

---

## 7. Vista del rol Super Administrador (`superadmin.jsx`)

El Super Administrador gestiona la **plataforma SaaS**, no un gimnasio concreto.
En móvil su vista es **deliberadamente mínima** — a diferencia del panel web,
que le da un back-office completo (gimnasios + planes).

| Vista | Función › ubicación | Acceso | Trazabilidad | Notas |
|---|---|---|---|---|
| Clientes de la plataforma | `SuperAdminApp` › pantalla única | rol Super Admin | rol de plataforma (SRS §2) | Cuenta de gimnasios + lista con estado activo / inactivo. Sin `BottomNav` ni navegación interna |

Tras el `LoginScreen`, muestra una sola pantalla: resumen (total · activos ·
inactivos) y la lista de gimnasios-cliente. El detalle operativo de cada
gimnasio vive en el panel web, no aquí.

## 8. Cobertura inversa — requerimiento → vista(s)

| Requerimiento | Vista(s) que lo implementan | Cobertura |
|---|---|---|
| RF 1.1 Registro | `NewMember`, `CajaMembers`, `CajaMemberEdit` | ✅ |
| RF 1.2 Asignación entrenador | `NewMember` (campo), `AdminTrainers` | ⚠️ Parcial — sin flujo dedicado (CU-05) |
| RF 1.3 Baja lógica | `CajaMemberEdit` + `SoftDeleteModal`, `AdminMemberDetail` | ✅ |
| RF 2.1 Ingreso único | `CajaAttendanceLog`, `AdminScanner` | ✅ |
| RF 2.2 Escaneo DNI/QR | `MemberQR`, `AdminScanner` | ✅ |
| RF 2.3 Bloqueo + alerta | `ScannerVerdict` (denegado), `AdminHome` (bandeja) | ✅ |
| RF 2.4 Margen de gracia | `AdminSettings`, estado `grace` en listas | ✅ |
| RF 3.1 Pago efectivo | `CashRegister`, `CajaCharge` | ✅ |
| RF 3.2 Pasarela QR | `MemberPayOnline`, `CajaCharge` | ✅ |
| RF 3.3 Acreditación manual | `MemberPayOnline` (subir), `ApprovePayments` (aprobar) | ✅ |
| RF 3.4 Aviso 7 días | `MemberNotifications`, `MemberHome` | ✅ |
| RF 3.5 Recordatorio diario | `MemberNotifications` | ✅ |
| RF 3.6 Banner si push off | — | ❌ No implementado |
| RF 4.1 Biblioteca | `TrainerLibrary`, `CreateExercise` | ✅ |
| RF 4.2 Personalizar + agenda | `EditRoutine`, `AssignRoutine` | ✅ |
| RF 4.3 Asistente virtual | `WorkoutAssistant` | ✅ |
| RF 4.4 Completado + esfuerzo | `WorkoutAssistant`, `LogEffortModal` | ✅ |
| RF 5.1 Observación + foto | `MemberObservation` | ✅ |
| RF 5.2 Buzón observaciones | `AdminInbox` | ✅ |
| RF 5.3 Anuncios | `NewAnnouncement` | ✅ |
| RNF 1 Usabilidad asistente | `WorkoutAssistant` (botones grandes, alto contraste) | ✅ |
| RNF 2 Rendimiento / caché | `AdminScanner`, `CreateExercise` (animación versionada) | ⚠️ Visual |
| RNF 3 Seguridad / multi-tenant | `AdminAuditLog`, horario de `caja`, logout en perfiles | ⚠️ Parcial |
| RNF 4 Almacenamiento imágenes | `MemberObservation`, `MemberPayOnline`, `NewProduct` | ⚠️ Visual (texto "máx 2MB") |

## 9. Vacíos detectados (sin vista en el prototipo)

| Faltante | Caso de uso | Comentario |
|---|---|---|
| Recuperación de contraseña | CU-02 | El enlace existe en `LoginScreen`, sin pantalla de reset |
| Asignar entrenador | CU-05 / RF 1.2 | Solo campo de texto en `NewMember`; sin selector dedicado |
| Banner push deshabilitado | RF 3.6 | No existe el banner de respaldo |

---

## 10. Mejoras de implementación aplicadas (plan ejecutado)

Cambios transversales que afectan a **todas las vistas** anteriores:

1. **`Btn` / `Chip`** ([shared.jsx](sas_Gym_high/shared.jsx)) ahora propagan
   `style`, `disabled` y props extra; nueva variante `kind="danger"`. Corrige
   ~12 sitios donde el estilo se descartaba (p. ej. botón de baja lógica).
2. **Accesibilidad**: títulos de `Header` y `SectionTitle` como headings
   (`role="heading"`), `aria-label` en navegación y botón volver, foco visible
   por teclado, contraste de `--ink-3` subido a nivel WCAG AA.
3. **Componentes de formulario** (`Toggle`, `Stepper`, `Field`, `PhyField`)
   centralizados en `shared.jsx`; datos mock compartidos consolidados en
   [data.jsx](sas_Gym_high/data.jsx) con una fecha única `TODAY`.
4. **Router con pila** (`useRouter` en `shared.jsx`): el botón "volver" regresa
   a la pantalla de origen real en lugar de un destino fijo.
5. **Inicio de sesión** (`LoginScreen` en `shared.jsx` — **CU-01**): pantalla
   de login compartida, adaptada por rol (correo de ejemplo y etiqueta). Cada
   app de rol arranca con un gate de autenticación; los botones «Cerrar
   sesión» (CU-03) ahora regresan de verdad al login. La invalidación de
   token en servidor queda fuera del prototipo.

### Vista de inicio de sesión

| Vista | Función › ubicación | Roles | Trazabilidad |
|---|---|---|---|
| Inicio de sesión | `LoginScreen` › [shared.jsx](sas_Gym_high/shared.jsx) | los 4 (member · trainer · caja · admin) | **CU-01**; CU-03 (logout); RNF 3 (token «Recordarme»); enlace CU-02 |

Se muestra antes del `home` de cada rol; al pulsar «Iniciar sesión» entra a la
app del rol, y «Cerrar sesión» vuelve aquí.
