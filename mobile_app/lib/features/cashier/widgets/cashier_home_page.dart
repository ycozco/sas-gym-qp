import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class CashierHomePage extends StatelessWidget {
  const CashierHomePage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final myLogs = state.auditLogs
        .where((log) => log.actor.contains('Caja'))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Caja y Accesos',
          subtitle:
              'Valida ingresos, cobra operaciones y deja trazabilidad inmediata.',
          trailing: StatusPill(
            label: 'TURNO EN CURSO',
            color: palette.accent,
            solid: true,
          ),
        ),
        const SizedBox(height: 18),
        _TurnSummary(palette: palette, logs: myLogs),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Asistencias Hoy',
                value: '${state.members.where((m) => m.todayCheckIn).length}',
                note: 'En este turno',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                icon: Icons.inventory_2_outlined,
                label: 'Stock Crítico',
                value: '${state.products.where((p) => p.stock < 20).length}',
                note: 'Menos de 20 un.',
                accent: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Operación Auditada'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: themedCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security_rounded, color: colors.info, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Operas bajo perfil de Cajero Autorizado.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Todas las transacciones de ventas y aprobaciones de asistencia son registradas con tu firma digital en la bitácora global del administrador.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Mis logs de auditoría',
          action: '${myLogs.length} hoy',
        ),
        if (myLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: themedCardDecoration(context),
            child: Center(
              child: Text(
                'No has registrado movimientos en este turno.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Column(
            children: myLogs.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LogTile(
                  icon:
                      entry.action.contains('Cobró') ||
                          entry.action.contains('Venta')
                      ? Icons.point_of_sale_rounded
                      : Icons.qr_code_scanner_rounded,
                  title: entry.action,
                  detail: entry.detail,
                  time: entry.time,
                  color: entry.color,
                  locked: true,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _TurnSummary extends StatelessWidget {
  const _TurnSummary({required this.palette, required this.logs});

  final RolePalette palette;
  final List<AuditEntry> logs;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final chargeLogs = logs.where(
      (l) => l.action.contains('Cobró') || l.action.contains('Venta'),
    );
    double revenue = 0;
    final reg = RegExp(r'S/\s*([0-9.]+)');
    for (var l in chargeLogs) {
      final match = reg.firstMatch(l.detail);
      if (match != null) {
        revenue += double.tryParse(match.group(1)!) ?? 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: themedCardDecoration(context, color: colors.surfaceElevated),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SALDO DEL TURNO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                  color: palette.accent,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: 'CIERRA 14:00',
                color: palette.accent,
                solid: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'S/ ${revenue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${chargeLogs.length} transacciones registradas en este turno.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
