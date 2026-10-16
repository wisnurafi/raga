import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'detak_assets.dart';
import 'detak_widget.dart';

/// Speech bubble used for Detak's contextual messages (mockup 1 & 3).
class DetakBubble extends StatelessWidget {
  final String text;

  const DetakBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2B2540),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(26, 12),
          painter: _BubbleTailPainter(),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width / 2 - 9, 0)
      ..lineTo(size.width / 2 + 9, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(
        p, Paint()..color = Colors.white.withValues(alpha: 0.94));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Mood pill ("Senang", "Ngantuk", ...) — color per mood.
class DetakMoodChip extends StatelessWidget {
  final DetakMood mood;

  const DetakMoodChip({super.key, required this.mood});

  static const _colors = {
    DetakMood.halo: [Color(0xFF9AA0B4), Color(0xFF20242E)],
    DetakMood.senang: [Color(0xFF6FCF97), Color(0xFF1E3A2B)],
    DetakMood.semangat: [Color(0xFFF2A93B), Color(0xFF3A2A10)],
    DetakMood.ngantuk: [Color(0xFF7C8DB0), Color(0xFF1F2A3A)],
    DetakMood.dukung: [Color(0xFF6FB7D6), Color(0xFF1E3A4A)],
    DetakMood.bangga: [Color(0xFFF2C94C), Color(0xFF3A2E10)],
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[mood]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        detakMoodLabel(context, mood),
        style: TextStyle(
          color: c[1],
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "Lv. 4" pill — muted, next to the mood chip.
class DetakLevelChip extends StatelessWidget {
  final int level;

  const DetakLevelChip({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: rc.chipInactive,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Lv. $level',
        style: TextStyle(
          color: rc.onChipInactive,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Rounded progress bar (kedekatan / tahap pertumbuhan).
class DetakProgressBar extends StatelessWidget {
  final double progress;
  final double height;

  const DetakProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: rc.sliderTrack,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: rc.chipActive),
        ),
      ),
    );
  }
}
