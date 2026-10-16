import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/strings.dart';
import 'detak_assets.dart';
import 'detak_state.dart';

/// Localized mood chip label ("Senang", "Happy", ...).
String detakMoodLabel(BuildContext context, DetakMood mood) =>
    tx(context, 'detak_mood_${mood.name}');

/// Localized growth-stage label ("Dua daun", "Two leaves", ...).
String detakStageLabel(BuildContext context, DetakStage stage) {
  const keys = {
    DetakStage.kuncup: 'detak_stage_kuncup',
    DetakStage.duaDaun: 'detak_stage_dua',
    DetakStage.rimbun: 'detak_stage_rimbun',
    DetakStage.berbunga: 'detak_stage_berbunga',
  };
  return tx(context, keys[stage]!);
}

/// Resolves a logged reaction to display text, filling {n}/{stage} args.
String detakReactionText(BuildContext context, DetakReaction reaction) {
  final args = <String, Object>{};
  reaction.args.forEach((k, v) {
    args[k] = k == 'stage'
        ? detakStageLabel(context, DetakStage.values.byName(v))
        : v;
  });
  return tx(context, reaction.messageKey, args);
}

/// The living Detak: three composited sprite layers (body, sprout,
/// accessory) with idle life — breathing (3s), blinking (~5s), a leaf
/// wiggle + bounce on tap, crossfading moods, and a dynamic energy
/// needle drawn over the chest gauge.
///
/// With [calmMode] everything is static (accessibility, "Mode tenang").
class DetakWidget extends StatefulWidget {
  final DetakMood mood;
  final DetakColor color;
  final DetakStage stage;
  final DetakAccessory accessory;
  final double energy; // 0..1, drives the chest needle
  final bool calmMode;
  final bool interactive;
  final VoidCallback? onTap;

  const DetakWidget({
    super.key,
    required this.mood,
    required this.color,
    required this.stage,
    this.accessory = DetakAccessory.none,
    this.energy = 0.5,
    this.calmMode = false,
    this.interactive = false,
    this.onTap,
  });

  @override
  State<DetakWidget> createState() => _DetakWidgetState();
}

class _DetakWidgetState extends State<DetakWidget>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _blink;
  late final AnimationController _tap;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (!widget.calmMode) _startIdle();
  }

  void _startIdle() {
    _breath.repeat(reverse: true);
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.calmMode || _blink.isAnimating) return;
      _blink.forward().then((_) {
        if (mounted && !widget.calmMode) _blink.reverse();
      });
    });
  }

  void _stopIdle() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _breath.stop();
    _breath.reset();
    _blink.reset();
  }

  @override
  void didUpdateWidget(DetakWidget old) {
    super.didUpdateWidget(old);
    if (old.calmMode != widget.calmMode) {
      if (widget.calmMode) {
        _stopIdle();
      } else {
        _startIdle();
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _blink.dispose();
    _tap.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.calmMode) _tap.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Image.asset(
        DetakAssets.body(widget.mood, widget.color),
        key: ValueKey('${widget.mood.name}_${widget.color.name}'),
        fit: BoxFit.contain,
      ),
    );
    final sproutImg = Image.asset(
      DetakAssets.sprout(widget.stage),
      fit: BoxFit.contain,
    );
    final accPath = DetakAssets.accessory(widget.accessory);

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: widget.interactive ? _handleTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_breath, _blink, _tap]),
          builder: (_, __) {
            // Idle breath: gentle 3s scale loop.
            final breathe = widget.calmMode
                ? 1.0
                : 1.0 + 0.035 * Curves.easeInOut.transform(_breath.value);
            // Blink: quick vertical squash every ~5s.
            final squash = widget.calmMode
                ? 1.0
                : 1.0 - 0.14 * _blink.value;
            // Tap: bounce + leaf wiggle, decaying.
            final t = _tap.value;
            final bounce =
                widget.calmMode ? 1.0 : 1.0 + 0.10 * math.sin(t * math.pi);
            final wiggle = widget.calmMode
                ? 0.0
                : 0.22 * math.sin(t * math.pi * 3) * (1 - t);
            return Transform.scale(
              scale: breathe * bounce,
              child: Transform.scale(
                scaleY: squash,
                alignment: Alignment.center,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: body),
                    // Leaf wiggle rotates around the stem base.
                    Positioned.fill(
                      child: Transform.rotate(
                        angle: wiggle,
                        alignment:
                            const Alignment(0.02, -0.34), // stem base
                        child: sproutImg,
                      ),
                    ),
                    if (accPath != null)
                      Positioned.fill(
                        child: Image.asset(accPath, fit: BoxFit.contain),
                      ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _NeedlePainter(widget.energy),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Draws the chest-gauge needle. The baked needle is erased from the
/// sprites at build time; this paints it live from [energy]
/// (0 = left/blue, 1 = right/red, 0.5 = straight up).
class _NeedlePainter extends CustomPainter {
  final double energy;
  const _NeedlePainter(this.energy);

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(
      size.width * DetakAssets.needlePivotX,
      size.height * DetakAssets.needlePivotY,
    );
    // ±55° from vertical across the arc.
    final angle = -0.96 + 1.92 * energy.clamp(0.0, 1.0);
    final len = size.width * 0.062;
    final tip = pivot +
        Offset(math.sin(angle) * len, -math.cos(angle) * len);
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.016
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, tip, paint);
    canvas.drawCircle(pivot, size.width * 0.020, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.energy != energy;
}
