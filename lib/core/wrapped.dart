// Raga Wrapped: a Spotify-Wrapped-style weekly recap, computed fully
// on-device from the user's own records. One Wrapped per calendar
// week (Monday start); a week's Wrapped unlocks once that week ends.

import '../models/bmi_record.dart';
import 'bmi.dart';
import 'streak.dart';

/// Monday (date-only) of the most recently *completed* week.
DateTime lastCompletedWeekMonday(DateTime now) =>
    mondayOf(now).subtract(const Duration(days: 7));

/// Days until the next Monday, when a new Wrapped unlocks.
int daysUntilNextWrapped(DateTime now) {
  final d = (8 - now.weekday) % 7;
  return d == 0 ? 7 : d;
}

/// Dev-mode preview helper: Monday of the most recent week (starting with
/// the current, still-open week and walking back) that has at least one
/// log. Walks back at most [maxWeeksBack] weeks; returns null when no week
/// in range has logs. The production path (last completed week via
/// [lastCompletedWeekMonday]) is untouched — this exists only so the story
/// UI can be QA'd with real data without waiting for Monday.
DateTime? previewWeekMonday(List<BmiRecord> records, DateTime now,
    {int maxWeeksBack = 12}) {
  if (records.isEmpty) return null;
  var monday = mondayOf(now);
  for (var i = 0; i < maxWeeksBack; i++) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));
    final hasLogs = records.any((r) =>
        !r.createdAt.isBefore(start) && r.createdAt.isBefore(end));
    if (hasLogs) return start;
    monday = monday.subtract(const Duration(days: 7));
  }
  return null;
}

class WrappedData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int logCount;
  final int activeDays;

  /// Last minus first weight inside the week. Negative = lost.
  /// Null when the week has fewer than 2 logs.
  final double? deltaKg;
  final double? deltaPct;

  /// First and last logged weights of the week (chronological).
  /// Null under the same condition as [deltaKg].
  final double? firstKg;
  final double? lastKg;

  /// Last logged weight of each day, Monday-first; null = no log that day.
  final List<double?> dayWeights;

  /// Longest run of consecutive calendar days inside the week with ≥1 log.
  final int bestDayStreak;

  /// Weekly weigh-in streak as it stood at the end of the week.
  final int streakWeeks;

  final double avgBmi;

  /// Average BMI of the previous week; null when it has no logs.
  final double? prevAvgBmi;

  /// Consecutive weeks (walking back from this one) whose average BMI
  /// lands in the same category as this week's.
  final int zoneStreakWeeks;

  const WrappedData({
    required this.weekStart,
    required this.weekEnd,
    required this.logCount,
    required this.activeDays,
    this.deltaKg,
    this.deltaPct,
    this.firstKg,
    this.lastKg,
    required this.dayWeights,
    required this.bestDayStreak,
    required this.streakWeeks,
    required this.avgBmi,
    this.prevAvgBmi,
    required this.zoneStreakWeeks,
  });
}

/// Average BMI of the week starting [weekMonday] (date-only),
/// or null when that week has no logs.
double? _avgBmiOf(List<BmiRecord> records, DateTime weekMonday) {
  final start = DateTime(weekMonday.year, weekMonday.month, weekMonday.day);
  final end = start.add(const Duration(days: 7));
  final inWeek = records.where((r) =>
      !r.createdAt.isBefore(start) && r.createdAt.isBefore(end));
  if (inWeek.isEmpty) return null;
  return inWeek.map((r) => r.bmi).reduce((a, b) => a + b) / inWeek.length;
}

/// Builds the Wrapped for the week starting [weekMonday] (date-only).
/// Returns null when the week has no logs — the UI shows the
/// "quiet week" state instead.
WrappedData? computeWrapped(
    List<BmiRecord> records, DateTime weekMonday) {
  final start = DateTime(weekMonday.year, weekMonday.month, weekMonday.day);
  final end = start.add(const Duration(days: 7));
  final inWeek = records
      .where((r) =>
          !r.createdAt.isBefore(start) && r.createdAt.isBefore(end))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  if (inWeek.isEmpty) return null;

  final first = inWeek.first;
  final last = inWeek.last;
  double? deltaKg;
  double? deltaPct;
  double? firstKg;
  double? lastKg;
  if (inWeek.length >= 2) {
    firstKg = first.weightKg;
    lastKg = last.weightKg;
    deltaKg = lastKg - firstKg;
    deltaPct = deltaKg / firstKg * 100;
  }

  final dayWeights = <double?>[];
  for (var i = 0; i < 7; i++) {
    final day = start.add(Duration(days: i));
    final next = day.add(const Duration(days: 1));
    double? latest;
    for (final r in inWeek) {
      if (!r.createdAt.isBefore(day) && r.createdAt.isBefore(next)) {
        latest = r.weightKg; // inWeek is chronological → last match wins
      }
    }
    dayWeights.add(latest);
  }

  var bestDayStreak = 0;
  var run = 0;
  for (final w in dayWeights) {
    if (w != null) {
      run++;
      if (run > bestDayStreak) bestDayStreak = run;
    } else {
      run = 0;
    }
  }
  final activeDays = dayWeights.where((w) => w != null).length;

  final streakWeeks = computeStreak(records
          .where((r) => r.createdAt.isBefore(end))
          .map((r) => r.createdAt)
          .toList())
      .weeks;

  final avgBmi =
      inWeek.map((r) => r.bmi).reduce((a, b) => a + b) / inWeek.length;

  final prevAvgBmi =
      _avgBmiOf(records, start.subtract(const Duration(days: 7)));

  // Zone streak: walk back week by week while the week's average BMI
  // shares this week's category. Capped at 104 (two years).
  final zone = categoryOf(avgBmi);
  var zoneStreakWeeks = 0;
  var cursor = start;
  for (var i = 0; i < 104; i++) {
    final avg = _avgBmiOf(records, cursor);
    if (avg == null || categoryOf(avg) != zone) break;
    zoneStreakWeeks++;
    cursor = cursor.subtract(const Duration(days: 7));
  }

  return WrappedData(
    weekStart: start,
    weekEnd: end.subtract(const Duration(days: 1)),
    logCount: inWeek.length,
    activeDays: activeDays,
    deltaKg: deltaKg,
    deltaPct: deltaPct,
    firstKg: firstKg,
    lastKg: lastKg,
    dayWeights: dayWeights,
    bestDayStreak: bestDayStreak,
    streakWeeks: streakWeeks,
    avgBmi: avgBmi,
    prevAvgBmi: prevAvgBmi,
    zoneStreakWeeks: zoneStreakWeeks,
  );
}

/// ISO 8601 week number (1–53). E.g. Monday 2026-10-12 → 42.
int isoWeekNumber(DateTime d) {
  // The Thursday of this week determines the ISO week-year.
  final thursday = d.add(Duration(days: 4 - d.weekday));
  final jan4 = DateTime(thursday.year, 1, 4);
  final week1Thursday = jan4.add(Duration(days: 4 - jan4.weekday));
  return thursday.difference(week1Thursday).inDays ~/ 7 + 1;
}

const _idMonthsFull = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _idMonthsShortUp = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MEI',
  'JUN',
  'JUL',
  'AGU',
  'SEP',
  'OKT',
  'NOV',
  'DES',
];

const _enMonthsShortUp = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// '12 – 18 Oktober 2026' / 'Oct 12 – 18, 2026'.
/// Cross-month: '30 November – 6 Desember 2026' / 'Nov 30 – Dec 6, 2026'.
/// Cross-year: '29 Desember 2025 – 4 Januari 2026'
///             / 'Dec 29, 2025 – Jan 4, 2026'.
String formatWeekRangeFull(DateTime start, DateTime end, String locale) {
  final id = locale != 'en';
  // Indonesian uses full month names ("12 – 18 Oktober 2026", per the
  // mockup); English uses the app's short months ("Oct 12 – 18, 2026").
  final m1 = (id ? _idMonthsFull : enShortMonths)[start.month - 1];
  final m2 = (id ? _idMonthsFull : enShortMonths)[end.month - 1];
  if (start.year != end.year) {
    return id
        ? '${start.day} $m1 ${start.year} – ${end.day} $m2 ${end.year}'
        : '$m1 ${start.day}, ${start.year} – $m2 ${end.day}, ${end.year}';
  }
  if (start.month != end.month) {
    return id
        ? '${start.day} $m1 – ${end.day} $m2 ${end.year}'
        : '$m1 ${start.day} – $m2 ${end.day}, ${end.year}';
  }
  return id
      ? '${start.day} – ${end.day} $m1 ${start.year}'
      : '$m1 ${start.day} – ${end.day}, ${start.year}';
}

/// '12–18 OKT' / 'OCT 12–18'.
/// Cross-month: '30 NOV–6 DES' / 'NOV 30–DEC 6'.
String formatWeekRangeShort(DateTime start, DateTime end, String locale) {
  final id = locale != 'en';
  final m1 = (id ? _idMonthsShortUp : _enMonthsShortUp)[start.month - 1];
  final m2 = (id ? _idMonthsShortUp : _enMonthsShortUp)[end.month - 1];
  if (start.month != end.month || start.year != end.year) {
    return id
        ? '${start.day} $m1–${end.day} $m2'
        : '$m1 ${start.day}–$m2 ${end.day}';
  }
  return id ? '${start.day}–${end.day} $m1' : '$m1 ${start.day}–${end.day}';
}
