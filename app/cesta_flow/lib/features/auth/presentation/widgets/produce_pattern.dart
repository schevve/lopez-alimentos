import 'package:flutter/material.dart';

// Camada decorativa sem interação; a grade alternada não muda ao reconstruir.
class ProducePattern extends StatelessWidget {
  const ProducePattern({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(child: CustomPaint(painter: _ProducePainter())),
    );
  }
}

class _ProducePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0xFFF1FBF3).withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var row = 0; row * 104 < size.height + 80; row++) {
      for (var col = 0; col * 96 < size.width + 80; col++) {
        canvas.save();
        canvas.translate(col * 96.0 + (row.isOdd ? 44 : 0), row * 104.0 + 28);
        canvas.rotate(((row + col) % 3 - 1) * .28);
        canvas.translate(-24, -24);
        switch ((row * 3 + col) % 4) {
          case 0:
            // Maçã com folha.
            canvas.drawPath(
              Path()
                ..moveTo(24, 17)
                ..cubicTo(2, 3, 3, 42, 18, 44)
                ..quadraticBezierTo(24, 40, 29, 44)
                ..cubicTo(45, 44, 49, 4, 24, 17)
                ..close(),
              pen,
            );
            canvas.drawPath(
              Path()
                ..moveTo(24, 17)
                ..quadraticBezierTo(21, 10, 25, 5)
                ..moveTo(26, 12)
                ..quadraticBezierTo(28, 1, 38, 3)
                ..quadraticBezierTo(38, 12, 26, 12),
              pen,
            );
          case 1:
            // Cenoura e ramas.
            canvas.drawPath(
              Path()
                ..moveTo(15, 19)
                ..quadraticBezierTo(24, 12, 32, 22)
                ..quadraticBezierTo(24, 36, 9, 47)
                ..quadraticBezierTo(10, 29, 15, 19)
                ..close()
                ..moveTo(20, 17)
                ..quadraticBezierTo(14, -1, 23, 3)
                ..lineTo(25, 16)
                ..quadraticBezierTo(32, -3, 35, 4)
                ..lineTo(29, 18)
                ..quadraticBezierTo(46, 7, 43, 16)
                ..lineTo(32, 22)
                ..moveTo(14, 27)
                ..lineTo(19, 30)
                ..moveTo(21, 33)
                ..lineTo(25, 35),
              pen,
            );
          case 2:
            // Folha com nervuras.
            canvas.drawPath(
              Path()
                ..moveTo(12, 41)
                ..cubicTo(-1, 16, 25, 8, 41, 6)
                ..cubicTo(44, 24, 35, 49, 12, 41)
                ..close()
                ..moveTo(7, 47)
                ..lineTo(33, 16)
                ..moveTo(16, 35)
                ..lineTo(14, 23)
                ..moveTo(22, 29)
                ..lineTo(33, 28),
              pen,
            );
          case 3:
            // Pera de contorno orgânico.
            canvas.drawPath(
              Path()
                ..moveTo(23, 12)
                ..cubicTo(12, 9, 17, 22, 9, 28)
                ..cubicTo(-3, 43, 23, 53, 36, 43)
                ..cubicTo(48, 33, 33, 24, 31, 17)
                ..quadraticBezierTo(29, 11, 23, 12)
                ..close()
                ..moveTo(24, 12)
                ..quadraticBezierTo(22, 6, 28, 2)
                ..moveTo(28, 10)
                ..quadraticBezierTo(41, 13, 40, 3)
                ..quadraticBezierTo(29, 2, 28, 10),
              pen,
            );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProducePainter oldDelegate) => false;
}
