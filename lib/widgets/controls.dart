import 'package:flutter/material.dart';

import '../core/theme.dart';

/// "Tinggi badan / 170 cm" block: small label, huge number + unit,
/// lavender slider underneath — the mockup's measure block.
class MeasureSlider extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double sliderValue;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const MeasureSlider({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RagaType.label(rc.onCardMuted)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: RagaType.hero(48, rc.onCard)),
            const SizedBox(width: 8),
            Text(unit, style: RagaType.label(rc.onCardMuted)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: rc.sliderFill,
            inactiveTrackColor: rc.sliderTrack,
            thumbColor: rc.sliderThumb,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: _RingThumb(
              radius: 11,
              fill: rc.sliderThumb,
              ring: rc.sliderRing,
            ),
          ),
          child: Slider(
            value: sliderValue.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _RingThumb extends SliderComponentShape {
  final double radius;
  final Color fill;
  final Color ring;

  const _RingThumb({
    required this.radius,
    required this.fill,
    required this.ring,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius + 3);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, radius + 3, Paint()..color = ring);
    canvas.drawCircle(center, radius, Paint()..color = fill);
  }
}

/// Round − / + stepper buttons with a big value between them
/// (age stepper, target-weight stepper).
class StepperRow extends StatelessWidget {
  final String value;
  final String? unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final double valueSize;

  const StepperRow({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.unit,
    this.valueSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepBtn(icon: Icons.remove, onTap: onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: RagaType.hero(valueSize, rc.onCard)),
              if (unit != null) ...[
                const SizedBox(width: 6),
                Text(unit!, style: RagaType.label(rc.onCardMuted)),
              ],
            ],
          ),
        ),
        _StepBtn(icon: Icons.add, onTap: onPlus),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: rc.cardBorder, width: 1.5),
          color: rc.card,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: rc.onCard, size: 22),
        ),
      ),
    );
  }
}
