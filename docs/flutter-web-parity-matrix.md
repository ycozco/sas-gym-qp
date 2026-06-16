# Matriz de Paridad Flutter/Web

Estado de referencia para cruzar `mobile_app`, `web_admin` y backend NestJS. Esta matriz se debe actualizar cada vez que un flujo cambie de `demo` o `mixto` a `real`.

Estados:

- `real`: usa backend productivo del tenant.
- `mixto`: combina backend real con fallback/local UI.
- `demo`: depende de estado local o mock.
- `faltante`: no existe flujo operativo equivalente.

## Reglas de contrato compartido

- Flutter y web deben usar el mismo endpoint por dominio cuando el flujo represente la misma operación.
- `tenant_id` via header y RBAC backend son la fuente de verdad; no se aceptan filtros cliente-only como mecanismo de seguridad.
- `themeMode` usa wire format único: `system | light | dark`.
- Edición de planes de membresía impacta solo ventas nuevas; las membresías existentes conservan snapshot.
- Venta POS y venta de membresía deben respetar el contrato `cartItems/payments`.

## Paridad por rol

| Rol | Flujo | Flutter | Web | Endpoint / Fuente | Estado | Nota |
|---|---|---|---|---|---|---|
| `SUPER_ADMIN` | Login y sesión | Sí | Sí | `/auth/login`, `/auth/me`, `/auth/refresh` | `real` | Web ya refresca por cookie; Flutter sigue con token local. |
| `SUPER_ADMIN` | Tenants / toggle | Sí | Sí | `/tenants`, `/tenants/:id/toggle` | `real` | Barrera SaaS aplicada. |
| `SUPER_ADMIN` | Resumen SaaS | Parcial | Sí | `/tenants`, `/reports/dashboard` | `mixto` | Flutter aún usa más datos locales para presentación. |
| `ADMIN` | Dashboard | Parcial | Sí | `/reports/dashboard` | `mixto` | Flutter ya carga datos reales; algunos tiles siguen con composición local. |
| `ADMIN` | Miembros | Sí | Sí | `/admin/members` | `real` | Flutter ahora carga catálogo real; formularios siguen con UX histórica. |
| `ADMIN` | Cajeros | Sí | Sí | `/admin/cashiers` | `real` | Permisos en backend siguen siendo placeholder UI. |
| `ADMIN` | Productos | Sí | Sí | `/products` | `real` | Flutter y web leen inventario real. |
| `ADMIN` | Membresías CRUD | Sí | Sí | `/membership-plans` | `real` | Snapshot histórico validado. |
| `ADMIN` | Configuración tenant | Sí | Sí | `/tenants/me`, `/tenants/me/settings` | `real` | Colores y branding aplican por tenant. |
| `ADMIN` | Observaciones | Sí | Sí | `/observations` | `real` | Upload ya existe en móvil; web consume listado. |
| `ADMIN` | Auditoría | Sí | Sí | `/reports/audit-logs` | `real` | Filtros avanzados aún pendientes. |
| `CAJA` | Apertura / caja activa / cierre | Sí | Sí | `/payments/caja/*` | `real` | Flujo base alineado. |
| `CAJA` | POS productos | Sí | Sí | `/payments/pos-charge`, `/products` | `real` | Contrato compartido. |
| `CAJA` | Venta membresía | Sí | Sí | `/payments/membership-sale`, `/membership-plans` | `real` | Mantener snapshot de plan. |
| `CAJA` | Búsqueda de socios | Sí | Sí | `/members/search` | `real` | Flutter aún conserva UI histórica para alta local. |
| `CAJA` | Acceso / veredicto | Sí | Sí | `/attendance/simulation-access`, `/attendance/verify` | `real` | Venta desde acceso denegado disponible. |
| `TRAINER` | Alumnos asignados | Sí | Sí | `/members/assigned` | `real` | Flutter ya prioriza asignados reales. |
| `TRAINER` | Seguimiento / notas | Parcial | Parcial | `/observations`, datos de alumno | `mixto` | Persistencia fina de notas y plantillas sigue parcial. |
| `TRAINER` | Biblioteca / plantillas | Sí | Parcial | local / futura API | `demo` | Requiere endpoints propios para paridad total. |
| `MEMBER` | Perfil / membresía actual | Sí | Sí | `/auth/me` | `real` | Flutter compone UI desde perfil autenticado. |
| `MEMBER` | Historial de pagos | Sí | Sí | `/payments/me` | `real` | Flutter ya inyecta pagos reales en la vista. |
| `MEMBER` | QR / acceso | Sí | Sí | `/auth/me`, `/attendance/verify` | `real` | Móvil conserva experiencia principal. |
| `MEMBER` | Rutina activa | Parcial | Sí | `/routines/active` | `mixto` | Flutter aún mezcla backend con vistas locales. |
| `MEMBER` | Anuncios | Sí | Sí | `/announcements` | `real` | |
| `MEMBER` | Clases | Parcial | Sí | `/schedules` | `mixto` | Flutter aún no consume horarios reales en toda la UX. |
| `MEMBER` | Puntos | Parcial | Sí | `/points/summary`, `/points/catalog` | `mixto` | Web ya consume catálogo; Flutter aún no explota todo el dominio. |

## Buckets de brechas activas

### Sin backend faltante

- Tema y preferencia visual.
- Configuración tenant.
- Planes de membresía.
- Caja, POS, cierre, egresos.
- Miembros admin.
- Productos.
- Auditoría.

### Requiere ajuste de shape

- Pagos de miembro en Flutter.
- Mapeo de alumnos asignados en Flutter.
- Resumen SaaS de Flutter.
- Estados de membresía y badges entre ambos clientes.

### Requiere endpoint nuevo

- Plantillas de rutina de entrenador.
- Biblioteca de ejercicios persistente.
- Seguimiento rico de progreso.
- Clases/reservas con acciones de inscripción/cancelación.
- Puntos con canje transaccional completo en cliente móvil.
