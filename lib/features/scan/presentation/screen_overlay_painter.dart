// Pégalo al final del archivo scan_screen.dart
import 'package:flutter/cupertino.dart';

class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  CornerPainter({required this.color, this.strokeWidth = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Bordes redondeados en las puntas

    double cornerLength = 30.0; // Largo de la esquina

    // Esquina Superior Izquierda
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Esquina Superior Derecha
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Esquina Inferior Derecha
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );

    // Esquina Inferior Izquierda
    canvas.drawPath(
      Path()
        ..moveTo(cornerLength, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}