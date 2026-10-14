import 'package:flutter/material.dart';

// Text with a subtle vertical shine: luminous at the top, settling into
// the base color at the bottom. For hero numbers and card titles on
// glass — body copy stays flat for readability.
class ShineText extends StatelessWidget {
  final String text;
  final TextStyle style;

  /// The luminous top of the gradient. Defaults to a soft lavender-gray
  /// that reads as "shine" without glaring.
  final Color shine;

  const ShineText(
    this.text, {
    super.key,
    required this.style,
    this.shine = const Color(0xFF8B87C9),
  });

  @override
  Widget build(BuildContext context) {
    final base = style.color ?? const Color(0xFF1B1B2F);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shine, base],
        stops: const [0.0, 0.6],
      ).createShader(bounds),
      // The child must be fully opaque: the shader supplies the color.
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
