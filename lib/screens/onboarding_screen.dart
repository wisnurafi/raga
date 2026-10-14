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

// First-launch setup from the mockup: 4 steps —
// 1. name/age/gender, 2. measurements, 3. optional weight goal,
// 4. optional weigh-in schedule. Metric is canonical internally;
// imperial is display-only. Finishes via [AppState.completeOnboarding]
// then [onDone]. Root is a transparent scaffold — main.dart already
// wraps this screen in RagaBg.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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

  // Step 3 — 0 = Turun, 1 = Jaga, 2 = Naik.
  int _direction = 0;
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

  Future<void> _setUnits(bool metric) async {
    if (metric == _metric) return;
    setState(() => _metric = metric);
    await AppState.of(context).setMetricUnits(metric);
  }

  // ---------- step 1 ----------

  void _continueFromStep1() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama panggilan dulu')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = 2);
  }

  // ---------- step 3 ----------

  void _setDirection(int i) {
    setState(() {
      _direction = i;
      _goalKg = switch (i) {
        2 => (_weightKg + 3).clamp(30.0, 150.0).toDouble(),
        1 => _weightKg,
        _ => (_weightKg - 3).clamp(30.0, 150.0).toDouble(),
      };
    });
  }

  double get _goalDiffKg =>
      (_direction == 2 ? _goalKg - _weightKg : _weightKg - _goalKg).abs();

  String _goalHint() {
    final w = '${_trimNum(_dispW(_weightKg))} $_wu';
    if (_direction == 1) return 'Tetap di $w';
    final sign = _direction == 2 ? '+' : '−';
    return 'Sekarang $w · selisih $sign${formatNum(_goalDiffKg)} $_wu';
  }

  String _eta() {
    if (_direction == 1) return '—';
    final weeks = (_goalDiffKg / _pace).ceil();
    final date = DateTime.now().add(Duration(days: weeks * 7));
    return '±$weeks minggu · ${formatDateId(date)}';
  }

  void _saveGoal() {
    _pendingGoalKg = _direction == 1 ? _weightKg : _goalKg;
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
    if (days.length == 7) return 'Setiap hari · $t';
    final names = days.map((d) => idShortDays[d - 1]).toList();
    if (names.length == 1) return '1× seminggu · ${names.first} · $t';
    final joined = names.length == 2
        ? names.join(' & ')
        : '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
    return '${names.length}× seminggu · $joined · $t';
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

  /// Permission-first arming: request permission →
  /// setWeeklyReminder(true) → setReminderSchedule →
  /// scheduleBestEffortDays. Denied permission leaves the reminder off
  /// with an honest message instead of a dead toggle.
  Future<void> _armReminder(AppState state) async {
    final days = _days.toList();
    final ok = await ReminderService.requestPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Nyalakan notifikasi di pengaturan sistem dulu'),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            children: [
              OnboardingTopBar(
                step: _step,
                onBack:
                    _step > 1 ? () => setState(() => _step--) : () {},
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
                    label: 'Lanjut', onPressed: _continueFromStep1),
                2 => RagaButton(
                    label: 'Lanjut',
                    onPressed: () => setState(() => _step = 3)),
                3 => Column(
                    children: [
                      RagaButton(
                          label: 'Simpan target', onPressed: _saveGoal),
                      RagaTextButton(
                          label: 'Lewati dulu', onPressed: _skipGoal),
                    ],
                  ),
                _ => Column(
                    children: [
                      RagaButton(
                        label: 'Selesai',
                        onPressed:
                            _saving ? null : () => _finish(arm: true),
                      ),
                      RagaTextButton(
                        label: 'Lewati dulu',
                        onPressed:
                            _saving ? null : () => _finish(arm: false),
                      ),
                    ],
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String t, String sub) {
    final rc = context.rc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: RagaType.bigTitle(rc.onBg)),
        const SizedBox(height: 8),
        Text(sub, style: RagaType.body(rc.onBgMuted)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _optionalBadge() {
    final rc = context.rc;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rc.success, width: 1.5),
      ),
      child: Text('OPSIONAL', style: RagaType.badge(rc.success)),
    );
  }

  /// Green category pill ("Normal"), dark label — like the mockup.
  Widget _categoryPill(double bmi) {
    final rc = context.rc;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: rc.badgeOk,
      ),
      child: Text(
        bmiCatLabel(bmiCatOf(bmi)),
        style: RagaType.chip(rc.onBadgeOk).copyWith(fontSize: 14),
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
          'Kenalan dulu, yuk',
          'Biar Raga bisa menyapamu dan menghitung dengan tepat.',
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama panggilan',
                  style: RagaType.label(rc.onCardMuted)),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                style: RagaType.hero(26, rc.onCard),
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
              Text('Umur', style: RagaType.cardTitle(rc.onCardMuted)),
              Expanded(
                child: StepperRow(
                  value: '$_age',
                  onMinus: () => setState(
                      () => _age = (_age - 1).clamp(5, 120).toInt()),
                  onPlus: () => setState(
                      () => _age = (_age + 1).clamp(5, 120).toInt()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Jenis kelamin',
            style: RagaType.label(rc.onBgMuted)),
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
      child: GestureDetector(
        onTap: () => setState(() => _isMale = male),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: selected ? rc.chipActive : rc.chipInactive,
            border: Border.all(
              color: selected ? rc.chipActive : rc.chipBorder,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rc.card,
                  border:
                      Border.all(color: rc.cardBorder, width: 1.2),
                ),
                child: Icon(
                  male ? Icons.male : Icons.female,
                  size: 30,
                  color: selected
                      ? rc.onChipActive
                      : rc.onChipInactive,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                male ? 'Pria' : 'Wanita',
                style: RagaType.chip(
                  selected ? rc.onChipActive : rc.onChipInactive,
                ).copyWith(fontSize: 16),
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
          'Ukuran tubuhmu',
          'Dipakai untuk menghitung BMI awalmu.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 180,
              child: RagaSegmented(
                options: const ['cm · kg', 'in · lb'],
                selected: _metric ? 0 : 1,
                onChanged: (i) => _setUnits(i == 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: MeasureSlider(
            label: 'Tinggi badan',
            value: _trimNum(_dispH()),
            unit: _hu,
            sliderValue: _dispH(),
            min: _metric ? 130 : 51,
            max: _metric ? 220 : 87,
            onChanged: (v) => setState(
                () => _heightCm = _metric ? v : v * 2.54),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: MeasureSlider(
            label: 'Berat badan',
            value: _trimNum(_dispW(_weightKg)),
            unit: _wu,
            sliderValue: _dispW(_weightKg),
            min: _metric ? 30 : 66,
            max: _metric ? 150 : 330,
            onChanged: (v) => setState(
                () => _weightKg = _metric ? v : v / 2.20462),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Row(
            children: [
              Text('BMI awalmu',
                  style: RagaType.cardTitle(rc.onCard)),
              const Spacer(),
              Text(formatNum(bmi),
                  style: RagaType.hero(28, rc.onCard)),
              const SizedBox(width: 10),
              _categoryPill(bmi),
            ],
          ),
        ),
      ],
    );
  }

  // ----- step 3 -----

  Widget _step3() {
    final rc = context.rc;
    final targetKg = _direction == 1 ? _weightKg : _goalKg;
    final targetBmi = calcBmi(weightKg: targetKg, heightCm: _heightCm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _optionalBadge(),
        const SizedBox(height: 14),
        _title(
          'Punya target berat?',
          'Atur sekarang atau nanti di Profil. Boleh dilewati.',
        ),
        GlassCard(
          child: Column(
            children: [
              RagaSegmented(
                options: const ['Turun', 'Jaga', 'Naik'],
                selected: _direction,
                onChanged: _setDirection,
              ),
              const SizedBox(height: 8),
              StepperRow(
                value: _trimNum(_dispW(_goalKg)),
                unit: _wu,
                valueSize: 56,
                onMinus: () => setState(() => _goalKg =
                    (_goalKg - 0.5).clamp(30.0, 150.0).toDouble()),
                onPlus: () => setState(() => _goalKg =
                    (_goalKg + 0.5).clamp(30.0, 150.0).toDouble()),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _goalHint(),
                  textAlign: TextAlign.center,
                  style: RagaType.body(rc.onCardMuted),
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
                    'BMI target ${formatNum(targetBmi)} · '
                    '${bmiCatLabel(bmiCatOf(targetBmi))}',
                    style: RagaType.chip(rc.onBadgeOk)
                        .copyWith(fontSize: 15),
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
              Text('Laju per minggu',
                  style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 12),
              Row(
                children: [0.25, 0.5, 0.75].map((p) {
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: p == 0.75 ? 0 : 8),
                      child: PaceChip(
                        label: '$p kg',
                        selected: _pace == p,
                        onTap: () => setState(() => _pace = p),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Perkiraan tercapai',
                      style: RagaType.body(rc.onCardMuted)),
                  Text(_eta(), style: RagaType.chip(rc.onCard)),
                ],
              ),
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
          'Jadwal menimbang',
          'Pilih hari dan jam, Raga akan mengingatkanmu. '
          'Boleh dilewati.',
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: DayChip(
                    label: idShortDays[i],
                    selected: _days.contains(i + 1),
                    onTap: () => setState(() {
                      final day = i + 1;
                      if (_days.contains(day)) {
                        if (_days.length > 1) _days.remove(day);
                      } else {
                        _days.add(day);
                      }
                    }),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jam pengingat',
                  style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickTime,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      _timeColon(),
                      style: RagaType.hero(48, rc.onCard),
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
        GlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ringkasan',
                  style: RagaType.cardTitle(rc.onCard)),
              Text(_summary(),
                  style: RagaType.chip(rc.onCardMuted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Bisa diubah kapan saja di Profil.',
            style: RagaType.caption(rc.onBgMuted),
          ),
        ),
      ],
    );
  }
}
