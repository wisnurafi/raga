import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/bmi.dart';
import '../core/streak.dart';
import '../core/theme.dart';
import '../core/tips.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/gauge.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';

// The BMI result screen from the mockup: gauge with the big number under
// the arc, category badge, legend, tips, and save/share actions.
class ResultScreen extends StatefulWidget {
  final double bmi;
  final double heightCm;
  final double weightKg;

  const ResultScreen({
    super.key,
    required this.bmi,
    required this.heightCm,
    required this.weightKg,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _shot = ScreenshotController();
  bool _sharing = false;
  // Guards the save button: saveRecord awaits disk + network, so two fast
  // taps would create two BmiRecords before the pop.
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final metric = state.metricUnits;
    final bmi = widget.bmi;
    final cat = categoryOf(bmi);
    final name = state.activeProfile.name;

    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                children: [
                  _topRow(rc, name, cat),
                  const SizedBox(height: 18),
                  GlassCard(
                    child: Column(
                      children: [
                        BmiGauge(bmi: bmi),
                        Text(
                          formatNum(bmi),
                          style: RagaType.hero(60, rc.onCard),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kg/m²',
                          style: RagaType.label(rc.onCardMuted),
                        ),
                        const SizedBox(height: 12),
                        _categoryPill(rc, cat),
                        const SizedBox(height: 16),
                        _legend(rc),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _healthyRangeCard(state, rc, metric),
                  const SizedBox(height: 22),
                  Text(
                    'Tips untukmu',
                    style: RagaType.section(rc.onBg),
                  ),
                  const SizedBox(height: 12),
                  ..._resultTips(state, cat).map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color: rc.cardBorder,
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                t.icon,
                                color: rc.onCard,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: RagaType.chip(rc.onCard)
                                        .copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.desc,
                                    style: RagaType.caption(
                                        rc.onCardMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: RagaButton(
                          label: _saving
                              ? 'Menyimpan…'
                              : 'Simpan ke riwayat',
                          onPressed: _saving ? null : () => _save(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: RagaOutlineButton(
                          label: _sharing
                              ? 'Membagikan…'
                              : 'Bagikan',
                          onPressed: _sharing
                              ? null
                              : () => _share(bmi, cat),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // The share card lives off-screen; only the screenshot sees it.
              // NOTE: no Opacity wrapper here — RenderOpacity skips painting
              // entirely at opacity 0, leaving the Screenshot's
              // RepaintBoundary blank so capture() fails. Off-screen
              // positioning alone keeps it invisible while still painted.
              Positioned(
                left: -2000,
                top: 0,
                child: Screenshot(
                  controller: _shot,
                  child: _ShareCard(
                    bmi: bmi,
                    cat: cat,
                    name: name,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRow(RagaColors rc, String name, BmiCategory cat) {
    return Row(
      children: [
        CircleBtn(
          icon: Icons.chevron_left,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Hasil BMI',
                textAlign: TextAlign.center,
                style: RagaType.title(rc.onBg),
              ),
              const SizedBox(height: 2),
              Text(
                '$name · ${formatDateId(DateTime.now())}',
                textAlign: TextAlign.center,
                style: RagaType.label(rc.onBgMuted),
              ),
            ],
          ),
        ),
        CircleBtn(
          icon: Icons.ios_share,
          onTap: _sharing ? () {} : () => _share(widget.bmi, cat),
        ),
      ],
    );
  }

  Widget _categoryPill(RagaColors rc, BmiCategory cat) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: rc.badgeFor(cat),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cat.label,
        style: RagaType.chip(rc.onBadge),
      ),
    );
  }

  // The legend stays English — exactly like the mockup.
  Widget _legend(RagaColors rc) {
    const cats = [
      BmiCategory.underweight,
      BmiCategory.normal,
      BmiCategory.overweight,
      BmiCategory.obese
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < cats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rc.catColor(cats[i]),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            cats[i].label,
            style: RagaType.caption(rc.onCard)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  // Tips for this result: daily rotation plus the comeback/streak
  // rules (trend vs goal, 4+ week consistency).
  List<TipItem> _resultTips(AppState state, BmiCategory cat) {
    final pid = state.activeProfile.id;
    final recs = state.recordsOf(pid);
    final weightsKg = [for (final r in recs.reversed) r.weightKg];
    final streakWeeks =
        computeStreak([for (final r in recs) r.createdAt]).weeks;
    return tipsForResult(
      cat: cat,
      weightsKg: weightsKg,
      goalKg: state.goalFor(pid),
      streakWeeks: streakWeeks,
      day: DateTime.now(),
    );
  }

  // Healthy weight range for the user's height (BMI 18.5–24.99),
  // with a one-tap "Jadikan target" that fills the Goals section
  // on the Streak tab — no manual retyping.
  Widget _healthyRangeCard(AppState state, RagaColors rc, bool metric) {
    final range = idealWeightRange(widget.heightCm);
    final w = widget.weightKg;
    String fw(double kg) =>
        metric ? '${formatNum(kg)} kg' : '${(kg * kgToLb).round()} lb';

    // Snap the suggested target into the healthy range: the nearest
    // bound when outside, the current weight (maintain) when inside.
    final double target;
    final String status;
    if (w < range.min - 0.05) {
      target = range.min;
      status = 'Kamu ${fw(w)} — ${fw(range.min - w)} di bawah rentang sehat.';
    } else if (w > range.max + 0.05) {
      target = range.max;
      status = 'Kamu ${fw(w)} — ${fw(w - range.max)} di atas rentang sehat.';
    } else {
      target = w;
      status = 'Kamu ${fw(w)} — di dalam rentang sehat ✓';
    }

    final pid = state.activeProfile.id;
    final existing = state.goalFor(pid);
    final already = existing != null && (existing - target).abs() < 0.05;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rentang berat sehat',
            style: RagaType.cardTitle(rc.onCard),
          ),
          const SizedBox(height: 6),
          Text(
            'Untuk tinggi ${metric ? '${formatNum(widget.heightCm)} cm' : '${(widget.heightCm * cmToIn).round()} in'}: '
            '${fw(range.min)} – ${fw(range.max)}',
            style: RagaType.body(rc.onCard),
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: RagaType.caption(rc.onCardMuted),
          ),
          const SizedBox(height: 14),
          RagaButton(
            label: already ? 'Sudah jadi target' : 'Jadikan target',
            onPressed:
                already ? null : () => _setAsGoal(state, pid, target, metric),
          ),
        ],
      ),
    );
  }

  Future<void> _setAsGoal(
      AppState state, String pid, double targetKg, bool metric) async {
    await state.setGoalWeight(pid, targetKg);
    if (!mounted) return;
    final t = metric
        ? '${formatNum(targetKg)} kg'
        : '${(targetKg * kgToLb).round()} lb';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Target $t tersimpan — cek tab Streak.')),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppState.of(context).saveRecord(
        heightCm: widget.heightCm,
        weightKg: widget.weightKg,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Tersimpan di riwayat.')),
      );
      Navigator.pop(context);
    } finally {
      // After the pop this state is gone; the guard also protects the
      // (impossible but cheap) path where the save outlives the screen.
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share(double bmi, BmiCategory cat) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final bytes = await _shot.capture();
      if (bytes == null) throw StateError('screenshot failed');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/raga-bmi-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'BMI saya ${formatNum(bmi)} (${cat.label}) — dihitung dengan Raga',
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Gagal membuat gambar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

// The card that gets shared: the brand art as its backdrop, a mini gauge
// with the BMI number, the name, and the category — Manrope throughout.
class _ShareCard extends StatelessWidget {
  final double bmi;
  final BmiCategory cat;
  final String name;

  const _ShareCard({
    required this.bmi,
    required this.cat,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    const onWhite = Colors.white;
    const onWhiteMuted = Color(0xCCFFFFFF);
    const navy = Color(0xFF1D1B3A);

    TextStyle st(double size, FontWeight w, Color c) =>
        GoogleFonts.manrope(
          fontSize: size,
          fontWeight: w,
          color: c,
          height: 1.15,
        );

    return Container(
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: const Color(0xFF241D55),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/raga-bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(32, 32, 32, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        BmiGauge(bmi: bmi, height: 130),
                        Text(
                          formatNum(bmi),
                          style: st(44, FontWeight.w800, onWhite),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('kg/m²',
                      style: st(14, FontWeight.w600, onWhiteMuted)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      color: _catColor(cat),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      cat.label,
                      style: st(14, FontWeight.w700, navy),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(name,
                      style: st(17, FontWeight.w700, onWhite)),
                  const SizedBox(height: 10),
                  Text(
                    'RAGA',
                    style: st(13, FontWeight.w800, onWhiteMuted)
                        .copyWith(letterSpacing: 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _catColor(BmiCategory c) => switch (c) {
        BmiCategory.underweight => const Color(0xFF6FB1FF),
        BmiCategory.normal => const Color(0xFF5EE0A0),
        BmiCategory.overweight => const Color(0xFFF5B84B),
        BmiCategory.obese => const Color(0xFFFF7A6B),
      };
}
