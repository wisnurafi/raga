import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/wrapped.dart';
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

    test('delta, counts and badge for a losing week', () {
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
      expect(w.badgeId, 'pejuang');
      expect(w.weekStart, _monday);
      expect(w.weekEnd, DateTime(2026, 10, 18));
    });

    test('konsisten badge wins over pejuang', () {
      final recs = [
        for (var i = 0; i < 5; i++)
          _rec('r$i', 80 - i * 0.5,
              DateTime(2026, 10, 12 + i, 8)),
      ];
      final w = computeWrapped(recs, _monday)!;
      expect(w.activeDays, 5);
      expect(w.badgeId, 'konsisten');
    });

    test('single log: no delta, penjelajah badge', () {
      final w = computeWrapped(
          [_rec('a', 80, DateTime(2026, 10, 13, 8))], _monday)!;
      expect(w.deltaKg, isNull);
      expect(w.badgeId, 'penjelajah');
    });

    test('prev week count is compared correctly', () {
      final recs = [
        _rec('a', 80, DateTime(2026, 10, 6, 8)),
        _rec('b', 80, DateTime(2026, 10, 7, 8)),
        _rec('c', 79, DateTime(2026, 10, 13, 8)),
      ];
      final w = computeWrapped(recs, _monday)!;
      expect(w.logCount, 1);
      expect(w.prevLogCount, 2);
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
}
