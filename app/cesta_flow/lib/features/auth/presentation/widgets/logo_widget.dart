import 'package:flutter/material.dart';

// Composição provisória isolada para substituir por um asset no futuro.
class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.color = const Color(0xFF1C5632),
    this.backgroundColor = const Color(0xFFF1FBF3),
  });

  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo: número 7 integrado a produtos de mercado',
      image: true,
      child: SizedBox(
        width: 200,
        height: 168,
        child: CustomPaint(painter: _LogoPainter(color, backgroundColor)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.color, this.backgroundColor);

  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 168);
    final ink = Paint()..color = color;
    final cutout = Paint()..color = backgroundColor;
    final detail = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Embalagem à esquerda e folha recortada no rótulo.
    canvas.drawPath(
      Path()
        ..moveTo(12, 82)
        ..quadraticBezierTo(34, 87, 59, 82)
        ..lineTo(54, 139)
        ..quadraticBezierTo(32, 135, 12, 139)
        ..quadraticBezierTo(18, 110, 12, 82)
        ..close(),
      ink,
    );
    canvas.drawLine(const Offset(16, 90), const Offset(55, 90), detail);
    canvas.drawLine(const Offset(16, 132), const Offset(53, 132), detail);
    canvas.drawPath(
      Path()
        ..moveTo(28, 120)
        ..quadraticBezierTo(24, 104, 44, 101)
        ..quadraticBezierTo(43, 120, 28, 120)
        ..close(),
      cutout,
    );

    // Garrafa e caixa de leite compartilham a silhueta do conjunto.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(117, 64, 15, 8),
        const Radius.circular(2),
      ),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(117, 75)
        ..lineTo(132, 75)
        ..lineTo(140, 91)
        ..lineTo(140, 125)
        ..lineTo(108, 125)
        ..lineTo(108, 91)
        ..close(),
      ink,
    );
    canvas.drawLine(const Offset(111, 91), const Offset(137, 91), detail);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(153, 53, 24, 6),
        const Radius.circular(2),
      ),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(152, 62)
        ..lineTo(177, 62)
        ..lineTo(187, 76)
        ..lineTo(187, 127)
        ..lineTo(144, 127)
        ..lineTo(144, 76)
        ..close(),
      ink,
    );
    canvas.drawLine(const Offset(144, 76), const Offset(187, 76), detail);
    canvas.drawPath(
      Path()
        ..moveTo(177, 62)
        ..lineTo(170, 76)
        ..lineTo(170, 127),
      detail,
    );

    // Pão em primeiro plano, com cortes claros na crosta.
    final bread = Path()
      ..moveTo(91, 123)
      ..cubicTo(92, 94, 147, 91, 162, 115)
      ..quadraticBezierTo(171, 130, 151, 131)
      ..lineTo(100, 131)
      ..quadraticBezierTo(88, 131, 91, 123)
      ..close();
    canvas.drawPath(
      bread,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawPath(bread, ink);
    for (final x in [108.0, 125.0, 142.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 103)
          ..quadraticBezierTo(x + 7, 106, x + 9, 114),
        detail,
      );
    }

    // O 7 contornado une os produtos à base, como no protótipo.
    final seven = Path()
      ..moveTo(30, 10)
      ..lineTo(134, 10)
      ..lineTo(134, 35)
      ..lineTo(70, 146)
      ..lineTo(35, 146)
      ..lineTo(92, 46)
      ..lineTo(30, 46)
      ..close();
    canvas.drawPath(
      seven,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawPath(seven, ink);
    canvas.drawPath(
      Path()
        ..moveTo(42, 22)
        ..lineTo(122, 22)
        ..lineTo(122, 32)
        ..lineTo(62, 136)
        ..lineTo(54, 136)
        ..lineTo(111, 34)
        ..lineTo(42, 34)
        ..close(),
      cutout,
    );
    for (var x = 89.0; x <= 177; x += 22) {
      canvas.drawRect(Rect.fromLTWH(x, 137, 12, 11), ink);
    }
    canvas.drawRect(const Rect.fromLTWH(6, 154, 184, 12), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      color != oldDelegate.color ||
      backgroundColor != oldDelegate.backgroundColor;
}
