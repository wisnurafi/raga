import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Primary action: full-width lavender pill, DARK navy label —
/// exactly like the mockup ("Lanjut", "Hitung BMI", ...).
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
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: height,
        decoration: BoxDecoration(
          gradient: rc.btnGradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: rc.btnBottom.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: RagaType.button(rc.onBtn).copyWith(fontSize: fontSize),
            ),
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
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: rc.cardBorder, width: 1.5),
          color: rc.card,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onPressed,
          child: Center(
            child: Text(label, style: RagaType.button(rc.onCard)),
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
