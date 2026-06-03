# APIs y flujos

Este documento resume los endpoints encontrados en los controladores NestJS y los flujos de negocio que representan.

## Endpoints por modulo

### Auth

| Metodo | Ruta | Uso |
|---|---|---|
| `POST` | `/auth/login` | Autentica por email/DNI y password. |
| `POST` | `/auth/forgot-password` | Recuperacion simulada o disparador futuro. |
| `GET` | `/auth/me` | Perfil del usuario autenticado. |

### Tenants

| Metodo | Ruta | Uso |
|---|---|---|
| `GET` | `/tenants` | Lista gimnasios/clientes SaaS. |
| `POST` | `/tenants/:id/toggle` | Activa o suspende un tenant. |

### Members

| Metodo | Ruta | Uso |
|---|---|---|
| `GET` | `/members/search?q=` | Busca miembros por tenant. |
| `POST` | `/members/workout-log` | Guarda log de entrenamiento. |

### Attendance

| Metodo | Ruta | Uso |
|---|---|---|
| `POST` | `/attendance/verify` | Valida QR/TOTP y registra asistencia. |
| `POST` | `/attendance/fingerprint/register` | Registra huella. |
| `POST` | `/attendance/fingerprint/verify` | Verifica huella y registra ingreso. |

### Routines

| Metodo | Ruta | Uso |
|---|---|---|
| `GET` | `/routines/active` | Obtiene rutina activa del miembro autenticado. |

### Payments

| Metodo | Ruta | Uso |
|---|---|---|
| `POST` | `/payments/upload-receipt` | Crea pago/comprobante para revision. |
| `GET` | `/payments/pending` | Lista pagos pendientes. |
| `POST` | `/payments/:id/resolve` | Aprueba o rechaza un pago. |
| `GET` | `/payments/check-shift` | Verifica turno de cajero. |
| `POST` | `/payments/pos-charge` | Procesa cobro POS. |
| `POST` | `/payments/caja/open` | Abre caja. |
| `GET` | `/payments/caja/active` | Consulta caja activa. |
| `POST` | `/payments/caja/egress` | Registra egreso. |
| `GET` | `/payments/caja/details` | Detalle de caja y movimientos. |
| `POST` | `/payments/caja/close` | Cierra caja. |
| `POST` | `/payments/membership-sale` | Registra venta de membresia. |

### Observations

| Metodo | Ruta | Uso |
|---|---|---|
| `POST` | `/observations/upload` | Crea observacion/incidencia. |
| `GET` | `/observations` | Lista observaciones del tenant. |

### Announcements

| Metodo | Ruta | Uso |
|---|---|---|
| `GET` | `/announcements` | Lista anuncios activos. |
| `GET` | `/announcements/all` | Lista todos los anuncios. |
| `POST` | `/announcements` | Crea anuncio. |
| `PUT` | `/announcements/:id` | Actualiza anuncio. |
| `PATCH` | `/announcements/:id/toggle` | Activa/desactiva anuncio. |

### Reports

| Metodo | Ruta | Uso |
|---|---|---|
| `GET` | `/reports/audit-logs` | Lista auditoria por tenant. |

## Flujos de negocio

### Login y contexto tenant

1. El usuario envia credenciales a `/auth/login`.
2. El backend valida usuario, password y tenant.
3. El backend devuelve token y datos de sesion.
4. La app guarda token y tenant en almacenamiento seguro.
5. Cada request debe enviar token y contexto tenant.

### Suspension SaaS

1. Superadmin cambia estado del tenant con `/tenants/:id/toggle`.
2. El backend actualiza el estado.
3. El gateway puede emitir evento al tenant afectado.
4. La app muestra `GymSuspendedBarrier` cuando detecta suspension.

### Acceso por QR

1. El miembro genera o muestra un QR dinamico.
2. Caja/Admin escanea DNI/token.
3. `/attendance/verify` valida TOTP y membresia.
4. El backend registra asistencia.
5. La UI muestra veredicto verde o rojo.

### Pago manual

1. El miembro sube comprobante a `/payments/upload-receipt`.
2. Admin lista pendientes con `/payments/pending`.
3. Admin aprueba o rechaza con `/payments/:id/resolve`.
4. Si se aprueba, se actualiza membresia/estado del miembro.

### Turno de caja y POS

1. Cajero abre caja con `/payments/caja/open`.
2. La app consulta caja activa.
3. Cajero procesa cobros o ventas.
4. Los movimientos quedan asociados a caja y cajero.
5. Cajero cierra caja con montos reportados.
6. Admin puede revisar diferencias y auditoria.

### Rutinas y progreso

1. El miembro consulta `/routines/active`.
2. La app muestra ejercicios y sesiones.
3. El miembro registra esfuerzo.
4. `/members/workout-log` guarda la sesion.
5. Entrenador/Admin revisan progreso segun integraciones futuras.
