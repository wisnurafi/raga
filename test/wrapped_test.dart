import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/wrapped.dart';
import 'package:raga/detak/detak_assets.dart';
import 'package:raga/models/bmi_record.dart';

BmiRecord _rec(String id, double kg, DateTime at) => BmiRecord(
      id: id,
      profileId: 'p1',
      heightCm: 170,
      weightKg: kg,
      createdAt: at,
    );

// Week: Mon 2026-10-12 .. Sun 2026-10-18.
final _monday = DateTime(2026, 10, 12);

void main() {
  group('computeWrapped', () {
    test('empty week returns null', () {
      expect(computeWrapped([], _monday), isNull);
      expect(
          computeWrapped(
              [_rec('a', 70, DateTime(2026, 10, 5))], _monday),
          isNull);
    });

    test('delta, counts, first/last for a losing week', () {
      final recs = [
        _rec('a', 80, DateTime(2026, 10, 12, 8)),
        _rec('b', 79, DateTime(2026, 10, 14, 8)),
        _rec('c', 78.5, DateTime(2026, 10, 16, 8)),
      ];
      final w = computeWrapped(recs, _monday)!;
      expect(w.logCount, 3);
      expect(w.activeDays, 3);
      expect(w.deltaKg, closeTo(-1.5, 1e-9));
      expect(w.deltaPct, closeTo(-1.5 / 80 * 100, 1e-9));
      expect(w.firstKg, 80);
      expect(w.lastKg, 78.5);
      expect(w.weekStart, _monday);
      expect(w.weekEnd, DateTime(2026, 10, 18));
    });

    test('dayWeights is Monday-first with first-log-of-day', () {
      final recs = [
        _rec('a', 70, DateTime(2026, 10, 12, 8)), // Mon morning wins
        _rec('b', 69.5, DateTime(2026, 10, 12, 20)), // Mon evening ignored
        _rec('c', 71, DateTime(2026, 10, 14, 8)), // Wed
      ];
      final w = computeWrapped(recs, _monday)!;
      expect(w.dayWeights.length, 7);
      expect(w.dayWeights[0], 70);
      expect(w.dayWeights[1], isNull);
      expect(w.dayWeights[2], 71);
      expect(w.dayWeights.sublist(3), everyElement(isNull));
      // firstKg/lastKg are chronological, not day-based.
      expect(w.firstKg, 70);
      expect(w.lastKg, 71);
      expect(w.activeDays, 2);
    });

    test('bestDayStreak counts consecutive calendar days', () {
      final recs = [
        _rec('a', 70, DateTime(2026, 10, 12, 8)), // Mon
        _rec('b', 70, DateTime(2026, 10, 13, 8)), // Tue
        _rec('c', 70, DateTime(2026, 10, 14, 8)), // Wed
        // Thu skipped
        _rec('d', 70, DateTime(2026, 10, 16, 8)), // Fri
      ];
      final w = computeWrapped(recs, _monday)!;
      expect(w.bestDayStreak, 3);
    });

    test('single log: no delta, dayWeights has one entry', () {
      final w = computeWrapped(
          [_rec('a', 80, DateTime(2026, 10, 13, 8))], _monday)!;
      expect(w.deltaKg, isNull);
      expect(w.firstKg, isNull);
      expect(w.lastKg, isNull);
      expect(w.dayWeights[1], 80);
      expect(w.bestDayStreak, 1);
      expect(w.activeDays, 1);
    });

    test('prevAvgBmi is set when the previous week has logs', () {
      final recs = [
        _rec('a', 66, DateTime(2026, 10, 6, 8)), // prev week
        _rec('b', 65, DateTime(2026, 10, 13, 8)), // this week
      ];
      final w = computeWrapped(recs, _monday)!;
      expect(w.prevAvgBmi, closeTo(66 / (1.7 * 1.7), 1e-9));
    });

    test('prevAvgBmi is null without previous-week logs', () {
      final w = computeWrapped(
          [_rec('a', 65, DateTime(2026, 10, 13, 8))], _monday)!;
      expect(w.prevAvgBmi, isNull);
    });

    test('zoneStreakWeeks counts same-zone weeks back', () {
      // 65/66/64 kg at 170cm are all "normal" zone.
      final recs = [
        _rec('a', 65, DateTime(2026, 10, 13, 8)),
        _rec('b', 66, DateTime(2026, 10, 6, 8)),
        _rec('c', 64, DateTime(2026, 9, 29, 8)),
      ];
      expect(computeWrapped(recs, _monday)!.zoneStreakWeeks, 3);
    });

    test('zoneStreakWeeks stops at a different-zone week', () {
      // 80 kg at 170cm is "overweight", 65 kg is "normal".
      final recs = [
        _rec('a', 65, DateTime(2026, 10, 13, 8)),
        _rec('b', 80, DateTime(2026, 10, 6, 8)),
      ];
      expect(computeWrapped(recs, _monday)!.zoneStreakWeeks, 1);
    });
  });

  group('week helpers', () {
    test('lastCompletedWeekMonday', () {
      // Friday 2026-10-16 -> Monday 2026-10-05.
      expect(lastCompletedWeekMonday(DateTime(2026, 10, 16)),
          DateTime(2026, 10, 5));
      // Monday 2026-10-19 -> Monday 2026-10-12.
      expect(lastCompletedWeekMonday(DateTime(2026, 10, 19)),
          DateTime(2026, 10, 12));
    });

    test('daysUntilNextWrapped', () {
      expect(daysUntilNextWrapped(DateTime(2026, 10, 16)), 3); // Fri
      expect(daysUntilNextWrapped(DateTime(2026, 10, 18)), 1); // Sun
      expect(daysUntilNextWrapped(DateTime(2026, 10, 19)), 7); // Mon
    });

    test('isoWeekNumber', () {
      expect(isoWeekNumber(DateTime(2026, 10, 12)), 42); // Mon
      expect(isoWeekNumber(DateTime(2026, 10, 18)), 42); // Sun same week
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1); // Thu
      expect(isoWeekNumber(DateTime(2025, 12, 29)), 1); // Mon, ISO year 2026
      expect(isoWeekNumber(DateTime(2026, 1, 4)), 1); // Sun
      expect(isoWeekNumber(DateTime(2026, 1, 5)), 2); // Mon
    });

    group('formatWeekRangeFull', () {
      test('same month', () {
        expect(
            formatWeekRangeFull(
                DateTime(2026, 10, 12), DateTime(2026, 10, 18), 'id'),
            '12 – 18 Oktober 2026');
        expect(
            formatWeekRangeFull(
                DateTime(2026, 10, 12), DateTime(2026, 10, 18), 'en'),
            'Oct 12 – 18, 2026');
      });

      test('cross month', () {
        expect(
            formatWeekRangeFull(
                DateTime(2026, 11, 30), DateTime(2026, 12, 6), 'id'),
            '30 November – 6 Desember 2026');
        expect(
            formatWeekRangeFull(
                DateTime(2026, 11, 30), DateTime(2026, 12, 6), 'en'),
            'Nov 30 – Dec 6, 2026');
      });

      test('cross year', () {
        expect(
            formatWeekRangeFull(
                DateTime(2025, 12, 29), DateTime(2026, 1, 4), 'id'),
            '29 Desember 2025 – 4 Januari 2026');
        expect(
            formatWeekRangeFull(
                DateTime(2025, 12, 29), DateTime(2026, 1, 4), 'en'),
            'Dec 29, 2025 – Jan 4, 2026');
      });
    });

    group('formatWeekRangeShort', () {
      test('same month', () {
        expect(
            formatWeekRangeShort(
                DateTime(2026, 10, 12), DateTime(2026, 10, 18), 'id'),
            '12–18 OKT');
        expect(
            formatWeekRangeShort(
                DateTime(2026, 10, 12), DateTime(2026, 10, 18), 'en'),
            'OCT 12–18');
      });

      test('cross month', () {
        expect(
            formatWeekRangeShort(
                DateTime(2026, 11, 30), DateTime(2026, 12, 6), 'id'),
            '30 NOV–6 DES');
        expect(
            formatWeekRangeShort(
                DateTime(2026, 11, 30), DateTime(2026, 12, 6), 'en'),
            'NOV 30–DEC 6');
      });
    });

    group('previewWeekMonday', () {
      // "now" fixed: Wed 2026-10-14, so the current week is Mon 2026-10-12.
      final now = DateTime(2026, 10, 14, 12);

      test('empty records returns null', () {
        expect(previewWeekMonday([], now), isNull);
      });

      test('picks the current week when it has logs', () {
        final recs = [_rec('a', 80, DateTime(2026, 10, 13, 8))];
        expect(previewWeekMonday(recs, now), DateTime(2026, 10, 12));
      });

      test('walks back to the most recent week with logs', () {
        final recs = [
          _rec('a', 80, DateTime(2026, 10, 5, 8)), // week of Oct 5
          _rec('b', 79, DateTime(2026, 9, 21, 8)), // week of Sep 21
        ];
        expect(previewWeekMonday(recs, now), DateTime(2026, 10, 5));
      });

      test('returns null when the only logs are beyond 12 weeks', () {
        final recs = [_rec('a', 80, DateTime(2026, 7, 1, 8))];
        expect(previewWeekMonday(recs, now), isNull);
      });

      test('preview story computes for the found week', () {
        final recs = [
          _rec('a', 80, DateTime(2026, 10, 13, 8)),
          _rec('b', 79, DateTime(2026, 10, 14, 8)),
        ];
        final monday = previewWeekMonday(recs, now)!;
        final w = computeWrapped(recs, monday)!;
        expect(w.logCount, 2);
        expect(w.deltaKg, closeTo(-1.0, 1e-9));
      });
    });
  });

  group('detakTotalXp', () {
    test('sums banked level XP plus current progress', () {
      expect(detakTotalXp(1, 0), 0);
      expect(detakTotalXp(2, 3), detakXpForLevel(1) + 3); // 5 + 3
      expect(
          detakTotalXp(4, 2),
          detakXpForLevel(1) +
              detakXpForLevel(2) +
              detakXpForLevel(3) +
              2); // 5 + 8 + 13 + 2
    });
  });
}
