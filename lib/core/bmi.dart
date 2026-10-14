import 'package:flutter/material.dart';

/// Kategori BMI standar WHO.
enum BmiCategory { underweight, normal, overweight, obese }

/// Metadata tampilan tiap kategori: label resmi (sesuai brief), penjelasan
/// berbahasa Indonesia yang mudah dipahami, dan warna indikator.
class CategoryMeta {
  final String label;
  final String explanation;
  final Color color;
  const CategoryMeta(this.label, this.explanation, this.color);
}

const Map<BmiCategory, CategoryMeta> categoryMeta = {
  BmiCategory.underweight: CategoryMeta(
    'Underweight',
    'Berat badanmu di bawah rentang sehat. Yuk naikin pelan-pelan dengan cara yang sehat.',
    Color(0xFF5AA9E6),
  ),
  BmiCategory.normal: CategoryMeta(
    'Normal',
    'Berat badanmu ada di rentang sehat. Pertahankan!',
    Color(0xFF3ED598),
  ),
  BmiCategory.overweight: CategoryMeta(
    'Overweight',
    'Berat badanmu sedikit di atas rentang sehat. Masih gampang dikejar, kok.',
    Color(0xFFF2B544),
  ),
  BmiCategory.obese: CategoryMeta(
    'Obese',
    'Berat badanmu di atas rentang sehat. Nggak apa-apa, mulai dari langkah kecil aja.',
    Color(0xFFF2555A),
  ),
};

BmiCategory categoryOf(double bmi) {
  if (bmi < 18.5) return BmiCategory.underweight;
  if (bmi < 25) return BmiCategory.normal;
  if (bmi < 30) return BmiCategory.overweight;
  return BmiCategory.obese;
}

/// BMI = berat (kg) / tinggi (m)^2
double calcBmi({required double weightKg, required double heightCm}) {
  final m = heightCm / 100;
  if (m <= 0) return 0;
  return weightKg / (m * m);
}

/// Rentang berat ideal untuk tinggi tertentu (berdasar rentang BMI sehat 18.5 - 24.99).
({double min, double max}) idealWeightRange(double heightCm) {
  final m2 = (heightCm / 100) * (heightCm / 100);
  return (min: 18.5 * m2, max: 24.99 * m2);
}

/// BMR dengan rumus Mifflin-St Jeor.
double bmrMifflin({
  required double weightKg,
  required double heightCm,
  required int age,
  required bool isMale,
}) {
  return 10 * weightKg + 6.25 * heightCm - 5 * age + (isMale ? 5 : -161);
}

/// Faktor aktivitas untuk TDEE.
const Map<String, double> activityFactors = {
  'Minim': 1.2,
  'Ringan': 1.375,
  'Sedang': 1.55,
  'Berat': 1.725,
};

double tdee(double bmr, double activityFactor) => bmr * activityFactor;

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 19) return 'Selamat sore';
  return 'Selamat malam';
}

/// Format angka ala Indonesia: koma sebagai pemisah desimal.
String formatId(double value, [int decimals = 1]) {
  return value.toStringAsFixed(decimals).replaceAll('.', ',');
}

/// Format angka ribuan ala Indonesia: 2217 -> "2.217"
String formatIntId(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

const idMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatDateId(DateTime d) => '${d.day} ${idMonths[d.month - 1]}';
