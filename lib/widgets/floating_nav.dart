import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'glass.dart';

// Glassmorphism bottom nav: a floating frosted pill. The active tab
// expands into a gradient capsule with its label; the rest stay icons.
// The pill's inner height is pinned: Scaffold lays out bottomNavigationBar
// with unbounded height, and without an explicit height this tree once
// measured itself at full screen. Never again.
class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const FloatingNav({super.key, required this.index, required this.onTap});

  static const _items = [
    (Icons.calculate_outlined, Icons.calculate, 'Calculate'),
    (Icons.show_chart_outlined, Icons.show_chart, 'History'),
    (Icons.favorite_outline, Icons.favorite, 'Health'),
    (
      Icons.local_fire_department_outlined,
      Icons.local_fire_department,
      'Streak'
    ),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  // Width of the expanded (active) tab. "Calculate" is the longest label;
  // 128 fits icon + gap + label + capsule padding on a 360pt screen.
  static const _activeWidth = 128.0;

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SafeArea(
      top: false,
      child: GlassContainer(
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        borderRadius: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        blur: 28,
        opacity: 0.52,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final inactiveWidth =
                  (constraints.maxWidth - _activeWidth) / (_items.length - 1);
              return Row(
                children: List.generate(_items.length, (i) {
                  final active = i == index;
                  final (iconOut, iconFill, label) = _items[i];
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: active ? _activeWidth : inactiveWidth,
                      // Inactive tabs are icon-only in a narrow slot: no
                      // horizontal padding, or the 23px icon overflows it.
                      padding: EdgeInsets.symmetric(
                          horizontal: active ? 14 : 0, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: active
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  rc.primaryBtn,
                                  const Color(0xFF9A8CF5),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: rc.primaryBtn
                                      .withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: active ? 1.0 : 0.94,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              active ? iconFill : iconOut,
                              size: 23,
                              color: active ? rc.onPrimaryBtn : rc.onBgMuted,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: active
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: rc.onPrimaryBtn,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
