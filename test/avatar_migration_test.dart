import 'package:flutter_test/flutter_test.dart';
import 'package:raga/avatar/avatar_manifest.dart';
import 'package:raga/avatar/avatar_migration.dart';
import 'package:raga/avatar/avatar_models.dart';
import 'package:raga/avatar/avatar_progress.dart';
import 'package:raga/avatar/progression.dart';
import 'package:raga/models/bmi_record.dart';

// Evidence I.8: migration rebuilds XP and unlocks from record history.

AvatarManifest? _manifest;
ProgressionConfig? _prog;

Future<AvatarProgressService> _service(DateTime now) async {
  _manifest ??= await AvatarManifest.load();
  _prog ??= await ProgressionConfig.load();
  return AvatarProgressService(
      manifest: _manifest!, progression: _prog!, clock: () => now);
}

BmiRecord _rec(String pid, DateTime at, [double w = 70]) => BmiRecord(
      profileId: pid,
      heightCm: 170,
      weightKg: w,
      createdAt: at,
    );

List<BmiRecord> _dailyHistory(String pid, DateTime end, int days) {
  final day = DateTime(end.year, end.month, end.day);
  return [
    for (var i = days - 1; i >= 0; i--)
      _rec(pid, day.subtract(Duration(days: i)), 70.0 - i * 0.1),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Monday 2026-10-19 09:00 local.
  final mon9 = DateTime(2026, 10, 19, 9, 0);

  group('migrateAvatarState', () {
    test('rebuilds xp and unlocks from history, no notification flood',
        () async {
      final s = await _service(mon9);
      // 10 records, all backdated (Oct 9..18).
      final history = _dailyHistory('p', DateTime(2026, 10, 18, 9), 10);
      final st = migrateAvatarState(
        service: s,
        profileId: 'p',
        history: history,
        goalKg: 65,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      // Backdated: no daily_record XP. Streak milestones 3 & 7 hit,
      // setup +40, goal_set +25.
      expect(
          st.ledger.where((e) => e.type == XpType.dailyRecord), isEmpty);
      expect(st.totalXp, 40 + 40 + 40 + 25);
      expect(st.bestStreak, 10);
      // Unlocks from history: 10 records -> coral, 7-day streak -> curly.
      expect(st.unlockedItemIds, contains('coral'));
      expect(st.unlockedItemIds, contains('curly'));
      // ...all pre-marked seen: no flood.
      expect(st.unlockSeenIds, st.unlockedItemIds);
      // Goal baseline = latest weight (Oct 18 record = 70.0).
      expect(st.goalBaselineKg, 70.0);
      // Default config kept.
      expect(st.config, AvatarConfig.defaults(s.manifest));
    });

    test('empty history: only setup xp, open items seen', () async {
      final s = await _service(mon9);
      final st = migrateAvatarState(
        service: s,
        profileId: 'p',
        history: const [],
        goalKg: null,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(st.totalXp, 40);
      expect(st.bestStreak, 0);
      expect(st.goalReached, isFalse);
      expect(st.goalBaselineKg, isNull);
      // Only the always-open items, all seen.
      expect(st.unlockedItemIds.length, 8);
      expect(st.unlockSeenIds, st.unlockedItemIds);
    });

    test('record dated today earns daily xp in migration', () async {
      final s = await _service(mon9);
      final history = _dailyHistory('p', mon9, 3);
      final st = migrateAvatarState(
        service: s,
        profileId: 'p',
        history: history,
        goalKg: null,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(
          st.ledger.where((e) => e.type == XpType.dailyRecord), hasLength(1));
    });

    test('never grants goal_reached: it fires on the next weigh-in',
        () async {
      final s = await _service(mon9);
      // History already below the goal — migration must NOT invent it.
      final history = [
        _rec('p', DateTime(2026, 10, 17, 9), 64.0),
        _rec('p', DateTime(2026, 10, 18, 9), 64.5),
      ];
      final st = migrateAvatarState(
        service: s,
        profileId: 'p',
        history: history,
        goalKg: 65,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      expect(
          st.ledger.where((e) => e.type == XpType.goalReached), isEmpty);
      expect(st.goalReached, isFalse);
      expect(st.unlockedItemIds, isNot(contains('blue')));
    });

    test('result survives a storage roundtrip', () async {
      final s = await _service(mon9);
      final history = _dailyHistory('p', DateTime(2026, 10, 18, 9), 10);
      final st = migrateAvatarState(
        service: s,
        profileId: 'p',
        history: history,
        goalKg: 65,
        hasWeighSchedule: false,
        scheduleWeekdays: const [],
      );
      final back = AvatarProfileState.fromJson(st.toJson());
      expect(back.totalXp, st.totalXp);
      expect(back.unlockedItemIds, st.unlockedItemIds);
      expect(back.unlockSeenIds, st.unlockSeenIds);
      expect(back.bestStreak, st.bestStreak);
      expect(back.goalBaselineKg, st.goalBaselineKg);
    });
  });
}
