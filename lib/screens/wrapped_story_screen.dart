// Raga Wrapped story viewer: full-screen swipeable slides, redesigned from
// Wisnu's 6-frame mockup (2026-10-16).
//
// Slides: cover → weight → consistency → BMI → Detak → recap. Progress
// segments on top, tap left/right edges to move (except the recap slide,
// which owns its buttons), X to close.
//
// The story is ALWAYS a dark gradient — one fixed look regardless of the
// app theme. Detak appears live via DetakWidget.

import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/wrapped.dart';
import '../detak/detak_assets.dart';
import '../detak/detak_state.dart';
import '../detak/detak_widget.dart';
import '../state/app_state.dart';

typedef _Glow = ({Color color, Alignment at, double radius});

/// Signed weekly delta for display: '−0.5' (U+2212) / '+0.3' / '0.0' / '–'.
String _signedDelta(WrappedData d) {
  final kg = d.deltaKg;
  if (kg == null) return '–';
  if (kg < -0.05) return '−${formatNum(kg.abs())}';
  if (kg > 0.05) return '+${formatNum(kg)}';
  return '0.0';
}

class WrappedStoryScreen extends StatefulWidget {
  final WrappedData data;

  const WrappedStoryScreen({super.key, required this.data});

  @override
  State<WrappedStoryScreen> createState() => _WrappedStoryScreenState();
}

class _WrappedStoryScreenState extends State<WrappedStoryScreen> {
  final _controller = PageController();
  final _shot = ScreenshotController();
  int _page = 0;
  bool _sharing = false;

  static const _slideCount = 6;
  static const _white = Colors.white;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int p) {
    final next = p.clamp(0, _slideCount - 1);
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  // ------------------------------------------------------------ scaffolding

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final locale = AppState.of(context).locale;
    final shortRange = formatWeekRangeShort(d.weekStart, d.weekEnd, locale);
    final fullRange = formatWeekRangeFull(d.weekStart, d.weekEnd, locale);
    final detak = AppState.of(context).detak;
    final energy = AppState.of(context).detakEnergy;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              _cover(d, detak, energy, fullRange),
              _weight(locale, d),
              _consistency(locale, d, detak, energy),
              _bmiSlide(d),
              _detakSlide(detak, energy),
              _summary(d, detak, energy),
            ],
          ),
          // Header: progress segments + title row + close.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _slideCount; i++)
                          Expanded(
                            child: Container(
                              height: 5,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i <= _page
                                    ? _white
                                    : _white.withValues(alpha: 0.28),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'RAGA WRAPPED · $shortRange',
                          style: RagaType.label(_white).copyWith(
                              fontSize: 13, letterSpacing: 1.5),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _white.withValues(alpha: 0.35)),
                            ),
                            child: Icon(Icons.close,
                                size: 18,
                                color: _white.withValues(alpha: 0.85)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // "Tap to continue" hint (all slides but the recap).
          if (_page < _slideCount - 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Text(
                tx(context, 'wrapped_tap_next'),
                textAlign: TextAlign.center,
                style: RagaType.caption(_white.withValues(alpha: 0.6))
                    .copyWith(fontSize: 14),
              ),
            ),
          // Tap zones (disabled on the recap slide — its buttons own taps).
          if (_page < _slideCount - 1)
            Positioned.fill(
              top: 110,
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
          // Share card, off-screen: only the Screenshot's RepaintBoundary
          // sees it. No Opacity wrapper — RenderOpacity skips painting at
          // opacity 0 and capture() would come back blank.
          Positioned(
            left: -10000,
            top: 0,
            child: Screenshot(
              controller: _shot,
              child: _SummaryShareCard(
                data: d,
                shortRange: shortRange,
                color: detak.color,
                stage: detakStageForLevel(detak.level),
                accessory: detak.accessory,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One slide: vertical gradient base + radial glows + content.
  Widget _bg({
    required List<Color> base,
    required List<_Glow> glows,
    required Widget child,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: base,
            ),
          ),
        ),
        for (final g in glows)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: g.at,
                  radius: g.radius,
                  colors: [
                    g.color,
                    g.color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }

  /// Slide content: centered, scrolls if the screen is short.
  Widget _body(Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 140, 32, 84),
      child: Center(
        child: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  /// Small uppercase section caption, e.g. "BERAT BADAN".
  Widget _cap(String s, Color c) => Text(
        s,
        style: RagaType.caption(c)
            .copyWith(letterSpacing: 2, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      );

  /// Live Detak at a fixed square size (DetakWidget is 1:1 AspectRatio).
  Widget _detak(double size, DetakState detak, double energy,
      {DetakStage? stage}) {
    return SizedBox(
      width: size,
      height: size,
      child: DetakWidget(
        mood: DetakMood.senang,
        color: detak.color,
        stage: stage ?? detakStageForLevel(detak.level),
        accessory: detak.accessory,
        energy: energy,
        calmMode: detak.calmMode,
      ),
    );
  }

  // -------------------------------------------------------------- slide 0

  Widget _cover(WrappedData d, DetakState detak,
      double energy, String fullRange) {
    return _bg(
      base: const [Color(0xFF46338B), Color(0xFF1D1440)],
      glows: const [
        (color: Color(0x593ED598), at: Alignment(-0.8, -0.75), radius: 0.9),
        (color: Color(0x4D4A9EFF), at: Alignment(0.85, 0.9), radius: 1.0),
      ],
      child: _body(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _white.withValues(alpha: 0.35)),
            ),
            child: Text(
              tx(context, 'wrapped_week_n',
                  {'n': isoWeekNumber(d.weekStart)}),
              style: RagaType.label(_white).copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _detak(210, detak, energy),
                const Positioned(
                  left: 26,
                  top: 56,
                  child: Text('✦',
                      style: TextStyle(
                          color: Color(0xFFFFD66B), fontSize: 18)),
                ),
                const Positioned(
                  right: 30,
                  top: 84,
                  child: Text('✦',
                      style:
                          TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const Positioned(
                  left: 52,
                  bottom: 44,
                  child: Text('✦',
                      style: TextStyle(
                          color: Color(0xB3FFFFFF), fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            tx(context, 'wrapped_cover_title'),
            style: RagaType.bigTitle(_white).copyWith(fontSize: 32),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            fullRange,
            style: RagaType.caption(_white.withValues(alpha: 0.65))
                .copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      )),
    );
  }

  // -------------------------------------------------------------- slide 1

  Widget _weight(String locale, WrappedData d) {
    final hasDelta = d.deltaKg != null;
    return _bg(
      base: const [Color(0xFF1E4CB4), Color(0xFF0E1E55)],
      glows: const [
        (color: Color(0x594A9EFF), at: Alignment(-0.7, -0.7), radius: 1.0),
      ],
      child: _body(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cap(tx(context, 'wrapped_weight_cap'),
                const Color(0xFF9DBCFF)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _signedDelta(d),
                  style: RagaType.hero(112, _white),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('kg',
                      style: RagaType.title(
                              _white.withValues(alpha: 0.85))
                          .copyWith(fontSize: 28)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasDelta
                  ? tx(context, 'wrapped_weight_week', {
                      'a': formatNum(d.firstKg!, 1),
                      'b': formatNum(d.lastKg!, 1),
                    })
                  : tx(context, 'wrapped_delta_need'),
              style: RagaType.label(_white).copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            if (hasDelta) ...[
              const SizedBox(height: 22),
              _weightChart(locale, d),
              const SizedBox(height: 22),
              // Footnote as an in-flow callout card, like the consistency
              // and BMI slides — not pinned to the screen bottom.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _weightNote(d),
                  style: RagaType.label(_white.withValues(alpha: 0.9))
                      .copyWith(fontSize: 15, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _weightNote(WrappedData d) {
    final kg = d.deltaKg!;
    if (kg < -0.05) {
      return tx(
          context,
          kg.abs() <= 1
              ? 'wrapped_weight_note_safe'
              : 'wrapped_weight_note_fast',
          {'kg': formatNum(kg.abs())});
    }
    if (kg > 0.05) {
      return tx(context, 'wrapped_weight_note_up',
          {'kg': formatNum(kg)});
    }
    return tx(context, 'wrapped_weight_note_flat');
  }

  Widget _weightChart(String locale, WrappedData d) {
    final weights = d.dayWeights;
    final spots = <FlSpot>[
      for (var i = 0; i < 7; i++)
        if (weights[i] != null) FlSpot(i.toDouble(), weights[i]!),
    ];
    final vals = spots.map((s) => s.y).toList();
    var minY = vals.reduce((a, b) => a < b ? a : b);
    var maxY = vals.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 0.05) {
      minY -= 1.0;
      maxY += 1.0;
    } else {
      minY -= 0.6;
      maxY += 0.6;
    }
    final kg = d.deltaKg!;
    final lastColor = kg < -0.05
        ? const Color(0xFF3ED598)
        : kg > 0.05
            ? const Color(0xFFFF6B5E)
            : _white;
    final last = spots.length - 1;
    return Container(
      height: 190,
      // Wide horizontal padding: the Mon/Sun labels are centered on the
      // plot edges, so without this they get clipped by the card.
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.06),
        border:
            Border.all(color: _white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i > 6) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortDays(locale)[i],
                      style: RagaType.caption(
                              _white.withValues(alpha: 0.6))
                          .copyWith(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: _white,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  if (index == last) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: lastColor,
                      strokeWidth: 2.5,
                      strokeColor: _white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 4,
                    color: _white,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- slide 2

  Widget _consistency(String locale, WrappedData d, DetakState detak,
      double energy) {
    final days = shortDays(locale);
    return _bg(
      base: const [Color(0xFF0D4A44), Color(0xFF06231F)],
      glows: const [
        (color: Color(0x663ED598), at: Alignment(0.6, -0.7), radius: 1.0),
      ],
      child: _body(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cap(tx(context, 'wrapped_cons_cap'),
              const Color(0xFF3ED598)),
          const SizedBox(height: 8),
          Text('${d.activeDays}', style: RagaType.hero(110, _white)),
          Text(
            tx(context, 'wrapped_cons_days'),
            style: RagaType.section(_white).copyWith(fontSize: 19),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.dayWeights[i] != null
                        ? const Color(0xFF3ED598)
                        : Colors.transparent,
                    border: d.dayWeights[i] != null
                        ? null
                        : Border.all(
                            color: _white.withValues(alpha: 0.4),
                            width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    days[i][0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: d.dayWeights[i] != null
                          ? const Color(0xFF07332C)
                          : _white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _detak(88, detak, energy),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.08),
                    border: Border.all(
                        color: _white.withValues(alpha: 0.14)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tx(context, 'wrapped_cons_best',
                        {'n': d.bestDayStreak}),
                    style: RagaType.label(_white)
                        .copyWith(fontSize: 14, height: 1.35),
                  ),
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  // -------------------------------------------------------------- slide 3

  Widget _bmiSlide(WrappedData d) {
    final zone = categoryOf(d.avgBmi);
    final zoneEn = zone.label;
    final prevZone =
        d.prevAvgBmi == null ? null : categoryOf(d.prevAvgBmi!);
    final titleKey = prevZone == null
        ? 'wrapped_bmi_zone'
        : prevZone == zone
            ? 'wrapped_bmi_hold'
            : 'wrapped_bmi_enter';
    return _bg(
      base: const [Color(0xFF221543), Color(0xFF120C26)],
      glows: const [
        (color: Color(0x598B7CF6), at: Alignment(-0.6, -0.6), radius: 1.0),
      ],
      child: _body(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cap('BMI', const Color(0xFF3ED598)),
          const SizedBox(height: 14),
          Text(
            tx(context, titleKey, {'z': zoneEn}),
            style: RagaType.title(_white).copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          // Gauge with the number parked in the arc's empty interior,
          // clear of both the arc and the needle dot on the ring.
          SizedBox(
            width: 280,
            height: 172,
            child: Stack(
              children: [
                Positioned.fill(
                  child:
                      CustomPaint(painter: _ZoneGaugePainter(d.avgBmi)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 86,
                  child: Text(
                    formatNum(d.avgBmi),
                    style: RagaType.hero(60, _white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Text('kg/m²',
              style:
                  RagaType.caption(_white.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _zoneColor(zone),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              zoneEn,
              style: RagaType.chip(const Color(0xFF101828)),
            ),
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  tx(context, 'wrapped_bmi_streak_n',
                      {'n': d.zoneStreakWeeks}),
                  style: RagaType.title(_white).copyWith(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  tx(context, 'wrapped_bmi_streak_sub', {'z': zoneEn}),
                  style: RagaType.caption(
                      _white.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Color _zoneColor(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const Color(0xFF6EA8FE),
        BmiCategory.normal => const Color(0xFF3ED598),
        BmiCategory.overweight => const Color(0xFFF5A623),
        BmiCategory.obese => const Color(0xFFFF6B5E),
      };

  // -------------------------------------------------------------- slide 4

  Widget _detakSlide(DetakState detak, double energy) {
    final curStage = detakStageForLevel(detak.level);
    final nextStage = detakStageForLevel(detak.level + 1);
    final hint = nextStage != curStage
        ? tx(context, 'wrapped_detak_hint', {
            'n': detak.xpRemaining,
            'stage': detakStageLabel(context, nextStage).toLowerCase(),
          })
        : tx(context, 'detak_closeness_hint', {
            'n': detak.xpRemaining,
            'm': detak.level + 1,
          });
    return _bg(
      base: const [Color(0xFF3B2A73), Color(0xFF1D1440)],
      glows: const [
        (color: Color(0x4DB9ACF2), at: Alignment(0.5, -0.8), radius: 1.0),
      ],
      child: _body(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cap(tx(context, 'wrapped_detak_cap'),
              const Color(0xFFF5A6C6)),
          const SizedBox(height: 14),
          Text(
            tx(context, 'wrapped_detak_heading'),
            style: RagaType.bigTitle(_white).copyWith(fontSize: 30),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _detak(76, detak, energy, stage: curStage),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward,
                    color: _white.withValues(alpha: 0.7), size: 26),
              ),
              _detak(160, detak, energy, stage: nextStage),
            ],
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx(context, 'wrapped_detak_level',
                          {'a': detak.level, 'b': detak.level + 1}),
                      style: RagaType.label(_white),
                    ),
                    const Spacer(),
                    Text(
                      tx(context, 'wrapped_detak_xp',
                          {'n': detakTotalXp(detak.level, detak.xpInLevel)}),
                      style: RagaType.label(_white)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: detak.progress,
                    minHeight: 10,
                    backgroundColor: _white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  hint,
                  style: RagaType.caption(
                      _white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  // -------------------------------------------------------------- slide 5

  Widget _summary(WrappedData d, DetakState detak,
      double energy) {
    final zoneEn = categoryOf(d.avgBmi).label;
    return _bg(
      base: const [Color(0xFF3B2A73), Color(0xFF1D1440)],
      glows: const [
        (color: Color(0x4DB9ACF2), at: Alignment(0.5, -0.8), radius: 1.0),
      ],
      child: _body(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cap(tx(context, 'wrapped_sum_cap'),
              const Color(0xFFB9A8F5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  tx(context, 'wrapped_sum_heading'),
                  style: RagaType.bigTitle(_white).copyWith(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              _detak(70, detak, energy),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _white.withValues(alpha: 0.06),
              border:
                  Border.all(color: _white.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _sumRow(
                  tx(context, 'wrapped_sum_logs'),
                  Text(
                    tx(context, 'wrapped_sum_days', {'n': d.activeDays}),
                    style: RagaType.label(_white).copyWith(fontSize: 18),
                  ),
                ),
                _sumRow(
                  tx(context, 'wrapped_sum_weight'),
                  Text(
                    d.deltaKg == null ? '–' : '${_signedDelta(d)} kg',
                    style: RagaType.label(_white).copyWith(fontSize: 18),
                  ),
                ),
                _sumRow(
                  tx(context, 'wrapped_sum_bmi'),
                  Text(
                    '${formatNum(d.avgBmi)} · $zoneEn',
                    style: RagaType.label(_white).copyWith(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(tx(context, 'wrapped_sum_target'),
                          style: RagaType.label(
                              _white.withValues(alpha: 0.75))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7CF6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tx(context, 'wrapped_sum_target_pill', {
                            'n': math.min(7, d.activeDays + 1)
                          }),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tx(context, 'wrapped_sum_note'),
            style: RagaType.caption(_white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _white,
                foregroundColor: const Color(0xFF1A1030),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              onPressed: _sharing ? null : _share,
              child: Text(
                tx(context, 'wrapped_share'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1030),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tx(context, 'wrapped_done'),
              style: RagaType.label(_white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      )),
    );
  }

  Widget _sumRow(String label, Widget value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(label,
                  style: RagaType.label(
                      _white.withValues(alpha: 0.75))),
              const Spacer(),
              value,
            ],
          ),
        ),
        Divider(height: 1, color: _white.withValues(alpha: 0.1)),
      ],
    );
  }

  // ----------------------------------------------------------------- share

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    final d = widget.data;
    final locale = AppState.of(context).locale;
    // Captured up front: using BuildContext after an await trips
    // use_build_context_synchronously.
    final shortRange =
        formatWeekRangeShort(d.weekStart, d.weekEnd, locale);
    final shareText = tx(context, 'wrapped_share_text', {
      'range': shortRange,
      'logs': d.activeDays,
      'delta': _signedDelta(d),
      'bmi': formatNum(d.avgBmi),
      'zone': categoryOf(d.avgBmi).label,
    });
    final failText = tx(context, 'wrapped_share_fail');
    setState(() => _sharing = true);
    try {
      final bytes = await _shot.capture();
      if (bytes == null) throw StateError('screenshot failed');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/raga-wrapped-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: shareText);
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(failText)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

/// Half-circle zone gauge for the Wrapped BMI slide: four segments over
/// BMI 15–35 (under 17.5% / normal 32.5% / over 25% / obese 25%) with a
/// white marker dot on the average BMI.
class _ZoneGaugePainter extends CustomPainter {
  final double bmi;
  const _ZoneGaugePainter(this.bmi);

  static const _edges = [0.0, 0.175, 0.5, 0.75, 1.0];
  static const _colors = [
    Color(0xFF6EA8FE),
    Color(0xFF3ED598),
    Color(0xFFF5A623),
    Color(0xFFFF6B5E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    const gap = 0.045; // radians between segments
    final center = Offset(size.width / 2, size.height - stroke / 2);
    final radius = size.width / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < 4; i++) {
      final start = math.pi + _edges[i] * math.pi + gap / 2;
      final sweep = (_edges[i + 1] - _edges[i]) * math.pi - gap;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = _colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    final t = ((bmi - 15) / 20).clamp(0.0, 1.0);
    final a = math.pi + t * math.pi;
    final dot = Offset(
      center.dx + radius * math.cos(a),
      center.dy + radius * math.sin(a),
    );
    canvas.drawCircle(
        dot, 12, Paint()..color = Colors.white.withValues(alpha: 0.3));
    canvas.drawCircle(dot, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ZoneGaugePainter old) => old.bmi != bmi;
}

/// The card that gets shared: dark gradient, Detak, and the week's key
/// numbers. Rendered off-screen; only the Screenshot sees it.
class _SummaryShareCard extends StatelessWidget {
  final WrappedData data;
  final String shortRange;
  final DetakColor color;
  final DetakStage stage;
  final DetakAccessory accessory;

  const _SummaryShareCard({
    required this.data,
    required this.shortRange,
    required this.color,
    required this.stage,
    required this.accessory,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final d = data;
    final zoneEn = categoryOf(d.avgBmi).label;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(label,
                  style: RagaType.label(white.withValues(alpha: 0.7))),
              const Spacer(),
              Text(value,
                  style: RagaType.label(white)
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        );
    return Container(
      width: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B2A73), Color(0xFF1D1440)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tx(context, 'wrapped_title'),
                style: RagaType.title(white)),
            const SizedBox(height: 4),
            Text(shortRange,
                style:
                    RagaType.caption(white.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            SizedBox(
              width: 100,
              height: 100,
              child: DetakWidget(
                mood: DetakMood.senang,
                color: color,
                stage: stage,
                accessory: accessory,
                energy: 0.5,
                calmMode: true,
              ),
            ),
            const SizedBox(height: 16),
            row(tx(context, 'wrapped_sum_logs'),
                tx(context, 'wrapped_sum_days', {'n': d.activeDays})),
            row(tx(context, 'wrapped_sum_weight'),
                d.deltaKg == null ? '–' : '${_signedDelta(d)} kg'),
            row(tx(context, 'wrapped_sum_bmi'),
                '${formatNum(d.avgBmi)} · $zoneEn'),
            const SizedBox(height: 12),
            Text('Raga · $shortRange',
                style:
                    RagaType.caption(white.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}
