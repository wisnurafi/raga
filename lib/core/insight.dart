import 'dart:math';
import 'bmi.dart';

// One smart line for the home screen, computed locally from weigh-in
// history, the goal, and the streak. Pure function: no I/O, no clock
// tricks beyond "now". Priority: goal hit > drifting away > on track >
// streak > not enough data.
String buildInsight({
  required List<({DateTime at, double weightKg})> history, // ascending
  required double currentKg,
  double? goalKg,
  required int streakWeeks,
}) {
  String kg(double v) => formatNum(v, 1);

  if (history.isEmpty) {
    return 'Log your first weigh-in and Raga starts reading your trend.';
  }

  // Goal reached — celebrate, don't analyze.
  if (goalKg != null && (goalKg - currentKg).abs() < 0.5) {
    return 'Goal reached — ${kg(goalKg)} kg! 🎉 Now the real game: keeping it.';
  }

  final now = DateTime.now();
  final recent = history
      .where((h) => now.difference(h.at).inDays <= 30)
      .toList();
  final weeks =
      max(1, now.difference(recent.first.at).inDays ~/ 7);

  if (recent.length >= 2) {
    final delta = recent.last.weightKg - recent.first.weightKg; // <0 = lost
    if (goalKg != null) {
      final need = goalKg - recent.last.weightKg; // <0 = need to lose
      final drifting =
          (need < -0.05 && delta > 0.05) || (need > 0.05 && delta < -0.05);
      final progressing =
          (need < -0.05 && delta < -0.05) || (need > 0.05 && delta > 0.05);
      if (drifting) {
        final dir = delta > 0 ? 'up' : 'down';
        return '${kg(delta.abs())} kg $dir in the last $weeks ${weeks == 1 ? 'week' : 'weeks'} — time to turn it around.';
      }
      if (progressing) {
        final est = estimateGoal(history: history, targetKg: goalKg);
        final eta = est.days == null
            ? 'keep it up'
            : est.days! <= 1
                ? 'almost there'
                : '~${est.days} days to go';
        final dir = delta < 0 ? 'down' : 'up';
        return '${kg(delta.abs())} kg $dir in $weeks ${weeks == 1 ? 'week' : 'weeks'} — $eta to ${kg(goalKg)} kg.';
      }
      return 'Weight is steady — $weeks ${weeks == 1 ? 'week' : 'weeks'} and holding. Nice.';
    }
    // No goal: just report the trend honestly.
    if (delta.abs() < 0.1) {
      return 'Steady $weeks ${weeks == 1 ? 'week' : 'weeks'} in a row. Consistency wins.';
    }
    final dir = delta < 0 ? 'down' : 'up';
    return '${kg(delta.abs())} kg $dir in the last $weeks ${weeks == 1 ? 'week' : 'weeks'}.';
  }

  // Not enough recent weigh-ins to read a trend.
  final need = 3 - recent.length;
  if (streakWeeks >= 2) {
    return '🔥 $streakWeeks-week streak! Log $need more ${need == 1 ? 'weigh-in' : 'weigh-ins'} so I can read your trend.';
  }
  return 'Log $need more ${need == 1 ? 'weigh-in' : 'weigh-ins'} and I\'ll start reading your trend.';
}
