// Raga Wrapped story viewer: full-screen swipeable slides, one per
// highlight of the week. Progress segments on top, tap left/right
// edges to move, X to close.

import 'package:flutter/material.dart';
import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/wrapped.dart';
import '../state/app_state.dart';

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
    final rc = context.rc;
    final locale = AppState.of(context).locale;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              rc.chipActive.withValues(alpha: 0.55),
              rc.card,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _cover(rc, locale),
                  _logs(rc, locale),
                  _delta(rc, locale),
                  _streak(rc, locale),
                  _badge(rc, locale),
                  _closing(rc, locale),
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
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: i <= _page
                                ? rc.onCard
                                : rc.onCard.withValues(alpha: 0.3),
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
                  icon: Icon(Icons.close, color: rc.onCard),
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
      ),
    );
  }

  Widget _shell(RagaColors rc, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 90, 32, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _big(RagaColors rc, String s, {double size = 64}) => Text(
        s,
        style: RagaType.title(rc.onCard).copyWith(fontSize: size),
        textAlign: TextAlign.center,
      );

  Widget _sub(RagaColors rc, String s) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(s,
            style: RagaType.label(rc.onCardMuted),
            textAlign: TextAlign.center),
      );

  Widget _cover(RagaColors rc, String locale) {
    final d = widget.data;
    return _shell(rc, [
      Text('✨', style: RagaType.title(rc.onCard).copyWith(fontSize: 56)),
      const SizedBox(height: 18),
      _big(rc, tx(context, 'wrapped_title'), size: 44),
      _sub(rc, tx(context, 'wrapped_cover_sub')),
      const SizedBox(height: 10),
      Text(
        '${formatDateId(d.weekStart, locale: locale)} – ${formatDateId(d.weekEnd, locale: locale)}',
        style: RagaType.caption(rc.onCardMuted),
      ),
    ]);
  }

  Widget _logs(RagaColors rc, String locale) {
    final d = widget.data;
    final diff = d.logCount - d.prevLogCount;
    final vs = diff == 0
        ? ''
        : tx(context, 'wrapped_logs_vs',
            {'d': '${diff > 0 ? '+' : ''}$diff'});
    return _shell(rc, [
      _big(rc, '${d.logCount}'),
      _sub(rc,
          d.logCount == 1
              ? tx(context, 'wrapped_logs_one')
              : tx(context, 'wrapped_logs', {'n': d.logCount})),
      if (vs.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(vs, style: RagaType.caption(rc.chipActive)),
        ),
    ]);
  }

  Widget _delta(RagaColors rc, String locale) {
    final d = widget.data;
    final kg = d.deltaKg;
    if (kg == null) {
      return _shell(rc, [
        _big(rc, '–'),
        _sub(rc, tx(context, 'wrapped_delta_need')),
      ]);
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
    return _shell(rc, [
      Text(flat ? '➖' : kg < 0 ? '📉' : '📈',
          style: RagaType.title(rc.onCard).copyWith(fontSize: 56)),
      const SizedBox(height: 18),
      _big(rc, text, size: 34),
    ]);
  }

  Widget _streak(RagaColors rc, String locale) {
    final d = widget.data;
    return _shell(rc, [
      Text('🔥', style: RagaType.title(rc.onCard).copyWith(fontSize: 56)),
      const SizedBox(height: 18),
      _big(rc, '${d.streakWeeks}'),
      _sub(rc,
          d.streakWeeks == 1
              ? tx(context, 'wrapped_streak_one')
              : tx(context, 'wrapped_streak', {'n': d.streakWeeks})),
    ]);
  }

  Widget _badge(RagaColors rc, String locale) {
    final d = widget.data;
    return _shell(rc, [
      Text(tx(context, 'wrapped_badge_title'),
          style: RagaType.caption(rc.onCardMuted)),
      const SizedBox(height: 14),
      Text('🏅', style: RagaType.title(rc.onCard).copyWith(fontSize: 64)),
      const SizedBox(height: 18),
      _big(rc, tx(context, 'wrapped_badge_${d.badgeId}'), size: 34),
      _sub(rc, tx(context, 'wrapped_badge_${d.badgeId}_d')),
    ]);
  }

  Widget _closing(RagaColors rc, String locale) {
    return _shell(rc, [
      _big(rc, '💪', size: 56),
      const SizedBox(height: 18),
      Text(tx(context, 'wrapped_closing'),
          style: RagaType.title(rc.onCard).copyWith(fontSize: 28),
          textAlign: TextAlign.center),
    ]);
  }
}
