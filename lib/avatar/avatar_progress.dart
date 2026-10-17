import 'dart:math' as math;

import '../core/streak.dart' show mondayOf;
import '../models/bmi_record.dart';
import 'avatar_manifest.dart';
import 'avatar_models.dart';
import 'progression.dart';

// Pure progress engine for Raga Avatar: XP ledger, levels, daily streaks
// and item unlocks. No UI, no storage, no DateTime.now() — the clock is
// injected so every rule is unit-testable.
//
// Called from AppState (which owns storage and the record history); the
// UI only observes the returned result.

/// Injectable clock. Production passes nothing (DateTime.now);
/// tests pass a fixed time.
typedef AvatarClock = DateTime Function();

/// XP event types. The strings double as keys into
/// progression.json's xpAwards.
abstract class XpType {
  static const dailyRecord = 'daily_record';
  static const scheduledWeigh = 'scheduled_weigh';
  static const streakMilestone = 'streak_milestone';
  static const profileSetupComplete = 'profile_setup_complete';
  static const goalSet = 'goal_set';
  static const goalReached = 'goal_reached';
  static const weeklyWrappedViewed = 'weekly_wrapped_viewed';
}

/// A consecutive-day run per spec E: calendar days (local) with at least
/// one record each. One full empty day breaks the run.
class DailyStreak {
  /// Run ending today (or yesterday when today has no record yet).
  final int current;

  /// First day of the current run; null when [current] is 0.
  final DateTime? start;

  /// Best run ever inside the evaluated history.
  final int best;

  const DailyStreak({
    required this.current,
    required this.start,
    required this.best,
  });
}

class AvatarProgressResult {
  final AvatarProfileState nextState;
  final List<XpEvent> newEvents;
  final List<AvatarItem> newlyUnlocked;
  final int oldLevel;
  final int newLevel;

  const AvatarProgressResult({
    required this.nextState,
    required this.newEvents,
    required this.newlyUnlocked,
    required this.oldLevel,
    required this.newLevel,
  });

  bool get leveledUp => newLevel > oldLevel;
}

class AvatarProgressService {
  final AvatarManifest manifest;
  final ProgressionConfig progression;
  final AvatarClock clock;

  AvatarProgressService({
    required this.manifest,
    required this.progression,
    AvatarClock? clock,
  }) : clock = clock ?? DateTime.now;

  /// 'yyyy-MM-dd' in local time. Days are calendar days, never UTC.
  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DailyStreak computeDailyStreak(
      Iterable<DateTime> logTimes, DateTime now) {
    final days = <DateTime>{
      for (final t in logTimes) DateTime(t.year, t.month, t.day),
    };
    final today = DateTime(now.year, now.month, now.day);
    var cursor = today;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var current = 0;
    while (days.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final start =
        current == 0 ? null : cursor.add(const Duration(days: 1));
    var best = 0;
    var run = 0;
    DateTime? prev;
    final sorted = days.toList()..sort();
    for (final d in sorted) {
      if (prev != null && d.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = d;
    }
    return DailyStreak(current: current, start: start, best: best);
  }

  /// Direction-aware goal check (spec D + Wisnu 2026-10-17): the baseline
  /// is the latest weight when the target was set.
  /// turun: w <= target; naik: w >= target; jaga (|base-target| <= 0.5):
  /// |w - target| <= 0.5. Without a baseline, fall back to Detak's
  /// tolerance rule.
  static bool isGoalReached({
    required double weightKg,
    required double goalKg,
    required double? baselineKg,
  }) {
    if (baselineKg == null) {
      return (weightKg - goalKg).abs() <= 0.05;
    }
    if ((baselineKg - goalKg).abs() <= 0.5) {
      return (weightKg - goalKg).abs() <= 0.5;
    }
    if (goalKg < baselineKg) return weightKg <= goalKg;
    return weightKg >= goalKg;
  }

  /// A record was saved. Grants daily_record (+ scheduled_weigh bonus)
  /// only for the day's first record dated today — backdated records
  /// count for history, streak and records_count, never for daily XP.
  /// Streak milestones come from the full history.
  AvatarProgressResult onRecordSaved({
    required String profileId,
    required DateTime recordDate,
    required List<BmiRecord> history,
    required AvatarProfileState state,
    required bool hasWeighSchedule,
    required List<int> scheduleWeekdays,
  }) {
    final now = clock();
    final recordKey = dayKey(recordDate);
    final isToday = recordKey == dayKey(now);
    final events = <XpEvent>[];

    if (isToday && !state.hasEvent(XpType.dailyRecord, recordKey)) {
      events.add(XpEvent(
        profileId: profileId,
        type: XpType.dailyRecord,
        key: recordKey,
        amount: progression.award(XpType.dailyRecord),
        date: now,
      ));
      if (hasWeighSchedule &&
          scheduleWeekdays.contains(recordDate.weekday) &&
          !state.hasEvent(XpType.scheduledWeigh, recordKey)) {
        events.add(XpEvent(
          profileId: profileId,
          type: XpType.scheduledWeigh,
          key: recordKey,
          amount: progression.award(XpType.scheduledWeigh),
          date: now,
        ));
      }
    }

    // Streak milestones come from the full history (backdated records
    // count). Evaluated as of the record's own day, so a migration-style
    // replay credits past runs exactly like the live flow did.
    final asOf = recordDate.isAfter(now) ? now : recordDate;
    final streak =
        computeDailyStreak(history.map((r) => r.createdAt), asOf);
    for (final m in progression.streakMilestones) {
      if (streak.current >= m && streak.start != null) {
        final key = '$m-${dayKey(streak.start!)}';
        if (!state.hasEvent(XpType.streakMilestone, key)) {
          events.add(XpEvent(
            profileId: profileId,
            type: XpType.streakMilestone,
            key: key,
            amount: progression.award(XpType.streakMilestone),
            date: now,
          ));
        }
      }
    }

    return _apply(profileId, state, events,
        bestStreak: math.max(state.bestStreak, streak.best),
        recordsCount: history.length);
  }

  /// A target was set. XP once per distinct target value (no farming by
  /// re-setting the same number); the baseline is refreshed every time
  /// so the direction stays truthful.
  AvatarProgressResult onGoalSet({
    required String profileId,
    required double targetKg,
    required double? baselineKg,
    required AvatarProfileState state,
  }) {
    final key = targetKg.toStringAsFixed(1);
    final events = <XpEvent>[];
    if (!state.hasEvent(XpType.goalSet, key)) {
      events.add(XpEvent(
        profileId: profileId,
        type: XpType.goalSet,
        key: key,
        amount: progression.award(XpType.goalSet),
        date: clock(),
      ));
    }
    final next = baselineKg == null
        ? state.copyWith(clearGoalBaseline: true)
        : state.copyWith(goalBaselineKg: baselineKg);
    return _apply(profileId, next, events);
  }

  /// A target was reached (AppState evaluates [isGoalReached] on the
  /// saved record, then calls this). XP once per target value.
  AvatarProgressResult onGoalReached({
    required String profileId,
    required double targetKg,
    required AvatarProfileState state,
  }) {
    final key = targetKg.toStringAsFixed(1);
    final events = <XpEvent>[];
    if (!state.hasEvent(XpType.goalReached, key)) {
      events.add(XpEvent(
        profileId: profileId,
        type: XpType.goalReached,
        key: key,
        amount: progression.award(XpType.goalReached),
        date: clock(),
      ));
    }
    return _apply(profileId, state, events, goalReached: true);
  }

  /// A profile was created (or finished onboarding). Once per profile.
  AvatarProgressResult onProfileCreated({
    required String profileId,
    required AvatarProfileState state,
  }) {
    final events = <XpEvent>[];
    if (!state.hasEvent(XpType.profileSetupComplete, 'setup')) {
      events.add(XpEvent(
        profileId: profileId,
        type: XpType.profileSetupComplete,
        key: 'setup',
        amount: progression.award(XpType.profileSetupComplete),
        date: clock(),
      ));
    }
    return _apply(profileId, state, events);
  }

  /// The weekly Wrapped story was opened. Once per calendar week
  /// (Monday start, like the Wrapped itself).
  AvatarProgressResult onWrappedViewed({
    required String profileId,
    required AvatarProfileState state,
  }) {
    final key = dayKey(mondayOf(clock()));
    final events = <XpEvent>[];
    if (!state.hasEvent(XpType.weeklyWrappedViewed, key)) {
      events.add(XpEvent(
        profileId: profileId,
        type: XpType.weeklyWrappedViewed,
        key: key,
        amount: progression.award(XpType.weeklyWrappedViewed),
        date: clock(),
      ));
    }
    return _apply(profileId, state, events);
  }

  /// Appends [events] idempotently ((profileId, type, key) is unique),
  /// recomputes the level from the ledger and evaluates unlocks.
  /// Unlocks are permanent: once in unlockedItemIds, always.
  AvatarProgressResult _apply(
    String profileId,
    AvatarProfileState state,
    List<XpEvent> events, {
    int? bestStreak,
    int? recordsCount,
    bool? goalReached,
  }) {
    final have = state.ledger.map((e) => e.uid).toSet();
    final fresh = <XpEvent>[];
    for (final e in events) {
      if (e.profileId != profileId) continue;
      if (have.add(e.uid)) fresh.add(e);
    }
    final oldLevel = progression.levelForXp(state.totalXp);
    var next = state.copyWith(ledger: [...state.ledger, ...fresh]);
    if (bestStreak != null && bestStreak > next.bestStreak) {
      next = next.copyWith(bestStreak: bestStreak);
    }
    if (goalReached == true) {
      next = next.copyWith(goalReached: true);
    }
    final newLevel = progression.levelForXp(next.totalXp);
    final newlyUnlocked = _evaluateUnlocks(next,
        level: newLevel, recordsCount: recordsCount);
    if (newlyUnlocked.isNotEmpty) {
      next = next.copyWith(unlockedItemIds: {
        ...next.unlockedItemIds,
        for (final i in newlyUnlocked) i.id,
      });
    }
    return AvatarProgressResult(
      nextState: next,
      newEvents: fresh,
      newlyUnlocked: newlyUnlocked,
      oldLevel: oldLevel,
      newLevel: newLevel,
    );
  }

  List<AvatarItem> _evaluateUnlocks(
    AvatarProfileState state, {
    required int level,
    int? recordsCount,
  }) {
    final out = <AvatarItem>[];
    for (final item in manifest.items) {
      if (state.unlockedItemIds.contains(item.id)) continue;
      final u = item.unlock;
      if (u == null) continue; // open-from-start items are seeded at init
      final ok = switch (u.type) {
        UnlockType.level => level >= (u.value as int),
        UnlockType.streakDays => state.bestStreak >= (u.value as int),
        UnlockType.recordsCount =>
          recordsCount != null && recordsCount >= (u.value as int),
        UnlockType.goalReached => state.goalReached && (u.value as bool),
        _ => false,
      };
      if (ok) out.add(item);
    }
    return out;
  }
}
