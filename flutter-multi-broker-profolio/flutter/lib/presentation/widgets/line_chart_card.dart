import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChartPoint {
  const ChartPoint(this.x, this.y);

  final double x;
  final double y;
}

class LineChartCard extends StatelessWidget {
  const LineChartCard({
    required this.title,
    required this.points,
    this.color,
    super.key,
  });

  final String title;
  final List<ChartPoint> points;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _LinePainter(
                  points: points,
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.points, required this.color});

  final List<ChartPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      axis,
    );

    if (points.length < 2) {
      return;
    }

    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final spanY = (maxY - minY).abs() < 0.0001 ? 1.0 : maxY - minY;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final dx = size.width * (i / (points.length - 1));
      final normalized = (p.y - minY) / spanY;
      final dy = size.height - (normalized * (size.height - 8)) - 8;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
