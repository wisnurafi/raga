import 'package:flutter_test/flutter_test.dart';
import 'package:raga/avatar/avatar_manifest.dart';
import 'package:raga/avatar/avatar_models.dart';
import 'package:raga/avatar/progression.dart';

// Evidence I.3 (level part): boundaries, XP->level conversion, max cap.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProgressionConfig prog;
  late AvatarManifest manifest;
  setUpAll(() async {
    prog = await ProgressionConfig.load();
    manifest = await AvatarManifest.load();
  });

  group('progression.json', () {
    test('level curve: 19 thresholds, total 983, max level 20', () {
      expect(prog.maxLevel, 20);
      expect(prog.levelThresholds.length, 19);
      final total = prog.levelThresholds.reduce((a, b) => a + b);
      expect(total, 983);
      expect(prog.xpForLevel(20), 983);
    });

    test('titles cover levels 1..20 exactly once', () {
      final seen = <int>{};
      for (final t in prog.titles) {
        for (var l = t.min; l <= t.max; l++) {
          expect(seen.add(l), isTrue, reason: 'level $l covered twice');
        }
      }
      expect(seen, {for (var l = 1; l <= 20; l++) l});
      expect(prog.titleFor(1), 'Pemula');
      expect(prog.titleFor(5), 'Pemula');
      expect(prog.titleFor(6), 'Pejalan');
      expect(prog.titleFor(10), 'Pejalan');
      expect(prog.titleFor(11), 'Penjelajah');
      expect(prog.titleFor(15), 'Penjelajah');
      expect(prog.titleFor(16), 'Juara');
      expect(prog.titleFor(20), 'Juara');
    });

    test('all xp awards present and positive', () {
      const types = [
        'daily_record',
        'scheduled_weigh',
        'streak_milestone',
        'profile_setup_complete',
        'goal_set',
        'goal_reached',
        'weekly_wrapped_viewed',
      ];
      for (final type in types) {
        expect(prog.award(type), greaterThan(0), reason: type);
      }
      expect(prog.award('daily_record'), 15);
      expect(prog.award('goal_reached'), 150);
    });

    test('unknown award type throws instead of granting 0', () {
      expect(() => prog.award('nope'), throwsStateError);
    });

    test('streak milestones', () {
      expect(prog.streakMilestones, [3, 7, 14, 30]);
    });
  });

  group('level math', () {
    test('boundaries: 19/20, 43/44, 982/983', () {
      expect(prog.levelForXp(0), 1);
      expect(prog.levelForXp(19), 1);
      expect(prog.levelForXp(20), 2);
      expect(prog.levelForXp(43), 2);
      expect(prog.levelForXp(44), 3);
      expect(prog.levelForXp(70), 3);
      expect(prog.levelForXp(71), 4);
      expect(prog.levelForXp(982), 19);
      expect(prog.levelForXp(983), 20);
    });

    test('level caps at max even for huge xp', () {
      expect(prog.levelForXp(1000000), 20);
      expect(prog.levelForXp(983), 20);
    });

    test('xpForLevel is cumulative', () {
      expect(prog.xpForLevel(1), 0);
      expect(prog.xpForLevel(2), 20);
      expect(prog.xpForLevel(3), 44);
      expect(prog.xpForLevel(11), 360);
      expect(prog.xpForLevel(20), 983);
    });

    test('progress inside a level and the header chip format', () {
      expect(prog.xpIntoLevel(0, 1), 0);
      expect(prog.xpIntoLevel(44, 3), 0);
      expect(prog.xpIntoLevel(50, 3), 6);
      expect(prog.xpToNextLevel(1), 20);
      expect(prog.xpToNextLevel(3), 27);
      expect(prog.xpToNextLevel(20), 0);
      // "<Title> · Lv. n · into / toNext XP" — the Avatar screen chip.
      const xp = 360;
      final level = prog.levelForXp(xp);
      expect(level, 11);
      expect(
          '${prog.titleFor(level)} · Lv. $level · '
          '${prog.xpIntoLevel(xp, level)} / ${prog.xpToNextLevel(level)} XP',
          'Penjelajah · Lv. 11 · 0 / 55 XP');
    });
  });

  group('models', () {
    test('AvatarConfig defaults come from the manifest', () {
      final c = AvatarConfig.defaults(manifest);
      expect(c.skin, 'skin-2');
      expect(c.hair, 'short');
      expect(c.hairColor, 'navy');
      expect(c.shirt, 'lavender');
      expect(c.accessory, isNull);
      expect(c.frame, isNull);
    });

    test('AvatarConfig serialization roundtrip', () {
      const c = AvatarConfig(
        skin: 'skin-3',
        hair: 'curly',
        hairColor: 'brown',
        shirt: 'amber',
        accessory: 'glasses',
        frame: 'fire',
      );
      expect(AvatarConfig.fromJson(c.toJson()), c);
      final d = AvatarConfig.defaults(manifest);
      expect(AvatarConfig.fromJson(d.toJson()), d);
    });

    test('XpEvent uid is (profileId, type, key); roundtrip', () {
      final e = XpEvent(
        profileId: 'p1',
        type: 'daily_record',
        key: '2026-10-17',
        amount: 15,
        date: DateTime(2026, 10, 17),
      );
      expect(e.uid, 'p1|daily_record|2026-10-17');
      final back = XpEvent.fromJson(e.toJson());
      expect(back.uid, e.uid);
      expect(back.amount, 15);
      expect(back.date, DateTime(2026, 10, 17));
    });
  });
}
