import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/app_state.dart';

// Main screen header from the mockup: avatar circle left, centered
// title, dark/light toggle right. The moon/sun button flips [AppState.darkMode].
class RagaHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showAvatar;

  const RagaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final name = state.activeProfile.name.trim();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Row(
      children: [
        if (showAvatar)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rc.avatarBg,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: rc.avatarFg,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 52),
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: rc.onBg,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: rc.onBgMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        _CircleBtn(
          icon: rc.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          onTap: () => state.setDarkMode(!state.darkMode),
        ),
      ],
    );
  }
}

// Onboarding header: back chevron, segmented progress, "n/4" label.
class OnboardHeader extends StatelessWidget {
  final int step; // 1-based
  final int total;
  final VoidCallback onBack;

  const OnboardHeader({
    super.key,
    required this.step,
    required this.total,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Row(
      children: [
        _CircleBtn(icon: Icons.chevron_left, onTap: onBack, size: 46),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              final filled = i < step;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(
                      right: i == total - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: filled
                        ? rc.chipActive
                        : rc.onBgMuted.withValues(alpha: 0.30),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$step/$total',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: rc.onBgMuted,
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rc.chipInactive,
          border: Border.all(color: rc.cardBorder, width: 1.2),
        ),
        child: Icon(icon, color: rc.onBg, size: 24),
      ),
    );
  }
}
