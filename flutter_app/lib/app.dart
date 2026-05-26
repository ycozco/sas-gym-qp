import 'package:flutter/material.dart';
import 'data/gym_seed.dart';
import 'data/gym_state.dart';
import 'features/auth/login_screen.dart';
import 'features/admin/screens/admin_screen.dart';
import 'features/cashier/screens/cashier_screen.dart';
import 'features/member/screens/member_screen.dart';
import 'features/superadmin/screens/superadmin_screen.dart';
import 'features/trainer/screens/trainer_screen.dart';
import 'models/gym_models.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';
import 'core/saas/gym_suspended_barrier.dart';

class SasGymApp extends StatefulWidget {
  const SasGymApp({super.key});

  @override
  State<SasGymApp> createState() => _SasGymAppState();
}

// Orden de gate aplicado por _SasGymAppState.build:
//   1. authLoading -> splash de carga.
//   2. currentUser == null -> LoginScreen.
//   3. tenant SaaS inactivo (no superadmin) -> GymSuspendedBarrier.
//   4. autenticado + tenant activo -> _RoleScreenHost segun rol.
// Cualquier cambio al gate debe mantener este orden o actualizar los
// smoke tests en test/smoke/role_routing_test.dart.
class _SasGymAppState extends State<SasGymApp> {
  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);

    // Si está validando las credenciales de inicio, mostrar una pantalla de carga premium
    if (state.authLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(
          backgroundColor: Color(0xFF0E0E10),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFE5A93B),
                ),
                SizedBox(height: 20),
                Text(
                  'SaaaS GYM',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Cargando tu perfil...',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = state.currentUser;

    // Si no está autenticado, mostrar la pantalla de Login
    if (user == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SaaaS GYM',
        theme: AppTheme.light(),
        home: const LoginScreen(),
      );
    }

    final role = user.rol;
    final palette = rolePalettes[role]!;
    final isDark = role == GymRole.admin;

    // Si el gimnasio está bloqueado (SaaS suspended) y el rol no es superadmin, mostrar barrera
    final isBlocked = !state.isCurrentGymActive && role != GymRole.superadmin;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SaaaS GYM',
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E0E11) : const Color(0xFFFBFBF9),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                selectedRole: role,
              ),
              Expanded(
                child: isBlocked
                    ? GymSuspendedBarrier(
                        onContactAdmin: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Soporte SaaS contactado. Se envió un correo de alerta.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        },
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _RoleScreenHost(
                          key: ValueKey(role),
                          palette: palette,
                          role: role,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.selectedRole,
  });

  final GymRole selectedRole;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final user = state.currentUser;
    final isDark = selectedRole == GymRole.admin;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: rolePalettes[selectedRole]!.accent,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: rolePalettes[selectedRole]!.accent.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SaaaS GYM',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              if (user != null) ...[
                IconButton(
                  icon: Icon(Icons.logout, size: 20, color: isDark ? Colors.white60 : const Color(0xFF8B8B8B)),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () => state.logout(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (user != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16161A) : rolePalettes[selectedRole]!.surfaceTint.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF232329) : rolePalettes[selectedRole]!.accent.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: rolePalettes[selectedRole]!.accent.withValues(alpha: 0.12),
                    child: Text(
                      user.nombreCompleto.isNotEmpty ? user.nombreCompleto.substring(0, 1).toUpperCase() : 'U',
                      style: TextStyle(
                        color: rolePalettes[selectedRole]!.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nombreCompleto,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedRole.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : rolePalettes[selectedRole]!.accentInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const StatusPill(
                    label: 'En Línea',
                    color: Color(0xFF00B85C),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _RoleScreenHost extends StatelessWidget {
  const _RoleScreenHost({
    super.key,
    required this.role,
    required this.palette,
  });

  final GymRole role;
  final RolePalette palette;

  @override
  Widget build(BuildContext context) {
    final screen = switch (role) {
      GymRole.member => const MemberScreen(),
      GymRole.trainer => const TrainerScreen(),
      GymRole.cashier => const CashierScreen(),
      GymRole.admin => const AdminScreen(),
      GymRole.superadmin => const SuperAdminScreen(),
    };

    return RoleSurface(
      palette: palette,
      child: screen,
    );
  }
}