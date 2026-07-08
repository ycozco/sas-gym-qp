# Migration Validation Report

**Fecha:** 2026-05-25
**Plan ejecutado:** [PLAN_MIGRACION_CORRECCION.md](../PLAN_MIGRACION_CORRECCION.md)
**Inventario base:** [MIGRATION_INVENTORY.md](MIGRATION_INVENTORY.md)
**ValidaciÃ³n:** 100 % contenerizada (Docker), sin ejecutar `flutter`/`npm` directamente en el host.

---

## 1. Resumen ejecutivo

| Fase | Commit | Estado | ValidaciÃ³n contenerizada |
|------|--------|--------|--------------------------|
| Baseline | `8a2b97d` | âœ… | n/a (snapshot) |
| Pre-requisitos containerizaciÃ³n | `fee4507` | âœ… | api y app-web buildeables |
| Plan contenerizado | `6e92514` | âœ… | docs |
| Fase 0: inventario + smoke tests | `75d2dcd` | âœ… | flutter-ci 7/7 + api OK |
| Fase 1: aislar punto de entrada | `5f8f999` | âœ… | flutter-ci 7/7 |
| Fase 2.1: login â†’ features/auth | `6cfea88` | âœ… | flutter-ci 7/7 |
| Fase 2.2: member â†’ features/member | `ac17888` | âœ… | flutter-ci 7/7 |
| Fase 2.3: trainer â†’ features/trainer | `296ebde` | âœ… | flutter-ci 7/7 |
| Fase 2.4: cashier â†’ features/cashier | `019a0bf` | âœ… | flutter-ci 7/7 |
| Fase 2.5: admin â†’ features/admin | `330aefd` | âœ… | flutter-ci 7/7 |
| Fase 2.6: superadmin â†’ features/superadmin + cierre | `5ba23be` | âœ… | tests Flutter 7/7 + api + app-web |
| Fase 3: widgets con dominio reubicados | `867bb78` | âœ… | tests Flutter 11/11 + api + app-web |
| Fase 4: fronteras core/data/models | `2132559` | âœ… | flutter-ci 11/11 + api |
| Fase 5: barriles e imports normalizados | `cbf06bc` | âœ… | tests Flutter 11/11 + api + app-web |

---

## 2. Comandos de validaciÃ³n ejecutados (Fase 6)

### 2.1 Suite completa de Flutter dentro del contenedor

```powershell
docker compose --profile ci build flutter-ci
docker compose run --rm flutter-ci flutter test
```

**Resultado:**

```
00:00 +0: loading /app/test/smoke/app_boot_test.dart
00:01 +1: /app/test/smoke/app_boot_test.dart: SasGymApp boots and renders login when no user is set
00:01 +2: /app/test/smoke/role_routing_test.dart: app boots for role member without throwing
00:02 +3: /app/test/smoke/role_routing_test.dart: app boots for role trainer without throwing
00:02 +4: /app/test/smoke/role_routing_test.dart: app boots for role cashier without throwing
00:02 +5: /app/test/smoke/role_routing_test.dart: app boots for role admin without throwing
00:02 +6: /app/test/smoke/role_routing_test.dart: app boots for role superadmin without throwing
00:02 +7: /app/test/smoke/role_routing_test.dart: SaaS barrier renders when current gym is inactive
00:03 +8: /app/test/smoke/widgets_relocated_test.dart: QRPattern monta con seed sin lanzar
00:03 +9: /app/test/smoke/widgets_relocated_test.dart: TimerRing monta con valores arbitrarios sin lanzar
00:03 +10: /app/test/smoke/widgets_relocated_test.dart: ExerciseAnim monta para bicep curl sin lanzar
00:03 +11: /app/test/smoke/widgets_relocated_test.dart: GymSuspendedBarrier monta y muestra titulo de suspension
00:03 +11: All tests passed!
```

11/11 verdes.

### 2.2 Backend release dentro de Docker

```powershell
docker compose build api
```

Imagen `sas_gym-api` build limpio (compilaciÃ³n TS con `nest build` dentro del contenedor).

### 2.3 Flutter web release dentro de Docker

```powershell
docker compose --env-file ../.env.local.example -f ../infra/docker/compose.local.yml build app-web
```

Imagen `sasgym_app_web_local` build limpio. El stage `build` corre `flutter build web --release` y deja el bundle estÃ¡tico servido por nginx en el puerto 80.

### 2.4 VerificaciÃ³n estÃ¡tica de paths antiguos

```powershell
Select-String -Path "mobile_app\lib\**\*.dart" -Pattern "features/roles/" -SimpleMatch
```

Resultado: **cero matches**.

```powershell
Select-String -Path "mobile_app\lib\**\*.dart" -Pattern "screens/" -SimpleMatch
```

Resultado: **solo barrels internos** (`export 'screens/<screen>.dart';` dentro de cada feature). Ninguna referencia al antiguo `lib/screens/`.

---

## 3. Estructura final de `lib/`

```
lib/
  main.dart              # bootstrap puro
  app.dart               # gate auth + barrera SaaS + role host
  core/
    network/api_client.dart
    storage/secure_storage.dart
  data/
    gym_seed.dart
    gym_state.dart       # TODO(arch-future): partir por feature
  models/
    gym_models.dart      # TODO(arch-future): separar DTOs puros de catalogos visuales
  theme/
    app_theme.dart
  widgets/
    app_shell.dart       # RoleSurface, RoleTabs, RoleNavBar, MetricTile, ActionTile, etc.
    exercise_anim.dart   # reusable trainer+member
    saas/
      gym_suspended_barrier.dart
  features/
    auth/
      auth.dart          # barrel
      screens/login_screen.dart
    member/
      member.dart        # barrel
      screens/member_screen.dart
      widgets/qr_pattern.dart
      widgets/timer_ring.dart
      widgets/log_effort_modal.dart
    trainer/
      trainer.dart       # barrel
      screens/trainer_screen.dart
    cashier/
      cashier.dart       # barrel
      screens/cashier_screen.dart
    admin/
      admin.dart         # barrel
      screens/admin_screen.dart
    superadmin/
      superadmin.dart    # barrel
      screens/superadmin_screen.dart
```

`lib/screens/` y `lib/features/roles/` **no existen**.

---

## 4. Criterios de aceptaciÃ³n finales

- [x] `lib/screens/` y `lib/features/roles/` no existen.
- [x] Cada rol vive en `features/<rol>/screens/` con su propio export barril.
- [x] `widgets/` no contiene lÃ³gica especÃ­fica de un rol (los widgets de dominio movidos a `features/member/widgets/`).
- [x] `docker compose --profile ci build flutter-ci` verde (analyze + 11 tests).
- [x] `docker compose build api` verde.
- [x] `docker compose --env-file ../.env.local.example -f ../infra/docker/compose.local.yml build app-web` verde (Flutter web release build dentro del contenedor).
- [x] ValidaciÃ³n 100 % contenerizada â€” sin `flutter`/`npm` en el host.

---

## 5. Deuda tÃ©cnica registrada (fuera de alcance)

Documentada inline con `TODO(arch-future)`:

- `data/gym_state.dart`: monolito `ChangeNotifier`. IteraciÃ³n futura: partir en notifiers por feature (Riverpod/Bloc).
- `models/gym_models.dart`: importa `material.dart` para `Color`/`IconData`. IteraciÃ³n futura: separar DTOs puros de catÃ¡logos visuales.
- Cross-feature import en `features/trainer/screens/trainer_screen.dart` consume `ReportObservationView` del socio. Smell registrado para reubicar.
- `features/member/widgets/qr_pattern.dart` queda sin callers (member usa `qr_flutter` real). Conservado como afordance documentada.

---

## 6. CÃ³mo volver atrÃ¡s

Cada commit de fase es revertible con `git revert`. Las dependencias son lineales: revertir Fase N requiere revertir N+1...6 en orden inverso primero. Para un rollback total al baseline:

```powershell
git reset --hard 8a2b97d
```
