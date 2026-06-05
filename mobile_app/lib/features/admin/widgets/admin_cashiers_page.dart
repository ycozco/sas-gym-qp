import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminCashiersPage extends StatelessWidget {
  const AdminCashiersPage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return ListView(
      key: const PageStorageKey<String>('admin-cashiers'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionHeader(
                title: 'Cuentas de Caja',
                action: 'Permisos en tiempo real',
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.person_add_rounded,
                color: palette.accent,
                size: 26,
              ),
              onPressed: () => _showAddCashierDialog(context),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: adminCardDecoration(context),
          child: Text(
            'Habilita o suspende cuentas de caja al instante, y selecciona individualmente qué módulos tienen permitido visualizar en el rol limitado.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: state.cashiers.map((cashier) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: adminCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: palette.accent.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: palette.accent,
                          child: Text(
                            cashier.name
                                .substring(
                                  0,
                                  cashier.name.length >= 2
                                      ? 2
                                      : cashier.name.length,
                                )
                                .toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cashier.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Horario: ${cashier.shift}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cashier Active Switch
                        Switch(
                          value: cashier.active,
                          activeThumbColor: const Color(0xFF00B85C),
                          inactiveTrackColor: colors.borderStrong,
                          onChanged: (val) =>
                              state.toggleCashierActive(cashier.name),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: colors.border),
                    Text(
                      'Módulos y Permisos Habilitados:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Permissions Choice list
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          [
                            'Cobros',
                            'Asistencia',
                            'Ventas',
                            'Productos',
                            'Usuarios',
                            'Log lectura',
                          ].map((permission) {
                            final hasIt = cashier.permissions.contains(
                              permission,
                            );
                            return FilterChip(
                              label: Text(
                                permission,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: hasIt
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: hasIt,
                              selectedColor: palette.accent.withValues(
                                alpha: 0.16,
                              ),
                              checkmarkColor: palette.accent,
                              labelStyle: TextStyle(
                                color: hasIt
                                    ? palette.accent
                                    : colors.textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(
                                color: hasIt ? palette.accent : colors.border,
                              ),
                              backgroundColor: colors.surfaceAlt,
                              onSelected: (selected) {
                                state.toggleCashierPermission(
                                  cashier.name,
                                  permission,
                                );
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddCashierDialog(BuildContext context) {
    final colors = context.sasColors;
    final nameCtrl = TextEditingController();
    final shiftCtrl = TextEditingController(text: '08:00 - 16:00');
    final List<String> permissions = ['Cobros', 'Asistencia'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Registrar Cajero',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: shiftCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Turno de Horas',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Permisos Iniciales:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children:
                          [
                            'Cobros',
                            'Asistencia',
                            'Ventas',
                            'Productos',
                            'Usuarios',
                            'Log lectura',
                          ].map((perm) {
                            final hasIt = permissions.contains(perm);
                            return ChoiceChip(
                              label: Text(
                                perm,
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: hasIt,
                              selectedColor: palette.accent.withValues(
                                alpha: 0.18,
                              ),
                              labelStyle: TextStyle(
                                color: hasIt
                                    ? palette.accent
                                    : colors.textSecondary,
                                fontWeight: hasIt
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                              backgroundColor: colors.surfaceAlt,
                              side: BorderSide(
                                color: hasIt ? palette.accent : colors.border,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    permissions.add(perm);
                                  } else {
                                    permissions.remove(perm);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: roleFilledPillButtonStyle(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.accentInk,
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    // Add new cashier to state
                    state.cashiers.add(
                      CashierAccount(
                        name: nameCtrl.text.trim(),
                        shift: shiftCtrl.text.trim(),
                        permissions: permissions,
                        active: true,
                      ),
                    );
                    state.updateGymSettings(
                      state.graceDays,
                      state.alertDays,
                    ); // Forces notifyListeners
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Crear',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
