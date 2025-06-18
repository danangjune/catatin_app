import 'package:flutter/material.dart';

class SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  SparklinePainter(this.dataPoints, {this.color = const Color(0xFF20BF55)});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final horizontalStep = width / (dataPoints.length - 1);

    path.moveTo(0, height - (dataPoints[0] * height));

    for (int i = 1; i < dataPoints.length; i++) {
      path.lineTo(horizontalStep * i, height - (dataPoints[i] * height));
    }

    canvas.drawPath(path, paint);

    // Draw gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, width, height))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints || oldDelegate.color != color;
  }
}
