import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/bmi.dart';

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
}
