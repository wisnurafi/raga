import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Top-down light sheen clipped to the pill shape, so the "lighting"
/// reads on the button itself. [peakAlpha] is the white alpha at the top
/// edge, fading to transparent by [fadeEnd] (fraction of the height).
class _Sheen extends StatelessWidget {
  final BorderRadius radius;
  final double peakAlpha;
  final double fadeEnd;

  const _Sheen({
    required this.radius,
    this.peakAlpha = 0.35,
    this.fadeEnd = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: peakAlpha),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: [0.0, fadeEnd],
          ),
        ),
      ),
    );
  }
}

/// Primary action: full-width lavender pill, DARK navy label —
/// exactly like the mockup ("Lanjut", "Hitung BMI", ...).
///
/// Depth treatment: a tight pill-hugging shadow (negative spread so it
/// never balloons into a square halo) plus a top-down sheen clipped to
/// the exact pill shape, so the "lighting" reads on the button itself.
class RagaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;

  const RagaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 64,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: rc.btnBottom.withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: rc.btnGradient,
            borderRadius: radius,
          ),
          child: Stack(
            children: [
              // Sheen: light falling on the top half of the pill.
              _Sheen(radius: radius),
              Positioned.fill(
                child: InkWell(
                  borderRadius: radius,
                  onTap: onPressed,
                  child: Center(
                    child: Text(
                      label,
                      style: RagaType.button(rc.onBtn)
                          .copyWith(fontSize: fontSize),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary action: outline pill with theme text ("Bagikan").
class RagaOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;

  const RagaOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: rc.cardShadow.withValues(alpha: 0.6),
            blurRadius: 14,
            spreadRadius: -6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: rc.cardBorder, width: 1.5),
            color: rc.card,
          ),
          child: Stack(
            children: [
              _Sheen(radius: radius, peakAlpha: 0.22, fadeEnd: 0.5),
              Positioned.fill(
                child: InkWell(
                  borderRadius: radius,
                  onTap: onPressed,
                  child: Center(
                    child:
                        Text(label, style: RagaType.button(rc.onCard)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet centered text action ("Lewati dulu").
class RagaTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const RagaTextButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
      child: Text(label, style: RagaType.chip(rc.onBgMuted)),
    );
  }
}

/// Destructive action: danger-tinted outline pill ("Hapus", "Restore").
class DangerPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const DangerPillButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: rc.danger.withValues(alpha: 0.12),
              border: Border.all(color: rc.danger, width: 1.5),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: rc.danger,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
