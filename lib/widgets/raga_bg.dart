import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

// App background: Wisnu's art, drawn full-bleed behind everything.
// Dark mode: his gradient PNG + painted illustration (concentric rings
// top-left, ECG pulse line, leaf branches top-right & bottom-left).
// Light mode: same illustration over a light lavender gradient —
// the PNG is dark-only, so the light canvas is painted in code.
// The glass cards blur this, so it doubles as the frost source.
class RagaBg extends StatelessWidget {
  final Widget child;
  const RagaBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      color: rc.bgFallback,
      child: Stack(
        children: [
          if (rc.isDark)
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/images/raga-bg.png'),
                fit: BoxFit.cover,
              ),
            )
          else
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF8F5FF),
                      Color(0xFFE9DEF9),
                      Color(0xFFD9CBF3),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(painter: _DecoPainter(rc)),
          ),
          child,
        ],
      ),
    );
  }
}

class _DecoPainter extends CustomPainter {
  final RagaColors rc;
  _DecoPainter(this.rc);

  @override
  void paint(Canvas canvas, Size size) {
    _rings(canvas, size);
    _ecg(canvas, size);
    // Top-right branch: from off-screen top-right, sweeping down-left.
    _branch(
      canvas,
      Offset(size.width * 1.04, -size.height * 0.03),
      Offset(size.width * 0.60, size.height * 0.30),
      size.width * 0.16,
    );
    // Bottom-left branch: from off-screen bottom-left, sweeping up-right.
    _branch(
      canvas,
      Offset(-size.width * 0.04, size.height * 1.03),
      Offset(size.width * 0.40, size.height * 0.68),
      size.width * 0.15,
    );
  }

  void _rings(Canvas canvas, Size size) {
    final c = Offset(-size.width * 0.10, size.height * 0.11);
    final paint = Paint()
      ..color = rc.decoRings
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final r in [70.0, 122.0, 174.0]) {
      canvas.drawCircle(c, r, paint);
    }
  }

  void _ecg(Canvas canvas, Size size) {
    final y = size.height * 0.52;
    final w = size.width;
    final p = Path()
      ..moveTo(0, y)
      ..lineTo(w * 0.355, y)
      ..lineTo(w * 0.410, y - 30)
      ..lineTo(w * 0.448, y + 38)
      ..lineTo(w * 0.474, y - 12)
      ..lineTo(w * 0.500, y)
      ..lineTo(w, y);
    canvas.drawPath(
      p,
      Paint()
        ..color = rc.decoEcg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _branch(Canvas canvas, Offset start, Offset end, double leafLen) {
    final ctrl = Offset(
      (start.dx + end.dx) / 2 + (end.dy - start.dy) * 0.18,
      (start.dy + end.dy) / 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
      Paint()
        ..color = rc.decoLeafVein
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 1; i <= 5; i++) {
      final t = i / 6;
      final pos = _quadPoint(start, ctrl, end, t);
      final tan = _quadTangent(start, ctrl, end, t);
      final ang = atan2(tan.dy, tan.dx);
      final size = leafLen * (1 - t * 0.30);
      _leaf(canvas, pos, ang + 0.75, size);
      _leaf(canvas, pos, ang - 0.75, size * 0.88);
    }
  }

  void _leaf(Canvas canvas, Offset base, double angle, double len) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.34, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.34, 0, 0)
        ..close(),
      Paint()..color = rc.decoLeaf,
    );
    canvas.drawLine(
      Offset(len * 0.10, 0),
      Offset(len * 0.90, 0),
      Paint()
        ..color = rc.decoLeafVein
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  Offset _quadPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  Offset _quadTangent(Offset p0, Offset p1, Offset p2, double t) {
    return Offset(
      2 * (1 - t) * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx),
      2 * (1 - t) * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _DecoPainter old) => old.rc != rc;
}
