# Leyenda de vistas y trazabilidad — Panel Web (`crosshero_web_high`)

Prototipo hi-fi del **panel web de administración** de GymSmart, hermano del
prototipo móvil `sas_Gym_high/`. Layout de escritorio (sidebar + área de
contenido), construido sobre la spec `mockups_section.md §11.1` (WEB-01…WEB-09)
y la estructura real de la app Django `crosshero-gym/`.

Fuentes: SRS v2.0, Casos de Uso v2.0, Matriz de privacidad v2.0,
`mockups_section.md §11`.

---

## 1. Convenciones (leyenda)

### Roles del panel web

| Rol (prototipo) | Actor SRS | Login | Acceso principal |
|---|---|---|---|
| `superadmin` | Super-Administrador | sí | Plataforma SaaS: gimnasios e instancias multi-tenant |
| `admin` | Administrador | sí | Gestión total del gimnasio |
| `cajero` | Caja / Recepción | sí | Operación limitada, turno con horario |
| `coach` | Entrenador | sí | Alumnos asignados |
| `miembro` | Practicante | sí | Su propia cuenta |

> El panel web es **multi-rol**: el `Login` permite entrar como cualquiera de
> los 4 roles y cada uno ve un sidebar distinto. El SRS reserva el panel web
> sobre todo para Administrador; aquí los 4 roles tienen una vista web mínima.
> El **Super-Admin** del SRS sigue fuera del alcance del prototipo.

### Códigos

- **RF / RNF** — Requerimientos del SRS v2.0.
- **CU-xx** — Casos de Uso v2.0.
- **WEB-xx** — Mockup de referencia en `mockups_section.md §11.1`.

### Ubicación de una vista

`archivo › función` — la **sección** es el `id` que recibe `go(id)` / el
sidebar en [crosshero_web_high/app.jsx](crosshero_web_high/app.jsx).

### Archivos del prototipo

| Archivo | Contenido |
|---|---|
| [index.html](crosshero_web_high/index.html) | Carga React + Babel + scripts |
| [styles.css](crosshero_web_high/styles.css) | Design system de escritorio |
| [shared.jsx](crosshero_web_high/shared.jsx) | Iconos, `Sidebar`, `Topbar`, `Kpi`, `Panel`, `Bars`, `Donut`, `Badge` |
| [data.jsx](crosshero_web_high/data.jsx) | Datos mock + definición de roles y navegación |
| [dashboards.jsx](crosshero_web_high/dashboards.jsx) | `Login` + 4 dashboards |
| [modules.jsx](crosshero_web_high/modules.jsx) | Usuarios, Pagos, Asistencia, Productos, Reportes, Config |
| [modules2.jsx](crosshero_web_high/modules2.jsx) | Membresías, Caja, Finanzas, Puntos, Clases, Entrenamientos, CRM |
| [app.jsx](crosshero_web_high/app.jsx) | Raíz: login + shell + routing por rol |

---

## 2. Vistas del panel web — trazabilidad

| # | Vista | Función › sección | Rol(es) | Mockup | Trazabilidad (RF / RNF / CU) |
|---|---|---|---|---|---|
| 1 | Inicio de sesión | `Login` › *(login)* | todos | — | **CU-01**; CU-02 (enlace recuperar); RNF 3 (token "recordarme") |
| 2 | Dashboard Admin | `AdminDashboard` › `dashboard` | admin | **WEB-01** | RF 2.3 (accesos denegados), RF 3.3 (pagos pendientes), RF 3.4 (por vencer) |
| 3 | Dashboard de turno | `CajeroDashboard` › `dashboard` | cajero | — | RF 2.1, RF 3.1 (resumen del turno); RNF 3 (turno con horario) |
| 4 | Panel del entrenador | `CoachDashboard` › `dashboard` | coach | — | RF 3.6 (consumo); Vista Técnica (L Asignados) |
| 5 | Mi resumen | `MiembroDashboard` › `dashboard` | miembro | MOB-USER-04 | RF 3.4; estado de membresía (L Propio) |
| 6 | Usuarios (lista) | `Usuarios` › `usuarios` | admin, coach | **WEB-02** | **RF 1.1**, RF 1.2, RF 1.3; CU-04 |
| 7 | Detalle de usuario | `UserDetail` › `usuarios` (sub) | admin, coach | **WEB-03** | Vista Operativa (L/E Admin); **RF 1.3** (baja lógica), RF 3.1; CU-06, CU-07 |
| 8 | Pagos y acreditaciones | `Pagos` › `pagos` | admin, cajero | **WEB-04** | **RF 3.1** (cobros del día), **RF 3.3** (aprobar acreditación); CU-09, CU-11 |
| 9 | Control de asistencia | `Asistencia` › `asistencia` | admin, cajero | **WEB-05** | **RF 2.1, RF 2.2, RF 2.3**; CU-08; RNF 2 (validación ≤ 2 s) |
| 10 | Productos e inventario | `Productos` › `productos` | admin, cajero | — | Módulo Productos (CRUD de inventario y precios) |
| 11 | Reportes y analítica | `Reportes` › `reportes` | admin | **WEB-08** | Soporte de gestión: retención, ingresos, métodos de pago |
| 12 | Configuración del gimnasio | `Config` › `config` | admin | **WEB-09** | CU-07 (Perfil Empresa); RF 2.4 (día de gracia configurable) |
| 13 | Membresías y planes | `Membresias` › `membresias` | admin, cajero | — | RF 3.x (planes, precios); congelar / traspasar / abono de membresía |
| 14 | Caja del turno | `Caja` › `caja` | admin, cajero | — | Apertura / cierre de caja, movimientos, egresos del turno; RNF 3 (control por turno) |
| 15 | Finanzas del gimnasio | `Finanzas` › `finanzas` | admin | — | Sueldos, servicios, gastos e ingresos especiales (módulo `pagos` de crosshero) |
| 16 | Puntos y fidelización | `Puntos` › `puntos` | admin, cajero | — | Catálogo canjeable y canjes (módulo `puntos` — fuera del SRS, propio de crosshero) |
| 17 | Clases y horarios | `Clases` › `clases` | admin, coach | **WEB-06** | Gestión de clases, cupos y entrenadores |
| 18 | Entrenamientos y rutinas | `Entrenamientos` › `entrenamientos` | admin, coach | — | **RF 4.1, RF 4.2** (biblioteca de rutinas/ejercicios y grupos musculares) |
| 19 | CRM · campañas y contactos | `CRM` › `crm` | admin | — | RF 5.3 (comunicación); campañas email/WhatsApp/push, contactos y seguimientos |

| 20 | Resumen de la plataforma | `SuperDashboard` › `dashboard` | superadmin | — | Back-office SaaS: KPIs de la red, estado de instancias |
| 21 | Gimnasios de la red | `Gimnasios` › `gimnasios` | superadmin | — | Clientes = instancias multi-tenant; alta/estado de cada gimnasio |
| 22 | Planes SaaS | `PlanesSaaS` › `planes` | superadmin | — | Planes de suscripción de la plataforma + facturación (MRR) |

> Filas 20-22: rol **Super Administrador** — gestiona la plataforma SaaS, no un
> gimnasio concreto. Es el back-office multi-tenant; el SRS lo menciona como
> rol de plataforma.

> Filas 13-19: módulos añadidos para dar **paridad con la app real
> `crosshero-gym`**. Varios (`puntos`, `crm`, `finanzas`) son funcionalidad
> propia de crosshero que **excede el SRS v2.0** — el SRS solo cubre acceso,
> pagos, rutinas, observaciones y anuncios. Cada vista es la **pantalla
> principal** del módulo; sus sub-flujos (CRUD detallado, formularios) quedan
> como iteración posterior.

### Notas de privacidad por vista

- **Usuarios / Detalle de usuario** muestran la *Vista Operativa* (nombre, DNI,
  estado de membresía, entrenador). El panel **no expone datos médicos ni
  físicos** del practicante (matriz: Admin = `No` sobre Vista Técnica/Física).
- **Pagos** y **Asistencia** son `Lectura/Escritura` para Admin; el Cajero
  opera la misma pantalla pero su actividad queda registrada (auditoría).
- **Reportes** y **Configuración** son exclusivos de Admin.

---

## 3. Cobertura inversa — requerimiento → vista del panel web

| Requerimiento | Vista(s) del panel web | Cobertura |
|---|---|---|
| CU-01 Inicio de sesión | `Login` | ✅ |
| CU-02 Recuperación de contraseña | `Login` (solo enlace) | ⚠️ Parcial |
| CU-03 Cierre de sesión | botón "Cerrar sesión" del `Topbar` → vuelve al `Login` | ✅ (simulado) |
| RF 1.1 Registro de usuario | `Usuarios` (botón Registrar) | ✅ |
| RF 1.2 Asignación de entrenador | `UserDetail` (campo Entrenador) | ⚠️ Parcial |
| RF 1.3 Baja lógica | `UserDetail` (botón "Dar de baja lógica") | ✅ |
| RF 2.1 Registro de ingreso | `Asistencia` (log del día), `AdminDashboard` | ✅ |
| RF 2.2 Escaneo QR / DNI | `Asistencia` (escáner + ingreso manual) | ✅ |
| RF 2.3 Bloqueo + alerta | `Asistencia` (denegados), `AdminDashboard` | ✅ |
| RF 2.4 Margen de gracia | `Config` (día de gracia configurable) | ✅ |
| RF 3.1 Pago en efectivo | `Pagos` (cobros del día), `UserDetail` | ✅ |
| RF 3.3 Acreditación manual | `Pagos` (pendientes → aprobar/rechazar) | ✅ |
| RF 3.4 Aviso de vencimiento | `AdminDashboard` (pagos pendientes / por vencer) | ✅ |
| RNF 2 Rendimiento ≤ 2 s | `Asistencia` (flujo de escaneo) | ⚠️ Visual |
| RNF 3 Seguridad / multi-tenant | `Login` (token), sidebar muestra instancia única del gym | ⚠️ Parcial |

## 4. Vacíos detectados (sin vista en el panel web)

| Faltante | Caso de uso / RF | Comentario |
|---|---|---|
| Recuperación de contraseña | CU-02 | Solo existe el enlace en el `Login`, sin pantalla de reset |
| Asignación de entrenador (flujo) | RF 1.2 / CU-05 | `UserDetail` muestra el entrenador pero sin selector dedicado |
| Buzón de observaciones | WEB-07 / RF 5.2 | Pendiente — el SRS sí lo pide; añadir como vista de módulo |
| Banner si push deshabilitado | RF 3.6 | No implementado |

> Las **vistas principales** de los 12 módulos ya están cubiertas (filas
> 1-19). Lo pendiente son **sub-flujos** dentro de cada módulo (formularios
> CRUD, detalles, confirmaciones) y la pantalla de observaciones.

> Estas vistas se pueden añadir luego siguiendo los mockups `WEB-06`/`WEB-07`
> de `mockups_section.md` con la misma estructura (`modules.jsx`).

---

## 5. Relación con los otros artefactos del proyecto

| Artefacto | Qué cubre |
|---|---|
| `sas_Gym_high/` + [TRAZABILIDAD_VISTAS.md](TRAZABILIDAD_VISTAS.md) | Prototipo **móvil** (apps de los 4 roles) |
| `crosshero_web_high/` + este documento | Prototipo **web de escritorio** (panel de administración) |
| `crosshero-gym/` (Django) | Implementación real del panel web (219 plantillas) |
| `flutter_app/` | Port nativo del prototipo móvil |

El prototipo web reutiliza los **tokens de marca** de `sas_Gym_high`
(paleta, tipografías, acento lima) para mantener coherencia visual entre la
app móvil y el panel web.
