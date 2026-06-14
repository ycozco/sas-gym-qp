import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import 'trainer_shared_utils.dart';

class AssignRoutineView extends StatefulWidget {
  const AssignRoutineView({
    super.key,
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
  State<AssignRoutineView> createState() => _AssignRoutineViewState();
}

class _AssignRoutineViewState extends State<AssignRoutineView> {
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
          'Asignador Semanal',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
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
                decoration: trainerCardDecoration(context),
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
                              color: isRest
                                  ? colors.textMuted
                                  : colors.textPrimary,
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
              style: roleFilledPillButtonStyle(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                final memberUserId = state.findMemberUserIdByDni(widget.member.dni);
                final selectedTemplateName = _weeklyRoutines.values.firstWhere(
                  (value) => value != 'Descanso',
                  orElse: () => '',
                );
                final selectedTemplate = widget.templates.cast<Map<String, dynamic>?>().firstWhere(
                  (item) => item?['name']?.toString() == selectedTemplateName,
                  orElse: () => null,
                );

                if (memberUserId != null &&
                    selectedTemplate != null &&
                    (selectedTemplate['id']?.toString().isNotEmpty ?? false)) {
                  await state.assignRoutineTemplate(
                    memberUserId: memberUserId,
                    templateId: selectedTemplate['id'].toString(),
                    agendaSemanal: _weeklyRoutines.map((key, value) {
                      final templateMatch = widget.templates.cast<Map<String, dynamic>?>().firstWhere(
                        (item) => item?['name']?.toString() == value,
                        orElse: () => null,
                      );
                      return MapEntry(
                        key,
                        templateMatch?['id']?.toString().isNotEmpty == true
                            ? templateMatch!['id'].toString()
                            : value,
                      );
                    }),
                  );
                } else {
                  state.addAnnouncement('RUTINA', 'Rutina asignada a ${widget.member.name}', 'Se actualizó la matriz semanal de rutinas.');
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Matriz semanal de ${widget.member.name} guardada y publicada'),
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
