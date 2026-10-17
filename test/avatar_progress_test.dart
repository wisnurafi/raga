import 'package:flutter_test/flutter_test.dart';
import 'package:raga/avatar/avatar_manifest.dart';
import 'package:raga/avatar/avatar_models.dart';
import 'package:raga/avatar/avatar_progress.dart';
import 'package:raga/avatar/progression.dart';
import 'package:raga/models/bmi_record.dart';

// Evidence I.4 (XP), I.5 (streak), I.6 (unlock): idempotency, every XP
// source, backdated records, streak rules, unlock boundaries and
// permanence. The clock is injected — no DateTime.now() in the logic.

AvatarManifest? _manifest;
ProgressionConfig? _prog;

Future<AvatarProgressService> _service(DateTime now) async {
  _manifest ??= await AvatarManifest.load();
  _prog ??= await ProgressionConfig.load();
  return AvatarProgressService(
      manifest: _manifest!, progression: _prog!, clock: () => now);
}

Future<AvatarProfileState> _fresh(DateTime now) async {
  final s = await _service(now);
  return AvatarProfileState.initial(s.manifest);
}

BmiRecord _rec(String pid, DateTime at, [double w = 70]) => BmiRecord(
      profileId: pid,
      heightCm: 170,
      weightKg: w,
      createdAt: at,
    );

/// History of one record per day for [days] days ending at [end].
List<BmiRecord> _dailyHistory(String pid, DateTime end, int days,
    [double w = 70]) {
  final day = DateTime(end.year, end.month, end.day);
  return [
    for (var i = days - 1; i >= 0; i--)
      _rec(pid, day.subtract(Duration(days: i)), w),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Monday 2026-10-19 09:00 local — kept fixed so weekday math is stable.
  final mon9 = DateTime(2026, 10, 19, 9, 0);

  group('xp idempotency', () {
    test('same record saved twice grants daily xp once', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      final history = [_rec('p', mon9)];
      final r1 = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r1.newEvents.map((e) => e.type), ['daily_record']);
      st = r1.nextState;
      final r2 = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r2.newEvents, isEmpty);
      expect(st.totalXp, 15);
    });

    test('every hook is idempotent on repeat calls', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      AvatarProfileState again(AvatarProgressResult r) => r.nextState;

      st = again(s.onProfileCreated(profileId: 'p', state: st));
      st = again(s.onProfileCreated(profileId: 'p', state: st));
      expect(
          st.ledger.where((e) => e.type == XpType.profileSetupComplete),
          hasLength(1));

      st = again(s.onGoalSet(
          profileId: 'p', targetKg: 65, baselineKg: 70, state: st));
      st = again(s.onGoalSet(
          profileId: 'p', targetKg: 65, baselineKg: 70, state: st));
      expect(st.ledger.where((e) => e.type == XpType.goalSet), hasLength(1));

      st = again(s.onGoalReached(profileId: 'p', targetKg: 65, state: st));
      st = again(s.onGoalReached(profileId: 'p', targetKg: 65, state: st));
      expect(
          st.ledger.where((e) => e.type == XpType.goalReached), hasLength(1));

      st = again(s.onWrappedViewed(profileId: 'p', state: st));
      st = again(s.onWrappedViewed(profileId: 'p', state: st));
      expect(st.ledger.where((e) => e.type == XpType.weeklyWrappedViewed),
          hasLength(1));
    });
  });

  group('xp sources', () {
    test('daily_record +15, second record same day gives nothing',
        () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      var r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: [_rec('p', mon9)],
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.nextState.totalXp, 15);
      r = s.onRecordSaved(
        profileId: 'p',
        recordDate: DateTime(2026, 10, 19, 21, 30),
        history: [_rec('p', mon9), _rec('p', DateTime(2026, 10, 19, 21, 30))],
        state: r.nextState,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.newEvents, isEmpty);
      expect(r.nextState.totalXp, 15);
    });

    test('scheduled_weigh bonus only on scheduled weekdays with a schedule',
        () async {
      // Monday is in the schedule.
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      var r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: [_rec('p', mon9)],
        state: st,
        hasWeighSchedule: true,
        scheduleWeekdays: const [1],
      );
      expect(r.newEvents.map((e) => e.type),
          ['daily_record', 'scheduled_weigh']);
      expect(r.nextState.totalXp, 23);

      // Same call without a schedule: no bonus.
      st = await _fresh(mon9);
      r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: [_rec('p', mon9)],
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [1],
      );
      expect(r.newEvents.map((e) => e.type), ['daily_record']);

      // Scheduled day is Sunday, record is Monday: no bonus.
      st = await _fresh(mon9);
      r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: [_rec('p', mon9)],
        state: st,
        hasWeighSchedule: true,
        scheduleWeekdays: const [7],
      );
      expect(r.newEvents.map((e) => e.type), ['daily_record']);
    });

    test('streak milestones fire at 3 and 7 days, once per streak run',
        () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      // Replay 7 days of history, one record a day, oldest first.
      for (var d = 6; d >= 0; d--) {
        final day = DateTime(2026, 10, 19 - d, 9);
        final history = _dailyHistory('p', day, 7 - d);
        final r = s.onRecordSaved(
          profileId: 'p',
          recordDate: day,
          history: history,
          state: st,
          hasWeighSchedule: false,
          scheduleWeekdays: const [],
        );
        st = r.nextState;
      }
      final milestones =
          st.ledger.where((e) => e.type == XpType.streakMilestone).toList();
      expect(milestones.map((e) => e.key.split('-').first).toSet(),
          {'3', '7'});
      // Each milestone exactly once even though later days re-evaluate.
      expect(milestones, hasLength(2));
      expect(st.bestStreak, 7);
    });

    test('profile_setup_complete +40 once', () async {
      final s = await _service(mon9);
      final st = await _fresh(mon9);
      final r = s.onProfileCreated(profileId: 'p', state: st);
      expect(r.newEvents.single.amount, 40);
      expect(r.nextState.totalXp, 40);
    });

    test('goal_set +25 per distinct target', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      var r = s.onGoalSet(
          profileId: 'p', targetKg: 65, baselineKg: 70, state: st);
      expect(r.newEvents.single.amount, 25);
      expect(r.nextState.goalBaselineKg, 70);
      st = r.nextState;
      // Same target again: no XP, but the baseline refreshes.
      r = s.onGoalSet(
          profileId: 'p', targetKg: 65, baselineKg: 68, state: st);
      expect(r.newEvents, isEmpty);
      expect(r.nextState.goalBaselineKg, 68);
      // A different target pays again.
      r = s.onGoalSet(
          profileId: 'p', targetKg: 63, baselineKg: 68, state: r.nextState);
      expect(r.newEvents.single.amount, 25);
    });

    test('goal_reached direction rules', () {
      // turun: w <= target
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 64.9, goalKg: 65, baselineKg: 70),
          isTrue);
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 65.1, goalKg: 65, baselineKg: 70),
          isFalse);
      // naik: w >= target
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 65.1, goalKg: 65, baselineKg: 60),
          isTrue);
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 64.9, goalKg: 65, baselineKg: 60),
          isFalse);
      // jaga: |w - target| <= 0.5
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 65.4, goalKg: 65, baselineKg: 65.2),
          isTrue);
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 65.6, goalKg: 65, baselineKg: 65.2),
          isFalse);
      // no baseline: Detak-style tolerance
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 65.04, goalKg: 65, baselineKg: null),
          isTrue);
      expect(
          AvatarProgressService.isGoalReached(
              weightKg: 65.5, goalKg: 65, baselineKg: null),
          isFalse);
    });

    test('goal_reached +150 and unlocks the blue shirt', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      final r = s.onGoalReached(profileId: 'p', targetKg: 65, state: st);
      expect(r.newEvents.single.amount, 150);
      expect(r.nextState.goalReached, isTrue);
      expect(r.newlyUnlocked.map((e) => e.id), contains('blue'));
      expect(r.nextState.unlockedItemIds, contains('blue'));
    });

    test('weekly_wrapped_viewed +15 once per week', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      var r = s.onWrappedViewed(profileId: 'p', state: st);
      expect(r.newEvents.single.amount, 15);
      st = r.nextState;
      // Same week again: nothing.
      r = s.onWrappedViewed(profileId: 'p', state: st);
      expect(r.newEvents, isEmpty);
      // Next week: pays again.
      final nextWeek =
          AvatarProgressService(manifest: s.manifest, progression: s.progression,
              clock: () => DateTime(2026, 10, 26, 9));
      r = nextWeek.onWrappedViewed(profileId: 'p', state: st);
      expect(r.newEvents.single.amount, 15);
    });
  });

  group('backdated records', () {
    test('no daily xp, but streak and records_count still count', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      // 10 records, all dated in the past (migration-style replay).
      for (var d = 9; d >= 0; d--) {
        final day = DateTime(2026, 10, 9 + (9 - d), 9);
        final history = _dailyHistory('p', day, 10 - d);
        final r = s.onRecordSaved(
          profileId: 'p',
          recordDate: day,
          history: history,
          state: st,
          hasWeighSchedule: false,
          scheduleWeekdays: const [],
        );
        st = r.nextState;
      }
      expect(
          st.ledger.where((e) => e.type == XpType.dailyRecord), isEmpty,
          reason: 'backdated records earn no daily xp');
      // ...but the 10-record unlock fired and streak milestones 3 & 7 hit.
      expect(st.unlockedItemIds, contains('coral'));
      expect(st.bestStreak, 10);
      expect(
          st.ledger
              .where((e) => e.type == XpType.streakMilestone)
              .map((e) => e.key.split('-').first)
              .toSet(),
          {'3', '7'});
    });
  });

  group('daily streak', () {
    test('consecutive days grow the streak', () {
      final streak = AvatarProgressService.computeDailyStreak(
        _dailyHistory('p', mon9, 5).map((r) => r.createdAt),
        mon9,
      );
      expect(streak.current, 5);
      expect(streak.best, 5);
      expect(AvatarProgressService.dayKey(streak.start!),
          '2026-10-15');
    });

    test('a full empty day breaks the streak', () {
      // Records Oct 15, 16, 18 (17 missing) — current run is just the 18th.
      final times = [
        DateTime(2026, 10, 15, 9),
        DateTime(2026, 10, 16, 9),
        DateTime(2026, 10, 18, 9),
      ];
      final streak = AvatarProgressService.computeDailyStreak(
          times, DateTime(2026, 10, 18, 9));
      expect(streak.current, 1);
      expect(streak.best, 2);
    });

    test('multiple records on one day count once', () {
      final times = [
        DateTime(2026, 10, 18, 8),
        DateTime(2026, 10, 18, 12),
        DateTime(2026, 10, 18, 23, 59),
        DateTime(2026, 10, 19, 0, 1),
      ];
      final streak = AvatarProgressService.computeDailyStreak(
          times, DateTime(2026, 10, 19, 9));
      expect(streak.current, 2);
    });

    test('bestStreak never drops when the streak breaks', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      // 7-day run first.
      var history = _dailyHistory('p', DateTime(2026, 10, 12, 9), 7);
      var r = s.onRecordSaved(
        profileId: 'p',
        recordDate: DateTime(2026, 10, 12, 9),
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      st = r.nextState;
      expect(st.bestStreak, 7);
      // A new lonely record a week later: current run is 1, best stays 7.
      history = [
        ...history,
        _rec('p', DateTime(2026, 10, 19, 9)),
      ];
      r = s.onRecordSaved(
        profileId: 'p',
        recordDate: DateTime(2026, 10, 19, 9),
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.nextState.bestStreak, 7);
    });
  });

  group('unlocks', () {
    Future<AvatarProfileState> _withXp(DateTime now, int xp) async {
      final s = await _service(now);
      final st = await _fresh(now);
      // Synthetic ledger grants to reach a precise total.
      var i = 0;
      var remaining = xp;
      final ledger = <XpEvent>[];
      while (remaining > 0) {
        final amount = remaining >= 40 ? 40 : remaining;
        ledger.add(XpEvent(
            profileId: 'p',
            type: 'synthetic',
            key: 'k${i++}',
            amount: amount,
            date: now));
        remaining -= amount;
      }
      return st.copyWith(ledger: ledger);
    }

    test('level unlock at the boundary and one below', () async {
      final s = await _service(mon9);
      // Amber needs level 8 = 215 xp.
      var st = await _withXp(mon9, 200);
      var r = s.onWrappedViewed(profileId: 'p', state: st); // +15 -> 215
      expect(r.newLevel, 8);
      expect(r.newlyUnlocked.map((e) => e.id), contains('amber'));

      st = await _withXp(mon9, 199);
      r = s.onWrappedViewed(profileId: 'p', state: st); // +15 -> 214
      expect(r.newLevel, 7);
      expect(r.newlyUnlocked.map((e) => e.id), isNot(contains('amber')));
    });

    test('pulse needs level 10', () async {
      final s = await _service(mon9);
      // Level 10 = 308 xp.
      var st = await _withXp(mon9, 293);
      var r = s.onWrappedViewed(profileId: 'p', state: st); // +15 -> 308
      expect(r.newLevel, 10);
      expect(r.newlyUnlocked.map((e) => e.id), contains('pulse'));
    });

    test('streak unlock at 7 days, not at 6', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      var history = _dailyHistory('p', mon9, 6);
      var r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.newlyUnlocked.map((e) => e.id), isNot(contains('curly')));
      history = _dailyHistory('p', mon9, 7);
      r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: history,
        state: r.nextState,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.newlyUnlocked.map((e) => e.id), contains('curly'));
    });

    test('records_count unlock at 10 records, not 9', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      for (var n = 1; n <= 10; n++) {
        final day = DateTime(2026, 10, 19 - (10 - n), 9);
        final r = s.onRecordSaved(
          profileId: 'p',
          recordDate: day,
          history: _dailyHistory('p', day, n),
          state: st,
          hasWeighSchedule: false,
          scheduleWeekdays: const [],
        );
        st = r.nextState;
        if (n < 10) {
          expect(st.unlockedItemIds, isNot(contains('coral')),
              reason: 'record $n');
        }
      }
      expect(st.unlockedItemIds, contains('coral'));
    });

    test('unlocks are permanent after the streak breaks', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      // Earn curly with a 7-day run ending Oct 12.
      var history = _dailyHistory('p', DateTime(2026, 10, 12, 9), 7);
      var r = s.onRecordSaved(
        profileId: 'p',
        recordDate: DateTime(2026, 10, 12, 9),
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      st = r.nextState;
      expect(st.unlockedItemIds, contains('curly'));
      // Streak breaks (gap), new record Oct 19: curly stays open.
      history = [...history, _rec('p', mon9)];
      r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.nextState.unlockedItemIds, contains('curly'));
      expect(r.newlyUnlocked, isEmpty);
    });

    test('null-unlock items are open from the start', () async {
      final st = await _fresh(mon9);
      for (final id in [
        'short',
        'wavy',
        'bun',
        'lavender',
        'mint',
        'glasses',
        'band',
        'leaf'
      ]) {
        expect(st.unlockedItemIds, contains(id), reason: id);
      }
    });

    test('fire needs a 30-day best streak', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      var history = _dailyHistory('p', mon9, 29);
      var r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: history,
        state: st,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.newlyUnlocked.map((e) => e.id), isNot(contains('fire')));
      history = _dailyHistory('p', mon9, 30);
      r = s.onRecordSaved(
        profileId: 'p',
        recordDate: mon9,
        history: history,
        state: r.nextState,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(r.newlyUnlocked.map((e) => e.id), contains('fire'));
    });
  });

  group('service-level profile isolation', () {
    test('events on A never touch B', () async {
      final s = await _service(mon9);
      var a = await _fresh(mon9);
      var b = await _fresh(mon9);
      final ra = s.onRecordSaved(
        profileId: 'a',
        recordDate: mon9,
        history: [_rec('a', mon9)],
        state: a,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      a = ra.nextState;
      expect(a.totalXp, 15);
      expect(b.totalXp, 0);
      expect(b.ledger, isEmpty);
      // Unlock on A doesn't leak to B.
      final rb = s.onGoalReached(profileId: 'a', targetKg: 65, state: a);
      a = rb.nextState;
      expect(a.unlockedItemIds, contains('blue'));
      expect(b.unlockedItemIds, isNot(contains('blue')));
    });
  });

  group('AvatarProfileState serialization', () {
    test('roundtrip', () async {
      final s = await _service(mon9);
      var st = await _fresh(mon9);
      st = s
          .onRecordSaved(
            profileId: 'p',
            recordDate: mon9,
            history: [_rec('p', mon9)],
            state: st,
            hasWeighSchedule: true,
            scheduleWeekdays: const [1],
          )
          .nextState;
      st = s
          .onGoalSet(
              profileId: 'p', targetKg: 65, baselineKg: 70, state: st)
          .nextState;
      final back = AvatarProfileState.fromJson(st.toJson());
      expect(back.totalXp, st.totalXp);
      expect(back.unlockedItemIds, st.unlockedItemIds);
      expect(back.unlockSeenIds, st.unlockSeenIds);
      expect(back.bestStreak, st.bestStreak);
      expect(back.goalReached, st.goalReached);
      expect(back.goalBaselineKg, st.goalBaselineKg);
      expect(back.config, st.config);
      expect(back.ledger.map((e) => e.uid), st.ledger.map((e) => e.uid));
    });

    test('wrong schemaVersion throws', () async {
      _manifest ??= await AvatarManifest.load();
      expect(
          () => AvatarProfileState.fromJson({
                'schemaVersion': 999,
                'config':
                    AvatarProfileState.initial(_manifest!).config.toJson(),
              }),
          throwsFormatException);
    });
  });
}
