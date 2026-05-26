import 'package:flutter/material.dart';

/// Premium dialog for recording workout weight and effort (RPE scale).
class LogEffortModal extends StatefulWidget {
  const LogEffortModal({
    super.key,
    required this.exerciseName,
    required this.defaultReps,
    required this.defaultWeight,
    required this.onSave,
  });

  final String exerciseName;
  final String defaultReps;
  final int? defaultWeight;
  final Function(int reps, double weight, int rpe) onSave;

  @override
  State<LogEffortModal> createState() => _LogEffortModalState();
}

class _LogEffortModalState extends State<LogEffortModal> {
  late int reps;
  late double weight;
  int rpe = 8;

  @override
  void initState() {
    super.initState();
    reps = int.tryParse(widget.defaultReps.split('-')[0]) ?? 10;
    weight = (widget.defaultWeight ?? 20).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFD2FF3A), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Registra las especificaciones reales de tu serie:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 20),

            const Text(
              'Repeticiones completadas',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _counterButton(Icons.remove, () {
                  if (reps > 1) setState(() => reps--);
                }),
                Text(
                  '$reps reps',
                  style: const TextStyle(color: Color(0xFFD2FF3A), fontSize: 22, fontWeight: FontWeight.w900),
                ),
                _counterButton(Icons.add, () {
                  setState(() => reps++);
                }),
              ],
            ),
            const SizedBox(height: 18),

            const Text(
              'Peso levantado (kg)',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _counterButton(Icons.remove_circle_outline, () {
                  if (weight >= 2.5) setState(() => weight -= 2.5);
                }),
                Text(
                  '$weight kg',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                _counterButton(Icons.add_circle_outline, () {
                  setState(() => weight += 2.5);
                }),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Esfuerzo Percibido (RPE)',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '@ RPE $rpe',
                  style: const TextStyle(color: Color(0xFFFF7A1A), fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF7A1A),
                inactiveTrackColor: const Color(0xFF3E3E3E),
                thumbColor: const Color(0xFFFF7A1A),
                overlayColor: const Color(0xFFFF7A1A).withValues(alpha: 0.16),
              ),
              child: Slider(
                value: rpe.toDouble(),
                min: 5,
                max: 10,
                divisions: 5,
                label: 'RPE $rpe',
                onChanged: (val) {
                  setState(() => rpe = val.round());
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RPE 5 (Cómodo)', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5)),
                Text('RPE 10 (Fallo máximo)', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5)),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8C8C8C), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2FF3A),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      widget.onSave(reps, weight, rpe);
                      Navigator.pop(context);
                    },
                    child: const Text('Guardar Serie', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}
