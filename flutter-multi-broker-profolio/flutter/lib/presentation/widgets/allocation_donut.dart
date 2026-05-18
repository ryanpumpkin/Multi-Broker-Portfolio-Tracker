import 'dart:math' as math;

import 'package:flutter/material.dart';

class AllocationDonut extends StatelessWidget {
  const AllocationDonut({
    required this.allocations,
    super.key,
  });

  final Map<String, double> allocations;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allocation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: CustomPaint(
                      painter: _DonutPainter(allocations: allocations),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: allocations.entries
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${e.key}: ${e.value.toStringAsFixed(1)}%',
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.allocations});

  final Map<String, double> allocations;

  static final List<Color> _palette = [
    const Color(0xFF006C84),
    const Color(0xFF4A8F29),
    const Color(0xFF9A3A00),
    const Color(0xFFAA2E5D),
    const Color(0xFF5A33B8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (allocations.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = allocations.values.fold<double>(0, (a, b) => a + b);
    var start = -math.pi / 2;
    var index = 0;

    for (final value in allocations.values) {
      final sweep = 2 * math.pi * (value / total);
      final paint = Paint()
        ..color = _palette[index % _palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.42;
      canvas.drawArc(rect.deflate(radius * 0.21), start, sweep, false, paint);
      start += sweep;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.allocations != allocations;
  }
}
