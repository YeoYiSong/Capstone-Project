import 'package:flutter/material.dart';
import '../models/doodle_stroke.dart';

class Assys extends CustomPainter {
  final List<DoodleStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;

  Assys(this.strokes, this.currentStroke, this.currentColor);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint =
          Paint()
            ..color = stroke.color
            ..strokeWidth = 5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      final path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (var point in stroke.points) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    if (currentStroke.isNotEmpty) {
      final paint =
          Paint()
            ..color = currentColor
            ..strokeWidth = 5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (var point in currentStroke) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant Assys oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.currentColor != currentColor;
  }
}
