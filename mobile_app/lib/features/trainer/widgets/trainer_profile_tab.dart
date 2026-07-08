import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import 'trainer_shared_utils.dart';

class TrainerProfileTab extends StatelessWidget {
  const TrainerProfileTab({
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
    final user = state.currentUser;
    final trainerProfile = user?.trainerProfile ?? const <String, dynamic>{};
    final name = user?.nombreCompleto ?? 'Entrenador';
    final email = user?.email ?? 'Sin correo registrado';
    final initials = _initials(name);
    final sede =
        trainerProfile['sede_nombre']?.toString() ??
        trainerProfile['sede']?.toString() ??
        'Sede sin registrar';
    final especialidad =
        trainerProfile['especialidad']?.toString() ??
        trainerProfile['especialidades']?.toString() ??
        'Sin especialidad registrada';
    final turno = trainerProfile['turno']?.toString() ?? 'Turno sin registrar';
    final certificacion =
        trainerProfile['certificacion']?.toString() ??
        'Certificación sin registrar';
    final rating = trainerProfile['rating']?.toString();
    final students = state.assignedTrainerMembers.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        SectionHeader(title: 'Perfil del Entrenador'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: trainerCardDecoration(context),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: palette.accent.withValues(alpha: 0.12),
                foregroundColor: palette.accent,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Entrenador · $sede',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFFFFB300),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      rating == null
                          ? '$students alumnos asignados'
                          : '$rating · $students alumnos',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: trainerCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información Operativa',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 14),
              _rowProfileInfo('Turno', turno),
              _rowProfileInfo('Especialidad', especialidad),
              _rowProfileInfo('Certificación', certificacion),
              _rowProfileInfo('Email', email),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: trainerCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Soporte e Incidencias',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: palette.accent.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.report_problem_rounded,
                      color: palette.accent,
                    ),
                  ),
                  title: const Text(
                    'Buzón de Incidencias',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Reporta daños en máquinas o áreas del local',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => onGo('report-observation'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowProfileInfo(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'EN';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}
