import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/bmi.dart';
import 'package:raga/core/tips.dart';

void main() {
  group('calcBmi', () {
    test('170 cm / 65 kg = 22.5 (Normal)', () {
      final bmi = calcBmi(weightKg: 65, heightCm: 170);
      expect(bmi, closeTo(22.49, 0.01));
      expect(categoryOf(bmi), BmiCategory.normal);
    });

    test('WHO category boundaries', () {
      expect(categoryOf(18.4), BmiCategory.underweight);
      expect(categoryOf(18.5), BmiCategory.normal);
      expect(categoryOf(24.9), BmiCategory.normal);
      expect(categoryOf(25.0), BmiCategory.overweight);
      expect(categoryOf(29.9), BmiCategory.overweight);
      expect(categoryOf(30.0), BmiCategory.obese);
    });
  });

  group('idealWeightRange', () {
    test('170 cm -> 53.5 - 72.2 kg', () {
      final r = idealWeightRange(170);
      expect(r.min, closeTo(53.47, 0.01));
      expect(r.max, closeTo(72.22, 0.01));
    });
  });

  group('bmrMifflin', () {
    test('male 65 kg / 170 cm / 21 yrs = 1612.5', () {
      final bmr = bmrMifflin(
          weightKg: 65, heightCm: 170, age: 21, isMale: true);
      expect(bmr, closeTo(1612.5, 0.01));
    });

    test('female uses the -161 constant', () {
      final male = bmrMifflin(
          weightKg: 65, heightCm: 170, age: 21, isMale: true);
      final female = bmrMifflin(
          weightKg: 65, heightCm: 170, age: 21, isMale: false);
      expect(male - female, closeTo(166, 0.01));
    });
  });

  group('formatNum', () {
    test('dot as decimal separator', () {
      expect(formatNum(22.5), '22.5');
      expect(formatIntNum(2217), '2,217');
    });
  });

  group('idSpanLabel', () {
    test('human Indonesian spans', () {
      final a = DateTime(2026, 10, 15);
      expect(idSpanLabel(a, a), 'hari ini');
      expect(idSpanLabel(a, a.add(const Duration(days: 3))), '3 hari');
      expect(idSpanLabel(a, a.add(const Duration(days: 21))), '3 minggu');
      expect(idSpanLabel(a, a.add(const Duration(days: 90))), '3 bulan');
    });
  });

  group('buildWeightInsight', () {
    test('needs at least 2 points', () {
      expect(
        buildWeightInsight([65], [DateTime(2026, 10, 1)]),
        contains('Belum cukup data'),
      );
    });

    test('stable weight', () {
      final s = buildWeightInsight(
        [65.0, 65.0],
        [DateTime(2026, 9, 1), DateTime(2026, 10, 1)],
      );
      expect(s, contains('Stabil di 65.0 kg'));
    });

    test('healthy loss pace with goal remaining', () {
      final s = buildWeightInsight(
        [70.0, 68.0],
        [DateTime(2026, 9, 1), DateTime(2026, 10, 1)],
        goalKg: 70,
      );
      expect(s, contains('Turun 2.0 kg'));
      expect(s, contains('dalam batas sehat'));
      expect(s, contains('Kurang 2.0 kg lagi ke target'));
    });

    test('too-fast loss warns', () {
      final s = buildWeightInsight(
        [80.0, 70.0],
        [DateTime(2026, 9, 1), DateTime(2026, 10, 1)],
      );
      expect(s, contains('konsultasi ahli gizi'));
    });

    test('goal reached', () {
      final s = buildWeightInsight(
        [70.0, 65.2],
        [DateTime(2026, 9, 1), DateTime(2026, 10, 1)],
        goalKg: 65,
      );
      expect(s, contains('tercapai'));
    });

    test('imperial rendering', () {
      final s = buildWeightInsight(
        [70.0, 68.0],
        [DateTime(2026, 9, 1), DateTime(2026, 10, 1)],
        metric: false,
      );
      expect(s, contains('lb'));
      expect(s, isNot(contains('kg')));
    });
  });

  group('tips', () {
    test('70 tips total across 4 categories', () {
      final n = BmiCategory.values
          .map((c) => healthTips[c]!.length)
          .reduce((a, b) => a + b);
      expect(n, 70);
    });

    test('tipsForDay is deterministic per day with distinct tips', () {
      final day = DateTime(2026, 10, 15);
      final a = tipsForDay(BmiCategory.normal, day).map((t) => t.title);
      final b = tipsForDay(BmiCategory.normal, day).map((t) => t.title);
      expect(a, orderedEquals(b));
      expect(a.toSet(), hasLength(3));
    });

    test('fewer than 2 records -> the 3 dasar tips', () {
      final tips = tipsForResult(
        cat: BmiCategory.overweight,
        weightsKg: [80],
        goalKg: null,
        streakWeeks: 0,
        day: DateTime(2026, 10, 15),
      );
      expect(
        tips.map((t) => t.title),
        orderedEquals([
          'Kurangi minuman manis',
          'Jalan santai tiap hari',
          'Makan perlahan',
        ]),
      );
    });

    test('trend away from goal -> comeback tip first', () {
      final tips = tipsForResult(
        cat: BmiCategory.overweight,
        weightsKg: [78, 79, 80.5], // rising while the goal is below
        goalKg: 70,
        streakWeeks: 0,
        day: DateTime(2026, 10, 15),
      );
      expect(tips.first.tags, contains('comeback'));
    });

    test('trend toward goal -> plain rotation, no overrides', () {
      final day = DateTime(2026, 10, 15);
      final tips = tipsForResult(
        cat: BmiCategory.overweight,
        weightsKg: [82, 80, 78.5], // falling toward the goal
        goalKg: 70,
        streakWeeks: 0,
        day: day,
      );
      expect(
        tips.map((t) => t.title),
        orderedEquals(
            tipsForDay(BmiCategory.overweight, day).map((t) => t.title)),
      );
    });

    test('streak of 4+ weeks -> streak tip last', () {
      final tips = tipsForResult(
        cat: BmiCategory.normal,
        weightsKg: [65, 65.1, 64.9],
        goalKg: null,
        streakWeeks: 5,
        day: DateTime(2026, 10, 15),
      );
      expect(tips.last.tags, contains('streak'));
    });

    test('dailyTip returns one tip from the pool', () {
      final tip = dailyTip(BmiCategory.obese, DateTime(2026, 10, 15));
      expect(healthTips[BmiCategory.obese]!.contains(tip), isTrue);
    });
  });
}
