// Detak's home: speech bubble, the companion itself, closeness,
// growth stages, daily quests, recent reactions, and the expression
// gallery. Mockups 1 + 3 + 4 combined into one scrollable page.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';
import '../detak/detak_assets.dart';
import '../detak/detak_engine.dart';
import '../detak/detak_state.dart';
import '../detak/detak_ui.dart';
import '../detak/detak_widget.dart';
import 'detak_style_screen.dart';

class DetakScreen extends StatefulWidget {
  const DetakScreen({super.key});

  @override
  State<DetakScreen> createState() => _DetakScreenState();
}

class _DetakScreenState extends State<DetakScreen> {
  String? _bubbleOverrideKey;
  Timer? _bubbleTimer;
  // Recent reactions: 5 latest by default, the rest behind "show all"
  // (same pattern as the history tab).
  bool _showAllReactions = false;

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _onDetakTap() {
    final state = AppState.of(context);
    final key = DetakEngine.tapMessage(state.detak);
    unawaited(state.saveDetak());
    setState(() => _bubbleOverrideKey = key);
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bubbleOverrideKey = null);
    });
  }

  String _bubbleText(BuildContext context, DetakState d) {
    if (_bubbleOverrideKey != null) return tx(context, _bubbleOverrideKey!);
    if (d.reactions.isNotEmpty) {
      return detakReactionText(context, d.reactions.first);
    }
    return tx(context, 'detak_msg_greet_0');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final d = state.detak;
    final rc = context.rc;
    final mood = d.reactions.isNotEmpty ? d.reactions.first.mood : DetakMood.halo;

    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
            children: [
              _header(context, state, rc),
              const SizedBox(height: 18),
              _heroCard(context, state, rc, d, mood),
              const SizedBox(height: 14),
              _closenessCard(context, rc, d),
              const SizedBox(height: 14),
              _growthCard(context, rc, d),
              const SizedBox(height: 20),
              Text(tx(context, 'detak_today'),
                  style: RagaType.section(rc.onBg)),
              const SizedBox(height: 10),
              _questRow(context, state, rc, d, 'log'),
              const SizedBox(height: 10),
              _questRow(context, state, rc, d, 'trend'),
              const SizedBox(height: 20),
              Text(tx(context, 'detak_recent'),
                  style: RagaType.section(rc.onBg)),
              const SizedBox(height: 10),
              ..._reactionRows(context, rc, d,
                  _showAllReactions ? d.reactions : d.reactions.take(5)),
              _reactionsToggle(context, d.reactions.length),
              const SizedBox(height: 20),
              Text(tx(context, 'detak_gallery_title'),
                  style: RagaType.section(rc.onBg)),
              const SizedBox(height: 2),
              Text(tx(context, 'detak_gallery_subtitle'),
                  style: RagaType.caption(rc.onBgMuted)),
              const SizedBox(height: 10),
              _gallery(context, rc),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(16),
                radius: 18,
                child: Text(
                  tx(context, 'detak_note'),
                  style: RagaType.caption(rc.onCardMuted),
                ),
              ),
              const SizedBox(height: 20),
              RagaButton(
                label: tx(context, 'detak_change_style'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DetakStyleScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppState state, RagaColors rc) {
    return Row(
      children: [
        CircleBtn(
          icon: Icons.chevron_left,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tx(context, 'detak_title'),
                  style: RagaType.title(rc.onBg), textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(tx(context, 'detak_subtitle'),
                  style: RagaType.label(rc.onBgMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        CircleBtn(
          icon: Icons.light_mode_outlined,
          onTap: () => state.setDarkMode(!state.darkMode),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context, AppState state, RagaColors rc,
      DetakState d, DetakMood mood) {
    return GlassCard(
      child: Column(
        children: [
          DetakBubble(text: _bubbleText(context, d)),
          const SizedBox(height: 6),
          SizedBox(
            width: 150,
            child: DetakWidget(
              mood: mood,
              color: d.color,
              stage: d.stage,
              accessory: d.accessory,
              energy: state.detakEnergy,
              calmMode: d.calmMode,
              interactive: true,
              onTap: _onDetakTap,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        d.name,
                        style: RagaType.title(rc.onCard)
                            .copyWith(fontSize: 22),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DetakStyleScreen()),
                      ),
                      child: Icon(Icons.edit,
                          size: 18, color: rc.onCardMuted),
                    ),
                  ],
                ),
              ),
              DetakMoodChip(mood: mood),
              const SizedBox(width: 8),
              DetakLevelChip(level: d.level),
            ],
          ),
        ],
      ),
    );
  }

  Widget _closenessCard(
      BuildContext context, RagaColors rc, DetakState d) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tx(context, 'detak_closeness'),
                  style: RagaType.cardTitle(rc.onCard)),
              const Spacer(),
              Text('Lv. ${d.level}', style: RagaType.label(rc.onCardMuted)),
            ],
          ),
          const SizedBox(height: 10),
          DetakProgressBar(progress: d.progress),
          const SizedBox(height: 10),
          Text(
            tx(context, 'detak_closeness_hint',
                {'n': '${d.xpRemaining}', 'm': '${d.level + 1}'}),
            style: RagaType.body(rc.onCardMuted),
          ),
        ],
      ),
    );
  }

  static const _stageRanges = {
    DetakStage.kuncup: 'Lv. 1–2',
    DetakStage.duaDaun: 'Lv. 3–4',
    DetakStage.rimbun: 'Lv. 5–7',
    DetakStage.berbunga: 'Lv. 8+',
  };

  Widget _growthCard(BuildContext context, RagaColors rc, DetakState d) {
    final nextStage = detakStageForLevel(d.level + 1);
    final hint = d.stage == DetakStage.berbunga
        ? tx(context, 'detak_growth_max',
            {'name': d.name, 'm': '${d.level}'})
        : tx(context, 'detak_growth_hint', {
            'n': '${d.xpRemaining}',
            'name': d.name,
            'stage': detakStageLabel(context, nextStage),
          });
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tx(context, 'detak_growth'),
                  style: RagaType.cardTitle(rc.onCard)),
              const Spacer(),
              Text('Lv. ${d.level}', style: RagaType.label(rc.onCardMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final s in DetakStage.values)
                Expanded(child: _stageMini(context, rc, d, s)),
            ],
          ),
          const SizedBox(height: 12),
          DetakProgressBar(progress: d.progress, height: 8),
          const SizedBox(height: 10),
          Text(hint, style: RagaType.body(rc.onCardMuted)),
        ],
      ),
    );
  }

  Widget _stageMini(
      BuildContext context, RagaColors rc, DetakState d, DetakStage s) {
    final active = s == d.stage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: rc.chipInactive.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? rc.chipActive : rc.cardBorder,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DetakWidget(
              mood: DetakMood.halo,
              color: DetakColor.lavender,
              stage: s,
              energy: 0.5,
              calmMode: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detakStageLabel(context, s),
            style: RagaType.caption(rc.onCard).copyWith(
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _stageRanges[s]!,
            style: RagaType.caption(rc.onCardMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _questRow(BuildContext context, AppState state, RagaColors rc,
      DetakState d, String quest) {
    final now = DateTime.now();
    final done = d.isQuestDone(now, quest);
    final label = tx(
        context, quest == 'log' ? 'detak_quest_log' : 'detak_quest_trend');
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 18,
      onTap: () {
        if (quest == 'log') {
          // Deep-link to the weigh-in flow on the Home tab.
          Navigator.pop(context);
          state.requestTab(0);
        } else {
          // Viewing the trend completes the quest.
          Navigator.pop(context);
          state.requestTab(1);
          unawaited(state.completeDetakTrendQuest());
        }
      },
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF6FCF97) : Colors.transparent,
              border: Border.all(
                color:
                    done ? const Color(0xFF6FCF97) : rc.cardBorder,
                width: 2,
              ),
            ),
            child: done
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: RagaType.body(rc.onCard)),
          ),
          Text(
            done
                ? (d.questTime(now, quest) ?? '')
                : tx(context, 'detak_quest_reward'),
            style: RagaType.caption(rc.onCardMuted),
          ),
        ],
      ),
    );
  }

  List<Widget> _reactionRows(
      BuildContext context, RagaColors rc, DetakState d,
      Iterable<DetakReaction> shown) {
    // The state keeps 20; the page shows the 5 latest by default.
    return [
      for (final r in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            radius: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: DetakWidget(
                    mood: r.mood,
                    color: d.color,
                    stage: d.stage,
                    accessory: d.accessory,
                    energy: 0.5,
                    calmMode: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detakMoodLabel(context, r.mood),
                          style: RagaType.label(rc.onCard)),
                      const SizedBox(height: 2),
                      Text(
                        detakReactionText(context, r),
                        style: RagaType.caption(rc.onCardMuted),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeLabel(context, r.ts),
                  style: RagaType.caption(rc.onCardMuted),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _reactionsToggle(BuildContext context, int total) {
    if (total <= 5) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Center(
        child: RagaTextButton(
          label: _showAllReactions
              ? tx(context, 'detak_show_less')
              : tx(context, 'detak_show_all', {'n': total}),
          onPressed: () => setState(() => _showAllReactions = !_showAllReactions),
        ),
      ),
    );
  }

  String _timeLabel(BuildContext context, DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(ts.year, ts.month, ts.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return tx(context, 'detak_recent_today');
    if (diff == 1) return tx(context, 'detak_recent_yesterday');
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  Widget _gallery(BuildContext context, RagaColors rc) {
    final moods = DetakMood.values;
    const descs = [
      'detak_expr_halo_d',
      'detak_expr_senang_d',
      'detak_expr_semangat_d',
      'detak_expr_ngantuk_d',
      'detak_expr_dukung_d',
      'detak_expr_bangga_d',
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        for (var i = 0; i < moods.length; i++)
          GlassCard(
            padding: const EdgeInsets.all(14),
            radius: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  child: DetakWidget(
                    mood: moods[i],
                    color: DetakColor.lavender,
                    stage: DetakStage.duaDaun,
                    energy: 0.5,
                    calmMode: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(detakMoodLabel(context, moods[i]),
                    style: RagaType.label(rc.onCard)),
                const SizedBox(height: 4),
                Text(
                  tx(context, descs[i]),
                  style: RagaType.caption(rc.onCardMuted),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
