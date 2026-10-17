import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/bmi_record.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/gauge.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import 'history_chart_card.dart';


// History: 6-month strip, weight/BMI trend chart with range filter,
// auto insight, and recent entries.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Default = "Semua": preserves the pre-filter behavior (all records).
  int _rangeIdx = 4;
  bool _showAll = false;

  // Range filter labels and matching day counts (null = no limit).
  List<String> _rangeLabels(BuildContext context) => [
        tx(context, 'range_7d'),
        tx(context, 'range_30d'),
        tx(context, 'range_3m'),
        tx(context, 'range_6m'),
        tx(context, 'range_all'),
      ];
  static const List<int?> _rangeDays = [7, 30, 90, 180, null];

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final records = state.recordsOf(state.activeProfileId);
    final metric = state.metricUnits;
    final ranged = _ranged(records);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        RagaHeader(title: tx(context, 'history_title')),
        if (records.isEmpty) ...[
          const SizedBox(height: 72),
          Center(
            child: Text(
              tx(context, 'history_empty'),
              textAlign: TextAlign.center,
              style: RagaType.body(rc.onBgMuted),
            ),
          ),
        ] else ...[
          const SizedBox(height: 18),
          _rangeChips(context),
          const SizedBox(height: 18),
          _monthStrip(context, records, metric),
          const SizedBox(height: 18),
          HistoryChartCard(rangeIdx: _rangeIdx),
          const SizedBox(height: 18),
          _insightCard(context, ranged, state, metric),
          const SizedBox(height: 22),
          Text(tx(context, 'history_recent'),
              style: RagaType.section(rc.onBg)),
          const SizedBox(height: 14),
          ..._entryRows(context, ranged, metric),
          _showAllToggle(context, ranged.length),
        ],
      ],
    );
  }

  // Records inside the selected range filter (newest-first, like input).
  List<BmiRecord> _ranged(List<BmiRecord> records) {
    final days = _rangeDays[_rangeIdx];
    if (days == null) return records;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return records.where((r) => r.createdAt.isAfter(cutoff)).toList();
  }

  Widget _rangeChips(BuildContext context) {
    final labels = _rangeLabels(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            SelectChip(
              label: labels[i],
              selected: i == _rangeIdx,
              onTap: () => setState(() {
                _rangeIdx = i;
                _showAll = false;
              }),
            ),
          ],
        ],
      ),
    );
  }

  // --- 6-month strip ------------------------------------------------------

  List<DateTime> _lastSixMonths() {
    final now = DateTime.now();
    return List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );
  }

  // Newest record inside a calendar month, or null. records are newest-first.
  BmiRecord? _latestInMonth(List<BmiRecord> records, DateTime month) {
    for (final r in records) {
      if (r.createdAt.year == month.year &&
          r.createdAt.month == month.month) {
        return r;
      }
    }
    return null;
  }

  String _stripWeight(double kg, bool metric) {
    final v = metric ? kg : kg * kgToLb;
    return formatNumTrimmed(v);
  }

  Widget _monthStrip(
      BuildContext context, List<BmiRecord> records, bool metric) {
    final locale = AppState.of(context).locale;
    final months = _lastSixMonths();
    final monthNames = locale == 'en' ? enShortMonths : idShortMonths;
    final recs = [for (final m in months) _latestInMonth(records, m)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < months.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _MonthCard(
              month: monthNames[months[i].month - 1],
              value: recs[i] == null
                  ? '-'
                  : _stripWeight(recs[i]!.weightKg, metric),
              highlighted: i == months.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  // --- recent entries -------------------------------------------------------

  // Auto-generated insight for the selected range, in the app locale.
  Widget _insightCard(BuildContext context, List<BmiRecord> records,
      AppState state, bool metric) {
    final rc = context.rc;
    // buildWeightInsight wants oldest-first; records are newest-first.
    final ordered = records.reversed.toList();
    final text = buildWeightInsight(
      [for (final r in ordered) r.weightKg],
      [for (final r in ordered) r.createdAt],
      goalKg: state.goalFor(state.activeProfileId),
      metric: metric,
      locale: state.locale,
    );
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 22, color: rc.chipActive),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx(context, 'history_insight'),
                    style: RagaType.cardTitle(rc.onCard)),
                const SizedBox(height: 6),
                Text(text, style: RagaType.body(rc.onCardMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _entryRows(
      BuildContext context, List<BmiRecord> records, bool metric) {
    // 10 newest by default; the rest behind "Tampilkan semua".
    // No real pagination: a personal tracker holds dozens of rows, not
    // thousands — and every row is a blurred GlassCard, so an unbounded
    // list would jank the scroll on low-end phones.
    final shown = (_showAll ? records : records.take(10)).toList();
    final rows = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      final older = i + 1 < records.length ? records[i + 1] : null;
      rows.add(_entryRow(context, shown[i], older, metric));
    }
    return rows;
  }

  Widget _showAllToggle(BuildContext context, int total) {
    if (total <= 10) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Center(
        child: RagaTextButton(
          label: _showAll
              ? tx(context, 'history_show_less')
              : tx(context, 'history_show_all', {'n': total}),
          onPressed: () => setState(() => _showAll = !_showAll),
        ),
      ),
    );
  }

  Widget _entryRow(
      BuildContext context, BmiRecord r, BmiRecord? older, bool metric) {
    final rc = context.rc;
    final locale = AppState.of(context).locale;

    String deltaTxt = '';
    var deltaColor = rc.onCardMuted;
    if (older != null) {
      final dKg = r.weightKg - older.weightKg;
      final d = metric ? dKg : dKg * kgToLb;
      final unit = metric ? 'kg' : 'lb';
      if (d < 0) {
        deltaTxt = '−${formatNum(d.abs())} $unit';
        deltaColor = rc.success;
      } else if (d > 0) {
        deltaTxt = '+${formatNum(d)} $unit';
        deltaColor = rc.danger;
      } else {
        deltaTxt = '±0.0 $unit';
      }
    }

    final weightTxt = metric
        ? '${formatNum(r.weightKg)} kg'
        : '${formatNum(r.weightKg * kgToLb)} lb';

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          BmiRing(bmi: r.bmi),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDateId(r.createdAt, locale: locale),
                style: RagaType.label(rc.onCard),
              ),
              const SizedBox(height: 3),
              Text(
                '$weightTxt · ${categoryOf(r.bmi).labelFor(locale)}',
                style: RagaType.caption(rc.onCardMuted),
              ),
            ],
          ),
          const Spacer(),
          if (deltaTxt.isNotEmpty)
            Text(
              deltaTxt,
              style: RagaType.label(deltaColor).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

// Frosted month card; the current month carries the highlight border.
class _MonthCard extends StatelessWidget {
  final String month;
  final String value;
  final bool highlighted;

  const _MonthCard({
    required this.month,
    required this.value,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 66,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: rc.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlighted ? rc.chipActive : rc.cardBorder,
              width: highlighted ? 2 : 1.2,
            ),
          ),
          child: Column(
            children: [
              Text(
                month,
                style: RagaType.label(rc.onCardMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: RagaType.chip(rc.onCard).copyWith(
                  fontSize: 17,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
