import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/streak.dart';
import '../state/app_state.dart';
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
        const RagaHeader(title: 'Streak'),
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
                '${streak.weeks} minggu',
                style: RagaType.hero(52, rc.onCard),
              ),
              const SizedBox(height: 6),
              Text(
                streak.thisWeekDone
                    ? 'Minggu ini sudah timbang ✓'
                    : 'Timbang minggu ini biar streak lanjut',
                textAlign: TextAlign.center,
                style: RagaType.body(rc.onCardMuted),
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
                '8 minggu terakhir',
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
                          ? 'Semua milestone tercapai!'
                          : 'Target berikutnya: $next minggu',
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
                  '${streak.weeksToMilestone} minggu lagi',
                  style: RagaType.body(rc.onCardMuted),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  'Konsisten banget — pertahankan!',
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
}
