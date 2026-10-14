import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
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
      final h = _num(_height.text);
      final w = _num(_weight.text);
      final a = int.tryParse(_age.text.trim());
      if (h == null || h < 100 || h > 250) {
        setState(() => _error = 'A sensible height: 100–250 cm');
        return false;
      }
      if (w == null || w < 20 || w > 500) {
        setState(() => _error = 'A sensible weight: 20–500 kg');
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
    double? goal;
    if (!skipGoal && _goal.text.trim().isNotEmpty) {
      goal = _num(_goal.text);
      if (goal == null || goal <= 20 || goal >= 500) {
        setState(() => _error = 'A sensible target: 20–500 kg');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await AppState.of(context).completeOnboarding(
        name: _name.text.trim(),
        isMale: _isMale,
        age: int.parse(_age.text.trim()),
        heightCm: _num(_height.text)!,
        weightKg: _num(_weight.text)!,
        goalKg: goal,
      );
      widget.onDone();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              _dots(rc),
              const SizedBox(height: 28),
              Expanded(
                child: PageView(
                  controller: _pager,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() {
                      _page = i;
                      _error = null;
                    });
                  },
                  children: [
                    _namePage(rc),
                    _measurePage(rc),
                    _goalPage(rc),
                  ],
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
    return GlassContainer(
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Hello! What\'s\nyour name?', 'This is what Raga will call you.', rc),
          GlassContainer(
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
      ),
    );
  }

  Widget _measurePage(RagaColors rc) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Your\nmeasurements?', 'To calculate your BMI and calorie needs.', rc),
          _field(rc, ctl: _height, label: 'Height', suffix: 'cm'),
          const SizedBox(height: 12),
          _field(rc, ctl: _weight, label: 'Weight', suffix: 'kg'),
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
      ),
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

  Widget _goalPage(RagaColors rc) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Have a weight\ntarget?', 'Optional — you can set it later too.', rc),
          _field(rc, ctl: _goal, label: 'Target weight', suffix: 'kg'),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _saving ? null : () => _finish(skipGoal: true),
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}
