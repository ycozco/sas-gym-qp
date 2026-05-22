

---

## 11. Mockups Detallados — Vistas por Plataforma y Rol

### 11.0 Roles y Accesos (mapeo rápido)

Este mapeo resume qué rol usa cada mockup y qué permisos/acciones clave aparecen en las vistas. Se mantiene coherencia con la planificación técnica y el documento de Design Thinking (sección `1.4 Roles del Sistema`).

| Rol | Plataformas | Acciones clave en mockups |
|---|---|---|
| **Super-Admin** | Web Admin Panel | Crear/gestionar instancias, configurar pasarelas, ver reportes globales (WEB-01, WEB-09) |
| **Administrador** | Web Admin + App Admin (Flutter) | Gestionar usuarios, membresías, horarios, ver dashboard local (WEB-01, WEB-02, WEB-03, MOB-ADMIN-01) |
| **Caja / Recepción** | App Flutter (Caja) | Escanear QR, validar acceso, registrar pagos en efectivo (MOB-ADMIN-02, MOB-ADMIN-03) |
| **Entrenador** | App Entrenador (Flutter) | Ver lista de alumnos, vista técnica, asignar/editar rutinas (MOB-TRAINER-01, MOB-TRAINER-02, MOB-TRAINER-03) |
| **Usuario / Practicante** | App Usuario (Flutter) | Mostrar QR, iniciar asistente de entrenamiento, pagar membresía (ExerciseCard, QR Member Screen, Mi Agenda) |

Notas:
- En cada mockup donde se muestra información sensible (pagos, DNI, datos físicos), la vista debe respetar el principio de mínima exposición por rol.
- Las acciones rápidas en las vistas móviles (escaneo, registrar pago, marcar serie completada) deben diseñarse para un flujo en < 2 segundos cuando sea crítico.


### 11.1 Panel Admin Web (Escritorio — responsive)

> Panel de administración accesible desde navegador. Diseño sidebar izquierdo + contenido principal.

#### Layout General del Panel Web Admin

```
+--------------------------------------------------------------------------+
|  GymSmart                                    [Notif] [Marco Q.] [Config] |
+----------+---------------------------------------------------------------+
|          |                                                               |
| SIDEBAR  |                    AREA DE CONTENIDO                          |
|          |                                                               |
| Dashboard|                                                               |
| Usuarios |                                                               |
| Acceso   |                                                               |
| Pagos    |                                                               |
| Horarios |                                                               |
| Anuncios |                                                               |
| Observac.|                                                               |
| Reportes |                                                               |
| Config.  |                                                               |
|----------|---------------------------------------------------------------|
| Gym:     |                                                               |
| FitZone  |                                                               |
+----------+---------------------------------------------------------------+
```

#### WEB-01: Dashboard Admin

```
+----------------------------------------------------------------------+
|  Dashboard - FitZone Gym                           Hoy: 20 May 2026 |
+----------------------------------------------------------------------+
|                                                                      |
|  +--------------+ +--------------+ +--------------+ +------------+  |
|  |  42          | |  28          | |  S/. 2,480   | |  5         |  |
|  |  Usuarios    | |  Ingresos    | |  Cobrado     | |  Vencidos  |  |
|  |  Activos     | |  Hoy         | |  Este Mes    | |  Esta Sem. |  |
|  +--------------+ +--------------+ +--------------+ +------------+  |
|                                                                      |
|  +---------------------------------+ +--------------------------+   |
|  |  Asistencia Semanal             | |  Pagos Pendientes        |   |
|  |  +-------------------------+    | |                          |   |
|  |  |  [Grafica de barras]    |    | |  ! Diego C. - 3 dias    |   |
|  |  |  Lun Mar Mie Jue Vie   |    | |  ! Ana T.  - 1 dia      |   |
|  |  |   25  30  28  22  18   |    | |  ! Luis M. - 7 dias     |   |
|  |  +-------------------------+    | |  ! Rosa P. - hoy        |   |
|  +---------------------------------+ +--------------------------+   |
|                                                                      |
|  +---------------------------------------------------------------+  |
|  |  Ultimos Ingresos del Dia                                     |  |
|  |  OK 08:42  Diego Ccallo - Activa    X 08:50  Ana Torres - VEN |  |
|  |  OK 08:45  Maria Lopez - Activa     OK 09:01  Jose Perez - OK |  |
|  +---------------------------------------------------------------+  |
+----------------------------------------------------------------------+
```

#### WEB-02: Lista de Usuarios

```
+----------------------------------------------------------------------+
|  Usuarios                                    [+ Registrar Usuario]   |
+----------------------------------------------------------------------+
|  Buscar por nombre o DNI...           Filtro: [Todos] [Estado]       |
|                                                                      |
|  +----+--------------+----------+--------------+----------+-------+  |
|  | #  | Nombre       | DNI      | Membresia    | Entrena. | Accion|  |
|  +----+--------------+----------+--------------+----------+-------+  |
|  | 1  | Diego C.     | 72345678 | OK Activo    | Sofia M. | [...]  |  |
|  |    |              |          | Vence: 21/06 |          |        |  |
|  +----+--------------+----------+--------------+----------+-------+  |
|  | 2  | Ana T.       | 45678901 | X Vencido    | Juan P.  | [...]  |  |
|  |    |              |          | Hace 3 dias  |          |        |  |
|  +----+--------------+----------+--------------+----------+-------+  |
|  | 3  | Luis M.      | 89012345 | ~ Pendiente  | Sin asig.| [...]  |  |
|  +----+--------------+----------+--------------+----------+-------+  |
|  Mostrando 1-10 de 42 usuarios              [< 1 2 3 4 5 >]        |
+----------------------------------------------------------------------+

Menu de acciones [...]: Ver detalle | Registrar pago | Asignar entrenador |
                        Aprobar acreditacion | Dar de baja
```

#### WEB-03: Detalle de Usuario - Vista Operativa

```
+----------------------------------------------------------------------+
|  <- Volver a Usuarios        Diego Ccallo         [Registrar Pago]   |
+----------------------------------------------------------------------+
|  +-------------------------------+  +------------------------------+ |
|  |  DATOS DEL USUARIO            |  |  MEMBRESIA ACTUAL            | |
|  |  [FOTO]  Diego Ccallo         |  |  Estado: OK ACTIVO           | |
|  |          DNI: 72345678        |  |  Plan: Mensual (S/. 80)     | |
|  |          Tel: 951234567       |  |  Vence: 21/06/2026          | |
|  |  Entrenador: Sofia Mamani     |  |  ================--  31d   | |
|  +-------------------------------+  |  [Registrar Pago Efectivo]  | |
|                                      +------------------------------+ |
|  +---------------------------------------------------------------+  |
|  |  HISTORIAL DE PAGOS                                            |  |
|  |  21/05  S/.80  Efectivo  OK  |  21/04  S/.80  Yape  OK        |  |
|  |  21/03  S/.80  Pasarela  OK  |  21/02  S/.80  Efectivo  OK    |  |
|  +---------------------------------------------------------------+  |
|  +---------------------------------------------------------------+  |
|  |  ASISTENCIA (30 dias) - 18/22 dias habiles                     |  |
|  |  [Calendario con dias marcados verde/gris]                     |  |
|  +---------------------------------------------------------------+  |
+----------------------------------------------------------------------+
```

#### WEB-04: Gestion de Pagos y Acreditaciones

```
+----------------------------------------------------------------------+
|  Pagos y Acreditaciones                                              |
|  Tabs: [Pendientes (3)] [Historial] [Cobros del dia]                 |
+----------------------------------------------------------------------+
|  +---------------------------------------------------------------+  |
|  |  Ana Torres       S/. 80   Yape   20/05 08:30                 |  |
|  |  [Screenshot]   [OK Aprobar]  [X Rechazar]  [Ver grande]      |  |
|  +---------------------------------------------------------------+  |
|  +---------------------------------------------------------------+  |
|  |  Rosa Paredes     S/. 80   Plin   19/05 19:15                 |  |
|  |  [Screenshot]   [OK Aprobar]  [X Rechazar]  [Ver grande]      |  |
|  +---------------------------------------------------------------+  |
+----------------------------------------------------------------------+
```

#### WEB-05: Control de Asistencia

```
+----------------------------------------------------------------------+
|  Control de Asistencia                          Hoy: 20 Mayo 2026    |
+----------------------------------------------------------------------+
|  +----------------------+  +------------------------------------+   |
|  |  ESCANER QR           |  |  LOG DEL DIA (28 ingresos)        |   |
|  |  +------------------+ |  |  09:15 OK Carmen H. - Activa      |   |
|  |  | [AREA WEBCAM]    | |  |  09:01 OK Jose P.   - Activa      |   |
|  |  | para escaneo QR  | |  |  08:50 X  Ana T.    - VENCIDO     |   |
|  |  +------------------+ |  |  08:45 OK Maria L.  - Activa      |   |
|  |  [Buscar DNI] [Manual]|  |  08:42 OK Diego C.  - Activa      |   |
|  +----------------------+  +------------------------------------+   |
|  +---------------------------------------------------------------+  |
|  |  Asistencia por hora: Pico 6-8AM (35%), 5-7PM (40%)           |  |
|  +---------------------------------------------------------------+  |
+----------------------------------------------------------------------+
```

#### WEB-06: Gestion de Horarios y Clases

```
+----------------------------------------------------------------------+
|  Horarios y Clases                              [+ Crear Clase]      |
|  Vista: [Semanal] [Lista]              Semana: < 19-25 May 2026 >    |
+----------------------------------------------------------------------+
|  +--------+----------+----------+----------+----------+----------+  |
|  | Hora   | Lunes    | Martes   | Miercol. | Jueves   | Viernes  |  |
|  +--------+----------+----------+----------+----------+----------+  |
|  | 06:00  | CrossFit |          | CrossFit |          | CrossFit |  |
|  |        | Sofia M. |          | Sofia M. |          | Sofia M. |  |
|  |        | 8/15     |          | 12/15    |          | 5/15     |  |
|  +--------+----------+----------+----------+----------+----------+  |
|  | 18:00  | Funcional| Box      | Funcional| Box      |          |  |
|  |        | Sofia M. | Carlos R.| Sofia M. | Carlos R.|          |  |
|  |        | 14/20    | 9/15     | 16/20    | 8/15     |          |  |
|  +--------+----------+----------+----------+----------+----------+  |
|  [V] Disponible  [!] Casi lleno (>80%)  [X] Lleno (lista espera)   |
+----------------------------------------------------------------------+
```

#### WEB-07: Buzon de Observaciones

```
+----------------------------------------------------------------------+
|  Observaciones                3 sin revisar       [Todas] [Fecha]    |
+----------------------------------------------------------------------+
|  +---------------------------------------------------------------+  |
|  |  [!] SIN REVISAR                                   20/05 8:30 |  |
|  |  Diego Ccallo (Usuario)                                       |  |
|  |  "Cable de la maquina de triceps suelto"                      |  |
|  |  [thumbnail foto]           [Marcar como revisada]            |  |
|  +---------------------------------------------------------------+  |
|  +---------------------------------------------------------------+  |
|  |  [OK] REVISADA                                     18/05 15:10|  |
|  |  Sofia Mamani (Entrenador)                                    |  |
|  |  "La banca de press inclinado tiene el tapizado roto."        |  |
|  |  [thumbnail foto]                                             |  |
|  +---------------------------------------------------------------+  |
+----------------------------------------------------------------------+
```

#### WEB-08: Reportes y Analitica

```
+----------------------------------------------------------------------+
|  Reportes                         Periodo: [Este Mes] [Exportar]     |
+----------------------------------------------------------------------+
|  +------------------------------+ +------------------------------+  |
|  |  Asistencia por Semana       | |  Ingresos por Metodo         |  |
|  |  [Grafica linea]             | |  [Grafica donut]             |  |
|  |  S1:120 S2:135 S3:128 S4:140 | |  Efectivo:45% Yape:40%      |  |
|  +------------------------------+ |  Pasarela:15%                |  |
|                                    +------------------------------+  |
|  +---------------------------------------------------------------+  |
|  |  Retencion: 38/42 renovaron (90.5%) - +6 nuevos - +4.8%      |  |
|  +---------------------------------------------------------------+  |
+----------------------------------------------------------------------+
```

#### WEB-09: Configuracion del Gimnasio

```
+----------------------------------------------------------------------+
|  Configuracion del Gimnasio                        [Guardar Cambios] |
+----------------------------------------------------------------------+
|  +--------------------------------+ +----------------------------+   |
|  |  Nombre: [FitZone Gym_______]  | |  [   LOGO   ] [Cambiar]   |   |
|  |  Anos:   [5________________]   | +----------------------------+   |
|  |  Direccion: [Av. Ejercito...]  |  Redes: FB [___] IG [___]       |
|  |  Telefono: [951234567]         |  Gracia (dias): [1]             |
|  |  Horario: [6AM - 10PM]        |  Moneda: [S/.]                  |
|  |  Descripcion: [____________]   |  Zona horaria: [America/Lima]   |
|  +--------------------------------+                                  |
+----------------------------------------------------------------------+
```

---

### 11.2 Vistas Moviles - App Admin / Caja (Flutter)

#### MOB-ADMIN-01: Dashboard

```
+================================+
|  FitZone Gym         [Notif 3] |
+================================+
|  +--------+  +--------+       |
|  |  42    |  |  28    |       |
|  | Activos|  | Hoy    |       |
|  +--------+  +--------+       |
|  +--------+  +--------+       |
|  | S/.2480|  |  5     |       |
|  | mes    |  |Vencidos|       |
|  +--------+  +--------+       |
|                                |
|  ULTIMOS INGRESOS              |
|  OK 09:15 Carmen H.           |
|  X  08:50 Ana T. - VENCIDO    |
|  OK 08:42 Diego C.            |
|  [Ver todos ->]                |
+================================+
|  Home  Users  Acceso Pagos Mas |
+================================+
```

#### MOB-ADMIN-02: Escaner de Acceso (Admin y Caja)

```
+================================+
|  <- Escaner de Acceso          |
+================================+
|  +------------------------+    |
|  |                        |    |
|  |    [ AREA CAMARA  ]    |    |
|  |    [ FULLSCREEN   ]    |    |
|  |    Apunta al QR del    |    |
|  |    usuario             |    |
|  |                        |    |
|  +------------------------+    |
|  -- ULTIMO ESCANEO --          |
|  +------------------------+    |
|  |  OK ACCESO CONCEDIDO   |    |
|  |  Diego Ccallo           |    |
|  |  08:42 am - Activo      |    |
|  +------------------------+    |
+================================+
|  Home  Users  Acceso Pagos Mas |
+================================+

Feedback: Acceso Concedido (fondo verde)
+================================+
|  OK ACCESO CONCEDIDO           |
|  Diego Ccallo                  |
|  Membresia: Activa             |
|  Vence: 21/06/2026             |
|  [Escanear otro]               |
+================================+

Feedback: Acceso Denegado (fondo rojo)
+================================+
|  X ACCESO DENEGADO             |
|  Ana Torres                    |
|  Membresia: VENCIDA            |
|  Vencio hace 3 dias            |
|  [Escanear otro] [Registrar $] |
+================================+
```

#### MOB-ADMIN-03: Registrar Pago Efectivo

```
+================================+
|  <- Registrar Pago             |
+================================+
|  Diego Ccallo                  |
|  DNI: 72345678                 |
|  Estado: ! Vencido (3 dias)    |
|                                |
|  Plan:  [Mensual v]            |
|  Monto: S/. 80.00             |
|  Metodo: (x) Efectivo         |
|  Nota: [___________________]  |
|                                |
|  +------------------------+    |
|  |   CONFIRMAR PAGO       |    |
|  |   S/. 80.00            |    |
|  +------------------------+    |
|  Nueva fecha: 21/06/2026      |
+================================+
```

---

### 11.3 Vistas Moviles - App Entrenador / Instructor (Flutter)

#### MOB-TRAINER-01: Mis Usuarios (Asignados)

```
+================================+
|  Mis Usuarios        [Notif 1] |
+================================+
|  Buscar usuario...             |
|                                |
|  +------------------------+    |
|  |  Diego Ccallo           |    |
|  |  Objetivo: Hipertrofia  |    |
|  |  Peso: 72 kg            |    |
|  |  Ultima sesion: Ayer    |    |
|  +------------------------+    |
|  +------------------------+    |
|  |  Maria Lopez            |    |
|  |  Objetivo: Tonificacion |    |
|  |  Peso: 58 kg            |    |
|  |  Ultima sesion: Hace 3d |    |
|  +------------------------+    |
|  +------------------------+    |
|  |  Jose Perez             |    |
|  |  Objetivo: Fuerza       |    |
|  |  ! Sin rutina asignada  |    |
|  +------------------------+    |
+================================+
| Alumnos Biblioteca Obs. Perfil |
+================================+
```

#### MOB-TRAINER-02: Vista Tecnica del Usuario

```
+================================+
|  <- Diego Ccallo               |
+================================+
|  Tabs: [Datos] [Rutina] [Hist.]|
|                                |
|  DATOS TECNICOS                |
|  Peso: 72 kg - Altura: 175 cm |
|  Edad: 22 - Objetivo: Hipertr.|
|  Lesiones: Hombro izq.        |
|                                |
|  PROGRESO DE PESO              |
|  +------------------------+    |
|  | [Grafica de linea]     |    |
|  | Ene:75 Feb:74 May:72   |    |
|  +------------------------+    |
|                                |
|  ULTIMAS SESIONES              |
|  OK 19/05 Push (Pecho+Tric.)  |
|  OK 17/05 Pull (Espalda+Bic.) |
|  OK 15/05 Legs (Pierna)       |
|  X  13/05 Push (No asistio)   |
|                                |
|  [Asignar Rutina] [Edit Agenda]|
+================================+
```

#### MOB-TRAINER-03: Biblioteca de Ejercicios

```
+================================+
|  <- Biblioteca         [+ New] |
+================================+
|  Buscar...     [Todos v]       |
|                                |
|  PECHO                         |
|  +---------+--------------+    |
|  |  [GIF]  | Press Banca  |    |
|  | animado | 4x10, 60s    |    |
|  +---------+--------------+    |
|  +---------+--------------+    |
|  |  [GIF]  | Press Inclin.|    |
|  | animado | 3x12, 45s    |    |
|  +---------+--------------+    |
|  ESPALDA                       |
|  +---------+--------------+    |
|  |  [GIF]  | Remo barra   |    |
|  | animado | 4x10, 60s    |    |
|  +---------+--------------+    |
+================================+
| Alumnos Biblioteca Obs. Perfil |
+================================+
```

#### MOB-TRAINER-04: Agenda Semanal del Usuario

```
+================================+
|  <- Agenda de Diego Ccallo     |
+================================+
|  +---------+--------------+    |
|  | LUNES   | Push (Pecho  |    |
|  |         | + Triceps)   |    |
|  |         | [Cambiar v]  |    |
|  +---------+--------------+    |
|  | MARTES  | -- Descanso--|    |
|  +---------+--------------+    |
|  | MIERCOL | Pull (Espalda|    |
|  |         | + Biceps)    |    |
|  +---------+--------------+    |
|  | JUEVES  | -- Descanso--|    |
|  +---------+--------------+    |
|  | VIERNES | Legs (Pierna)|    |
|  +---------+--------------+    |
|  | SAB/DOM | -- Descanso--|    |
|  +---------+--------------+    |
|  +------------------------+    |
|  |   PUBLICAR AGENDA      |    |
|  +------------------------+    |
+================================+
```

---

### 11.4 Vistas Moviles - App Usuario (Flutter)

#### MOB-USER-01: Home / Feed de Anuncios

```
+================================+
|  FitZone Gym         [Notif 2] |
+================================+
|  +------------------------+    |
|  |  PROMO JUNIO!          |    |
|  |  +------------------+  |    |
|  |  | [Imagen promo]   |  |    |
|  |  +------------------+  |    |
|  |  Renueva en junio y    |    |
|  |  lleva a un amigo      |    |
|  |  gratis. - 18/05       |    |
|  +------------------------+    |
|  +------------------------+    |
|  |  Nuevo horario          |    |
|  |  Yoga Mar/Jue 7AM      |    |
|  |  15/05                  |    |
|  +------------------------+    |
+================================+
|  Home  Agenda Memb.  QR Perfil |
+================================+
```

#### MOB-USER-02: Mi Agenda Semanal

```
+================================+
|  <- Mi Agenda                  |
+================================+
|  < 19 - 25 Mayo >              |
|  +------+------------------+   |
|  | LUN  | Push (Pecho+Tric)|   |
|  |  19  | OK Completado    |   |
|  +------+------------------+   |
|  | MAR  | -- Descanso --   |   |
|  +------+------------------+   |
|  | MIE  | Pull (Espalda)   |   |
|  | HOY  | [INICIAR ENTREN.]|   |
|  +------+------------------+   |
|  | JUE  | -- Descanso --   |   |
|  +------+------------------+   |
|  | VIE  | Legs (Pierna)    |   |
|  |      | [Bloq] Proximo   |   |
|  +------+------------------+   |
|  | S/D  | -- Descanso --   |   |
|  +------+------------------+   |
+================================+
|  Home  Agenda Memb.  QR Perfil |
+================================+
```

#### MOB-USER-03: Asistente Virtual de Entrenamiento

```
+================================+
|  <- Pull (Espalda+Biceps)      |
|  Ejercicio 2 de 5              |
+================================+
|  +------------------------+    |
|  |   [GIF ANIMADO:        |    |
|  |    Remo con barra      |    |
|  |    tecnica correcta]   |    |
|  +------------------------+    |
|                                |
|  REMO CON BARRA               |
|  Serie 2 de 4                  |
|  ========--------  50%         |
|  10 reps x 50 kg sugerido     |
|  60 seg descanso               |
|                                |
|  +---------+ +--------------+  |
|  | AJUSTAR | | OK SERIE     |  |
|  | ESFUERZO| | COMPLETADA   |  |
|  +---------+ +--------------+  |
+================================+

Modal: Ajustar Esfuerzo
+================================+
|  Ajustar Esfuerzo Real         |
|  Peso real:  [ - ]  45  [ + ] |
|  Reps reales:[ - ]   8  [ + ] |
|  +------------------------+    |
|  |   GUARDAR Y CONTINUAR  |    |
|  +------------------------+    |
+================================+

Temporizador de Descanso
+================================+
|           DESCANSO             |
|         +========+             |
|        +          +            |
|        |   0:45    |            |
|        +          +            |
|         +========+             |
|  Siguiente: Press mancuernas   |
|  +------------------------+    |
|  |   SALTAR DESCANSO      |    |
|  +------------------------+    |
+================================+

Entrenamiento Completado
+================================+
|                                |
|   ENTRENAMIENTO                |
|   COMPLETADO!                  |
|   Pull (Espalda + Biceps)      |
|   5 ejercicios - 18 series     |
|   Duracion: 52 min             |
|   Remo: 45kg (sug. 50kg)      |
|   Jalon: 55kg (sug. 55kg)     |
|   +------------------------+   |
|   |     VOLVER AL INICIO    |   |
|   +------------------------+   |
+================================+
```

#### MOB-USER-04: Mi Membresia

```
+================================+
|  <- Mi Membresia               |
+================================+
|  +------------------------+    |
|  |  Estado: OK ACTIVA      |    |
|  |  Plan: Mensual          |    |
|  |  Vence: 21 Junio 2026   |    |
|  |  ================----   |    |
|  |  21 dias restantes       |    |
|  +------------------------+    |
|  +------------------------+    |
|  |   PAGAR CON YAPE/PLIN  |    |
|  +------------------------+    |
|  +------------------------+    |
|  |   ACREDITAR PAGO MANUAL |    |
|  +------------------------+    |
|  HISTORIAL                     |
|  21/05 S/.80 Efectivo OK       |
|  21/04 S/.80 Yape     OK       |
|  21/03 S/.80 Pasarela OK       |
+================================+
|  Home  Agenda Memb.  QR Perfil |
+================================+
```

#### MOB-USER-05: Mi QR de Acceso

```
+================================+
|  <- Mi QR de Acceso            |
+================================+
|  +------------------------+    |
|  |  Diego Ccallo           |    |
|  |  OK Membresia Activa    |    |
|  +------------------------+    |
|  +------------------------+    |
|  |  +------------------+  |    |
|  |  |                  |  |    |
|  |  |   == == == ==    |  |    |
|  |  |       QR         |  |    |
|  |  |   == == == ==    |  |    |
|  |  |                  |  |    |
|  |  +------------------+  |    |
|  |  Muestra este QR en    |    |
|  |  la entrada del gym    |    |
|  |  Se actualiza c/30s    |    |
|  +------------------------+    |
|  +------------------------+    |
|  |   AUMENTAR BRILLO      |    |
|  +------------------------+    |
+================================+
|  Home  Agenda Memb.  QR Perfil |
+================================+
```

#### MOB-USER-06: Mi Perfil - Tab Datos Privados

```
+================================+
|  <- Mi Perfil                  |
|  [Privado] [Social] [Fisico]   |
+================================+
|  [FOTO] Diego Ccallo           |
|         DNI: 72345678          |
|  Email: [diego@email.com]      |
|  Celular: [951234567]          |
|  [Cambiar contrasena]          |
|  +------------------------+    |
|  |    GUARDAR CAMBIOS      |    |
|  +------------------------+    |
+================================+
|  Home  Agenda Memb.  QR Perfil |
+================================+
```

#### MOB-USER-06b: Mi Perfil - Tab Social

```
+================================+
|  [Privado] [Social] [Fisico]   |
+================================+
|  [FOTO] Nickname:              |
|         [El_Diego]             |
|         [Cambiar foto]         |
|                                |
|  Modo Activo:                  |
|  [===O-----] ACTIVO            |
|  Otros usuarios pueden ver     |
|  tu foto y nickname.           |
|  +------------------------+    |
|  |    GUARDAR CAMBIOS      |    |
|  +------------------------+    |
+================================+
```

#### MOB-USER-06c: Mi Perfil - Tab Fisico (Solo visible para el usuario)

```
+================================+
|  [Privado] [Social] [Fisico]   |
+================================+
|  [Candado] Solo visible para ti|
|                                |
|  Peso actual: [72] kg          |
|  Cintura: [80] cm              |
|  Cadera:  [95] cm              |
|  Pecho:   [100] cm             |
|  Brazo:   [35] cm              |
|                                |
|  FOTOS COMPARATIVAS            |
|  +------+  +------+           |
|  |ANTES |  |DESPUES|           |
|  |Ene26 |  |May26  |           |
|  +------+  +------+           |
|  [+ Agregar foto]              |
|                                |
|  HISTORIAL DE PESO             |
|  +------------------------+    |
|  | [Grafica de linea]     |    |
|  | E:75 F:74 M:73 A:72   |    |
|  +------------------------+    |
+================================+
```

#### MOB-USER-07: Crear Observacion

```
+================================+
|  <- Nueva Observacion          |
+================================+
|  Describe el problema:         |
|  +------------------------+    |
|  | Cable de la maquina de |    |
|  | triceps suelto...      |    |
|  +------------------------+    |
|  +----------+ cable_roto.jpg   |
|  | foto     | 1.2 MB OK       |
|  | preview  | [Cambiar]        |
|  +----------+                  |
|  [Tomar foto] [Galeria]        |
|  +------------------------+    |
|  |    ENVIAR OBSERVACION   |    |
|  +------------------------+    |
+================================+
```

#### MOB-USER-08: Clases Disponibles + Reservar

```
+================================+
|  <- Clases           [Todas v] |
+================================+
|  < 19 - 25 Mayo >              |
|  MIERCOLES 21 (HOY)            |
|  +------------------------+    |
|  | 06:00  CrossFit         |    |
|  | Sofia M. - 12/15        |    |
|  | [V] Disponible          |    |
|  | [RESERVAR]              |    |
|  +------------------------+    |
|  +------------------------+    |
|  | 07:00  Spinning         |    |
|  | Juan P. - 11/12         |    |
|  | [!] Casi lleno          |    |
|  | [RESERVAR]              |    |
|  +------------------------+    |
|  +------------------------+    |
|  | 18:00  Funcional        |    |
|  | Sofia M. - 20/20        |    |
|  | [X] Lleno               |    |
|  | [LISTA DE ESPERA]       |    |
|  +------------------------+    |
+================================+
|  Home  Agenda Memb.  QR Perfil |
+================================+
```
