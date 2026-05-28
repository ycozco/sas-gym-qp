# Inventario pre-migraciÃ³n (Fase 0)

FotografÃ­a del Ã¡rbol `mobile_app/lib/` al inicio de la migraciÃ³n arquitectÃ³nica.

## 1. `lib/screens/` (cÃ³digo real, candidato a moverse a `features/`)

| Archivo | TamaÃ±o aprox. | Destino |
|---------|---------------|---------|
| admin_screen.dart | 119 KB | `features/admin/screens/admin_screen.dart` |
| member_screen.dart | 92 KB | `features/member/screens/member_screen.dart` |
| cashier_screen.dart | 70 KB | `features/cashier/screens/cashier_screen.dart` |
| trainer_screen.dart | 56 KB | `features/trainer/screens/trainer_screen.dart` |
| login_screen.dart | 22 KB | `features/auth/screens/login_screen.dart` |
| superadmin_screen.dart | 9 KB | `features/superadmin/screens/superadmin_screen.dart` |

## 2. `lib/features/` (shim actual)

Todos son re-exports de 43â€“48 bytes que apuntan a `lib/screens/*`. Se eliminan en Fase 2 cuando el cÃ³digo real se mueva.

| Archivo | Contenido actual | AcciÃ³n |
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
| `QRPattern` | EspecÃ­fico del socio | `features/member/widgets/` |
| `TimerRing` | EspecÃ­fico del socio (refresh TOTP) | `features/member/widgets/` |
| `PushDisabledBanner` | EspecÃ­fico del socio | `features/member/widgets/` |
| `GymSuspendedBarrier` | Transversal (lo usa `app.dart`) | `lib/core/saas/` |
| `StatusPill` | AgnÃ³stico | Se queda en `widgets/` |
| `MetricTile`, `ActionTile`, `LogTile`, `SectionHeader` | AgnÃ³sticos | Se quedan en `widgets/` |
| `RoleNavBar`, `RoleSurface`, `RoleTabs` | AgnÃ³sticos (toman `RolePalette`) | Se quedan en `widgets/` |

## 4. Imports cruzados detectados

- `app.dart` â†’ `features/auth/login_screen.dart` + `features/roles/*_screen.dart` (vÃ­a shim, OK transitoriamente).
- `screens/*` â†’ `widgets/shared_widgets.dart` (consume widgets de dominio que viven en compartidos; se rompe esta dependencia en Fase 3 moviendo los widgets a sus features).
- `screens/*` â†’ `widgets/app_shell.dart` (UI agnÃ³stica como `RoleNavBar`, `SectionHeader`, etc. â€” esto se conserva).
- `data/gym_state.dart` â†’ `core/network/api_client.dart`, `core/storage/secure_storage.dart`, `models/gym_models.dart` (cumple regla de dependencia).
- `models/gym_models.dart` â†’ `package:flutter/material.dart` (impuro: usa `Color` e `IconData`). Se anota como deuda de Fase 4 (puede ser aceptable porque la UI necesita esos tipos; alternativa = mover a Dart puro y mapear en presentaciÃ³n).

## 5. Estado y dependencias

- Ãšnico `ChangeNotifier`: `GymState` en `data/gym_state.dart`. No se parte en esta migraciÃ³n (registrado como deuda en secciÃ³n 8 del plan).
- Capa `core/` existente: `network/api_client.dart`, `storage/secure_storage.dart`. Sin dependencias hacia UI.
- Backend NestJS contenerizado con mÃ³dulos `auth`, `members`, `attendance`, `payments`, `routines`, `observations`, `tenants`, `reports`, `schedules`, `announcements`.

## 6. Red de seguridad inicial

- `mobile_app/test/smoke/app_boot_test.dart` â€” boot de `SasGymApp` con `startBackground: false`, verifica pantalla de login.
- `mobile_app/test/smoke/role_routing_test.dart` â€” inyecta un `LoggedInUser` por cada `GymRole` y valida que el shell de rol monta sin excepciÃ³n.

Ambos corren dentro del contenedor `flutter-ci` (`docker compose --profile ci build flutter-ci`).

