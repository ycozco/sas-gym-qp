# Prueba caja desde móvil - Celular físico - 2026-06-16

## Objetivo

Validar desde el APK instalado en un celular físico que el rol caja puede operar contra el backend Docker local:

- Abrir caja.
- Registrar venta/cobro.
- Verificar doble tap/doble submit.
- Registrar egreso.
- Cerrar caja.
- Verificar trazabilidad/auditoría.

## Ambiente

| Campo | Valor |
| --- | --- |
| Rama | `production` |
| Backend | Docker local |
| API local para celular | `http://192.168.1.11:3000/api/v1` |
| APK esperado | `release/2026-06-16_v0.1/sas-gym-v0.1.0-2026-06-16-local.apk` |
| Flavor | `dev` |
| App ID | `com.sasgym.app.dev` |
| Modo | `APP_MODE=backend` |
| Usuario caja | `caja1.surco@test.sasgym.com` |
| Contraseña | `caja_secure_pass` |

## Precondiciones

- PC y celular conectados a la misma red Wi-Fi.
- Docker Compose activo con API publicada en puerto `3000`.
- Desde el navegador del celular debe abrir `http://192.168.1.11:3000/api/v1`.
- APK dev/local instalado en el celular.
- No debe existir una caja abierta previa para el cajero; si existe, cerrarla antes de iniciar.

## Datos de prueba

| Dato | Valor |
| --- | --- |
| Saldo inicial | `S/ 100.00` |
| Producto POS sugerido | `Botella de agua 600ml` |
| Método de pago sugerido | `Efectivo` |
| Egreso | `S/ 30.00` |
| Motivo egreso | `Prueba egreso móvil` |

## Casos

### MOB-CAJA-001 - Abrir caja

Pasos:

1. Abrir el APK `SaaaS GYM Dev`.
2. Iniciar sesión como caja.
3. En la pantalla Inicio, ubicar `Turno de caja`.
4. Tocar `Abrir`.
5. Confirmar saldo inicial `100` y observación `Prueba caja móvil`.
6. Refrescar el panel.

Resultado esperado:

- El panel muestra `CAJA ABIERTA`.
- El saldo apertura muestra `S/ 100.00`.
- Se registra un log local de `Apertura de Caja (API)`.

Estado: `PASÓ`

### MOB-CAJA-002 - Registrar venta/cobro

Pasos:

1. Ir a pestaña `POS`.
2. Seleccionar un socio existente.
3. Agregar `Botella de agua 600ml`.
4. Tocar `CONTINUAR AL PAGO`.
5. Elegir `Efectivo`.
6. Ingresar efectivo recibido igual o mayor al total.
7. Tocar `Confirmar Venta`.

Resultado esperado:

- Aparece confirmación `Venta Completada`.
- La pestaña `Ventas` muestra una venta nueva.
- El panel de caja actualiza movimientos y total esperado.
- La venta queda persistida en backend.

Estado: `PASÓ`

### MOB-CAJA-003 - Doble tap/doble submit

Pasos:

1. Repetir el flujo de venta con un producto de bajo monto.
2. En el diálogo de pago, tocar `Confirmar Venta` dos veces lo más rápido posible.
3. Volver a `Ventas`.
4. Refrescar el panel de caja.

Resultado esperado:

- Debe existir un solo cobro para esa intención de venta.
- No deben duplicarse movimientos financieros.

Estado: `PASÓ`

Observación de riesgo:

- En la UI actual el botón `Confirmar Venta` no muestra un bloqueo explícito de submit mientras espera la respuesta del backend. Si aparecen dos cobros, marcar como `FALLA CRÍTICA`.

### MOB-CAJA-004 - Registrar egreso

Pasos:

1. Ir a pantalla Inicio.
2. En `Turno de caja`, tocar `Egreso`.
3. Registrar monto `30`.
4. Registrar motivo `Prueba egreso móvil`.
5. Elegir método `Efectivo`.
6. Confirmar.
7. Refrescar el panel.

Resultado esperado:

- Movimientos aumenta en al menos una unidad.
- Efectivo esperado descuenta `S/ 30.00`.
- Se registra log local `Egreso de Caja (API)`.

Estado: `PASÓ`

### MOB-CAJA-005 - Cerrar caja

Pasos:

1. Ir a pantalla Inicio.
2. En `Turno de caja`, tocar `Cerrar`.
3. Confirmar los montos precargados por el sistema.
4. Registrar observación `Cierre prueba caja móvil`.
5. Confirmar cierre.
6. Refrescar el panel.

Resultado esperado:

- La caja queda cerrada en backend.
- El panel vuelve a `SIN CAJA ABIERTA`.
- La diferencia esperada es `S/ 0.00` si los montos coinciden.
- Se registra log local `Cierre de Caja (API)`.

Estado: `PASÓ`

### MOB-CAJA-006 - Verificar auditoría

Pasos:

1. Revisar `Mis logs de auditoría` en el rol caja.
2. Revisar desde el rol admin si la auditoría global expone la operación.
3. Opcionalmente validar en backend/DB que existan caja, movimientos y venta.

Resultado esperado:

- Existen evidencias para apertura, venta, egreso y cierre.
- Los eventos están asociados al usuario caja y al tenant correcto.

Estado: `PASÓ`

## Criterio de aprobación

La prueba completa se aprueba si:

- El flujo se ejecuta completo desde el APK del celular.
- No hay duplicidad de cobros en doble tap.
- Los totales de cierre cuadran con `saldo inicial + ingresos - egresos`.
- La auditoría permite rastrear las operaciones principales.

Si el doble submit duplica pagos, la prueba queda `FALLIDA CRÍTICA`.

## Registro de ejecución

Resultado marcado como `PASÓ` el 2026-06-16 por indicación del responsable de validación funcional.

| Caso | Estado | Evidencia | Observaciones |
| --- | --- | --- | --- |
| MOB-CAJA-001 | `PASÓ` | Validación funcional en APK dev/local | Caja abierta desde celular. |
| MOB-CAJA-002 | `PASÓ` | Validación funcional en APK dev/local | Venta/cobro registrado desde POS móvil. |
| MOB-CAJA-003 | `PASÓ` | Validación funcional en APK dev/local | Doble submit sin duplicidad reportada. |
| MOB-CAJA-004 | `PASÓ` | Validación funcional en APK dev/local | Egreso registrado desde panel móvil. |
| MOB-CAJA-005 | `PASÓ` | Validación funcional en APK dev/local | Caja cerrada desde celular. |
| MOB-CAJA-006 | `PASÓ` | Validación funcional en APK dev/local | Auditoría revisada. |
