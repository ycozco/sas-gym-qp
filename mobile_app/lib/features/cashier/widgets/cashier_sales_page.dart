import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class CashierSalesPage extends StatelessWidget {
  const CashierSalesPage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final cashierSalesLogs = state.auditLogs
        .where(
          (log) =>
              log.actor.contains('Caja') &&
              (log.action.contains('Venta') || log.action.contains('Cobró')),
        )
        .toList();

    double totalTurnRevenue = cashierSalesLogs.fold(0, (sum, log) {
      final reg = RegExp(r'S/\s*([0-9.]+)');
      final match = reg.firstMatch(log.detail);
      if (match != null) {
        return sum + (double.tryParse(match.group(1)!) ?? 0.0);
      }
      return sum;
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Ventas de Caja',
          subtitle:
              'Historial de ventas y movimientos registrados en este turno.',
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _posStatBox(
                  context,
                  'Ventas Totales',
                  '${cashierSalesLogs.length}',
                  'registradas',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _posStatBox(
                  context,
                  'Recaudacion',
                  'S/ ${totalTurnRevenue.toStringAsFixed(2)}',
                  'en caja',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const SectionHeader(
          title: 'Historial del Turno',
          action: 'Solicitar anulación',
        ),
        if (cashierSalesLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                'No has realizado ventas en este turno.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Column(
            children: cashierSalesLogs.map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_rounded, color: colors.accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.action,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.detail,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          log.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Solicitud de anulación enviada al Administrador para: ${log.action}',
                                ),
                                backgroundColor: palette.accent,
                              ),
                            );
                          },
                          child: Text(
                            'Anular',
                            style: TextStyle(
                              color: colors.danger,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _posStatBox(
    BuildContext context,
    String title,
    String val,
    String note,
  ) {
    final colors = context.sasColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(note, style: TextStyle(fontSize: 10, color: colors.textMuted)),
        ],
      ),
    );
  }
}
