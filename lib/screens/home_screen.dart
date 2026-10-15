import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import 'result_screen.dart';

// The "Hitung BMI" screen from the mockup: profile chips, body-data
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

    final hDisp = metric ? _h : _h / cmToIn;
    final wDisp = metric ? _w : _w * kgToLb;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        const RagaHeader(title: 'Hitung BMI'),
        const SizedBox(height: 18),
        _profileChips(state),
        const SizedBox(height: 18),
        _bodyDataCard(state, rc, metric, hDisp, wDisp),
        const SizedBox(height: 14),
        _genderAgeRow(state, rc),
        const SizedBox(height: 22),
        RagaButton(
          label: 'Hitung BMI',
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
            return ProfileChip(
              label: 'Tambah',
              selected: false,
              isAdd: true,
              onTap: () => _addProfileSheet(state),
            );
          }
          final pr = profiles[i];
          return ProfileChip(
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
              Text('Data tubuh', style: RagaType.cardTitle(rc.onCard)),
              const Spacer(),
              SizedBox(
                width: 170,
                child: RagaSegmented(
                  options: const ['cm · kg', 'in · lb'],
                  selected: metric ? 0 : 1,
                  onChanged: (i) => state.setMetricUnits(i == 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MeasureSlider(
            label: 'Tinggi badan',
            value: hDisp.toStringAsFixed(0),
            unit: metric ? 'cm' : 'in',
            sliderValue: hDisp,
            min: metric ? heightRangeCm.min : heightRangeIn.min,
            max: metric ? heightRangeCm.max : heightRangeIn.max,
            onChanged: (v) =>
                setState(() => _h = metric ? v : v / cmToIn),
          ),
          const SizedBox(height: 6),
          MeasureSlider(
            label: 'Berat badan',
            value: wDisp.toStringAsFixed(0),
            unit: metric ? 'kg' : 'lb',
            sliderValue: wDisp,
            min: metric ? weightRangeKg.min : weightRangeLb.min,
            max: metric ? weightRangeKg.max : weightRangeLb.max,
            onChanged: (v) =>
                setState(() => _w = metric ? v : v / kgToLb),
          ),
        ],
      ),
    );
  }

  Widget _genderAgeRow(AppState state, RagaColors rc) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: RagaSegmented(
              options: const ['Pria', 'Wanita'],
              selected: _isMale ? 0 : 1,
              onChanged: (i) {
                final male = i == 0;
                setState(() => _isMale = male);
                state.updateActiveProfile(
                    (p) => p.copyWith(isMale: male));
              },
            ),
          ),
          const SizedBox(width: 12),
          // Display only — age is edited in Profil.
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Text(
              '$_age tahun',
              style: RagaType.chip(rc.onCard),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProfileSheet(AppState state) async {
    final p = await showProfileSheet(context, metric: state.metricUnits);
    if (p != null) {
      await state.addProfile(p);
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
