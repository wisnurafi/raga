import 'package:flutter/material.dart';
import '../core/theme.dart';

// Big number + unit + slider, exactly like the mockup's
// "Height 170 cm" / "Weight 65 kg" blocks.
class MeasureSlider extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int decimals;

  const MeasureSlider({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: rc.onCardMuted,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toStringAsFixed(decimals),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: rc.onCard,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              unit,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: rc.onCardMuted,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: rc.sliderFill,
            inactiveTrackColor: rc.sliderTrack,
            thumbColor: rc.sliderThumb,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 13,
              elevation: 2,
            ),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Round − / + stepper flanking a big value, like the mockup's
// age stepper ("Umur − 21 +") and target-weight stepper.
class StepperRow extends StatelessWidget {
  final Widget value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const StepperRow({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StepBtn(icon: Icons.remove, onTap: onMinus),
        value,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rc.chipInactive,
          border: Border.all(color: rc.cardBorder, width: 1.2),
        ),
        child: Icon(icon, color: rc.onCard, size: 22),
      ),
    );
  }
}

// Small labeled row inside a GlassCard: label left, value right.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: rc.onCardMuted,
          ),
        ),
        trailing ??
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: rc.onCard,
              ),
            ),
      ],
    );
  }
}

// Category badge pill ("Normal") — tinted per category like the mockup.
class CategoryBadge extends StatelessWidget {
  final BmiCat cat;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CategoryBadge({
    super.key,
    required this.cat,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: rc.badgeFor(cat),
      ),
      child: Text(
        bmiCatLabel(cat),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: rc.onBadgeFor(cat),
        ),
      ),
    );
  }
}
