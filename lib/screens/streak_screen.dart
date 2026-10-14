import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/streak.dart';
import '../state/app_state.dart';
import '../widgets/glass.dart';

// Dedicated streak page: weekly weigh-in consistency, milestone badges,
// and room to grow (freeze weeks, history heatmap, ...).
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  static const _flame = Color(0xFFFF9F43);

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;
    final streak = computeStreak(
      state.recordsOf(p.id).map((r) => r.createdAt).toList(),
    );

    // A newly hit milestone pops a celebration exactly once
    // (tracked in milestonesSeen, which also survives backup/restore).
    int? hit;
    for (final m in streakMilestones) {
      if (streak.weeks >= m && !state.milestonesSeen.contains(m)) {
        hit = m;
        break;
      }
    }
    final celebrate = hit;
    if (celebrate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        state.markMilestoneSeen(celebrate);
        _milestoneDialog(context, celebrate);
      });
    }

    final status = streak.weeks == 0
        ? 'Log a weigh-in to start your streak.'
        : streak.thisWeekDone
            ? "This week's weigh-in is in — streak safe."
            : 'Weigh in this week to keep the streak alive.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Text(
          'Streak',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: rc.onImage,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Consistency beats intensity.',
          style: TextStyle(fontSize: 13.5, color: rc.onImageMuted),
        ),
        const SizedBox(height: 18),
        _heroCard(rc, streak, status),
        const SizedBox(height: 14),
        _badgesCard(rc, streak),
        const SizedBox(height: 14),
        _howItWorksCard(rc),
      ],
    );
  }

  Widget _heroCard(RagaColors rc, StreakInfo streak, String status) {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _flame.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_fire_department_outlined,
                  size: 24,
                  color: _flame,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weigh-in streak',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: rc.onCardMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: rc.mint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        streak.thisWeekDone
                            ? "This week: weighed in"
                            : 'This week: not yet',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: rc.onCardMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${streak.weeks}',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: rc.onCard,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text(
                  streak.weeks == 1 ? 'week' : 'weeks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: rc.onCardMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            status,
            style: TextStyle(fontSize: 13.5, color: rc.onCardMuted),
          ),
          if (streak.nextMilestone != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next badge: ${streak.nextMilestone} weeks',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: rc.onCardMuted,
                  ),
                ),
                Text(
                  '${streak.weeksToMilestone} to go',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: rc.mint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (streak.weeks / streak.nextMilestone!).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: rc.panel,
                valueColor: const AlwaysStoppedAnimation(_flame),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badgesCard(RagaColors rc, StreakInfo streak) {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Milestones',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: rc.onCardMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in streakMilestones) _badge(rc, m, streak.weeks >= m),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(RagaColors rc, int milestone, bool earned) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned
                ? _flame.withValues(alpha: 0.16)
                : rc.panel.withValues(alpha: 0.5),
            border: Border.all(
              color: earned
                  ? _flame.withValues(alpha: 0.6)
                  : rc.onCardMuted.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Icon(
            earned
                ? Icons.local_fire_department
                : Icons.local_fire_department_outlined,
            size: 24,
            color: earned ? _flame : rc.onCardMuted.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$milestone w',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: earned ? rc.onCard : rc.onCardMuted.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _howItWorksCard(RagaColors rc) {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: rc.onCardMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A week counts when you log at least one weigh-in, Monday to Sunday. '
            'Miss a full week and the streak resets — but every Monday is a fresh start.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: rc.onCardMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _milestoneDialog(BuildContext context, int weeks) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: rc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Streak milestone! 🔥'),
        content: Text(
          '$weeks weeks of consistent weigh-ins. That kind of discipline is what moves the number.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep going'),
          ),
        ],
      ),
    );
  }
}
