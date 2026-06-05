import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/gym_seed.dart';
import 'data/gym_state.dart';
import 'features/admin/admin.dart';
import 'features/auth/auth.dart';
import 'features/cashier/cashier.dart';
import 'features/member/member.dart';
import 'features/superadmin/superadmin.dart';
import 'features/trainer/trainer.dart';
import 'models/gym_models.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_tokens.dart';
import 'widgets/app_shell.dart';
import 'widgets/saas/gym_suspended_barrier.dart';

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
        darkTheme: AppTheme.dark(),
        themeMode: state.themeMode,
        home: const _AuthLoadingScreen(),
      );
    }

    final user = state.currentUser;

    // Si no está autenticado, mostrar la pantalla de Login
    if (user == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SaaaS GYM',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: state.themeMode,
        home: const LoginScreen(),
      );
    }

    final role = user.rol;
    final palette = rolePalettes[role]!;

    // Si el gimnasio está bloqueado (SaaS suspended) y el rol no es superadmin, mostrar barrera
    final isBlocked = !state.isCurrentGymActive && role != GymRole.superadmin;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SaaaS GYM',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(selectedRole: role),
              Expanded(
                child: isBlocked
                    ? GymSuspendedBarrier(
                        onContactAdmin: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Soporte SaaS contactado. Se envió un correo de alerta.',
                              ),
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

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colors.accent),
            const SizedBox(height: 20),
            Text(
              'SaaaS GYM',
              style: GoogleFonts.bricolageGrotesque(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cargando tu perfil...',
              style: GoogleFonts.plusJakartaSans(
                color: colors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.selectedRole});

  final GymRole selectedRole;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final user = state.currentUser;
    final colors = context.sasColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: rolePalettes[selectedRole]!.accent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: rolePalettes[selectedRole]!.accent.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 4,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SaaaS GYM',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (user != null) ...[
                _ThemeModeButton(
                  currentMode: state.themeMode,
                  onChanged: state.updateThemeMode,
                ),
                IconButton(
                  icon: Icon(Icons.logout, size: 20, color: colors.textMuted),
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
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: rolePalettes[selectedRole]!.accent
                        .withValues(alpha: 0.12),
                    child: Text(
                      user.nombreCompleto.isNotEmpty
                          ? user.nombreCompleto.substring(0, 1).toUpperCase()
                          : 'U',
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
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedRole.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? colors.textSecondary
                                : rolePalettes[selectedRole]!.accentInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const StatusPill(label: 'En Línea', color: Color(0xFF00B85C)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({required this.currentMode, required this.onChanged});

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final icon = switch (currentMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Cambiar tema',
      icon: Icon(icon, size: 20, color: colors.textMuted),
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: ThemeMode.system,
            child: _ThemeModeMenuItem(
              icon: Icons.brightness_auto_rounded,
              label: 'Sistema',
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.light,
            child: _ThemeModeMenuItem(
              icon: Icons.light_mode_rounded,
              label: 'Claro',
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.dark,
            child: _ThemeModeMenuItem(
              icon: Icons.dark_mode_rounded,
              label: 'Oscuro',
            ),
          ),
        ];
      },
    );
  }
}

class _ThemeModeMenuItem extends StatelessWidget {
  const _ThemeModeMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RoleScreenHost extends StatelessWidget {
  const _RoleScreenHost({super.key, required this.role, required this.palette});

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

    return RoleSurface(palette: palette, child: screen);
  }
}
