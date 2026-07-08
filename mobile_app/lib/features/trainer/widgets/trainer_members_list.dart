import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import 'trainer_shared_utils.dart';

class TrainerMembersList extends StatelessWidget {
  const TrainerMembersList({
    super.key,
    required this.palette,
    required this.state,
    required this.onGo,
  });

  final RolePalette palette;
  final GymState state;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final trainerStudents = state.assignedTrainerMembers.isNotEmpty
        ? state.assignedTrainerMembers
        : state.members.where((m) => m.assignedTrainer == 'Carlos M.').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Cockpit Entrenador',
          subtitle:
              'Supervisa el progreso físico, planifica rutinas y gestiona tu biblioteca técnica.',
          trailing: StatusPill(
            label: 'ACTIVO',
            color: palette.accent,
            solid: true,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.people_rounded,
                label: 'Mis Alumnos',
                value: '${trainerStudents.length}',
                note: 'Bajo tu tutela',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Entrenando Hoy',
                value:
                    '${trainerStudents.where((s) => s.isActiveInGym).length}',
                note: 'Presentes en sala',
                accent: const Color(0xFF00B85C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Alumnos Asignados',
          action: '${trainerStudents.length} activos',
        ),
        if (trainerStudents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: trainerCardDecoration(context),
            child: const Center(
              child: Text(
                'No tienes alumnos asignados.',
                style: TextStyle(
                  color: Color(0xFF6E6E6E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Column(
            children: trainerStudents.map((member) {
              Color statusColor;
              String statusLabel;
              if (member.state == 'active') {
                statusColor = const Color(0xFF00B85C);
                statusLabel = 'Al día';
              } else if (member.state == 'grace') {
                statusColor = const Color(0xFFFFB300);
                statusLabel = 'Día Gracia';
              } else {
                statusColor = const Color(0xFFFF3B30);
                statusLabel = 'Vencido';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onGo('student-details', {'member': member}),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: trainerCardDecoration(context),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: member.isActiveInGym
                              ? const Color(0xFF00B85C).withValues(alpha: 0.15)
                              : palette.accent.withValues(alpha: 0.12),
                          foregroundColor: member.isActiveInGym
                              ? const Color(0xFF00B85C)
                              : palette.accent,
                          child: Text(
                            member.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (member.isActiveInGym) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00B85C),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${member.goal} · Sesiones: ${member.sessions}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF6D6D6D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              member.isActiveInGym
                                  ? 'En Sala'
                                  : 'Última: ${member.lastSeen}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: member.isActiveInGym
                                    ? const Color(0xFF00B85C)
                                    : const Color(0xFF6D6D6D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            StatusPill(label: statusLabel, color: statusColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
