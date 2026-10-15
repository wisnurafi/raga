import 'strings.dart';

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

  /// Localized label for UI chrome. The result screen's gauge legend
  /// keeps [label] (English, per the mockup) — everything else goes
  /// through here.
  String labelFor(String locale) => locale == 'en'
      ? label
      : switch (this) {
          BmiCategory.underweight => 'Kurus',
          BmiCategory.normal => 'Normal',
          BmiCategory.overweight => 'Gemuk',
          BmiCategory.obese => 'Obesitas',
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

const enShortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Monday-first short day names: Sen..Min.
const idShortDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Monday-first short day names, English.
const enShortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

List<String> shortDays(String locale) =>
    locale == 'en' ? enShortDays : idShortDays;

/// One-line reminder schedule summary, e.g.
/// "2× seminggu · Sen & Kam · 07.00" / "Setiap hari · 07.00" / "Mati".
String reminderSummary(List<int> days, int h, int m,
    {String locale = 'id'}) {
  if (days.isEmpty) return txl(locale, 'rem_off');
  final t =
      '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';
  final sorted = [...days]..sort();
  if (sorted.length == 7) {
    return txl(locale, 'rem_every_day', {'t': t});
  }
  final names = sorted.map((d) => shortDays(locale)[d - 1]).toList();
  final joined = names.length == 1
      ? names.first
      : names.length == 2
          ? '${names[0]} & ${names[1]}'
          : '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  return txl(locale, 'rem_per_week',
      {'n': names.length, 'days': joined, 't': t});
}

String formatDateId(DateTime d, {String locale = 'id'}) {
  final months = locale == 'en' ? enShortMonths : idShortMonths;
  return '${d.day} ${months[d.month - 1]}';
}

/// Human span between two dates, Indonesian:
/// "hari ini", "3 hari", "2 minggu", "6 bulan".
String idSpanLabel(DateTime a, DateTime b) => _spanLabel(a, b, locale: 'id');

/// English twin of [idSpanLabel]: "today", "3 days", "2 weeks", "6 months".
String enSpanLabel(DateTime a, DateTime b) => _spanLabel(a, b, locale: 'en');

String spanLabel(DateTime a, DateTime b, {String locale = 'id'}) =>
    _spanLabel(a, b, locale: locale);

String _spanLabel(DateTime a, DateTime b, {required String locale}) {
  final days = b.difference(a).inDays.abs();
  if (days < 1) return txl(locale, 'span_today');
  String plural(String key, int n) {
    // Indonesian has no plural; English needs "1 day" vs "3 days".
    if (locale == 'id') return txl(locale, key, {'n': n});
    final one = {
      'span_days': '1 day',
      'span_weeks': '1 week',
      'span_months': '1 month',
    }[key]!;
    return n == 1 ? one : txl(locale, key, {'n': n});
  }

  if (days < 14) return plural('span_days', days);
  if (days < 60) return plural('span_weeks', (days / 7).round());
  return plural('span_months', (days / 30).round());
}

/// One-or-two-sentence insight for the history analytics card.
///
/// [weightsKg] oldest-first, already filtered to the selected range;
/// [dates] the matching timestamps, oldest-first. [goalKg] the profile's
/// goal weight in kg, if set. Set [metric] false to render in lb.
/// [locale] picks the sentence language ('id' default keeps the pinned
/// unit-test output).
String buildWeightInsight(
  List<double> weightsKg,
  List<DateTime> dates, {
  double? goalKg,
  bool metric = true,
  String locale = 'id',
}) {
  assert(weightsKg.length == dates.length);
  String w(double kg) =>
      metric ? '${formatNum(kg)} kg' : '${(kg * kgToLb).round()} lb';
  if (weightsKg.length < 2) {
    return txl(locale, 'insight_empty');
  }
  final first = weightsKg.first;
  final last = weightsKg.last;
  final span = spanLabel(dates.first, dates.last, locale: locale);
  final d = last - first; // negative = lost weight
  final buf = StringBuffer();
  if (d.abs() < 0.05) {
    buf.write(txl(locale, 'insight_stable', {'w': w(last), 'span': span}));
  } else {
    buf.write(txl(locale, d < 0 ? 'insight_down' : 'insight_up',
        {'w': w(d.abs()), 'span': span}));
    final days = dates.last.difference(dates.first).inDays;
    if (days >= 7) {
      final rate = d.abs() / (days / 7);
      if (d < 0) {
        buf.write(rate <= 1.0
            ? txl(locale, 'insight_rate_ok', {'r': w(rate)})
            : txl(locale, 'insight_rate_fast', {
                'r': w(rate),
                'lim': metric ? '0,5–1 kg' : '1–2 lb'
              }));
      } else {
        buf.write(txl(locale, 'insight_rate', {'r': w(rate)}));
      }
    }
  }
  if (goalKg != null) {
    final rem = goalKg - last;
    if (rem.abs() < 0.5) {
      buf.write(txl(locale, 'insight_goal_done', {'w': w(goalKg)}));
    } else if (rem > 0) {
      buf.write(txl(locale, 'insight_goal_left', {'w': w(rem)}));
    } else {
      buf.write(txl(locale, 'insight_goal_over', {'w': w(rem.abs())}));
    }
  }
  return buf.toString();
}
