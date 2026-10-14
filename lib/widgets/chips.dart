import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Base selectable pill. Selected = lavender fill + DARK navy label,
/// exactly like the mockup.
class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final EdgeInsetsGeometry padding;
  final Widget? prefix;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? rc.chipActive : rc.chipInactive,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: selected ? rc.chipActive : rc.chipBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefix != null) ...[
              prefix!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: RagaType.chip(
                selected ? rc.onChipActive : rc.onChipInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile chip from the home header ("Wisnu ✓", "Ibu", "+ Tambah").
class ProfileChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showCheck;
  final bool isAdd;
  final VoidCallback onTap;

  const ProfileChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return _Pill(
      label: label,
      selected: selected,
      onTap: onTap,
      prefix: showCheck && selected
          ? Icon(Icons.check, size: 16, color: rc.onChipActive)
          : (isAdd ? Icon(Icons.add, size: 16, color: rc.onChipInactive) : null),
    );
  }
}

/// Activity level chip ("Minim", "Ringan ✓", "Sedang", "Berat").
class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return _Pill(
      label: label,
      selected: selected,
      onTap: onTap,
      prefix: selected
          ? Icon(Icons.check, size: 16, color: rc.onChipActive)
          : null,
    );
  }
}

/// Day chip for the weigh-in schedule ("Sen".."Min"). Selected chips get
/// the dot indicator under the label, like the mockup.
class DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DayChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 64,
        decoration: BoxDecoration(
          color: selected ? rc.chipActive : rc.chipInactive,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: selected ? rc.chipActive : rc.chipBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: RagaType.chip(
                selected ? rc.onChipActive : rc.onChipInactive,
              ).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? rc.onChipActive : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pace option pill ("0.25 kg", "0.5 kg", "0.75 kg").
class PaceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PaceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      selected: selected,
      onTap: onTap,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

/// Two/three-option segmented control ("cm · kg" / "in · lb",
/// "Pria" / "Wanita", "Turun" / "Jaga" / "Naik").
class RagaSegmented extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const RagaSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: rc.isDark ? rc.chipInactive : const Color(0xFFE4E0F4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selected
                        ? (rc.isDark ? rc.chipActive : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: i == selected && !rc.isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      options[i],
                      style: RagaType.chip(
                        i == selected
                            ? (rc.isDark ? rc.onCard : rc.onChipActive)
                            : rc.onCardMuted,
                      ).copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
