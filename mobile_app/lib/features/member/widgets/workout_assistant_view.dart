import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/exercise_anim.dart';
import 'log_effort_modal.dart';
import 'timer_ring.dart';

class WorkoutAssistantView extends StatefulWidget {
  const WorkoutAssistantView({
    super.key,
    required this.palette,
    required this.onBack,
  });

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<WorkoutAssistantView> createState() => _WorkoutAssistantViewState();
}

class _WorkoutAssistantViewState extends State<WorkoutAssistantView> {
  List<ExerciseItem> _exercises = [];
  bool _loading = true;
  String? _activeTemplateId;

  int _exerciseIndex = 0;
  int _setIndex = 0; // 0 to sets-1
  bool _isResting = false;
  int _restTimeRemaining = 0;
  Timer? _restTimer;

  // Track logs
  int _completedExercisesCount = 0;
  double _totalWeightLifted = 0.0;
  final List<String> _prAlerts = [];
  final List<Map<String, dynamic>> _loggedSeries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoutine();
    });
  }

  Future<void> _loadRoutine() async {
    try {
      final state = GymStateProvider.of(context);
      final routine = await state.loadActiveRoutine();
      if (routine != null) {
        final List<ExerciseItem> parsed = [];
        _activeTemplateId = routine['template_id'] as String?;
        final template = routine['template'];
        if (template != null && template['ejercicios'] != null) {
          final ejerciciosList = template['ejercicios'] as List;
          for (var item in ejerciciosList) {
            final exercise = item['exercise'];
            if (exercise != null) {
              parsed.add(ExerciseItem(
                id: exercise['id'] as String?,
                name: exercise['nombre'] ?? 'Ejercicio',
                muscle: exercise['grupo_muscular'] ?? 'General',
                sets: item['series'] ?? 4,
                reps: '${item['repeticiones']}',
                weight: item['peso_sugerido_kg'] != null ? (item['peso_sugerido_kg'] as num).toInt() : null,
                restSeconds: item['descanso_seg'] ?? 60,
                icon: Icons.fitness_center,
                available: exercise['activo'] ?? true,
              ));
            }
          }
        }
        if (parsed.isNotEmpty) {
          setState(() {
            _exercises = parsed;
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        _exercises = List.from(memberExercises);
        _loading = false;
      });
    } catch (e) {
      AppLogger.debug('Error loading active routine', e);
      setState(() {
        _exercises = List.from(memberExercises);
        _loading = false;
      });
    }
  }

  void _startRest(int seconds) {
    setState(() {
      _isResting = true;
      _restTimeRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 1) {
        setState(() {
          _restTimeRemaining--;
        });
      } else {
        _stopRest();
      }
    });
  }

  void _stopRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
  }

  void _addRestSeconds(int seconds) {
    setState(() {
      _restTimeRemaining += seconds;
    });
  }

  void _nextSet(ExerciseItem current) {
    _stopRest();

    // Accumulate stats
    _totalWeightLifted += (current.weight ?? 0) * (int.tryParse(current.reps.split('-')[0]) ?? 10);

    if (_setIndex < current.sets - 1) {
      setState(() {
        _setIndex++;
      });
      // Trigger rest ring countdown
      _startRest(current.restSeconds);
    } else {
      // Done with all sets of this exercise
      _completedExercisesCount++;
      _nextExercise();
    }
  }

  void _nextExercise() {
    _stopRest();
    if (_exerciseIndex < _exercises.length - 1) {
      setState(() {
        _exerciseIndex++;
        _setIndex = 0;
      });
    } else {
      // Finished workout! Save session
      _saveWorkoutSession();
      setState(() {
        _exerciseIndex = _exercises.length;
      });
    }
  }

  Future<void> _saveWorkoutSession() async {
    final state = GymStateProvider.of(context);
    final sessionData = {
      'templateId': _activeTemplateId ?? 'rutina_a_fuerza_general',
      'fecha': DateTime.now().toIso8601String(),
      'estado': 'COMPLETED',
      'seriesLog': _loggedSeries,
    };
    await state.saveWorkoutSession(sessionData);
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: widget.onBack,
          ),
          title: const Text(
            'CARGANDO RUTINA...',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2FF3A)),
          ),
        ),
      );
    }

    final totalExercises = _exercises.length;

    // Summary/Finished screen
    if (_exerciseIndex >= totalExercises) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2FF3A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events, size: 48, color: Colors.black),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡ENTRENAMIENTO COMPLETADO!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Has registrado con éxito tu sesión del día.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5),
                ),
                const SizedBox(height: 32),

                // Stats container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: Column(
                    children: [
                      _finishedStatRow('Ejercicios realizados', '$_completedExercisesCount / $totalExercises'),
                      const Divider(color: Color(0xFF2C2C2C), height: 24),
                      _finishedStatRow('Volumen levantado', '${_totalWeightLifted.round()} kg'),
                      const Divider(color: Color(0xFF2C2C2C), height: 24),
                      _finishedStatRow('Duración aproximada', '48 min'),
                      if (_prAlerts.isNotEmpty) ...[
                        const Divider(color: Color(0xFF2C2C2C), height: 24),
                        _finishedStatRow('Nuevos Récords (PR)', _prAlerts.first),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                ElevatedButton(
                  style: roleFilledPillButtonStyle(
                    backgroundColor: const Color(0xFFD2FF3A),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumHeight: 54,
                  ),
                  onPressed: () {
                    widget.onBack();
                  },
                  child: const Text('Volver a Inicio', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentExercise = _exercises[_exerciseIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            // Confirm quit
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF2C2C2C)),
                ),
                title: const Text('¿Abandonar entrenamiento?', style: TextStyle(color: Colors.white)),
                content: const Text('Tu progreso de series registradas hoy no se guardará.', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Continuar', style: TextStyle(color: Color(0xFFD2FF3A))),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onBack();
                    },
                    child: const Text('Salir', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          'ASISTENTE: EJERCICIO ${_exerciseIndex + 1} DE $totalExercises',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exercise core block
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        currentExercise.name,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Músculo: ${currentExercise.muscle} · Meta: ${currentExercise.sets} series de ${currentExercise.reps} reps',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),

                      // Set Pips
                      Row(
                        children: List.generate(currentExercise.sets, (idx) {
                          final isCompleted = idx < _setIndex;
                          final isActive = idx == _setIndex;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFFD2FF3A)
                                    : isActive
                                        ? const Color(0xFF0066FF)
                                        : const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Anim and Timer Stack
                      if (_isResting)
                        Center(
                          child: TimerRing(
                            secondsRemaining: _restTimeRemaining,
                            totalSeconds: currentExercise.restSeconds,
                            color: widget.palette.accent,
                          ),
                        )
                      else
                        Center(
                          child: ExerciseAnim(
                            exerciseName: currentExercise.name,
                            size: 190,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Giant control buttons
                  Column(
                    children: [
                      if (_isResting) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: roleOutlinedPillButtonStyle(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF3C3C3C)),
                                  minimumHeight: 60,
                                ),
                                onPressed: () => _addRestSeconds(15),
                                child: const Text('+15s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton(
                                style: roleFilledPillButtonStyle(
                                  backgroundColor: const Color(0xFF2C2C2C),
                                  foregroundColor: Colors.white,
                                  minimumHeight: 60,
                                ),
                                onPressed: _stopRest,
                                child: const Text('Saltar Descanso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          style: roleFilledPillButtonStyle(
                            backgroundColor: const Color(0xFFD2FF3A),
                            foregroundColor: Colors.black,
                            minimumHeight: 68,
                          ),
                          onPressed: () {
                            // Show effort logger dialog
                            showDialog(
                              context: context,
                              builder: (ctx) => LogEffortModal(
                                exerciseName: '${currentExercise.name} - Serie ${_setIndex + 1}',
                                defaultReps: currentExercise.reps,
                                defaultWeight: currentExercise.weight,
                                onSave: (reps, weight, rpe) {
                                  // Save this set's log
                                  _loggedSeries.add({
                                    'exerciseId': currentExercise.id ?? currentExercise.name,
                                    'serieNumero': _setIndex + 1,
                                    'pesoRealKg': weight.toDouble(),
                                    'repsReales': reps,
                                    'completada': true,
                                    'rpe': rpe,
                                  });
                                  // Update stats with real logged weight
                                  setState(() {
                                    if (weight > (currentExercise.weight ?? 0)) {
                                      _prAlerts.add('${currentExercise.name} a $weight kg!');
                                    }
                                  });
                                  _nextSet(currentExercise);
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle, size: 26),
                          label: Text(
                            'COMPLETAR SERIE ${_setIndex + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _nextExercise,
                          child: Text(
                            'Saltar Ejercicio',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _finishedStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
      ],
    );
  }
}
