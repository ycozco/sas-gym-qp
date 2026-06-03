import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
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
    final cashierSalesLogs = state.auditLogs
        .where((log) => log.actor.contains('Caja') && (log.action.contains('Venta') || log.action.contains('Cobró')))
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
          subtitle: 'Historial de ventas y movimientos registrados en este turno.',
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E2D8)),
          ),
          child: Row(
            children: [
              Expanded(child: _posStatBox('Ventas Totales', '${cashierSalesLogs.length}', 'registradas')),
              const SizedBox(width: 12),
              Expanded(child: _posStatBox('Recaudación', 'S/ ${totalTurnRevenue.toStringAsFixed(2)}', 'en caja')),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6E2D8)),
            ),
            child: const Center(
              child: Text(
                'No has realizado ventas en este turno.',
                style: TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.bold),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6E2D8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.action, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text(log.detail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(log.time, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Solicitud de anulación enviada al Administrador para: ${log.action}'),
                                backgroundColor: palette.accent,
                              ),
                            );
                          },
                          child: const Text(
                            'Anular',
                            style: TextStyle(
                              color: Colors.red,
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

  Widget _posStatBox(String title, String val, String note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E4D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF707070), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(note, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
