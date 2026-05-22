import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a simulated 25x25 QR Code using a CustomPainter.
/// Generates three standard QR "finder patterns" at the corners and fills the rest with seed-based noise.
class QRPattern extends StatelessWidget {
  const QRPattern({
    super.key,
    required this.seed,
    this.size = 200,
    this.color = Colors.black,
  });

  final String seed;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E4D9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _QRPainter(seed: seed, color: color),
      ),
    );
  }
}

class _QRPainter extends CustomPainter {
  _QRPainter({required this.seed, required this.color});

  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int gridCount = 25;
    final double cellSize = size.width / gridCount;

    // Helper to draw a square block in the grid
    void drawCell(int x, int y) {
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, cellSize + 0.2, cellSize + 0.2),
        paint,
      );
    }

    // Helper to draw the 7x7 Finder Pattern at (x, y)
    void drawFinderPattern(int px, int py) {
      // Outer 7x7
      for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 7; j++) {
          if (i == 0 || i == 6 || j == 0 || j == 6) {
            drawCell(px + i, py + j);
          }
        }
      }
      // Inner 3x3 solid block
      for (int i = 2; i < 5; i++) {
        for (int j = 2; j < 5; j++) {
          drawCell(px + i, py + j);
        }
      }
    }

    // 1. Draw corner finder patterns
    drawFinderPattern(0, 0); // Top-left
    drawFinderPattern(gridCount - 7, 0); // Top-right
    drawFinderPattern(0, gridCount - 7); // Bottom-left

    // 2. Generate deterministic noise based on seed hash
    final int hash = seed.hashCode;
    final random = math.Random(hash);

    for (int y = 0; y < gridCount; y++) {
      for (int x = 0; x < gridCount; x++) {
        // Skip finder patterns
        if (x < 8 && y < 8) continue; // Top-left
        if (x >= gridCount - 8 && y < 8) continue; // Top-right
        if (x < 8 && y >= gridCount - 8) continue; // Bottom-left

        // Also add simulated alignment patterns
        if (x == gridCount - 9 && y == gridCount - 9) {
          // Draw small 5x5 center pattern
          for (int i = -2; i <= 2; i++) {
            for (int j = -2; j <= 2; j++) {
              if (i.abs() == 2 || j.abs() == 2 || (i == 0 && j == 0)) {
                drawCell(x + i, y + j);
              }
            }
          }
          continue;
        }
        if (x >= gridCount - 11 && x <= gridCount - 7 && y >= gridCount - 11 && y <= gridCount - 7) {
          continue; // skip alignment area to not overlap
        }

        // Timing patterns (horizontal & vertical lines)
        if (y == 6 && x % 2 == 0) {
          drawCell(x, y);
          continue;
        }
        if (x == 6 && y % 2 == 0) {
          drawCell(x, y);
          continue;
        }

        // Random cells based on seed
        if (random.nextDouble() > 0.48) {
          drawCell(x, y);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QRPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.color != color;
  }
}

/// A premium circular timer progress ring with segment animations.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    this.size = 180,
    this.color = const Color(0xFFD2FF3A),
    this.onFinished,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final double size;
  final Color color;
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    final double progress = totalSeconds > 0 ? secondsRemaining / totalSeconds : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow/Shadow
          Container(
            width: size - 12,
            height: size - 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF151515),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Custom Paint Arc
          CustomPaint(
            size: Size(size, size),
            painter: _TimerRingPainter(
              progress: progress,
              color: color,
              backgroundColor: const Color(0xFF2C2C2C),
            ),
          ),
          // Text values in center
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DESCANSO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(secondsRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'de $totalSeconds s',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSecs) {
    final int m = totalSecs ~/ 60;
    final int s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // Background track paint
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc paint
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc from top (-pi/2)
    final double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Dynamic bicep-curl and squat animating figure vector painter
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

class _ExerciseAnimState extends State<ExerciseAnim> with SingleTickerProviderStateMixin {
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
    final isSquat = widget.exerciseName.toLowerCase().contains('sentadilla') ||
        widget.exerciseName.toLowerCase().contains('pierna');
    final isBench = widget.exerciseName.toLowerCase().contains('press') ||
        widget.exerciseName.toLowerCase().contains('aperturas');

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
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

  final double animationValue; // 0.0 to 1.0 (reverses automatically)
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
      // --- SQUAT ANIMATION ---
      // Squat height goes down as animationValue increases
      final double squatOffset = animationValue * 16.0;

      // Feet anchor
      final leftFoot = Offset(w * 0.35, h * 0.85);
      final rightFoot = Offset(w * 0.65, h * 0.85);

      // Knees bow outward/downward
      final double kneeY = h * 0.70 + (squatOffset * 0.4);
      final leftKnee = Offset(w * 0.30 - (squatOffset * 0.3), kneeY);
      final rightKnee = Offset(w * 0.70 + (squatOffset * 0.3), kneeY);

      // Hips/Butt drop
      final hips = Offset(w * 0.5, h * 0.55 + squatOffset);

      // Neck / Head drops
      final neck = Offset(w * 0.5, h * 0.35 + squatOffset);
      final headCenter = Offset(w * 0.5, h * 0.25 + squatOffset);

      // Draw Head
      canvas.drawCircle(headCenter, 8.0, fillPaint);

      // Draw Body (Spine)
      canvas.drawLine(neck, hips, strokePaint);

      // Draw Legs
      canvas.drawLine(leftFoot, leftKnee, strokePaint);
      canvas.drawLine(leftKnee, hips, strokePaint);
      canvas.drawLine(rightFoot, rightKnee, strokePaint);
      canvas.drawLine(rightKnee, hips, strokePaint);

      // Barbell resting on back/neck
      final barY = neck.dy + 4;
      canvas.drawLine(Offset(w * 0.20, barY), Offset(w * 0.80, barY), barPaint);

      // Barbell Plates
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, barY - 10, 10, 20), const Radius.circular(3)), platePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.77, barY - 10, 10, 20), const Radius.circular(3)), platePaint);

      // Arms holding bar
      canvas.drawLine(neck, Offset(w * 0.32, barY + 8), strokePaint);
      canvas.drawLine(neck, Offset(w * 0.68, barY + 8), strokePaint);
    } else if (isBench) {
      // --- BENCH PRESS ANIMATION ---
      // Barbell goes up and down
      final double pressOffset = (1.0 - animationValue) * 22.0;

      // Draw Bench
      final benchPaint = Paint()
        ..color = const Color(0xFF424242)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(Offset(w * 0.2, h * 0.75), Offset(w * 0.8, h * 0.75), benchPaint); // Bench surface
      canvas.drawLine(Offset(w * 0.3, h * 0.75), Offset(w * 0.3, h * 0.90), benchPaint); // Left leg
      canvas.drawLine(Offset(w * 0.7, h * 0.75), Offset(w * 0.7, h * 0.90), benchPaint); // Right leg

      // Person lying on back
      final hips = Offset(w * 0.35, h * 0.70);
      final neck = Offset(w * 0.60, h * 0.70);
      final headCenter = Offset(w * 0.67, h * 0.68);

      // Head
      canvas.drawCircle(headCenter, 7.0, fillPaint);
      // Torso
      canvas.drawLine(hips, neck, strokePaint);
      // Lying Leg
      canvas.drawLine(hips, Offset(w * 0.22, h * 0.85), strokePaint);

      // Barbell height
      final barY = h * 0.40 + pressOffset;

      // Arms extending to bar
      final leftElbow = Offset(w * 0.42, h * 0.58 + (pressOffset * 0.3));
      final rightElbow = Offset(w * 0.54, h * 0.58 + (pressOffset * 0.3));
      final handLeft = Offset(w * 0.42, barY);
      final handRight = Offset(w * 0.58, barY);

      canvas.drawLine(neck, leftElbow, strokePaint);
      canvas.drawLine(leftElbow, handLeft, strokePaint);
      canvas.drawLine(neck, rightElbow, strokePaint);
      canvas.drawLine(rightElbow, handRight, strokePaint);

      // Barbell bar
      canvas.drawLine(Offset(w * 0.22, barY), Offset(w * 0.78, barY), barPaint);

      // Barbell Plates
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.17, barY - 12, 10, 24), const Radius.circular(3)), platePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.75, barY - 12, 10, 24), const Radius.circular(3)), platePaint);
    } else {
      // --- BICEP CURL ANIMATION ---
      // Forearm angle rotates based on animationValue
      final double curlAngle = 0.2 + (animationValue * 1.5); // Radians rotation

      final shoulder = Offset(w * 0.45, h * 0.35);
      final elbow = Offset(w * 0.45, h * 0.55);

      // Forearm end calculations
      final double armLength = w * 0.22;
      final double wristX = elbow.dx - armLength * math.sin(curlAngle);
      final double wristY = elbow.dy - armLength * math.cos(curlAngle);
      final wrist = Offset(wristX, wristY);

      // Head
      final headCenter = Offset(w * 0.50, h * 0.20);
      canvas.drawCircle(headCenter, 9.0, fillPaint);

      // Torso & Hips
      final hips = Offset(w * 0.50, h * 0.60);
      canvas.drawLine(headCenter, hips, strokePaint);

      // Legs
      canvas.drawLine(hips, Offset(w * 0.42, h * 0.85), strokePaint);
      canvas.drawLine(hips, Offset(w * 0.58, h * 0.85), strokePaint);

      // Upper arm
      canvas.drawLine(shoulder, elbow, strokePaint);
      // Forearm
      canvas.drawLine(elbow, wrist, strokePaint);

      // Dumbbell in wrist hand
      final dbPaint = Paint()
        ..color = const Color(0xFFFF7A1A)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.square;

      // Dumbbell handle parallel to wrist offset
      final dbStart = Offset(wrist.dx - 10, wrist.dy);
      final dbEnd = Offset(wrist.dx + 10, wrist.dy);
      canvas.drawLine(dbStart, dbEnd, dbPaint);

      // Dumbbell weights
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

/// Premium dialog for recording workout weight and effort (RPE scale)
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
  int rpe = 8; // RPE scale default is 8 (2 reps in reserve)

  @override
  void initState() {
    super.initState();
    // Parse default reps (could be a range like '8-10', extract first or parse)
    reps = int.tryParse(widget.defaultReps.split('-')[0]) ?? 10;
    weight = (widget.defaultWeight ?? 20).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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

            // Repeticiones selector
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

            // Peso Selector
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

            // RPE Effort slider
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

            // Confirm buttons
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

/// Blocks app interaction with a premium "Suspended SaaS Instance" display.
class GymSuspendedBarrier extends StatelessWidget {
  const GymSuspendedBarrier({super.key, required this.onContactAdmin});

  final VoidCallback onContactAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(Icons.block_outlined, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 28),
              const Text(
                'SERVICIO SUSPENDIDO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta sede del gimnasio ha sido suspendida temporalmente por administración de la red SaaaS GYM debido a temas de facturación pendientes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.headset_mic),
                label: const Text('Contactar Soporte SaaS', style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: onContactAdmin,
              ),
              const SizedBox(height: 12),
              Text(
                'Código de Error: CLIENT_SUSPENDED_BILLING',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
