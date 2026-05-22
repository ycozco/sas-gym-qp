import 'package:flutter/material.dart';
import 'data/gym_seed.dart';
import 'data/gym_state.dart';
import 'models/gym_models.dart';
import 'screens/admin_screen.dart';
import 'screens/cashier_screen.dart';
import 'screens/member_screen.dart';
import 'screens/trainer_screen.dart';
import 'screens/superadmin_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';
import 'widgets/shared_widgets.dart';

class SasGymApp extends StatefulWidget {
  const SasGymApp({super.key});

  @override
  State<SasGymApp> createState() => _SasGymAppState();
}

class _SasGymAppState extends State<SasGymApp> {
  GymRole _role = GymRole.member;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final palette = rolePalettes[_role]!;

    // If gym is inactive and role is not superadmin, block access
    final isBlocked = !state.isCurrentGymActive && _role != GymRole.superadmin;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SaaaS GYM',
      theme: AppTheme.light(),
      home: Scaffold(
        backgroundColor: const Color(0xFFFBFBF9),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                selectedRole: _role,
                onChanged: (role) => setState(() => _role = role),
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
                          key: ValueKey(_role),
                          palette: palette,
                          role: _role,
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
    required this.onChanged,
  });

  final GymRole selectedRole;
  final ValueChanged<GymRole> onChanged;

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text(
                  'SaaaS GYM',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                ),
              ),
              Text(
                'Plataforma Activa',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF8B8B8B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RoleTabs(selected: selectedRole, onChanged: onChanged),
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