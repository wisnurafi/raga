import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../state/app_state.dart';
import '../models/bmi_record.dart';
import '../widgets/cards.dart';

/// Layar "Riwayat": grafik tren berat/BMI + daftar catatan terakhir.
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
              'Riwayat',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: rc.onBg,
                letterSpacing: -0.8,
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE8C98F),
                shape: BoxShape.circle,
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
        const SizedBox(height: 16),
        const ProfileChips(),
        const SizedBox(height: 18),
        if (records.isEmpty)
          _emptyCard(context, rc)
        else ...[
          _trendCard(context, rc, records),
          const SizedBox(height: 22),
          const SectionTitle('Catatan terakhir'),
          _listCard(context, rc, records),
        ],
      ],
    );
  }

  Widget _emptyCard(BuildContext context, RagaColors rc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: rc.card,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Icon(Icons.show_chart, size: 44, color: rc.onCardMuted),
          const SizedBox(height: 12),
          Text(
            'Belum ada catatan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: rc.onCard,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hitung BMI lalu simpan ke riwayat,\ntrensmu akan muncul di sini.',
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
    final spanTxt = days < 32 ? '$days hari' : '${(days / 30).round()} bulan';
    final deltaTxt = diff == 0
        ? 'tetap · $spanTxt'
        : '${diff < 0 ? '↓' : '↑'} ${formatId(diff.abs())} kg · $spanTxt';

    final spots = <FlSpot>[];
    for (var i = 0; i < chrono.length; i++) {
      spots.add(FlSpot(i.toDouble(),
          _showWeight ? chrono[i].weightKg : chrono[i].bmi));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: rc.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showWeight ? 'Berat badan (kg)' : 'BMI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _miniSeg(context, 'Berat', _showWeight,
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
              Text(
                formatId(_showWeight ? latest.weightKg : latest.bmi),
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
                  color: const Color(0xFFE6F9EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  deltaTxt,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E9E6A),
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
                            idMonths[chrono[i].createdAt.month - 1],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A86AD),
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
                      color: const Color(0xFF8B7CF0).withValues(alpha: 0.12),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B7CF0) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF8A86AD),
          ),
        ),
      ),
    );
  }

  Widget _listCard(
      BuildContext context, RagaColors rc, List<BmiRecord> records) {
    final shown = records.take(8).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: rc.cardDark.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
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
                        formatDateId(r.createdAt),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${formatId(r.weightKg)} kg',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Text(
                      'BMI ${formatId(r.bmi)} · ${meta.label}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: meta.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != shown.length - 1)
                Divider(
                    height: 1, color: Colors.white.withValues(alpha: 0.12)),
            ],
          );
        }),
      ),
    );
  }
}
