# Modelo de datos

El esquema central esta en `backend/prisma/schema.prisma`. Usa PostgreSQL y Prisma bajo un enfoque multi-tenant de base compartida y esquema compartido.

## Dominios principales

### Multi-tenant y usuarios

Entidades:

- `Tenant`
- `User`
- `TrainerProfile`
- `MemberProfile`
- `AuditLog`

Funcion:

- Representar gimnasios/clientes SaaS.
- Aislar datos por tenant.
- Manejar roles y estado de usuarios.
- Guardar perfiles de entrenador y miembro.
- Registrar trazabilidad de operaciones.

### Membresias y pagos

Entidades:

- `Membership`
- `Payment`
- `Caja`
- `MovimientoCaja`

Funcion:

- Controlar membresias activas, vencidas o en gracia.
- Registrar pagos manuales y POS.
- Gestionar apertura, movimientos y cierre de caja.
- Asociar cobros al cajero y tenant.

### Asistencia y acceso

Entidades:

- `Attendance`
- `Fingerprint`
- `FingerprintAttendance`

Funcion:

- Validar acceso de miembros.
- Registrar asistencia por QR/TOTP.
- Modelar biometria para huella.
- Guardar ingresos por dispositivos fisicos.

### Rutinas y entrenamiento

Entidades:

- `Schedule`
- `Booking`
- `Exercise`
- `RoutineTemplate`
- `RoutineExercise`
- `RoutineAssignment`
- `WorkoutSession`
- `SeriesLog`

Funcion:

- Mantener biblioteca de ejercicios.
- Crear plantillas de rutina.
- Asignar rutinas a miembros.
- Registrar sesiones, series, esfuerzo y progreso.
- Gestionar clases y reservas.

### Observaciones y anuncios

Entidades:

- `Observation`
- `Announcement`

Funcion:

- Permitir reportes de incidencias o observaciones.
- Publicar comunicados del gimnasio.
- Mostrar banners activos por tenant.

### Inventario, ventas y puntos

Entidades:

- `Product`
- `ProductCategory`
- `ProductSale`
- `ProductPaymentMethodDetail`
- `ProductSaleDetail`
- `InventoryMovement`
- `PointsConfig`
- `PointsBalance`
- `PointsProduct`
- `PointsMembership`
- `PointsExchange`
- `PointsMovement`

Funcion:

- Mantener catalogo de productos.
- Registrar ventas de productos.
- Controlar stock y movimientos de inventario.
- Acumular y canjear puntos.

## Enums relevantes

- `Role`
- `UserState`
- `MembershipState`
- `PaymentMethod`
- `PaymentState`
- `AccessMethod`
- `BookingState`
- `SessionState`

## Reglas de arquitectura

- Toda entidad operativa debe incluir tenant o estar relacionada con una entidad que lo incluya.
- Las consultas de servicios deben filtrar por `tenant_id` o equivalente.
- Los endpoints no deben confiar solo en un tenant enviado por el cliente; debe validarse contra el JWT.
- Las operaciones sensibles deben quedar registradas en `AuditLog`.

## Nota de naming

El esquema mezcla nombres estilo snake case y nombres Prisma en PascalCase/camelCase segun entidad y campo. Antes de refactorizar nombres conviene priorizar estabilidad de integracion entre backend, seed y app.
