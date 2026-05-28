# Plan Detallado de MigraciÃ³n y CorrecciÃ³n ArquitectÃ³nica

> Proyecto: SAS GYM (`mobile_app` + `backend` NestJS)
> Objetivo: consolidar la arquitectura de Flutter y dejar una ruta de migraciÃ³n segura, validada en cada paso contra Flutter y contra el sistema backend, sin duplicar lÃ³gica ni mezclar capas.

---

## 0. LÃ­nea base y decisiones que sustituyen a versiones anteriores del plan

Esta versiÃ³n corrige el plan original y se alinea con el estado real del repositorio y con [AVANCES_MIGRACION_FLUTTER.md](AVANCES_MIGRACION_FLUTTER.md).

### 0.1 Estado real al momento de planificar

- Existe una capa **shim** en [mobile_app/lib/features/](mobile_app/lib/features/) cuyos archivos son re-exports de 43â€“48 bytes que apuntan a [mobile_app/lib/screens/](mobile_app/lib/screens/). La estructura `features/` estÃ¡ cableada en [app.dart](mobile_app/lib/app.dart), pero el cÃ³digo real (admin 119 KB, member 92 KB, cashier 70 KB, trainer 56 KB) sigue en `screens/`.
- La carpeta intermedia es `features/roles/` (no `features/member/`, `features/trainer/`, etc.), por lo que la migraciÃ³n debe **renombrar y mover**, no sÃ³lo mover.
- Estado global concentrado en un Ãºnico `ChangeNotifier`: [data/gym_state.dart](mobile_app/lib/data/gym_state.dart) (consumido por todas las pantallas vÃ­a `GymStateProvider`).
- Widgets reutilizables con dominio mezclado en [widgets/shared_widgets.dart](mobile_app/lib/widgets/shared_widgets.dart) (`QRPattern`, `TimerRing`, `GymSuspendedBarrier`, `PushDisabledBanner`).
- SÃ³lo existe un test simbÃ³lico en [mobile_app/test/widget_test.dart](mobile_app/test/widget_test.dart). Sin red de seguridad real.
- Backend NestJS operativo con mÃ³dulos `auth`, `members`, `attendance`, `payments`, `routines`, `observations`, `tenants`, `reports`, `schedules`, `announcements` (ver [backend/src/modules/](backend/src/modules/)).

### 0.2 Decisiones arquitectÃ³nicas fijadas para este plan

Para evitar el conflicto entre este documento y [AVANCES_MIGRACION_FLUTTER.md](AVANCES_MIGRACION_FLUTTER.md), se definen las siguientes reglas firmes:

1. **Ãrbol elegido:** `feature-first plano`, no Clean Architecture completa por feature.
   - Estructura por feature: `features/<feature>/{screens,widgets,state}/` (las dos Ãºltimas, opcionales).
   - Clean Architecture (`domain/data/presentation/`) queda como **evoluciÃ³n futura**, no es alcance de esta migraciÃ³n.
2. **Modelos:** `lib/models/` se conserva como espacio compartido para DTOs y enums alineados con el backend. No se duplican modelos por feature.
3. **Estado:** se conserva `GymState` global por compatibilidad. Su particiÃ³n por feature queda registrada como **deuda tÃ©cnica** para una iteraciÃ³n posterior; no es alcance de este plan.
4. **Shim actual:** los re-exports en `features/roles/*` se eliminan al finalizar la migraciÃ³n. No quedan como capa permanente.
5. **Naming:** se elimina la subcarpeta `roles/`. Cada rol o dominio cuelga directamente de `features/`. Se permite mezclar dominios (`auth`, `payments`) y roles (`member`, `cashier`) en el mismo nivel; esto es intencional y se documenta en la secciÃ³n 2.
6. **Red de seguridad:** cada fase agrega o ejecuta tests; `flutter analyze` por sÃ­ solo **no** es criterio de aceptaciÃ³n.
7. **Commits:** una fase = uno o mÃ¡s commits revertibles. Cada fase debe poder revertirse con `git revert` sin tocar las anteriores.

---

## 1. Resultados esperados al cierre del plan

- Estructura de carpetas clara, sin shims residuales.
- `main.dart` y `app.dart` con responsabilidades estrictamente separadas.
- Todo el cÃ³digo de UI vive en `features/`; `widgets/` sÃ³lo agrupa UI agnÃ³stica de dominio.
- `core/` sin dependencias de UI; `models/` sin dependencias de Flutter mÃ¡s allÃ¡ de Dart puro.
- Suite mÃ­nima de tests de humo por rol que se ejecuta en CI local.
- Backend sin regresiones: build, lint, contenedores y endpoints crÃ­ticos validados al cierre de cada fase relevante.

---

## 2. Arquitectura objetivo

### 2.1 Capas

- [lib/main.dart](mobile_app/lib/main.dart): bootstrap (Hive, providers raÃ­z, `runApp`).
- [lib/app.dart](mobile_app/lib/app.dart): composiciÃ³n, auth gate, ruteo por rol, barrera SaaS.
- `lib/core/`: red, almacenamiento, websockets, utilidades tÃ©cnicas globales.
- `lib/data/`: estado compartido, seeds, repositorios de memoria.
- `lib/models/`: modelos puros, enums, DTOs alineados con backend.
- `lib/theme/`: tokens visuales, paletas por rol.
- `lib/widgets/`: UI reutilizable y agnÃ³stica de dominio.
- `lib/features/`: pantallas y flujos por dominio o rol.

### 2.2 Features previstos

```
features/
  auth/         # login, recuperaciÃ³n, gate de sesiÃ³n
  member/       # home, agenda, QR, membresÃ­a, perfil
  trainer/      # alumnos, biblioteca, rutinas, progreso
  cashier/      # POS, escÃ¡ner, turnos
  admin/        # dashboard, usuarios, caja, auditorÃ­a, settings
  superadmin/   # panel SaaS global
```

Mezclar dominios (`auth`) con roles (`member`, `cashier`, ...) es intencional: simplifica el ruteo en `app.dart` sin forzar una capa de dominio adicional.

### 2.3 Reglas de dependencia

- `features/` â†’ puede usar `core/`, `data/`, `models/`, `theme/`, `widgets/`.
- `widgets/` â†’ no depende de ninguna feature.
- `core/` â†’ no importa pantallas ni widgets.
- `models/` â†’ no importa nada de Flutter UI (solo `dart:core`, `package:flutter/foundation.dart` si hace falta `ChangeNotifier`).

---

## 3. Estrategia de validaciÃ³n por fase (contenerizada)

Toda fase tiene **dos pistas de validaciÃ³n**, ambas ejecutadas dentro de contenedores Docker. Una fase no se da por cerrada si ambas pistas no aprueban.

> Pre-requisitos garantizados al cierre del commit `fee4507`:
> - `docker compose build api` produce imagen limpia (cliente Prisma regenerado).
> - `docker compose --profile ci build flutter-ci` ejecuta `flutter analyze` + `flutter test` dentro del contenedor y termina en exit code 0.
> - `docker compose build frontend-web` produce la imagen de release Flutter web sobre nginx.

### 3.1 ValidaciÃ³n Flutter (contenedor `flutter-ci`)

Comando Ãºnico:

```powershell
docker compose --profile ci build flutter-ci
```

El build de la imagen falla si `flutter analyze` o `flutter test` no pasan. No se ejecuta nada en el host.

Criterio comÃºn:

- `analyze` â†’ `No issues found!` dentro del contenedor.
- `test` â†’ 0 fallos. La cantidad de tests crece por fase.
- Imagen `sas_gym_flutter_ci:latest` queda construida.

Para correr los tests sin reconstruir desde cero (cuando se quiere ver el output suelto):

```powershell
docker compose run --rm --build flutter-ci flutter test
```

### 3.2 ValidaciÃ³n Sistema / Backend (contenedor `api`)

Comandos:

```powershell
docker compose build api
docker compose up -d db api
docker compose ps
```

Criterio comÃºn:

- `docker compose build api` termina sin errores TS (el `Dockerfile` corre `nest build` dentro).
- `db` (`gymsmart-postgres`) y `api` (`gymsmart-api`) ambos en estado `Up` / `healthy`.
- `POST /api/v1/auth/login` con credenciales seed responde `200 OK` y devuelve `token`.

ValidaciÃ³n funcional desde **otro contenedor** (cumple la directiva "todo contenerizado"):

```powershell
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@gymsmart.com',password:'<seed>'})}).then(r=>console.log(r.status))"
```

Resultado esperado: `200`.

Para apagar entre fases sin perder datos:

```powershell
docker compose down
```

### 3.3 Reglas de commit y rollback

- Cada fase produce **uno o mÃ¡s commits atÃ³micos** con prefijo `chore(arch-migration):` o `refactor(arch-migration):`.
- Antes de pasar a la fase siguiente, se verifica que `git revert <commit>` no produce conflictos en seco (`git revert --no-commit <commit> && git revert --abort`).
- Si la fase requiere mover archivos, usar `git mv` (no copiar/borrar) para preservar historial.

---

## 4. Fases

### Fase 0 â€” DiagnÃ³stico explÃ­cito y red de seguridad inicial

**Objetivo:** dejar evidencia escrita del estado real antes de mover nada y crear un mÃ­nimo de tests de humo para detectar regresiones en fases posteriores.

**Pre-condiciones:**

- `git status` limpio o con cambios en un branch independiente.
- Backend levantado en local (ver 3.2) para validar que los smoke tests pueden golpear endpoints reales si hace falta.

**Tareas:**

1. Crear archivo `mobile_app/MIGRATION_INVENTORY.md` con:
   - Lista de archivos en `lib/screens/` y tamaÃ±o.
   - Lista de archivos en `lib/features/` y su rol actual (shim / real).
   - Mapa de imports cruzados entre `widgets/shared_widgets.dart` y `screens/*`.
2. Anotar en el mismo archivo todo widget de `shared_widgets.dart` con dominio (`QRPattern`, `TimerRing`, `GymSuspendedBarrier`, `PushDisabledBanner`) y su feature destino tentativa.
3. Crear suite mÃ­nima de tests de humo en `mobile_app/test/smoke/`:
   - `app_boot_test.dart`: arranca `SasGymApp` y verifica que renderiza pantalla de login.
   - `role_routing_test.dart`: inyecta `GymState` con usuario por cada rol y verifica que la pantalla esperada se monta sin excepciÃ³n.

**ValidaciÃ³n Flutter (contenedor):**

```powershell
docker compose --profile ci build flutter-ci
```

Criterio: build verde (incluye `flutter analyze` + `flutter test`, smoke tests entran en la suite).

**ValidaciÃ³n Sistema (contenedor):**

```powershell
docker compose build api
docker compose up -d db api
docker compose ps
```

Criterio: contenedores `Up`, build limpio.

**Criterio de salida:**

- Existe `MIGRATION_INVENTORY.md` con los tres listados.
- Existen 2 smoke tests verdes ejecutados dentro de `flutter-ci`.
- Imagen `api` reconstruida limpia.

**Commit:** `chore(arch-migration): fase 0 - inventario y smoke tests`

**Rollback:** revertir el commit; no se ha tocado cÃ³digo de producciÃ³n.

---

### Fase 1 â€” Limpieza del punto de entrada

**Objetivo:** dejar `main.dart` minimalista y `app.dart` como Ãºnica autoridad sobre rutas, auth gate y barrera SaaS.

**Pre-condiciones:** Fase 0 cerrada.

**Tareas:**

1. Verificar que [main.dart](mobile_app/lib/main.dart) no conoce pantallas concretas (hoy ya cumple). Documentar en comentario por quÃ©.
2. Asegurar que [app.dart](mobile_app/lib/app.dart) es el Ãºnico que importa pantallas de rol.
3. Extraer `_TopBar` y `_RoleScreenHost` de `app.dart` a archivos propios en `lib/widgets/app_shell.dart` o `lib/core/shell/` si pesan mÃ¡s de lo razonable; si no, dejarlos privados.
4. Documentar el orden de gate en `app.dart`: `authLoading â†’ login â†’ SaaS barrier â†’ role host`.

**ValidaciÃ³n Flutter (contenedor):**

```powershell
docker compose --profile ci build flutter-ci
docker compose build frontend-web
```

Criterio:

- `flutter-ci` verde (smoke tests pasan).
- `frontend-web` buildea â€” implica que `flutter build web --release` compila sin errores.

**ValidaciÃ³n Sistema (contenedor):**

```powershell
docker compose up -d db api
docker compose ps
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@gymsmart.com',password:'<seed>'})}).then(r=>console.log(r.status))"
```

Criterio: `200` (login vÃ¡lido) y contenedores `Up`.

**Criterio de salida:**

- `main.dart` no importa ninguna pantalla.
- `app.dart` concentra la lÃ³gica de gate.
- Smoke tests verdes.

**Commit:** `refactor(arch-migration): fase 1 - aislar punto de entrada`

**Rollback:** `git revert` del commit. No hay efectos en backend.

---

### Fase 2 â€” MigraciÃ³n real de pantallas a `features/`

**Objetivo:** mover el cÃ³digo real desde `lib/screens/` a `lib/features/<feature>/screens/` y eliminar la indirecciÃ³n por shims.

**Pre-condiciones:** Fase 1 cerrada.

**Tareas (en este orden, un sub-commit por feature):**

1. `features/auth/screens/login_screen.dart` â† `git mv lib/screens/login_screen.dart`.
2. `features/member/screens/member_screen.dart` â† `git mv lib/screens/member_screen.dart`.
3. `features/trainer/screens/trainer_screen.dart` â† `git mv lib/screens/trainer_screen.dart`.
4. `features/cashier/screens/cashier_screen.dart` â† `git mv lib/screens/cashier_screen.dart`.
5. `features/admin/screens/admin_screen.dart` â† `git mv lib/screens/admin_screen.dart`.
6. `features/superadmin/screens/superadmin_screen.dart` â† `git mv lib/screens/superadmin_screen.dart`.

DespuÃ©s de cada movimiento:

- Borrar el shim correspondiente en `features/roles/` o `features/auth/`.
- Actualizar imports en `app.dart` y en el resto del Ã¡rbol.
- Ajustar imports relativos internos del archivo movido.

Al final de la fase:

- Eliminar carpeta `lib/screens/` (debe quedar vacÃ­a).
- Eliminar carpeta `lib/features/roles/` (debe quedar vacÃ­a).

**ValidaciÃ³n Flutter (contenedor, despuÃ©s de cada sub-commit):**

```powershell
docker compose --profile ci build flutter-ci
```

Criterio: build de la imagen `flutter-ci` verde tras cada sub-commit. Si un sub-commit rompe analyze o smoke tests, no continuar al siguiente rol hasta corregir.

**ValidaciÃ³n Sistema (contenedor):**

Sin cambios funcionales respecto a Fase 1 (este movimiento es 100% frontend). Al cierre de la fase, reconstruir el web release y validar contenedores:

```powershell
docker compose build frontend-web
docker compose ps
```

Criterio: `frontend-web` buildea (confirma que `flutter build web --release` sigue compilando con la nueva estructura), `db` y `api` siguen `Up`.

VerificaciÃ³n manual de UI (al cierre, no por sub-commit): levantar `frontend-web` en `localhost:8383` con `docker compose up -d frontend-web` y comprobar login + navegaciÃ³n por rol.

**Criterio de salida:**

- `lib/screens/` y `lib/features/roles/` eliminadas.
- Smoke tests verdes.
- App ejercitada manualmente por rol.

**Commits:** un commit por feature, prefijo `refactor(arch-migration): fase 2 - mover <feature> a features/<feature>/`.

**Rollback:** revertir commits en orden inverso al movimiento.

---

### Fase 3 â€” ReubicaciÃ³n de widgets con dominio

**Objetivo:** dejar `lib/widgets/` sÃ³lo con componentes agnÃ³sticos. Mover los widgets con conocimiento de dominio a la feature correspondiente.

**Pre-condiciones:** Fase 2 cerrada.

**Tareas:**

1. Para cada widget en [widgets/shared_widgets.dart](mobile_app/lib/widgets/shared_widgets.dart), aplicar el mapeo decidido en Fase 0:
   - `QRPattern`, `TimerRing` â†’ `features/member/widgets/`.
   - `GymSuspendedBarrier` â†’ `lib/core/saas/` (lo usa `app.dart`, transversal).
   - `PushDisabledBanner` â†’ `features/member/widgets/`.
   - Cualquier widget genuinamente reutilizable (`StatusPill`, `MetricTile`, `ActionTile`, `LogTile`, `SectionHeader`, `RoleNavBar`, `RoleSurface`, `RoleTabs`) **se conserva** en `widgets/`.
2. Partir `widgets/shared_widgets.dart` en archivos por widget si pasa los 500 LOC tras la limpieza.
3. Actualizar imports en cada feature.

**ValidaciÃ³n Flutter (contenedor):**

```powershell
docker compose --profile ci build flutter-ci
```

Criterio:

- Sin imports rotos (analyze limpio dentro del contenedor).
- Sin warnings `unused_import`.
- Smoke tests siguen verdes.
- Agregar 1 widget test por widget movido (verifica que monta sin error con datos mÃ­nimos).

**ValidaciÃ³n Sistema (contenedor):**

```powershell
docker compose up -d db api
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/members/qr-code',{headers:{'Authorization':'Bearer <token>','X-Tenant-ID':'<tenant>'}}).then(r=>r.json()).then(j=>console.log(JSON.stringify(j)))"
```

Criterio: respuesta contiene `qrSecret` e `intervalSeconds`.

**Criterio de salida:**

- `widgets/` libre de lÃ³gica de dominio.
- Widgets movidos con su test de humo.

**Commit:** `refactor(arch-migration): fase 3 - reubicar widgets con dominio`

**Rollback:** `git revert` del commit; las features siguen funcionando porque los archivos estaban consolidados.

---

### Fase 4 â€” ConsolidaciÃ³n de estado, modelos y `core/`

**Objetivo:** verificar fronteras entre `data/`, `models/` y `core/` sin partir el `GymState` global (eso es deuda tÃ©cnica fuera de alcance).

**Pre-condiciones:** Fase 3 cerrada.

**Tareas:**

1. Auditar [data/gym_state.dart](mobile_app/lib/data/gym_state.dart): confirmar que no importa nada de `features/`. Si lo hace, romper la dependencia.
2. Auditar [data/gym_seed.dart](mobile_app/lib/data/gym_seed.dart): debe contener sÃ³lo datos semilla, sin lÃ³gica reactiva.
3. Auditar [models/gym_models.dart](mobile_app/lib/models/gym_models.dart): debe ser Dart puro (sin `package:flutter/material.dart`). Si necesita `ChangeNotifier`, usar `package:flutter/foundation.dart`.
4. Confirmar que [core/network/api_client.dart](mobile_app/lib/core/network/api_client.dart) y [core/storage/secure_storage.dart](mobile_app/lib/core/storage/secure_storage.dart) no importan pantallas ni widgets.
5. Anotar `TODO(arch-future)` en `GymState` indicando dÃ³nde se partirÃ­a por feature en una iteraciÃ³n posterior.

**ValidaciÃ³n Flutter (contenedor):**

```powershell
docker compose --profile ci build flutter-ci
```

AnÃ¡lisis adicional de fronteras (host, sÃ³lo lectura):

```powershell
Select-String -Path "mobile_app\lib\core\**\*.dart","mobile_app\lib\models\**\*.dart" -Pattern "package:flutter/material" -SimpleMatch
Select-String -Path "mobile_app\lib\data\**\*.dart" -Pattern "import '../features" -SimpleMatch
```

Criterio: ambos `Select-String` devuelven **sin resultados**. (Lectura estÃ¡tica, no requiere Flutter en host.)

**ValidaciÃ³n Sistema (contenedor):**

```powershell
docker compose build api
docker compose up -d db api
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@gymsmart.com',password:'<seed>'})}).then(r=>r.json()).then(j=>console.log(JSON.stringify(j.user)))"
```

Criterio:

- Build de `api` limpio.
- Login devuelve `user` con `id`, `email`, `role`, `fullName` (valida que el shape del `LoggedInUser` consumido por Flutter siga intacto).

**Criterio de salida:**

- Reglas de dependencia de la secciÃ³n 2.3 verificadas con grep.
- `GymState` marcado con TODO de deuda.

**Commit:** `refactor(arch-migration): fase 4 - consolidar fronteras de core/data/models`

**Rollback:** revertir commit; cambios son anotaciones y ajustes de import.

---

### Fase 5 â€” VerificaciÃ³n de imports, dependencias y exports

**Objetivo:** eliminar imports redundantes, circulares o apuntando a paths obsoletos.

**Pre-condiciones:** Fase 4 cerrada.

**Tareas:**

1. Crear archivo `lib/features/<feature>/<feature>.dart` por cada feature, re-exportando sÃ³lo lo pÃºblico (pantalla principal y widgets reutilizables externamente).
2. Actualizar `app.dart` para que importe `package:mobile_app/features/<feature>/<feature>.dart` en vez del archivo profundo.
3. Verificar ausencia de imports circulares.
4. Verificar que no quedan referencias a `lib/screens/` o `lib/features/roles/`.

**ValidaciÃ³n Flutter (contenedor):**

```powershell
docker compose --profile ci build flutter-ci
docker compose build frontend-web
```

BÃºsquedas obligatorias (host, sÃ³lo lectura estÃ¡tica):

```powershell
Select-String -Path "mobile_app\lib\**\*.dart" -Pattern "screens/" -SimpleMatch
Select-String -Path "mobile_app\lib\**\*.dart" -Pattern "features/roles/" -SimpleMatch
```

Criterio: cero resultados en ambas bÃºsquedas; ambos contenedores buildean.

**ValidaciÃ³n Sistema (contenedor):**

Sin cambios respecto a fases previas. Repetir:

```powershell
docker compose build api
docker compose up -d db api
docker compose ps
```

Criterio: ambos contenedores `Up` y build limpio.

**Criterio de salida:**

- Cada feature expone un Ãºnico punto de entrada.
- BÃºsquedas confirman cero referencias a paths antiguos.

**Commit:** `refactor(arch-migration): fase 5 - normalizar imports y exports por feature`

**Rollback:** `git revert`; los archivos siguen donde la Fase 2 los dejÃ³.

---

### Fase 6 â€” ValidaciÃ³n funcional integral

**Objetivo:** confirmar que la migraciÃ³n no rompiÃ³ el comportamiento extremo a extremo.

**Pre-condiciones:** Fase 5 cerrada.

**Tareas:**

1. Ampliar `test/smoke/` con un test por flujo crÃ­tico:
   - `login_logout_test.dart`: login con cada rol, logout, vuelta a pantalla de login.
   - `member_qr_test.dart`: usuario miembro carga QR y se ve `TimerRing`.
   - `cashier_pos_test.dart`: pantalla POS monta sin error.
   - `admin_dashboard_test.dart`: pantalla admin monta sin error con seed.
   - `saas_barrier_test.dart`: con `isCurrentGymActive=false` la barrera SaaS aparece.
2. Documentar resultados en `mobile_app/MIGRATION_VALIDATION.md` con fecha y comandos ejecutados.

**ValidaciÃ³n Flutter (contenedor + cobertura):**

```powershell
docker compose --profile ci build flutter-ci
docker compose run --rm flutter-ci flutter test --coverage
docker compose build frontend-web
docker compose up -d frontend-web   # smoke visual en localhost:8383
```

Criterio:

- 0 fallos en suite completa dentro del contenedor.
- Cobertura â‰¥ 30 % en `features/*/screens/` (umbral mÃ­nimo, ajustable).
- `frontend-web` sirve la app en `http://localhost:8383` y los 5 roles son navegables con seed credentials.

**ValidaciÃ³n Sistema (contenedor):**

Ejecutar el set completo de endpoints crÃ­ticos desde dentro de `api`:

```powershell
docker compose up -d db api

# Login (devuelve token + tenantId + user)
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@gymsmart.com',password:'<seed>'})}).then(r=>r.json()).then(j=>console.log(JSON.stringify(j)))"

# QR seed (member)
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/members/qr-code',{headers:{'Authorization':'Bearer <member_token>','X-Tenant-ID':'<tenant>'}}).then(r=>r.json()).then(j=>console.log(JSON.stringify(j)))"

# Verify attendance (admin/cashier)
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/attendance/verify',{method:'POST',headers:{'Authorization':'Bearer <admin_token>','X-Tenant-ID':'<tenant>','Content-Type':'application/json'},body:JSON.stringify({dni:'12345678',otpToken:'<token>'})}).then(r=>r.json()).then(j=>console.log(JSON.stringify(j)))"

# Pending payments (admin)
docker compose exec api node -e "fetch('http://localhost:3000/api/v1/admin/pending-payments',{headers:{'Authorization':'Bearer <admin_token>','X-Tenant-ID':'<tenant>'}}).then(r=>r.json()).then(j=>console.log(JSON.stringify(j)))"
```

Criterio: los 4 endpoints responden el shape documentado en [AVANCES_MIGRACION_FLUTTER.md](AVANCES_MIGRACION_FLUTTER.md) secciÃ³n 2.

**Criterio de salida:**

- Suite de smoke tests completa.
- Documento `MIGRATION_VALIDATION.md` con evidencia.

**Commit:** `test(arch-migration): fase 6 - suite de smoke completa por flujo`

**Rollback:** revertir el commit elimina tests pero no compromete la app.

---

## 5. Orden de ejecuciÃ³n resumido

| Fase | Alcance | Riesgo | Tiempo estimado |
|------|---------|--------|-----------------|
| 0    | Inventario + smoke tests base | Bajo | 0.5 dÃ­a |
| 1    | Limpieza de `main.dart` y `app.dart` | Bajo | 0.5 dÃ­a |
| 2    | MigraciÃ³n real de pantallas a `features/` | **Alto** | 1.5 dÃ­a |
| 3    | ReubicaciÃ³n de widgets con dominio | Medio | 1 dÃ­a |
| 4    | AuditorÃ­a de `core/data/models` | Bajo | 0.5 dÃ­a |
| 5    | Imports, exports y barrels | Bajo | 0.5 dÃ­a |
| 6    | Suite de validaciÃ³n + smoke manual | Bajo | 1 dÃ­a |

Total: ~5.5 dÃ­as de trabajo enfocado.

---

## 6. Riesgos y controles

| Riesgo | Control |
|--------|---------|
| Romper imports al mover archivos | `git mv` + smoke tests entre sub-commits |
| Olvidar borrar shims tras migrar | BÃºsqueda forzosa en Fase 5: cero resultados de `screens/` o `features/roles/` |
| Widgets de dominio quedan en `widgets/` | Mapeo cerrado en Fase 0 + revisiÃ³n en Fase 3 |
| Backend deja de compilar por cambio accidental | ValidaciÃ³n sistema en cada fase incluye `docker compose build api` |
| `GymState` global crece descontrolado | TODO marcado en Fase 4; partir queda fuera de alcance |
| Sin tests = regresiones invisibles | Suite mÃ­nima creada en Fase 0, ampliada hasta Fase 6 |

---

## 7. Criterios de aceptaciÃ³n final

La migraciÃ³n se considera correcta cuando, de forma simultÃ¡nea:

- [lib/screens/](mobile_app/lib/screens/) y `lib/features/roles/` no existen.
- Cada rol vive en `features/<rol>/screens/` con su propio export barril.
- `widgets/` no contiene lÃ³gica especÃ­fica de un rol.
- `docker compose --profile ci build flutter-ci` verde (analyze + test dentro del contenedor).
- `docker compose build api` y `docker compose build frontend-web` verdes; contenedores levantan, login y endpoints crÃ­ticos siguen respondiendo el contrato documentado.
- Existe `MIGRATION_VALIDATION.md` con evidencia de comandos y fechas.

---

## 8. Fuera de alcance (deuda tÃ©cnica registrada)

Para no agrandar el plan mÃ¡s allÃ¡ de su objetivo, queda explÃ­citamente fuera de esta migraciÃ³n:

- Partir `GymState` en providers por feature (Riverpod / Bloc / mÃºltiples ChangeNotifier).
- Introducir Clean Architecture completa (`domain/data/presentation/`) por feature.
- Migrar lÃ³gica de red de Dio crudo a un repositorio formal por feature.
- InternacionalizaciÃ³n (`l10n/`).
- IntegraciÃ³n real de WebSockets en cliente (hoy el servicio estÃ¡ planeado en AVANCES pero no integrado en UI).

Estos puntos deben planificarse como iteraciones independientes una vez cerrada esta migraciÃ³n.


