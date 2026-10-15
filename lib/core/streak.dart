// Weekly weigh-in streak. A week counts when it has at least one
// weigh-in (calendar weeks, Monday start). The streak stays alive
// through the current week: it only breaks when a full past week
// goes by with nothing logged.
class StreakInfo {
  final int weeks;
  final bool thisWeekDone;
  final int? nextMilestone;
  const StreakInfo({
    required this.weeks,
    required this.thisWeekDone,
    required this.nextMilestone,
  });
  int get weeksToMilestone =>
      nextMilestone == null ? 0 : nextMilestone! - weeks;
}

const streakMilestones = [4, 8, 12, 26, 52];

/// The Monday (date-only) of the week containing [d]. Shared with the
/// streak screen so both compute week boundaries the same way.
DateTime mondayOf(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: (date.weekday - 1) % 7));
}

StreakInfo computeStreak(List<DateTime> weighIns) {
  if (weighIns.isEmpty) {
    return const StreakInfo(
        weeks: 0, thisWeekDone: false, nextMilestone: 4);
  }
  final weeksWithData = <DateTime>{};
  for (final w in weighIns) {
    weeksWithData.add(mondayOf(w));
  }
  final thisMonday = mondayOf(DateTime.now());
  final thisWeekDone = weeksWithData.contains(thisMonday);

  // Walk back from this week (or last, if this one is still empty).
  var cursor =
      thisWeekDone ? thisMonday : thisMonday.subtract(const Duration(days: 7));
  var weeks = 0;
  while (weeksWithData.contains(cursor)) {
    weeks++;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  // If this week is empty but last week had data, the streak is alive
  // at `weeks` — it just needs this week's weigh-in to grow.
  int? next;
  for (final m in streakMilestones) {
    if (m > weeks) {
      next = m;
      break;
    }
  }
  return StreakInfo(
      weeks: weeks, thisWeekDone: thisWeekDone, nextMilestone: next);
}
