import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Full-screen illustrated background: Wisnu's own art, dark or light
/// variant depending on the theme.
class RagaBg extends StatelessWidget {
  final Widget child;

  const RagaBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      color: rc.bgFallback,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              rc.isDark
                  ? 'assets/images/raga-bg.png'
                  : 'assets/images/raga-bg-light.png',
              fit: BoxFit.cover,
            ),
          ),
          // Must fill: a bare Stack child gets loose constraints and
          // shrink-wraps (a Column then pins top-left instead of
          // centering full-width). This was the off-center splash.
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
