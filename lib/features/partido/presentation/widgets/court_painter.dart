import 'dart:math';
import 'package:flutter/material.dart';

class CourtPainter extends CustomPainter {
  final Color courtColor;
  final Color lineColor;
  final Color netColor;
  final Color attackLineColor;

  CourtPainter({
    this.courtColor = const Color(0xFF1B2838),
    this.lineColor = const Color(0x33FFFFFF),
    this.netColor = const Color(0x66FFFFFF),
    this.attackLineColor = const Color(0x1AFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(10),
    );

    canvas.drawRRect(rect, Paint()..color = courtColor);

    final borderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, w - 4, h - 4),
        const Radius.circular(8),
      ),
      borderPaint,
    );

    final netY = h * 0.02;
    final netPaint = Paint()
      ..color = netColor
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(0, netY), Offset(w, netY), netPaint);

    const dashLen = 6.0;
    const gapLen = 4.0;
    for (double x = 0; x < w; x += dashLen + gapLen) {
      canvas.drawLine(
        Offset(x, netY - 3),
        Offset(x + min(dashLen, w - x), netY - 3),
        Paint()..color = netColor.withValues(alpha: 0.3),
      );
    }

    final attackY = h * 0.35;
    final attackPaint = Paint()
      ..color = attackLineColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(8, attackY), Offset(w - 8, attackY), attackPaint);

    for (double x = 8; x <= w - 8; x += 10) {
      final segmentEnd = min(x + 6, w - 8);
      canvas.drawLine(
        Offset(x, attackY + 3),
        Offset(segmentEnd, attackY + 3),
        Paint()..color = attackLineColor.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
