import 'package:flutter/material.dart';
import '../data/gym_seed.dart';
import '../data/gym_state.dart';
import '../models/gym_models.dart';
import '../widgets/app_shell.dart';
import '../widgets/shared_widgets.dart';
import '../features/member/screens/member_screen.dart';

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

    Widget? activeView;

    if (_historyStack.isNotEmpty) {
      final top = _historyStack.last;
      final String screen = top['screen'];
      final Map<String, dynamic>? params = top['params'];

      if (screen == 'student-details') {
        final member = params?['member'] as MemberRecord;
        activeView = _StudentDetailsView(
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
        activeView = _AssignRoutineView(
          palette: palette,
          member: member,
          templates: _routineTemplates,
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
    switch (tab) {
      case 0:
        return _TrainerMembersTab(
          key: key,
          palette: palette,
          state: state,
          onGo: _go,
        );
      case 1:
        return _TrainerExerciseLibraryTab(
          key: key,
          palette: palette,
          exercises: _localExercises,
          onAddExercise: (newEx) {
            setState(() {
              _localExercises.insert(0, newEx);
            });
            state.addAnnouncement('ENTRENAMIENTO', 'Nuevo ejercicio: ${newEx.name}', 'Se agregó ${newEx.name} a la biblioteca global.');
          },
        );
      case 2:
        return _TrainerTemplatesTab(
          key: key,
          palette: palette,
          templates: _routineTemplates,
          onAddTemplate: (name, muscle, exercises) {
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
        return _TrainerProgressTab(key: key, palette: palette);
      default:
        return _TrainerProfileTab(
          key: key,
          palette: palette,
          onGo: _go,
        );
    }
  }
}

// ==========================================
// TABS IMPLEMENTATION
// ==========================================

class _TrainerMembersTab extends StatelessWidget {
  const _TrainerMembersTab({
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
    // Show members assigned to Carlos M. or all members for mock testing
    final trainerStudents = state.members.where((m) => m.assignedTrainer == 'Carlos M.').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: palette.gradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(label: 'COCKPIT ENTRENADOR', color: palette.accent, solid: true),
              const SizedBox(height: 18),
              const Text(
                'Hola, Carlos M.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.7),
              ),
              const SizedBox(height: 6),
              Text(
                'Supervisa el progreso físico de tus alumnos, planifica sus rutinas y edita la biblioteca técnica.',
                style: TextStyle(fontSize: 13.5, color: Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
              ),
            ],
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
                value: '${trainerStudents.where((s) => s.isActiveInGym).length}',
                note: 'Presentes en sala',
                accent: const Color(0xFF00B85C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeader(title: 'Alumnos Asignados', action: '${trainerStudents.length} activos'),
        if (trainerStudents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: const Center(
              child: Text(
                'No tienes alumnos asignados.',
                style: TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.bold),
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: member.isActiveInGym
                              ? const Color(0xFF00B85C).withValues(alpha: 0.15)
                              : palette.accent.withValues(alpha: 0.12),
                          foregroundColor: member.isActiveInGym ? const Color(0xFF00B85C) : palette.accent,
                          child: Text(
                            member.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
                                  ]
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
                              member.isActiveInGym ? 'En Sala' : 'Última: ${member.lastSeen}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: member.isActiveInGym ? const Color(0xFF00B85C) : const Color(0xFF6D6D6D),
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

// ------------------------------------------
// STUDENT DETAILS SUB-VIEW
// ------------------------------------------
class _StudentDetailsView extends StatefulWidget {
  const _StudentDetailsView({
    required this.palette,
    required this.member,
    required this.notes,
    required this.onSaveNote,
    required this.onBack,
    required this.onGo,
  });

  final RolePalette palette;
  final MemberRecord member;
  final String notes;
  final Function(String) onSaveNote;
  final VoidCallback onBack;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  State<_StudentDetailsView> createState() => _StudentDetailsViewState();
}

class _StudentDetailsViewState extends State<_StudentDetailsView> {
  late TextEditingController _notesController;
  bool _isEditingNote = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          m.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Student Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: widget.palette.accent.withValues(alpha: 0.12),
                  foregroundColor: widget.palette.accent,
                  child: Text(
                    m.name.substring(0, 2).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 14),
                Text(m.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('DNI: ${m.dni} · ${m.email}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B6B))),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE8E4D9)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoStatColumn('Meta Principal', m.goal),
                    _infoStatColumn('Ingresó', m.startDate),
                    _infoStatColumn('Sesiones', '${m.sessions} completadas'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Injury warnings & Restrictions Notes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCCCC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Restricciones y Notas Médicas',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFFFF3B30)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(_isEditingNote ? Icons.save_rounded : Icons.edit_note_rounded,
                          color: const Color(0xFFFF3B30)),
                      onPressed: () {
                        if (_isEditingNote) {
                          widget.onSaveNote(_notesController.text);
                        }
                        setState(() {
                          _isEditingNote = !_isEditingNote;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _isEditingNote
                    ? TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Añade restricciones por lesión o cuidados especiales...',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      )
                    : Text(
                        widget.notes,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B1E1E),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Anthropometric Physical measurements
          SectionHeader(title: 'Medidas Antropométricas', action: 'Ficha Física'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _measureItem('Peso', '${m.physicalMeasurements['peso'] ?? 70.0} kg')),
                    Expanded(child: _measureItem('Estatura', '${m.physicalMeasurements['altura'] ?? 1.70} m')),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE8E4D9)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _measureItem('Pecho', '${m.physicalMeasurements['pecho'] ?? 90.0} cm')),
                    Expanded(child: _measureItem('Cintura', '${m.physicalMeasurements['cintura'] ?? 75.0} cm')),
                    Expanded(child: _measureItem('Cadera', '${m.physicalMeasurements['cadera'] ?? 95.0} cm')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Workout planning trigger
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit_calendar_rounded),
              label: const Text('Planificar / Asignar Rutina Semanal', style: TextStyle(fontWeight: FontWeight.w900)),
              onPressed: () => widget.onGo('assign-routine', {'member': m}),
            ),
          ),
          const SizedBox(height: 18),

          // Past RPE effort history logs
          SectionHeader(title: 'Historial de Esfuerzo Reciente', action: 'RPE Logs'),
          Column(
            children: [
              _rpeLogTile('Ayer', 'Press de banca', '4 series × 8 rep @ 75kg', 'RPE 9 (Cerca al fallo)'),
              _rpeLogTile('Hace 3d', 'Sentadilla con barra', '4 series × 6 rep @ 95kg', 'RPE 8 (2 rep en reserva)'),
              _rpeLogTile('Hace 5d', 'Press militar', '3 series × 10 rep @ 40kg', 'RPE 7 (3 rep en reserva)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoStatColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E8E), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _measureItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7A7A7A), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _rpeLogTile(String time, String exercise, String details, String rpeText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.deepOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(fontSize: 12, color: Color(0xFF6E6E6E))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                rpeText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.deepOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------
// WEEKLY ROUTINE BUILDER / ASSIGN VIEW
// ------------------------------------------
class _AssignRoutineView extends StatefulWidget {
  const _AssignRoutineView({
    required this.palette,
    required this.member,
    required this.templates,
    required this.onBack,
  });

  final RolePalette palette;
  final MemberRecord member;
  final List<Map<String, dynamic>> templates;
  final VoidCallback onBack;

  @override
  State<_AssignRoutineView> createState() => _AssignRoutineViewState();
}

class _AssignRoutineViewState extends State<_AssignRoutineView> {
  // Weekly matrix assignments
  final Map<String, String> _weeklyRoutines = {
    'LUN': 'Rutina A: Fuerza Pecho',
    'MAR': 'Rutina B: Hipertrofia Pierna',
    'MIÉ': 'Descanso',
    'JUE': 'Rutina C: Espalda & Pull',
    'VIE': 'Rutina A: Fuerza Pecho',
    'SÁB': 'Descanso',
    'DOM': 'Descanso',
  };

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Asignador Semanal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Matriz Semanal de Entrenamientos',
            style: TextStyle(fontSize: 13, letterSpacing: 1.1, fontWeight: FontWeight.w900, color: widget.palette.accent),
          ),
          const SizedBox(height: 4),
          Text(
            'Configura qué plantilla de rutina ejecuta ${widget.member.name} cada día de la semana.',
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B6B6B)),
          ),
          const SizedBox(height: 18),

          // LUN-DOM Matrix UI
          Column(
            children: _weeklyRoutines.keys.map((day) {
              final activeTemplate = _weeklyRoutines[day]!;
              final isRest = activeTemplate == 'Descanso';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    // Day Circle Badge
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isRest ? const Color(0xFFEEEEEE) : widget.palette.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isRest ? const Color(0xFF666666) : widget.palette.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rutina Asignada',
                              style: TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            activeTemplate,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isRest ? const Color(0xFF8E8E8E) : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action dropdown trigger
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Color(0xFF666666)),
                      onSelected: (value) {
                        setState(() {
                          _weeklyRoutines[day] = value;
                        });
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem(value: 'Descanso', child: Text('Descanso')),
                          ...widget.templates.map((t) {
                            return PopupMenuItem(
                              value: t['name'] as String,
                              child: Text(t['name'] as String),
                            );
                          }),
                        ];
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // Post audit log reactively
                state.addAnnouncement('RUTINA', 'Rutina asignada a ${widget.member.name}', 'Se actualizó la matriz semanal de rutinas.');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Matriz semanal de ${widget.member.name} guardada y notificada'),
                    backgroundColor: const Color(0xFF00B85C),
                  ),
                );
                widget.onBack();
              },
              child: const Text('Guardar y Publicar Rutina', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------
// EXERCISE LIBRARY TAB
// ------------------------------------------
class _TrainerExerciseLibraryTab extends StatefulWidget {
  const _TrainerExerciseLibraryTab({
    super.key,
    required this.palette,
    required this.exercises,
    required this.onAddExercise,
  });

  final RolePalette palette;
  final List<ExerciseItem> exercises;
  final Function(ExerciseItem) onAddExercise;

  @override
  State<_TrainerExerciseLibraryTab> createState() => _TrainerExerciseLibraryTabState();
}

class _TrainerExerciseLibraryTabState extends State<_TrainerExerciseLibraryTab> {
  String _searchQuery = '';
  String _selectedMuscle = 'Todos';
  String? _expandedExerciseName;

  final List<String> _muscleFilters = ['Todos', 'Pecho', 'Hombro', 'Pierna', 'Espalda', 'Bíceps', 'Tríceps'];

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2DDD5)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                hintText: 'Buscar ejercicio...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                    label: Text(muscle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: widget.palette.accent,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE8E4D9)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.palette.accent.withValues(alpha: 0.12),
              foregroundColor: widget.palette.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
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
                decoration: _cardDecoration(),
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
                              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2DDD5)),
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
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: widget.palette.accent),
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

// ------------------------------------------
// ROUTINE TEMPLATES TAB
// ------------------------------------------
class _TrainerTemplatesTab extends StatelessWidget {
  const _TrainerTemplatesTab({
    super.key,
    required this.palette,
    required this.templates,
    required this.onAddTemplate,
  });

  final RolePalette palette;
  final List<Map<String, dynamic>> templates;
  final Function(String, String, List<String>) onAddTemplate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        SectionHeader(
          title: 'Plantillas de Rutina',
          action: '${templates.length} Diseños',
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('Crear Nueva Plantilla', style: TextStyle(fontWeight: FontWeight.w900)),
          onPressed: () => _showCreateTemplateDialog(context),
        ),
        const SizedBox(height: 18),
        Column(
          children: templates.map((tmpl) {
            final List<String> exercises = List<String>.from(tmpl['exercises']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text(tmpl['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      const Spacer(),
                      StatusPill(label: tmpl['muscle'] as String, color: Colors.blue.withValues(alpha: 0.15), solid: false),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Ejercicios programados:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: exercises.map((ex) {
                      return Chip(
                        label: Text(ex, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: const Color(0xFFFAFAFA),
                        side: const BorderSide(color: Color(0xFFE8E4D9)),
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    String name = '';
    String muscle = '';
    String exStr = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2DDD5)),
          ),
          title: const Text('Crear Plantilla', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nombre de la Plantilla (ej. Rutina D)'),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Músculo / Categoría (ej. Espalda)'),
                onChanged: (val) => muscle = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Ejercicios (separados por coma)'),
                onChanged: (val) => exStr = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111111)),
              onPressed: () {
                if (name.isNotEmpty && muscle.isNotEmpty) {
                  final list = exStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  onAddTemplate(name, muscle, list);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------
// TRAINING VOLUME PROGRESS TAB
// ------------------------------------------
class _TrainerProgressTab extends StatelessWidget {
  const _TrainerProgressTab({super.key, required this.palette});

  final RolePalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        SectionHeader(title: 'Volumen Técnico Semanal', action: 'Últimas 8 Semanas'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tolerancia al esfuerzo & Carga del grupo',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5D5D5D), fontSize: 13),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 140,
                child: CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _VolumePainter(
                    volumes: [50, 56, 52, 60, 62, 70, 72, 78],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(child: _ProgressMiniStat(title: 'Volumen Promedio', value: '62.5 t')),
                  SizedBox(width: 10),
                  Expanded(child: _ProgressMiniStat(title: 'Carga Pico', value: '78.0 t')),
                  SizedBox(width: 10),
                  Expanded(child: _ProgressMiniStat(title: 'RPE Promedio', value: '8.1')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VolumePainter extends CustomPainter {
  _VolumePainter({required this.volumes});

  final List<double> volumes;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final barPaint = Paint()
      ..color = const Color(0xFF0066FF)
      ..style = PaintingStyle.fill;

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final double barGap = 12.0;
    final int barCount = volumes.length;
    final double totalGaps = barGap * (barCount - 1);
    final double barWidth = (w - totalGaps) / barCount;

    final double maxVal = 90.0; // max scale

    for (int i = 0; i < barCount; i++) {
      final val = volumes[i];
      final double barHeight = (val / maxVal) * (h - 25);
      final double x = i * (barWidth + barGap);
      final double y = h - 20 - barHeight;

      // Draw RRect bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(6),
        ),
        barPaint,
      );

      // Value label on top of bar
      textPaint.text = TextSpan(
        text: '${val.toInt()}t',
        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPaint.layout();
      textPaint.paint(canvas, Offset(x + (barWidth - textPaint.width) / 2, y - 14));

      // Week label below bar
      textPaint.text = TextSpan(
        text: 'S${i + 1}',
        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPaint.layout();
      textPaint.paint(canvas, Offset(x + (barWidth - textPaint.width) / 2, h - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _VolumePainter oldDelegate) {
    return oldDelegate.volumes != volumes;
  }
}

class _ProgressMiniStat extends StatelessWidget {
  const _ProgressMiniStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF6E6E6E), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.4),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------
// TRAINER PROFILE TAB
// ------------------------------------------
class _TrainerProfileTab extends StatelessWidget {
  const _TrainerProfileTab({
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
          decoration: _cardDecoration(),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: palette.accent.withValues(alpha: 0.12),
                foregroundColor: palette.accent,
                child: const Text('CM', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 16),
              const Text('Carlos Mendoza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Entrenador Elite · Sede Providencia', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star_rate_rounded, color: Color(0xFFFFB300), size: 24),
                  Icon(Icons.star_rate_rounded, color: Color(0xFFFFB300), size: 24),
                  Icon(Icons.star_rate_rounded, color: Color(0xFFFFB300), size: 24),
                  Icon(Icons.star_rate_rounded, color: Color(0xFFFFB300), size: 24),
                  Icon(Icons.star_rate_rounded, color: Color(0xFFFFB300), size: 24),
                  SizedBox(width: 8),
                  Text('4.9 (53 alumnos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información Operativa', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 14),
              _rowProfileInfo('Turno', 'Lunes a Viernes · 08:00 - 16:00'),
              _rowProfileInfo('Especialidad', 'Hipertrofia, Fuerza y Biomecánica'),
              _rowProfileInfo('Certificación', 'NSCA - Certified Personal Trainer'),
              _rowProfileInfo('Email', 'carlos.mendoza@sasgym.com'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Soporte e Incidencias', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: palette.accent.withValues(alpha: 0.12),
                  child: Icon(Icons.report_problem_rounded, color: palette.accent),
                ),
                title: const Text('Buzón de Incidencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Reporta daños en máquinas o áreas del local', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => onGo('report-observation'),
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
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// CARD DECORATION HELPER
// ==========================================
BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE2DDD5)),
  );
}