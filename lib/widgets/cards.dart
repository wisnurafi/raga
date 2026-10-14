import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../state/app_state.dart';
import 'glass.dart';

// Glass card for number input + slider.
class MeasureCard extends StatelessWidget {
  final String label;
  final double displayValue;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const MeasureCard({
    super.key,
    required this.label,
    required this.displayValue,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: rc.mintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  label.contains('Tinggi')
                      ? Icons.height
                      : Icons.monitor_weight_outlined,
                  size: 19,
                  color: rc.mint,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: rc.onCardMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatNum(displayValue, 0),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  color: rc.onCard,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: rc.primaryBtn,
              inactiveTrackColor: const Color(0xFFE4DEFB),
              thumbColor: rc.primaryBtn,
            ),
            child: Slider(
              value: displayValue.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// Unit toggle: cm·kg / in·lb (glass pill).
class UnitToggle extends StatelessWidget {
  const UnitToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(context, 'cm · kg', state.metricUnits,
              () => state.setMetricUnits(true)),
          _seg(context, 'in · lb', !state.metricUnits,
              () => state.setMetricUnits(false)),
        ],
      ),
    );
  }

  Widget _seg(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [rc.primaryBtn, const Color(0xFF9A8CF5)],
                )
              : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? rc.onPrimaryBtn : rc.onBgMuted,
          ),
        ),
      ),
    );
  }
}

// Profile chips row + add button.
class ProfileChips extends StatelessWidget {
  const ProfileChips({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.profiles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == state.profiles.length) {
            return GestureDetector(
              onTap: () => _showAddDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: rc.onImage),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: rc.onImage,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final p = state.profiles[i];
          final active = p.id == state.activeProfileId;
          return GestureDetector(
            onTap: () => state.setActiveProfile(p.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        colors: [rc.primaryBtn, const Color(0xFF9A8CF5)],
                      )
                    : null,
                color: active
                    ? null
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: rc.primaryBtn.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? rc.onPrimaryBtn : rc.onBg,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New profile'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Name, e.g. Dad',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(ctx, ctrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submit(ctx, ctrl),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext ctx, TextEditingController ctrl) {
    final name = ctrl.text.trim();
    Navigator.pop(ctx);
    if (name.isNotEmpty) AppState.of(ctx).addProfile(name);
  }
}

// Raga's primary button.
class RagaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  const RagaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: outlined
              ? Colors.white.withValues(alpha: 0.5)
              : rc.primaryBtn,
          foregroundColor: outlined ? rc.onBg : rc.onPrimaryBtn,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: outlined
                ? BorderSide(
                    color: rc.primaryBtn.withValues(alpha: 0.55),
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
          textStyle:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

// Small section heading above content.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: rc.onImage,
              letterSpacing: -0.3,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
