// Raga Wrapped story viewer: full-screen swipeable slides, one per
// highlight of the week. Progress segments on top, tap left/right
// edges to move, X to close.
//
// The story is ALWAYS dark (like Spotify Wrapped) regardless of the
// app theme — that's what makes the artwork pop and keeps one neutral
// look in both modes. Artwork: assets/images/wrapped/.

import 'package:flutter/material.dart';
import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/wrapped.dart';
import '../state/app_state.dart';

// Fixed dark canvas for every slide.
const _ink = Color(0xFF0C0C14);

class WrappedStoryScreen extends StatefulWidget {
  final WrappedData data;

  const WrappedStoryScreen({super.key, required this.data});

  @override
  State<WrappedStoryScreen> createState() => _WrappedStoryScreenState();
}

class _WrappedStoryScreenState extends State<WrappedStoryScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slideCount = 6;

  // Per-slide accent for the background glow.
  static const _accents = [
    Color(0xFF8B7CF6), // cover   — lavender
    Color(0xFF4A9EFF), // logs    — blue
    Color(0xFFF5A623), // delta   — amber
    Color(0xFFFF6B4A), // streak  — ember
    Color(0xFFF2C94C), // badge   — gold
    Color(0xFF8B7CF6), // closing — lavender
  ];

  static const _art = [
    'assets/images/wrapped/wrapped_cover.png',
    'assets/images/wrapped/wrapped_logs.png',
    'assets/images/wrapped/wrapped_delta.png',
    'assets/images/wrapped/wrapped_streak.png',
    'assets/images/wrapped/wrapped_badge.png',
    'assets/images/wrapped/wrapped_cover.png',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int p) {
    final next = p.clamp(0, _slideCount - 1);
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppState.of(context).locale;
    final bodies = [
      _cover(locale),
      _logs(locale),
      _delta(locale),
      _streak(locale),
      _badge(locale),
      _closing(locale),
    ];
    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                for (var i = 0; i < _slideCount; i++)
                  _slide(_art[i], bodies[i], _accents[i]),
              ],
            ),
            // Progress segments.
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  for (var i = 0; i < _slideCount; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _page
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Close.
            Positioned(
              top: 20,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close,
                    color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Tap zones.
            Positioned.fill(
              top: 64,
              child: Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _go(_page - 1))),
                  Expanded(
                      child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _go(_page + 1))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One slide: dark base, accent glow behind the artwork, content below.
  Widget _slide(String art, List<Widget> children, Color accent) {
    return Stack(
      children: [
        // Base.
        Container(color: _ink),
        // Accent glow, top third.
        Positioned(
          top: -120,
          left: -60,
          right: -60,
          height: 420,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 0.9,
                colors: [
                  accent.withValues(alpha: 0.38),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Faint floor glow so the bottom never feels empty.
        Positioned(
          bottom: -160,
          left: -80,
          right: -80,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [
                  accent.withValues(alpha: 0.16),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Content.
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(art, width: 148, height: 148),
              const SizedBox(height: 30),
              ...children,
            ],
          ),
        ),
      ],
    );
  }

  Widget _big(String s, {double size = 68}) => Text(
        s,
        style: RagaType.title(Colors.white)
            .copyWith(fontSize: size, height: 1.05),
        textAlign: TextAlign.center,
      );

  Widget _sub(String s, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(s,
            style: RagaType.label(
                    color ?? Colors.white.withValues(alpha: 0.72))
                .copyWith(fontSize: 16, height: 1.4),
            textAlign: TextAlign.center),
      );

  List<Widget> _cover(String locale) {
    final d = widget.data;
    return [
      _big(tx(context, 'wrapped_title'), size: 42),
      _sub(tx(context, 'wrapped_cover_sub')),
      const SizedBox(height: 10),
      Text(
        '${formatDateId(d.weekStart, locale: locale)} – ${formatDateId(d.weekEnd, locale: locale)}',
        style: RagaType.caption(
            Colors.white.withValues(alpha: 0.5)),
      ),
    ];
  }

  List<Widget> _logs(String locale) {
    final d = widget.data;
    final diff = d.logCount - d.prevLogCount;
    return [
      _big('${d.logCount}'),
      _sub(d.logCount == 1
          ? tx(context, 'wrapped_logs_one')
          : tx(context, 'wrapped_logs', {'n': d.logCount})),
      if (diff != 0)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            tx(context, 'wrapped_logs_vs',
                {'d': '${diff > 0 ? '+' : ''}$diff'}),
            style: RagaType.label(_accents[1])
                .copyWith(fontSize: 15),
          ),
        ),
    ];
  }

  List<Widget> _delta(String locale) {
    final d = widget.data;
    final kg = d.deltaKg;
    if (kg == null) {
      return [
        _big('–', size: 56),
        _sub(tx(context, 'wrapped_delta_need')),
      ];
    }
    final flat = kg.abs() < 0.05;
    final text = flat
        ? tx(context, 'wrapped_delta_flat')
        : kg < 0
            ? tx(context, 'wrapped_delta_down', {
                'kg': kg.abs().toStringAsFixed(1),
                'pct': d.deltaPct!.abs().toStringAsFixed(1),
              })
            : tx(context, 'wrapped_delta_up', {
                'kg': kg.toStringAsFixed(1),
                'pct': d.deltaPct!.toStringAsFixed(1),
              });
    return [
      _big(text, size: 36),
    ];
  }

  List<Widget> _streak(String locale) {
    final d = widget.data;
    return [
      _big('${d.streakWeeks}'),
      _sub(d.streakWeeks == 1
          ? tx(context, 'wrapped_streak_one')
          : tx(context, 'wrapped_streak', {'n': d.streakWeeks})),
    ];
  }

  List<Widget> _badge(String locale) {
    final d = widget.data;
    return [
      Text(tx(context, 'wrapped_badge_title'),
          style: RagaType.caption(
              Colors.white.withValues(alpha: 0.55))),
      const SizedBox(height: 12),
      _big(tx(context, 'wrapped_badge_${d.badgeId}'), size: 36),
      _sub(tx(context, 'wrapped_badge_${d.badgeId}_d')),
    ];
  }

  List<Widget> _closing(String locale) {
    return [
      _big(tx(context, 'wrapped_closing'), size: 30),
    ];
  }
}
