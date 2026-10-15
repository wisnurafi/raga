import 'package:flutter/material.dart';
import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/streak.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';

// Streak tab: weekly weigh-in consistency plus the next milestone.
// The computeStreak logic is untouched — only the UI is new.
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  // Milestones already queued for markMilestoneSeen. The post-frame
  // callback runs after every build, so this keeps the call
  // once-per-milestone even across rebuilds.
  final Set<int> _marked = {};

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;
    final dates =
        state.recordsOf(p.id).map((r) => r.createdAt).toList();
    final streak = computeStreak(dates);
    final goal = state.goalFor(p.id);

    for (final m in streakMilestones) {
      if (streak.weeks >= m &&
          !state.milestonesSeen.contains(m) &&
          _marked.add(m)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          state.markMilestoneSeen(m);
        });
      }
    }

    final next = streak.nextMilestone;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        RagaHeader(title: tx(context, 'streak_title')),
        const SizedBox(height: 18),
        // Hero: big flame, week count, this-week status.
        GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9F43).withValues(alpha: 0.18),
                  border: Border.all(
                    color: const Color(0xFFFF9F43).withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 40,
                  color: Color(0xFFFF9F43),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                weeksN(state.locale, streak.weeks),
                style: RagaType.hero(52, rc.onCard),
              ),
              const SizedBox(height: 6),
              Text(
                streak.thisWeekDone
                    ? tx(context, 'streak_done')
                    : tx(context, 'streak_todo'),
                textAlign: TextAlign.center,
                style: RagaType.body(rc.onCardMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Goals: the weight target lives here (moved from Profil) —
        // this tab is the user's goals home.
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx(context, 'streak_goals'),
                style: RagaType.cardTitle(rc.onCard),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _goalDialog(context, state),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx(context, 'streak_goal_weight'),
                            style: RagaType.body(rc.onCard),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal == null
                                ? tx(context, 'streak_no_goal')
                                : _goalText(
                                    context, state.metricUnits, p.weightKg, goal),
                            style: RagaType.caption(rc.onCardMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: rc.onCardMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Last 8 weeks: a dot per week, lit when it has a weigh-in.
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx(context, 'streak_last8'),
                style: RagaType.cardTitle(rc.onCard),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 8; i++) ...[
                    if (i > 0) const Spacer(),
                    _weekDot(_weekHasData(dates, i)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Next milestone: target, progress bar, weeks to go.
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 22,
                    color: rc.chipActive,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      next == null
                          ? tx(context, 'streak_all_done')
                          : tx(context, 'streak_next',
                              {'w': weeksN(state.locale, next)}),
                      style: RagaType.cardTitle(rc.onCard),
                    ),
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: streak.weeks / next,
                    minHeight: 8,
                    backgroundColor: rc.sliderTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(rc.chipActive),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tx(context, 'streak_togo', {
                    'w': weeksN(state.locale, streak.weeksToMilestone)
                  }),
                  style: RagaType.body(rc.onCardMuted),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  tx(context, 'streak_keep'),
                  style: RagaType.body(rc.onCardMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Whether the week [weeksAgo] calendar weeks back (0 = this week,
  // Monday start) has at least one weigh-in.
  bool _weekHasData(Iterable<DateTime> dates, int weeksAgo) {
    final thisMonday = mondayOf(DateTime.now());
    final target = thisMonday.subtract(Duration(days: weeksAgo * 7));
    return dates.any((d) => mondayOf(d).isAtSameMomentAs(target));
  }

  Widget _weekDot(bool lit) {
    final rc = context.rc;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? rc.chipActive : rc.sliderTrack,
        border: Border.all(
          color: lit ? rc.chipActive : rc.cardBorder,
          width: 1.2,
        ),
      ),
      child: lit
          ? Icon(Icons.check, size: 14, color: rc.onChipActive)
          : null,
    );
  }

  String _fmtW(double kg, bool metric) => metric
      ? '${kg.toStringAsFixed(1)} kg'
      : '${(kg * kgToLb).round()} lb';

  String _goalText(
      BuildContext context, bool metric, double curKg, double goalKg) {
    final d = goalKg - curKg;
    final g = _fmtW(goalKg, metric);
    if (d.abs() < 0.5) return tx(context, 'streak_goal_maintain', {'g': g});
    return d < 0
        ? tx(context, 'streak_goal_down', {'g': g})
        : tx(context, 'streak_goal_up', {'g': g});
  }

  // Goal dialog: direction segmented + weight stepper + a live
  // "−3.0 kg lagi" line. (Moved here from the Profil tab.)
  void _goalDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    final p = state.activeProfile;
    final metric = state.metricUnits;
    final cur = p.weightKg;
    final unit = metric ? 'kg' : 'lb';
    final min = metric ? 30.0 : 66.0;
    final max = metric ? 150.0 : 330.0;
    final step = metric ? 0.5 : 1.0;
    double toDisplay(double kg) => metric ? kg : kg * kgToLb;
    double toKg(double v) => metric ? v : v / kgToLb;
    final dirs = [
      tx(context, 'goal_lose'),
      tx(context, 'goal_maintain'),
      tx(context, 'goal_gain'),
    ];
    String dirOf(double v) {
      final d = toKg(v) - cur;
      if (d.abs() < 0.5) return dirs[1];
      return d < 0 ? dirs[0] : dirs[2];
    }

    var value = toDisplay(state.goalFor(p.id) ?? cur).clamp(min, max);
    var dir = dirOf(value);
    final hasGoal = state.goalFor(p.id) != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) {
          final d = toKg(value) - cur;
          final diffText = d.abs() < 0.5
              ? tx(ctx2, 'streak_dialog_stay', {'w': _fmtW(cur, metric)})
              : tx(ctx2, 'streak_dialog_togo', {
                  's': d < 0 ? '−' : '+',
                  'w': _fmtW(d.abs(), metric),
                });
          return AlertDialog(
            title: Text(tx(ctx2, 'streak_goal_weight')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RagaSegmented(
                  options: dirs,
                  selected: dirs.indexOf(dir),
                  onChanged: (i) => setLocal(() {
                    dir = dirs[i];
                    final kgNow = toKg(value);
                    if (dir == dirs[1]) {
                      value = toDisplay(cur);
                    } else if (dir == dirs[0] && kgNow >= cur) {
                      value = toDisplay(cur - 3).clamp(min, max);
                    } else if (dir == dirs[2] && kgNow <= cur) {
                      value = toDisplay(cur + 3).clamp(min, max);
                    }
                  }),
                ),
                const SizedBox(height: 18),
                StepperRow(
                  value: value.toStringAsFixed(metric ? 1 : 0),
                  unit: unit,
                  valueSize: 48,
                  onMinus: () => setLocal(() {
                    value = (value - step).clamp(min, max);
                    dir = dirOf(value);
                  }),
                  onPlus: () => setLocal(() {
                    value = (value + step).clamp(min, max);
                    dir = dirOf(value);
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  diffText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: rc.onCardMuted,
                  ),
                ),
                const SizedBox(height: 18),
                RagaButton(
                  label: tx(ctx2, 'streak_save_goal'),
                  height: 56,
                  onPressed: () async {
                    await state.setGoalWeight(p.id, toKg(value));
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                ),
                if (hasGoal)
                  RagaTextButton(
                    label: tx(ctx2, 'streak_delete_goal'),
                    onPressed: () async {
                      await state.setGoalWeight(p.id, null);
                      if (ctx2.mounted) Navigator.pop(ctx2);
                    },
                  )
                else
                  RagaTextButton(
                    label: tx(ctx2, 'cancel'),
                    onPressed: () => Navigator.pop(ctx2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
