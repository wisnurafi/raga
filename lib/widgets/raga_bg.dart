import 'package:flutter/material.dart';
import '../core/theme.dart';

// App background: Wisnu's art, drawn full-bleed behind everything.
// Dark mode uses his finished file; light mode uses a light treatment
// generated directly from the same file, so the composition (leaf
// branches, ECG line, concentric rings) is identical in both modes.
// The glass cards blur this, so it doubles as the frost source.
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
            child: Image(
              image: AssetImage(
                rc.isDark
                    ? 'assets/images/raga-bg.png'
                    : 'assets/images/raga-bg-light.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

