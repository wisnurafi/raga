import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/bmi.dart';

void main() {
  group('calcBmi', () {
    test('170 cm / 65 kg = 22.5 (Normal)', () {
      final bmi = calcBmi(weightKg: 65, heightCm: 170);
      expect(bmi, closeTo(22.49, 0.01));
      expect(categoryOf(bmi), BmiCategory.normal);
    });

    test('batas kategori WHO', () {
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
    test('pria 65 kg / 170 cm / 21 th = 1612.5', () {
      final bmr = bmrMifflin(
          weightKg: 65, heightCm: 170, age: 21, isMale: true);
      expect(bmr, closeTo(1612.5, 0.01));
    });

    test('wanita memakai konstanta -161', () {
      final pria = bmrMifflin(
          weightKg: 65, heightCm: 170, age: 21, isMale: true);
      final wanita = bmrMifflin(
          weightKg: 65, heightCm: 170, age: 21, isMale: false);
      expect(pria - wanita, closeTo(166, 0.01));
    });
  });

  group('formatId', () {
    test('koma sebagai pemisah desimal', () {
      expect(formatId(22.5), '22,5');
      expect(formatIntId(2217), '2.217');
    });
  });
}
