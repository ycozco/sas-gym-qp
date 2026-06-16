import 'package:flutter/material.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';

class MemberAgendaPage extends StatelessWidget {
  const MemberAgendaPage({
    super.key,
    required this.palette,
    required this.onGo,
  });

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final colors = context.sasColors;
    final activeRoutine = state.activeRoutine;
    final template = activeRoutine?['template'] as Map<String, dynamic>?;
    final routineExercises =
        (template?['ejercicios'] as List<dynamic>? ?? const <dynamic>[]);
    final mappedExercises = routineExercises.map((item) {
      final row = item as Map<String, dynamic>;
      final exercise = row['exercise'] as Map<String, dynamic>? ?? const {};
      return ExerciseItem(
        name: exercise['nombre']?.toString() ?? 'Ejercicio',
        muscle: exercise['grupo_muscular']?.toString() ?? 'General',
        sets: (row['series'] as num?)?.toInt() ?? 4,
        reps: ((row['repeticiones'] as num?)?.toInt() ?? 10).toString(),
        weight: (row['peso_sugerido_kg'] as num?)?.toInt(),
        restSeconds: (row['descanso_seg'] as num?)?.toInt() ?? 60,
        icon: Icons.fitness_center_rounded,
        available: true,
      );
    }).toList();
    final scheduleRows = state.schedules.isNotEmpty
        ? state.schedules
        : memberWeek
              .map(
                (day) => {
                  'dia_semana': [day.number],
                  'nombre_clase': day.group,
                },
              )
              .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        const SectionHeader(title: 'Agenda Semanal'),
        const SizedBox(height: 4),

        // Week strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(context),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scheduleRows.take(7).map((raw) {
              final rawDays = (raw['dia_semana'] as List?) ?? const [];
              final dayNumber = rawDays.isNotEmpty
                  ? ((rawDays.first as num?)?.toInt() ?? 1)
                  : 1;
              final day =
                  memberWeek[(dayNumber - 1).clamp(0, memberWeek.length - 1)];
              return Container(
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: day.today ? palette.accent : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: day.today ? palette.accent : colors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      day.day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: day.today
                            ? palette.accentInk
                            : const Color(0xFF747474),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day.number}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: day.today
                            ? palette.accentInk
                            : const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      raw['nombre_clase']?.toString() ?? day.group,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: day.today
                            ? palette.accentInk.withValues(alpha: 0.85)
                            : const Color(0xFF7C7C7C),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),

        // Active workout details
        const SectionHeader(title: 'Rutina del Día'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(
                    label: 'DÍA 1 (HOY)',
                    color: const Color(0xFF0B0B0B),
                    solid: true,
                  ),
                  const Spacer(),
                  StatusPill(
                    label: mappedExercises.isNotEmpty
                        ? '${mappedExercises.length} ejercicios'
                        : '45-50 min',
                    color: const Color(0xFF0066FF),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                template?['nombre']?.toString() ?? 'Push · Pecho + Hombros',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mappedExercises.isNotEmpty
                    ? (template?['descripcion']?.toString() ??
                          'Rutina activa sincronizada desde el backend.')
                    : '6 ejercicios asignados · Enfocado en desarrollo de fuerza de empuje.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onGo('assistant'),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text(
                  'Iniciar Asistente',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: roleFilledPillButtonStyle(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.accentInk,
                  minimumHeight: 52,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        const SectionHeader(title: 'Ejercicios de la Rutina'),
        Column(
          children: (mappedExercises.isNotEmpty ? mappedExercises : memberExercises)
              .map((exercise) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: _cardDecoration(context),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: palette.accent.withValues(alpha: 0.12),
                        foregroundColor: palette.accent,
                        child: Icon(exercise.icon, size: 18),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${exercise.sets} series × ${exercise.reps} reps · ${exercise.weight != null ? "${exercise.weight} kg" : "Al fallo"} · descanso: ${exercise.restSeconds}s',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFFCDCDCD),
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return themedCardDecoration(context, radius: 12);
  }
}
