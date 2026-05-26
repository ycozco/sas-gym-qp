# Inventario pre-migración (Fase 0)

Fotografía del árbol `flutter_app/lib/` al inicio de la migración arquitectónica.

## 1. `lib/screens/` (código real, candidato a moverse a `features/`)

| Archivo | Tamaño aprox. | Destino |
|---------|---------------|---------|
| admin_screen.dart | 119 KB | `features/admin/screens/admin_screen.dart` |
| member_screen.dart | 92 KB | `features/member/screens/member_screen.dart` |
| cashier_screen.dart | 70 KB | `features/cashier/screens/cashier_screen.dart` |
| trainer_screen.dart | 56 KB | `features/trainer/screens/trainer_screen.dart` |
| login_screen.dart | 22 KB | `features/auth/screens/login_screen.dart` |
| superadmin_screen.dart | 9 KB | `features/superadmin/screens/superadmin_screen.dart` |

## 2. `lib/features/` (shim actual)

Todos son re-exports de 43–48 bytes que apuntan a `lib/screens/*`. Se eliminan en Fase 2 cuando el código real se mueva.

| Archivo | Contenido actual | Acción |
|---------|------------------|--------|
| `features/auth/login_screen.dart` | `export '../../screens/login_screen.dart';` | Reemplazar por archivo real movido |
| `features/roles/admin_screen.dart` | `export '../../screens/admin_screen.dart';` | Reemplazar; subcarpeta `roles/` desaparece |
| `features/roles/cashier_screen.dart` | idem | idem |
| `features/roles/member_screen.dart` | idem | idem |
| `features/roles/superadmin_screen.dart` | idem | idem |
| `features/roles/trainer_screen.dart` | idem | idem |

## 3. Widgets compartidos con dominio (`widgets/shared_widgets.dart`)

Mapeo decidido para Fase 3 (no se mueve nada en Fase 0):

| Widget | Estado actual | Destino tras Fase 3 |
|--------|---------------|---------------------|
| `QRPattern` | Específico del socio | `features/member/widgets/` |
| `TimerRing` | Específico del socio (refresh TOTP) | `features/member/widgets/` |
| `PushDisabledBanner` | Específico del socio | `features/member/widgets/` |
| `GymSuspendedBarrier` | Transversal (lo usa `app.dart`) | `lib/core/saas/` |
| `StatusPill` | Agnóstico | Se queda en `widgets/` |
| `MetricTile`, `ActionTile`, `LogTile`, `SectionHeader` | Agnósticos | Se quedan en `widgets/` |
| `RoleNavBar`, `RoleSurface`, `RoleTabs` | Agnósticos (toman `RolePalette`) | Se quedan en `widgets/` |

## 4. Imports cruzados detectados

- `app.dart` → `features/auth/login_screen.dart` + `features/roles/*_screen.dart` (vía shim, OK transitoriamente).
- `screens/*` → `widgets/shared_widgets.dart` (consume widgets de dominio que viven en compartidos; se rompe esta dependencia en Fase 3 moviendo los widgets a sus features).
- `screens/*` → `widgets/app_shell.dart` (UI agnóstica como `RoleNavBar`, `SectionHeader`, etc. — esto se conserva).
- `data/gym_state.dart` → `core/network/api_client.dart`, `core/storage/secure_storage.dart`, `models/gym_models.dart` (cumple regla de dependencia).
- `models/gym_models.dart` → `package:flutter/material.dart` (impuro: usa `Color` e `IconData`). Se anota como deuda de Fase 4 (puede ser aceptable porque la UI necesita esos tipos; alternativa = mover a Dart puro y mapear en presentación).

## 5. Estado y dependencias

- Único `ChangeNotifier`: `GymState` en `data/gym_state.dart`. No se parte en esta migración (registrado como deuda en sección 8 del plan).
- Capa `core/` existente: `network/api_client.dart`, `storage/secure_storage.dart`. Sin dependencias hacia UI.
- Backend NestJS contenerizado con módulos `auth`, `members`, `attendance`, `payments`, `routines`, `observations`, `tenants`, `reports`, `schedules`, `announcements`.

## 6. Red de seguridad inicial

- `flutter_app/test/smoke/app_boot_test.dart` — boot de `SasGymApp` con `startBackground: false`, verifica pantalla de login.
- `flutter_app/test/smoke/role_routing_test.dart` — inyecta un `LoggedInUser` por cada `GymRole` y valida que el shell de rol monta sin excepción.

Ambos corren dentro del contenedor `flutter-ci` (`docker compose --profile ci build flutter-ci`).
