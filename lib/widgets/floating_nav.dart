import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Bottom navigation glassmorphism: pil kaca mengambang dengan blur,
/// tab aktif jadi kapsul gradien dengan animasi membesar yang halus.
class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const FloatingNav({super.key, required this.index, required this.onTap});

  static const _items = [
    (Icons.calculate_outlined, Icons.calculate, 'Hitung'),
    (Icons.show_chart_outlined, Icons.show_chart, 'Riwayat'),
    (Icons.favorite_outline, Icons.favorite, 'Kesehatan'),
    (Icons.person_outline, Icons.person, 'Profil'),
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
                final (iconOut, iconFill, label) = _items[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
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
                            duration: const Duration(milliseconds: 280),
                            child: Icon(
                              active ? iconFill : iconOut,
                              size: 22,
                              color: active
                                  ? rc.onPrimaryBtn
                                  : rc.onBgMuted,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: active
                                ? Padding(
                                    padding:
                                        const EdgeInsets.only(left: 8),
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
