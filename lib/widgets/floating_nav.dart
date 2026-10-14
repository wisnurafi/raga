import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme.dart';

// Glassmorphism bottom nav: a floating frosted pill. The active tab
// becomes a gradient capsule with a smooth expand animation.
class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const FloatingNav({super.key, required this.index, required this.onTap});

  static const _items = [
    (Icons.calculate_outlined, Icons.calculate),
    (Icons.show_chart_outlined, Icons.show_chart),
    (Icons.favorite_outline, Icons.favorite),
    (Icons.local_fire_department_outlined, Icons.local_fire_department),
    (Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7E6EE8).withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final active = i == index;
                final (iconOut, iconFill) = _items[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 11),
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
                      child: Center(
                        child: AnimatedScale(
                          scale: active ? 1.0 : 0.94,
                          duration: const Duration(milliseconds: 280),
                          child: Icon(
                            active ? iconFill : iconOut,
                            size: 23,
                            color: active ? rc.onPrimaryBtn : rc.onBgMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
