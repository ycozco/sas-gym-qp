# ðŸ‹ï¸ GymSmart â€” PlanificaciÃ³n TÃ©cnica Integral
## Desarrollo CrossHero como Base + Extensiones Personalizadas

> **Proyecto:** SAS GYM â€” GymSmart
> **Enfoque:** Construir todo lo que CrossHero ofrece como base, luego desarrollar lo que falta
> **Stack:** Flutter (mÃ³vil) Â· NestJS + Prisma (backend) Â· PostgreSQL (DB)
> **Arquitectura:** SaaS Multi-tenant
> **Fecha:** Mayo 2026

---

## 1. VisiÃ³n General del Producto

GymSmart es un sistema de gestiÃ³n integral para gimnasios pequeÃ±os y medianos (<100 usuarios activos por instancia). El desarrollo parte de **implementar todas las funcionalidades que CrossHero ya tiene consolidadas** como nÃºcleo del sistema, y sobre esa base se construyen los **mÃ³dulos diferenciadores** que CrossHero no cubre o cubre de forma incompleta para el mercado peruano.

```
â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•‘              GYMSMART â€” ARQUITECTURA DE PRODUCTO                â•‘
â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£
â•‘                                                                  â•‘
â•‘  CAPA 1 â€” BASE CROSSHERO (Replicar y adaptar)                   â•‘
â•‘  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”            â•‘
â•‘  â”‚ Auth & Roles â”‚ â”‚  MembresÃ­as  â”‚ â”‚  Asistencia  â”‚            â•‘
â•‘  â”‚  (Multi-rol) â”‚ â”‚  y Pagos     â”‚ â”‚  y Acceso    â”‚            â•‘
â•‘  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜            â•‘
â•‘  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”            â•‘
â•‘  â”‚  Reservas y  â”‚ â”‚  Biblioteca  â”‚ â”‚  Perfiles y  â”‚            â•‘
â•‘  â”‚  Horarios    â”‚ â”‚  Ejercicios  â”‚ â”‚  Dashboards  â”‚            â•‘
â•‘  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜            â•‘
â•‘                                                                  â•‘
â•‘  CAPA 2 â€” EXTENSIONES PERSONALIZADAS (Lo que falta)             â•‘
â•‘  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”            â•‘
â•‘  â”‚  Asistente   â”‚ â”‚  Pasarelas   â”‚ â”‚  Multi-vista â”‚            â•‘
â•‘  â”‚  Virtual     â”‚ â”‚  Peruanas    â”‚ â”‚  Privacidad  â”‚            â•‘
â•‘  â”‚  (Rutinas)   â”‚ â”‚  Yape/Plin   â”‚ â”‚  por Rol     â”‚            â•‘
â•‘  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜            â•‘
â•‘  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”            â•‘
â•‘  â”‚  Esfuerzo    â”‚ â”‚ Observacionesâ”‚ â”‚  QR DinÃ¡mico â”‚            â•‘
â•‘  â”‚  Real        â”‚ â”‚ con Foto     â”‚ â”‚  de Acceso   â”‚            â•‘
â•‘  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜            â•‘
â•‘                                                                  â•‘
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
```

---

## 2. Roles del Sistema (completos)

| Rol | DescripciÃ³n | Acceso App |
|---|---|---|
| **Super-Admin** | Gestiona el back-office SaaS global, crea instancias de gimnasios | Web Admin Panel |
| **Administrador** | Gestiona su instancia: cobros, asistencia, usuarios, anuncios | App Flutter (admin) |
| **Caja / RecepciÃ³n** | Sub-rol del Admin: cobros + control de acceso Ãºnicamente | App Flutter (caja) |
| **Entrenador** | Gestiona ejercicios, rutinas y seguimiento tÃ©cnico de sus asignados | App Flutter (trainer) |
| **Usuario** | Entrena, paga, genera su QR de acceso | App Flutter (member) |

---

Nota: Mapeo detallado de roles a vistas y mockups disponible en `planificacion_designthinking.md` secciÃ³n 1.4 (Roles del Sistema). Mantener ambos documentos sincronizados cuando se modifiquen permisos.


## 3. Funcionalidades Completas â€” CrossHero Base + Extensiones

### 3.1 MÃ“DULO A â€” AutenticaciÃ³n y GestiÃ³n de Usuarios
*(CrossHero base + adaptaciones)*

#### A.1 AutenticaciÃ³n
| Feature | Origen | DescripciÃ³n |
|---|---|---|
| Login con email/contraseÃ±a | CrossHero base | ValidaciÃ³n de credenciales, generaciÃ³n de JWT |
| "Recordarme" / Inicio automÃ¡tico | CrossHero base | Token de larga duraciÃ³n encriptado (`flutter_secure_storage`) |
| RecuperaciÃ³n de contraseÃ±a | CrossHero base | EnvÃ­o de link seguro al correo electrÃ³nico |
| Cierre de sesiÃ³n | CrossHero base | InvalidaciÃ³n del token en servidor (blacklist) |
| Multi-tenant routing | CrossHero base | Cada gimnasio tiene su `tenant_id` aislado |

#### A.2 GestiÃ³n de Usuarios
| Feature | Origen | DescripciÃ³n |
|---|---|---|
| Registro de usuario (auto) | CrossHero base | Estado "Pendiente de Pago" hasta confirmar membresÃ­a |
| Registro de usuario (manual por Admin) | CrossHero base | Admin registra directamente desde su panel |
| AsignaciÃ³n Entrenador â†’ Usuario (1:1) | ExtensiÃ³n | CrossHero permite N:N; aquÃ­ la relaciÃ³n es 1 Entrenador : N Usuarios |
| Baja lÃ³gica (Soft Delete) | CrossHero base | Estado "Inactivo", datos histÃ³ricos preservados |
| ActivaciÃ³n/reactivaciÃ³n de usuarios | CrossHero base | Cambia estado, restaura acceso |
| BÃºsqueda y filtros de usuarios | CrossHero base | Por nombre, DNI, estado membresÃ­a |
| InvitaciÃ³n de entrenadores por email | CrossHero base | Link seguro para registro inicial |

#### A.3 Perfiles (Multi-vista â€” ExtensiÃ³n clave)
| Feature | Origen | DescripciÃ³n |
|---|---|---|
| Perfil Empresa/Gimnasio | CrossHero base | Logo, nombre, horario, telÃ©fono, redes sociales |
| Perfil Profesional Entrenador | CrossHero base | Foto, especialidad, experiencia, certificaciones |
| Vista Privada del Usuario | CrossHero base | Correo, DNI, celular (solo el usuario) |
| Vista Operativa del Usuario | ExtensiÃ³n | Solo Admin: nombre, DNI, estado membresÃ­a, entrenador asignado |
| Vista TÃ©cnica del Usuario | ExtensiÃ³n | Solo Entrenador asignado: peso, lesiones, objetivo, historial |
| Vista Social del Usuario | ExtensiÃ³n | Foto/nickname, toggle Activo/Inactivo (visible para otros usuarios) |
| Vista FÃ­sica Privada del Usuario | ExtensiÃ³n | Fotos Antes/DespuÃ©s, medidas corporales (solo el usuario) |

---

### 3.2 MÃ“DULO B â€” Control de Asistencia y Acceso
*(CrossHero base + extensiÃ³n QR dinÃ¡mico)*

| Feature | Origen | DescripciÃ³n |
|---|---|---|
| Registro de ingreso al gimnasio | CrossHero base | Log con timestamp por usuario |
| Escaneo desde celular del Admin/Caja | CrossHero base | CÃ¡mara del dispositivo + biblioteca `mobile_scanner` |
| ValidaciÃ³n en tiempo real de membresÃ­a | CrossHero base | Verifica estado al momento del escaneo |
| Respuesta visual de acceso (verde/rojo) | ExtensiÃ³n | Fullscreen verde = concedido, rojo = denegado + alerta al Admin |
| QR dinÃ¡mico generado por el usuario | ExtensiÃ³n | QR con `member_id + tenant_id + timestamp` (rotaciÃ³n dinÃ¡mica) |
| Soporte cÃ¡mara fija en entrada (hardware) | ExtensiÃ³n | Endpoint REST que recibe identificador del escÃ¡ner autÃ³nomo |
| Margen de gracia de 1 dÃ­a post-vencimiento | ExtensiÃ³n | ConfiguraciÃ³n por instancia de gimnasio |
| Alerta push al Admin si membresÃ­a vencida | ExtensiÃ³n | NotificaciÃ³n en tiempo real via FCM |
| Log diario de ingresos | CrossHero base | Listado paginado con filtros de fecha |
| Registro Ãºnico de ingreso por dÃ­a | ExtensiÃ³n | Previene doble conteo si el usuario entra y sale varias veces |

---

### 3.3 MÃ“DULO C â€” GestiÃ³n de Pagos y MembresÃ­as
*(CrossHero base + pasarelas peruanas)*

| Feature | Origen | DescripciÃ³n |
|---|---|---|
| CreaciÃ³n y gestiÃ³n de planes/membresÃ­as | CrossHero base | Mensual, trimestral, anual â€” configuraciÃ³n por Admin |
| Registro de pago en efectivo | CrossHero base | Admin/Caja registra monto + confirma recepciÃ³n |
| CÃ¡lculo automÃ¡tico de fecha de vencimiento | CrossHero base | Suma duraciÃ³n del plan a la fecha de pago |
| Historial de pagos por usuario | CrossHero base | Timeline de todos los pagos registrados |
| Estados de membresÃ­a | CrossHero base | ACTIVO / VENCIDO / PENDIENTE / GRACIA / INACTIVO |
| Cobro online por pasarela (Culqi / Izipay) | ExtensiÃ³n | CrossHero usa Stripe; GymSmart usa pasarelas peruanas |
| GeneraciÃ³n de QR Yape/Plin desde pasarela | ExtensiÃ³n | QR dinÃ¡mico de cobro en pantalla del usuario |
| Webhook de confirmaciÃ³n de pago automÃ¡tica | ExtensiÃ³n | Pasarela notifica al backend, membresÃ­a se actualiza sola |
| AcreditaciÃ³n manual (upload screenshot) | ExtensiÃ³n | Usuario sube comprobante â†’ Admin aprueba/rechaza |
| NotificaciÃ³n push 7 dÃ­as antes del vencimiento | ExtensiÃ³n | Cron job diario evaluando fechas |
| Recordatorio push diario post-vencimiento | ExtensiÃ³n | Cron job, hasta que el estado cambie a ACTIVO |
| Banner en app si notificaciones deshabilitadas | ExtensiÃ³n | Fallback: alerta visual en home del usuario |
| Correo de respaldo si push deshabilitado | ExtensiÃ³n | SMTP template para recordatorio de vencimiento |
| Dashboard de caja (ingresos del dÃ­a) | ExtensiÃ³n | Resumen: efectivo, online, pendientes del dÃ­a |

---

### 3.4 MÃ“DULO D â€” Reservas y Horarios
*(CrossHero base)*

| Feature | Origen | DescripciÃ³n |
|---|---|---|
| DefiniciÃ³n de clases/horarios por Admin | CrossHero base | Nombre de clase, entrenador, dÃ­as, hora, cupo mÃ¡ximo |
| Reserva de clase por usuario | CrossHero base | Ver disponibilidad + reservar lugar |
| CancelaciÃ³n de reserva | CrossHero base | Dentro de ventana de tiempo configurable |
| Lista de espera automÃ¡tica | CrossHero base | Si clase llena, usuario entra a espera |
| NotificaciÃ³n de lugar disponible | CrossHero base | Push cuando un lugar se libera |
| Asistencia a clase (check-in en clase) | CrossHero base | ConfirmaciÃ³n de presencia en clase reservada |
| Historial de reservas del usuario | CrossHero base | Clases tomadas, canceladas, no asistidas |
| Calendario semanal del gimnasio | CrossHero base | Vista pÃºblica de todos los horarios disponibles |

> **Nota:** Las clases grupales con reserva son la forma de operar de CrossHero. GymSmart las mantiene disponibles. La agenda semanal personalizada 1:1 (por entrenador) es la **extensiÃ³n** para usuarios con entrenador asignado.

---

### 3.5 MÃ“DULO E â€” Rutinas, Agenda y Asistente Virtual
*(CrossHero base + ExtensiÃ³n asistente)*

#### E.1 Biblioteca de Ejercicios
| Feature | Origen | DescripciÃ³n |
|---|---|---|
| CRUD de ejercicios por Entrenador | CrossHero base | Nombre, descripciÃ³n, grupo muscular |
| Upload de imagen demostrativa | CrossHero base | Foto estÃ¡tica del ejercicio |
| Upload de animaciÃ³n GIF/WebM | ExtensiÃ³n | CrossHero usa imÃ¡genes estÃ¡ticas; GymSmart usa GIF/WebM animado |
| CachÃ© versionada de animaciones | ExtensiÃ³n | URL con `?v=N`, invalida cachÃ© al editar |
| CategorizaciÃ³n por grupo muscular | CrossHero base | Pecho, Espalda, Piernas, Hombros, BÃ­ceps, TrÃ­ceps, Core, etc. |
| BÃºsqueda y filtrado en biblioteca | CrossHero base | Por nombre y grupo muscular |

#### E.2 Plantillas y AsignaciÃ³n de Rutinas
| Feature | Origen | DescripciÃ³n |
|---|---|---|
| CreaciÃ³n de plantillas de rutina | CrossHero base | ColecciÃ³n de ejercicios con series, reps, peso sugerido, descanso |
| AsignaciÃ³n de rutina a usuario | CrossHero base | Entrenador vincula plantilla a su alumno |
| PersonalizaciÃ³n de plantilla por alumno | ExtensiÃ³n | El entrenador ajusta series/pesos segÃºn lesiones u objetivos especÃ­ficos |
| Agenda semanal personalizada (1:1) | ExtensiÃ³n | Entrenador define quÃ© rutina toca cada dÃ­a para cada usuario |
| PublicaciÃ³n de rutina al usuario | CrossHero base | Rutina disponible en la app del usuario tras publicar |

#### E.3 Asistente Virtual de Entrenamiento (ExtensiÃ³n completa)
| Feature | Origen | DescripciÃ³n |
|---|---|---|
| Vista de agenda semanal en app usuario | ExtensiÃ³n | Lunes-Domingo con grupo muscular del dÃ­a |
| Inicio de entrenamiento del dÃ­a | ExtensiÃ³n | Un toque â†’ lanza el asistente paso a paso |
| VisualizaciÃ³n animaciÃ³n del ejercicio | ExtensiÃ³n | GIF/WebM cargado desde cachÃ© |
| Contador de series y progreso | ExtensiÃ³n | "Serie 2 de 4" con barra de progreso |
| Peso sugerido por el entrenador | ExtensiÃ³n | Visible en pantalla durante la ejecuciÃ³n |
| Temporizador de descanso automÃ¡tico | ExtensiÃ³n | Cuenta regresiva circular, vibraciÃ³n al terminar |
| Registro de esfuerzo real | ExtensiÃ³n | Usuario ingresa peso real y reps reales por serie |
| Marcado "Entrenamiento Completado" | ExtensiÃ³n | Guarda sesiÃ³n en historial |
| Historial de sesiones por usuario | ExtensiÃ³n | Visible para el Entrenador en Vista TÃ©cnica |
| Progreso grÃ¡fico (esfuerzo en el tiempo) | ExtensiÃ³n | GrÃ¡fica de peso levantado por ejercicio a lo largo del tiempo |

---

### 3.6 MÃ“DULO F â€” ComunicaciÃ³n Interna
*(CrossHero base + extensiÃ³n observaciones)*

| Feature | Origen | DescripciÃ³n |
|---|---|---|
| PublicaciÃ³n de anuncios por Admin | CrossHero base | TÃ­tulo, descripciÃ³n, imagen opcional |
| Feed de anuncios para usuarios | CrossHero base | Visible en pantalla de inicio (banner + lista) |
| NotificaciÃ³n push de nuevo anuncio | CrossHero base | Alerta a todos los usuarios de la instancia |
| CreaciÃ³n de observaciÃ³n con foto | ExtensiÃ³n | Usuario o Entrenador reporta problema con evidencia fotogrÃ¡fica |
| BuzÃ³n de observaciones (Admin) | ExtensiÃ³n | Vista global consolidada de todas las observaciones |
| CompresiÃ³n automÃ¡tica de foto antes de upload | ExtensiÃ³n | Max 2MB, 1080px, comprimido en cliente |

---

### 3.7 MÃ“DULO G â€” Reportes y Dashboard
*(CrossHero base + extensiones analÃ­ticas)*

| Feature | Origen | DescripciÃ³n |
|---|---|---|
| Dashboard Admin: asistencia hoy | CrossHero base | Conteo de ingresos del dÃ­a |
| Dashboard Admin: membresÃ­as activas/vencidas | CrossHero base | Resumen del estado del gym |
| Dashboard Admin: ingresos del mes | CrossHero base | Total cobrado + pendientes |
| Reporte de asistencia por perÃ­odo | CrossHero base | Filtro por semana, mes, usuario |
| Reporte de pagos y cobros | CrossHero base | Historial detallado con mÃ©todo de pago |
| EstadÃ­sticas de retenciÃ³n de clientes | ExtensiÃ³n | % usuarios que renuevan vs. abandonan |
| Progreso fÃ­sico del usuario (Admin ve solo operativo) | ExtensiÃ³n | Admin ve estado de membresÃ­a, no datos fÃ­sicos |
| Progreso tÃ©cnico por usuario (Entrenador) | ExtensiÃ³n | GrÃ¡ficas de esfuerzo real por ejercicio en el tiempo |

---

### 3.8 MÃ“DULO H â€” Notificaciones y AutomatizaciÃ³n
*(ExtensiÃ³n completa sobre la base de CrossHero)*

| Feature | Origen | DescripciÃ³n |
|---|---|---|
| Push notifications base | CrossHero base | FCM para mensajes generales |
| NotificaciÃ³n vencimiento membresÃ­a (-7 dÃ­as) | ExtensiÃ³n | Cron job diario |
| Recordatorio diario post-vencimiento | ExtensiÃ³n | Cron job, hasta que pague |
| Alerta de acceso denegado al Admin | ExtensiÃ³n | Push en tiempo real cuando usuario con membresÃ­a vencida intenta ingresar |
| NotificaciÃ³n de pago confirmado | ExtensiÃ³n | Push al usuario cuando Admin registra pago o pasarela confirma |
| NotificaciÃ³n de nuevo anuncio | CrossHero base | Push masivo a todos los usuarios de la instancia |
| NotificaciÃ³n de lugar disponible en clase | CrossHero base | Push a lista de espera |

---

## 4. Arquitectura del Sistema

### 4.1 Diagrama de Capas

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    CLIENTES (Flutter App)                        â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚ App Admin â”‚  â”‚  App Entrenador â”‚  â”‚    App Usuario   â”‚   â”‚
â”‚  â”‚  / Caja   â”‚  â”‚                â”‚  â”‚                      â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚                â”‚                      â”‚
         â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                          â”‚ HTTPS / REST API
                          â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    BACKEND (NestJS)                              â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚  API Gateway + Auth Middleware (JWT + tenant_id guard)   â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚  Auth    â”‚ â”‚ Members  â”‚ â”‚Payments  â”‚ â”‚    Routines      â”‚   â”‚
â”‚  â”‚  Module  â”‚ â”‚ Module   â”‚ â”‚ Module   â”‚ â”‚    Module        â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚Attendanceâ”‚ â”‚Schedules â”‚ â”‚ Notif.   â”‚ â”‚   Observations   â”‚   â”‚
â”‚  â”‚  Module  â”‚ â”‚ Module   â”‚ â”‚ Module   â”‚ â”‚    Module        â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚              Prisma ORM (acceso a BD)                    â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚                â”‚                      â”‚
         â–¼                â–¼                      â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  PostgreSQL  â”‚  â”‚  Cloudinary / â”‚  â”‚  Firebase (FCM)           â”‚
â”‚  Multi-tenantâ”‚  â”‚  S3 Storage   â”‚  â”‚  Push Notifications       â”‚
â”‚  (tenant_id) â”‚  â”‚  (fotos/GIFs) â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### 4.2 Estrategia Multi-tenant

```
OpciÃ³n elegida: tenant_id en todas las tablas (Row-Level Security)

Ventajas para un SaaS de inicio:
  âœ… Base de datos Ãºnica (menor costo operativo)
  âœ… Migraciones de schema mÃ¡s simples
  âœ… Escalabilidad horizontal sin complejidad de routing

Reglas de implementaciÃ³n:
  1. TODOS los queries incluyen WHERE tenant_id = :tenantId
  2. Middleware de NestJS extrae tenant_id del JWT en cada request
  3. NingÃºn endpoint opera sin tenant_id validado
  4. Super-Admin tiene un tenant_id especial ('PLATFORM') para operaciones globales
```

### 4.3 Estructura del Proyecto Flutter (Feature-First)

```
gym_smart_app/
â”œâ”€â”€ lib/
â”‚   â”œâ”€â”€ core/
â”‚   â”‚   â”œâ”€â”€ auth/
â”‚   â”‚   â”‚   â”œâ”€â”€ auth_provider.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ jwt_service.dart
â”‚   â”‚   â”‚   â””â”€â”€ role_guard.dart
â”‚   â”‚   â”œâ”€â”€ network/
â”‚   â”‚   â”‚   â”œâ”€â”€ api_client.dart            # Dio + interceptors
â”‚   â”‚   â”‚   â”œâ”€â”€ tenant_interceptor.dart    # Agrega tenant_id a headers
â”‚   â”‚   â”‚   â””â”€â”€ auth_interceptor.dart      # Refresco de JWT automÃ¡tico
â”‚   â”‚   â”œâ”€â”€ storage/
â”‚   â”‚   â”‚   â”œâ”€â”€ secure_storage.dart        # JWT (flutter_secure_storage)
â”‚   â”‚   â”‚   â””â”€â”€ local_cache.dart           # Hive (rutinas offline)
â”‚   â”‚   â”œâ”€â”€ theme/
â”‚   â”‚   â”‚   â”œâ”€â”€ app_theme.dart             # Dark theme principal
â”‚   â”‚   â”‚   â”œâ”€â”€ colors.dart                # Paleta de colores
â”‚   â”‚   â”‚   â””â”€â”€ typography.dart            # Inter font scales
â”‚   â”‚   â””â”€â”€ router/
â”‚   â”‚       â”œâ”€â”€ app_router.dart            # go_router
â”‚   â”‚       â””â”€â”€ route_guards.dart          # Guards por rol
â”‚   â”‚
â”‚   â”œâ”€â”€ features/
â”‚   â”‚   â”œâ”€â”€ auth/
â”‚   â”‚   â”‚   â”œâ”€â”€ data/                      # Repository + API calls
â”‚   â”‚   â”‚   â”œâ”€â”€ domain/                    # Use cases
â”‚   â”‚   â”‚   â””â”€â”€ presentation/             # Screens + providers
â”‚   â”‚   â”‚       â”œâ”€â”€ login_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ forgot_password_screen.dart
â”‚   â”‚   â”‚       â””â”€â”€ auth_provider.dart
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ dashboard/                     # Por rol (Admin / Trainer / Member)
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ members/                       # GestiÃ³n de usuarios (Admin)
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ members_list_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ member_detail_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ member_profile_admin_view.dart  # Vista operativa
â”‚   â”‚   â”‚       â””â”€â”€ assign_trainer_screen.dart
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ profile/                       # Perfiles multi-vista
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ gym_profile_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ trainer_profile_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ member_private_view.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ member_social_view.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ member_technical_view.dart     # Solo entrenador
â”‚   â”‚   â”‚       â””â”€â”€ member_physical_view.dart      # Solo usuario
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ attendance/
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ scanner_screen.dart             # Admin/Caja: escanear
â”‚   â”‚   â”‚       â”œâ”€â”€ attendance_log_screen.dart      # Log del dÃ­a
â”‚   â”‚   â”‚       â””â”€â”€ qr_member_screen.dart           # Usuario: su QR
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ payments/
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ membership_status_screen.dart   # Usuario
â”‚   â”‚   â”‚       â”œâ”€â”€ pay_online_screen.dart          # WebView pasarela
â”‚   â”‚   â”‚       â”œâ”€â”€ manual_accreditation_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ register_cash_payment_screen.dart # Caja
â”‚   â”‚   â”‚       â””â”€â”€ approve_accreditation_screen.dart # Admin
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ schedules/                     # Horarios y reservas (CrossHero)
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ schedule_calendar_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ book_class_screen.dart
â”‚   â”‚   â”‚       â””â”€â”€ my_bookings_screen.dart
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ routines/
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ exercise_library_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ create_exercise_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ assign_routine_screen.dart
â”‚   â”‚   â”‚       â”œâ”€â”€ weekly_agenda_screen.dart       # Usuario: mi agenda
â”‚   â”‚   â”‚       â””â”€â”€ workout_assistant_screen.dart   # Asistente virtual
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ observations/
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ create_observation_screen.dart
â”‚   â”‚   â”‚       â””â”€â”€ observations_inbox_screen.dart  # Admin: buzÃ³n global
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ announcements/
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ announcements_feed_screen.dart
â”‚   â”‚   â”‚       â””â”€â”€ create_announcement_screen.dart # Admin
â”‚   â”‚   â”‚
â”‚   â”‚   â””â”€â”€ reports/
â”‚   â”‚       â””â”€â”€ presentation/
â”‚   â”‚           â”œâ”€â”€ admin_dashboard_screen.dart
â”‚   â”‚           â””â”€â”€ trainer_progress_screen.dart
â”‚   â”‚
â”‚   â”œâ”€â”€ shared/
â”‚   â”‚   â”œâ”€â”€ widgets/
â”‚   â”‚   â”‚   â”œâ”€â”€ gym_button.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ gym_card.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ role_badge.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ membership_status_chip.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ exercise_gif_player.dart        # CachÃ© versionada
â”‚   â”‚   â”‚   â”œâ”€â”€ rest_timer_widget.dart          # Temporizador circular
â”‚   â”‚   â”‚   â””â”€â”€ qr_display_widget.dart
â”‚   â”‚   â””â”€â”€ models/
â”‚   â”‚       â”œâ”€â”€ user.dart
â”‚   â”‚       â”œâ”€â”€ membership.dart
â”‚   â”‚       â”œâ”€â”€ routine.dart
â”‚   â”‚       â””â”€â”€ exercise.dart
â”‚   â”‚
â”‚   â””â”€â”€ main.dart
â”‚
â”œâ”€â”€ test/
â”‚   â”œâ”€â”€ unit/
â”‚   â”œâ”€â”€ widget/
â”‚   â””â”€â”€ integration/
â””â”€â”€ pubspec.yaml
```

---

## 5. Modelo de Datos Completo (Prisma Schema)

```prisma
// â”€â”€â”€ MULTI-TENANT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ USUARIOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // Relaciones segÃºn rol
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

// â”€â”€â”€ PERFILES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // Vista TÃ©cnica (solo entrenador ve)
  peso_kg             Float?
  altura_cm           Float?
  objetivo            String?
  lesiones            String?

  // Vista FÃ­sica (solo el usuario ve)
  medidas_json        Json?    // { cintura: 80, cadera: 95, pecho: 100 }
  fotos_comparativas  String[] // URLs de fotos Antes/DespuÃ©s

  workout_sessions    WorkoutSession[]
  routine_assignments RoutineAssignment[]
}

// â”€â”€â”€ MEMBRESÃAS Y PAGOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  GRACE      // Dentro del dÃ­a de gracia
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
  comprobante_url     String?       // Para acreditaciÃ³n manual
  referencia_externa  String?       // ID de transacciÃ³n de la pasarela
  timestamp           DateTime      @default(now())
}

enum PaymentMethod {
  CASH
  GATEWAY      // Culqi / Izipay
  MANUAL_YAPE  // AcreditaciÃ³n manual Yape
  MANUAL_PLIN  // AcreditaciÃ³n manual Plin
}

enum PaymentState {
  PENDING
  APPROVED
  REJECTED
}

// â”€â”€â”€ ASISTENCIA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  QR_AUTONOMOUS  // CÃ¡mara fija
  QR_ADMIN       // Admin escaneÃ³ desde celular
  MANUAL_ADMIN   // Admin registrÃ³ manualmente
}

// â”€â”€â”€ RESERVAS Y HORARIOS (CrossHero) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
model Schedule {
  id              String   @id @default(uuid())
  tenant_id       String
  tenant          Tenant   @relation(fields: [tenant_id], references: [id])
  trainer_id      String
  nombre_clase    String
  descripcion     String?
  dia_semana      Int[]    // [1,3,5] = Lunes, MiÃ©rcoles, Viernes
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
  fecha       DateTime      // Fecha especÃ­fica de la clase
  estado      BookingState  @default(CONFIRMED)
  created_at  DateTime      @default(now())
}

enum BookingState {
  CONFIRMED
  CANCELLED
  WAITLIST
  ATTENDED
}

// â”€â”€â”€ EJERCICIOS Y RUTINAS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  animacion_version Int      @default(1)  // Incrementar para invalidar cachÃ©
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

// â”€â”€â”€ OBSERVACIONES Y ANUNCIOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

## 6. APIs REST â€” Endpoints Principales

### Auth
```
POST   /auth/login                     # Login, retorna JWT + refreshToken
POST   /auth/refresh                   # Renueva JWT usando refreshToken
POST   /auth/logout                    # Invalida token en servidor
POST   /auth/forgot-password           # EnvÃ­a email de recuperaciÃ³n
POST   /auth/reset-password            # Cambia contraseÃ±a con token del email
POST   /auth/register                  # Registro de usuario (auto)
```

### Users / Members
```
GET    /users                          # Lista usuarios (paginada, filtros)
GET    /users/:id                      # Detalle de usuario
PATCH  /users/:id                      # Actualizar perfil
DELETE /users/:id                      # Baja lÃ³gica (soft delete)
POST   /users/:id/assign-trainer       # Asignar entrenador a usuario
GET    /users/:id/profile/technical    # Vista tÃ©cnica (solo trainer asignado)
GET    /users/:id/profile/physical     # Vista fÃ­sica (solo el propio usuario)
```

### Memberships & Payments
```
GET    /memberships/:userId            # MembresÃ­a activa del usuario
POST   /memberships                    # Crear nueva membresÃ­a
PATCH  /memberships/:id/status         # Actualizar estado manualmente
POST   /payments/cash                  # Registrar pago en efectivo (Caja)
POST   /payments/gateway/create        # Generar QR/link de cobro (Culqi/Izipay)
POST   /payments/gateway/webhook       # Webhook de confirmaciÃ³n de pasarela
POST   /payments/manual/upload         # Usuario sube screenshot
PATCH  /payments/:id/approve           # Admin aprueba acreditaciÃ³n manual
PATCH  /payments/:id/reject            # Admin rechaza acreditaciÃ³n
GET    /payments/history/:userId       # Historial de pagos
```

### Attendance
```
POST   /attendance/scan                # Validar QR/DNI, registrar ingreso
GET    /attendance/today               # Log de asistencia del dÃ­a
GET    /attendance/member/:userId      # Historial de asistencia del usuario
GET    /attendance/stats               # EstadÃ­sticas (por perÃ­odo)
GET    /members/:id/qr                 # Genera / retorna QR dinÃ¡mico del usuario
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
POST   /exercises                      # Crear ejercicio (con upload animaciÃ³n)
PUT    /exercises/:id                  # Editar + incrementar versiÃ³n cachÃ©
DELETE /exercises/:id                  # Eliminar (soft)
POST   /routines/templates             # Crear plantilla de rutina
GET    /routines/templates             # Listar plantillas del entrenador
PUT    /routines/templates/:id         # Editar plantilla
POST   /routines/assign                # Asignar rutina + agenda a usuario
GET    /routines/my-agenda             # Agenda semanal del usuario
POST   /routines/sessions/start        # Iniciar sesiÃ³n de entrenamiento
POST   /routines/sessions/:id/log      # Registrar serie (esfuerzo real)
POST   /routines/sessions/:id/complete # Marcar sesiÃ³n como completada
GET    /routines/sessions/:userId      # Historial de sesiones (entrenador)
```

### Observations & Announcements
```
POST   /observations                   # Crear observaciÃ³n (con foto)
GET    /observations                   # BuzÃ³n global (solo Admin)
PATCH  /observations/:id/reviewed      # Marcar como revisada
POST   /announcements                  # Publicar anuncio
GET    /announcements                  # Feed de anuncios de la instancia
DELETE /announcements/:id              # Eliminar anuncio
```

---

## 7. Stack TecnolÃ³gico Completo

### Flutter (App MÃ³vil)
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

  # QR & CÃ¡mara
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

  # UI / GrÃ¡ficas
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

### ðŸ“¦ Sprint 0 â€” Infraestructura y Setup (Semana 0)

**Backend:**
- [ ] Inicializar proyecto NestJS con arquitectura modular
- [ ] Configurar Prisma + PostgreSQL (schema inicial)
- [ ] Configurar variables de entorno (.env, ConfigModule)
- [ ] Middleware global: `tenant_id` extractor del JWT
- [ ] Configurar Firebase Admin SDK
- [ ] Setup Docker Compose (postgres + app backend)
- [ ] CI/CD bÃ¡sico (GitHub Actions â†’ build + lint)

**Flutter:**
- [ ] Inicializar proyecto Flutter con clean architecture
- [ ] Configurar `go_router` con estructura de rutas por rol
- [ ] Configurar Riverpod + providers base
- [ ] Configurar `flutter_secure_storage` para JWT
- [ ] Configurar Dio + interceptors (auth + tenant)
- [ ] Setup Firebase para FCM
- [ ] Primer build funcional en dispositivo fÃ­sico Android

---

### ðŸ“¦ Sprint 1 â€” Auth + Multi-tenant (Semanas 1-2)
*Equivalente CrossHero: mÃ³dulo de autenticaciÃ³n*

**Backend:**
- [ ] MÃ³dulo Auth: login, registro, logout, JWT refresh
- [ ] Guard global de tenant + rol (`@Roles()`, `@TenantId()`)
- [ ] MÃ³dulo Tenants: CRUD de instancias de gimnasio (Super-Admin)
- [ ] Endpoint `/auth/forgot-password` + `/auth/reset-password`
- [ ] Token blacklist en memoria (Redis o DB)

**Flutter:**
- [ ] Pantalla Login (email + contraseÃ±a + "Recordarme")
- [ ] Pantalla Recuperar contraseÃ±a
- [ ] AuthProvider con Riverpod (estado de sesiÃ³n global)
- [ ] Routing condicional post-login (redirige segÃºn `rol`)
- [ ] Logout con invalidaciÃ³n de token en servidor
- [ ] Scaffold base de home para cada rol (Admin / Trainer / Member / Caja)

---

### ðŸ“¦ Sprint 2 â€” Perfiles y GestiÃ³n de Usuarios (Semanas 3-4)
*Equivalente CrossHero: gestiÃ³n de usuarios y perfiles*

**Backend:**
- [ ] MÃ³dulo Users: CRUD completo con guards de rol
- [ ] Endpoint Vista TÃ©cnica (solo entrenador asignado)
- [ ] Endpoint Vista FÃ­sica (solo propio usuario)
- [ ] ValidaciÃ³n DNI Ãºnico por tenant
- [ ] Upload de foto de perfil (Cloudinary/S3 + compresiÃ³n con Sharp)
- [ ] AsignaciÃ³n Entrenador â†’ Usuario
- [ ] Baja lÃ³gica (soft delete, campo `estado = INACTIVE`)

**Flutter:**
- [ ] Pantalla: Lista de usuarios (Admin) con bÃºsqueda + filtros
- [ ] Pantalla: Detalle usuario â†’ Vista Operativa (Admin)
- [ ] Pantalla: Vista TÃ©cnica (Entrenador â€” solo sus asignados)
- [ ] Pantalla: Perfil propio del Usuario (multi-tab: Privado / Social / FÃ­sico)
- [ ] Pantalla: Perfil Empresa/Gimnasio (Admin edita, todos ven)
- [ ] Pantalla: Perfil Entrenador (ediciÃ³n propia)
- [ ] Pantalla: Asignar entrenador (Admin)
- [ ] Flujo: Registro de usuario (auto + manual Admin)
- [ ] Flujo: Dar de baja con confirmaciÃ³n

---

### ðŸ“¦ Sprint 3 â€” Pagos y Control de Asistencia (Semanas 5-7)
*Equivalente CrossHero: membresÃ­as + pagos + control de acceso*

**Backend:**
- [ ] MÃ³dulo Memberships: CRUD, estados, cÃ¡lculo de vencimiento
- [ ] MÃ³dulo Payments: efectivo, gateway, webhook Culqi/Izipay, acreditaciÃ³n manual
- [ ] IntegraciÃ³n Culqi o Izipay: generaciÃ³n de QR/link de cobro
- [ ] Webhook handler de confirmaciÃ³n de pago (actualiza membresÃ­a automÃ¡ticamente)
- [ ] MÃ³dulo Attendance: validar QR, registrar ingreso, log diario
- [ ] Endpoint: Generar QR dinÃ¡mico del usuario (`member_id + tenant_id + ts`)
- [ ] Endpoint: Soporte cÃ¡mara fija (recibe identificador externo)
- [ ] Margen de gracia de 1 dÃ­a (configurable por tenant)
- [ ] Cron job: notificaciÃ³n 7 dÃ­as antes del vencimiento
- [ ] Cron job: recordatorio diario post-vencimiento
- [ ] Push FCM: alerta a Admin cuando acceso denegado

**Flutter:**
- [ ] Pantalla: EscÃ¡ner QR/DNI fullscreen (Admin/Caja) â€” `mobile_scanner`
- [ ] Feedback visual: Verde (acceso concedido) / Rojo (denegado) con animaciÃ³n
- [ ] Pantalla: Log de ingresos del dÃ­a (Admin/Caja)
- [ ] Pantalla: QR dinÃ¡mico del usuario (fullscreen, `qr_flutter`)
- [ ] Pantalla: Estado de membresÃ­a (Usuario) con progress bar dÃ­as restantes
- [ ] Pantalla: Pagar online â†’ WebView pasarela (Culqi/Izipay QR o link)
- [ ] Pantalla: Acreditar pago manual (upload screenshot, `image_picker`)
- [ ] Pantalla: Registrar pago efectivo (Admin/Caja)
- [ ] Pantalla: Aprobar/rechazar acreditaciÃ³n manual (Admin)
- [ ] ConfiguraciÃ³n FCM y push notifications

---

### ðŸ“¦ Sprint 4 â€” Reservas y Horarios (Semana 8)
*CrossHero base: horarios y reservas de clases*

**Backend:**
- [ ] MÃ³dulo Schedules: CRUD de clases con cupo y horario
- [ ] MÃ³dulo Bookings: reservar, cancelar, lista de espera automÃ¡tica
- [ ] LÃ³gica de cupo: si clase llena â†’ entra a lista de espera
- [ ] NotificaciÃ³n push cuando se libera un lugar de lista de espera
- [ ] Registro de asistencia a clase (check-in en clase especÃ­fica)

**Flutter:**
- [ ] Pantalla: Calendario semanal del gimnasio (todos los horarios)
- [ ] Pantalla: Reservar clase (ver disponibilidad + confirmar)
- [ ] Pantalla: Mis reservas (historial + prÃ³ximas)
- [ ] Pantalla: GestiÃ³n de clases (Admin: crear/editar/eliminar)
- [ ] Push notification: lugar disponible en lista de espera

---

### ðŸ“¦ Sprint 5 â€” Rutinas, Biblioteca y Asistente Virtual (Semanas 9-11)
*CrossHero base (biblioteca + asignaciÃ³n) + ExtensiÃ³n (asistente virtual)*

**Backend:**
- [ ] MÃ³dulo Exercises: CRUD con upload GIF/WebM (Cloudinary/S3), versionado de cachÃ©
- [ ] MÃ³dulo RoutineTemplates: CRUD con lista de ejercicios + configuraciÃ³n por serie
- [ ] MÃ³dulo RoutineAssignments: asignar plantilla + agenda semanal personalizada
- [ ] MÃ³dulo WorkoutSessions: iniciar sesiÃ³n, log de series, completar sesiÃ³n
- [ ] Endpoint: Historial de sesiones por usuario (para entrenador)
- [ ] Endpoint: Agenda semanal del usuario (quÃ© rutina toca hoy)

**Flutter:**
- [ ] Pantalla: Biblioteca de ejercicios (Entrenador) â€” lista con thumbnail GIF
- [ ] Pantalla: Crear/Editar ejercicio (Entrenador) â€” upload GIF/WebM con `flutter_image_compress`
- [ ] `ExerciseGifPlayer`: widget con cachÃ© versionada (`flutter_cache_manager`)
- [ ] Pantalla: Crear plantilla de rutina (Entrenador) â€” drag & drop orden de ejercicios
- [ ] Pantalla: Asignar rutina a usuario + configurar agenda semanal
- [ ] Pantalla: Mi Agenda Semanal (Usuario) â€” vista Lunes-Domingo con rutina del dÃ­a
- [ ] Pantalla: **Asistente Virtual** (Usuario):
  - [ ] Header: nombre rutina + N ejercicios
  - [ ] GIF del ejercicio en tiempo real (cacheado)
  - [ ] Indicador serie actual: "Serie 2 de 4"
  - [ ] Peso sugerido por el entrenador
  - [ ] BotÃ³n "Serie Completada" â†’ activa temporizador
  - [ ] `RestTimerWidget`: temporizador circular cuenta regresiva con vibraciÃ³n al llegar a 0
  - [ ] BotÃ³n "Ajustar Esfuerzo" â†’ modal para ingresar peso real + reps reales
  - [ ] Avance automÃ¡tico al siguiente ejercicio / serie
  - [ ] Pantalla de finalizaciÃ³n "Â¡Entrenamiento Completado! ðŸ’ª"
- [ ] Pantalla: Vista TÃ©cnica Entrenador (historial de sesiones + grÃ¡fica de progreso)
- [ ] GrÃ¡fica de progreso por ejercicio (`fl_chart`)

---

### ðŸ“¦ Sprint 6 â€” Observaciones, Anuncios y Reportes (Semanas 12-13)
*CrossHero base (anuncios) + Extensiones (observaciones + dashboard)*

**Backend:**
- [ ] MÃ³dulo Observations: crear con foto (upload S3), buzÃ³n global del Admin
- [ ] MÃ³dulo Announcements: crear/publicar/eliminar, feed por instancia
- [ ] MÃ³dulo Reports: estadÃ­sticas de asistencia, ingresos, retenciÃ³n
- [ ] Endpoint: Dashboard Admin (resumen en tiempo real)

**Flutter:**
- [ ] Pantalla: Crear observaciÃ³n (texto + foto, compresiÃ³n automÃ¡tica antes de upload)
- [ ] Pantalla: BuzÃ³n de Observaciones (Admin) â€” lista con miniaturas, fullscreen en tap
- [ ] Pantalla: Crear anuncio (Admin) â€” tÃ­tulo + descripciÃ³n + imagen opcional
- [ ] Pantalla: Feed de anuncios (Usuario/Entrenador) â€” banner destacado + lista
- [ ] Pantalla: Dashboard Admin â€” cards con mÃ©tricas en tiempo real
- [ ] Pantalla: Reportes (grÃ¡ficas de asistencia y pagos por perÃ­odo)

---

### ðŸ“¦ Sprint 7 â€” Polish, Testing y Deploy (Semanas 14-15)

- [ ] Dark theme finalizado con todos los componentes
- [ ] Shimmer loading en todas las listas y cards
- [ ] Mensajes de error y estados vacÃ­os diseÃ±ados
- [ ] Validaciones de formularios (DNI peruano 8 dÃ­gitos, email, celular)
- [ ] CompresiÃ³n de imÃ¡genes verificada < 2MB en todos los uploads
- [ ] Testing unitario: use cases y repositories
- [ ] Testing de widget: pantallas crÃ­ticas (login, escÃ¡ner, asistente)
- [ ] Testing de integraciÃ³n: flujo completo ingreso â†’ pago â†’ entrenamiento
- [ ] Testing en dispositivos Android reales (gama baja y media)
- [ ] OptimizaciÃ³n de performance (splash screen, lazy loading de rutas)
- [ ] Build APK de producciÃ³n + firma
- [ ] Deploy backend en VPS / Railway / Render
- [ ] ConfiguraciÃ³n de dominio y SSL

---

## 9. Comparativa CrossHero vs GymSmart

| MÃ³dulo | CrossHero | GymSmart | Diferencia |
|---|---|---|---|
| Auth y roles | âœ… Multi-rol + JWT | âœ… Igual + sub-rol Caja | Se agrega rol `CAJA` con permisos limitados |
| GestiÃ³n de miembros | âœ… Completo | âœ… + Vista multi-rol (4 vistas por usuario) | CrossHero no tiene segmentaciÃ³n tan granular de privacidad |
| MembresÃ­as | âœ… Planes y estados | âœ… + Gracia 1 dÃ­a + alertas automÃ¡ticas | CrossHero tiene alertas bÃ¡sicas |
| Pagos | âœ… Stripe (tarjetas) | âœ… Culqi/Izipay (Yape/Plin) + acreditaciÃ³n manual | Pasarelas del mercado peruano |
| Control de acceso | âœ… Check-in app | âœ… + QR dinÃ¡mico usuario + cÃ¡mara fija hardware | CrossHero no tiene QR generado por el usuario |
| Reservas/Horarios | âœ… Clases grupales con cupo y lista de espera | âœ… Igual | Paridad completa |
| Biblioteca ejercicios | âœ… Imagen estÃ¡tica | âœ… + GIF/WebM animado + cachÃ© versionada | CrossHero no tiene animaciones |
| AsignaciÃ³n rutinas | âœ… AsignaciÃ³n bÃ¡sica | âœ… + Agenda semanal personalizada 1:1 | CrossHero no tiene agenda dÃ­a por dÃ­a |
| Asistente virtual | âŒ No tiene | âœ… GIF + temporizador + esfuerzo real | Funcionalidad nueva completa |
| Historial esfuerzo | âŒ No tiene | âœ… Series por sesiÃ³n + grÃ¡ficas de progreso | Funcionalidad nueva completa |
| Observaciones | âŒ No tiene | âœ… Con foto + buzÃ³n Admin | Funcionalidad nueva completa |
| Anuncios/Feed | âœ… BÃ¡sico | âœ… + Push notification masiva + imagen | ExtensiÃ³n del mÃ³dulo base |
| Reportes | âœ… BÃ¡sicos | âœ… + RetenciÃ³n + progreso tÃ©cnico | ExtensiÃ³n con analÃ­tica adicional |
| Multi-tenant | âœ… Por organizaciÃ³n | âœ… tenant_id en todas las tablas | Misma estrategia, implementaciÃ³n propia |

---

## 10. Checklist de Pantallas â€” VerificaciÃ³n de Completitud

### Admin / Caja
- [ ] Login y recuperaciÃ³n de contraseÃ±a
- [ ] Dashboard principal (mÃ©tricas en tiempo real)
- [ ] Lista de usuarios (bÃºsqueda + filtros)
- [ ] Detalle usuario (Vista Operativa)
- [ ] Asignar entrenador a usuario
- [ ] Dar de baja usuario (soft delete)
- [ ] EscÃ¡ner QR/DNI de ingreso
- [ ] Log de asistencia del dÃ­a
- [ ] Registrar pago en efectivo
- [ ] Aprobar/rechazar acreditaciÃ³n manual
- [ ] GestiÃ³n de clases/horarios (CRUD)
- [ ] BuzÃ³n de observaciones (global)
- [ ] Crear y publicar anuncio
- [ ] ConfiguraciÃ³n perfil del gimnasio
- [ ] Reportes de asistencia y pagos

### Entrenador
- [ ] Lista de usuarios asignados
- [ ] Vista TÃ©cnica de usuario
- [ ] Historial de sesiones del usuario + grÃ¡fica progreso
- [ ] Biblioteca de ejercicios (lista + thumbnails)
- [ ] Crear/editar ejercicio (upload GIF/WebM)
- [ ] Crear/editar plantilla de rutina
- [ ] Asignar rutina + agenda semanal a usuario
- [ ] Crear observaciÃ³n (texto + foto)
- [ ] Feed de anuncios
- [ ] Perfil profesional (ediciÃ³n)

### Usuario
- [ ] Home con feed de anuncios
- [ ] Agenda semanal personalizada
- [ ] Asistente virtual de entrenamiento (GIF + temporizador + esfuerzo real)
- [ ] Pantalla de finalizaciÃ³n de entrenamiento
- [ ] Estado de membresÃ­a (dÃ­as restantes + progress bar)
- [ ] Pagar online (WebView pasarela)
- [ ] Acreditar pago manual (upload screenshot)
- [ ] QR dinÃ¡mico de acceso (fullscreen)
- [ ] Calendario de clases grupales + reservar
- [ ] Mis reservas
- [ ] Crear observaciÃ³n
- [ ] Perfil: datos privados
- [ ] Perfil: vista social (toggle Activo/Inactivo)
- [ ] Perfil: vista fÃ­sica (fotos A/D, medidas)


