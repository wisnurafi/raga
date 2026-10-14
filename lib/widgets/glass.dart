import 'dart:ui';

import 'package:flutter/material.dart';

// Frosted-glass card: blurs what's behind it, translucent white surface,
// gradient edge highlight (bright at the top, fading down), and a soft
// light falling from the top inside the glass.
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
    this.blur = 24,
    this.opacity = 0.34,
  });

  @override
  Widget build(BuildContext context) {
    // Gradient border thickness. Kept small so the inner radius math
    // never goes negative on the tighter cards.
    const edge = 1.4;
    final innerRadius = (borderRadius - edge).clamp(0.0, borderRadius);
    return Padding(
      padding: margin,
      child: Container(
        // Border shell: the gradient is the edge highlight — bright at
        // the top edge, fading toward the bottom.
        padding: const EdgeInsets.all(edge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.18),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E6EE8).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: Stack(
                children: [
                  // Soft light falling from the top inside the glass.
                  // Positioned, so it never affects the card's size.
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x33FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
