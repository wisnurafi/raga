import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Weight/BMI trend line from the history screen: curved lavender line,
/// soft area fill, white dots with lavender rings, solid green last dot.
class HistoryChart extends StatelessWidget {
  final List<double> values;
  final double height;

  const HistoryChart({super.key, required this.values, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final n = values.length;
    if (n == 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Belum ada data grafik.',
            style: RagaType.body(rc.onCardMuted),
          ),
        ),
      );
    }
    final spots = [
      for (var i = 0; i < n; i++) FlSpot(i.toDouble(), values[i]),
    ];
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 0.5) {
      minY -= 1;
      maxY += 1;
    } else {
      final pad = (maxY - minY) * 0.25;
      minY -= pad;
      maxY += pad;
    }
    // A single point still draws its dot: pad the x range so the
    // chart has something to map it to.
    final minX = n == 1 ? -0.5 : 0.0;
    final maxX = n == 1 ? 0.5 : (n - 1).toDouble();
    final line = rc.isDark ? const Color(0xFFB9ACF2) : const Color(0xFF9180DE);
    final last = n - 1;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: rc.onCard.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: line,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  if (index == last) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: rc.catNormal,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 4,
                    color: rc.isDark ? const Color(0xFF2A2470) : Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: line,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    line.withValues(alpha: 0.25),
                    line.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
