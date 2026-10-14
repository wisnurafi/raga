import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/streak.dart';
import '../state/app_state.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';

// Streak tab: weekly weigh-in consistency plus milestone badges.
// New visual language — the computeStreak logic is unchanged.
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
    final streak = computeStreak(
      state.recordsOf(p.id).map((r) => r.createdAt).toList(),
    );

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        const RagaHeader(title: 'Streak'),
        const SizedBox(height: 18),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rc.chipActive,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                streak.weeks == 0
                    ? 'No streak yet'
                    : '${streak.weeks}-week streak',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: rc.onCard,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Weigh in every week to keep it burning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: rc.onCardMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < streakMilestones.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _milestoneCard(streakMilestones[i], streak),
            ],
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Text(
                'This week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: rc.onCard,
                ),
              ),
              const Spacer(),
              if (streak.thisWeekDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: rc.badgeOk,
                  ),
                  child: Text(
                    'Logged ✓',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: rc.onBadgeOk,
                    ),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    'Not yet — weigh in to keep it alive.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: rc.onCardMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Frosted milestone tile: reached ones glow lavender, the next one
  // shows how far away it is.
  Widget _milestoneCard(int m, StreakInfo streak) {
    final rc = context.rc;
    final reached = streak.weeks >= m;
    final isNext = streak.nextMilestone == m;
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: reached
                  ? rc.chipActive.withValues(alpha: 0.25)
                  : rc.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: reached ? rc.chipActive : rc.cardBorder,
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$m',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: rc.onCard,
                  ),
                ),
                Text(
                  'wks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: rc.onCardMuted,
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${streak.weeksToMilestone} to go',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: rc.onCardMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
