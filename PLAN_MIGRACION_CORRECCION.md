# Plan Detallado de Migración y Corrección Arquitectónica

> Proyecto: SAS GYM (`flutter_app` + `backend` NestJS)
> Objetivo: consolidar la arquitectura de Flutter y dejar una ruta de migración segura, validada en cada paso contra Flutter y contra el sistema backend, sin duplicar lógica ni mezclar capas.

---

## 0. Línea base y decisiones que sustituyen a versiones anteriores del plan

Esta versión corrige el plan original y se alinea con el estado real del repositorio y con [AVANCES_MIGRACION_FLUTTER.md](AVANCES_MIGRACION_FLUTTER.md).

### 0.1 Estado real al momento de planificar

- Existe una capa **shim** en [flutter_app/lib/features/](flutter_app/lib/features/) cuyos archivos son re-exports de 43–48 bytes que apuntan a [flutter_app/lib/screens/](flutter_app/lib/screens/). La estructura `features/` está cableada en [app.dart](flutter_app/lib/app.dart), pero el código real (admin 119 KB, member 92 KB, cashier 70 KB, trainer 56 KB) sigue en `screens/`.
- La carpeta intermedia es `features/roles/` (no `features/member/`, `features/trainer/`, etc.), por lo que la migración debe **renombrar y mover**, no sólo mover.
- Estado global concentrado en un único `ChangeNotifier`: [data/gym_state.dart](flutter_app/lib/data/gym_state.dart) (consumido por todas las pantallas vía `GymStateProvider`).
- Widgets reutilizables con dominio mezclado en [widgets/shared_widgets.dart](flutter_app/lib/widgets/shared_widgets.dart) (`QRPattern`, `TimerRing`, `GymSuspendedBarrier`, `PushDisabledBanner`).
- Sólo existe un test simbólico en [flutter_app/test/widget_test.dart](flutter_app/test/widget_test.dart). Sin red de seguridad real.
- Backend NestJS operativo con módulos `auth`, `members`, `attendance`, `payments`, `routines`, `observations`, `tenants`, `reports`, `schedules`, `announcements` (ver [backend/src/modules/](backend/src/modules/)).

### 0.2 Decisiones arquitectónicas fijadas para este plan

Para evitar el conflicto entre este documento y [AVANCES_MIGRACION_FLUTTER.md](AVANCES_MIGRACION_FLUTTER.md), se definen las siguientes reglas firmes:

1. **Árbol elegido:** `feature-first plano`, no Clean Architecture completa por feature.
   - Estructura por feature: `features/<feature>/{screens,widgets,state}/` (las dos últimas, opcionales).
   - Clean Architecture (`domain/data/presentation/`) queda como **evolución futura**, no es alcance de esta migración.
2. **Modelos:** `lib/models/` se conserva como espacio compartido para DTOs y enums alineados con el backend. No se duplican modelos por feature.
3. **Estado:** se conserva `GymState` global por compatibilidad. Su partición por feature queda registrada como **deuda técnica** para una iteración posterior; no es alcance de este plan.
4. **Shim actual:** los re-exports en `features/roles/*` se eliminan al finalizar la migración. No quedan como capa permanente.
5. **Naming:** se elimina la subcarpeta `roles/`. Cada rol o dominio cuelga directamente de `features/`. Se permite mezclar dominios (`auth`, `payments`) y roles (`member`, `cashier`) en el mismo nivel; esto es intencional y se documenta en la sección 2.
6. **Red de seguridad:** cada fase agrega o ejecuta tests; `flutter analyze` por sí solo **no** es criterio de aceptación.
7. **Commits:** una fase = uno o más commits revertibles. Cada fase debe poder revertirse con `git revert` sin tocar las anteriores.

---

## 1. Resultados esperados al cierre del plan

- Estructura de carpetas clara, sin shims residuales.
- `main.dart` y `app.dart` con responsabilidades estrictamente separadas.
- Todo el código de UI vive en `features/`; `widgets/` sólo agrupa UI agnóstica de dominio.
- `core/` sin dependencias de UI; `models/` sin dependencias de Flutter más allá de Dart puro.
- Suite mínima de tests de humo por rol que se ejecuta en CI local.
- Backend sin regresiones: build, lint, contenedores y endpoints críticos validados al cierre de cada fase relevante.

---

## 2. Arquitectura objetivo

### 2.1 Capas

- [lib/main.dart](flutter_app/lib/main.dart): bootstrap (Hive, providers raíz, `runApp`).
- [lib/app.dart](flutter_app/lib/app.dart): composición, auth gate, ruteo por rol, barrera SaaS.
- `lib/core/`: red, almacenamiento, websockets, utilidades técnicas globales.
- `lib/data/`: estado compartido, seeds, repositorios de memoria.
- `lib/models/`: modelos puros, enums, DTOs alineados con backend.
- `lib/theme/`: tokens visuales, paletas por rol.
- `lib/widgets/`: UI reutilizable y agnóstica de dominio.
- `lib/features/`: pantallas y flujos por dominio o rol.

### 2.2 Features previstos

```
features/
  auth/         # login, recuperación, gate de sesión
  member/       # home, agenda, QR, membresía, perfil
  trainer/      # alumnos, biblioteca, rutinas, progreso
  cashier/      # POS, escáner, turnos
  admin/        # dashboard, usuarios, caja, auditoría, settings
  superadmin/   # panel SaaS global
```

Mezclar dominios (`auth`) con roles (`member`, `cashier`, ...) es intencional: simplifica el ruteo en `app.dart` sin forzar una capa de dominio adicional.

### 2.3 Reglas de dependencia

- `features/` → puede usar `core/`, `data/`, `models/`, `theme/`, `widgets/`.
- `widgets/` → no depende de ninguna feature.
- `core/` → no importa pantallas ni widgets.
- `models/` → no importa nada de Flutter UI (solo `dart:core`, `package:flutter/foundation.dart` si hace falta `ChangeNotifier`).

---

## 3. Estrategia de validación por fase

Toda fase tiene **dos pistas de validación**: Flutter y Sistema. Una fase no se da por cerrada si ambas pistas no aprueban.

### 3.1 Validación Flutter (común a todas las fases)

Comandos base:

```powershell
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

Criterio común:

- `flutter analyze` → `No issues found!`.
- `flutter test` → 0 fallos. La cantidad de tests crece según la fase.
- La app arranca sin excepciones en consola (`flutter run -d windows` o `flutter run -d chrome`).

### 3.2 Validación Sistema / Backend (común a todas las fases)

Comandos base:

```powershell
cd backend
npm run build
docker compose up -d
docker compose ps
```

Criterio común:

- `npm run build` termina sin errores TypeScript.
- Contenedores `backend-api` y `backend-db` en estado `Up`.
- `GET /api/v1/health` (o el endpoint disponible más cercano) responde `200 OK`.
- `POST /api/v1/auth/login` con seed credentials responde `200 OK` y devuelve `token`.

### 3.3 Reglas de commit y rollback

- Cada fase produce **uno o más commits atómicos** con prefijo `chore(arch-migration):` o `refactor(arch-migration):`.
- Antes de pasar a la fase siguiente, se verifica que `git revert <commit>` no produce conflictos en seco (`git revert --no-commit <commit> && git revert --abort`).
- Si la fase requiere mover archivos, usar `git mv` (no copiar/borrar) para preservar historial.

---

## 4. Fases

### Fase 0 — Diagnóstico explícito y red de seguridad inicial

**Objetivo:** dejar evidencia escrita del estado real antes de mover nada y crear un mínimo de tests de humo para detectar regresiones en fases posteriores.

**Pre-condiciones:**

- `git status` limpio o con cambios en un branch independiente.
- Backend levantado en local (ver 3.2) para validar que los smoke tests pueden golpear endpoints reales si hace falta.

**Tareas:**

1. Crear archivo `flutter_app/MIGRATION_INVENTORY.md` con:
   - Lista de archivos en `lib/screens/` y tamaño.
   - Lista de archivos en `lib/features/` y su rol actual (shim / real).
   - Mapa de imports cruzados entre `widgets/shared_widgets.dart` y `screens/*`.
2. Anotar en el mismo archivo todo widget de `shared_widgets.dart` con dominio (`QRPattern`, `TimerRing`, `GymSuspendedBarrier`, `PushDisabledBanner`) y su feature destino tentativa.
3. Crear suite mínima de tests de humo en `flutter_app/test/smoke/`:
   - `app_boot_test.dart`: arranca `SasGymApp` y verifica que renderiza pantalla de login.
   - `role_routing_test.dart`: inyecta `GymState` con usuario por cada rol y verifica que la pantalla esperada se monta sin excepción.

**Validación Flutter:**

```powershell
cd flutter_app
flutter analyze
flutter test test/smoke/
```

Criterio: ambos smoke tests verdes.

**Validación Sistema:**

```powershell
cd backend
npm run build
docker compose up -d
docker compose ps
```

Criterio: contenedores `Up`, `npm run build` limpio.

**Criterio de salida:**

- Existe `MIGRATION_INVENTORY.md` con los tres listados.
- Existen 2 smoke tests verdes en `test/smoke/`.
- Backend compila y corre.

**Commit:** `chore(arch-migration): fase 0 - inventario y smoke tests`

**Rollback:** revertir el commit; no se ha tocado código de producción.

---

### Fase 1 — Limpieza del punto de entrada

**Objetivo:** dejar `main.dart` minimalista y `app.dart` como única autoridad sobre rutas, auth gate y barrera SaaS.

**Pre-condiciones:** Fase 0 cerrada.

**Tareas:**

1. Verificar que [main.dart](flutter_app/lib/main.dart) no conoce pantallas concretas (hoy ya cumple). Documentar en comentario por qué.
2. Asegurar que [app.dart](flutter_app/lib/app.dart) es el único que importa pantallas de rol.
3. Extraer `_TopBar` y `_RoleScreenHost` de `app.dart` a archivos propios en `lib/widgets/app_shell.dart` o `lib/core/shell/` si pesan más de lo razonable; si no, dejarlos privados.
4. Documentar el orden de gate en `app.dart`: `authLoading → login → SaaS barrier → role host`.

**Validación Flutter:**

```powershell
cd flutter_app
flutter analyze
flutter test
flutter run -d windows  # o chrome — verificación manual de arranque
```

Criterio:

- Smoke tests siguen verdes.
- App arranca, muestra login si no hay sesión, navega a home por rol con seed credentials.

**Validación Sistema:**

```powershell
cd backend
docker compose ps
curl -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"admin@gymsmart.com","password":"<seed>"}'
```

Criterio: login responde `200 OK` con token y `tenantId`.

**Criterio de salida:**

- `main.dart` no importa ninguna pantalla.
- `app.dart` concentra la lógica de gate.
- Smoke tests verdes.

**Commit:** `refactor(arch-migration): fase 1 - aislar punto de entrada`

**Rollback:** `git revert` del commit. No hay efectos en backend.

---

### Fase 2 — Migración real de pantallas a `features/`

**Objetivo:** mover el código real desde `lib/screens/` a `lib/features/<feature>/screens/` y eliminar la indirección por shims.

**Pre-condiciones:** Fase 1 cerrada.

**Tareas (en este orden, un sub-commit por feature):**

1. `features/auth/screens/login_screen.dart` ← `git mv lib/screens/login_screen.dart`.
2. `features/member/screens/member_screen.dart` ← `git mv lib/screens/member_screen.dart`.
3. `features/trainer/screens/trainer_screen.dart` ← `git mv lib/screens/trainer_screen.dart`.
4. `features/cashier/screens/cashier_screen.dart` ← `git mv lib/screens/cashier_screen.dart`.
5. `features/admin/screens/admin_screen.dart` ← `git mv lib/screens/admin_screen.dart`.
6. `features/superadmin/screens/superadmin_screen.dart` ← `git mv lib/screens/superadmin_screen.dart`.

Después de cada movimiento:

- Borrar el shim correspondiente en `features/roles/` o `features/auth/`.
- Actualizar imports en `app.dart` y en el resto del árbol.
- Ajustar imports relativos internos del archivo movido.

Al final de la fase:

- Eliminar carpeta `lib/screens/` (debe quedar vacía).
- Eliminar carpeta `lib/features/roles/` (debe quedar vacía).

**Validación Flutter (después de cada sub-commit):**

```powershell
cd flutter_app
flutter analyze
flutter test test/smoke/
```

Criterio: ambos en verde tras cada sub-commit. Si un sub-commit rompe smoke tests, no continuar al siguiente rol hasta corregir.

**Validación Sistema:**

Sin cambios respecto a Fase 1 (este movimiento es 100% frontend). Mantener `docker compose ps` con contenedores `Up` para validar manualmente login + 1 acción por rol al cierre de la fase.

Criterio adicional manual:

- Login como `member` muestra QR.
- Login como `admin` muestra dashboard.
- Login como `cashier` permite abrir turno (o muestra error de turno si está fuera de horario — comportamiento esperado).

**Criterio de salida:**

- `lib/screens/` y `lib/features/roles/` eliminadas.
- Smoke tests verdes.
- App ejercitada manualmente por rol.

**Commits:** un commit por feature, prefijo `refactor(arch-migration): fase 2 - mover <feature> a features/<feature>/`.

**Rollback:** revertir commits en orden inverso al movimiento.

---

### Fase 3 — Reubicación de widgets con dominio

**Objetivo:** dejar `lib/widgets/` sólo con componentes agnósticos. Mover los widgets con conocimiento de dominio a la feature correspondiente.

**Pre-condiciones:** Fase 2 cerrada.

**Tareas:**

1. Para cada widget en [widgets/shared_widgets.dart](flutter_app/lib/widgets/shared_widgets.dart), aplicar el mapeo decidido en Fase 0:
   - `QRPattern`, `TimerRing` → `features/member/widgets/`.
   - `GymSuspendedBarrier` → `lib/core/saas/` (lo usa `app.dart`, transversal).
   - `PushDisabledBanner` → `features/member/widgets/`.
   - Cualquier widget genuinamente reutilizable (`StatusPill`, `MetricTile`, `ActionTile`, `LogTile`, `SectionHeader`, `RoleNavBar`, `RoleSurface`, `RoleTabs`) **se conserva** en `widgets/`.
2. Partir `widgets/shared_widgets.dart` en archivos por widget si pasa los 500 LOC tras la limpieza.
3. Actualizar imports en cada feature.

**Validación Flutter:**

```powershell
cd flutter_app
flutter analyze
flutter test
```

Criterio:

- Sin imports rotos.
- Sin warnings de imports sin uso (`unused_import`).
- Smoke tests siguen verdes.
- Agregar 1 widget test por widget movido (verifica que monta sin error con datos mínimos).

**Validación Sistema:**

Sin cambios. Backend debe seguir `Up`. Validación adicional manual: la pantalla del socio sigue mostrando el QR con rotación TOTP (verificable porque [features/member/](flutter_app/lib/features/member/) consume el endpoint `/members/qr-code`).

```powershell
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/members/qr-code
```

Criterio: responde `qrSecret` e `intervalSeconds`.

**Criterio de salida:**

- `widgets/` libre de lógica de dominio.
- Widgets movidos con su test de humo.

**Commit:** `refactor(arch-migration): fase 3 - reubicar widgets con dominio`

**Rollback:** `git revert` del commit; las features siguen funcionando porque los archivos estaban consolidados.

---

### Fase 4 — Consolidación de estado, modelos y `core/`

**Objetivo:** verificar fronteras entre `data/`, `models/` y `core/` sin partir el `GymState` global (eso es deuda técnica fuera de alcance).

**Pre-condiciones:** Fase 3 cerrada.

**Tareas:**

1. Auditar [data/gym_state.dart](flutter_app/lib/data/gym_state.dart): confirmar que no importa nada de `features/`. Si lo hace, romper la dependencia.
2. Auditar [data/gym_seed.dart](flutter_app/lib/data/gym_seed.dart): debe contener sólo datos semilla, sin lógica reactiva.
3. Auditar [models/gym_models.dart](flutter_app/lib/models/gym_models.dart): debe ser Dart puro (sin `package:flutter/material.dart`). Si necesita `ChangeNotifier`, usar `package:flutter/foundation.dart`.
4. Confirmar que [core/network/api_client.dart](flutter_app/lib/core/network/api_client.dart) y [core/storage/secure_storage.dart](flutter_app/lib/core/storage/secure_storage.dart) no importan pantallas ni widgets.
5. Anotar `TODO(arch-future)` en `GymState` indicando dónde se partiría por feature en una iteración posterior.

**Validación Flutter:**

```powershell
cd flutter_app
flutter analyze
flutter test
```

Análisis adicional de dependencias (manual, grep):

```powershell
cd flutter_app/lib
Select-String -Path "core\**\*.dart","models\**\*.dart" -Pattern "package:flutter/material" -SimpleMatch
Select-String -Path "data\**\*.dart" -Pattern "import '../features" -SimpleMatch
```

Criterio: ambos `Select-String` devuelven **sin resultados**.

**Validación Sistema:**

```powershell
cd backend
npm run build
docker compose ps
curl http://localhost:3000/api/v1/auth/me -H "Authorization: Bearer <token>"
```

Criterio:

- Build limpio.
- `/auth/me` (o equivalente) responde el perfil. Si el endpoint no existe, validar con `POST /auth/login` que el `LoggedInUser` deserializa correctamente.

**Criterio de salida:**

- Reglas de dependencia de la sección 2.3 verificadas con grep.
- `GymState` marcado con TODO de deuda.

**Commit:** `refactor(arch-migration): fase 4 - consolidar fronteras de core/data/models`

**Rollback:** revertir commit; cambios son anotaciones y ajustes de import.

---

### Fase 5 — Verificación de imports, dependencias y exports

**Objetivo:** eliminar imports redundantes, circulares o apuntando a paths obsoletos.

**Pre-condiciones:** Fase 4 cerrada.

**Tareas:**

1. Crear archivo `lib/features/<feature>/<feature>.dart` por cada feature, re-exportando sólo lo público (pantalla principal y widgets reutilizables externamente).
2. Actualizar `app.dart` para que importe `package:flutter_app/features/<feature>/<feature>.dart` en vez del archivo profundo.
3. Verificar ausencia de imports circulares.
4. Verificar que no quedan referencias a `lib/screens/` o `lib/features/roles/`.

**Validación Flutter:**

```powershell
cd flutter_app
flutter analyze
flutter test
flutter pub deps --no-dev --style=compact
```

Búsquedas obligatorias:

```powershell
Select-String -Path "lib\**\*.dart" -Pattern "screens/" -SimpleMatch
Select-String -Path "lib\**\*.dart" -Pattern "features/roles/" -SimpleMatch
```

Criterio: cero resultados en ambas búsquedas.

**Validación Sistema:**

Sin cambios respecto a fases previas. Repetir validación común (build + contenedores `Up` + login `200`).

**Criterio de salida:**

- Cada feature expone un único punto de entrada.
- Búsquedas confirman cero referencias a paths antiguos.

**Commit:** `refactor(arch-migration): fase 5 - normalizar imports y exports por feature`

**Rollback:** `git revert`; los archivos siguen donde la Fase 2 los dejó.

---

### Fase 6 — Validación funcional integral

**Objetivo:** confirmar que la migración no rompió el comportamiento extremo a extremo.

**Pre-condiciones:** Fase 5 cerrada.

**Tareas:**

1. Ampliar `test/smoke/` con un test por flujo crítico:
   - `login_logout_test.dart`: login con cada rol, logout, vuelta a pantalla de login.
   - `member_qr_test.dart`: usuario miembro carga QR y se ve `TimerRing`.
   - `cashier_pos_test.dart`: pantalla POS monta sin error.
   - `admin_dashboard_test.dart`: pantalla admin monta sin error con seed.
   - `saas_barrier_test.dart`: con `isCurrentGymActive=false` la barrera SaaS aparece.
2. Documentar resultados en `flutter_app/MIGRATION_VALIDATION.md` con fecha y comandos ejecutados.

**Validación Flutter:**

```powershell
cd flutter_app
flutter analyze
flutter test
flutter test --coverage
flutter run -d windows  # smoke manual final
```

Criterio:

- 0 fallos en suite completa.
- Cobertura de los archivos en `features/*/screens/` ≥ 30 % (umbral mínimo, ajustable).
- App arranca y permite navegar por los 5 roles con seed credentials.

**Validación Sistema:**

Ejecutar el set completo de endpoints críticos:

```powershell
cd backend
docker compose ps

# Login
curl -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"admin@gymsmart.com","password":"<seed>"}'

# QR seed (member)
curl -H "Authorization: Bearer <member_token>" -H "X-Tenant-ID: <tenant>" http://localhost:3000/api/v1/members/qr-code

# Verify attendance (admin/cashier)
curl -X POST http://localhost:3000/api/v1/attendance/verify -H "Authorization: Bearer <admin_token>" -H "X-Tenant-ID: <tenant>" -H "Content-Type: application/json" -d '{"dni":"12345678","otpToken":"<token>"}'

# Pending payments (admin)
curl -H "Authorization: Bearer <admin_token>" -H "X-Tenant-ID: <tenant>" http://localhost:3000/api/v1/admin/pending-payments
```

Criterio: los 4 endpoints responden el shape documentado en [AVANCES_MIGRACION_FLUTTER.md](AVANCES_MIGRACION_FLUTTER.md) sección 2.

**Criterio de salida:**

- Suite de smoke tests completa.
- Documento `MIGRATION_VALIDATION.md` con evidencia.

**Commit:** `test(arch-migration): fase 6 - suite de smoke completa por flujo`

**Rollback:** revertir el commit elimina tests pero no compromete la app.

---

## 5. Orden de ejecución resumido

| Fase | Alcance | Riesgo | Tiempo estimado |
|------|---------|--------|-----------------|
| 0    | Inventario + smoke tests base | Bajo | 0.5 día |
| 1    | Limpieza de `main.dart` y `app.dart` | Bajo | 0.5 día |
| 2    | Migración real de pantallas a `features/` | **Alto** | 1.5 día |
| 3    | Reubicación de widgets con dominio | Medio | 1 día |
| 4    | Auditoría de `core/data/models` | Bajo | 0.5 día |
| 5    | Imports, exports y barrels | Bajo | 0.5 día |
| 6    | Suite de validación + smoke manual | Bajo | 1 día |

Total: ~5.5 días de trabajo enfocado.

---

## 6. Riesgos y controles

| Riesgo | Control |
|--------|---------|
| Romper imports al mover archivos | `git mv` + smoke tests entre sub-commits |
| Olvidar borrar shims tras migrar | Búsqueda forzosa en Fase 5: cero resultados de `screens/` o `features/roles/` |
| Widgets de dominio quedan en `widgets/` | Mapeo cerrado en Fase 0 + revisión en Fase 3 |
| Backend deja de compilar por cambio accidental | Validación sistema en cada fase incluye `npm run build` |
| `GymState` global crece descontrolado | TODO marcado en Fase 4; partir queda fuera de alcance |
| Sin tests = regresiones invisibles | Suite mínima creada en Fase 0, ampliada hasta Fase 6 |

---

## 7. Criterios de aceptación final

La migración se considera correcta cuando, de forma simultánea:

- [lib/screens/](flutter_app/lib/screens/) y `lib/features/roles/` no existen.
- Cada rol vive en `features/<rol>/screens/` con su propio export barril.
- `widgets/` no contiene lógica específica de un rol.
- `flutter analyze` y `flutter test` verdes.
- Backend compila, contenedores levantan, login y endpoints críticos siguen respondiendo el contrato documentado.
- Existe `MIGRATION_VALIDATION.md` con evidencia de comandos y fechas.

---

## 8. Fuera de alcance (deuda técnica registrada)

Para no agrandar el plan más allá de su objetivo, queda explícitamente fuera de esta migración:

- Partir `GymState` en providers por feature (Riverpod / Bloc / múltiples ChangeNotifier).
- Introducir Clean Architecture completa (`domain/data/presentation/`) por feature.
- Migrar lógica de red de Dio crudo a un repositorio formal por feature.
- Internacionalización (`l10n/`).
- Integración real de WebSockets en cliente (hoy el servicio está planeado en AVANCES pero no integrado en UI).

Estos puntos deben planificarse como iteraciones independientes una vez cerrada esta migración.
