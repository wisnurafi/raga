// Standard WHO BMI categories.
enum BmiCategory { underweight, normal, overweight, obese }

BmiCategory categoryOf(double bmi) {
  if (bmi < 18.5) return BmiCategory.underweight;
  if (bmi < 25) return BmiCategory.normal;
  if (bmi < 30) return BmiCategory.overweight;
  return BmiCategory.obese;
}

/// English display label per category — the mockup's gauge legend is English.
extension BmiCategoryLabel on BmiCategory {
  String get label => switch (this) {
        BmiCategory.underweight => 'Underweight',
        BmiCategory.normal => 'Normal',
        BmiCategory.overweight => 'Overweight',
        BmiCategory.obese => 'Obese',
      };
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

// Unit conversions, single source of truth (home, history, health,
// onboarding, and profile screens all convert for imperial display).
const kgToLb = 2.20462;
const cmToIn = 1 / 2.54;

// Fixed-decimal formatting ("24.9"). No thousands separator here — for
// grouped integers use formatIntNum (US style) or formatIntId (Indonesian).
String formatNum(double value, [int decimals = 1]) {
  return value.toStringAsFixed(decimals);
}

String _groupInt(int value, String sep) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(sep);
    buf.write(s[i]);
  }
  return buf.toString();
}

// US style: 2,217. (Pinned by unit tests — keep the behavior.)
String formatIntNum(int value) => _groupInt(value, ',');

// --- Indonesian presentation (what the mockup shows) ---
// Thousands separated by '.', e.g. 2.217 for TDEE.
String formatIntId(int value) => _groupInt(value, '.');

const idShortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Monday-first short day names: Sen..Min.
const idShortDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String formatDateId(DateTime d) => '${d.day} ${idShortMonths[d.month - 1]}';
