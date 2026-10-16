// Raga Wrapped: a Spotify-Wrapped-style weekly recap, computed fully
// on-device from the user's own records. One Wrapped per calendar
// week (Monday start); a week's Wrapped unlocks once that week ends.

import '../models/bmi_record.dart';
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
  final double? deltaKg;
  final double? deltaPct;

  /// Weekly weigh-in streak as it stood at the end of the week.
  final int streakWeeks;
  final double avgBmi;

  /// Badge id: konsisten | pejuang | maraton | comeback | penjelajah.
  final String badgeId;

  /// Log count of the week before, for the comparison slide.
  final int prevLogCount;

  const WrappedData({
    required this.weekStart,
    required this.weekEnd,
    required this.logCount,
    required this.activeDays,
    this.deltaKg,
    this.deltaPct,
    required this.streakWeeks,
    required this.avgBmi,
    required this.badgeId,
    required this.prevLogCount,
  });
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

  final prevStart = start.subtract(const Duration(days: 7));
  final prevLogCount = records
      .where((r) =>
          !r.createdAt.isBefore(prevStart) && r.createdAt.isBefore(start))
      .length;

  final first = inWeek.first;
  final last = inWeek.last;
  double? deltaKg;
  double? deltaPct;
  if (inWeek.length >= 2) {
    deltaKg = last.weightKg - first.weightKg;
    deltaPct = deltaKg / first.weightKg * 100;
  }

  final activeDays = inWeek
      .map((r) =>
          DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day))
      .toSet()
      .length;

  final streakWeeks = computeStreak(records
          .where((r) => r.createdAt.isBefore(end))
          .map((r) => r.createdAt)
          .toList())
      .weeks;

  final avgBmi =
      inWeek.map((r) => r.bmi).reduce((a, b) => a + b) / inWeek.length;

  // Badge, first match wins (priority order).
  String badgeId = 'penjelajah';
  DateTime? latestBefore;
  for (final r in records) {
    if (r.createdAt.isBefore(start) &&
        (latestBefore == null || r.createdAt.isAfter(latestBefore))) {
      latestBefore = r.createdAt;
    }
  }
  final longGap = latestBefore != null &&
      start
              .difference(DateTime(
                  latestBefore.year, latestBefore.month, latestBefore.day))
              .inDays >=
          14;
  if (activeDays >= 5) {
    badgeId = 'konsisten';
  } else if (deltaKg != null && deltaKg <= -1) {
    badgeId = 'pejuang';
  } else if (streakWeeks >= 8) {
    badgeId = 'maraton';
  } else if (longGap) {
    badgeId = 'comeback';
  }

  return WrappedData(
    weekStart: start,
    weekEnd: end.subtract(const Duration(days: 1)),
    logCount: inWeek.length,
    activeDays: activeDays,
    deltaKg: deltaKg,
    deltaPct: deltaPct,
    streakWeeks: streakWeeks,
    avgBmi: avgBmi,
    badgeId: badgeId,
    prevLogCount: prevLogCount,
  );
}
