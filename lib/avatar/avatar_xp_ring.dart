import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Circular XP progress ring with the avatar nested inside it.
///
/// The arc shows progress toward the next level ([percent] 0..1); the
/// avatar itself is rendered by [AvatarView] and only passed through here.
class XpRing extends StatelessWidget {
  final double percent;
  final double size;
  final double avatarSize;
  final Widget child;

  const XpRing({
    super.key,
    required this.percent,
    required this.child,
    this.size = 176,
    this.avatarSize = 144,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Semantics(
      label: 'XP ring',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _XpRingPainter(
                percent: percent.clamp(0.0, 1.0),
                track: rc.isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFEDF0F8),
                fill: rc.chipActive,
              ),
            ),
            SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _XpRingPainter extends CustomPainter {
  final double percent;
  final Color track;
  final Color fill;

  _XpRingPainter({
    required this.percent,
    required this.track,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    if (percent > 0) {
      final fillPaint = Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * percent, false,
          fillPaint);
    }
  }

  @override
  bool shouldRepaint(_XpRingPainter old) =>
      old.percent != percent ||
      old.track != track ||
      old.fill != fill;
}
