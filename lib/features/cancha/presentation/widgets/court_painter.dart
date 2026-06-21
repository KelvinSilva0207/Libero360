import 'package:flutter/material.dart';

class CourtPainter extends CustomPainter {
  final Color lineColor;
  final Color courtColor;
  final Color netColor;
  final Color attackLineColor;

  CourtPainter({
    this.lineColor = const Color(0x55FFFFFF),
    this.courtColor = const Color(0xFF1B2838),
    this.netColor = const Color(0x88FFFFFF),
    this.attackLineColor = const Color(0x33FFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawCourtBorder(canvas, size);
    _drawCenterLine(canvas, size);
    _drawAttackLines(canvas, size);
    _drawNetPosts(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          courtColor,
          Color.lerp(courtColor, Colors.white, 0.04)!,
          courtColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 2, size.width, size.height),
        const Radius.circular(12),
      ),
      shadowPaint,
    );
  }

  void _drawCourtBorder(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(10),
      ),
      borderPaint,
    );
  }

  void _drawCenterLine(Canvas canvas, Size size) {
    final netY = size.height * 0.42;
    final netHeight = size.height * 0.16;

    final centerLinePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, netY), Offset(size.width, netY), centerLinePaint);

    canvas.drawLine(
      Offset(0, netY + netHeight),
      Offset(size.width, netY + netHeight),
      centerLinePaint,
    );

    final netFill = Paint()
      ..color = netColor.withValues(alpha: 0.08);
    canvas.drawRect(Rect.fromLTWH(0, netY, size.width, netHeight), netFill);

    final netPaint = Paint()
      ..color = netColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, netY, size.width, netHeight), netPaint);

    final dashPaint = Paint()
      ..color = netColor
      ..strokeWidth = 1;
    const dashLen = 6.0;
    const gapLen = 8.0;
    final netMidY = netY + netHeight / 2;
    for (double x = 0; x < size.width; x += dashLen + gapLen) {
      canvas.drawLine(
        Offset(x, netMidY - 6),
        Offset(x + dashLen.clamp(0, size.width - x), netMidY - 6),
        dashPaint,
      );
    }
    canvas.drawLine(
      Offset(0, netMidY + 6),
      Offset(size.width, netMidY + 6),
      dashPaint..color = netColor.withValues(alpha: 0.4),
    );
  }

  void _drawAttackLines(Canvas canvas, Size size) {
    final attackPaint = Paint()
      ..color = attackLineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final topAttackY = size.height * 0.28;
    final bottomAttackY = size.height * 0.72;

    canvas.drawLine(Offset(0, topAttackY), Offset(size.width, topAttackY), attackPaint);
    canvas.drawLine(Offset(0, bottomAttackY), Offset(size.width, bottomAttackY), attackPaint);
  }

  void _drawNetPosts(Canvas canvas, Size size) {
    final postPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const postRadius = 4.0;
    final netY = size.height * 0.42;
    final netHeight = size.height * 0.16;
    final centerY = netY + netHeight / 2;

    canvas.drawCircle(Offset(postRadius + 2, centerY), postRadius, postPaint);
    canvas.drawCircle(Offset(size.width - postRadius - 2, centerY), postRadius, postPaint);
  }

  @override
  bool shouldRepaint(covariant CourtPainter oldDelegate) => false;
}
