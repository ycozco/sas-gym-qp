import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import 'member_shared_utils.dart';

class MemberSubscriptionPage extends StatelessWidget {
  const MemberSubscriptionPage({
    super.key,
    required this.palette,
    required this.onGo,
  });

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = getLoggedMember(state);
    final currentMembership = state.currentUser?.memberships?.isNotEmpty == true
        ? Map<String, dynamic>.from(
            state.currentUser!.memberships!.first as Map,
          )
        : null;
    final balance =
        state.memberPointsSummary?['balance'] as Map<String, dynamic>?;
    final planName =
        currentMembership?['plan_nombre']?.toString() ?? 'Plan Actual';
    final startDate =
        currentMembership?['fecha_inicio']?.toString().split('T').first ?? '—';
    final endDate =
        currentMembership?['fecha_vencimiento']?.toString().split('T').first ??
        '—';
    final totalPaid = (currentMembership?['monto'] as num?)?.toDouble() ?? 0;
    final points = (balance?['puntos_disponibles'] as num?)?.toInt() ?? 0;
    final earnedPoints =
        (balance?['puntos_totales_ganados'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        const SectionHeader(title: 'Mi Membresía'),
        const SizedBox(height: 4),

        // Progress card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Plan Actual: $planName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  StatusPill(
                    label: mateo.state.toUpperCase(),
                    color: mateo.state == 'active'
                        ? const Color(0xFF00B85C)
                        : mateo.state == 'grace'
                        ? const Color(0xFFFFB300)
                        : Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Vigencia: del $startDate al $endDate',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(height: 16),
              // Linear indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: mateo.state == 'active'
                      ? 0.45
                      : (mateo.state == 'grace' ? 0.05 : 0.0),
                  backgroundColor: const Color(0xFFF0EFE9),
                  color: palette.accent,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    mateo.state == 'active'
                        ? '14 días restantes'
                        : '0 días restantes',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'S/ ${totalPaid.toStringAsFixed(2)} pagados',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumHeight: 50,
                ),
                onPressed: () => onGo('pay'),
                child: const Text(
                  'Renovar / Pagar Membresía',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        const SectionHeader(title: 'Puntos y Fidelización'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.stars_rounded,
                  label: 'Disponibles',
                  value: '$points',
                  note: 'Saldo actual',
                  accent: palette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Ganados',
                  value: '$earnedPoints',
                  note: 'Histórico',
                  accent: const Color(0xFF0066FF),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        const SectionHeader(title: 'Historial de Pagos'),
        Column(
          children: mateo.paymentHistory.reversed.map((pay) {
            Color stateColor = const Color(0xFF00B85C);
            String stateText = 'Aprobado';
            if (pay.state == 'pending') {
              stateColor = const Color(0xFFFFB300);
              stateText = 'Pendiente';
            } else if (pay.state == 'rejected') {
              stateColor = Colors.redAccent;
              stateText = 'Rechazado';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        pay.method == 'Tarjeta'
                            ? Icons.credit_card_rounded
                            : Icons.phone_android_rounded,
                        color: stateColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pay.planName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pay.date} · vía ${pay.method}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF7A7A7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'S/ ${pay.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusPill(label: stateText, color: stateColor),
                      ],
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

  BoxDecoration _cardDecoration(BuildContext context) {
    return themedCardDecoration(context, radius: 12);
  }
}
