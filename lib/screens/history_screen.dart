import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/theme.dart';
import '../models/bmi_record.dart';
import '../state/app_state.dart';
import '../widgets/chips.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';

const _kgToLb = 2.20462;

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        const RagaHeader(title: 'History'),
        if (records.isEmpty) ...[
          const SizedBox(height: 72),
          Center(
            child: Text(
              'No entries yet — calculate your BMI to start your history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: rc.onBgMuted,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 18),
          _monthStrip(records, metric),
          const SizedBox(height: 18),
          _chartCard(records, metric),
          const SizedBox(height: 22),
          Text(
            'Recent entries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: rc.onBg,
            ),
          ),
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
    final v = metric ? kg : kg * _kgToLb;
    return formatNum(v).replaceAll(RegExp(r'\.0$'), '');
  }

  Widget _monthStrip(List<BmiRecord> records, bool metric) {
    final months = _lastSixMonths();
    final recs = [for (final m in months) _latestInMonth(records, m)];
    var highlight = -1;
    for (var i = recs.length - 1; i >= 0; i--) {
      if (recs[i] != null) {
        highlight = i;
        break;
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < months.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _MonthCard(
              month: shortMonths[months[i].month - 1],
              value: recs[i] == null
                  ? '–'
                  : _stripWeight(recs[i]!.weightKg, metric),
              highlighted: i == highlight,
            ),
          ],
        ],
      ),
    );
  }

  // --- trend chart card ----------------------------------------------------

  Widget _chartCard(List<BmiRecord> records, bool metric) {
    final rc = context.rc;
    final months = _lastSixMonths();
    final recs = [for (final m in months) _latestInMonth(records, m)];

    final spots = <FlSpot>[];
    final plotMonths = <DateTime>[];
    for (var i = 0; i < months.length; i++) {
      final r = recs[i];
      if (r == null) continue;
      final v = _showWeight
          ? (metric ? r.weightKg : r.weightKg * _kgToLb)
          : r.bmi;
      spots.add(FlSpot(spots.length.toDouble(), v));
      plotMonths.add(months[i]);
    }

    final withData = [
      for (var i = 0; i < recs.length; i++)
        if (recs[i] != null) i,
    ];
    final latest = withData.isEmpty ? null : recs[withData.last];
    final bigTxt = latest == null
        ? '–'
        : _showWeight
            ? formatNum(metric ? latest.weightKg : latest.weightKg * _kgToLb)
            : formatNum(latest.bmi);

    String? pillTxt;
    if (withData.length >= 2) {
      final a = recs[withData.first]!;
      final b = recs[withData.last]!;
      if (_showWeight) {
        final dKg = b.weightKg - a.weightKg;
        final d = metric ? dKg : dKg * _kgToLb;
        final unit = metric ? 'kg' : 'lb';
        pillTxt = d == 0
            ? 'steady · 6 months'
            : '${d < 0 ? '↓' : '↑'} ${formatNum(d.abs())} $unit · 6 months';
      } else {
        final d = b.bmi - a.bmi;
        pillTxt = d == 0
            ? 'steady · 6 months'
            : '${d < 0 ? '↓' : '↑'} ${formatNum(d.abs())} · 6 months';
      }
    }

    final Widget chartBody;
    if (spots.isEmpty) {
      chartBody = SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No data in the last 6 months',
            style: TextStyle(fontSize: 14, color: rc.onCardMuted),
          ),
        ),
      );
    } else {
      chartBody = SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: spots.length <= 1 ? 1.0 : (spots.length - 1).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: rc.onCardMuted.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (v, meta) {
                    final i = v.round();
                    if (i < 0 || i >= plotMonths.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        shortMonths[plotMonths[i].month - 1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: rc.onCardMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: rc.onCardAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final last = index == spots.length - 1;
                    return FlDotCirclePainter(
                      radius: last ? 6 : 5,
                      color: Colors.white,
                      strokeWidth: last ? 3 : 0,
                      strokeColor: rc.badgeOk,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      rc.chipActive.withValues(alpha: 0.25),
                      rc.chipActive.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
                      ? (metric ? 'Body weight (kg)' : 'Body weight (lb)')
                      : 'BMI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: rc.onCard,
                  ),
                ),
              ),
              SizedBox(
                width: 168,
                child: Segmented<String>(
                  options: const ['Weight', 'BMI'],
                  value: _showWeight ? 'Weight' : 'BMI',
                  onChanged: (v) => setState(() => _showWeight = v == 'Weight'),
                  labelOf: (v) => v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                bigTxt,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: rc.onCard,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (pillTxt != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: rc.badgeOk,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pillTxt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: rc.onBadgeOk,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          chartBody,
        ],
      ),
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

  BmiCat _bmiCatOf(BmiCategory c) => switch (c) {
        BmiCategory.underweight => BmiCat.under,
        BmiCategory.normal => BmiCat.normal,
        BmiCategory.overweight => BmiCat.over,
        BmiCategory.obese => BmiCat.obese,
      };

  Widget _entryRow(BmiRecord r, BmiRecord? older, bool metric) {
    final rc = context.rc;
    final cat = _bmiCatOf(r.category);
    final catColor = switch (cat) {
      BmiCat.under => rc.catUnder,
      BmiCat.normal => rc.catNormal,
      BmiCat.over => rc.catOver,
      BmiCat.obese => rc.catObese,
    };

    String deltaTxt = '';
    var deltaColor = rc.onCardMuted;
    if (older != null) {
      final dKg = r.weightKg - older.weightKg;
      final d = metric ? dKg : dKg * _kgToLb;
      final unit = metric ? 'kg' : 'lb';
      if (d < 0) {
        deltaTxt = '−${formatNum(d.abs())} $unit';
        deltaColor = rc.badgeOk;
      } else if (d > 0) {
        deltaTxt = '+${formatNum(d)} $unit';
        deltaColor = rc.catObese;
      } else {
        deltaTxt = '±0.0 $unit';
      }
    }

    final weightTxt = metric
        ? '${formatNum(r.weightKg)} kg'
        : '${formatNum(r.weightKg * _kgToLb)} lb';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: catColor, width: 2.5),
            ),
            child: Center(
              child: Text(
                formatNum(r.bmi),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: rc.onCard,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(r.createdAt),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: rc.onCard,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$weightTxt · ${bmiCatLabel(cat)}',
                style: TextStyle(fontSize: 13.5, color: rc.onCardMuted),
              ),
            ],
          ),
          const Spacer(),
          if (deltaTxt.isNotEmpty)
            Text(
              deltaTxt,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: deltaColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

// Frosted month card with an optional highlight ring for the most
// recent month that has data.
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: rc.onCard,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: rc.onCard,
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
