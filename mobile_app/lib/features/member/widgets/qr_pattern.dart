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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2DDD5), width: 1.5),
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

    void drawCell(int x, int y) {
      canvas.drawRect(
        Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize + 0.2,
          cellSize + 0.2,
        ),
        paint,
      );
    }

    void drawFinderPattern(int px, int py) {
      for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 7; j++) {
          if (i == 0 || i == 6 || j == 0 || j == 6) {
            drawCell(px + i, py + j);
          }
        }
      }
      for (int i = 2; i < 5; i++) {
        for (int j = 2; j < 5; j++) {
          drawCell(px + i, py + j);
        }
      }
    }

    drawFinderPattern(0, 0);
    drawFinderPattern(gridCount - 7, 0);
    drawFinderPattern(0, gridCount - 7);

    final int hash = seed.hashCode;
    final random = math.Random(hash);

    for (int y = 0; y < gridCount; y++) {
      for (int x = 0; x < gridCount; x++) {
        if (x < 8 && y < 8) continue;
        if (x >= gridCount - 8 && y < 8) continue;
        if (x < 8 && y >= gridCount - 8) continue;

        if (x == gridCount - 9 && y == gridCount - 9) {
          for (int i = -2; i <= 2; i++) {
            for (int j = -2; j <= 2; j++) {
              if (i.abs() == 2 || j.abs() == 2 || (i == 0 && j == 0)) {
                drawCell(x + i, y + j);
              }
            }
          }
          continue;
        }
        if (x >= gridCount - 11 &&
            x <= gridCount - 7 &&
            y >= gridCount - 11 &&
            y <= gridCount - 7) {
          continue;
        }

        if (y == 6 && x % 2 == 0) {
          drawCell(x, y);
          continue;
        }
        if (x == 6 && y % 2 == 0) {
          drawCell(x, y);
          continue;
        }

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
