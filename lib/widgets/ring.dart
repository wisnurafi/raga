import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Donut progress ring from the health screen: "73%" over "BMR",
/// lavender arc on a soft track.
class DonutRing extends StatelessWidget {
  final double percent;
  final double size;
  final String centerTop;
  final String centerBottom;

  const DonutRing({
    super.key,
    required this.percent,
    this.size = 110,
    required this.centerTop,
    required this.centerBottom,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              percent: percent.clamp(0.0, 1.0),
              track: rc.isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFEDF0F8),
              fill: rc.chipActive,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTop,
                style: RagaType.hero(22, rc.onCard),
              ),
              Text(
                centerBottom,
                style: RagaType.label(rc.onCardMuted).copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;
  final Color track;
  final Color fill;

  _DonutPainter({
    required this.percent,
    required this.track,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2,
        size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      percent * math.pi * 2,
      false,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.percent != percent;
}
