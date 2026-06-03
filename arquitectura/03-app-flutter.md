# App Flutter

## Proposito

`mobile_app/` es la app principal del producto. Porta la experiencia de los mockups y organiza las vistas por rol. Puede correr como app Flutter local, web build y contenedor Nginx.

## Stack

- Flutter / Dart.
- Material 3.
- `dio` para HTTP.
- `flutter_secure_storage` para JWT y tenant.
- `socket_io_client` para eventos en tiempo real.
- `hive` y `hive_flutter` como base de almacenamiento local.
- `connectivity_plus` para detectar conectividad.
- `qr_flutter` y `otp` para QR/TOTP.
- `google_fonts` para tipografia.

## Entrada y flujo

```text
main.dart
  -> SasGymApp en app.dart
    -> login si no hay sesion
    -> barrera SaaS si el tenant esta suspendido
    -> pantalla del rol autenticado
```

Archivos clave:

- `lib/main.dart`: inicializa Flutter y monta la app.
- `lib/app.dart`: decide la vista activa segun sesion, rol y estado SaaS.
- `lib/theme/app_theme.dart`: estilos globales.
- `lib/data/gym_state.dart`: estado compartido, auth demo y datos operativos.
- `lib/data/gym_seed.dart`: datos semilla para la experiencia mock.
- `lib/models/gym_models.dart`: modelos y enums compartidos.
- `lib/widgets/app_shell.dart`: shell visual, tabs, metricas, tiles y navegacion.
- `lib/widgets/saas/gym_suspended_barrier.dart`: bloqueo visual por tenant suspendido.

## Features por rol

| Feature | Archivos principales | Estado |
|---|---|---|
| Auth | `features/auth/screens/login_screen.dart` | Implementado con login, demo y recuperacion. |
| Superadmin | `features/superadmin/screens/superadmin_screen.dart` | Implementado para listado y suspension/activacion. |
| Member | `features/member/screens/member_screen.dart` y widgets propios | Implementado con rutinas, QR, pagos, clases y esfuerzo. |
| Trainer | `features/trainer/screens/trainer_screen.dart` | Implementado con ejercicios, plantillas y seguimiento. |
| Cashier | `features/cashier/screens/cashier_screen.dart` y widgets POS | Implementado con turno, POS, ventas, scan y membresias. |
| Admin | `features/admin/screens/admin_screen.dart` y widgets admin | Implementado con dashboard, miembros, caja, productos y auditoria. |

## Servicios

- `core/network/api_client.dart`: cliente Dio con base URL e interceptores.
- `core/storage/secure_storage.dart`: wrapper de almacenamiento seguro (limpio de APIs deprecadas).
- `core/services/sync_queue_service.dart`: base para cola de sincronización offline.
- `core/services/websocket_service.dart`: conexión a eventos de tiempo real.

---

## Gestión de Estado Modular (Plan de Refactorización)

Actualmente, `mobile_app/lib/data/gym_state.dart` actúa como una clase administradora global (*God-Class*), mezclando autenticación, turnos de caja, rutinas, anuncios y cache local. 

Para optimizar el rendimiento y evitar repintados innecesarios en la interfaz de usuario, se establece el siguiente plan de fragmentación en **proveedores atómicos de Riverpod**:

```
gym_state.dart (ChangeNotifier Global)
     │
     ├──► authProvider (StateNotifier / Autenticación, JWT, checkAuth)
     ├──► cashierProvider (StateNotifier / Turnos de caja, POS, arqueo diario)
     ├──► memberProvider (Notifier / Rutinas del día, series, registro de esfuerzo RPE)
     ├──► announcementsProvider (Notifier / Feed de comunicados, banners)
     └──► offlineCacheProvider (Sincronización y persistencia con Hive)
```

### Ejemplo de Proveedor Atómico (Riverpod)

```dart
// lib/features/auth/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final LoggedInUser? user;
  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, LoggedInUser? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  AuthNotifier(this._api) : super(AuthState());

  Future<bool> login(String email, String password, String tenantId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.dio.post('/auth/login', 
        data: {'email': email, 'password': password},
        options: Options(headers: {'X-Tenant-ID': tenantId})
      );
      final token = response.data['token'];
      await SecureStorage.saveToken(token);
      await SecureStorage.saveTenantId(tenantId);
      
      final profileRes = await _api.dio.get('/auth/me');
      final user = LoggedInUser.fromJson(profileRes.data);
      state = AuthState(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, error: 'Credenciales inválidas');
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiClient());
});
```

*Nota: Los widgets de la interfaz consumirán estos proveedores utilizando selectores específicos (`ref.watch(authProvider.select((s) => s.user))`), lo que reducirá el repintado redundante en dispositivos móviles de gama media.*

## Dependencia de mockups

Los mockups en React siguen siendo una fuente de referencia importante. La app Flutter ya traslado gran parte de la estructura por rol, pero aun hay areas donde los mockups pueden servir para completar fidelidad visual, densidad de informacion y microflujos.

## Riesgos actuales

- Convivencia entre datos reales y datos mock.
- Validaciones visuales no garantizadas para todos los viewports.
- Algunos flujos estan implementados como simulacion local y no necesariamente conectados a endpoints reales.
- La cobertura de tests actual parece centrada en smoke tests.
