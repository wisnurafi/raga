import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../state/app_state.dart';
import '../widgets/glass.dart';

// The "Health" screen: ideal weight, daily calories, and resting calories.
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
        '${p.name} · ${p.isMale ? 'Male' : 'Female'} · ${p.age} yrs · ${formatNum(p.heightCm, 0)} cm · ${formatNum(p.weightKg, 0)} kg';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: rc.onImage,
                letterSpacing: -0.8,
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8C98F),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 2,
                ),
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
        Text(meta, style: TextStyle(fontSize: 13.5, color: rc.onImageMuted)),
        const SizedBox(height: 18),
        // Berat badan ideal
        GlassContainer(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: rc.mintSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite_outline,
                      size: 19,
                      color: rc.mint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ideal weight',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: rc.onCardMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                    TextSpan(
                        text: '${formatNum(range.min)} – ${formatNum(range.max)} '),
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
        GlassContainer(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: rc.primaryBtn.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_fire_department_outlined,
                      size: 19,
                      color: rc.primaryBtn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Daily calorie needs',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: rc.onCardMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: rc.onCard,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: formatIntNum(tdeeVal.round())),
                    TextSpan(
                      text: ' kcal/day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: rc.onCardMuted,
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
                        gradient: active
                            ? LinearGradient(
                                colors: [
                                  rc.primaryBtn,
                                  const Color(0xFF9A8CF5)
                                ],
                              )
                            : null,
                        color: active
                            ? null
                            : rc.panel.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: active ? rc.onPrimaryBtn : rc.onBgMuted,
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
        GlassContainer(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          borderRadius: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resting calories',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: rc.onCard,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mifflin-St Jeor formula',
                    style: TextStyle(
                        fontSize: 12.5, color: rc.onCardMuted),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: rc.onCard,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: formatIntNum(bmr.round())),
                    TextSpan(
                      text: ' kcal',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: rc.onCardMuted),
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

// Ideal-weight range bar with a marker for the current weight.
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
    // Bar scale: min-15 .. max+15 so the marker never hugs the edge.
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
              formatNum(lo, 0),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A86AD),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'You: ${formatNum(current, 0)} kg',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A5680),
              ),
            ),
            Text(
              formatNum(hi, 0),
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
