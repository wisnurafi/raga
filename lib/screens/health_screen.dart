import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../widgets/chips.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/ring.dart';


// Display labels -> stored activity keys (English, unchanged
// in storage so old installs keep their value).
List<String> _activityLabels(BuildContext context) => [
      tx(context, 'activity_minimal'),
      tx(context, 'activity_light'),
      tx(context, 'activity_moderate'),
      tx(context, 'activity_active'),
    ];
const _activityKeys = ['Minimal', 'Light', 'Moderate', 'Active'];

// Health: activity level, daily calorie needs + BMR donut,
// lose/maintain/gain targets, ideal weight range.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  // 'Intense' is a legacy stored label from before the redesign; it means
  // the highest activity band.
  String _activityKey(String stored) =>
      stored == 'Intense' ? 'Active' : stored;

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;
    final metric = state.metricUnits;
    final activityKey = _activityKey(state.activity);

    final range = idealWeightRange(p.heightCm);
    final bmr = bmrMifflin(
      weightKg: p.weightKg,
      heightCm: p.heightCm,
      age: p.age,
      isMale: p.isMale,
    );
    final tdeeVal = tdee(bmr, activityFactors[activityKey] ?? 1.375);
    final pct = (bmr / tdeeVal).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        RagaHeader(title: tx(context, 'health_title')),
        const SizedBox(height: 16),
        _activityChips(context, state, activityKey),
        const SizedBox(height: 16),
        _calorieCard(context, p, metric, tdeeVal, pct),
        const SizedBox(height: 14),
        _goalMinis(context, tdeeVal),
        const SizedBox(height: 14),
        _idealCard(context, p, metric, range),
        const SizedBox(height: 16),
        Center(
          child: Text(
            tx(context, 'health_bmr_line',
                {'bmr': formatIntId(bmr.round())}),
            textAlign: TextAlign.center,
            style: RagaType.caption(rc.onCardMuted),
          ),
        ),
      ],
    );
  }

  Widget _activityChips(
      BuildContext context, AppState state, String activityKey) {
    final labels = _activityLabels(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            SelectChip(
              label: labels[i],
              selected: _activityKeys[i] == activityKey,
              onTap: () => state.setActivity(_activityKeys[i]),
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
        : '${formatNum(p.heightCm * cmToIn, 0)} in';
    final weightTxt = metric
        ? '${formatNum(p.weightKg)} kg'
        : '${formatNum(p.weightKg * kgToLb)} lb';
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx(context, 'health_calorie_need'),
                  style: RagaType.cardTitle(rc.onCard),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatIntId(tdeeVal.round()),
                      style: RagaType.hero(52, rc.onCard).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'kcal',
                      style: RagaType.label(rc.onCardMuted)
                          .copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tx(context, 'profile_line', {
                    'gender': tx(
                        context, p.isMale ? 'male' : 'female'),
                    'n': p.age,
                    'h': '$heightTxt · $weightTxt',
                  }),
                  style: RagaType.body(rc.onCardMuted)
                      .copyWith(fontSize: 13.5),
                ),
              ],
            ),
          ),
          DonutRing(
            percent: pct,
            centerTop: '${(pct * 100).round()}%',
            centerBottom: 'BMR',
          ),
        ],
      ),
    );
  }

  Widget _goalMinis(BuildContext context, double tdeeVal) {
    final rc = context.rc;
    final maxV = tdeeVal + 500;
    final items = [
      (tx(context, 'goal_lose'), (tdeeVal - 500).round(), rc.catUnder),
      (tx(context, 'goal_maintain'), tdeeVal.round(), rc.catNormal),
      (tx(context, 'goal_gain'), (tdeeVal + 500).round(), rc.catOver),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _goalMini(
              rc,
              label: items[i].$1,
              value: items[i].$2,
              frac: (items[i].$2 / maxV).clamp(0.0, 1.0),
              bar: items[i].$3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _goalMini(
    RagaColors rc, {
    required String label,
    required int value,
    required double frac,
    required Color bar,
  }) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: RagaType.label(rc.onCardMuted)),
          const SizedBox(height: 4),
          Text(
            formatIntId(value),
            style: RagaType.hero(20, rc.onCard).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
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
                  width: c.maxWidth * frac,
                  height: 6,
                  decoration: BoxDecoration(
                    color: bar,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idealCard(BuildContext context, Profile p, bool metric,
      ({double min, double max}) range) {
    final rc = context.rc;
    final lo = metric ? range.min : range.min * kgToLb;
    final hi = metric ? range.max : range.max * kgToLb;
    final cur = metric ? p.weightKg : p.weightKg * kgToLb;
    final unit = metric ? 'kg' : 'lb';
    final scaleLo = metric ? 40.0 : 40 * kgToLb;
    final scaleHi = metric ? 90.0 : 90 * kgToLb;
    final curTxt = formatNumTrimmed(cur);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx(context, 'health_ideal'),
            style: RagaType.cardTitle(rc.onCard),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${formatNum(lo)} – ${formatNum(hi)}',
                style: RagaType.hero(32, rc.onCard).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: RagaType.label(rc.onCardMuted).copyWith(fontSize: 18),
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
                style: RagaType.label(rc.onCardMuted),
              ),
              Text(
                tx(context, 'health_you', {'v': curTxt, 'u': unit}),
                style: RagaType.label(rc.onCard)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                formatNum(scaleHi, 0),
                style: RagaType.label(rc.onCardMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
