import 'package:flutter/material.dart';
import '../core/theme.dart';

// The big lavender pill button from the mockup ("Calculate BMI",
// "Continue", "Save goal"...). Diagonal gradient, dark-navy label.
class RagaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;

  const RagaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 62,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [rc.btnTop, rc.btnBottom],
          ),
          boxShadow: [
            BoxShadow(
              color: rc.btnBottom.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: rc.onBtn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Secondary action: glass pill with hairline border ("Share", "Skip").
class RagaGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;

  const RagaGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 62,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: rc.chipInactive,
              border: Border.all(color: rc.cardBorder, width: 1.2),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: rc.onCard,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Plain text link used for "Skip for now" under the primary button.
class RagaTextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const RagaTextLink({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: rc.onBg,
          ),
        ),
      ),
    );
  }
}
