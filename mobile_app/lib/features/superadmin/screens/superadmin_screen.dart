import 'package:flutter/material.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';

class SuperAdminScreen extends StatelessWidget {
  const SuperAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final clients = state.saClients;
    final palette = rolePalettes[GymRole.superadmin]!;

    final totalGyms = clients.length;
    final activeGyms = clients.where((c) => c.active).length;
    final suspendedGyms = totalGyms - activeGyms;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Panel del Super Administrador (SaaS)'),
          const SizedBox(height: 8),

          // SaaS KPI Metrics row
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.business,
                  label: 'Gimnasios Totales',
                  value: '$totalGyms',
                  note: 'Clientes en red',
                  accent: palette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.check_circle_outline,
                  label: 'Sedes Activas',
                  value: '$activeGyms',
                  note: 'Operando normalmente',
                  accent: const Color(0xFF00B85C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.lock_outline,
                  label: 'Suspendidos',
                  value: '$suspendedGyms',
                  note: 'Cortes por facturación',
                  accent: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Control de Sedes / Clientes SaaS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF202020),
            ),
          ),
          const SizedBox(height: 12),

          // Tenant list
          Expanded(
            child: ListView.separated(
              itemCount: clients.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final client = clients[index];
                final isCurrent = client.id == state.selectedClientId;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? palette.accent
                          : const Color(0xFFE2DDD5),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Logo Emoji
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: client.active
                              ? palette.accent.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          client.logo,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ACTUAL',
                                      style: TextStyle(
                                        color: palette.accentInk,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              client.location,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 13,
                                  color: Color(0xFF909090),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${client.membersCount} socios',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF858585),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action triggers
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Switch(
                            value: client.active,
                            activeThumbColor: const Color(0xFF00B85C),
                            activeTrackColor: const Color(
                              0xFF00B85C,
                            ).withValues(alpha: 0.25),
                            inactiveThumbColor: Colors.red,
                            inactiveTrackColor: Colors.red.withValues(
                              alpha: 0.25,
                            ),
                            onChanged: (val) {
                              state.toggleSaClient(client.id);
                            },
                          ),
                          Text(
                            client.active ? 'ACTIVO' : 'SUSPENDIDO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: client.active
                                  ? const Color(0xFF00B85C)
                                  : Colors.red,
                            ),
                          ),
                          if (client.active) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                state.selectClient(client.id);
                              },
                              child: Text(
                                'Simular Sede',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      palette.accent == const Color(0xFFE91E63)
                                      ? Colors.blue
                                      : palette.accent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
