import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../state/app_state.dart';
import '../models/bmi_record.dart';
import '../widgets/glass.dart';
import '../widgets/cards.dart';
import '../widgets/shine_text.dart';

// The "History" screen: weight/BMI trend chart + recent entries.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showWeight = true;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final p = state.activeProfile;
    final records = state.recordsOf(p.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: rc.onImage,
                letterSpacing: -0.8,
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: state.records.isEmpty
                      ? null
                      : () => _exportCsv(context),
                  borderRadius: BorderRadius.circular(23),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Icon(
                      Icons.ios_share,
                      size: 20,
                      color: rc.onImage,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C98F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      p.initial,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1B2F),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const ProfileChips(),
        const SizedBox(height: 18),
        if (records.isEmpty)
          _emptyCard(context, rc)
        else ...[
          _trendCard(context, rc, records),
          const SizedBox(height: 22),
          const SectionTitle('Recent entries'),
          _listCard(context, rc, records),
        ],
      ],
    );
  }

  // Dumps the full history to a CSV file and opens the share sheet.
  Future<void> _exportCsv(BuildContext context) async {
    final state = AppState.of(context);
    final rows = <List<String>>[
      ['date', 'profile', 'height_cm', 'weight_kg', 'bmi', 'category'],
      for (final r in state.records)
        [
          r.createdAt.toIso8601String(),
          state.profiles
              .where((p) => p.id == r.profileId)
              .map((p) => p.name)
              .join(),
          r.heightCm.toStringAsFixed(1),
          r.weightKg.toStringAsFixed(1),
          r.bmi.toStringAsFixed(1),
          categoryOf(r.bmi).name,
        ],
    ];
    final csv = rows.map((r) => r.map(_csvCell).join(',')).join('\n');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/raga-history.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'Raga history');
  }

  String _csvCell(String v) =>
      v.contains(RegExp(r'[",\n]')) ? '"${v.replaceAll('"', '""')}"' : v;

  Widget _emptyCard(BuildContext context, RagaColors rc) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: rc.mintSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.show_chart, size: 36, color: rc.mint),
          ),
          const SizedBox(height: 14),
          Text(
            'No entries yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: rc.onCard,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calculate your BMI and save it —\nyour trend will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: rc.onCardMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(
      BuildContext context, RagaColors rc, List<BmiRecord> records) {
    final chrono = records.reversed.toList();
    final latest = records.first;
    final first = chrono.first;
    final diff = latest.weightKg - first.weightKg;
    final days = latest.createdAt.difference(first.createdAt).inDays;
    final spanTxt = days < 32 ? '$days days' : '${(days / 30).round()} mo';
    final deltaTxt = diff == 0
        ? 'steady · $spanTxt'
        : '${diff < 0 ? '↓' : '↑'} ${formatNum(diff.abs())} kg · $spanTxt';

    final spots = <FlSpot>[];
    for (var i = 0; i < chrono.length; i++) {
      spots.add(FlSpot(i.toDouble(),
          _showWeight ? chrono[i].weightKg : chrono[i].bmi));
    }

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showWeight ? 'Weight (kg)' : 'BMI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: rc.onCardAccent,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: rc.panel.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _miniSeg(context, 'Weight', _showWeight,
                        () => setState(() => _showWeight = true)),
                    _miniSeg(context, 'BMI', !_showWeight,
                        () => setState(() => _showWeight = false)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShineText(
                formatNum(_showWeight ? latest.weightKg : latest.bmi),
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: rc.onCard,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: rc.mintSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  deltaTxt,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: rc.mint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: Color(0xFFEDE9FA),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final i = v.round();
                        if (i < 0 || i >= chrono.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortMonths[chrono[i].createdAt.month - 1],
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
                    color: const Color(0xFF8B7CF0),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF8B7CF0).withValues(alpha: 0.22),
                          const Color(0xFF8B7CF0).withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniSeg(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [rc.primaryBtn, const Color(0xFF9A8CF5)],
                )
              : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? rc.onPrimaryBtn : rc.onBgMuted,
          ),
        ),
      ),
    );
  }

  Widget _listCard(
      BuildContext context, RagaColors rc, List<BmiRecord> records) {
    final shown = records.take(8).toList();
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      borderRadius: 26,
      child: Column(
        children: List.generate(shown.length, (i) {
          final r = shown[i];
          final meta = categoryMeta[r.category]!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatDate(r.createdAt),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: rc.onBg,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${formatNum(r.weightKg)} kg',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: rc.onBg,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'BMI ${formatNum(r.bmi)} · ${meta.label}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          // Darkened so it stays readable on the soft pill.
                          color:
                              Color.lerp(meta.color, Colors.black, 0.38)!,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i != shown.length - 1)
                Divider(
                    height: 1,
                    color: rc.onBgMuted.withValues(alpha: 0.18)),
            ],
          );
        }),
      ),
    );
  }
}
