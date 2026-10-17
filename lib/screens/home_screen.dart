import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/tips.dart';
import '../state/app_state.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../detak/detak_assets.dart';
import '../detak/detak_widget.dart';
import 'detak_screen.dart';
import 'knowledge_hub_screen.dart';
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
  // True once a slider moved and the value isn't persisted to the profile
  // yet (persist happens on "Hitung BMI"). While dirty, external profile
  // changes must not clobber the in-progress input (see below).
  bool _dirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = AppState.of(context).activeProfile;
    if (p.id != _pid) {
      // Profile switch: always take the new profile's data, dropping any
      // un-persisted slider movement.
      _pid = p.id;
      _dirty = false;
      _h = p.heightCm;
      _w = p.weightKg;
      _isMale = p.isMale;
      _age = p.age;
    } else if (!_dirty &&
        (p.heightCm != _h ||
            p.weightKg != _w ||
            p.isMale != _isMale ||
            p.age != _age)) {
      // The stored profile changed underneath (e.g. edited from the Profil
      // tab): pick it up, otherwise Home would keep showing stale values
      // and the next "Hitung BMI" would silently overwrite the edit.
      // Skipped while _dirty so a slider drag in progress isn't wiped by a
      // Home-originated notify (e.g. tapping gender right after dragging).
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

    final hDisp = metric ? _h : _h * cmToIn;
    final wDisp = metric ? _w : _w * kgToLb;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        RagaHeader(title: tx(context, 'home_title')),
        const SizedBox(height: 14),
        _detakCard(context, state),
        const SizedBox(height: 18),
        _profileChips(state),
        const SizedBox(height: 18),
        _bodyDataCard(context, state, rc, metric, hDisp, wDisp),
        const SizedBox(height: 14),
        _genderAgeRow(context, state, rc),
        const SizedBox(height: 22),
        RagaButton(
          label: tx(context, 'home_calc'),
          onPressed: () => _calculate(state),
        ),
        const SizedBox(height: 18),
        _dailyTipCard(context, state, rc),
        const SizedBox(height: 18),
        _knowledgeCard(context, rc),
      ],
    );
  }

  // Knowledge Hub entry: a card under the daily tip. Tapping pushes the
  // hub screen — never a new bottom-nav tab (nav stays at 6 tabs).
  Widget _knowledgeCard(BuildContext context, RagaColors rc) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const KnowledgeHubScreen(),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined,
              size: 26, color: rc.chipActive),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx(context, 'kh_title'),
                  style: RagaType.cardTitle(rc.onCard),
                ),
                const SizedBox(height: 2),
                Text(
                  tx(context, 'kh_subtitle'),
                  style: RagaType.caption(rc.onCardMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: rc.onCardMuted),
        ],
      ),
    );
  }

  // Compact Detak entry: the companion + its current speech bubble.
  // Tapping opens an intro dialog first (never navigates directly).
  Widget _detakCard(BuildContext context, AppState state) {
    final d = state.detak;
    final mood =
        d.reactions.isNotEmpty ? d.reactions.first.mood : DetakMood.halo;
    final msg = d.reactions.isNotEmpty
        ? detakReactionText(context, d.reactions.first)
        : tx(context, 'detak_msg_greet_0');
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      onTap: () => _detakDialog(context, state),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: DetakWidget(
              mood: mood,
              color: d.color,
              stage: d.stage,
              accessory: d.accessory,
              energy: state.detakEnergy,
              calmMode: d.calmMode,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d.name,
                  style: RagaType.label(context.rc.onCard),
                ),
                const SizedBox(height: 4),
                Text(
                  msg,
                  style: RagaType.caption(context.rc.onCardMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.rc.onCardMuted),
        ],
      ),
    );
  }

  // Intro dialog: Detak, the contextual message, what the page is for,
  // then explicit open / close actions.
  void _detakDialog(BuildContext context, AppState state) {
    final d = state.detak;
    final mood =
        d.reactions.isNotEmpty ? d.reactions.first.mood : DetakMood.halo;
    final msg = d.reactions.isNotEmpty
        ? detakReactionText(context, d.reactions.first)
        : tx(context, 'detak_msg_greet_0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 130,
              child: DetakWidget(
                mood: mood,
                color: d.color,
                stage: d.stage,
                accessory: d.accessory,
                energy: state.detakEnergy,
                calmMode: d.calmMode,
                interactive: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(
                  color: context.rc.onCard,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              tx(ctx, 'detak_dialog_body'),
              style: TextStyle(color: context.rc.onCardMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            RagaButton(
              label: tx(ctx, 'detak_dialog_open'),
              height: 56,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DetakScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tx(ctx, 'close')),
            ),
          ],
        ),
      ),
    );
  }

  // "Tips hari ini": one tip from the pool of the BMI category the
  // current inputs fall into, rotated daily (different seed from the
  // Result screen so they rarely overlap).
  Widget _dailyTipCard(BuildContext context, AppState state, RagaColors rc) {
    final cat = categoryOf(calcBmi(weightKg: _w, heightCm: _h));
    final tip = dailyTip(cat, DateTime.now(), locale: state.locale);
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outlined, size: 22, color: rc.chipActive),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx(context, 'home_tip_today'),
                  style: RagaType.cardTitle(rc.onCard),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tip.title} · ${tip.desc}',
                  style: RagaType.body(rc.onCardMuted),
                ),
              ],
            ),
          ),
        ],
      ),
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
              label: tx(context, 'add'),
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
            onTap: () {
              // No-op on the active chip: without this, tapping it after
              // dragging a slider would reset the slider via the sync in
              // didChangeDependencies (same id, different values).
              if (pr.id != state.activeProfileId) {
                state.setActiveProfile(pr.id);
              }
            },
          );
        },
      ),
    );
  }

  Widget _bodyDataCard(BuildContext context, AppState state, RagaColors rc,
      bool metric, double hDisp, double wDisp) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tx(context, 'home_body_data'),
                  style: RagaType.cardTitle(rc.onCard)),
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
            label: tx(context, 'home_height'),
            value: hDisp.toStringAsFixed(0),
            unit: metric ? 'cm' : 'in',
            sliderValue: hDisp,
            min: metric ? heightRangeCm.min : heightRangeIn.min,
            max: metric ? heightRangeCm.max : heightRangeIn.max,
            onChanged: (v) {
              final nv = metric ? v : v / cmToIn;
              setState(() {
                _h = nv;
                _dirty = true;
              });
            },
          ),
          const SizedBox(height: 6),
          MeasureSlider(
            label: tx(context, 'home_weight'),
            value: wDisp.toStringAsFixed(0),
            unit: metric ? 'kg' : 'lb',
            sliderValue: wDisp,
            min: metric ? weightRangeKg.min : weightRangeLb.min,
            max: metric ? weightRangeKg.max : weightRangeLb.max,
            onChanged: (v) {
              final nv = metric ? v : v / kgToLb;
              setState(() {
                _w = nv;
                _dirty = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _genderAgeRow(BuildContext context, AppState state, RagaColors rc) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: RagaSegmented(
              options: [tx(context, 'male'), tx(context, 'female')],
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
          // Age is editable here too (typo fix, birthday) and writes
          // back to the profile, mirroring the gender segmented above.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ageStepBtn(rc, Icons.remove, () => _setAge(state, _age - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  tx(context, 'age_years', {'n': _age}),
                  style: RagaType.chip(rc.onCard),
                ),
              ),
              _ageStepBtn(rc, Icons.add, () => _setAge(state, _age + 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ageStepBtn(RagaColors rc, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rc.chipInactive,
          border: Border.all(color: rc.chipBorder),
        ),
        child: Icon(icon, size: 16, color: rc.onCard),
      ),
    );
  }

  void _setAge(AppState state, int v) {
    final nv = v.clamp(5, 120).toInt();
    setState(() => _age = nv);
    state.updateActiveProfile((p) => p.copyWith(age: nv));
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
    // Persisted now — external profile edits may sync again.
    // (Set synchronously: the notify inside updateActiveProfile only
    // schedules a build, which always runs after this line.)
    _dirty = false;
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
