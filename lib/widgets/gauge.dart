import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

// Half-circle BMI gauge from the mockup: four color segments
// (blue/green/yellow/red) with a white-dot marker sitting ON the arc,
// dark-ringed like the design.
class ResultGauge extends StatelessWidget {
  final double bmi;
  const ResultGauge({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(bmi, context.rc),
      child: const SizedBox(height: 190, width: double.infinity),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double bmi;
  final RagaColors rc;
  _GaugePainter(this.bmi, this.rc);

  static const _min = 14.0;
  static const _max = 34.0;

  double _angle(double v) {
    final c = v.clamp(_min, _max);
    return pi + (c - _min) / (_max - _min) * pi;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 16);
    final radius = min(size.width / 2 - 30, size.height - 30);
    final rect = Rect.fromCircle(center: center, radius: radius);

    const trackW = 24.0;
    const bounds = [14.0, 18.5, 25.0, 30.0, 34.0];
    final colors = [rc.catUnder, rc.catNormal, rc.catOver, rc.catObese];
    const gap = 0.03;
    for (var i = 0; i < 4; i++) {
      final a0 = _angle(bounds[i]) + gap;
      final a1 = _angle(bounds[i + 1]) - gap;
      canvas.drawArc(
        rect,
        a0,
        a1 - a0,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Value marker: white dot with a dark ring, sitting on the arc.
    final a = _angle(bmi);
    final pos = center + Offset(cos(a) * radius, sin(a) * radius);
    canvas.drawCircle(pos, 14, Paint()..color = const Color(0xFF2B2358));
    canvas.drawCircle(pos, 9.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.bmi != bmi || old.rc != rc;
}

// Category legend under the gauge: color dot + name, like the mockup.
class GaugeLegend extends StatelessWidget {
  final BmiCat active;
  const GaugeLegend({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: BmiCat.values.map((c) {
        final isActive = c == active;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: rc.badgeFor(c),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              bmiCatLabel(c),
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? rc.onCard : rc.onCardMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
