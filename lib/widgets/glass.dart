import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme.dart';

// Frosted-glass card from the mockup: blurs the illustrated background,
// translucent surface, hairline edge. All tones come from the theme so
// dark and light mode both read as glass, not flat pastel.
//
// Needs something behind it (like [RagaBg]) for the blur to show.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.blur = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final card = Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: rc.card,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: rc.cardBorder, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
