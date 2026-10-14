import 'dart:ui';

import 'package:flutter/material.dart';

// Frosted-glass card: blurs what's behind it, translucent white surface,
// thin light border, soft shadow.
//
// Needs something behind it (like [HealthBg]) for the blur to show.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.blur = 18,
    this.opacity = 0.42,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7E6EE8).withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
