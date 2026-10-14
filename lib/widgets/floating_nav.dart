import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Bottom navigation versi improve: floating pill yang ngambang,
/// tab aktif jadi kapsul highlight dengan animasi geser yang halus.
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: rc.cardDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? rc.primaryBtn : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: active ? 1.0 : 0.92,
                      duration: const Duration(milliseconds: 260),
                      child: Icon(
                        active ? iconFill : iconOut,
                        size: 21,
                        color: active ? rc.onPrimaryBtn : rc.onBgMuted,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: active
                          ? Padding(
                              padding: const EdgeInsets.only(left: 7),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
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
    );
  }
}
