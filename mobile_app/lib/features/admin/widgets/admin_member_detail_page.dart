import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminMemberDetailPage extends StatelessWidget {
  const AdminMemberDetailPage({
    super.key,
    required this.palette,
    required this.state,
    required this.memberDni,
    required this.onBack,
    required this.onEdit,
  });

  final RolePalette palette;
  final GymState state;
  final String memberDni;
  final VoidCallback onBack;
  final Function(MemberRecord) onEdit;

  @override
  Widget build(BuildContext context) {
    // Find member
    final idx = state.allMembersIncludingSoftDeleted.indexWhere(
      (m) => m.dni == memberDni,
    );
    if (idx == -1) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Socio no encontrado: $memberDni')),
      );
    }
    final member = state.allMembersIncludingSoftDeleted[idx];

    Color statusColor = const Color(0xFF00B85C);
    String statusLabel = 'Activo';
    if (member.state == 'expired') {
      statusColor = const Color(0xFFFF3B30);
      statusLabel = 'Vencido';
    } else if (member.state == 'grace') {
      statusColor = const Color(0xFFFFB300);
      statusLabel = 'Gracia';
    } else if (member.state == 'baja_logica') {
      statusColor = const Color(0xFFFF7A1A);
      statusLabel = 'Baja Lógica';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: onBack,
        ),
        title: const Text(
          'Ficha de Socio',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => onEdit(member),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: adminCardDecoration(),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: palette.accent.withValues(alpha: 0.12),
                  child: Text(
                    member.name
                        .substring(
                          0,
                          member.name.length >= 2 ? 2 : member.name.length,
                        )
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'DNI: ${member.dni}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 12),
                StatusPill(
                  label: statusLabel.toUpperCase(),
                  color: statusColor,
                  solid: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details List
          const SectionHeader(title: 'Datos Personales'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: adminCardDecoration(),
            child: Column(
              children: [
                _infoRow(
                  Icons.phone_rounded,
                  'Celular',
                  member.phone.isEmpty ? 'No registrado' : member.phone,
                ),
                const Divider(height: 20, color: Color(0xFF2E2E38)),
                _infoRow(
                  Icons.email_rounded,
                  'Correo',
                  member.email.isEmpty ? 'No registrado' : member.email,
                ),
                const Divider(height: 20, color: Color(0xFF2E2E38)),
                _infoRow(
                  Icons.calendar_today_rounded,
                  'Fecha de Registro',
                  member.startDate,
                ),
                const Divider(height: 20, color: Color(0xFF2E2E38)),
                _infoRow(
                  Icons.flag_rounded,
                  'Objetivo',
                  member.goal.isEmpty ? 'No definido' : member.goal,
                ),
                const Divider(height: 20, color: Color(0xFF2E2E38)),
                _infoRow(
                  Icons.person_pin_rounded,
                  'Entrenador Asignado',
                  member.assignedTrainer.isEmpty
                      ? 'Ninguno'
                      : member.assignedTrainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment History
          SectionHeader(
            title: 'Historial de Pagos',
            action: '${member.paymentHistory.length} transacciones',
          ),
          if (member.paymentHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: adminCardDecoration(),
              child: const Center(
                child: Text(
                  'No registra pagos aprobados o pendientes.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Column(
              children: member.paymentHistory.map((pay) {
                Color pColor = const Color(0xFF00B85C);
                String pLabel = 'Aprobado';
                if (pay.state == 'pending') {
                  pColor = const Color(0xFFFFB300);
                  pLabel = 'Pendiente';
                } else if (pay.state == 'rejected') {
                  pColor = const Color(0xFFFF3B30);
                  pLabel = 'Rechazado';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: adminCardDecoration(),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_rounded, color: pColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pay.planName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pay.date} · Método: ${pay.method}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11.5,
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
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusPill(
                            label: pLabel.toUpperCase(),
                            color: pColor,
                            solid: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),

          // Suspension Actions
          if (member.state != 'baja_logica') ...[
            ElevatedButton(
              style: roleFilledPillButtonStyle(
                backgroundColor: const Color(0xFF2C0F14),
                foregroundColor: const Color(0xFFFF5252),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                state.toggleMemberLogicDelete(member.dni);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Socio ${member.name} marcado como BAJA LÓGICA.',
                    ),
                  ),
                );
                onBack();
              },
              child: const Text(
                'Dar de Baja Lógica (Suspender)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            ElevatedButton(
              style: roleFilledPillButtonStyle(
                backgroundColor: const Color(0xFF0F2C1E),
                foregroundColor: const Color(0xFF52FF9A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                state.toggleMemberLogicDelete(member.dni);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Socio ${member.name} reactivado con éxito.'),
                  ),
                );
                onBack();
              },
              child: const Text(
                'Reactivar Socio (Quitar Suspensión)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, color: Colors.white30, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Expanded(
          child: Text(
            val,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
