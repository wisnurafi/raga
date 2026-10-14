import 'dart:math';
import 'package:flutter/material.dart';
import '../core/bmi.dart';

/// Gauge BMI setengah lingkaran, digambar manual dengan CustomPainter.
/// Empat segmen warna sesuai kategori + penanda posisi nilai.
class BmiGauge extends StatelessWidget {
  final double bmi;
  const BmiGauge({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(bmi),
      child: const SizedBox(height: 168, width: double.infinity),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double bmi;
  _GaugePainter(this.bmi);

  static const _min = 12.0;
  static const _max = 42.0;

  double _angle(double v) {
    final c = v.clamp(_min, _max);
    return pi + (c - _min) / (_max - _min) * pi;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 14);
    final radius = min(size.width / 2 - 28, size.height - 28);
    final rect = Rect.fromCircle(center: center, radius: radius);

    const trackW = 26.0;
    final trackPaint = Paint()
      ..color = const Color(0xFFE7E2F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackW
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, trackPaint);

    // Segmen kategori dengan sedikit jeda antar segmen.
    const bounds = [12.0, 18.5, 25.0, 30.0, 42.0];
    const colors = [
      Color(0xFF5AA9E6),
      Color(0xFF3ED598),
      Color(0xFFF2B544),
      Color(0xFFF2555A),
    ];
    const gap = 0.035;
    for (var i = 0; i < 4; i++) {
      final a0 = _angle(bounds[i]) + gap;
      final a1 = _angle(bounds[i + 1]) - gap;
      final p = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, a0, a1 - a0, false, p);
    }

    // Penanda posisi nilai: lingkaran putih dengan ring gelap.
    final a = _angle(bmi);
    final pos = center + Offset(cos(a) * radius, sin(a) * radius);
    canvas.drawCircle(
      pos,
      13,
      Paint()..color = const Color(0xFF1B1B2F),
    );
    canvas.drawCircle(
      pos,
      9,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.bmi != bmi;
}

/// Legenda kategori di bawah gauge: titik warna + nama.
class GaugeLegend extends StatelessWidget {
  final BmiCategory active;
  const GaugeLegend({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: BmiCategory.values.map((c) {
        final meta = categoryMeta[c]!;
        final isActive = c == active;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: meta.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              meta.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1B1B2F)
                    : const Color(0xFF8A86AD),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
