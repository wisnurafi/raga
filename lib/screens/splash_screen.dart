import 'package:flutter/material.dart';

// Animated splash: the figure mark pops in, the wordmark and tagline
// follow, then the whole thing fades out into the app. The native
// launch_background shows this exact first frame, so the handoff from
// the OS splash to this animation is seamless.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _markScale;
  late final Animation<double> _markFade;
  late final Animation<double> _wordFade;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagRise;
  late final Animation<double> _outro;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _markFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _markScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _wordFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.25, 0.5, curve: Curves.easeOut),
    );
    _tagFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.42, 0.62, curve: Curves.easeOut),
    );
    _tagRise = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.42, 0.62, curve: Curves.easeOutCubic),
      ),
    );
    _outro = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.82, 1.0, curve: Curves.easeIn),
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
    return FadeTransition(
      opacity: _outro,
      child: Container(
        color: const Color(0xFF301663),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _markFade,
                child: ScaleTransition(
                  scale: _markScale,
                  child: Image.asset(
                    'assets/mark/raga-mark.png',
                    width: 148,
                    height: 148,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _wordFade,
                child: const Text(
                  'Raga',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _tagFade,
                child: SlideTransition(
                  position: _tagRise,
                  child: Text(
                    'Know your body.',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: Colors.white.withValues(alpha: 0.72),
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
