import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/glass.dart';
import '../widgets/raga_bg.dart';

// Branded splash from the mockup (p.6): the gauge mark in a glass tile,
// the "Raga" wordmark, tagline, then a short loading bar. Runs ~1.9s,
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
      duration: const Duration(milliseconds: 1900),
    );
    _intro = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );
    _introScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic),
      ),
    );
    // The loading bar fills over ~1.6s.
    _progress = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.06, 0.9, curve: Curves.easeInOut),
    );
    _outro = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.9, 1.0, curve: Curves.easeIn),
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
      child: SafeArea(
        child: FadeTransition(
          opacity: _outro,
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _intro,
                child: ScaleTransition(
                  scale: _introScale,
                  child: GlassCard(
                    radius: 36,
                    padding: const EdgeInsets.all(12),
                    blur: 18,
                    child: Image.asset(
                      'assets/images/raga-mark.png',
                      width: 132,
                      height: 132,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _intro,
                child: Text(
                  'Raga',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: rc.onBg,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _intro,
                child: Text(
                  'Know your body, guard your health.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: rc.onBgMuted,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: rc.onBgMuted.withValues(alpha: 0.30),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _progress.value.clamp(0.0, 1.0),
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
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: rc.onBgMuted,
                ),
              ),
              const SizedBox(height: 76),
            ],
          ),
        ),
      ),
    );
  }
}
