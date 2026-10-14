import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../state/app_state.dart';

/// Layar "Kesehatan": berat badan ideal, TDEE, dan BMR.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final p = state.activeProfile;

    final range = idealWeightRange(p.heightCm);
    final bmr = bmrMifflin(
      weightKg: p.weightKg,
      heightCm: p.heightCm,
      age: p.age,
      isMale: p.isMale,
    );
    final factor = activityFactors[state.activity] ?? 1.375;
    final tdeeVal = tdee(bmr, factor);

    final meta =
        '${p.name} · ${p.isMale ? 'Pria' : 'Wanita'} · ${p.age} th · ${formatId(p.heightCm, 0)} cm · ${formatId(p.weightKg, 0)} kg';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kesehatan',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: rc.onBg,
                letterSpacing: -0.8,
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE8C98F),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  p.initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B2F),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(meta, style: TextStyle(fontSize: 13.5, color: rc.onBgMuted)),
        const SizedBox(height: 18),
        // Berat badan ideal
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(
            color: rc.card,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Berat badan ideal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: rc.onCard,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: '${formatId(range.min)} – ${formatId(range.max)} '),
                    TextSpan(
                      text: 'kg',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: rc.onCardMuted,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _IdealBar(
                min: range.min,
                max: range.max,
                current: p.weightKg,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // TDEE
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: rc.cardDark.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kebutuhan kalori harian (TDEE)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: rc.onBgMuted,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: formatIntId(tdeeVal.round())),
                    const TextSpan(
                      text: ' kcal/hari',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB9B5E6),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activityFactors.keys.map((label) {
                  final active = label == state.activity;
                  return GestureDetector(
                    onTap: () => state.setActivity(label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? rc.primaryBtn
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: active ? rc.onPrimaryBtn : Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // BMR
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          decoration: BoxDecoration(
            color: rc.cardDark.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BMR (saat istirahat)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rumus Mifflin-St Jeor',
                    style: TextStyle(
                        fontSize: 12.5, color: rc.onBgMuted),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: formatIntId(bmr.round())),
                    const TextSpan(
                      text: ' kcal',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB9B5E6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bar rentang berat ideal dengan penanda posisi berat saat ini.
class _IdealBar extends StatelessWidget {
  final double min;
  final double max;
  final double current;

  const _IdealBar({
    required this.min,
    required this.max,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    // Skala bar: min-15 .. max+15 agar penanda tidak mentok di tepi.
    final lo = min - 15;
    final hi = max + 15;
    double posOf(double v) =>
        ((v - lo) / (hi - lo)).clamp(0.02, 0.98).toDouble();

    return Column(
      children: [
        SizedBox(
          height: 26,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final left = posOf(min) * w;
              final right = posOf(max) * w;
              final cur = posOf(current) * w;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4DEFB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Positioned(
                    left: left,
                    child: Container(
                      width: right - left,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3ED598),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: cur - 11,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B7CF0),
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatId(lo, 0),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A86AD),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'Kamu: ${formatId(current, 0)} kg',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A5680),
              ),
            ),
            Text(
              formatId(hi, 0),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A86AD),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
