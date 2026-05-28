# Leyenda de vistas y trazabilidad â€” Panel Web (`mockups/web`)

Prototipo hi-fi del **panel web de administraciÃ³n** de GymSmart, hermano del
prototipo mÃ³vil `mockups/mobile/`. Layout de escritorio (sidebar + Ã¡rea de
contenido), construido sobre la spec `mockups_section.md Â§11.1` (WEB-01â€¦WEB-09)
y la estructura real de la app Django `proyecto_antiguo/`.

Fuentes: SRS v2.0, Casos de Uso v2.0, Matriz de privacidad v2.0,
`mockups_section.md Â§11`.

---

## 1. Convenciones (leyenda)

### Roles del panel web

| Rol (prototipo) | Actor SRS | Login | Acceso principal |
|---|---|---|---|
| `superadmin` | Super-Administrador | sÃ­ | Plataforma SaaS: gimnasios e instancias multi-tenant |
| `admin` | Administrador | sÃ­ | GestiÃ³n total del gimnasio |
| `cajero` | Caja / RecepciÃ³n | sÃ­ | OperaciÃ³n limitada, turno con horario |
| `coach` | Entrenador | sÃ­ | Alumnos asignados |
| `miembro` | Practicante | sÃ­ | Su propia cuenta |

> El panel web es **multi-rol**: el `Login` permite entrar como cualquiera de
> los 4 roles y cada uno ve un sidebar distinto. El SRS reserva el panel web
> sobre todo para Administrador; aquÃ­ los 4 roles tienen una vista web mÃ­nima.
> El **Super-Admin** del SRS sigue fuera del alcance del prototipo.

### CÃ³digos

- **RF / RNF** â€” Requerimientos del SRS v2.0.
- **CU-xx** â€” Casos de Uso v2.0.
- **WEB-xx** â€” Mockup de referencia en `mockups_section.md Â§11.1`.

### UbicaciÃ³n de una vista

`archivo â€º funciÃ³n` â€” la **secciÃ³n** es el `id` que recibe `go(id)` / el
sidebar en [mockups/web/app.jsx](mockups/web/app.jsx).

### Archivos del prototipo

| Archivo | Contenido |
|---|---|
| [index.html](mockups/web/index.html) | Carga React + Babel + scripts |
| [styles.css](mockups/web/styles.css) | Design system de escritorio |
| [shared.jsx](mockups/web/shared.jsx) | Iconos, `Sidebar`, `Topbar`, `Kpi`, `Panel`, `Bars`, `Donut`, `Badge` |
| [data.jsx](mockups/web/data.jsx) | Datos mock + definiciÃ³n de roles y navegaciÃ³n |
| [dashboards.jsx](mockups/web/dashboards.jsx) | `Login` + 4 dashboards |
| [modules.jsx](mockups/web/modules.jsx) | Usuarios, Pagos, Asistencia, Productos, Reportes, Config |
| [modules2.jsx](mockups/web/modules2.jsx) | MembresÃ­as, Caja, Finanzas, Puntos, Clases, Entrenamientos, CRM |
| [app.jsx](mockups/web/app.jsx) | RaÃ­z: login + shell + routing por rol |

---

## 2. Vistas del panel web â€” trazabilidad

| # | Vista | FunciÃ³n â€º secciÃ³n | Rol(es) | Mockup | Trazabilidad (RF / RNF / CU) |
|---|---|---|---|---|---|
| 1 | Inicio de sesiÃ³n | `Login` â€º *(login)* | todos | â€” | **CU-01**; CU-02 (enlace recuperar); RNF 3 (token "recordarme") |
| 2 | Dashboard Admin | `AdminDashboard` â€º `dashboard` | admin | **WEB-01** | RF 2.3 (accesos denegados), RF 3.3 (pagos pendientes), RF 3.4 (por vencer) |
| 3 | Dashboard de turno | `CajeroDashboard` â€º `dashboard` | cajero | â€” | RF 2.1, RF 3.1 (resumen del turno); RNF 3 (turno con horario) |
| 4 | Panel del entrenador | `CoachDashboard` â€º `dashboard` | coach | â€” | RF 3.6 (consumo); Vista TÃ©cnica (L Asignados) |
| 5 | Mi resumen | `MiembroDashboard` â€º `dashboard` | miembro | MOB-USER-04 | RF 3.4; estado de membresÃ­a (L Propio) |
| 6 | Usuarios (lista) | `Usuarios` â€º `usuarios` | admin, coach | **WEB-02** | **RF 1.1**, RF 1.2, RF 1.3; CU-04 |
| 7 | Detalle de usuario | `UserDetail` â€º `usuarios` (sub) | admin, coach | **WEB-03** | Vista Operativa (L/E Admin); **RF 1.3** (baja lÃ³gica), RF 3.1; CU-06, CU-07 |
| 8 | Pagos y acreditaciones | `Pagos` â€º `pagos` | admin, cajero | **WEB-04** | **RF 3.1** (cobros del dÃ­a), **RF 3.3** (aprobar acreditaciÃ³n); CU-09, CU-11 |
| 9 | Control de asistencia | `Asistencia` â€º `asistencia` | admin, cajero | **WEB-05** | **RF 2.1, RF 2.2, RF 2.3**; CU-08; RNF 2 (validaciÃ³n â‰¤ 2 s) |
| 10 | Productos e inventario | `Productos` â€º `productos` | admin, cajero | â€” | MÃ³dulo Productos (CRUD de inventario y precios) |
| 11 | Reportes y analÃ­tica | `Reportes` â€º `reportes` | admin | **WEB-08** | Soporte de gestiÃ³n: retenciÃ³n, ingresos, mÃ©todos de pago |
| 12 | ConfiguraciÃ³n del gimnasio | `Config` â€º `config` | admin | **WEB-09** | CU-07 (Perfil Empresa); RF 2.4 (dÃ­a de gracia configurable) |
| 13 | MembresÃ­as y planes | `Membresias` â€º `membresias` | admin, cajero | â€” | RF 3.x (planes, precios); congelar / traspasar / abono de membresÃ­a |
| 14 | Caja del turno | `Caja` â€º `caja` | admin, cajero | â€” | Apertura / cierre de caja, movimientos, egresos del turno; RNF 3 (control por turno) |
| 15 | Finanzas del gimnasio | `Finanzas` â€º `finanzas` | admin | â€” | Sueldos, servicios, gastos e ingresos especiales (mÃ³dulo `pagos` de crosshero) |
| 16 | Puntos y fidelizaciÃ³n | `Puntos` â€º `puntos` | admin, cajero | â€” | CatÃ¡logo canjeable y canjes (mÃ³dulo `puntos` â€” fuera del SRS, propio de crosshero) |
| 17 | Clases y horarios | `Clases` â€º `clases` | admin, coach | **WEB-06** | GestiÃ³n de clases, cupos y entrenadores |
| 18 | Entrenamientos y rutinas | `Entrenamientos` â€º `entrenamientos` | admin, coach | â€” | **RF 4.1, RF 4.2** (biblioteca de rutinas/ejercicios y grupos musculares) |
| 19 | CRM Â· campaÃ±as y contactos | `CRM` â€º `crm` | admin | â€” | RF 5.3 (comunicaciÃ³n); campaÃ±as email/WhatsApp/push, contactos y seguimientos |

| 20 | Resumen de la plataforma | `SuperDashboard` â€º `dashboard` | superadmin | â€” | Back-office SaaS: KPIs de la red, estado de instancias |
| 21 | Gimnasios de la red | `Gimnasios` â€º `gimnasios` | superadmin | â€” | Clientes = instancias multi-tenant; alta/estado de cada gimnasio |
| 22 | Planes SaaS | `PlanesSaaS` â€º `planes` | superadmin | â€” | Planes de suscripciÃ³n de la plataforma + facturaciÃ³n (MRR) |

> Filas 20-22: rol **Super Administrador** â€” gestiona la plataforma SaaS, no un
> gimnasio concreto. Es el back-office multi-tenant; el SRS lo menciona como
> rol de plataforma.

> Filas 13-19: mÃ³dulos aÃ±adidos para dar **paridad con la app real
> `proyecto_antiguo`**. Varios (`puntos`, `crm`, `finanzas`) son funcionalidad
> propia de crosshero que **excede el SRS v2.0** â€” el SRS solo cubre acceso,
> pagos, rutinas, observaciones y anuncios. Cada vista es la **pantalla
> principal** del mÃ³dulo; sus sub-flujos (CRUD detallado, formularios) quedan
> como iteraciÃ³n posterior.

### Notas de privacidad por vista

- **Usuarios / Detalle de usuario** muestran la *Vista Operativa* (nombre, DNI,
  estado de membresÃ­a, entrenador). El panel **no expone datos mÃ©dicos ni
  fÃ­sicos** del practicante (matriz: Admin = `No` sobre Vista TÃ©cnica/FÃ­sica).
- **Pagos** y **Asistencia** son `Lectura/Escritura` para Admin; el Cajero
  opera la misma pantalla pero su actividad queda registrada (auditorÃ­a).
- **Reportes** y **ConfiguraciÃ³n** son exclusivos de Admin.

---

## 3. Cobertura inversa â€” requerimiento â†’ vista del panel web

| Requerimiento | Vista(s) del panel web | Cobertura |
|---|---|---|
| CU-01 Inicio de sesiÃ³n | `Login` | âœ… |
| CU-02 RecuperaciÃ³n de contraseÃ±a | `Login` (solo enlace) | âš ï¸ Parcial |
| CU-03 Cierre de sesiÃ³n | botÃ³n "Cerrar sesiÃ³n" del `Topbar` â†’ vuelve al `Login` | âœ… (simulado) |
| RF 1.1 Registro de usuario | `Usuarios` (botÃ³n Registrar) | âœ… |
| RF 1.2 AsignaciÃ³n de entrenador | `UserDetail` (campo Entrenador) | âš ï¸ Parcial |
| RF 1.3 Baja lÃ³gica | `UserDetail` (botÃ³n "Dar de baja lÃ³gica") | âœ… |
| RF 2.1 Registro de ingreso | `Asistencia` (log del dÃ­a), `AdminDashboard` | âœ… |
| RF 2.2 Escaneo QR / DNI | `Asistencia` (escÃ¡ner + ingreso manual) | âœ… |
| RF 2.3 Bloqueo + alerta | `Asistencia` (denegados), `AdminDashboard` | âœ… |
| RF 2.4 Margen de gracia | `Config` (dÃ­a de gracia configurable) | âœ… |
| RF 3.1 Pago en efectivo | `Pagos` (cobros del dÃ­a), `UserDetail` | âœ… |
| RF 3.3 AcreditaciÃ³n manual | `Pagos` (pendientes â†’ aprobar/rechazar) | âœ… |
| RF 3.4 Aviso de vencimiento | `AdminDashboard` (pagos pendientes / por vencer) | âœ… |
| RNF 2 Rendimiento â‰¤ 2 s | `Asistencia` (flujo de escaneo) | âš ï¸ Visual |
| RNF 3 Seguridad / multi-tenant | `Login` (token), sidebar muestra instancia Ãºnica del gym | âš ï¸ Parcial |

## 4. VacÃ­os detectados (sin vista en el panel web)

| Faltante | Caso de uso / RF | Comentario |
|---|---|---|
| RecuperaciÃ³n de contraseÃ±a | CU-02 | Solo existe el enlace en el `Login`, sin pantalla de reset |
| AsignaciÃ³n de entrenador (flujo) | RF 1.2 / CU-05 | `UserDetail` muestra el entrenador pero sin selector dedicado |
| BuzÃ³n de observaciones | WEB-07 / RF 5.2 | Pendiente â€” el SRS sÃ­ lo pide; aÃ±adir como vista de mÃ³dulo |
| Banner si push deshabilitado | RF 3.6 | No implementado |

> Las **vistas principales** de los 12 mÃ³dulos ya estÃ¡n cubiertas (filas
> 1-19). Lo pendiente son **sub-flujos** dentro de cada mÃ³dulo (formularios
> CRUD, detalles, confirmaciones) y la pantalla de observaciones.

> Estas vistas se pueden aÃ±adir luego siguiendo los mockups `WEB-06`/`WEB-07`
> de `mockups_section.md` con la misma estructura (`modules.jsx`).

---

## 5. RelaciÃ³n con los otros artefactos del proyecto

| Artefacto | QuÃ© cubre |
|---|---|
| `mockups/mobile/` + [TRAZABILIDAD_VISTAS.md](TRAZABILIDAD_VISTAS.md) | Prototipo **mÃ³vil** (apps de los 4 roles) |
| `mockups/web/` + este documento | Prototipo **web de escritorio** (panel de administraciÃ³n) |
| `proyecto_antiguo/` (Django) | ImplementaciÃ³n real del panel web (219 plantillas) |
| `mobile_app/` | Port nativo del prototipo mÃ³vil |

El prototipo web reutiliza los **tokens de marca** de `mockups/mobile`
(paleta, tipografÃ­as, acento lima) para mantener coherencia visual entre la
app mÃ³vil y el panel web.


