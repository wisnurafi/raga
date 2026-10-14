import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/glass.dart';
import '../widgets/raga_bg.dart';

// Branded splash from the mockup: the gauge mark in a glass tile,
// the "Raga" wordmark with a lavender glow (dark mode only),
// the Indonesian tagline, then a short loading bar. Runs ~1.7s,
// fades out, then hands off via [onDone].
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _intro;
  late final Animation<double> _introScale;
  late final Animation<double> _progress;
  late final Animation<double> _outro;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _intro = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _introScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    // The loading bar fills over ~1.6s.
    _progress = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.05, 0.92, curve: Curves.easeInOut),
    );
    _outro = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
      ),
    );
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return RagaBg(
      // Material ancestor: without it Flutter renders Text with the
      // "missing Material" fallback style, which draws a yellow underline
      // (this was the mysterious yellow line under the "Raga" wordmark —
      // splash is the only screen without a Scaffold).
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: FadeTransition(
            opacity: _outro,
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _intro,
                  child: ScaleTransition(
                    scale: _introScale,
                    child: GlassCard(
                      radius: 32,
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        // Light mode gets the dark-needle variant so the
                        // needle stays readable on the light glass tile.
                        rc.isDark
                            ? 'assets/images/raga-mark.png'
                            : 'assets/images/raga-mark-light.png',
                        width: 104,
                        height: 104,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _intro,
                  child: Text(
                    'Raga',
                    style: RagaType.hero(64, rc.onBg).copyWith(
                      letterSpacing: -2,
                      // Never underlined: the wordmark must not inherit the
                      // "missing Material" fallback decoration on any frame.
                      decoration: TextDecoration.none,
                      // Lavender glow on dark; the light canvas stays clean.
                      shadows: rc.isDark
                          ? [
                              Shadow(
                                color: rc.chipActive
                                    .withValues(alpha: 0.55),
                                blurRadius: 32,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _intro,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Kenali tubuhmu, jaga kesehatanmu.',
                      textAlign: TextAlign.center,
                      style: RagaType.body(rc.onBgMuted)
                          .copyWith(fontSize: 16),
                    ),
                  ),
                ),
                const Spacer(flex: 6),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => Container(
                    width: 140,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: rc.onBgMuted.withValues(alpha: 0.30),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor:
                            _progress.value.clamp(0.0, 1.0).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: rc.chipActive,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Memuat...',
                  style: RagaType.body(rc.onBgMuted),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
