# Leyenda de vistas y trazabilidad â€” SaaaS GYM (prototipo `mockups/mobile`)

Documento de referencia que mapea **cada vista del prototipo web** con los
requerimientos del SRS, la matriz de privacidad y los casos de uso.

Fuentes: `EspecificaciÃ³n de requerimientos.pdf` (SRS v2.0), `Casos de uso.pdf`
(CU v2.0), `Matriz de privacidad de datos y acceso.pdf` (v2.0).

---

## 1. Convenciones (leyenda)

### Roles del sistema

| Rol en el prototipo | Actor SRS | Archivo | App raÃ­z |
|---|---|---|---|
| `member` | Practicante | [mockups/mobile/member.jsx](mockups/mobile/member.jsx) | `MemberApp` |
| `trainer` | Entrenador | [mockups/mobile/trainer.jsx](mockups/mobile/trainer.jsx) | `TrainerApp` |
| `caja` | â€” (refinamiento operativo del Administrador) | [mockups/mobile/caja.jsx](mockups/mobile/caja.jsx) | `CajaApp` |
| `admin` | Administrador | [mockups/mobile/admin.jsx](mockups/mobile/admin.jsx) | `AdminApp` |
| `superadmin` | Super-Administrador (plataforma SaaS) | [mockups/mobile/superadmin.jsx](mockups/mobile/superadmin.jsx) | `SuperAdminApp` |

> **Nota:** el SRS v2.0 define 4 roles: Super-Administrador, Administrador,
> Entrenador y Practicante. El prototipo **no implementa Super-Admin** y
> **aÃ±ade `caja`** como sub-rol del Administrador con operaciÃ³n limitada,
> horario asignado y log de auditorÃ­a. La columna "Actor SRS" lo refleja.

### CÃ³digos de requerimiento

- **RF x.y** â€” Requerimiento Funcional (SRS Â§4, mÃ³dulos M4.1â€“M4.5).
- **RNF x** â€” Requerimiento No Funcional (SRS Â§5).
- **CU-xx** â€” Caso de Uso (v2.0).

### Accesos (matriz de privacidad)

`L` Lectura Â· `E` Escritura Â· `C` CreaciÃ³n Â· `Propio` solo datos del propio
usuario Â· `Asignados` solo usuarios vinculados Â· `No` sin acceso.

### UbicaciÃ³n de una vista

`archivo â€º funciÃ³n â€º ruta` â€” la **ruta** es el `id` que recibe `go(id)` en el
router del rol. **Acceso** indica desde dÃ³nde se llega: pestaÃ±a de `BottomNav`,
sub-pantalla o modal.

---

## 2. Resumen de requerimientos

### Funcionales (SRS v2.0)

| MÃ³dulo | RF | DescripciÃ³n |
|---|---|---|
| M4.1 Usuarios | RF 1.1 | Registro de practicante (auto / manual por Admin) |
| | RF 1.2 | AsignaciÃ³n Entrenadorâ†”Practicante (solo Admin) |
| | RF 1.3 | Baja lÃ³gica (soft delete, solo Admin) |
| M4.2 Asistencia | RF 2.1 | Registro Ãºnico de ingreso |
| | RF 2.2 | Escaneo cÃ¡mara fija (DNI/QR) o manual desde celular |
| | RF 2.3 | Bloqueo + alerta al Admin si membresÃ­a vencida |
| | RF 2.4 | Margen de gracia de 1 dÃ­a |
| M4.3 Pagos | RF 3.1 | Registro de pago en efectivo (Admin) |
| | RF 3.2 | Pago online vÃ­a pasarela (QR Yape/Plin) |
| | RF 3.3 | AcreditaciÃ³n manual digital (subir comprobante) |
| | RF 3.4 | Aviso en app 7 dÃ­as antes del vencimiento |
| | RF 3.5 | Recordatorio diario tras vencimiento |
| | RF 3.6 | Banner de alerta si las push estÃ¡n deshabilitadas |
| M4.4 Rutinas | RF 4.1 | Biblioteca de ejercicios y plantillas (Entrenador) |
| | RF 4.2 | Personalizar plantilla + definir agenda semanal |
| | RF 4.3 | Asistente virtual (animaciÃ³n, series, descanso) |
| | RF 4.4 | Marcar "completado" + registrar esfuerzo real |
| M4.5 ComunicaciÃ³n | RF 5.1 | Crear observaciones con evidencia fotogrÃ¡fica |
| | RF 5.2 | BuzÃ³n consolidado de observaciones (solo Admin) |
| | RF 5.3 | Crear y publicar anuncios (Admin) |

### No funcionales

| RNF | DescripciÃ³n |
|---|---|
| RNF 1 | Usabilidad: asistente optimizado para uso rÃ¡pido / manos sudadas |
| RNF 2 | Rendimiento: validaciÃ³n de ingreso â‰¤ 2 s; animaciones cacheadas y versionadas |
| RNF 3 | Seguridad: tokens encriptados, invalidaciÃ³n en logout, aislamiento multi-tenant |
| RNF 4 | Almacenamiento: imÃ¡genes â‰¤ 2 MB / 1080 px, compresiÃ³n en frontend |

---

## 3. Vistas del rol Practicante (`member.jsx`)

`BottomNav`: Inicio Â· Agenda Â· **Acceso** (FAB) Â· MembresÃ­a Â· Perfil

| Vista | FunciÃ³n â€º ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Inicio | `MemberHome` â€º `home` | nav Inicio | RF 3.4, RF 5.3, RF 4.3 (entrada) | Feed de anuncios (L); estado de membresÃ­a (L Propio) |
| Agenda semanal | `MemberAgenda` â€º `agenda` | nav Agenda | RF 4.2, CU-15 (entrada) | AsignaciÃ³n de rutinas (L Propia) |
| Asistente de entrenamiento | `WorkoutAssistant` â€º `assistant` | sub-pantalla (full screen) | **RF 4.3, RF 4.4, CU-15**, RNF 1 | Registro de esfuerzo real (L/E Propio) |
| â€” Ajustar esfuerzo | `LogEffortModal` | modal en `assistant` | RF 4.4, CU-15 (FA esfuerzo real) | Peso/reps reales (E Propio) |
| Mi acceso (QR) | `MemberQR` â€º `qr` | nav Acceso (FAB) | RF 2.2, CU-08 | Genera QR Propio; rota cada 60 s (RNF 2/3) |
| Mi membresÃ­a | `MemberMembership` â€º `pay` | nav MembresÃ­a | RF 3.4, CU-08/10 (entrada) | Estado de pagos (L Propio) |
| Pagar membresÃ­a | `MemberPayOnline` â€º `payOnline` | sub-pantalla de `pay` | **RF 3.2, RF 3.3, CU-10, CU-11**, RNF 4 | Sube comprobante (â‰¤ 2 MB) |
| Mi perfil | `MemberProfile` â€º `profile` | nav Perfil | CU-07, CU-03 (logout) | Datos privados / Vista Social / Vista FÃ­sica (L/E Propio); switch Modo Activo |
| Clases grupales | `MemberBookings` â€º `bookings` | acciÃ³n rÃ¡pida | *Sin RF directo* â€” funcionalidad extra del prototipo | â€” |
| Reportar observaciÃ³n | `MemberObservation` â€º `observation` | acciÃ³n rÃ¡pida | **RF 5.1, CU-16**, RNF 4 | CreaciÃ³n (Propias) |
| Notificaciones | `MemberNotifications` â€º `notifications` | icono campana | RF 3.4, RF 3.5, RF 5.3, CU-12 | Reutilizada tambiÃ©n por `caja` y `admin` |

---

## 4. Vistas del rol Entrenador (`trainer.jsx`)

`BottomNav`: Alumnos Â· Ejercicios Â· Rutinas Â· Progreso Â· Perfil

| Vista | FunciÃ³n â€º ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Alumnos | `TrainerHome` â€º `home` | nav Alumnos | RF 1.2 (consumo) | Lista de practicantes (L Asignados) |
| Vista tÃ©cnica del alumno | `TrainerMemberDetail` â€º `memberDetail` | desde lista | **RF 3.6, RF 4.2** (entrada), CU-14 | Vista TÃ©cnica + esfuerzo real (L Asignados) |
| Biblioteca de ejercicios | `TrainerLibrary` â€º `library` | nav Ejercicios | **RF 4.1, CU-13** | Ejercicios/plantillas (L/E/C Entrenador) |
| Nuevo / editar ejercicio | `CreateExercise` â€º `createExercise` / `editExercise` | desde biblioteca | **RF 4.1, CU-13**, RNF 2, RNF 4 | Sube animaciÃ³n GIF/WebM (â‰¤ 2 MB, versionada) |
| Plantillas de rutina | `TrainerRoutines` â€º `routines` | nav Rutinas | RF 4.2, CU-14 | Plantillas (L/E/C) |
| Editar rutina | `EditRoutine` â€º `editRoutine` | desde plantillas | RF 4.2, CU-14 | Personaliza series/peso/descanso |
| Asignar rutina + agenda | `AssignRoutine` â€º `assignRoutine` | desde rutina/alumno | **RF 4.2, CU-14** | Define agenda semanal (E Asignados) |
| Progreso tÃ©cnico | `TrainerStats` â€º `stats` | nav Progreso | RF 3.6, CU-14 (insumo) | Esfuerzo real (L Asignados) |
| Mi perfil profesional | `TrainerProfile` â€º `profile` | nav Perfil | CU-07, CU-03 (logout) | Perfil Profesional (L/E Propio) |

---

## 5. Vistas del rol Caja (`caja.jsx`)

`BottomNav`: Inicio Â· Asistencia Â· **Cobrar** (FAB) Â· Ventas Â· MÃ¡s
OperaciÃ³n limitada del Administrador: **toda acciÃ³n genera log de auditorÃ­a**
y la cuenta solo opera dentro de su horario asignado (RNF 3).

| Vista | FunciÃ³n â€º ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Inicio (turno) | `CajaHome` â€º `home` | nav Inicio | RF 3.1/3.2 (resumen), RF 2.1 (resumen) | Saldo del turno; log propio (L Propio) |
| Asistencia / escÃ¡ner | `AdminScanner` â€º `scan` | nav Asistencia | **RF 2.2, RF 2.3, CU-08** | ValidaciÃ³n de ingreso (componente compartido con Admin) |
| Registrar cobro | `CajaCharge` â€º `charge` | nav Cobrar (FAB) | **RF 3.1, RF 3.2, CU-09** | Cobra membresÃ­as y productos |
| Ventas del turno | `CajaSales` â€º `sales` | nav Ventas | Soporte operativo (log solo lectura) | Ventas (L Propio); anulaciÃ³n â†’ Admin |
| MÃ¡s | `CajaMore` â€º `more` | nav MÃ¡s | hub de navegaciÃ³n | Lista de permisos del cajero |
| CatÃ¡logo de productos | `CajaProducts` â€º `products` | desde MÃ¡s | RF (alta/precio limitado) | Crear/precio sÃ­; eliminar â†’ Admin |
| Nuevo producto | `NewProduct` â€º `newProduct` | desde catÃ¡logo | Alta de producto **con log** | AcciÃ³n auditada (cajero_id) |
| Ajustar producto | `EditProduct` â€º `editProduct` | desde catÃ¡logo | Solo precio/stock | Cambios estructurales â†’ Admin |
| Usuarios del gym | `CajaMembers` â€º `members` | desde MÃ¡s | **RF 1.1** | Registrar/editar (L/E Datos de Registro) |
| Editar usuario | `CajaMemberEdit` â€º `memberEdit` | desde lista | **RF 1.1, RF 1.3, CU-06** | Baja lÃ³gica sÃ­; eliminaciÃ³n fÃ­sica â†’ Admin |
| â€” Confirmar baja lÃ³gica | `SoftDeleteModal` | modal en `memberEdit` | **RF 1.3, CU-06** | Soft delete; queda en log |
| Nuevo usuario | `NewMember` â€º `newMember` | desde Usuarios | **RF 1.1, CU-04** | Componente compartido con Admin |
| Mi historial de acciones | `CajaMyLogs` â€º `myLogs` | desde MÃ¡s | Trazabilidad (visible al Admin) | Log propio (solo lectura) |
| Asistencias del dÃ­a | `CajaAttendanceLog` â€º `attendanceLog` | desde MÃ¡s | **RF 2.1, CU-08** | Log de ingresos (solo lectura) |
| Notificaciones | `MemberNotifications` â€º `notifications` | icono campana | RF 3.4/3.5, CU-12 | Vista reutilizada |

---

## 6. Vistas del rol Administrador (`admin.jsx`)

`BottomNav`: Inicio Â· Usuarios Â· **Escanear** (FAB) Â· Caja Â· MÃ¡s

| Vista | FunciÃ³n â€º ruta | Acceso | Trazabilidad | Notas de privacidad / rol |
|---|---|---|---|---|
| Dashboard | `AdminHome` â€º `home` | nav Inicio | RF 3.3, RF 5.2, RF 2.3 (bandeja) | Resumen de instancia (multi-tenant) |
| Usuarios | `AdminMembers` â€º `members` | nav Usuarios | RF 1.1 (entrada) | Vista Operativa (L/E Admin) |
| Detalle de usuario | `AdminMemberDetail` â€º `memberDetail` | desde lista | RF 1.3, RF 3.1, CU-07 | Vista Operativa: nombre, DNI, estado, entrenador. **Admin NO ve datos mÃ©dicos** |
| Nuevo usuario | `NewMember` â€º `newMember` | desde Usuarios | **RF 1.1, CU-04** | Campo "Entrenador asignado" â†’ RF 1.2 (parcial) |
| EscÃ¡ner + veredicto | `AdminScanner` / `ScannerVerdict` â€º `scan` | nav Escanear (FAB) | **RF 2.2, RF 2.3, RF 2.4, CU-08**, RNF 2 | Acceso Concedido / Denegado |
| Caja (dÃ­a) | `AdminCash` â€º `cash` | nav Caja | RF 3.1 (resumen) | Ingresos del dÃ­a (L/E Admin) |
| Registrar cobro | `CashRegister` â€º `cashRegister` | desde Caja / detalle | **RF 3.1, CU-09** | Efectivo; botÃ³n se deshabilita sin usuario |
| Aprobar pagos | `ApprovePayments` â€º `approvePayments` | desde bandeja / MÃ¡s | **RF 3.3, CU-11** | Revisa comprobante y aprueba acreditaciÃ³n |
| MÃ¡s | `AdminMore` â€º `more` | nav MÃ¡s | hub de navegaciÃ³n | â€” |
| BuzÃ³n de observaciones | `AdminInbox` â€º `inbox` | desde MÃ¡s | **RF 5.2, CU-17** | Lectura Global + evidencias (solo Admin) |
| Nuevo aviso | `NewAnnouncement` â€º `newAnnouncement` | desde MÃ¡s / acciÃ³n rÃ¡pida | **RF 5.3, CU-18** | CreaciÃ³n de anuncios; toggle push |
| Clases y horarios | `AdminClasses` â€º `classes` | desde MÃ¡s | *Sin RF directo* â€” extra del prototipo | â€” |
| Reportes | `AdminReports` â€º `reports` | desde MÃ¡s | Soporte de gestiÃ³n (retenciÃ³n, ingresos) | â€” |
| ConfiguraciÃ³n del gym | `AdminSettings` â€º `settings` | desde MÃ¡s | CU-07 (Perfil Empresa), RF 2.4 (dÃ­a de gracia) | Perfil Empresa (L/E Admin) |
| Cuentas de Caja | `AdminCashiers` â€º `cashiers` | desde MÃ¡s | GestiÃ³n del sub-rol `caja` (extra) | â€” |
| Nuevo cajero | `NewCashier` â€º `newCashier` | desde Cuentas de Caja | Crea cuenta con horario + permisos | Define alcance operativo del cajero |
| Editar cajero | `EditCashier` â€º `editCashier` | desde Cuentas de Caja | Edita turno; ve acciones del cajero | Enlaza al log de auditorÃ­a |
| Entrenadores | `AdminTrainers` â€º `trainers` | desde MÃ¡s | RF 1.2 (contexto) | GestiÃ³n de Usuarios (E/EjecuciÃ³n Admin) |
| Log de auditorÃ­a | `AdminAuditLog` â€º `auditLog` | desde MÃ¡s | Trazabilidad global Caja/Trainer | RNF 3 (seguridad / rendiciÃ³n de cuentas) |
| Productos (CRUD) | `AdminProducts` â€º `adminProducts` | desde MÃ¡s | CRUD completo de inventario | â€” |
| Editar producto | `EditAdminProduct` â€º `editAdminProduct` | desde Productos | CRUD + **eliminaciÃ³n fÃ­sica** | Zona crÃ­tica solo Admin; queda en log |
| Notificaciones | `MemberNotifications` â€º `notifications` | icono campana | RF 3.4/3.5, CU-12 | Vista reutilizada |

---

## 7. Vista del rol Super Administrador (`superadmin.jsx`)

El Super Administrador gestiona la **plataforma SaaS**, no un gimnasio concreto.
En mÃ³vil su vista es **deliberadamente mÃ­nima** â€” a diferencia del panel web,
que le da un back-office completo (gimnasios + planes).

| Vista | FunciÃ³n â€º ubicaciÃ³n | Acceso | Trazabilidad | Notas |
|---|---|---|---|---|
| Clientes de la plataforma | `SuperAdminApp` â€º pantalla Ãºnica | rol Super Admin | rol de plataforma (SRS Â§2) | Cuenta de gimnasios + lista con estado activo / inactivo. Sin `BottomNav` ni navegaciÃ³n interna |

Tras el `LoginScreen`, muestra una sola pantalla: resumen (total Â· activos Â·
inactivos) y la lista de gimnasios-cliente. El detalle operativo de cada
gimnasio vive en el panel web, no aquÃ­.

## 8. Cobertura inversa â€” requerimiento â†’ vista(s)

| Requerimiento | Vista(s) que lo implementan | Cobertura |
|---|---|---|
| RF 1.1 Registro | `NewMember`, `CajaMembers`, `CajaMemberEdit` | âœ… |
| RF 1.2 AsignaciÃ³n entrenador | `NewMember` (campo), `AdminTrainers` | âš ï¸ Parcial â€” sin flujo dedicado (CU-05) |
| RF 1.3 Baja lÃ³gica | `CajaMemberEdit` + `SoftDeleteModal`, `AdminMemberDetail` | âœ… |
| RF 2.1 Ingreso Ãºnico | `CajaAttendanceLog`, `AdminScanner` | âœ… |
| RF 2.2 Escaneo DNI/QR | `MemberQR`, `AdminScanner` | âœ… |
| RF 2.3 Bloqueo + alerta | `ScannerVerdict` (denegado), `AdminHome` (bandeja) | âœ… |
| RF 2.4 Margen de gracia | `AdminSettings`, estado `grace` en listas | âœ… |
| RF 3.1 Pago efectivo | `CashRegister`, `CajaCharge` | âœ… |
| RF 3.2 Pasarela QR | `MemberPayOnline`, `CajaCharge` | âœ… |
| RF 3.3 AcreditaciÃ³n manual | `MemberPayOnline` (subir), `ApprovePayments` (aprobar) | âœ… |
| RF 3.4 Aviso 7 dÃ­as | `MemberNotifications`, `MemberHome` | âœ… |
| RF 3.5 Recordatorio diario | `MemberNotifications` | âœ… |
| RF 3.6 Banner si push off | â€” | âŒ No implementado |
| RF 4.1 Biblioteca | `TrainerLibrary`, `CreateExercise` | âœ… |
| RF 4.2 Personalizar + agenda | `EditRoutine`, `AssignRoutine` | âœ… |
| RF 4.3 Asistente virtual | `WorkoutAssistant` | âœ… |
| RF 4.4 Completado + esfuerzo | `WorkoutAssistant`, `LogEffortModal` | âœ… |
| RF 5.1 ObservaciÃ³n + foto | `MemberObservation` | âœ… |
| RF 5.2 BuzÃ³n observaciones | `AdminInbox` | âœ… |
| RF 5.3 Anuncios | `NewAnnouncement` | âœ… |
| RNF 1 Usabilidad asistente | `WorkoutAssistant` (botones grandes, alto contraste) | âœ… |
| RNF 2 Rendimiento / cachÃ© | `AdminScanner`, `CreateExercise` (animaciÃ³n versionada) | âš ï¸ Visual |
| RNF 3 Seguridad / multi-tenant | `AdminAuditLog`, horario de `caja`, logout en perfiles | âš ï¸ Parcial |
| RNF 4 Almacenamiento imÃ¡genes | `MemberObservation`, `MemberPayOnline`, `NewProduct` | âš ï¸ Visual (texto "mÃ¡x 2MB") |

## 9. VacÃ­os detectados (sin vista en el prototipo)

| Faltante | Caso de uso | Comentario |
|---|---|---|
| RecuperaciÃ³n de contraseÃ±a | CU-02 | El enlace existe en `LoginScreen`, sin pantalla de reset |
| Asignar entrenador | CU-05 / RF 1.2 | Solo campo de texto en `NewMember`; sin selector dedicado |
| Banner push deshabilitado | RF 3.6 | No existe el banner de respaldo |

---

## 10. Mejoras de implementaciÃ³n aplicadas (plan ejecutado)

Cambios transversales que afectan a **todas las vistas** anteriores:

1. **`Btn` / `Chip`** ([shared.jsx](mockups/mobile/shared.jsx)) ahora propagan
   `style`, `disabled` y props extra; nueva variante `kind="danger"`. Corrige
   ~12 sitios donde el estilo se descartaba (p. ej. botÃ³n de baja lÃ³gica).
2. **Accesibilidad**: tÃ­tulos de `Header` y `SectionTitle` como headings
   (`role="heading"`), `aria-label` en navegaciÃ³n y botÃ³n volver, foco visible
   por teclado, contraste de `--ink-3` subido a nivel WCAG AA.
3. **Componentes de formulario** (`Toggle`, `Stepper`, `Field`, `PhyField`)
   centralizados en `shared.jsx`; datos mock compartidos consolidados en
   [data.jsx](mockups/mobile/data.jsx) con una fecha Ãºnica `TODAY`.
4. **Router con pila** (`useRouter` en `shared.jsx`): el botÃ³n "volver" regresa
   a la pantalla de origen real en lugar de un destino fijo.
5. **Inicio de sesiÃ³n** (`LoginScreen` en `shared.jsx` â€” **CU-01**): pantalla
   de login compartida, adaptada por rol (correo de ejemplo y etiqueta). Cada
   app de rol arranca con un gate de autenticaciÃ³n; los botones Â«Cerrar
   sesiÃ³nÂ» (CU-03) ahora regresan de verdad al login. La invalidaciÃ³n de
   token en servidor queda fuera del prototipo.

### Vista de inicio de sesiÃ³n

| Vista | FunciÃ³n â€º ubicaciÃ³n | Roles | Trazabilidad |
|---|---|---|---|
| Inicio de sesiÃ³n | `LoginScreen` â€º [shared.jsx](mockups/mobile/shared.jsx) | los 4 (member Â· trainer Â· caja Â· admin) | **CU-01**; CU-03 (logout); RNF 3 (token Â«RecordarmeÂ»); enlace CU-02 |

Se muestra antes del `home` de cada rol; al pulsar Â«Iniciar sesiÃ³nÂ» entra a la
app del rol, y Â«Cerrar sesiÃ³nÂ» vuelve aquÃ­.


