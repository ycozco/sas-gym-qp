# Plan de verificacion y pruebas

## Objetivo

Definir una estrategia de verificacion para SaaaS GYM que cubra pruebas unitarias, integracion, smoke tests, pruebas por rol y criterios de aceptacion. El foco es validar el estado actual del sistema sin asumir que todas las pantallas Flutter ya consumen API real.

## Capas de verificacion

| Capa | Objetivo | Herramientas |
|---|---|---|
| Backend unitario | Validar servicios, controladores, guards e interceptor. | Jest, Nest Testing Module. |
| Backend E2E | Validar endpoints principales con app Nest levantada. | Jest E2E, Supertest. |
| Base de datos | Validar schema Prisma, seed y aislamiento por tenant. | Prisma, PostgreSQL, Docker Compose. |
| Flutter unit/widget | Validar estado, routing por rol y componentes criticos. | `flutter test`. |
| Flutter estatico | Detectar errores de analisis, APIs deprecadas y lints. | `flutter analyze`. |
| Integracion | Validar API + DB + Flutter web + hub estatico. | Docker Compose, logs, requests manuales. |
| E2E funcional | Validar flujos de negocio por rol. | Smoke manual guiado o automatizacion futura. |

## Comandos base

### Backend

```powershell
cd backend
npm run build
npm run test
npm run test:e2e
```

### Flutter

```powershell
cd mobile_app
flutter analyze
flutter test
```

### Integracion local

```powershell
docker compose up --build
docker compose ps
docker compose logs api
docker compose logs frontend-web
```

Servicios a verificar:

- API: `http://localhost:3000`
- Flutter web: `http://localhost:8383`
- Hub/mockups/docs: `http://localhost:8282`
- PostgreSQL: `127.0.0.1:5432`

## Pruebas unitarias backend

### Cobertura minima esperada

| Modulo | Casos unitarios recomendados |
|---|---|
| `auth` | Credenciales validas, password invalido, usuario inexistente, tenant suspendido, payload JWT esperado. |
| `tenants` | Listado de tenants, toggle activo/suspendido, emision de evento de suspension si aplica. |
| `payments` | Subida de comprobante, aprobacion/rechazo, venta POS, venta de membresia, idempotencia si existe token. |
| `cashier-session` | Apertura de caja, caja activa, egreso, detalle, cierre y calculo de diferencias. |
| `attendance` | QR valido, QR invalido, membresia vencida, periodo de gracia, registro de asistencia. |
| `members` | Busqueda por tenant, guardado de workout log, bloqueo de acceso cross-tenant. |
| `announcements` | Crear, listar activos, listar todos, editar y activar/desactivar. |
| `reports` | Listado de auditoria filtrado por tenant. |

### Guards e interceptor

Validar:

- `AuthGuard` rechaza requests sin token o con token invalido.
- `TenantGuard` rechaza `X-Tenant-ID` distinto al tenant del JWT.
- `RolesGuard` bloquea roles no autorizados.
- `AuditInterceptor` registra escrituras exitosas y oculta campos sensibles como password, token, secret, hash y key.

## Pruebas backend E2E

El test E2E actual solo valida `GET /`. La cobertura E2E recomendada debe crecer hacia flujos reales.

Casos E2E prioritarios:

1. `POST /auth/login` devuelve token y usuario.
2. `GET /auth/me` requiere token.
3. `GET /tenants` responde para superadmin.
4. `POST /tenants/:id/toggle` cambia estado del tenant.
5. `POST /attendance/verify` registra asistencia con QR valido.
6. `POST /payments/caja/open` abre caja.
7. `POST /payments/pos-charge` registra cobro.
8. `POST /payments/caja/close` cierra caja.
9. `GET /reports/audit-logs` muestra operaciones auditadas.

## Pruebas Flutter

### Smoke tests actuales

Ya existen pruebas base en `mobile_app/test/`:

- `widget_test.dart`: smoke simple.
- `smoke/app_boot_test.dart`: arranque y login sin usuario.
- `smoke/role_routing_test.dart`: arranque por cada rol y barrera SaaS.
- `smoke/widgets_relocated_test.dart`: verificacion de widgets compartidos.

### Casos recomendados

| Area | Casos |
|---|---|
| Auth | Render login, modo demo, error visual, recuperacion de password. |
| Routing por rol | Superadmin, admin, caja, entrenador y miembro cargan sin excepciones. |
| Tenant suspendido | Muestra barrera SaaS y bloquea vistas operativas. |
| Admin | Dashboard, miembros, productos, pagos pendientes, auditoria y modales sensibles. |
| Caja | Turno activo, scanner, POS, ventas, caja y cierre. |
| Miembro | QR, rutina, pago/renovacion, observaciones y registro de esfuerzo. |
| Entrenador | Miembros asignados, ejercicios, plantillas y progreso. |
| Estado | Login/logout, tenant activo/inactivo, actualizaciones de datos demo/API. |

## Pruebas de integracion

### Preparacion

1. Levantar servicios:

```powershell
docker compose up --build
```

2. Confirmar estado:

```powershell
docker compose ps
```

3. Revisar logs:

```powershell
docker compose logs api
docker compose logs frontend-web
docker compose logs web
```

### Casos de integracion API + DB

| Flujo | Resultado esperado |
|---|---|
| Seed inicial | La API arranca luego de `prisma db push`, `generate` y `seed`. |
| Login | Se obtiene JWT y datos de usuario. |
| Perfil | `/auth/me` responde solo con JWT valido. |
| Tenant suspendido | El tenant cambia de estado y la app puede bloquear la experiencia. |
| Caja | Se abre caja, se registra movimiento y se cierra con detalle. |
| Pago | Pago pendiente puede aprobarse o rechazarse. |
| Asistencia | QR/huella registra asistencia segun reglas. |
| Auditoria | Escrituras aparecen en `AuditLog`. |

### Casos de integracion web

| Servicio | URL | Resultado esperado |
|---|---|---|
| API | `http://localhost:3000` | Respuesta HTTP del backend. |
| Flutter web | `http://localhost:8383` | App carga sin errores visibles. |
| Hub estatico | `http://localhost:8282` | Navegacion a mockups y docs. |
| Mockups web | `http://localhost:8282/mockups/web/` | Prototipo web carga. |
| Mockups mobile | `http://localhost:8282/mockups/mobile/` | Prototipo mobile carga. |

## Pruebas E2E por rol

### Super Administrador

- Iniciar sesion como superadmin.
- Ver listado de gimnasios.
- Suspender un tenant.
- Confirmar bloqueo visual en app del tenant.
- Reactivar tenant.

### Administrador

- Iniciar sesion como admin.
- Revisar dashboard.
- Crear o editar miembro si el flujo esta conectado.
- Revisar pagos pendientes.
- Aprobar/rechazar pago.
- Revisar auditoria.

### Caja

- Iniciar sesion como caja.
- Abrir turno.
- Registrar venta/cobro.
- Registrar asistencia.
- Crear egreso.
- Cerrar caja.
- Confirmar que operaciones restringidas no esten disponibles.

### Entrenador

- Iniciar sesion como entrenador.
- Ver miembros asignados.
- Revisar ejercicios y rutinas.
- Crear plantilla o ejercicio si el flujo esta disponible.
- Revisar progreso.

### Miembro

- Iniciar sesion como miembro.
- Ver estado de membresia.
- Abrir QR.
- Consultar rutina activa.
- Registrar esfuerzo.
- Enviar observacion.
- Simular pago o renovacion.

## Matriz de casos criticos

| Caso | Tipo | Aceptacion |
|---|---|---|
| Login | Unitario + E2E | JWT valido, usuario correcto y tenant asociado. |
| Tenant suspendido | Integracion + Flutter | El usuario ve barrera SaaS y no opera. |
| Caja/POS | Unitario + Integracion | Caja abierta, cobro registrado, movimiento asociado. |
| Pagos | Unitario + E2E | Pago pendiente cambia a aprobado/rechazado y audita. |
| QR/asistencia | Unitario + Integracion | QR valido registra asistencia; invalido rechaza. |
| Rutinas | Flutter + API | Miembro ve rutina activa y puede guardar progreso. |
| Anuncios | Unitario + Flutter | Admin publica; miembro ve activos. |
| Auditoria | Unitario + Integracion | Escrituras quedan en logs sin datos sensibles. |

## Criterios de aceptacion

Una entrega se considera verificada cuando:

- `npm run build` pasa en backend.
- `npm run test` pasa en backend.
- `flutter analyze` pasa sin errores.
- `flutter test` pasa.
- `docker compose up --build` levanta los servicios principales.
- Las URLs `3000`, `8383` y `8282` responden.
- Los flujos criticos por rol tienen evidencia manual o automatizada.
- No se expone `proyecto_antiguo/` desde el hub estatico.
- Toda operacion sensible queda auditada o tiene pendiente documentado.
