import 'dart:math';
import 'package:flutter/material.dart';

class CourtPainter extends CustomPainter {
  final Color lineColor;
  final Color courtColor;
  final Color netColor;

  CourtPainter({
    this.lineColor = const Color(0x44FFFFFF),
    this.courtColor = const Color(0xFF1B2838),
    this.netColor = const Color(0x66FFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(12)),
      Paint()..color = courtColor,
    );

    final borderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, w - 4, h - 4), const Radius.circular(10)),
      borderPaint,
    );

    final netPaint = Paint()
      ..color = netColor
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, h * 0.22), Offset(w, h * 0.22), netPaint);

    final dashPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final dashLen = 8.0;
    final gapLen = 6.0;
    for (double x = 0; x < w; x += dashLen + gapLen) {
      canvas.drawLine(
        Offset(x, h * 0.22 - 4),
        Offset(x + min(dashLen, w - x), h * 0.22 - 4),
        dashPaint,
      );
    }

    final faintPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, h * 0.38), Offset(w, h * 0.38), faintPaint);
    canvas.drawLine(Offset(0, h * 0.62), Offset(w, h * 0.62), faintPaint);

    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h * 0.22), faintPaint);
    canvas.drawLine(Offset(w / 2, h * 0.22), Offset(w / 2, h), faintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
