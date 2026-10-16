import 'package:flutter_test/flutter_test.dart';
import 'package:raga/detak/detak_engine.dart';
import 'package:raga/detak/detak_quests.dart';
import 'package:raga/detak/detak_state.dart';

DetakFacts _facts(DateTime now,
        {bool missedYesterday = false, double? goalKg}) =>
    DetakFacts(
      now: now,
      daysSinceOpen: 0,
      loggedToday: false,
      missedYesterday: missedYesterday,
      dailyStreak: 0,
      energy: 0.0,
      goalKg: goalKg,
    );

void main() {
  // Monday 2026-10-19 09:00 local.
  final mon9 = DateTime(2026, 10, 19, 9, 0);
  // Tuesday 2026-10-20 15:00 local.
  final tue15 = DateTime(2026, 10, 20, 15, 0);

  group('daily offer', () {
    test('always starts with log and only offers eligible quests', () {
      final s = DetakState();
      final offer = rollDailyQuests(s, _facts(mon9), mon9);
      expect(offer.first, 'log');
      expect(offer.length, inInclusiveRange(2, 3));
      expect(offer.toSet().length, offer.length); // no duplicates
      for (final id in offer) {
        final def = detakQuestDef(id)!;
        expect(def.eligible(_facts(mon9), mon9), isTrue);
      }
    });

    test('same day + same facts => identical offer (no reshuffle)', () {
      final s = DetakState();
      final a = rollDailyQuests(s, _facts(mon9), mon9);
      // Facts change mid-day (goal set, past 10 AM) — offer must NOT move.
      final b = rollDailyQuests(
          s, _facts(DateTime(2026, 10, 19, 15, 30), goalKg: 65), mon9);
      expect(b, a);
    });

    test('offer survives a restart (toJson/fromJson round-trip)', () {
      final s = DetakState();
      final a = rollDailyQuests(s, _facts(mon9), mon9);
      final s2 = DetakState.fromJson(s.toJson());
      expect(rollDailyQuests(s2, _facts(mon9), mon9), a);
    });

    test('tight eligibility => deterministic small offer', () {
      // Tuesday 15:00, goal already set, nothing missed:
      // only 'trend' is eligible besides 'log'.
      final s = DetakState();
      final offer =
          rollDailyQuests(s, _facts(tue15, goalKg: 65), tue15);
      expect(offer, ['log', 'trend']);
    });

    test('gates: eligibility flags are exact', () {
      final comeback = detakQuestDef('comeback')!;
      expect(comeback.eligible(_facts(mon9, missedYesterday: true), mon9),
          isTrue);
      expect(comeback.eligible(_facts(mon9), mon9), isFalse);
      expect(
          comeback.completeIf!(_facts(mon9, missedYesterday: true), mon9),
          isTrue);

      final wrapped = detakQuestDef('wrapped')!;
      expect(wrapped.eligible(_facts(mon9), mon9), isTrue);
      expect(wrapped.eligible(_facts(tue15), tue15), isFalse);

      final late = DateTime(2026, 10, 19, 11, 0);
      final early = detakQuestDef('early')!;
      expect(early.eligible(_facts(mon9), mon9), isTrue);
      expect(early.eligible(_facts(late), late), isFalse);
      expect(early.completeIf!(_facts(late), late), isFalse);

      final goal = detakQuestDef('goal')!;
      expect(goal.eligible(_facts(mon9), mon9), isTrue);
      expect(goal.eligible(_facts(mon9, goalKg: 65), mon9), isFalse);

      // ...and an ineligible quest can never appear in a roll, whatever
      // the seed draws.
      var s = DetakState();
      expect(rollDailyQuests(s, _facts(tue15), tue15),
          isNot(contains('wrapped')));
      s = DetakState();
      expect(rollDailyQuests(s, _facts(mon9), mon9),
          isNot(contains('comeback')));
      s = DetakState();
      expect(
          rollDailyQuests(s, _facts(late), late), isNot(contains('early')));
    });
  });

  group('completion', () {
    test('same trigger twice in one day grants XP once', () {
      final s = DetakState();
      final f = _facts(mon9);
      rollDailyQuests(s, f, mon9);
      final xpBefore = s.xpInLevel;
      final l1 = completeQuests(s, f, mon9, 'log');
      expect(l1, greaterThanOrEqualTo(0));
      expect(s.xpInLevel, greaterThan(xpBefore));
      final l2 = completeQuests(s, f, mon9, 'log');
      expect(l2, 0);
      // each quest recorded exactly once
      final done = s.questsDone[DetakState.dayKey(mon9)]!;
      expect(done.toSet().length, done.length);
    });

    test('non-offered trigger is a no-op', () {
      final s = DetakState();
      final f = _facts(tue15, goalKg: 65); // offer == ['log', 'trend']
      rollDailyQuests(s, f, tue15);
      expect(completeQuests(s, f, tue15, 'wrapped'), 0);
      expect(completeQuests(s, f, tue15, 'goal'), 0);
      expect(s.questsDone[DetakState.dayKey(tue15)] ?? [], isEmpty);
      expect(s.xpInLevel, 0);
    });

    test('quests reset the next day and can be earned again', () {
      final s = DetakState();
      final fMon = _facts(mon9);
      rollDailyQuests(s, fMon, mon9);
      completeQuests(s, fMon, mon9, 'log');
      final xpAfterMonday = s.xpInLevel;

      final tue9 = DateTime(2026, 10, 20, 9, 0);
      final fTue = _facts(tue9);
      rollDailyQuests(s, fTue, tue9); // new day => new roll
      final gained = completeQuests(s, fTue, tue9, 'log');
      expect(s.xpInLevel, greaterThan(xpAfterMonday));
      expect(gained, greaterThanOrEqualTo(0));
      // Monday's completions live under Monday's key only
      expect(s.isQuestDone(tue9, 'log'), isTrue);
    });

    test('onRecordSaved is idempotent for quest XP', () {
      final s = DetakState();
      final f = _facts(mon9);
      final r1 = DetakEngine.onRecordSaved(s, f, goalReached: false);
      final xp1 = s.xpInLevel;
      final r2 = DetakEngine.onRecordSaved(s, f, goalReached: false);
      expect(r2.leveledUp, isFalse);
      expect(s.xpInLevel, xp1);
      // first call may or may not level up depending on the draw; either way
      // the second call grants nothing new
      expect(r1, isA<DetakEngineResult>());
    });

    test('onQuestTrigger only completes offered quests, once', () {
      final s = DetakState();
      final f = _facts(tue15, goalKg: 65); // offer == ['log', 'trend']
      DetakEngine.onQuestTrigger(s, f, 'trend');
      expect(s.isQuestDone(tue15, 'trend'), isTrue);
      final xp1 = s.xpInLevel;
      DetakEngine.onQuestTrigger(s, f, 'trend');
      expect(s.xpInLevel, xp1);
      // 'goal' was never offered => the trigger can't complete it
      DetakEngine.onQuestTrigger(s, f, 'goal');
      expect(s.isQuestDone(tue15, 'goal'), isFalse);
    });
  });
}
