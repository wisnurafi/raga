import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/theme.dart';
import '../models/bmi_record.dart';
import '../state/app_state.dart';
import '../widgets/chart.dart';
import '../widgets/chips.dart';
import '../widgets/gauge.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';


// History: 6-month strip, weight/BMI trend chart, recent entries.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showWeight = true;

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final records = state.recordsOf(state.activeProfileId);
    final metric = state.metricUnits;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        const RagaHeader(title: 'Riwayat'),
        if (records.isEmpty) ...[
          const SizedBox(height: 72),
          Center(
            child: Text(
              'Belum ada catatan.',
              textAlign: TextAlign.center,
              style: RagaType.body(rc.onBgMuted),
            ),
          ),
        ] else ...[
          const SizedBox(height: 18),
          _monthStrip(records, metric),
          const SizedBox(height: 18),
          _chartCard(records, metric),
          const SizedBox(height: 22),
          Text('Catatan terakhir', style: RagaType.section(rc.onBg)),
          const SizedBox(height: 14),
          ..._entryRows(records, metric),
        ],
      ],
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

  Widget _monthStrip(List<BmiRecord> records, bool metric) {
    final months = _lastSixMonths();
    final recs = [for (final m in months) _latestInMonth(records, m)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < months.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _MonthCard(
              month: idShortMonths[months[i].month - 1],
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

  // --- trend chart card ----------------------------------------------------

  double _plotValue(BmiRecord r, bool metric) => _showWeight
      ? (metric ? r.weightKg : r.weightKg * kgToLb)
      : r.bmi;

  Widget _chartCard(List<BmiRecord> records, bool metric) {
    final rc = context.rc;
    // Plot individual records (oldest-first, capped at 30 points) so
    // sparse histories still draw a line instead of "no data".
    // records arrive newest-first: take the 30 newest first, then
    // reverse to oldest-first for plotting.
    final recs = records.take(30).toList().reversed.toList();
    final values = [
      for (final r in recs) _plotValue(r, metric),
    ];

    final latest = recs.isEmpty ? null : recs.last;
    final bigTxt =
        latest == null ? '–' : formatNum(_plotValue(latest, metric));

    Widget? deltaPill;
    if (recs.length >= 2) {
      final a = recs.first;
      final b = recs.last;
      final d = _showWeight
          ? (metric
              ? b.weightKg - a.weightKg
              : (b.weightKg - a.weightKg) * kgToLb)
          : b.bmi - a.bmi;
      final unit = _showWeight ? (metric ? ' kg' : ' lb') : '';
      final span = _spanLabel(a.createdAt, b.createdAt);
      if (d.abs() < 0.0001) {
        deltaPill = _pill('stabil · $span',
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
                      ? (metric ? 'Berat badan (kg)' : 'Berat badan (lb)')
                      : 'BMI',
                  style: RagaType.cardTitle(rc.onCard),
                ),
              ),
              SizedBox(
                width: 168,
                child: RagaSegmented(
                  options: const ['Berat', 'BMI'],
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
          const SizedBox(height: 12),
          HistoryChart(values: values),
        ],
      ),
    );
  }

  // Human span between two record dates: "hari ini", "3 hari",
  // "2 minggu", "6 bulan".
  String _spanLabel(DateTime a, DateTime b) {
    final days = b.difference(a).inDays.abs();
    if (days < 1) return 'hari ini';
    if (days < 14) return '$days hari';
    if (days < 60) return '${(days / 7).round()} minggu';
    return '${(days / 30).round()} bulan';
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

  // --- recent entries -------------------------------------------------------

  List<Widget> _entryRows(List<BmiRecord> records, bool metric) {
    final shown = records.take(8).toList();
    final rows = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      final older = i + 1 < records.length ? records[i + 1] : null;
      rows.add(_entryRow(shown[i], older, metric));
    }
    return rows;
  }

  Widget _entryRow(BmiRecord r, BmiRecord? older, bool metric) {
    final rc = context.rc;

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
                formatDateId(r.createdAt),
                style: RagaType.label(rc.onCard),
              ),
              const SizedBox(height: 3),
              Text(
                '$weightTxt · ${categoryOf(r.bmi).label}',
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
