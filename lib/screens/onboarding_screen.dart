import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../data/reminder_service.dart';
import '../state/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/glass.dart';

// First-launch setup: name -> measurements -> goal. Creates the real
// profile, then hands off to the main app. Shown once; the flag lives
// in SharedPreferences (and survives restore via the backup blob).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;
  bool _saving = false;

  final _name = TextEditingController();
  final _height = TextEditingController(text: '170');
  final _weight = TextEditingController(text: '65');
  final _age = TextEditingController(text: '21');
  final _goal = TextEditingController();
  bool _isMale = true;
  bool _metric = true;
  bool _metricInit = false;
  bool _remindWeekly = false;
  String? _error;

  @override
  void dispose() {
    _pager.dispose();
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _age.dispose();
    _goal.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick up the global unit setting once; the local toggle owns it after.
    if (!_metricInit) {
      _metricInit = true;
      _metric = AppState.of(context).metricUnits;
      if (!_metric) {
        // Controllers start with metric defaults; rewrite them so the
        // numbers don't silently change meaning under an imperial user
        // (happens after clear-all-data, which keeps unit settings).
        _height.text = _fmtV(170 / 2.54);
        _weight.text = _fmtV(65 * 2.20462);
      }
    }
  }

  // Unit conversions. Controllers always hold DISPLAY units; metric is
  // the canonical unit everywhere else.
  double _hToMetric(double v) => _metric ? v : v * 2.54;
  double _wToMetric(double v) => _metric ? v : v / 2.20462;
  String _fmtV(double v) => v.toStringAsFixed(v >= 100 ? 0 : 1);

  void _setMetric(bool v) {
    if (v == _metric) return;
    // Rewrite the fields into the new units so the numbers keep meaning
    // the same thing instead of silently changing unit under the user.
    final h = _num(_height.text);
    final w = _num(_weight.text);
    final g = _num(_goal.text);
    setState(() => _metric = v);
    if (h != null) _height.text = _fmtV(v ? h * 2.54 : h / 2.54);
    if (w != null) _weight.text = _fmtV(v ? w / 2.20462 : w * 2.20462);
    if (g != null && _goal.text.trim().isNotEmpty) {
      _goal.text = _fmtV(v ? g / 2.20462 : g * 2.20462);
    }
    AppState.of(context).setMetricUnits(v);
  }

  bool _validPage() {
    setState(() => _error = null);
    if (_page == 0) {
      if (_name.text.trim().isEmpty) {
        setState(() => _error = 'Tell me your name first');
        return false;
      }
      return true;
    }
    if (_page == 1) {
      final hd = _num(_height.text);
      final wd = _num(_weight.text);
      final a = int.tryParse(_age.text.trim());
      final h = hd == null ? null : _hToMetric(hd);
      final w = wd == null ? null : _wToMetric(wd);
      if (h == null || h < 100 || h > 250) {
        setState(() => _error = _metric
            ? 'A sensible height: 100–250 cm'
            : 'A sensible height: 39–98 in');
        return false;
      }
      if (w == null || w < 20 || w > 500) {
        setState(() => _error = _metric
            ? 'A sensible weight: 20–500 kg'
            : 'A sensible weight: 44–1102 lb');
        return false;
      }
      if (a == null || a < 5 || a > 120) {
        setState(() => _error = 'A sensible age: 5–120 years');
        return false;
      }
      return true;
    }
    return true; // goal page: optional
  }

  void _next() {
    if (!_validPage()) return;
    if (_page < 2) {
      _pager.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Honor a typed goal; empty field == no goal.
      _finish(skipGoal: false);
    }
  }

  Future<void> _finish({required bool skipGoal}) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final state = AppState.of(context);
    final messenger = ScaffoldMessenger.of(context);

    double? goalKg;
    if (!skipGoal && _goal.text.trim().isNotEmpty) {
      final gd = _num(_goal.text);
      final gKg = gd == null ? null : _wToMetric(gd);
      if (gKg == null || gKg <= 20 || gKg >= 500) {
        setState(() => _error = _metric
            ? 'A sensible target: 20–500 kg'
            : 'A sensible target: 44–1102 lb');
        return;
      }
      goalKg = gKg;
    }

    final hd = _num(_height.text);
    final wd = _num(_weight.text);
    final age = int.tryParse(_age.text.trim());
    if (hd == null || wd == null || age == null) {
      // Can't happen: page 1 validates before you can get here. Defensive.
      setState(() => _error = 'Double-check your measurements');
      return;
    }

    setState(() => _saving = true);
    try {
      await state.completeOnboarding(
        name: _name.text.trim(),
        isMale: _isMale,
        age: age,
        heightCm: _hToMetric(hd),
        weightKg: _wToMetric(wd),
        goalKg: goalKg,
      );
      if (_remindWeekly) {
        await _enableReminder(state, messenger);
      }
      widget.onDone();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Same permission-first flow as the Profile screen: no permission, no
  // toggle flip, and an honest message about what happened.
  Future<void> _enableReminder(
      AppState state, ScaffoldMessengerState messenger) async {
    final ok = await ReminderService.requestPermission();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Turn on notifications in system settings first'),
        ),
      );
      return;
    }
    if (!await ReminderService.canScheduleExact()) {
      await ReminderService.requestExactAlarmsPermission();
    }
    await ReminderService.scheduleBestEffort(
      weekday: state.reminderWeekday,
      hour: state.reminderHour,
      minute: state.reminderMinute,
    );
    await state.setWeeklyReminder(true);
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              Image.asset(
                'assets/mark/raga-mark.png',
                width: 52,
                height: 52,
              ),
              const SizedBox(height: 14),
              _dots(rc),
              const SizedBox(height: 28),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) => PageView(
                    controller: _pager,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() {
                        _page = i;
                        _error = null;
                      });
                    },
                    children: [
                      _centeredPage(constraints, _namePage(rc)),
                      _centeredPage(constraints, _measurePage(rc)),
                      _centeredPage(constraints, _goalPage(rc)),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFF2555A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _pager.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: RagaButton(
                      label: _saving
                          ? 'Saving…'
                          : _page == 2
                              ? 'Start'
                              : 'Next',
                      onPressed: _saving ? () {} : _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dots(RagaColors rc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: active ? rc.primaryBtn : rc.panel,
          ),
        );
      }),
    );
  }

  // Centers short pages vertically so the screen never looks half-empty;
  // taller content still scrolls instead of clipping.
  Widget _centeredPage(BoxConstraints c, Widget content) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: c.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [content],
        ),
      ),
    );
  }

  Widget _title(String t, String sub, RagaColors rc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: rc.onImage,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          style: TextStyle(fontSize: 15, height: 1.5, color: rc.onImageMuted),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _field(RagaColors rc,
      {required TextEditingController ctl,
      required String label,
      required String suffix,
      TextInputType? keyboard}) {
    // Higher fill than the default glass: input text has to survive on
    // top of the artwork, whose brightness varies top to bottom.
    return GlassContainer(
      opacity: 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: rc.onCardMuted,
                  ),
                ),
                TextField(
                  controller: ctl,
                  keyboardType: keyboard ??
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: rc.onCard,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(bottom: 8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            suffix,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: rc.onCardMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _namePage(RagaColors rc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Hello! What\'s\nyour name?', 'This is what Raga will call you.', rc),
        GlassContainer(
          opacity: 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: rc.onCard,
            ),
            decoration: InputDecoration(
              hintText: 'Your name…',
              hintStyle: TextStyle(color: rc.onCardMuted),
              border: InputBorder.none,
              isDense: true,
            ),
            onSubmitted: (_) => _next(),
          ),
        ),
      ],
    );
  }

  Widget _measurePage(RagaColors rc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Your\nmeasurements?', 'To calculate your BMI and calorie needs.', rc),
        GlassContainer(
          opacity: 0.75,
          borderRadius: 999,
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _unitSeg(rc, 'cm · kg', true),
              const SizedBox(width: 6),
              _unitSeg(rc, 'in · lb', false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _field(rc,
            ctl: _height, label: 'Height', suffix: _metric ? 'cm' : 'in'),
        const SizedBox(height: 12),
        _field(rc,
            ctl: _weight, label: 'Weight', suffix: _metric ? 'kg' : 'lb'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                rc,
                ctl: _age,
                label: 'Age',
                suffix: 'yrs',
                keyboard: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassContainer(
                opacity: 0.75,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: rc.onCardMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _genderChip(rc, 'M', true),
                        const SizedBox(width: 8),
                        _genderChip(rc, 'F', false),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _genderChip(RagaColors rc, String label, bool male) {
    final active = _isMale == male;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isMale = male),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? rc.primaryBtn : rc.panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: active ? rc.onPrimaryBtn : rc.onCardMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _unitSeg(RagaColors rc, String label, bool metric) {
    final active = _metric == metric;
    return GestureDetector(
      onTap: () => _setMetric(metric),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? rc.primaryBtn : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: active ? rc.onPrimaryBtn : rc.onCardMuted,
          ),
        ),
      ),
    );
  }

  Widget _goalPage(RagaColors rc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Have a weight\ntarget?', 'Optional — you can set it later too.', rc),
        _field(rc,
            ctl: _goal,
            label: 'Target weight',
            suffix: _metric ? 'kg' : 'lb'),
        const SizedBox(height: 16),
        GlassContainer(
          opacity: 0.75,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: rc.primaryBtn.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: rc.primaryBtn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly reminder',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: rc.onCard,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A nudge to weigh in, Sundays at 9:00',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: rc.onCardMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _remindWeekly,
                onChanged: (v) => setState(() => _remindWeekly = v),
                activeColor: rc.primaryBtn,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _saving ? null : () => _finish(skipGoal: true),
            child: const Text('Skip for now'),
          ),
        ),
      ],
    );
  }
}
