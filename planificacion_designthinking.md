# 🏋️ GymSmart — Design Thinking Completo
## Proceso de Diseño, Problemas y Contexto de Usuario

> **Proyecto:** SAS GYM — GymSmart
> **Metodología:** Design Thinking (Stanford d.school)
> **Contexto geográfico:** Arequipa, Perú — gimnasios pequeños y medianos
> **Fecha:** Mayo 2026

---

## FASE 1 — EMPATIZAR

### 1.1 Contexto Real: El Gimnasio de Arequipa en 2026

Los gimnasios pequeños y medianos en Arequipa operan en su mayoría con **sistemas completamente manuales o en papel**. Este es el entorno real que GymSmart busca transformar:

```
Estado actual típico de un gimnasio arequipeño:

┌─────────────────────────────────────────────────┐
│  RECEPCIÓN                                       │
│  ┌──────────────────────────────┐               │
│  │  Cuaderno de asistencia      │  ← Papel      │
│  │  con nombres y fechas        │               │
│  └──────────────────────────────┘               │
│  ┌──────────────────────────────┐               │
│  │  Fichas de pago mensual      │  ← Papel      │
│  │  (a veces Excel desactual.)  │               │
│  └──────────────────────────────┘               │
│                                                  │
│  ENTRENADOR                                      │
│  ┌──────────────────────────────┐               │
│  │  Rutinas escritas a mano     │  ← Papel      │
│  │  en hojas sueltas            │               │
│  └──────────────────────────────┘               │
└─────────────────────────────────────────────────┘
```

### 1.2 Problemas Observados en Arequipa (Investigación de Campo)

#### 🔴 Problemas Críticos (Impacto Alto)

| # | Problema | Consecuencia |
|---|---|---|
| P1 | **Registro de asistencia en cuaderno físico** | Imposible saber si alguien entró sin permiso. Sin histórico digital. Pérdida de cuadernos. |
| P2 | **Cobros y vencimientos gestionados de memoria o en Excel sin sincronización** | Usuarios con mensualidad vencida siguen entrando. Deuda acumulada sin alertas. |
| P3 | **Sin notificación de vencimiento al usuario** | El usuario se entera cuando ya debe. Fricción en la relación cliente-gimnasio. |
| P4 | **Rutinas escritas a mano en hojas sueltas** | El usuario pierde la hoja. El entrenador no sabe si la rutina se ejecutó. |
| P5 | **Sin historial de progreso del usuario** | El entrenador no puede ajustar la rutina basándose en datos reales de rendimiento. |

#### 🟡 Problemas Moderados

| # | Problema | Consecuencia |
|---|---|---|
| P6 | **Cobros en efectivo sin comprobante digital** | Sin trazabilidad. Disputas sobre si se pagó o no. |
| P7 | **Sin centralización de información entre admin y entrenador** | El admin no sabe qué rutina tiene asignada el usuario. El entrenador no sabe si el usuario está al día en pagos. |
| P8 | **Comunicación por WhatsApp personal del dueño** | Anuncios pierden contexto. El usuario no sabe sobre promociones. |
| P9 | **Fotos de progreso físico enviadas por WhatsApp** | Privacidad comprometida. Sin comparativa visual ordenada. |
| P10 | **Sin diferenciación de rol entrenador/admin** | El entrenador ve información de pagos que no le compete. |

#### 🟢 Problemas Menores (Oportunidades de mejora)

| # | Problema |
|---|---|
| P11 | Sin ejercicios con demostración visual (el usuario hace mal el movimiento) |
| P12 | Sin estadísticas de asistencia para el dueño del gimnasio |
| P13 | Sin buzón para que el usuario reporte máquinas dañadas |

---

### 1.3 Personas (Arquetipos de Usuario)

#### 👤 Persona 1: Marco — El Dueño/Admin del Gimnasio
```
Nombre:   Marco Quispe
Edad:     38 años
Ciudad:   Arequipa (Cercado)
Negocio:  Gym propio, 5 años operando, ~60 usuarios activos

Motivaciones:
- Que nadie entre sin pagar
- Saber cuántos vienen cada día
- No tener problemas con los pagos
- Comunicarse con sus clientes fácilmente

Frustraciones:
- "Se me olvida quién debe el mes"
- "A veces el encargado deja entrar a alguien sin revisar"
- "Tengo un Excel pero lo actualizo solo los martes"
- "No sé si los entrenadores están haciendo bien su trabajo"

Tecnología:
- Smartphone Android de gama media
- Usa WhatsApp intensamente
- Excel básico, nunca instaló software especializado
- Desconfía de sistemas "muy complicados"
```

#### 👤 Persona 2: Sofía — La Instructora/Entrenadora
```
Nombre:   Sofía Mamani
Edad:     26 años
Ciudad:   Arequipa (Cayma)
Trabajo:  Instructora en 2 gimnasios, turno mañana y tarde

Motivaciones:
- Que sus alumnos progresen y ella pueda verlo
- Tener sus rutinas organizadas por alumno
- No perder el tiempo escribiendo a mano

Frustraciones:
- "Escribo la misma rutina 5 veces para alumnos distintos"
- "No sé si mi alumno realmente hizo todos los ejercicios"
- "Cuando un alumno falta, no sé si fue por lesión o pereza"
- "El dueño me pide reportes pero no tengo datos"

Tecnología:
- Smartphone, usa Instagram y TikTok
- Nunca usó una app de gestión de gym
- Usa notas de voz y fotos en WhatsApp para comunicarse con alumnos
```

#### 👤 Persona 3: Diego — El Usuario
```
Nombre:   Diego Ccallo
Edad:     22 años
Ciudad:   Arequipa (Paucarpata)
Situación: Universitario, va al gym 4 veces por semana

Motivaciones:
- Seguir su rutina sin depender del entrenador
- Ver su progreso visual (antes/después)
- Pagar fácil, sin ir al banco

Frustraciones:
- "Mi rutina era una hoja que perdí"
- "No sé si estoy haciendo el ejercicio bien"
- "Tengo que ir a preguntar si ya vence mi mensualidad"
- "Para pagar tengo que ir en efectivo y a veces no llevo"

Tecnología:
- Heavy user de smartphone
- Paga con Yape/Plin siempre
- Busca tutoriales en YouTube para ver técnica de ejercicios
- Usaría una app si es fácil y rápida
```

#### 👤 Persona 4: Carmen — La Cajera / Recepcionista
```
Nombre:   Carmen Choque
Edad:     30 años
Ciudad:   Arequipa (Mariano Melgar)
Trabajo:  Cajera a tiempo completo en el gimnasio

Motivaciones:
- Registrar pagos rápido y sin errores
- Saber inmediatamente si alguien puede entrar o no
- No cometer errores que luego el dueño le cobre

Frustraciones:
- "A veces no sé si alguien ya pagó o no"
- "La gente llega junta en la mañana y se hace cola"
- "El dueño dice que alguien ya pagó pero no está en el cuaderno"
- "Si el cuaderno se ensucia o pierde, no tengo respaldo"

Tecnología:
- Smartphone básico
- Prefiere interfaces simples, sin muchas pantallas
- Usa WhatsApp pero no apps especializadas
```

---

## FASE 2 — DEFINIR

### 1.4 Roles del Sistema (Operativos)

A continuación se resumen los roles funcionales del producto, su acceso principal y responsabilidades clave. Estos roles deben mapearse a las vistas y mockups descritos en el sistema.

| Rol | Acceso / Plataforma | Responsabilidades clave | Vistas / Mockups relevantes |
|---|---:|---|---|
| **Super-Admin** | Web Admin Panel (plataforma SaaS) | Gestiona instancias, crea gimnasios, configura pasarelas y ajustes globales | Dashboard Admin Web (WEB-01), Configuración (WEB-09) |
| **Administrador** | Web Admin + App Admin (Flutter) | Gestión diaria de la instancia: usuarios, cobros, horarios, reportes | WEB-01, WEB-02, WEB-03, MOB-ADMIN-01 |
| **Caja / Recepción** | App Flutter (Caja) | Registrar pagos en efectivo, escanear QR de acceso, validar ingresos rápidos | MOB-ADMIN-02 (Escaner), MOB-ADMIN-03 (Registrar Pago) |
| **Entrenador** | App Entrenador (Flutter) | Crear/editar rutinas, asignar ejercicios, seguimiento técnico de alumnos | MOB-TRAINER-01, MOB-TRAINER-02, MOB-TRAINER-03 |
| **Usuario / Practicante** | App Usuario (Flutter) | Ejecutar rutinas (asistente), mostrar QR de acceso, pagar membresías | ExerciseCard, QR Member Screen, Mi Agenda (asistente) |

Notas operativas:
- El rol `Super-Admin` es para administración de la plataforma multi-tenant (operaciones globales).
- `Administrador` tiene sub-roles operativos (p. ej. `Caja`) con permisos más limitados; la `Caja` debe poder operar sin acceder a configuraciones avanzadas.
- Las vistas deben respetar el principio de mínima exposición: cada rol ve solo la información necesaria (ver `Perfiles — Multi-vista` en la planificación técnica).


### 2.1 Declaraciones del Problema (Point of View)

```
POV 1 — Admin/Dueño:
"Marco necesita saber en tiempo real si un usuario puede entrar
porque actualmente depende de la memoria de su cajera y un cuaderno
físico que no garantiza ni consistencia ni velocidad."

POV 2 — Instructora:
"Sofía necesita crear rutinas personalizadas una sola vez y ver
si sus alumnos las ejecutaron porque actualmente escribe a mano
la misma información repetidamente sin tener retroalimentación."

POV 3 — Usuario:
"Diego necesita entrenar de forma autónoma con guía visual porque
actualmente su rutina es un papel que pierde y no sabe si está
ejecutando los movimientos correctamente."

POV 4 — Cajera:
"Carmen necesita validar el acceso de un usuario en menos de 2
segundos porque actualmente revisa un cuaderno físico que puede
estar desactualizado y genera colas en la entrada."
```

### 2.2 HMW (How Might We) — ¿Cómo podríamos…?

```
🔹 ¿Cómo podríamos eliminar el cuaderno de asistencia sin que
   el admin necesite capacitación extensa?

🔹 ¿Cómo podríamos alertar al usuario antes de que venza
   su mensualidad para que pague sin fricciones?

🔹 ¿Cómo podríamos permitir que el usuario vea su rutina
   exactamente como el entrenador la diseñó?

🔹 ¿Cómo podríamos permitir que la cajera valide un ingreso
   con solo apuntar la cámara al QR del usuario?

🔹 ¿Cómo podríamos dar al entrenador visibilidad del progreso
   real de su alumno sin que el alumno tenga que reportarlo?

🔹 ¿Cómo podríamos centralizar toda la información del gimnasio
   sin que el dueño tenga que aprender software complejo?
```

---

## FASE 3 — IDEAR

### 3.1 Mapa de Propuesta de Valor

```
Problema                          Solución GymSmart
─────────────────────────────     ─────────────────────────────────────
Cuaderno asistencia (papel)   →   Escáner QR + validación instantánea
Excel de pagos desactualizado →   Dashboard en tiempo real + alertas push
Sin notificación vencimiento  →   Notif. 7 días antes + diaria al vencer
Rutinas en papel              →   Biblioteca digital + asistente con GIFs
Sin historial de progreso     →   Registro de esfuerzo real por serie
Comunicación por WhatsApp     →   Módulo de anuncios + observaciones
Privacidad comprometida       →   Sistema multi-vista por rol
Cobros solo en efectivo       →   Yape/Plin via pasarela Culqi/Izipay
Sin centralización de datos   →   SaaS multi-tenant por instancia
```

### 3.2 Flujos de Usuario Críticos

#### Flujo 1: Ingreso al Gimnasio (Crítico — < 2 segundos)
```
PRACTICANTE                      CAJERA/ADMIN                   SISTEMA
     │                                │                              │
     │  Muestra QR en pantalla        │                              │
     │ ─────────────────────────────► │                              │
     │                                │  Apunta cámara al QR        │
     │                                │ ─────────────────────────── ►│
     │                                │                              │ Valida tenant_id
     │                                │                              │ Verifica membresía
     │                                │                              │ Registra ingreso
     │                                │                 ◄────────────│ ACCESO CONCEDIDO ✅
     │                                │  Verde + sonido positivo     │
     │ ◄───────────────────────────── │                              │
     │                                │
     │  [ALTERNATIVO: Membresía vencida]
     │                                │ ◄────────────────────────────│ ACCESO DENEGADO ❌
     │                                │  Rojo + alerta push al Admin │
     │                                │  "Diego C. - membresía vencida"
```

#### Flujo 2: Pago Digital Yape/Plin
```
PRACTICANTE                         SISTEMA / PASARELA              ADMIN
     │                                      │                         │
     │  Accede a "Mi Membresía"             │                         │
     │  Toca "Pagar Online"                 │                         │
     │ ─────────────────────────────────── ►│                         │
     │                          Genera QR Culqi/Link Yape             │
     │ ◄───────────────────────────────────│                         │
     │  Abre Yape, escanea QR               │                         │
     │  Realiza transferencia               │                         │
     │ ─────────────────────────────────── ►│                         │
     │                        Culqi notifica webhook                  │
     │                                      │ Actualiza membresía ───►│
     │ ◄─────────────────── Push: "¡Pago confirmado! Vence 21/06"    │
     │
     │  [ALTERNATIVO: Pago manual / captura]
     │  Sube screenshot de Yape             │
     │ ─────────────────────────────────── ►│ ──────────────── notifica ►│
     │                                      │               Admin revisa │
     │                                      │               Aprueba ─────►│
     │ ◄─────────────────── Push: "Tu pago fue aprobado"               │
```

#### Flujo 3: Ejecución de Rutina (Asistente Virtual)
```
PRACTICANTE                         APP (ASISTENTE)
     │                                    │
     │  Abre Mi Agenda                    │
     │  Hoy: Lunes — Pecho + Tríceps      │
     │  Toca "Iniciar Entrenamiento" ────►│
     │                                    │ Carga rutina asignada
     │                                    │ (de caché local si está)
     │                          ◄─────────│ Muestra ejercicio 1:
     │                                    │ [GIF: Press Banca]
     │                                    │ 4 series × 10 reps × 60kg
     │  Hace la serie                     │
     │  Toca "Serie Completada" ─────────►│
     │                          ◄─────────│ Timer: 60 seg descanso
     │  [Opcional] "Ajustar Esfuerzo"     │
     │  Ingresa: 55kg reales, 8 reps ────►│ Guarda en historial
     │                          ◄─────────│ Siguiente serie / ejercicio
     │  ... (completa todas las series)   │
     │  Toca "Entrenamiento Completado" ─►│
     │                          ◄─────────│ Guarda registro de sesión
     │                                    │ Visible para Entrenador
```

#### Flujo 4: Cajera — Registro de Pago Efectivo
```
CAJERA                              SISTEMA
  │                                    │
  │  Busca al usuario por nombre   │
  │  o DNI ──────────────────────────►│
  │                         ◄──────────│ Muestra: estado membresía vencida
  │                                    │ Monto a cobrar: S/. 80.00
  │  Recibe efectivo                   │
  │  Toca "Registrar Pago" ──────────►│
  │  Confirma monto ─────────────────►│
  │                         ◄──────────│ Actualiza membresía
  │                                    │ Nueva fecha vencimiento: 21/06
  │                         ◄──────────│ Registra en log con timestamp
  │                                    │ Push al usuario: "¡Pago registrado!"
```

---

## FASE 4 — PROTOTIPAR

### 4.1 Sistema de Diseño Visual

#### Paleta de Colores
```
Primario:     #1A1A2E   (Azul noche profundo — fondo principal)
Secundario:   #16213E   (Azul medio — cards, sidebars)
Acento:       #E94560   (Rojo energía — botones CTA, acciones primarias)
Éxito:        #0F9B58   (Verde — acceso concedido, pagos confirmados)
Alerta:       #F5A623   (Ámbar — vencimiento próximo, advertencias)
Error:        #E94560   (Rojo — acceso denegado, errores críticos)
Texto:        #FFFFFF / #B0B3C1 (Blanco primario / gris secundario)
Surface:      #0F3460   (Azul medio-oscuro — inputs, chips)
```

#### Tipografía
```
Display:   Inter Bold 28px      (Títulos de pantalla)
Heading:   Inter SemiBold 20px  (Secciones, cards header)
Body:      Inter Regular 16px   (Contenido general)
Caption:   Inter Regular 12px   (Fechas, metadata)
Button:    Inter Medium 16px    (CTAs)
```

#### Componentes Clave

**GymButton (CTA Principal)**
```
┌─────────────────────────────────┐
│         INICIAR ENTRENAMIENTO   │  ← 56px altura, borde redondeado 12px
│                                 │     Fondo #E94560, texto blanco
└─────────────────────────────────┘
```

**MembershipCard**
```
┌───────────────────────────────────────┐
│  👤 Diego Ccallo                      │
│  ─────────────────────────────────    │
│  Estado: ✅ ACTIVO                    │
│  Vence:  21 de Junio 2026             │
│                                       │
│  ████████████████░░░  19 días         │  ← Progress bar
└───────────────────────────────────────┘
```

**ExerciseCard (Asistente)**
```
┌───────────────────────────────────────┐
│  Serie 2 de 4                         │
│  ┌─────────────────────────────┐      │
│  │   [GIF: Press de Banca]     │      │  ← GIF animado, 280×200px
│  └─────────────────────────────┘      │
│  Press de Banca                       │
│  10 reps  ×  60 kg  ·  60s descanso   │
│  ─────────────────────────────────    │
│  [  Ajustar Esfuerzo  ]  [✅ Listo]   │
└───────────────────────────────────────┘
```

**AccessScanner (Cajera/Admin)**
```
┌───────────────────────────────────────┐
│           ESCANEAR QR                 │
│  ┌─────────────────────────────┐      │
│  │                             │      │
│  │    [ ÁREA DE CÁMARA ]       │      │  ← Visor cámara full
│  │                             │      │
│  └─────────────────────────────┘      │
│                                       │
│  ── ÚLTIMO REGISTRO ──────────────    │
│  ✅ Diego Ccallo  8:42 am             │
│  ❌ Ana Torres    8:40 am (VENCIDO)   │
└───────────────────────────────────────┘
```

---

### 4.2 Arquitectura de Información por Pantalla

#### ADMIN — Navigation Principal
```
Bottom Nav (4 tabs):
[🏠 Dashboard] [👥 Usuarios] [📷 Acceso] [📢 Más]

Dashboard
├── Card: Asistencia hoy (X / Total activos)
├── Card: Pagos pendientes esta semana
├── Card: Observaciones sin revisar
└── Lista: Últimos ingresos del día

Usuarios
├── SearchBar + Filtros (Activo / Vencido / Pendiente)
├── Lista usuarios (Avatar, Nombre, Estado membresía, Vence en X días)
└── Detalle Usuario
    ├── Vista Operativa (solo admin ve)
    ├── Botón: Registrar Pago Efectivo
    ├── Botón: Aprobar Acreditación (si hay pendiente)
    ├── Botón: Asignar Entrenador
    └── Botón: Dar de Baja

Acceso (Escáner)
├── Cámara full-screen con overlay QR
└── Panel inferior: últimos 5 ingresos del día

Más
├── Observaciones (Buzón Global)
├── Anuncios (Crear / Gestionar)
└── Configuración Gimnasio
```

#### ENTRENADOR — Navigation Principal
```
Bottom Nav (3 tabs):
[👥 Mis Alumnos] [🏋️ Biblioteca] [👤 Mi Perfil]

Mis Alumnos
├── Lista de usuarios asignados
└── Vista Técnica de Alumno
    ├── Datos: Peso, Altura, Lesiones, Objetivo
    ├── Historial de sesiones completadas
    │   └── Por sesión: ejercicios, series, pesos reales
    ├── Botón: Asignar / Editar Rutina
    └── Botón: Definir Agenda Semanal

Biblioteca
├── Lista de ejercicios (con thumbnail GIF)
├── Botón: Crear Ejercicio
│   ├── Nombre
│   ├── Upload GIF/WebM (max 2MB)
│   └── Descripción técnica
└── Detalle Ejercicio → Editar / Eliminar

Mi Perfil
├── Foto, Nombre, Especialidad
├── Años de experiencia
├── Certificaciones
└── Botón: Editar perfil
```

#### PRACTICANTE — Navigation Principal
```
Bottom Nav (4 tabs):
[🏠 Home] [📅 Agenda] [💳 Membresía] [👤 Perfil]

Home (Feed)
├── Banner destacado (último anuncio)
└── Lista de anuncios del gimnasio

Agenda
├── Selector semana (Lunes - Domingo)
├── Por día: Grupo muscular asignado
└── Al tocar día con rutina:
    └── Pantalla Asistente
        ├── Header: Rutina del día, X ejercicios
        ├── Ejercicio actual: GIF + nombre + series
        ├── Progreso: Serie 2 de 4
        ├── Temporizador de descanso (circular)
        ├── Botón: Serie Completada
        ├── Botón: Ajustar Esfuerzo (peso real / reps reales)
        └── Al finalizar: "¡Entrenamiento Completado! 💪"

Membresía
├── Estado (Activo / Vencido / Pendiente)
├── Fecha vencimiento + días restantes (progress bar)
├── Botón: Pagar Online (→ WebView pasarela)
├── Botón: Acreditar Pago Manual (→ upload screenshot)
└── Historial de pagos

QR de Acceso (FAB o Tab)
└── QR dinámico full-screen + nombre + foto

Perfil
├── Tab: Datos Privados (Correo, DNI, Cel, Contraseña)
├── Tab: Vista Social (Foto, Nickname, toggle Activo/Inactivo)
└── Tab: Vista Física (Fotos A/D, Medidas, Peso histórico)
```

---

### 4.3 Microinteracciones Clave

#### Escáner de Acceso — Feedback Visual
```
QR Detectado → Procesando (spinner 0.5s)
    └── Membresía Vigente:
        ├── Fondo pantalla → VERDE (#0F9B58)
        ├── Icono: ✅ grande animado (scale in)
        ├── Texto: "ACCESO CONCEDIDO"
        ├── Nombre + foto del usuario
        └── Vibración corta + sonido positivo (beep)
    └── Membresía Vencida / No registrado:
        ├── Fondo pantalla → ROJO (#E94560)
        ├── Icono: ❌ grande animado
        ├── Texto: "ACCESO DENEGADO"
        ├── Motivo: "Membresía vencida - 3 días"
        ├── Push silencioso al Admin
        └── Vibración larga + sonido negativo
```

#### Temporizador de Descanso (Asistente)
```
Serie Completada ─────────►  Timer circular aparece
                             con animación de entrada (slide up)

                    ╔═══════════════╗
                    ║               ║
                    ║    0:45       ║  ← Cuenta regresiva
                    ║  ──────────   ║  ← Progress circular
                    ║  Descansando  ║
                    ╚═══════════════╝

Timer llega a 0 ──────────►  Vibración + sonido
                             "¡Listo para la siguiente serie!"
                             Ejercicio siguiente aparece automáticamente
```

#### Notificación Vencimiento (Push)
```
7 días antes:
  🏋️ GymSmart · Tu membresía vence en 7 días
  "Renueva ahora y sigue entrenando sin interrupciones. Paga con Yape"
  [Pagar ahora] ← CTA directo que abre la app en Membresía

Día del vencimiento:
  ⚠️ GymSmart · Tu membresía venció hoy
  "Renueva hoy para seguir entrenando mañana"
  [Renovar] ← CTA

Post-vencimiento (diario):
  🔴 GymSmart · Tu acceso está restringido
  "Tu membresía lleva X días vencida. Renueva para recuperar el acceso"
```

---

## FASE 5 — TESTEAR

### 5.1 Criterios de Éxito Medibles

| Métrica | Objetivo | Cómo medirlo |
|---|---|---|
| Tiempo de validación de ingreso | < 2 segundos | Log timestamp QR scan → respuesta servidor |
| Tasa de adopción en primer mes | > 80% usuarios activos usando el QR | Registros de ingreso digital vs. total |
| Reducción de deuda por membresía vencida | > 50% en 3 meses | Comparativa pagos antes/después |
| Satisfacción cajera (SUS score) | > 75/100 | Encuesta System Usability Scale |
| Tiempo de asignación de rutina (entrenador) | < 5 minutos | Analytics de tiempo en pantalla |
| Sesiones de entrenamiento registradas | > 70% de las asistencias | Sesiones completadas / ingresos registrados |

### 5.2 Flujo de Onboarding por Rol

#### Admin (primera vez)
```
1. Login con credenciales que le envió el Super-Admin
2. Wizard de configuración del gimnasio:
   - Nombre, logo, dirección, teléfono
   - Horario de atención
3. ¡Listo! Dashboard con accesos directos:
   - "Registra tu primer usuario"
   - "Invita a tu entrenador"
   - "Prueba el escáner de acceso"
```

#### Entrenador (primera vez)
```
1. Recibe email/WhatsApp con link de invitación del Admin
2. Crea su contraseña
3. Wizard simple:
   - Foto, especialidad, experiencia
4. ¡Listo! Ve su lista de usuarios (si ya le asignaron)
```

#### Usuario (primera vez)
```
1. Auto-registro: Nombre, Correo, DNI, Celular, Contraseña
2. Estado: "Pendiente de Pago" — no puede entrar aún
3. Pantalla clara: "Para activar tu membresía, paga S/. 80 aquí:"
   [Pagar con Yape] o [Coordina con recepción]
4. Tras pago confirmado → puede generar su QR y ver su rutina
```

---

## 6. Modelo de Datos (Esquema Conceptual)

```
TENANT (Gimnasio)
├── id, nombre, logo, dirección, teléfono, horario
└── plan_suscripcion, fecha_vencimiento_plan

USER
├── id, tenant_id, email, password_hash, rol [ADMIN|TRAINER|MEMBER|CAJA]
├── nombre_completo, dni, celular
└── estado [ACTIVO|INACTIVO|PENDIENTE]

MEMBER_PROFILE (Usuario)
├── user_id, entrenador_asignado_id
├── [Vista Social] nickname, foto_url, modo_activo
├── [Vista Técnica] peso_kg, altura_cm, objetivo, lesiones
└── [Vista Física] medidas_json (solo visible para el propio usuario)

TRAINER_PROFILE (Entrenador)
├── user_id, especialidad, anos_experiencia
└── certificaciones, biografia, foto_url

MEMBERSHIP (Membresía)
├── id, tenant_id, user_id
├── estado [ACTIVO|VENCIDO|PENDIENTE|GRACIA]
├── fecha_inicio, fecha_vencimiento
└── monto_pagado, metodo_pago

PAYMENT (Pago)
├── id, tenant_id, membership_id, registrado_por_user_id
├── monto, metodo [EFECTIVO|PASARELA|MANUAL]
├── comprobante_url (screenshot para manual)
└── estado [PENDIENTE|APROBADO|RECHAZADO], timestamp

ATTENDANCE (Asistencia)
├── id, tenant_id, user_id
├── timestamp_ingreso
└── validado_por [QR_AUTONOMO|ADMIN_SCAN]

EXERCISE (Ejercicio — Biblioteca)
├── id, tenant_id, trainer_id
├── nombre, descripcion
├── animacion_url, animacion_version (para invalidar caché)
└── grupo_muscular

ROUTINE_TEMPLATE (Plantilla de Rutina)
├── id, tenant_id, trainer_id, nombre
└── ejercicios_json [{exercise_id, series, reps, peso_sugerido, descanso_seg}]

ROUTINE_ASSIGNMENT (Asignación)
├── id, tenant_id, member_id, trainer_id, template_id
└── agenda_semanal_json {LUN: template_id, MAR: null, ...}

WORKOUT_SESSION (Sesión de Entrenamiento)
├── id, tenant_id, member_id, template_id
├── fecha, estado [COMPLETADO|EN_CURSO|OMITIDO]
└── series_log_json [{exercise_id, serie, peso_real, reps_reales}]

OBSERVATION (Observación)
├── id, tenant_id, author_id, autor_rol
├── texto, foto_url
└── timestamp, revisado_por_admin

ANNOUNCEMENT (Anuncio)
├── id, tenant_id, autor_id
├── titulo, descripcion, imagen_url
└── publicado_en, activo
```

---

## 7. Checklist de UX para Entorno Gimnasio

> Diseñar para el uso real: manos sudadas, luz tenue, urgencia de tiempo

- [ ] **Touch targets mínimo 56px** en pantallas de uso durante entrenamiento
- [ ] **Contraste WCAG AA** (ratio ≥ 4.5:1) en todos los textos
- [ ] **Dark theme por defecto** (uso en gym con luz variada)
- [ ] **Feedback háptico** (vibración) en acciones críticas (acceso concedido/denegado)
- [ ] **Textos en botones CTA en MAYÚSCULAS** para legibilidad rápida
- [ ] **No más de 3 taps** para llegar a la acción más usada por rol
- [ ] **Skeleton loaders** mientras carga (no spinner genérico)
- [ ] **Caché offline** para rutinas y ejercicios (WiFi del gym puede fallar)
- [ ] **Formato 24h** para logs de ingreso (contexto peruano)
- [ ] **Soles (S/.)** como moneda en todos los valores de pago
- [ ] **Validación de DNI peruano** (8 dígitos numéricos) en registro
- [ ] **Compresión de imagen** antes de upload (celulares de gama media tienen fotos de 8-12MB)

---

## 8. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| WiFi del gimnasio inestable | Alta | Alto | Cache offline para rutinas, modo degradado para escáner |
| Usuarios con celulares de gama baja (Android 8/9) | Alta | Medio | Flutter targeting Android API 24+, evitar librerías pesadas |
| Admin se resiste al cambio digital | Media | Alto | Onboarding simple con wizard + video tutorial de 2 minutos |
| Pasarela de pago (Culqi) con latencia | Media | Alto | Timeout visible + opción acreditación manual como fallback |
| Fotos grandes saturan almacenamiento | Alta | Medio | Compresión obligatoria cliente-side antes de upload |
| Multi-tenant con datos cruzados | Baja | Crítico | `tenant_id` en TODAS las queries, middleware de validación |
| Entrenador sin dispositivo propio | Media | Bajo | App disponible para tablet o dispositivo compartido del gym |

---

## 9. Próximos Pasos Inmediatos

### Semana 0 (Antes de primer sprint)
```
[ ] Validar preguntas abiertas con el cliente (ver planificacion.md §11)
[ ] Crear repositorios: gym_smart_app + gym_smart_backend
[ ] Configurar proyecto Firebase (FCM + Storage)
[ ] Obtener credenciales sandbox Culqi o Izipay
[ ] Decidir: schema-per-tenant vs. tenant_id en tablas
[ ] Diseñar en Figma las 5 pantallas críticas:
    - Login
    - Escáner de Acceso (Admin/Caja)
    - QR del Usuario
    - Asistente de Entrenamiento
    - Registro de Pago Efectivo
```

### Sprint 1 Kick-off (Semana 1)
```
[ ] Inicializar Flutter con clean architecture
[ ] Configurar CI/CD básico (GitHub Actions → build APK debug)
[ ] Implementar auth con JWT + flutter_secure_storage
[ ] Primer build funcional en dispositivo Android físico
```
