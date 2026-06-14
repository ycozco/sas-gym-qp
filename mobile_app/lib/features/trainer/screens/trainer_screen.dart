import 'package:flutter/material.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import '../../member/widgets/report_observation_view.dart';
import '../widgets/trainer_home_page.dart';
import '../widgets/trainer_member_detail.dart';
import '../widgets/trainer_routine_editor.dart';
import '../widgets/trainer_exercise_library_tab.dart';
import '../widgets/trainer_templates_tab.dart';
import '../widgets/trainer_progress_tab.dart';
import '../widgets/trainer_profile_tab.dart';

class TrainerScreen extends StatefulWidget {
  const TrainerScreen({super.key});

  @override
  State<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends State<TrainerScreen> {
  int _currentTab = 0;
  final List<Map<String, dynamic>> _historyStack = [];

  // Local storage for trainer's custom exercises
  final List<ExerciseItem> _localExercises = List.from(exerciseLibrary);

  // Local storage for routine templates
  final List<Map<String, dynamic>> _routineTemplates = [
    {
      'name': 'Rutina A: Fuerza Pecho',
      'muscle': 'Pecho / Hombro',
      'exercises': ['Press de banca', 'Press militar', 'Aperturas en máquina']
    },
    {
      'name': 'Rutina B: Hipertrofia Pierna',
      'muscle': 'Cuádriceps / Glúteo',
      'exercises': ['Sentadilla con barra', 'Hip thrust', 'Prensa inclinada']
    },
    {
      'name': 'Rutina C: Espalda & Pull',
      'muscle': 'Espalda / Bíceps',
      'exercises': ['Peso muerto convencional', 'Remo con barra', 'Curl bíceps mancuerna']
    },
  ];

  // Selected student's notes
  final Map<String, String> _studentNotes = {
    '12345678': 'Restricción: evitar press tras nuca por molestia en manguito rotador izquierdo.',
    '87654321': 'Objetivo: pérdida de grasa. Cuidar rodilla derecha en sentadillas profundas.',
    '11223344': 'Fuerza máxima. Sin lesiones reportadas.',
    '44332211': 'Tonificación general. Hipermovilidad en codos.',
  };

  void _go(String screen, [Map<String, dynamic>? params]) {
    setState(() {
      _historyStack.add({'screen': screen, 'params': params});
    });
  }

  void _back() {
    if (_historyStack.isNotEmpty) {
      setState(() {
        _historyStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final palette = rolePalettes[GymRole.trainer]!;
    final backendTemplates = state.trainerTemplates.map((item) {
      final exercises = (item['ejercicios'] as List<dynamic>? ?? const [])
          .map((entry) {
            final row = entry as Map<String, dynamic>;
            final exercise = row['exercise'] as Map<String, dynamic>? ?? const {};
            return exercise['nombre']?.toString() ?? 'Ejercicio';
          })
          .toList();
      return {
        'id': item['id']?.toString() ?? '',
        'name': item['nombre']?.toString() ?? 'Plantilla',
        'muscle': item['descripcion']?.toString() ?? 'General',
        'exercises': exercises,
      };
    }).toList();
    final effectiveTemplates =
        backendTemplates.isNotEmpty ? backendTemplates : _routineTemplates;

    Widget? activeView;

    if (_historyStack.isNotEmpty) {
      final top = _historyStack.last;
      final String screen = top['screen'];
      final Map<String, dynamic>? params = top['params'];

      if (screen == 'student-details') {
        final member = params?['member'] as MemberRecord;
        activeView = StudentDetailsView(
          palette: palette,
          member: member,
          notes: _studentNotes[member.dni] ?? 'Sin restricciones médicas.',
          onSaveNote: (newNote) {
            setState(() {
              _studentNotes[member.dni] = newNote;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Nota médica guardada correctamente'),
                backgroundColor: palette.accent,
              ),
            );
          },
          onBack: _back,
          onGo: _go,
        );
      } else if (screen == 'assign-routine') {
        final member = params?['member'] as MemberRecord;
        activeView = AssignRoutineView(
          palette: palette,
          member: member,
          templates: effectiveTemplates,
          onBack: _back,
        );
      } else if (screen == 'report-observation') {
        activeView = ReportObservationView(
          palette: palette,
          onBack: _back,
        );
      }
    }

    if (activeView != null) {
      return Column(
        children: [
          Expanded(child: activeView),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildTab(_currentTab, state, palette, key: ValueKey<int>(_currentTab)),
            ),
          ),
          RoleNavBar(
            currentIndex: _currentTab,
            accent: palette.accent,
            accentInk: palette.accentInk,
            onChanged: (index) => setState(() => _currentTab = index),
            items: const [
              RoleNavItem(icon: Icons.people_outline_rounded, label: 'Alumnos'),
              RoleNavItem(icon: Icons.menu_book_rounded, label: 'Biblioteca'),
              RoleNavItem(icon: Icons.assignment_outlined, label: 'Plantillas'),
              RoleNavItem(icon: Icons.bar_chart_rounded, label: 'Progreso'),
              RoleNavItem(icon: Icons.person_outline_rounded, label: 'Perfil'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int tab, GymState state, RolePalette palette, {Key? key}) {
    final backendExercises = state.trainerExercises.map((item) {
      return ExerciseItem(
        id: item['id']?.toString(),
        name: item['nombre']?.toString() ?? 'Ejercicio',
        muscle: item['grupo_muscular']?.toString() ?? 'General',
        sets: 4,
        reps: '10',
        weight: null,
        restSeconds: 60,
        icon: Icons.fitness_center_rounded,
        available: item['activo'] != false,
      );
    }).toList();
    final effectiveExercises =
        backendExercises.isNotEmpty ? backendExercises : _localExercises;
    final backendTemplates = state.trainerTemplates.map((item) {
      final exercises = (item['ejercicios'] as List<dynamic>? ?? const [])
          .map((entry) {
            final row = entry as Map<String, dynamic>;
            final exercise = row['exercise'] as Map<String, dynamic>? ?? const {};
            return exercise['nombre']?.toString() ?? 'Ejercicio';
          })
          .toList();
      return {
        'id': item['id']?.toString() ?? '',
        'name': item['nombre']?.toString() ?? 'Plantilla',
        'muscle': item['descripcion']?.toString() ?? 'General',
        'exercises': exercises,
      };
    }).toList();
    final effectiveTemplates =
        backendTemplates.isNotEmpty ? backendTemplates : _routineTemplates;

    switch (tab) {
      case 0:
        return TrainerHomePage(
          key: key,
          palette: palette,
          state: state,
          onGo: _go,
        );
      case 1:
        return TrainerExerciseLibraryTab(
          key: key,
          palette: palette,
          exercises: effectiveExercises,
          onAddExercise: (newEx) async {
            if (state.currentUser?.rol == GymRole.trainer) {
              await state.createTrainerExercise(
                nombre: newEx.name,
                grupoMuscular: newEx.muscle,
              );
            } else {
              setState(() {
                _localExercises.insert(0, newEx);
              });
            }
            state.addAnnouncement('ENTRENAMIENTO', 'Nuevo ejercicio: ${newEx.name}', 'Se agregó ${newEx.name} a la biblioteca global.');
          },
        );
      case 2:
        return TrainerTemplatesTab(
          key: key,
          palette: palette,
          templates: effectiveTemplates,
          onAddTemplate: (name, muscle, exercises) async {
            if (state.currentUser?.rol == GymRole.trainer &&
                state.trainerExercises.isNotEmpty) {
              final payload = exercises
                  .map((exerciseName) {
                    final match = state.trainerExercises.cast<Map<String, dynamic>?>().firstWhere(
                      (item) => item?['nombre']?.toString() == exerciseName,
                      orElse: () => null,
                    );
                    if (match == null) return null;
                    return {
                      'exerciseId': match['id'],
                      'orden': exercises.indexOf(exerciseName) + 1,
                      'series': 4,
                      'repeticiones': 10,
                      'descansoSeg': 60,
                    };
                  })
                  .whereType<Map<String, dynamic>>()
                  .toList();
              if (payload.isNotEmpty) {
                await state.createTrainerTemplate(
                  nombre: name,
                  descripcion: muscle,
                  ejercicios: payload,
                );
                return;
              }
            }
            setState(() {
              _routineTemplates.add({
                'name': name,
                'muscle': muscle,
                'exercises': exercises,
              });
            });
          },
        );
      case 3:
        return TrainerProgressTab(
          key: key,
          palette: palette,
          progress: state.trainerProgress,
        );
      default:
        return TrainerProfileTab(
          key: key,
          palette: palette,
          onGo: _go,
        );
    }
  }
}
