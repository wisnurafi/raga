import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/bmi.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/controls.dart';
import '../widgets/gauge.dart';
import '../widgets/glass.dart';

// The BMI result screen from the mockup: gauge with the big number inside
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

// Tips per category, exactly like the mockup: icon circle + title + desc.
const Map<BmiCategory, List<({String title, String desc, IconData icon})>>
    _tips = {
  BmiCategory.underweight: [
    (
      title: 'Eat more often',
      desc: 'Smaller portions, packed with nutrients.',
      icon: Icons.restaurant,
    ),
    (
      title: 'Snack smart',
      desc: 'Nuts, avocado, and milk are great picks.',
      icon: Icons.cookie,
    ),
    (
      title: "Don't skip breakfast",
      desc: "It's your morning fuel.",
      icon: Icons.free_breakfast,
    ),
  ],
  BmiCategory.normal: [
    (
      title: 'Stay active',
      desc: 'Walk 30 minutes, 5 days a week.',
      icon: Icons.bolt,
    ),
    (
      title: 'Drink enough',
      desc: 'About 2 liters of water a day.',
      icon: Icons.water_drop,
    ),
    (
      title: 'Sleep well',
      desc: '7–8 hours every night.',
      icon: Icons.bedtime,
    ),
  ],
  BmiCategory.overweight: [
    (
      title: 'Cut sugary drinks',
      desc: 'Swap them for water.',
      icon: Icons.no_drinks,
    ),
    (
      title: 'Walk daily',
      desc: 'A relaxed 30-minute walk every day.',
      icon: Icons.directions_walk,
    ),
    (
      title: 'Eat slowly',
      desc: "Stop when you're full.",
      icon: Icons.restaurant,
    ),
  ],
  BmiCategory.obese: [
    (
      title: 'Start small',
      desc: 'Small steps you can actually stick to.',
      icon: Icons.footprints,
    ),
    (
      title: 'Move more',
      desc: '15 minutes a day, then add more.',
      icon: Icons.directions_walk,
    ),
    (
      title: 'Talk to a pro',
      desc: 'Consider a nutritionist.',
      icon: Icons.medical_services,
    ),
  ],
};

class _ResultScreenState extends State<ResultScreen> {
  final _shot = ScreenshotController();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final bmi = widget.bmi;
    final cat = bmiCatOf(bmi);
    final coreCat = categoryOf(bmi);
    final name = state.activeProfile.name;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              _topRow(rc, name),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  children: [
                    SizedBox(
                      height: 232,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          ResultGauge(bmi: bmi),
                          Positioned(
                            top: 86,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                Text(
                                  formatNum(bmi),
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w800,
                                    color: rc.onCard,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'kg/m²',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: rc.onCardMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    CategoryBadge(cat: cat),
                    const SizedBox(height: 16),
                    GaugeLegend(active: cat),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Tips for you',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: rc.onBg,
                ),
              ),
              const SizedBox(height: 12),
              ..._tips[coreCat]!.map(
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
                            color: rc.chipInactive,
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: rc.onCard,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.desc,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: rc.onCardMuted,
                                  height: 1.4,
                                ),
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
                      label: 'Save to history',
                      onPressed: () => _save(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: RagaGhostButton(
                      label: _sharing ? 'Sharing…' : 'Share',
                      onPressed:
                          _sharing ? null : () => _share(bmi, cat),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // The share card lives off-screen; only the screenshot sees it.
          Positioned(
            left: -2000,
            top: 0,
            child: Opacity(
              opacity: 0,
              child: Screenshot(
                controller: _shot,
                child: _ShareCard(bmi: bmi, cat: cat),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topRow(RagaColors rc, String name) {
    return Row(
      children: [
        _CircleBtn(
          icon: Icons.chevron_left,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'BMI Result',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: rc.onBg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$name · ${formatDate(DateTime.now())}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: rc.onBgMuted,
                ),
              ),
            ],
          ),
        ),
        _CircleBtn(
          icon: Icons.ios_share,
          onTap: _sharing ? () {} : () => _share(widget.bmi, bmiCatOf(widget.bmi)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    await AppState.of(context).saveRecord(
      heightCm: widget.heightCm,
      weightKg: widget.weightKg,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to history')),
    );
    Navigator.pop(context);
  }

  Future<void> _share(double bmi, BmiCat cat) async {
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
            'My BMI is ${formatNum(bmi)} (${bmiCatLabel(cat)}) — calculated with Raga',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't create the image")),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rc.chipInactive,
          border: Border.all(color: rc.cardBorder, width: 1.2),
        ),
        child: Icon(icon, color: rc.onBg, size: 24),
      ),
    );
  }
}

// The card that gets shared: dark, self-contained, theme-independent.
class _ShareCard extends StatelessWidget {
  final double bmi;
  final BmiCat cat;

  const _ShareCard({required this.bmi, required this.cat});

  static const _catColors = <BmiCat, Color>{
    BmiCat.under: Color(0xFF60A5FA),
    BmiCat.normal: Color(0xFF34D399),
    BmiCat.over: Color(0xFFFBBF24),
    BmiCat.obese: Color(0xFFFB7185),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF453A8F), Color(0xFF241D52)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/raga-mark.png', width: 76, height: 76),
          const SizedBox(height: 18),
          Text(
            formatNum(bmi),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'kg/m²',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xA6FFFFFF),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bmiCatLabel(cat),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _catColors[cat],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Raga',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0x8CFFFFFF),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
