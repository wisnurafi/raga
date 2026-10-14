import 'dart:math';

import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../widgets/chips.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';

const _kgToLb = 2.20462;
const _cmToIn = 1 / 2.54;

// Mockup chips with the mockup's factors. 'Active' is the legacy stored
// label for what the mockup calls 'Intense' — mapped on read.
const _activityFactors = <String, double>{
  'Minimal': 1.2,
  'Light': 1.375,
  'Moderate': 1.55,
  'Intense': 1.725,
};

String _activityLabel(String stored) =>
    stored == 'Active' ? 'Intense' : stored;

// Health: activity level, daily calorie needs + BMR donut,
// lose/maintain/gain targets, ideal weight range.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;
    final metric = state.metricUnits;
    final activity = _activityLabel(state.activity);

    final range = idealWeightRange(p.heightCm);
    final bmr = bmrMifflin(
      weightKg: p.weightKg,
      heightCm: p.heightCm,
      age: p.age,
      isMale: p.isMale,
    );
    final tdeeVal = tdee(bmr, _activityFactors[activity] ?? 1.375);
    final pct = (bmr / tdeeVal).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        const RagaHeader(title: 'Health'),
        const SizedBox(height: 16),
        _activityChips(state, activity),
        const SizedBox(height: 16),
        _calorieCard(context, p, metric, tdeeVal, pct),
        const SizedBox(height: 14),
        _goalMinis(context, tdeeVal),
        const SizedBox(height: 14),
        _idealCard(context, p, metric, range),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'BMR ${formatIntNum(bmr.round())} kcal/day · Mifflin-St Jeor formula',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: rc.onCardMuted),
          ),
        ),
      ],
    );
  }

  Widget _activityChips(AppState state, String activity) {
    final labels = _activityFactors.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            SelectChip(
              label: labels[i],
              selected: labels[i] == activity,
              showCheck: true,
              onTap: () => state.setActivity(labels[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _calorieCard(BuildContext context, Profile p, bool metric,
      double tdeeVal, double pct) {
    final rc = context.rc;
    final heightTxt = metric
        ? '${formatNum(p.heightCm, 0)} cm'
        : '${formatNum(p.heightCm * _cmToIn, 0)} in';
    final weightTxt = metric
        ? '${formatNum(p.weightKg)} kg'
        : '${formatNum(p.weightKg * _kgToLb)} lb';
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily calorie needs',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: rc.onCardMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatIntNum(tdeeVal.round()),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: rc.onCard,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: rc.onCardMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.isMale ? 'Male' : 'Female'} · ${p.age} yrs · $heightTxt · $weightTxt',
                  style: TextStyle(fontSize: 13.5, color: rc.onCardMuted),
                ),
              ],
            ),
          ),
          _Donut(pct: pct),
        ],
      ),
    );
  }

  Widget _goalMinis(BuildContext context, double tdeeVal) {
    final rc = context.rc;
    final items = [
      ('Lose', (tdeeVal - 500).round(), rc.catUnder, 0.55),
      ('Maintain', tdeeVal.round(), rc.catNormal, 0.75),
      ('Gain', (tdeeVal + 500).round(), rc.catOver, 0.95),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: rc.onCardMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatIntNum(items[i].$2),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: rc.onCard,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 6,
                    child: LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(
                            width: c.maxWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              color: rc.sliderTrack,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Container(
                            width: c.maxWidth * items[i].$4,
                            height: 6,
                            decoration: BoxDecoration(
                              color: items[i].$3,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _idealCard(BuildContext context, Profile p, bool metric,
      ({double min, double max}) range) {
    final rc = context.rc;
    final lo = metric ? range.min : range.min * _kgToLb;
    final hi = metric ? range.max : range.max * _kgToLb;
    final cur = metric ? p.weightKg : p.weightKg * _kgToLb;
    final unit = metric ? 'kg' : 'lb';
    final scaleLo = metric ? 40.0 : 40 * _kgToLb;
    final scaleHi = metric ? 90.0 : 90 * _kgToLb;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ideal body weight',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: rc.onCardMuted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${formatNum(lo)} – ${formatNum(hi)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: rc.onCard,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: rc.onCardMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 26,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                double posOf(double v) =>
                    ((v - scaleLo) / (scaleHi - scaleLo)).clamp(0.0, 1.0);
                final segL = posOf(lo) * w;
                final segW = (posOf(hi) - posOf(lo)) * w;
                final dotX = (posOf(cur) * w).clamp(11.0, w - 11.0);
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      width: w,
                      height: 6,
                      decoration: BoxDecoration(
                        color: rc.sliderTrack,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Positioned(
                      left: segL,
                      child: Container(
                        width: segW,
                        height: 6,
                        decoration: BoxDecoration(
                          color: rc.catNormal,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: dotX - 11,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: rc.chipActive, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatNum(scaleLo, 0),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'You: ${formatNum(cur)} $unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: rc.onCardAccent,
                ),
              ),
              Text(
                formatNum(scaleHi, 0),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 92px BMR donut: full track ring + chipActive sweep from the top.
class _Donut extends StatelessWidget {
  final double pct;

  const _Donut({required this.pct});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(92, 92),
            painter: _RingPainter(
              track: rc.sliderTrack,
              sweep: rc.chipActive,
              pct: pct,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: rc.onCard,
                ),
              ),
              Text(
                'BMR',
                style: TextStyle(fontSize: 11, color: rc.onCardMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color track;
  final Color sweep;
  final double pct;

  _RingPainter({
    required this.track,
    required this.sweep,
    required this.pct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final sweepPaint = Paint()
      ..color = sweep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pct * 2 * pi,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.pct != pct || old.track != track || old.sweep != sweep;
}
