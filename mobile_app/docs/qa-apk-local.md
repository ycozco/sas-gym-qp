# QA APK local con backend real

Esta guia valida el APK local contra la API local Docker. No usar modo demo.

## Precondiciones

- PC y telefono en la misma red WiFi.
- API local arriba en `http://<IP_LAN_PC>:3000/api/v1`.
- Docker local levantado desde la raiz del repo:

```bash
cd /ruta/al/proyecto/sas-gym-qp
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

Para saber la IP LAN de la PC:

```bash
ip route get 1.1.1.1
```

Usar el valor que aparece despues de `src`.

- Verificacion rapida:

```bash
curl http://127.0.0.1:3000/api/v1
```

Debe responder `Hello World!`.

## Ejecutar en dispositivo conectado

Desde `mobile_app`:

```bash
cd /ruta/al/proyecto/sas-gym-qp/mobile_app
flutter devices
flutter run --flavor dev \
  --dart-define=APP_ENV=dev \
  --dart-define=APP_MODE=backend \
  --dart-define=API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1 \
  -d <DEVICE_ID>
```

No usar `APP_MODE=demo`. El APK backend local debe fallar si se intenta activar demo sin `ALLOW_DEMO_MODE=true`.

## Construir APK local repetible

Desde `mobile_app`:

```bash
API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1 ./scripts/build-local-apk.sh
```

APK generado:

```text
mobile_app/build/app/outputs/flutter-apk/app-dev-debug.apk
```

Instalar en celular conectado por cable:

```bash
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

El script exige `API_BASE_URL` y rechaza `localhost`, `127.0.0.1` y `10.0.2.2` porque no sirven para un telefono fisico.

## Credenciales base

| Rol | Usuario | Password |
| --- | --- | --- |
| SUPER_ADMIN | `superadmin@test.sasgym.com` | `super_secure_pass` |
| ADMIN | `admin1.surco@test.sasgym.com` | `admin_secure_pass` |
| CAJA | `caja1.surco@test.sasgym.com` | `caja_secure_pass` |
| TRAINER | `trainer1.surco@test.sasgym.com` | `trainer_secure_pass` |
| MEMBER | `socio01.surco@test.sasgym.com` | `member_secure_pass` |

## Matriz minima por rol

| Rol | Flujo | Resultado esperado | Evidencia |
| --- | --- | --- | --- |
| TRAINER | Login | Entra al home trainer sin datos demo | Pantalla muestra miembros/rutinas desde API o estados vacios reales |
| TRAINER | Crear incidencia desde buzon | Guarda sin error Prisma `detalles` | `docker compose ... logs api` sin `Argument detalles is missing` |
| TRAINER | Cargar miembros asignados | Lista o estado vacio controlado | No debe aparecer seed local incrustado |
| MEMBER | Login | Entra al home member | Rutina/pagos/agenda se consultan contra API |
| MEMBER | Ver QR | Muestra QR solo si backend entrega `qr_secret` | Sin secret debe mostrar `QR no disponible` |
| MEMBER | Registrar esfuerzo | Si no hay red, encola; si hay red, sincroniza | Mensaje de sincronizacion o cola offline |
| ADMIN | Login | Entra al panel admin | Deben cargar miembros, caja, productos y auditoria |
| ADMIN | Auditoria | Ver logs de login/incidencias | Debe aparecer `LOGIN / AUTH` tras login reciente |
| CAJA | Login | Entra al panel caja | Carga productos y miembros desde API |
| CAJA | Caja/venta | Intentar flujo POS | Error debe ser claro si falta turno o permiso |
| SUPER_ADMIN | Login | Entra al panel superadmin | Lista tenants desde API |

## Criterios de rechazo

- La app muestra usuarios/productos/rutinas demo sin haber iniciado sesion real.
- La app funciona con `localhost` en un telefono fisico.
- El login parece exitoso pero no aparece auditoria `LOGIN / AUTH`.
- Guardar incidencia genera errores Prisma en logs.
- Un `401` deja la app en una pantalla interna sin pedir login.
- Los mensajes de red son genericos cuando la API esta caida.

## Logs utiles

Desde la raiz del repo:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml logs --tail=160 api
```

Estado de servicios:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml ps
```
