import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import 'trainer_shared_utils.dart';

class StudentDetailsView extends StatefulWidget {
  const StudentDetailsView({
    super.key,
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
  State<StudentDetailsView> createState() => _StudentDetailsViewState();
}

class _StudentDetailsViewState extends State<StudentDetailsView> {
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
    final colors = context.sasColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: widget.onBack,
        ),
        title: Text(
          m.name,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Student Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: trainerCardDecoration(context),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: widget.palette.accent.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: widget.palette.accent,
                  child: Text(
                    m.name.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  m.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DNI: ${m.dni} · ${m.email}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
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
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF3B30),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Restricciones y Notas Médicas',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isEditingNote
                            ? Icons.save_rounded
                            : Icons.edit_note_rounded,
                        color: const Color(0xFFFF3B30),
                      ),
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
                          hintText:
                              'Añade restricciones por lesión o cuidados especiales...',
                          border: OutlineInputBorder(),
                          fillColor: null,
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
          SectionHeader(
            title: 'Medidas Antropométricas',
            action: 'Ficha Física',
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: trainerCardDecoration(context),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _measureItem(
                        'Peso',
                        '${m.physicalMeasurements['peso'] ?? 70.0} kg',
                      ),
                    ),
                    Expanded(
                      child: _measureItem(
                        'Estatura',
                        '${m.physicalMeasurements['altura'] ?? 1.70} m',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE8E4D9)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _measureItem(
                        'Pecho',
                        '${m.physicalMeasurements['pecho'] ?? 90.0} cm',
                      ),
                    ),
                    Expanded(
                      child: _measureItem(
                        'Cintura',
                        '${m.physicalMeasurements['cintura'] ?? 75.0} cm',
                      ),
                    ),
                    Expanded(
                      child: _measureItem(
                        'Cadera',
                        '${m.physicalMeasurements['cadera'] ?? 95.0} cm',
                      ),
                    ),
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
              style: roleFilledPillButtonStyle(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumHeight: 52,
              ),
              icon: const Icon(Icons.edit_calendar_rounded),
              label: const Text(
                'Planificar / Asignar Rutina Semanal',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              onPressed: () => widget.onGo('assign-routine', {'member': m}),
            ),
          ),
          const SizedBox(height: 18),

          // Past RPE effort history logs
          SectionHeader(
            title: 'Historial de Esfuerzo Reciente',
            action: 'RPE Logs',
          ),
          Column(
            children: [
              _rpeLogTile(
                context,
                'Ayer',
                'Press de banca',
                '4 series × 8 rep @ 75kg',
                'RPE 9 (Cerca al fallo)',
              ),
              _rpeLogTile(
                context,
                'Hace 3d',
                'Sentadilla con barra',
                '4 series × 6 rep @ 95kg',
                'RPE 8 (2 rep en reserva)',
              ),
              _rpeLogTile(
                context,
                'Hace 5d',
                'Press militar',
                '3 series × 10 rep @ 40kg',
                'RPE 7 (3 rep en reserva)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8E8E8E),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _measureItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF7A7A7A),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _rpeLogTile(
    BuildContext context,
    String time,
    String exercise,
    String details,
    String rpeText,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: trainerCardDecoration(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.deepOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6E6E6E),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A8A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rpeText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
