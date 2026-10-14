import 'package:flutter/material.dart';
import '../core/bmi.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import 'result_screen.dart';

// The "Calculate BMI" screen from the mockup: profile chips, body-data
// sliders with a unit toggle, gender + age, and the big calculate button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _pid = '';
  double _h = 170;
  double _w = 65;
  bool _isMale = true;
  int _age = 21;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = AppState.of(context).activeProfile;
    if (p.id != _pid) {
      _pid = p.id;
      _h = p.heightCm;
      _w = p.weightKg;
      _isMale = p.isMale;
      _age = p.age;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final metric = state.metricUnits;

    final hDisp = metric ? _h : _h / 2.54;
    final wDisp = metric ? _w : _w * 2.20462;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        const RagaHeader(title: 'Calculate BMI'),
        const SizedBox(height: 18),
        _profileChips(state),
        const SizedBox(height: 18),
        _bodyDataCard(state, rc, metric, hDisp, wDisp),
        const SizedBox(height: 14),
        _genderAgeCard(state, rc),
        const SizedBox(height: 22),
        RagaButton(
          label: 'Calculate BMI',
          onPressed: () => _calculate(state),
        ),
      ],
    );
  }

  Widget _profileChips(AppState state) {
    final profiles = state.profiles;
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: profiles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == profiles.length) {
            return SelectChip(
              label: '+ Add',
              selected: false,
              onTap: () => _addProfileDialog(state),
            );
          }
          final pr = profiles[i];
          return SelectChip(
            label: pr.name,
            selected: pr.id == state.activeProfileId,
            showCheck: true,
            onTap: () => state.setActiveProfile(pr.id),
          );
        },
      ),
    );
  }

  Widget _bodyDataCard(AppState state, RagaColors rc, bool metric,
      double hDisp, double wDisp) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Body data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: rc.onCard,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 170,
                child: Segmented<String>(
                  height: 44,
                  options: const ['cm · kg', 'in · lb'],
                  value: metric ? 'cm · kg' : 'in · lb',
                  onChanged: (v) =>
                      state.setMetricUnits(v == 'cm · kg'),
                  labelOf: (s) => s,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MeasureSlider(
            label: 'Height',
            value: hDisp,
            unit: metric ? 'cm' : 'in',
            min: metric ? 130 : 51,
            max: metric ? 220 : 87,
            onChanged: (v) =>
                setState(() => _h = metric ? v : v * 2.54),
          ),
          const SizedBox(height: 6),
          MeasureSlider(
            label: 'Weight',
            value: wDisp,
            unit: metric ? 'kg' : 'lb',
            min: metric ? 30 : 66,
            max: metric ? 150 : 330,
            onChanged: (v) =>
                setState(() => _w = metric ? v : v / 2.20462),
          ),
        ],
      ),
    );
  }

  Widget _genderAgeCard(AppState state, RagaColors rc) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Segmented<String>(
              options: const ['Male', 'Female'],
              value: _isMale ? 'Male' : 'Female',
              onChanged: (v) {
                final male = v == 'Male';
                setState(() => _isMale = male);
                state.updateActiveProfile(
                    (p) => p.copyWith(isMale: male));
              },
              labelOf: (s) => s,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _ageDialog(state),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              child: Text(
                '$_age yrs',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: rc.onCard,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProfileDialog(AppState state) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New profile'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) {
      await state.addProfile(name);
    }
  }

  Future<void> _ageDialog(AppState state) async {
    var age = _age;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Age'),
        content: StatefulBuilder(
          builder: (ctx, setS) => StepperRow(
            value: Text(
              '$age',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
            ),
            onMinus: () => setS(() {
              if (age > 5) age--;
            }),
            onPlus: () => setS(() {
              if (age < 100) age++;
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, age),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _age = picked);
      await state.updateActiveProfile((p) => p.copyWith(age: picked));
    }
  }

  void _calculate(AppState state) {
    // Remember the latest body stats on the profile.
    state.updateActiveProfile(
      (p) => p.copyWith(heightCm: _h, weightKg: _w),
    );
    final bmi = calcBmi(weightKg: _w, heightCm: _h);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          bmi: bmi,
          heightCm: _h,
          weightKg: _w,
        ),
      ),
    );
  }
}
