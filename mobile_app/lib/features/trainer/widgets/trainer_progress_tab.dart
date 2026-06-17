import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import 'trainer_shared_utils.dart';

class TrainerProgressTab extends StatelessWidget {
  const TrainerProgressTab({
    super.key,
    required this.palette,
    this.progress,
  });

  final RolePalette palette;
  final Map<String, dynamic>? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final weeklyLoads = (progress?['weeklyLoads'] as List<dynamic>? ?? const [])
        .map((item) => (item as Map<String, dynamic>)['volume'] as num? ?? 0)
        .map((value) => value.toDouble())
        .toList();
    final chartVolumes =
        weeklyLoads.isNotEmpty ? weeklyLoads : <double>[50, 56, 52, 60, 62, 70, 72, 78];
    final totals = progress?['totals'] as Map<String, dynamic>? ?? const {};

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        SectionHeader(title: 'Volumen Técnico Semanal', action: 'Últimas 8 Semanas'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: trainerCardDecoration(context),
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
                    volumes: chartVolumes,
                    labelColor: colors.textPrimary,
                    axisColor: colors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ProgressMiniStat(
                      title: 'Sesiones',
                      value: '${totals['sessions'] ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProgressMiniStat(
                      title: 'Completadas',
                      value: '${totals['completedSessions'] ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProgressMiniStat(
                      title: 'Reps Promedio',
                      value: '${totals['averageReps'] ?? 0}',
                    ),
                  ),
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
  _VolumePainter({
    required this.volumes,
    required this.labelColor,
    required this.axisColor,
  });

  final List<double> volumes;
  final Color labelColor;
  final Color axisColor;

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
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPaint.layout();
      textPaint.paint(canvas, Offset(x + (barWidth - textPaint.width) / 2, y - 14));

      // Week label below bar
      textPaint.text = TextSpan(
        text: 'S${i + 1}',
        style: TextStyle(
          color: axisColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
