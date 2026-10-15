import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';

/// Main screen header: avatar circle left, centered title, language +
/// theme toggles right — the mockup's header on home/history/health.
class RagaHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool showThemeToggle;

  const RagaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    return Row(
      children: [
        leading ??
            _Avatar(letter: state.activeProfile.initial),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: RagaType.title(rc.onBg),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: RagaType.label(rc.onBgMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        trailing ??
            (showThemeToggle
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LocaleButton(),
                      SizedBox(width: 10),
                      _MoonButton(),
                    ],
                  )
                : const SizedBox(width: 44)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String letter;

  const _Avatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rc.avatarBg,
      ),
      child: Center(
        child: Text(
          letter,
          style: RagaType.hero(20, rc.avatarFg),
        ),
      ),
    );
  }
}

class _MoonButton extends StatelessWidget {
  const _MoonButton();

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    return _CircleBtn(
      icon: state.darkMode
          ? Icons.dark_mode_outlined
          : Icons.light_mode_outlined,
      onTap: () => state.setDarkMode(!state.darkMode),
    );
  }
}

/// Language toggle: a 44px circle like the moon button. Shows the
/// language you switch TO ("EN" while Indonesian, "ID" while English),
/// and flips every string instantly via AppState.notifyListeners.
class _LocaleButton extends StatelessWidget {
  const _LocaleButton();

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final label = state.locale == 'id' ? 'EN' : 'ID';
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rc.iconBtnBg,
          border: Border.all(color: rc.cardBorder, width: 1),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () =>
              state.setLocale(state.locale == 'id' ? 'en' : 'id'),
          child: Center(
            child: Text(
              label,
              style: RagaType.chip(rc.iconBtnFg).copyWith(fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round header button (back chevron, share, moon).
class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => _CircleBtn(icon: icon, onTap: onTap);
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rc.iconBtnBg,
          border: Border.all(color: rc.cardBorder, width: 1),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: rc.iconBtnFg, size: 20),
        ),
      ),
    );
  }
}

/// Onboarding top bar: back chevron, 4-segment progress, "n/4".
class OnboardingTopBar extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback onBack;

  const OnboardingTopBar({
    super.key,
    required this.step,
    this.total = 4,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Row(
      children: [
        CircleBtn(icon: Icons.chevron_left, onTap: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(
                      right: i == total - 1 ? 0 : 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i < step
                          ? rc.chipActive
                          : rc.onBg.withValues(alpha: 0.18),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '$step/$total',
          style: RagaType.label(rc.onBg),
        ),
      ],
    );
  }
}
