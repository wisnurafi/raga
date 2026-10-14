import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme.dart';

// Floating bottom nav from the mockup: a frosted pill with five icons,
// no labels. The active tab is a solid lavender circle; the rest are
// quiet icons. The pill's inner height is pinned: Scaffold lays out
// bottomNavigationBar with unbounded height, and without an explicit
// height this tree once measured itself at full screen. Never again.
class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const FloatingNav({super.key, required this.index, required this.onTap});

  static const _icons = [
    Icons.calculate_outlined,
    Icons.show_chart_outlined,
    Icons.favorite_outline,
    Icons.local_fire_department_outlined,
    Icons.person_outline,
  ];

  static const _iconsActive = [
    Icons.calculate,
    Icons.show_chart,
    Icons.favorite,
    Icons.local_fire_department,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                color: rc.navBg,
                border: Border.all(color: rc.cardBorder, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_icons.length, (i) {
                  final active = i == index;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            active ? rc.navActive : Colors.transparent,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: rc.navActive
                                      .withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        active ? _iconsActive[i] : _icons[i],
                        size: 25,
                        color:
                            active ? rc.navActiveIcon : rc.navIcon,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
