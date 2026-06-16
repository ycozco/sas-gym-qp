# Prueba SyncQueue Offline desde Móvil - 2026-06-16

## Objetivo

Validar que el flujo móvil de registro de entrenamiento no use una cola legacy separada, sino `SyncQueueService` sobre `sync_queue_box`, conservando una llave de idempotencia para reintentar sin duplicar registros cuando vuelva la conexión.

## Alcance

- Aplicación Flutter `mobile_app`.
- Flujo de sesión de entrenamiento offline.
- Cola Hive `sync_queue_box`.
- Reintento con cabecera `X-Idempotency-Key`.
- APK dev/local instalado en celular físico conectado por USB.

## Implementación revisada

- `GymState.saveWorkoutSession` ahora adjunta `idempotencyKey`, envía la cabecera cuando hay red y encola en `SyncQueueService` cuando no hay conexión o falla el servidor.
- `ActiveRoutineNotifier.saveWorkoutSession` usa el mismo flujo de SyncQueue para la ruta móvil de rutinas.
- `syncOfflineLogs` migra entradas antiguas de `offline_workout_queue` hacia `sync_queue_box` antes de procesar pendientes.
- Al recuperar conexión, `GymState` procesa la cola una sola vez desde `syncOfflineLogs` para evitar reenvíos concurrentes.

## Casos ejecutados

| ID | Caso | Resultado esperado | Resultado |
| --- | --- | --- | --- |
| SYNC-001 | Guardar sesión de entrenamiento sin conexión desde el flujo móvil | Se guarda una entrada en `sync_queue_box` con endpoint `/members/workout-log` | PASÓ |
| SYNC-002 | Verificar llave de idempotencia | La cola conserva `workout-<sessionId>` y lo incluye en el payload | PASÓ |
| SYNC-003 | Procesar cola al recuperar conexión | `processQueue` envía la llave de idempotencia y limpia la cola si el envío fue exitoso | PASÓ |
| SYNC-004 | Instalar y ejecutar APK actualizado en celular físico | El APK dev/local arranca con los últimos cambios | PASÓ |

## Evidencia automatizada

Comando:

```bash
flutter test test/smoke/sync_queue_service_test.dart
```

Resultado esperado:

- La prueba `mobile workout offline path enqueues into SyncQueue with idempotency` debe pasar.
- No debe quedar pendiente en `sync_queue_box` después de un `processQueue` exitoso.

Resultado obtenido:

- `flutter test test/smoke/sync_queue_service_test.dart`: 5 pruebas pasaron.
- `flutter analyze`: sin errores de compilación; quedan 29 advertencias preexistentes fuera del flujo SyncQueue.

## Evidencia en celular físico

- Dispositivo ADB: `RRCXA08XX8E`.
- APK generado: `mobile_app/build/app/outputs/flutter-apk/app-dev-release.apk`.
- Copia local: `release/2026-06-16_v0.1/sas-gym-v0.1.0-2026-06-16-local.apk`.
- Paquete: `com.sasgym.app.dev`.
- Versión instalada: `versionName=0.1.0`, `versionCode=6`.
- Fecha de actualización reportada por Android: `2026-06-16 12:08:57`.
- Arranque validado con `adb shell am start -n com.sasgym.app.dev/com.sasgym.app.MainActivity`.

## Flujo de validación manual en celular

1. Confirmar que Docker local esté levantado y que el celular esté en la misma red que la computadora.
2. Abrir `SaaaS GYM Dev` en el celular.
3. Iniciar sesión con un socio activo que tenga rutina asignada.
4. Activar modo avión o desconectar Wi-Fi/datos.
5. Entrar al flujo de rutina/entrenamiento y guardar una sesión o log de esfuerzo.
6. Confirmar que la app no muestre pantalla roja ni se cierre.
7. Desactivar modo avión y recuperar conexión.
8. Reabrir o refrescar el flujo de entrenamiento para permitir el procesamiento de la cola.
9. Verificar que el registro se sincronice una sola vez y que no haya duplicidad en backend.

## Criterio de aceptación

La operación offline debe quedar en `sync_queue_box` con idempotencia, debe poder reenviarse al recuperar red y no debe generar duplicados si el usuario repite la acción o si la red falla durante el primer intento.

## Riesgos pendientes

- La validación manual completa depende de que el usuario de prueba tenga una rutina activa asignada.
- Si el backend no tiene idempotencia persistente para `/members/workout-log`, el cliente ya envía la llave, pero debe confirmarse la deduplicación final en servidor.
