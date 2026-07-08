# Planificacion de proyeccion movil - SaaaS GYM

## Objetivo

Definir la planificacion para evolucionar el aplicativo Flutter de SaaaS GYM hacia una app segura, estable y lista para QA/release. Incluye app movil, Flutter web como superficie de pruebas y contenedores locales para validacion.

Este documento complementa `proyeccion.md`, que contiene los hallazgos tecnicos y de seguridad ordenados por criticidad.

## Estado de ejecucion - 2026-06-03

Se ejecuto el primer tramo del plan movil, cubriendo M0 y la base critica de M1.

Cambios implementados:

- Se corrigio el payload POS invalido en `mobile_app/lib/data/gym_state.dart`.
- Se agrego `mobile_app/lib/core/config/app_config.dart` con:
  - `API_BASE_URL`
  - `APP_ENV`
  - `ENABLE_DEMO_LOGIN`
  - `ENABLE_QR_SIMULATOR`
- El login demo queda oculto por defecto y solo aparece con `--dart-define=ENABLE_DEMO_LOGIN=true`.
- La generacion TOTP basada en DNI queda detras de `--dart-define=ENABLE_QR_SIMULATOR=true`.
- El QR de miembro intenta usar `qr_secret`/`qrSecret` del perfil; si no existe, muestra estado no disponible en vez de generar secreto productivo por DNI.
- Se agrego `AppLogger` para sanitizar logs y evitar `debugPrint` crudos con errores de red, sync, WebSocket, pagos, caja, auditoria, rutinas e imagenes.
- `gym_cache` y `sync_queue_box` se abren cifradas con llave guardada en secure storage.
- En desarrollo existe fallback a caja Hive sin cifrar solo si habia datos locales antiguos; en `APP_ENV=prod` el fallo de cifrado corta el arranque.
- `logout()` limpia `gym_cache` y la cola offline.
- Se construyo `app-web` y se levanto en Docker para validar `http://localhost:8383`.
- `/auth/me` ahora entrega `qr_secret`/`qrSecret` dentro de `member_profile` para que la app genere QR con secreto emitido por backend.
- `AttendanceService` ya no acepta fallback TOTP derivado del DNI; si el socio no tiene `qr_secret`, deniega el acceso QR.
- Los socios creados desde flujo POS reciben `qr_secret` aleatorio.
- Se agregaron smoke tests moviles para validar que el login demo esta oculto por defecto y que QR renderiza con secreto backend.
- Se corrigio `backend/tsconfig.build.json` para que el build NestJS no compile `prisma/seed.ts`.

Verificacion ejecutada:

```powershell
cd mobile_app
flutter analyze
flutter test
cd ..
flutter analyze
flutter test
docker compose --env-file .env -f infra/docker/compose.local.yml build app-web
docker compose --env-file .env -f infra/docker/compose.local.yml up -d app-web
Invoke-WebRequest -Uri http://localhost:8383 -UseBasicParsing
npm run build
npm run test
```

Resultados:

- `flutter analyze`: sin issues.
- `flutter test`: todos los tests pasaron.
- `docker compose --env-file .env -f infra/docker/compose.local.yml build app-web`: paso; se emitio advertencia no bloqueante de compatibilidad futura WebAssembly en `socket_io_common`.
- `http://localhost:8383`: respondio `200 OK`.
- `npm run build` en backend: paso.
- `npm run test` en backend: 2 suites y 6 tests pasaron.

Pendientes moviles siguientes:

- Agregar pruebas widget especificas para que el panel demo no exista por defecto.
- Agregar pruebas para QR sin secreto y simulador habilitado solo por flag.
- Migrar caches Hive antiguos a cifrado en vez de usar fallback de desarrollo.
- Ejecutar build Android/iOS firmados con `APP_ENV=staging` y `APP_ENV=prod`.

## Entorno local disponible

El proyecto ya cuenta con Docker Compose local en `infra/docker/compose.local.yml`:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Servicios utiles para movil:

| Servicio | Contenedor | Uso | URL / Puerto |
|---|---|---|---|
| `api` | `sasgym_api_local` | Backend para integracion | `http://localhost:3000` |
| `app-web` | `sasgym_app_web_local` | Flutter web compilado | `http://localhost:8383` |
| `admin-web` | `sasgym_admin_web_local` | Mockups/docs de referencia | `http://localhost:8282` |

Comandos utiles:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml build app-web
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build app-web
docker compose --env-file .env -f infra/docker/compose.local.yml logs app-web
```

Nota: para validar integracion real de la app, tambien deben estar levantados `api`, `postgres` y `redis`.

## Builds moviles por ambiente

La app usa `--dart-define` para separar ambiente, API y modo demo:

```powershell
cd mobile_app
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
flutter build web --release --dart-define=APP_ENV=staging --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=https://api.<ip/dominio>/api/v1
flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1
flutter build apk --flavor prod --release --build-name 0.1.0 --build-number 1 --dart-define=APP_ENV=production --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=https://api.sas-gym.qpsecure.cloud/api/v1
```

Para movil/escritorio en modo backend, `API_BASE_URL` es obligatoria. No hay URL local implicita para evitar APKs que apunten por error a `localhost` o al emulador.

- Emulador Android: `http://10.0.2.2:3000/api/v1`.
- Celular fisico en la misma WiFi: `http://<IP_LAN_PC>:3000/api/v1`.
- Produccion: URL publica HTTPS.

Para `APP_ENV=production`, `API_BASE_URL` no puede usar `localhost`, `127.0.0.1` ni `10.0.2.2`.

Para release firmado se debe crear `mobile_app/android/key.properties` a partir de `mobile_app/android/key.properties.example`. No se debe commitear el keystore ni claves reales.

Flujo ADB recomendado para Redmi:

```powershell
C:\Users\yoset\AppData\Local\Android\Sdk\platform-tools\adb.exe devices -l
C:\Users\yoset\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r D:\proyectos\sas_gym\release\<fecha>_v0.1\sas-gym-v0.1.0-<fecha>.apk
```

Flavors Android:

- `dev`: `com.sasgym.app.dev`, etiqueta `SaaaS GYM Dev`.
- `staging`: `com.sasgym.app.staging`, etiqueta `SaaaS GYM Staging`.
- `prod`: `com.sasgym.app`, etiqueta `SaaaS GYM`.

## Meta movil

Convertir la app Flutter en una app segura, estable y lista para uso real por roles: miembro, entrenador, caja, administrador y superadministrador. La prioridad inicial es separar modo demo de modo productivo, cerrar riesgos de seguridad y estabilizar compilacion.

## Fase M0 - Estabilizacion tecnica

Objetivo: asegurar que la app compila y que los tests base pasan.

Tareas:

- Corregir el payload POS con sintaxis invalida en `mobile_app/lib/data/gym_state.dart`.
- Ejecutar:

```powershell
cd mobile_app
flutter analyze
flutter test
```

- Ejecutar CI por contenedor:

```powershell
flutter analyze
flutter test
```

- Revisar que `app-web` compile y sirva `http://localhost:8383`.
- Documentar errores reales encontrados durante analyze/test.

Criterio de salida:

- `flutter analyze` sin errores bloqueantes.
- `flutter test` pasa.
- `flutter analyze` y `flutter test` pasan.
- `http://localhost:8383` carga la app web.

## Fase M1 - Seguridad minima movil

Objetivo: evitar que mecanismos demo o secretos embebidos pasen a staging o produccion.

Tareas:

- Mover `API_BASE_URL` a `--dart-define`.
- Crear flags:
  - `ENABLE_DEMO_LOGIN`
  - `ENABLE_QR_SIMULATOR`
  - `APP_ENV`
- Desactivar credenciales demo por defecto.
- Remover generacion TOTP por DNI en modo productivo.
- Sanitizar logs de Dio, WebSocket y sync offline.
- Cifrar cajas Hive (`gym_cache`, `sync_queue_box`) con llave en secure storage.
- Definir limpieza de cache en logout.

Criterio de salida:

- Build productivo no muestra panel demo.
- API usa URL configurada por ambiente.
- No hay secretos TOTP derivados del DNI en produccion.
- Cache local sensible esta cifrada.

## Fase M2 - Integracion real por vertical

Objetivo: cerrar una vertical completa sin depender de datos mock.

Vertical recomendada:

1. Login real.
2. Tenant activo/suspendido.
3. Caja abre turno.
4. Caja registra venta/cobro.
5. Admin consulta auditoria y caja.
6. Miembro ve estado actualizado.

Uso de contenedores:

- Levantar `db` + `api`.
- Levantar `app-web`.
- Usar `test-client` para requests aislados si se requiere simular cliente externo.

Tareas:

- Separar explicitamente modo demo y modo backend.
- Limpiar datos semilla locales al iniciar sesion real.
- Mapear DTOs reales para caja, pagos, tenant y auditoria.
- Agregar feedback de errores consistente.
- Agregar pruebas widget/smoke para cada rol involucrado.

Criterio de salida:

- La vertical funciona contra la URL configurada en `API_BASE_URL`.
- No se mezclan datos demo con datos backend.
- Auditoria refleja operaciones reales.

## Fase M3 - Offline y rendimiento

Objetivo: que la app sea confiable en mala conectividad sin duplicar operaciones.

Tareas:

- Agregar `idempotencyKey` a transacciones offline.
- Definir max retries y expiracion por item de cola.
- Mostrar estado de sincronizacion al usuario.
- Evitar encolar operaciones financieras sin idempotencia.
- Reducir reconstrucciones por `notifyListeners()`.
- Encapsular timers en widgets pequenos.
- Validar tamanos de imagen antes de cargar bytes.

Criterio de salida:

- Rutinas offline se guardan y sincronizan sin duplicarse.
- Operaciones financieras offline tienen politica clara.
- Las pantallas con timers no causan reconstrucciones amplias.

## Fase M4 - Preparacion release movil

Objetivo: preparar Android/Web para distribucion.

Tareas:

- Definir `applicationId` real.
- Cambiar `android:label`.
- Configurar keystore release.
- Crear flavors dev/staging/prod.
- Revisar permisos Android.
- Generar build web release y APK/AAB release.

Criterio de salida:

- Build release firmado con keystore real.
- Configuracion por ambiente validada.
- App lista para QA externa.

## Pruebas usando contenedores locales

Flutter CI:

```powershell
flutter analyze
flutter test
```

Flutter web:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build app-web
```

Integracion con backend:

```powershell
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api app-web
```

Validaciones:

- Login renderiza.
- Roles cargan.
- Barrera SaaS aparece.
- Flujo caja basico.
- Flujo miembro QR/rutina.
- App web carga en `http://localhost:8383`.

## Entregables esperados

- App Flutter compila, analiza y prueba.
- Modo demo y modo backend quedan separados.
- Flujo caja/pagos/auditoria funciona en integracion local.
- Configuracion por ambiente lista.
- Build release movil preparado para QA.
