# Data test SAS Gym

Fecha de preparacion: 2026-06-04

Este archivo documenta la carga realista de prueba generada por `backend/prisma/seed-test.ts`.

## Alcance

La carga crea 5 gimnasios operativos:

- SAS Gym Surco Prime
- SAS Gym Miraflores Fit
- SAS Gym San Borja Performance
- SAS Gym Lince 24/7
- SAS Gym Callao Strong

Por cada gimnasio se crean:

- 2 administradores activos.
- 5 entrenadores activos con perfil tecnico.
- 3 cajeros activos.
- 20 socios con perfil, objetivo fisico y trainer asignado.
- 20 membresias con estados variados: ACTIVE, GRACE, EXPIRED, PENDING y SUSPENDED.
- 5 planes de membresia editables por tenant: mensual plata, mensual oro, trimestral, semestral y pase por dia.
- 3 cajas por sede con saldo inicial, ingresos de membresias, pagos asociados y movimientos.
- Productos base, categorias, movimientos de inventario, anuncios y un audit log de carga.

Tambien se crea un tenant tecnico para `superadmin@test.sasgym.com`.

## Credenciales

Passwords por rol:

- Superadmin: `super_secure_pass`
- Admin: `admin_secure_pass`
- Entrenador: `trainer_secure_pass`
- Caja: `caja_secure_pass`
- Socio: `member_secure_pass`

Correos por patron:

- Superadmin: `superadmin@test.sasgym.com`
- Admin: `admin1.surco@test.sasgym.com`, `admin2.surco@test.sasgym.com`
- Entrenador: `trainer1.surco@test.sasgym.com` ... `trainer5.surco@test.sasgym.com`
- Caja: `caja1.surco@test.sasgym.com` ... `caja3.surco@test.sasgym.com`
- Socio: `socio01.surco@test.sasgym.com` ... `socio20.surco@test.sasgym.com`

Cambiar `surco` por `miraflores`, `sanborja`, `lince` o `callao` para las otras sedes.

## Ejecucion

El seed esta protegido contra borrados accidentales. Para ejecutarlo:

```powershell
cd D:\proyectos\sas_gym\backend
$env:ALLOW_TEST_DATA_RESET='true'
npm run seed:test
```

Con Docker Compose, si se ejecuta dentro del contenedor API:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml exec api sh -lc "ALLOW_TEST_DATA_RESET=true npm run seed:test"
```

## Revision de edicion de membresias

La implementacion ahora incluye catalogo independiente `MembershipPlan` por tenant y referencia opcional `Membership.plan_id`.

La membresia asignada guarda una copia historica de:

- `plan_nombre`
- `duracion_dias`
- `monto`
- descuentos
- fechas
- estado

Esto significa que una venta/asignacion nueva crea un snapshot de la membresia. Editar `MembershipPlan` no actualiza membresias en curso.

Endpoints implementados:

- `GET /api/v1/membership-plans`
- `POST /api/v1/membership-plans`
- `PATCH /api/v1/membership-plans/:id`
- `DELETE /api/v1/membership-plans/:id` como baja logica
- `GET /api/v1/tenants/me`
- `PATCH /api/v1/tenants/me/settings`

Verificacion ejecutada:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml exec api sh -lc "npx ts-node prisma/verify-plan-snapshot.ts"
```

Resultado:

- Membresia existente antes de editar plan: S/ 150.
- Membresia existente despues de editar plan: S/ 150.
- Nuevo precio del plan: S/ 165.
- Nueva membresia temporal creada desde el plan editado: S/ 165.
- `snapshotPreserved: true`
- `newSaleUsesEditedPlan: true`

Con esa regla, los cambios de catalogo aplican solo a nuevas asignaciones o ventas.
