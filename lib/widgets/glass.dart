import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Card used everywhere in the app. Radius 26, blur 20, hairline border,
/// soft shadow — the mockup's card language.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 26,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: rc.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: rc.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: rc.cardShadow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
