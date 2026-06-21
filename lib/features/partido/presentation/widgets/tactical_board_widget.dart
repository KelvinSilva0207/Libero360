import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class TacticalBoardWidget extends StatelessWidget {
  const TacticalBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TacticalBoardPainter(),
              ),
            ),
            // Zones for tactical input
            ...List.generate(6, (index) {
              final row = index < 3 ? 0 : 1;
              final col = index % 3;
              return Positioned(
                left: 12 + col * (100),
                top: 12 + row * 160,
                child: Container(
                  width: 88,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Center(
                    child: Text(
                      'Zona ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TacticalBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(1, 1, w - 2, h - 2), linePaint);

    final netY = h / 2;
    final netPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, netY), Offset(w, netY), netPaint);

    for (double x = 8; x < w - 8; x += 14) {
      canvas.drawLine(
        Offset(x, netY - 4),
        Offset(x + 7, netY - 4),
        Paint()..color = Colors.white.withValues(alpha: 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
