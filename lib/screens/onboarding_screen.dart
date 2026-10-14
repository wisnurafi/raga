import 'package:flutter/material.dart';
import '../core/bmi.dart';
import '../core/theme.dart';
import '../data/reminder_service.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';

// First-launch setup from the mockup (p.7–10): 4 steps —
// 1. name/age/gender, 2. measurements, 3. optional weight goal,
// 4. optional weigh-in schedule. Metric is canonical internally;
// imperial is display-only. Finishes via [AppState.completeOnboarding]
// then [onDone].
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  int _step = 1;
  bool _saving = false;

  // Step 1.
  final _name = TextEditingController();
  int _age = 21;
  bool _isMale = true;

  // Step 2 — metric internally, always.
  bool _metric = true;
  bool _metricInit = false;
  double _heightCm = 170;
  double _weightKg = 65;

  // Step 3.
  String _direction = 'Lose';
  double _goalKg = 62;
  double _pace = 0.5;
  double? _pendingGoalKg;

  // Step 4 — 1=Mon..7=Sun, like AppState.reminderWeekdays.
  final Set<int> _days = {1, 4};
  int _hour = 7;
  int _minute = 0;
  bool _reminderOn = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_metricInit) {
      _metricInit = true;
      _metric = AppState.of(context).metricUnits;
    }
  }

  // Imperial display conversions (metric stays canonical).
  String get _wu => _metric ? 'kg' : 'lb';
  String get _hu => _metric ? 'cm' : 'in';
  double _dispH() => _metric ? _heightCm : _heightCm / 2.54;
  double _dispW(double kg) => _metric ? kg : kg * 2.20462;

  /// Whole numbers print clean ("62"), fractional keep one decimal.
  String _trimNum(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1);

  Future<void> _setUnits(String v) async {
    final m = v == 'cm · kg';
    if (m == _metric) return;
    setState(() => _metric = m);
    await AppState.of(context).setMetricUnits(m);
  }

  // ---------- step 1 ----------

  void _continueFromStep1() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = 2);
  }

  // ---------- step 3 ----------

  void _setDirection(String d) {
    setState(() {
      _direction = d;
      _goalKg = switch (d) {
        'Gain' => (_weightKg + 3).clamp(30.0, 150.0),
        'Maintain' => _weightKg,
        _ => (_weightKg - 3).clamp(30.0, 150.0),
      };
    });
  }

  double get _goalDiffKg => (_direction == 'Gain'
          ? _goalKg - _weightKg
          : _weightKg - _goalKg)
      .abs();

  String _goalHint() {
    final w = '${_trimNum(_dispW(_weightKg))} $_wu';
    if (_direction == 'Maintain') return 'Stay at $w';
    final sign = _direction == 'Gain' ? '+' : '−';
    return 'Now $w · $sign${formatNum(_goalDiffKg)} $_wu to go';
  }

  String _eta() {
    if (_direction == 'Maintain') return '—';
    final weeks = (_goalDiffKg / _pace).ceil();
    final date = DateTime.now().add(Duration(days: weeks * 7));
    return '±$weeks weeks · ${formatDate(date)}';
  }

  void _saveGoal() {
    _pendingGoalKg = _direction == 'Maintain' ? _weightKg : _goalKg;
    FocusScope.of(context).unfocus();
    setState(() => _step = 4);
  }

  void _skipGoal() {
    _pendingGoalKg = null;
    FocusScope.of(context).unfocus();
    setState(() => _step = 4);
  }

  // ---------- step 4 ----------

  String _timeColon() =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  String _summary() {
    final t =
        '${_hour.toString().padLeft(2, '0')}.${_minute.toString().padLeft(2, '0')}';
    final days = _days.toList()..sort();
    if (days.length == 7) return 'Every day · $t';
    final names = days.map((d) => _dayNames[d - 1]).toList();
    if (names.length == 1) return '1× a week · ${names.first} · $t';
    final joined = names.length == 2
        ? names.join(' & ')
        : '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
    return '${names.length}× a week · $joined · $t';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _finish({required bool arm}) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final state = AppState.of(context);
      if (arm && _reminderOn) {
        await _armReminder(state);
      } else {
        await state.setWeeklyReminder(false);
        await ReminderService.cancelAll();
      }
      await state.completeOnboarding(
        name: _name.text.trim(),
        isMale: _isMale,
        age: _age,
        heightCm: _heightCm,
        weightKg: _weightKg,
        goalKg: _pendingGoalKg,
      );
      widget.onDone();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Permission-first arming, exactly the spec sequence: request
  /// permission → setWeeklyReminder(true) → setReminderSchedule →
  /// scheduleBestEffortDays. Denied permission leaves the reminder off
  /// with an honest message instead of a dead toggle.
  Future<void> _armReminder(AppState state) async {
    final days = _days.toList();
    final ok = await ReminderService.requestPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on notifications in system settings first'),
          ),
        );
      }
      await state.setWeeklyReminder(false);
      await ReminderService.cancelAll();
      return;
    }
    await state.setWeeklyReminder(true);
    await state.setReminderSchedule(
        weekdays: days, hour: _hour, minute: _minute);
    await ReminderService.scheduleBestEffortDays(
        weekdays: days, hour: _hour, minute: _minute);
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          children: [
            OnboardHeader(
              step: _step,
              total: 4,
              onBack: _step > 1
                  ? () => setState(() => _step--)
                  : () {},
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: switch (_step) {
                  1 => _step1(),
                  2 => _step2(),
                  3 => _step3(),
                  _ => _step4(),
                },
              ),
            ),
            const SizedBox(height: 20),
            switch (_step) {
              1 => RagaButton(
                  label: 'Continue', onPressed: _continueFromStep1),
              2 => RagaButton(
                  label: 'Continue',
                  onPressed: () => setState(() => _step = 3)),
              3 => Column(
                  children: [
                    RagaButton(label: 'Save goal', onPressed: _saveGoal),
                    RagaTextLink(label: 'Skip for now', onTap: _skipGoal),
                  ],
                ),
              _ => Column(
                  children: [
                    RagaButton(
                      label: 'Finish',
                      onPressed:
                          _saving ? null : () => _finish(arm: true),
                    ),
                    RagaTextLink(
                      label: 'Skip for now',
                      onTap: _saving ? null : () => _finish(arm: false),
                    ),
                  ],
                ),
            },
          ],
        ),
      ),
    );
  }

  Widget _title(String t, String sub) {
    final rc = context.rc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: rc.onBg,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          style: TextStyle(
            fontSize: 15.5,
            height: 1.5,
            color: rc.onBgMuted,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _optionalBadge() {
    final rc = context.rc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rc.badgeOk, width: 1.5),
      ),
      child: Text(
        'OPTIONAL',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: rc.badgeOk,
        ),
      ),
    );
  }

  // ----- step 1 -----

  Widget _step1() {
    final rc = context.rc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          "Let's get acquainted",
          'So Raga can greet you and calculate accurately.',
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nickname',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: rc.onCard,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 4),
                ),
                onSubmitted: (_) => _continueFromStep1(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Row(
            children: [
              Text(
                'Age',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              Expanded(
                child: StepperRow(
                  value: Text(
                    '$_age',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: rc.onCard,
                    ),
                  ),
                  onMinus: () =>
                      setState(() => _age = (_age - 1).clamp(5, 120)),
                  onPlus: () =>
                      setState(() => _age = (_age + 1).clamp(5, 120)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: rc.onCardMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _genderCard(male: true),
            const SizedBox(width: 12),
            _genderCard(male: false),
          ],
        ),
      ],
    );
  }

  Widget _genderCard({required bool male}) {
    final rc = context.rc;
    final selected = _isMale == male;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border:
              selected ? Border.all(color: rc.chipActive, width: 2) : null,
        ),
        child: GlassCard(
          onTap: () => setState(() => _isMale = male),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rc.chipInactive,
                  border:
                      Border.all(color: rc.cardBorder, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    male ? '♂' : '♀',
                    style: TextStyle(fontSize: 28, color: rc.onCard),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                male ? 'Male' : 'Female',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: rc.onCard,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- step 2 -----

  Widget _step2() {
    final rc = context.rc;
    final bmi = calcBmi(weightKg: _weightKg, heightCm: _heightCm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'Your measurements',
          'Used to calculate your starting BMI.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 180,
              child: Segmented<String>(
                options: const ['cm · kg', 'in · lb'],
                value: _metric ? 'cm · kg' : 'in · lb',
                onChanged: _setUnits,
                labelOf: (s) => s,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: MeasureSlider(
            label: 'Height',
            value: _dispH(),
            unit: _hu,
            min: _metric ? 130 : 51,
            max: _metric ? 220 : 87,
            onChanged: (v) => setState(
                () => _heightCm = _metric ? v : v * 2.54),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: MeasureSlider(
            label: 'Weight',
            value: _dispW(_weightKg),
            unit: _wu,
            min: _metric ? 30 : 66,
            max: _metric ? 150 : 330,
            onChanged: (v) => setState(
                () => _weightKg = _metric ? v : v / 2.20462),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your starting BMI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              Row(
                children: [
                  Text(
                    formatNum(bmi),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: rc.onCard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CategoryBadge(cat: bmiCatOf(bmi)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----- step 3 -----

  Widget _step3() {
    final rc = context.rc;
    final targetKg = _direction == 'Maintain' ? _weightKg : _goalKg;
    final targetBmi = calcBmi(weightKg: targetKg, heightCm: _heightCm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _optionalBadge(),
        const SizedBox(height: 14),
        _title(
          'Have a weight goal?',
          'Set it now or later in Profile. You can skip this.',
        ),
        GlassCard(
          child: Column(
            children: [
              Segmented<String>(
                options: const ['Lose', 'Maintain', 'Gain'],
                value: _direction,
                onChanged: _setDirection,
                labelOf: (s) => s,
              ),
              const SizedBox(height: 18),
              StepperRow(
                value: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _trimNum(_dispW(_goalKg)),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: rc.onCard,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _wu,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: rc.onCardMuted,
                      ),
                    ),
                  ],
                ),
                onMinus: () => setState(
                    () => _goalKg = (_goalKg - 0.5).clamp(30.0, 150.0)),
                onPlus: () => setState(
                    () => _goalKg = (_goalKg + 0.5).clamp(30.0, 150.0)),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _goalHint(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: rc.onCardMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: rc.badgeOk,
                  ),
                  child: Text(
                    'Target BMI ${formatNum(targetBmi)} · '
                    '${bmiCatLabel(bmiCatOf(targetBmi))}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: rc.onBadgeOk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly pace',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [0.25, 0.5, 0.75].map((p) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: p == 0.75 ? 0 : 8),
                      child: SelectChip(
                        label: '$p kg',
                        selected: _pace == p,
                        onTap: () => setState(() => _pace = p),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              InfoRow(label: 'Estimated arrival', value: _eta()),
            ],
          ),
        ),
      ],
    );
  }

  // ----- step 4 -----

  Widget _step4() {
    final rc = context.rc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _optionalBadge(),
        const SizedBox(height: 14),
        _title(
          'Weigh-in schedule',
          'Pick days and a time — Raga will remind you. '
          'You can skip this.',
        ),
        Row(
          children: List.generate(7, (i) {
            final day = i + 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                child: DayPill(
                  label: _dayNames[i],
                  selected: _days.contains(day),
                  onTap: () => setState(() {
                    if (_days.contains(day)) {
                      if (_days.length > 1) _days.remove(day);
                    } else {
                      _days.add(day);
                    }
                  }),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reminder time',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickTime,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      _timeColon(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: rc.onCard,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _reminderOn,
                    onChanged: (v) =>
                        setState(() => _reminderOn = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(child: InfoRow(label: 'Summary', value: _summary())),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'You can change this anytime in Profile.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: rc.onCardMuted,
            ),
          ),
        ),
      ],
    );
  }
}
