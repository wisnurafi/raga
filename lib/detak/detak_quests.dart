import 'dart:math';

import 'detak_state.dart';

/// A daily-quest definition.
///
/// [trigger] is the engine event that can complete it: 'log' (a weight
/// record was saved), 'trend' (the trend was viewed), 'goal' (a weight
/// target was set), 'wrapped' (the weekly Wrapped was opened).
///
/// [eligible] decides whether the quest may be offered on a given day;
/// [completeIf] is an extra gate evaluated at trigger time (so a quest
/// offered in the morning can't complete under different conditions
/// at night).
class DetakQuestDef {
  final String id;
  final String trigger;
  final int xp;
  final String titleKey;
  final String action; // 'tab:0' | 'tab:1' | 'tab:3' | 'tab:4'
  final bool Function(DetakFacts f, DateTime now) eligible;
  final bool Function(DetakFacts f, DateTime now)? completeIf;

  const DetakQuestDef({
    required this.id,
    required this.trigger,
    required this.xp,
    required this.titleKey,
    required this.action,
    required this.eligible,
    this.completeIf,
  });
}

final List<DetakQuestDef> detakQuestPool = [
  DetakQuestDef(
    id: 'log',
    trigger: 'log',
    xp: 1,
    titleKey: 'detak_quest_log',
    action: 'tab:0',
    eligible: (_, __) => true,
  ),
  DetakQuestDef(
    id: 'early',
    trigger: 'log',
    xp: 1,
    titleKey: 'detak_quest_early',
    action: 'tab:0',
    eligible: (_, now) => now.hour < 10,
    completeIf: (_, now) => now.hour < 10,
  ),
  DetakQuestDef(
    id: 'trend',
    trigger: 'trend',
    xp: 1,
    titleKey: 'detak_quest_trend',
    action: 'tab:1',
    eligible: (_, __) => true,
  ),
  DetakQuestDef(
    id: 'comeback',
    trigger: 'log',
    xp: 2,
    titleKey: 'detak_quest_comeback',
    action: 'tab:0',
    eligible: (f, _) => f.missedYesterday,
    completeIf: (f, _) => f.missedYesterday,
  ),
  DetakQuestDef(
    id: 'goal',
    trigger: 'goal',
    xp: 1,
    titleKey: 'detak_quest_goal',
    action: 'tab:3',
    eligible: (f, _) => f.goalKg == null,
  ),
  DetakQuestDef(
    id: 'wrapped',
    trigger: 'wrapped',
    xp: 1,
    titleKey: 'detak_quest_wrapped',
    action: 'tab:4',
    eligible: (_, now) => now.weekday == DateTime.monday,
  ),
];

DetakQuestDef? detakQuestDef(String id) {
  for (final q in detakQuestPool) {
    if (q.id == id) return q;
  }
  return null;
}

/// Stable 32-bit FNV-1a hash. String.hashCode is not guaranteed stable
/// across runs, and the daily seed must be — otherwise a re-roll after
/// an unpersisted roll could draw a different offer.
int _stableSeed(String s) {
  var h = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    h ^= s.codeUnitAt(i);
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Today's quest offer: 'log' (the core habit, always there) plus two
/// seeded picks from the eligible pool.
///
/// Rolled ONCE per day and persisted on the state. The date-seeded shuffle
/// makes the first roll deterministic; persistence makes it immune to
/// mid-day eligibility changes (e.g. setting a goal at noon can't reshuffle
/// the morning's offer). Together they guarantee a completed quest can
/// never reappear and grant XP twice in one day.
List<String> rollDailyQuests(DetakState s, DetakFacts f, DateTime now) {
  final key = DetakState.dayKey(now);
  final stored = s.questOffer[key];
  if (stored != null) return List.unmodifiable(stored);
  final rng = Random(_stableSeed(key));
  final pool =
      detakQuestPool.where((q) => q.id != 'log' && q.eligible(f, now)).toList()
        ..shuffle(rng);
  final picked = ['log', ...pool.take(2).map((q) => q.id)];
  s.questOffer[key] = picked;
  // keep the map small: drop offers older than 8 days
  final cutoff = DetakState.dayKey(now.subtract(const Duration(days: 8)));
  s.questOffer.removeWhere((k, _) => k.compareTo(cutoff) < 0);
  return List.unmodifiable(picked);
}

/// Read-only view of today's persisted offer. Empty when no offer has
/// been rolled yet (call [rollDailyQuests] first).
List<String> offeredQuestIds(DetakState s, DateTime now) =>
    List.unmodifiable(
        s.questOffer[DetakState.dayKey(now)] ?? const <String>[]);

/// Completes every offered quest matching [trigger] whose gate passes.
/// Idempotent: already-completed quests and failed gates grant nothing,
/// so calling this twice for the same event is a no-op.
/// Returns the number of levels gained (0 when nothing new completed).
int completeQuests(DetakState s, DetakFacts f, DateTime now, String trigger) {
  var levels = 0;
  for (final id in offeredQuestIds(s, now)) {
    final def = detakQuestDef(id);
    if (def == null || def.trigger != trigger) continue;
    if (s.isQuestDone(now, id)) continue;
    if (def.completeIf != null && !def.completeIf!(f, now)) continue;
    s.markQuest(now, id);
    levels += s.addXp(def.xp);
  }
  return levels;
}
