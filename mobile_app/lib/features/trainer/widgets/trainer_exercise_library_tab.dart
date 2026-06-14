import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/exercise_anim.dart';
import 'trainer_shared_utils.dart';

class TrainerExerciseLibraryTab extends StatefulWidget {
  const TrainerExerciseLibraryTab({
    super.key,
    required this.palette,
    required this.exercises,
    required this.onAddExercise,
  });

  final RolePalette palette;
  final List<ExerciseItem> exercises;
  final Function(ExerciseItem) onAddExercise;

  @override
  State<TrainerExerciseLibraryTab> createState() => _TrainerExerciseLibraryTabState();
}

class _TrainerExerciseLibraryTabState extends State<TrainerExerciseLibraryTab> {
  String _searchQuery = '';
  String _selectedMuscle = 'Todos';
  String? _expandedExerciseName;

  final List<String> _muscleFilters = ['Todos', 'Pecho', 'Hombro', 'Pierna', 'Espalda', 'Bíceps', 'Tríceps'];

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final filtered = widget.exercises.where((ex) {
      final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscle == 'Todos' || ex.muscle == _selectedMuscle;
      return matchesSearch && matchesMuscle;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          SectionHeader(
            title: 'Biblioteca Técnica',
            action: '${widget.exercises.length} Ejercicios',
          ),
          const SizedBox(height: 10),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textMuted,
                ),
                hintText: 'Buscar ejercicio...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Muscle Chips filter scroll
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _muscleFilters.length,
              itemBuilder: (context, index) {
                final muscle = _muscleFilters[index];
                final isSelected = _selectedMuscle == muscle;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      muscle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : colors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: widget.palette.accent,
                    backgroundColor: colors.surface,
                    side: BorderSide(color: colors.border),
                    shape: const StadiumBorder(),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedMuscle = muscle);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Add exercise quick action
          ElevatedButton.icon(
            style: roleOutlinedPillButtonStyle(
              foregroundColor: widget.palette.accent,
              backgroundColor: widget.palette.accent.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo Ejercicio a la Biblioteca', style: TextStyle(fontWeight: FontWeight.w900)),
            onPressed: () => _showAddExerciseDialog(context),
          ),
          const SizedBox(height: 18),

          // Exercises List
          Column(
            children: filtered.map((exercise) {
              final isExpanded = _expandedExerciseName == exercise.name;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: trainerCardDecoration(context),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: widget.palette.accent.withValues(alpha: 0.12),
                          foregroundColor: widget.palette.accent,
                          child: Icon(exercise.icon, size: 18),
                        ),
                        title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${exercise.muscle} · ${exercise.sets}×${exercise.reps} · ${exercise.weight ?? 0}kg'),
                        trailing: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                        onTap: () {
                          setState(() {
                            _expandedExerciseName = isExpanded ? null : exercise.name;
                          });
                        },
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              const Divider(height: 1, color: Color(0xFFE8E4D9)),
                              const SizedBox(height: 12),
                              // Simulated stick figure animations
                              const Text(
                                'Visualización de Ejecución Técnica (Simulado)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF888888)),
                              ),
                              const SizedBox(height: 10),
                              ExerciseAnim(
                                exerciseName: exercise.name,
                                size: 140,
                                active: true,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Guía técnica: mantener columna neutral y controlar el tempo (3s excéntrica, 1s pausa, 1s concéntrica).',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final colors = context.sasColors;
    String name = '';
    String muscle = 'Pecho';
    int sets = 4;
    String reps = '10';
    double weight = 20.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.border),
              ),
              title: const Text('Nuevo Ejercicio', style: TextStyle(fontWeight: FontWeight.w900)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nombre del Ejercicio'),
                      onChanged: (val) => name = val,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: muscle,
                      items: _muscleFilters.where((m) => m != 'Todos').map((m) {
                        return DropdownMenuItem(value: m, child: Text(m));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => muscle = val);
                      },
                      decoration: const InputDecoration(labelText: 'Grupo Muscular'),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Series (ej. 4)'),
                      onChanged: (val) => sets = int.tryParse(val) ?? 4,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Repeticiones (ej. 10-12)'),
                      onChanged: (val) => reps = val,
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peso Inicial (kg)'),
                      onChanged: (val) => weight = double.tryParse(val) ?? 20.0,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: roleFilledPillButtonStyle(
                    backgroundColor: widget.palette.accent,
                    foregroundColor: widget.palette.accentInk,
                  ),
                  onPressed: () {
                    if (name.isNotEmpty) {
                      widget.onAddExercise(ExerciseItem(
                        name: name,
                        muscle: muscle,
                        sets: sets,
                        reps: reps,
                        weight: weight.toInt(),
                        restSeconds: 90,
                        icon: Icons.fitness_center_rounded,
                        available: true,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text('Agregar', style: TextStyle(color: widget.palette.accentInk)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
