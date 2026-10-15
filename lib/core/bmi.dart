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

// Height/weight ranges for the sliders on the home and onboarding
// screens. One place so the two screens can't drift apart.
const heightRangeCm = (min: 130.0, max: 220.0);
const heightRangeIn = (min: 51.0, max: 87.0);
const weightRangeKg = (min: 30.0, max: 150.0);
const weightRangeLb = (min: 66.0, max: 330.0);

// Fixed-decimal formatting ("24.9"). No thousands separator here — for
// grouped integers use formatIntNum (US style) or formatIntId (Indonesian).
String formatNum(double value, [int decimals = 1]) {
  return value.toStringAsFixed(decimals);
}

/// formatNum, but with a trailing ".0" dropped ("62" instead of "62.0").
String formatNumTrimmed(double value, [int decimals = 1]) =>
    formatNum(value, decimals).replaceAll(RegExp(r'\.0$'), '');

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

/// One-line reminder schedule summary, e.g.
/// "2× seminggu · Sen & Kam · 07.00" / "Setiap hari · 07.00" / "Mati".
String reminderSummary(List<int> days, int h, int m) {
  if (days.isEmpty) return 'Mati';
  final t =
      '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';
  final sorted = [...days]..sort();
  if (sorted.length == 7) return 'Setiap hari · $t';
  final names = sorted.map((d) => idShortDays[d - 1]).toList();
  final joined = names.length == 1
      ? names.first
      : names.length == 2
          ? '${names[0]} & ${names[1]}'
          : '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  return '${names.length}× seminggu · $joined · $t';
}

String formatDateId(DateTime d) => '${d.day} ${idShortMonths[d.month - 1]}';

/// Human span between two dates, Indonesian:
/// "hari ini", "3 hari", "2 minggu", "6 bulan".
String idSpanLabel(DateTime a, DateTime b) {
  final days = b.difference(a).inDays.abs();
  if (days < 1) return 'hari ini';
  if (days < 14) return '$days hari';
  if (days < 60) return '${(days / 7).round()} minggu';
  return '${(days / 30).round()} bulan';
}

/// One-or-two-sentence Indonesian insight for the history analytics card.
///
/// [weightsKg] oldest-first, already filtered to the selected range;
/// [dates] the matching timestamps, oldest-first. [goalKg] the profile's
/// goal weight in kg, if set. Set [metric] false to render in lb.
String buildWeightInsight(
  List<double> weightsKg,
  List<DateTime> dates, {
  double? goalKg,
  bool metric = true,
}) {
  assert(weightsKg.length == dates.length);
  String w(double kg) =>
      metric ? '${formatNum(kg)} kg' : '${(kg * kgToLb).round()} lb';
  if (weightsKg.length < 2) {
    return 'Belum cukup data di rentang ini — timbang minimal 2× biar trennya kebaca.';
  }
  final first = weightsKg.first;
  final last = weightsKg.last;
  final span = idSpanLabel(dates.first, dates.last);
  final d = last - first; // negative = lost weight
  final buf = StringBuffer();
  if (d.abs() < 0.05) {
    buf.write('Stabil di ${w(last)} selama $span — pertahankan.');
  } else {
    buf.write('${d < 0 ? 'Turun' : 'Naik'} ${w(d.abs())} dalam $span.');
    final days = dates.last.difference(dates.first).inDays;
    if (days >= 7) {
      final rate = d.abs() / (days / 7);
      if (d < 0) {
        buf.write(rate <= 1.0
            ? ' Laju ±${w(rate)}/minggu — masih dalam batas sehat.'
            : ' Laju ±${w(rate)}/minggu — di atas anjuran umum '
                '(${metric ? '0,5–1 kg' : '1–2 lb'}/minggu), '
                'pertimbangkan konsultasi ahli gizi.');
      } else {
        buf.write(' Laju ±${w(rate)}/minggu.');
      }
    }
  }
  if (goalKg != null) {
    final rem = goalKg - last;
    if (rem.abs() < 0.5) {
      buf.write(' Target ${w(goalKg)} tercapai — pertahankan!');
    } else if (rem > 0) {
      buf.write(' Kurang ${w(rem)} lagi ke target.');
    } else {
      buf.write(' ${w(rem.abs())} di bawah target.');
    }
  }
  return buf.toString();
}
