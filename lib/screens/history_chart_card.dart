import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/bmi_record.dart';
import '../state/app_state.dart';
import '../widgets/app_slice.dart';
import '../widgets/chart.dart';
import '../widgets/chips.dart';
import '../widgets/glass.dart';

/// The history screen's trend chart, extracted from `_HistoryScreenState`.
///
/// Heavy (fl_chart layout + paint over up to 60 points), so it subscribes
/// to [AppState] through [AppSlice]: only its own inputs — records in the
/// selected range, the unit toggle, the locale — rebuild it. A Detak tap,
/// a sync tick, or any other unrelated notification no longer repaints
/// the chart.
class HistoryChartCard extends StatelessWidget {
  /// Index into [_rangeDays]; owned by the parent's range chips.
  final int rangeIdx;

  const HistoryChartCard({super.key, required this.rangeIdx});

  static const List<int?> _rangeDays = [7, 30, 90, 180, null];

  @override
  Widget build(BuildContext context) {
    return AppSlice<_ChartInput>(
      select: (s) {
        final days = _rangeDays[rangeIdx];
        final all = s.recordsOf(s.activeProfileId);
        final records = days == null
            ? all
            : all
                .where((r) => r.createdAt.isAfter(
                    DateTime.now().subtract(Duration(days: days))))
                .toList();
        return _ChartInput(
          records: records,
          metric: s.metricUnits,
          locale: s.locale,
        );
      },
      builder: (context, input) => _ChartCardBody(input: input),
    );
  }
}

/// Everything the chart renders, with value equality so [AppSlice] can
/// tell "same data" apart from "new data".
@immutable
class _ChartInput {
  final List<BmiRecord> records; // newest-first, range-filtered
  final bool metric;
  final String locale;

  const _ChartInput({
    required this.records,
    required this.metric,
    required this.locale,
  });

  @override
  bool operator ==(Object other) =>
      other is _ChartInput &&
      metric == other.metric &&
      locale == other.locale &&
      _sameRecords(records, other.records);

  @override
  int get hashCode => Object.hash(metric, locale, records.length);
}

bool _sameRecords(List<BmiRecord> a, List<BmiRecord> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id ||
        a[i].weightKg != b[i].weightKg ||
        a[i].bmi != b[i].bmi ||
        !a[i].createdAt.isAtSameMomentAs(b[i].createdAt)) {
      return false;
    }
  }
  return true;
}

class _ChartCardBody extends StatefulWidget {
  final _ChartInput input;

  const _ChartCardBody({required this.input});

  @override
  State<_ChartCardBody> createState() => _ChartCardBodyState();
}

class _ChartCardBodyState extends State<_ChartCardBody> {
  bool _showWeight = true;

  double _plotValue(BmiRecord r, bool metric) => _showWeight
      ? (metric ? r.weightKg : r.weightKg * kgToLb)
      : r.bmi;

  @override
  Widget build(BuildContext context) {
    final records = widget.input.records;
    final metric = widget.input.metric;
    final locale = widget.input.locale;
    final rc = context.rc;
    // Plot individual records (oldest-first, capped at 60 points) so
    // sparse histories still draw a line instead of "no data".
    // records arrive newest-first: take the 60 newest first, then
    // reverse to oldest-first for plotting.
    final recs = records.take(60).toList().reversed.toList();
    final values = [
      for (final r in recs) _plotValue(r, metric),
    ];

    final latest = recs.isEmpty ? null : recs.last;
    final bigTxt =
        latest == null ? '–' : formatNum(_plotValue(latest, metric));

    Widget? deltaPill;
    // Delta over the whole selected range: records are newest-first,
    // so first = newest and last = oldest.
    if (records.length >= 2) {
      final a = records.last;
      final b = records.first;
      final d = _showWeight
          ? (metric
              ? b.weightKg - a.weightKg
              : (b.weightKg - a.weightKg) * kgToLb)
          : b.bmi - a.bmi;
      final unit = _showWeight ? (metric ? ' kg' : ' lb') : '';
      final span = spanLabel(a.createdAt, b.createdAt, locale: locale);
      if (d.abs() < 0.0001) {
        deltaPill = _pill(tx(context, 'history_stable', {'span': span}),
            rc.onCardMuted.withValues(alpha: 0.16), rc.onCardMuted);
      } else {
        // Solid fill + dark label, like the mockup's pills.
        deltaPill = _pill(
          '${d < 0 ? '↓' : '↑'} ${formatNum(d.abs())}$unit · $span',
          d < 0 ? rc.catNormal : rc.catObese,
          const Color(0xFF1D1B3A),
        );
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _showWeight
                      ? tx(context,
                          metric ? 'history_weight_kg' : 'history_weight_lb')
                      : 'BMI',
                  style: RagaType.cardTitle(rc.onCard),
                ),
              ),
              SizedBox(
                width: 168,
                child: RagaSegmented(
                  options: [tx(context, 'history_weight'), 'BMI'],
                  selected: _showWeight ? 0 : 1,
                  onChanged: (i) => setState(() => _showWeight = i == 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                bigTxt,
                style: RagaType.hero(48, rc.onCard).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (deltaPill != null) ...[
                const SizedBox(width: 12),
                Flexible(child: deltaPill),
              ],
            ],
          ),
          if (recs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statsLine(recs, metric),
              style: RagaType.caption(rc.onCardMuted),
            ),
          ],
          const SizedBox(height: 12),
          HistoryChart(
            values: values,
            // The band only makes sense on the BMI plot.
            showHealthyBand: !_showWeight,
          ),
        ],
      ),
    );
  }

  // "Rata-rata 62,4 kg · Terendah 61,0 · Tertinggi 64,2" for the
  // selected range, following the Berat/BMI toggle.
  String _statsLine(List<BmiRecord> recs, bool metric) {
    final vals = [for (final r in recs) _plotValue(r, metric)];
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final lo = vals.reduce((a, b) => a < b ? a : b);
    final hi = vals.reduce((a, b) => a > b ? a : b);
    final unit = _showWeight ? (metric ? ' kg' : ' lb') : '';
    return tx(context, 'history_stats', {
      'a': formatNum(avg),
      'l': formatNum(lo),
      'h': formatNum(hi),
      'u': unit,
    });
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: RagaType.chip(fg).copyWith(fontSize: 13)),
    );
  }
}
