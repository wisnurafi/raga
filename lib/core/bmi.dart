import 'package:flutter/material.dart';

// Standard WHO BMI categories.
enum BmiCategory { underweight, normal, overweight, obese }

// What each category looks like on screen: its label, a plain-English
// explanation, and the indicator color.
class CategoryMeta {
  final String label;
  final String explanation;
  final Color color;
  const CategoryMeta(this.label, this.explanation, this.color);
}

const Map<BmiCategory, CategoryMeta> categoryMeta = {
  BmiCategory.underweight: CategoryMeta(
    'Underweight',
    "You're below the healthy range. Let's bring it up slowly, the healthy way.",
    Color(0xFF5AA9E6),
  ),
  BmiCategory.normal: CategoryMeta(
    'Normal',
    "You're in the healthy range. Keep it up!",
    Color(0xFF3ED598),
  ),
  BmiCategory.overweight: CategoryMeta(
    'Overweight',
    "You're a bit above the healthy range. Totally doable to get back.",
    Color(0xFFF2B544),
  ),
  BmiCategory.obese: CategoryMeta(
    'Obese',
    "You're above the healthy range. No worries — start with small steps.",
    Color(0xFFF2555A),
  ),
};

BmiCategory categoryOf(double bmi) {
  if (bmi < 18.5) return BmiCategory.underweight;
  if (bmi < 25) return BmiCategory.normal;
  if (bmi < 30) return BmiCategory.overweight;
  return BmiCategory.obese;
}

// BMI = weight (kg) / height (m)^2
double calcBmi({required double weightKg, required double heightCm}) {
  final m = heightCm / 100;
  if (m <= 0) return 0;
  return weightKg / (m * m);
}

// Healthy weight range for a given height (BMI 18.5 – 24.99).
({double min, double max}) idealWeightRange(double heightCm) {
  final m2 = (heightCm / 100) * (heightCm / 100);
  return (min: 18.5 * m2, max: 24.99 * m2);
}

// BMR via the Mifflin-St Jeor formula.
double bmrMifflin({
  required double weightKg,
  required double heightCm,
  required int age,
  required bool isMale,
}) {
  return 10 * weightKg + 6.25 * heightCm - 5 * age + (isMale ? 5 : -161);
}

// Activity multipliers for daily calorie needs.
const Map<String, double> activityFactors = {
  'Minimal': 1.2,
  'Light': 1.375,
  'Moderate': 1.55,
  'Active': 1.725,
};

double tdee(double bmr, double activityFactor) => bmr * activityFactor;

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

// Number formatting, US style: decimal point, thousands separator.
String formatNum(double value, [int decimals = 1]) {
  return value.toStringAsFixed(decimals);
}

String formatIntNum(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

const shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) => '${d.day} ${shortMonths[d.month - 1]}';
