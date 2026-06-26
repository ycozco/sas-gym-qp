import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import 'trainer_shared_utils.dart';

class TrainerProfileTab extends StatelessWidget {
  const TrainerProfileTab({
    super.key,
    required this.palette,
    required this.onGo,
  });

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
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
                child: const Text(
                  'CM',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Carlos Mendoza',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Entrenador Elite · Sede Providencia',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.star_rate_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                  Icon(
                    Icons.star_rate_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                  Icon(
                    Icons.star_rate_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                  Icon(
                    Icons.star_rate_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                  Icon(
                    Icons.star_rate_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '4.9 (53 alumnos)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
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
              _rowProfileInfo('Turno', 'Lunes a Viernes · 08:00 - 16:00'),
              _rowProfileInfo(
                'Especialidad',
                'Hipertrofia, Fuerza y Biomecánica',
              ),
              _rowProfileInfo(
                'Certificación',
                'NSCA - Certified Personal Trainer',
              ),
              _rowProfileInfo('Email', 'carlos.mendoza@sasgym.com'),
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
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
