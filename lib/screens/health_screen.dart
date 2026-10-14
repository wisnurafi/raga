import 'dart:math';
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
        _goalCard(context, rc, state),
        const SizedBox(height: 14),
        // Ideal weight
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

  // Weight goal card: target, progress bar, and an ETA from the trend.
  Widget _goalCard(BuildContext context, RagaColors rc, AppState state) {
    final p = state.activeProfile;
    final goal = state.goalFor(p.id);
    final current = p.weightKg;

    String? eta;
    double progress = 0;
    if (goal != null) {
      final history = state
          .recordsOf(p.id)
          .map((r) => (at: r.createdAt, weightKg: r.weightKg))
          .toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      final est = estimateGoal(history: history, targetKg: goal);
      final diff = (goal - current).abs();
      if (diff < 0.5) {
        eta = "You've hit your goal — nice work!";
        progress = 1;
      } else if (est.away) {
        eta = 'Trending the other way — small steps will turn it around.';
      } else if (est.days == null) {
        eta = "Log a few more weigh-ins and I'll estimate your timeline.";
      } else {
        eta = est.days! <= 1
            ? 'Almost there — keep going!'
            : 'About ${_prettyDays(est.days!)} at your current pace';
        // Progress measured from the furthest you've been, so the bar
        // reflects the actual journey, not a made-up starting point.
        final weights = history.map((h) => h.weightKg).toList();
        if (weights.isNotEmpty) {
          final start = goal < current
              ? weights.reduce(max) // losing: from the heaviest
              : weights.reduce(min); // gaining: from the lightest
          final total = (goal - start).abs();
          if (total > 0.01) {
            progress = (1 - diff / total).clamp(0.0, 1.0).toDouble();
          }
        }
      }
    }

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weight goal',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: rc.onCard,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _goalDialog(context, state, goal, current),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rc.mintSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    goal == null ? Icons.add : Icons.edit_outlined,
                    size: 18,
                    color: rc.mint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (goal == null)
            Text(
              'Set a target and Raga will track your progress.',
              style: TextStyle(fontSize: 14.5, height: 1.5, color: rc.onCardMuted),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatNum(current, 1)} kg',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: rc.onCard,
                    letterSpacing: -0.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 6),
                  child: Text(
                    '→ ${formatNum(goal, 1)} kg',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: rc.onCardMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: rc.panel,
                valueColor: AlwaysStoppedAnimation(rc.mint),
              ),
            ),
            if (eta != null) ...[
              const SizedBox(height: 10),
              Text(
                eta,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _prettyDays(int days) {
    if (days < 14) return '$days ${days == 1 ? 'day' : 'days'}';
    final weeks = (days / 7).round();
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
  }

  void _goalDialog(
      BuildContext context, AppState state, double? currentGoal, double current) {
    final ctl = TextEditingController(
        text: currentGoal != null ? formatNum(currentGoal, 1) : '');
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (_) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            backgroundColor: rc.card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Weight goal'),
            content: TextField(
              controller: ctl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Target weight in kg',
                errorText: error,
              ),
              onChanged: (_) {
                if (error != null) setLocal(() => error = null);
              },
            ),
            actions: [
              if (currentGoal != null)
                TextButton(
                  onPressed: () async {
                    await state.setGoalWeight(state.activeProfileId, null);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final v = _parseGoalInput(ctl.text);
                  if (v == null) {
                    setLocal(
                        () => error = 'Enter a number, e.g. 65 or 65,5');
                    return;
                  }
                  if (v <= 20 || v >= 500) {
                    setLocal(
                        () => error = 'Pick something between 20 and 500 kg');
                    return;
                  }
                  await state.setGoalWeight(state.activeProfileId, v);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Forgiving goal parsing: trims whitespace, drops a trailing "kg",
  // and accepts both 65.5 and 65,5. Returns null when it's not a number.
  double? _parseGoalInput(String raw) {
    var s = raw.trim().toLowerCase().replaceAll(RegExp(r'kgs?$'), '').trim();
    if (s.isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
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
