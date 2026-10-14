import 'package:flutter/material.dart';
import '../core/theme.dart';

// Selectable pill from the mockup: profile chips ("Wisnu ✓", "Ibu",
// "+ Add"), activity levels, pace options. Selected = lavender fill,
// unselected = glass.
class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;
  final EdgeInsetsGeometry padding;

  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: selected ? rc.chipActive : rc.chipInactive,
          border: Border.all(
            color: selected ? Colors.transparent : rc.cardBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? rc.onChipActive : rc.onChipInactive,
              ),
            ),
            if (showCheck && selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check,
                  size: 16, color: rc.onChipActive, weight: 700),
            ],
          ],
        ),
      ),
    );
  }
}

// Segmented control from the mockup: Male/Female, cm·kg/in·lb,
// Lose/Maintain/Gain, Weight/BMI. Glass track, lavender thumb that
// slides to the selected option.
class Segmented<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final double height;

  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelOf,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: rc.chipInactive,
        border: Border.all(color: rc.cardBorder, width: 1.2),
      ),
      child: Row(
        children: options.map((o) {
          final sel = o == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(height / 2 - 4),
                  color: sel ? rc.chipActive : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    labelOf(o),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? rc.onChipActive : rc.onChipInactive,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Vertical day pill for the weigh-in schedule (Mon..Sun). The dot marks
// a selected day, like the mockup.
class DayPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DayPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? rc.chipActive : rc.chipInactive,
          border: Border.all(
            color: selected ? Colors.transparent : rc.cardBorder,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? rc.onChipActive : rc.onChipInactive,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? rc.onChipActive
                    : rc.onChipInactive.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
