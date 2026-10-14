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

    final hDisp = metric ? _h : _h / 2.54;
    final wDisp = metric ? _w : _w * 2.20462;

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
            min: metric ? 130 : 51,
            max: metric ? 220 : 87,
            onChanged: (v) =>
                setState(() => _h = metric ? v : v * 2.54),
          ),
          const SizedBox(height: 6),
          MeasureSlider(
            label: 'Berat badan',
            value: wDisp.toStringAsFixed(0),
            unit: metric ? 'kg' : 'lb',
            sliderValue: wDisp,
            min: metric ? 30 : 66,
            max: metric ? 150 : 330,
            onChanged: (v) =>
                setState(() => _w = metric ? v : v / 2.20462),
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
    final ctrl = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final rc = ctx.rc;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 24,
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profil baru',
                    style: RagaType.cardTitle(rc.onCard)),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: RagaType.body(rc.onCard),
                  decoration: InputDecoration(
                    hintText: 'Nama',
                    hintStyle:
                        RagaType.body(rc.onCardMuted),
                    filled: true,
                    fillColor: rc.chipInactive,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                          color: rc.chipBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                          color: rc.chipBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                          color: rc.chipActive, width: 2),
                    ),
                  ),
                  onSubmitted: (_) =>
                      Navigator.pop(ctx, ctrl.text.trim()),
                ),
                const SizedBox(height: 16),
                RagaButton(
                  label: 'Tambah',
                  onPressed: () =>
                      Navigator.pop(ctx, ctrl.text.trim()),
                ),
              ],
            ),
          ),
        );
      },
    );
    ctrl.dispose();
    // Empty name falls back to AppState.addProfile's default.
    if (name != null) {
      await state.addProfile(name);
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
