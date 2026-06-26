import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import 'trainer_shared_utils.dart';

class TrainerTemplatesTab extends StatelessWidget {
  const TrainerTemplatesTab({
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
          style: roleFilledPillButtonStyle(
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text(
            'Crear Nueva Plantilla',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          onPressed: () => _showCreateTemplateDialog(context),
        ),
        const SizedBox(height: 18),
        Column(
          children: templates.map((tmpl) {
            final List<String> exercises = List<String>.from(tmpl['exercises']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: trainerCardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text(
                        tmpl['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      StatusPill(
                        label: tmpl['muscle'] as String,
                        color: Colors.blue.withValues(alpha: 0.15),
                        solid: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ejercicios programados:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: exercises.map((ex) {
                      return Chip(
                        label: Text(
                          ex,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
    final colors = context.sasColors;
    String name = '';
    String muscle = '';
    String exStr = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          title: const Text(
            'Crear Plantilla',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Plantilla (ej. Rutina D)',
                ),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Músculo / Categoría (ej. Espalda)',
                ),
                onChanged: (val) => muscle = val,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Ejercicios (separados por coma)',
                ),
                onChanged: (val) => exStr = val,
              ),
            ],
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
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (name.isNotEmpty && muscle.isNotEmpty) {
                  final list = exStr
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
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
