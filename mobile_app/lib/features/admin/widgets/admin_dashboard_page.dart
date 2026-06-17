import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.palette,
    required this.state,
    required this.onGoApprovals,
    required this.onGoCreateMember,
    required this.onGoSettings,
    required this.onGoAuditLogs,
    required this.onGoCajaAudit,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onGoApprovals;
  final VoidCallback onGoCreateMember;
  final VoidCallback onGoSettings;
  final VoidCallback onGoAuditLogs;
  final VoidCallback onGoCajaAudit;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    // Count pending payments
    int pendingCount = 0;
    for (var m in state.allMembersIncludingSoftDeleted) {
      pendingCount += m.paymentHistory
          .where((p) => p.state == 'pending')
          .length;
    }

    // Dynamic metrics
    final activeCount = state.members
        .where((m) => m.state == 'active' || m.state == 'grace')
        .length;
    final totalMembersCount = state.members.length;
    final insideNowCount = state.members.where((m) => m.isActiveInGym).length;

    // Calculate revenue (approved payments)
    double totalRevenue = 0;
    for (var m in state.allMembersIncludingSoftDeleted) {
      for (var p in m.paymentHistory) {
        if (p.state == 'approved') {
          totalRevenue += p.price;
        }
      }
    }

    final int activeCajasCount = state.cashiers.where((c) => c.shift.toLowerCase() == 'abierta').length;

    return ListView(
      key: const PageStorageKey<String>('admin-dashboard'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Centro de Control',
          subtitle:
              'Administra socios, caja, auditoría y configuración global del gimnasio.',
          trailing: StatusPill(
            label: 'ADMIN',
            color: palette.accent,
            solid: true,
          ),
        ),
        const SizedBox(height: 18),

        if (pendingCount > 0) ...[
          GestureDetector(
            onTap: onGoApprovals,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2C0F14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bandeja de Pagos ($pendingCount pendientes)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hay comprobantes manuales de socios esperando tu validación.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF8A80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],

        Row(
          children: [
            Expanded(
              child: AdminMetric(
                label: 'Socios Activos',
                value: '$activeCount',
                note: 'Total: $totalMembersCount registrados',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminMetric(
                label: 'Adentro Ahora',
                value: '$insideNowCount',
                note: 'Check-ins activos',
                accent: const Color(0xFF00B85C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminMetric(
                label: 'Recaudado Total',
                value: 'S/ ${totalRevenue.toStringAsFixed(0)}',
                note: 'Planes aprobados',
                accent: const Color(0xFFFF7A1A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onGoCajaAudit,
                child: AdminMetric(
                  label: 'Cajas y Cuadre',
                  value: '$activeCajasCount',
                  note: '$activeCajasCount abiertas · Pulsa para auditar',
                  accent: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Acciones Rápidas'),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Crear Socio',
                note: 'Formulario de alta',
                accent: palette.accent,
                onTap: onGoCreateMember,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionTile(
                icon: Icons.point_of_sale_rounded,
                label: 'Control de Caja',
                note: 'Turnos y descuadres',
                accent: palette.accent,
                onTap: onGoCajaAudit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.settings_rounded,
                label: 'Ajustes',
                note: 'Días de gracia y reglas',
                accent: palette.accent,
                onTap: onGoSettings,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionTile(
                icon: Icons.rate_review_rounded,
                label: 'Comprobantes',
                note: 'Bandeja de pagos',
                accent: palette.accent,
                onTap: onGoApprovals,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.fact_check_outlined,
                label: 'Auditoría',
                note: 'Bitácora general',
                accent: palette.accent,
                onTap: onGoAuditLogs,
              ),
            ),
            const SizedBox(width: 10),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Resumen de Control'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: adminCardDecoration(context),
          child: Text(
            'Como administrador, controlas de forma global los cajeros, autorizaciones de dinero, el catálogo de productos y el alta o baja física/lógica de usuarios. Monitorea las acciones en tiempo real mediante la Bitácora de Auditoría.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class AdminMetric extends StatelessWidget {
  const AdminMetric({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    required this.accent,
  });

  final String label;
  final String value;
  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: adminCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: TextStyle(
              fontSize: 11,
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration adminCardDecoration([BuildContext? context]) {
  final colors = context?.sasColors;
  return BoxDecoration(
    color: colors?.surface ?? const Color(0xFF16161A),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: colors?.border ?? const Color(0xFF2E2E38),
      width: 1.0,
    ),
  );
}
