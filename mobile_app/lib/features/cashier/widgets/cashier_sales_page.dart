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
    final cashierSales = state.cashierSales;

    final totalTurnRevenue = cashierSales.fold<double>(
      0,
      (sum, sale) => sum + ((sale['amount'] as num?)?.toDouble() ?? 0),
    );

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
                  '${cashierSales.length}',
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

        SectionHeader(
          title: 'Historial del Turno',
          action: 'Actualizar',
          onTap: () => state.loadCajaSalesBackend(),
        ),
        if (cashierSales.isEmpty)
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
            children: cashierSales.map((sale) {
              final amount = (sale['amount'] as num?)?.toDouble() ?? 0;
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
                            sale['title']?.toString() ?? 'Venta',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sale['detail']?.toString() ?? '',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'S/ ${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          sale['time']?.toString() ?? '',
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
                                  'Solicitud de anulación enviada al Administrador para: ${sale['title'] ?? 'venta'}',
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
