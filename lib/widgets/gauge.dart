import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Half-circle BMI gauge from the mockup: four color segments
/// (blue → green → yellow → red) with a white marker dot on a navy ring.
///
/// Scale 15–40; segment boundaries sit at 14% / 40% / 60% of the arc
/// (BMI 18.5 / 25 / 30).
class BmiGauge extends StatelessWidget {
  final double bmi;
  final double height;

  const BmiGauge({super.key, required this.bmi, this.height = 190});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _GaugePainter(
          bmi: bmi,
          colors: [rc.catUnder, rc.catNormal, rc.catOver, rc.catObese],
          markerRing: const Color(0xFF2A2370),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double bmi;
  final List<Color> colors;
  final Color markerRing;

  // Segment edges as fractions of the 180° arc.
  static const _edges = [0.0, 0.14, 0.40, 0.60, 1.0];

  _GaugePainter({
    required this.bmi,
    required this.colors,
    required this.markerRing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final radius = math.min(size.width / 2 - stroke, size.height - stroke * 1.6);
    final center = Offset(size.width / 2, size.height - stroke * 0.8);
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (var i = 0; i < 4; i++) {
      final start = math.pi + _edges[i] * math.pi;
      final sweep = (_edges[i + 1] - _edges[i]) * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Marker dot at the BMI position.
    final t = ((bmi - 15) / 25).clamp(0.0, 1.0);
    final a = math.pi + t * math.pi;
    final dot = Offset(
      center.dx + radius * math.cos(a),
      center.dy + radius * math.sin(a),
    );
    canvas.drawCircle(dot, 17, Paint()..color = markerRing);
    canvas.drawCircle(dot, 11, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.bmi != bmi;
}

/// Small ring badge used in history rows: BMI value inside a
/// category-colored ring.
class BmiRing extends StatelessWidget {
  final double bmi;
  final double size;

  const BmiRing({super.key, required this.bmi, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final cat = bmiCatOf(bmi);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: rc.catColor(cat), width: 4),
      ),
      child: Center(
        child: Text(
          bmi.toStringAsFixed(1),
          style: RagaType.chip(rc.onCard).copyWith(fontSize: 14),
        ),
      ),
    );
  }
}
