import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dynamic bicep-curl and squat animating figure vector painter.
/// Reutilizable: lo consumen tanto la pantalla del socio (entrenamiento)
/// como la del entrenador (biblioteca de ejercicios), por lo que vive
/// en `widgets/` y no en una feature concreta.
class ExerciseAnim extends StatefulWidget {
  const ExerciseAnim({
    super.key,
    required this.exerciseName,
    this.size = 130,
    this.active = true,
  });

  final String exerciseName;
  final double size;
  final bool active;

  @override
  State<ExerciseAnim> createState() => _ExerciseAnimState();
}

class _ExerciseAnimState extends State<ExerciseAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseAnim oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSquat =
        widget.exerciseName.toLowerCase().contains('sentadilla') ||
        widget.exerciseName.toLowerCase().contains('pierna');
    final isBench =
        widget.exerciseName.toLowerCase().contains('press') ||
        widget.exerciseName.toLowerCase().contains('aperturas');

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2C2C2C), width: 1.5),
          ),
          child: CustomPaint(
            painter: _StickFigurePainter(
              animationValue: _controller.value,
              isSquat: isSquat,
              isBench: isBench,
            ),
          ),
        );
      },
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  _StickFigurePainter({
    required this.animationValue,
    required this.isSquat,
    required this.isBench,
  });

  final double animationValue;
  final bool isSquat;
  final bool isBench;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFFD2FF3A)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFD2FF3A)
      ..style = PaintingStyle.fill;

    final barPaint = Paint()
      ..color = const Color(0xFF7A5AE0)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final platePaint = Paint()
      ..color = const Color(0xFFFF7A1A)
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    if (isSquat) {
      final double squatOffset = animationValue * 16.0;

      final leftFoot = Offset(w * 0.35, h * 0.85);
      final rightFoot = Offset(w * 0.65, h * 0.85);

      final double kneeY = h * 0.70 + (squatOffset * 0.4);
      final leftKnee = Offset(w * 0.30 - (squatOffset * 0.3), kneeY);
      final rightKnee = Offset(w * 0.70 + (squatOffset * 0.3), kneeY);

      final hips = Offset(w * 0.5, h * 0.55 + squatOffset);

      final neck = Offset(w * 0.5, h * 0.35 + squatOffset);
      final headCenter = Offset(w * 0.5, h * 0.25 + squatOffset);

      canvas.drawCircle(headCenter, 8.0, fillPaint);

      canvas.drawLine(neck, hips, strokePaint);

      canvas.drawLine(leftFoot, leftKnee, strokePaint);
      canvas.drawLine(leftKnee, hips, strokePaint);
      canvas.drawLine(rightFoot, rightKnee, strokePaint);
      canvas.drawLine(rightKnee, hips, strokePaint);

      final barY = neck.dy + 4;
      canvas.drawLine(Offset(w * 0.20, barY), Offset(w * 0.80, barY), barPaint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.15, barY - 10, 10, 20),
          const Radius.circular(3),
        ),
        platePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.77, barY - 10, 10, 20),
          const Radius.circular(3),
        ),
        platePaint,
      );

      canvas.drawLine(neck, Offset(w * 0.32, barY + 8), strokePaint);
      canvas.drawLine(neck, Offset(w * 0.68, barY + 8), strokePaint);
    } else if (isBench) {
      final double pressOffset = (1.0 - animationValue) * 22.0;

      final benchPaint = Paint()
        ..color = const Color(0xFF424242)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(
        Offset(w * 0.2, h * 0.75),
        Offset(w * 0.8, h * 0.75),
        benchPaint,
      );
      canvas.drawLine(
        Offset(w * 0.3, h * 0.75),
        Offset(w * 0.3, h * 0.90),
        benchPaint,
      );
      canvas.drawLine(
        Offset(w * 0.7, h * 0.75),
        Offset(w * 0.7, h * 0.90),
        benchPaint,
      );

      final hips = Offset(w * 0.35, h * 0.70);
      final neck = Offset(w * 0.60, h * 0.70);
      final headCenter = Offset(w * 0.67, h * 0.68);

      canvas.drawCircle(headCenter, 7.0, fillPaint);
      canvas.drawLine(hips, neck, strokePaint);
      canvas.drawLine(hips, Offset(w * 0.22, h * 0.85), strokePaint);

      final barY = h * 0.40 + pressOffset;

      final leftElbow = Offset(w * 0.42, h * 0.58 + (pressOffset * 0.3));
      final rightElbow = Offset(w * 0.54, h * 0.58 + (pressOffset * 0.3));
      final handLeft = Offset(w * 0.42, barY);
      final handRight = Offset(w * 0.58, barY);

      canvas.drawLine(neck, leftElbow, strokePaint);
      canvas.drawLine(leftElbow, handLeft, strokePaint);
      canvas.drawLine(neck, rightElbow, strokePaint);
      canvas.drawLine(rightElbow, handRight, strokePaint);

      canvas.drawLine(Offset(w * 0.22, barY), Offset(w * 0.78, barY), barPaint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.17, barY - 12, 10, 24),
          const Radius.circular(3),
        ),
        platePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.75, barY - 12, 10, 24),
          const Radius.circular(3),
        ),
        platePaint,
      );
    } else {
      final double curlAngle = 0.2 + (animationValue * 1.5);

      final shoulder = Offset(w * 0.45, h * 0.35);
      final elbow = Offset(w * 0.45, h * 0.55);

      final double armLength = w * 0.22;
      final double wristX = elbow.dx - armLength * math.sin(curlAngle);
      final double wristY = elbow.dy - armLength * math.cos(curlAngle);
      final wrist = Offset(wristX, wristY);

      final headCenter = Offset(w * 0.50, h * 0.20);
      canvas.drawCircle(headCenter, 9.0, fillPaint);

      final hips = Offset(w * 0.50, h * 0.60);
      canvas.drawLine(headCenter, hips, strokePaint);

      canvas.drawLine(hips, Offset(w * 0.42, h * 0.85), strokePaint);
      canvas.drawLine(hips, Offset(w * 0.58, h * 0.85), strokePaint);

      canvas.drawLine(shoulder, elbow, strokePaint);
      canvas.drawLine(elbow, wrist, strokePaint);

      final dbPaint = Paint()
        ..color = const Color(0xFFFF7A1A)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.square;

      final dbStart = Offset(wrist.dx - 10, wrist.dy);
      final dbEnd = Offset(wrist.dx + 10, wrist.dy);
      canvas.drawLine(dbStart, dbEnd, dbPaint);

      final dbWeightPaint = Paint()..color = const Color(0xFF7A5AE0);
      canvas.drawCircle(dbStart, 7.0, dbWeightPaint);
      canvas.drawCircle(dbEnd, 7.0, dbWeightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isSquat != isSquat ||
        oldDelegate.isBench != isBench;
  }
}
