import 'dart:math';

import 'detak_assets.dart';
import 'detak_quests.dart';
import 'detak_state.dart';

class DetakEngineResult {
  final DetakMood mood;
  final String messageKey;
  final bool leveledUp;

  const DetakEngineResult({
    required this.mood,
    required this.messageKey,
    this.leveledUp = false,
  });
}

/// Rule-based, event-driven companion brain. No AI, no network:
/// events in, a mood + a message-template key out.
class DetakEngine {
  DetakEngine._();

  static final _rand = Random();

  // Message variant groups. Keys live in lib/core/strings.dart (detak_msg_*).
  static const Map<String, List<String>> _variants = {
    'greet': ['detak_msg_greet_0', 'detak_msg_greet_1'],
    'comeback3': ['detak_msg_comeback3_0', 'detak_msg_comeback3_1'],
    'comeback7': ['detak_msg_comeback7_0', 'detak_msg_comeback7_1'],
    'comeback14': ['detak_msg_comeback14_0', 'detak_msg_comeback14_1'],
    'record': [
      'detak_msg_record_0',
      'detak_msg_record_1',
      'detak_msg_record_2'
    ],
    'trend': ['detak_msg_trend_0', 'detak_msg_trend_1'],
    'streak': ['detak_msg_streak_0', 'detak_msg_streak_1'],
    'levelup': ['detak_msg_levelup_0', 'detak_msg_levelup_1'],
    'goal': ['detak_msg_goal_0', 'detak_msg_goal_1'],
    'missed': ['detak_msg_missed_0', 'detak_msg_missed_1'],
    'tap': ['detak_msg_tap_0', 'detak_msg_tap_1', 'detak_msg_tap_2'],
  };

  /// Picks a variant key, avoiding an immediate repeat of the same group.
  static String pickVariant(DetakState s, String group) {
    final list = _variants[group]!;
    if (list.length == 1) return list.first;
    final last = s.lastVariant[group] ?? -1;
    final idx = (last + 1 + _rand.nextInt(list.length - 1)) % list.length;
    s.lastVariant[group] = idx;
    return list[idx];
  }

  static bool isStreakMilestone(int dailyStreak, bool loggedToday) =>
      loggedToday && dailyStreak >= 7 && dailyStreak % 7 == 0;

  /// Called once per cold start. Updates open/greet tracking and returns
  /// the greeting. Logs a reaction only for the first open of the day
  /// (the "Reaksi terbaru" feed is for notable moments, not every open).
  static DetakEngineResult onAppOpen(DetakState s, DetakFacts f) {
    // Roll today's quest offer once (persisted; the caller saves the state).
    rollDailyQuests(s, f, f.now);
    final today = DetakState.dayKey(f.now);
    final greetedToday = s.lastGreetDay != null &&
        DetakState.dayKey(s.lastGreetDay!) == today;

    final DetakMood mood;
    final String group;
    if (f.daysSinceOpen >= 14) {
      mood = DetakMood.ngantuk;
      group = 'comeback14';
    } else if (f.daysSinceOpen >= 7) {
      mood = DetakMood.ngantuk;
      group = 'comeback7';
    } else if (f.daysSinceOpen >= 3) {
      mood = DetakMood.ngantuk;
      group = 'comeback3';
    } else if (f.missedYesterday) {
      mood = DetakMood.dukung;
      group = 'missed';
    } else if (f.loggedToday) {
      mood = DetakMood.senang;
      group = 'record';
    } else {
      mood = DetakMood.halo;
      group = 'greet';
    }
    final key = pickVariant(s, group);
    s.lastOpenDay = DateTime(f.now.year, f.now.month, f.now.day);
    if (!greetedToday) {
      s.lastGreetDay = s.lastOpenDay;
      s.logReaction(mood, key, f.now);
    }
    return DetakEngineResult(mood: mood, messageKey: key);
  }

  /// Called right after a weight record is saved. Offered 'log'-trigger
  /// quests (log / early / comeback) complete here, once per day each —
  /// repeat saves still react, but don't farm closeness.
  static DetakEngineResult onRecordSaved(
    DetakState s,
    DetakFacts f, {
    required bool goalReached,
  }) {
    final today = DateTime(f.now.year, f.now.month, f.now.day);
    s.lastLogDay = today;
    rollDailyQuests(s, f, f.now);
    final gained = completeQuests(s, f, f.now, 'log');
    final streakHit = isStreakMilestone(f.dailyStreak, true);

    final DetakMood mood;
    final String group;
    final Map<String, String> args;
    if (goalReached) {
      mood = DetakMood.bangga;
      group = 'goal';
      args = const {};
    } else if (gained > 0) {
      mood = DetakMood.semangat;
      group = 'levelup';
      args = {'n': '${s.level}', 'stage': s.stage.name};
    } else if (streakHit) {
      mood = DetakMood.semangat;
      group = 'streak';
      args = {'n': '${f.dailyStreak}'};
    } else {
      mood = DetakMood.senang;
      group = 'record';
      args = const {};
    }
    final key = pickVariant(s, group);
    s.logReaction(mood, key, f.now, args);
    return DetakEngineResult(
        mood: mood, messageKey: key, leveledUp: gained > 0);
  }

  /// Generic quest-trigger completion ('trend', 'goal', 'wrapped').
  /// Only quests in today's persisted offer can complete, and each only
  /// once per day — firing the same trigger twice is a no-op.
  static DetakEngineResult onQuestTrigger(
      DetakState s, DetakFacts f, String trigger) {
    final now = f.now;
    rollDailyQuests(s, f, now);
    final gained = completeQuests(s, f, now, trigger);
    final mood = gained > 0 ? DetakMood.semangat : DetakMood.senang;
    final group =
        gained > 0 ? 'levelup' : (trigger == 'trend' ? 'trend' : 'record');
    final args = gained > 0
        ? {'n': '${s.level}', 'stage': s.stage.name}
        : const <String, String>{};
    final key = pickVariant(s, group);
    s.logReaction(mood, key, now, args);
    return DetakEngineResult(
        mood: mood, messageKey: key, leveledUp: gained > 0);
  }

  /// Playful message when Detak is tapped. Not logged as a reaction.
  static String tapMessage(DetakState s) => pickVariant(s, 'tap');

  /// Consecutive calendar days (ending today or yesterday) with a weigh-in.
  static int dailyStreak(Iterable<DateTime> logTimes, DateTime now) {
    final days = <DateTime>{
      for (final t in logTimes) DateTime(t.year, t.month, t.day)
    };
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Weigh-in consistency over the last 7 days, 0..1. Drives the needle.
  static double energy(Iterable<DateTime> logTimes, DateTime now) {
    final days = <DateTime>{
      for (final t in logTimes) DateTime(t.year, t.month, t.day)
    };
    final today = DateTime(now.year, now.month, now.day);
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if (days.contains(today.subtract(Duration(days: i)))) n++;
    }
    return n / 7;
  }
}
