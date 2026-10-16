import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Floating bottom nav pill: 6 tabs, no labels. The active tab sits on a
/// lavender circle with a white icon — exactly like the mockup.
/// (The mockup draws 4 tabs; Streak is the 4th, Arena 5th, Profile 6th.)
class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const FloatingNav({super.key, required this.index, required this.onTap});

  static const _icons = [
    Icons.calculate_outlined,
    Icons.show_chart_outlined,
    Icons.favorite_outline,
    Icons.local_fire_department_outlined,
    Icons.emoji_events_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    // Explicit height: this pill once rendered full-screen when its
    // height was left to the content. Never remove the SizedBox.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        child: SizedBox(
          height: 68,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: rc.navBg,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: rc.navBorder, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < _icons.length; i++)
                      _Tab(
                        icon: _icons[i],
                        active: i == index,
                        onTap: () => onTap(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? rc.navActive : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 24,
          color: active ? rc.navActiveIcon : rc.navIcon,
        ),
      ),
    );
  }
}
