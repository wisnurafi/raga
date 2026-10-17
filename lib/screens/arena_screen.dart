// Arena tab: the fun zone. Two inner tabs — the community
// leaderboard (login-gated, strictly opt-in) and Raga Wrapped
// (a weekly recap story, unlocked every Monday).

import 'dart:async';

import 'package:flutter/material.dart';
import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/streak.dart';
import '../core/wrapped.dart';
import '../data/cloud_sync.dart';
import '../models/leaderboard_entry.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import 'wrapped_story_screen.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  int _tab = 0; // 0 = leaderboard, 1 = wrapped
  int _metric = 0; // 0 = % lost, 1 = streak
  bool _busy = false;
  bool _optBusy = false;
  Future<List<LeaderboardEntry>>? _boardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loggedIn = AppState.of(context).isLoggedIn;
    if (!loggedIn) {
      _boardFuture = null;
    } else if (_boardFuture == null) {
      _refreshBoard();
    }
  }

  void _refreshBoard() {
    // Push pending weigh-ins first: the board is computed server-side,
    // so without this a fresh local log wouldn't show up in your row.
    setState(() {
      _boardFuture = () async {
        await CloudSync.syncPending(AppState.of(context).records);
        return CloudSync.getLeaderboard(
            _metric == 0 ? 'pct_loss' : 'streak');
      }();
    });
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s)));
  }

  // Arena-local sign-in: same flow as Profile, but a returning login
  // auto-merges instead of asking (the user came here to see data).
  Future<void> _signIn() async {
    final state = AppState.of(context);
    setState(() => _busy = true);
    final res = await state.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.cancelled) {
      _snack(tx(context, 'auth_sign_in_cancelled'));
      return;
    }
    if (res.notConfigured) {
      _snack(tx(context, 'auth_not_configured'));
      return;
    }
    if (res.failed) {
      _snack(tx(context, 'auth_sign_in_failed', {'e': res.detail}));
      return;
    }
    if (res.isFirstLogin) {
      _snack(res.migratedCount > 0
          ? tx(context, 'auth_migrated', {'n': res.migratedCount})
          : tx(context, 'auth_welcome',
              {'name': state.accountName ?? ''}));
      return;
    }
    final n = await state.mergeFromCloud();
    if (!mounted) return;
    _snack(n > 0
        ? tx(context, 'auth_merged', {'n': n})
        : n == 0
            ? tx(context, 'auth_merge_empty')
            : tx(context, 'auth_merge_failed'));
  }

  Future<void> _toggleOptIn(bool v) async {
    setState(() => _optBusy = true);
    final ok = await AppState.of(context).setLeaderboardOptIn(v);
    if (!mounted) return;
    setState(() => _optBusy = false);
    if (ok) _refreshBoard();
  }

  /// The user's own board value, for the "your rank" card.
  double? _myValue(AppState state) {
    if (_metric == 1) {
      return computeStreak(
              [for (final r in state.records) r.createdAt])
          .weeks
          .toDouble();
    }
    final weekStart = mondayOf(DateTime.now());
    final recs = state.records
        .where((r) => !r.createdAt.isBefore(weekStart))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (recs.length < 2) return null;
    final raw = (recs.first.weightKg - recs.last.weightKg) /
        recs.first.weightKg *
        100;
    // Same 3%/week anti-abuse cap as the server, so the "your rank"
    // card always matches the board.
    return raw > 3.0 ? 3.0 : raw;
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        RagaHeader(title: tx(context, 'arena_title')),
        const SizedBox(height: 18),
        if (!state.isLoggedIn)
          _loginCard(rc)
        else ...[
          RagaSegmented(
            options: [
              tx(context, 'arena_tab_board'),
              tx(context, 'arena_tab_wrapped'),
            ],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 18),
          if (_tab == 0) _boardTab(rc, state) else _wrappedTab(rc, state),
        ],
      ],
    );
  }

  Widget _loginCard(RagaColors rc) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 30),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 52, color: rc.chipActive),
          const SizedBox(height: 16),
          Text(tx(context, 'arena_login_title'),
              style: RagaType.title(rc.onCard),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(tx(context, 'arena_login_body'),
              style: RagaType.caption(rc.onCardMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          RagaButton(
            label: tx(context, 'arena_login_button'),
            onPressed: _busy ? null : _signIn,
          ),
        ],
      ),
    );
  }

  Widget _boardTab(RagaColors rc, AppState state) {
    final optedIn = state.leaderboardOptIn;
    return Column(
      children: [
        RagaSegmented(
          options: [
            tx(context, 'lb_tab_loss'),
            tx(context, 'lb_tab_streak'),
          ],
          selected: _metric,
          onChanged: (i) {
            setState(() => _metric = i);
            _refreshBoard();
          },
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(tx(context, 'lb_opt_in'),
                        style: RagaType.label(rc.onCard)),
                  ),
                  Switch(
                    value: optedIn,
                    onChanged: _optBusy ? null : _toggleOptIn,
                  ),
                ],
              ),
              Text(tx(context, 'lb_opt_in_body'),
                  style: RagaType.caption(rc.onCardMuted)),
              if (optedIn) ...[
                const SizedBox(height: 6),
                Text(tx(context, 'lb_opt_in_on'),
                    style: RagaType.caption(rc.chipActive)),
                if (_metric == 0 && _myValue(state) == null) ...[
                  const SizedBox(height: 6),
                  Text(tx(context, 'lb_min_records'),
                      style: RagaType.caption(rc.onCardMuted)),
                ],
              ] else if (_metric == 0) ...[
                const SizedBox(height: 6),
                Text(tx(context, 'lb_min_records'),
                    style: RagaType.caption(rc.onCardMuted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<LeaderboardEntry>>(
          future: _boardFuture,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting ||
                !snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(tx(context, 'lb_empty'),
                    style: RagaType.caption(rc.onCardMuted),
                    textAlign: TextAlign.center),
              );
            }
            return Column(
              children: [
                // The "you" card sits apart from the list, not glued to it.
                if (optedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _rankCard(rc, state, entries),
                  ),
                for (var i = 0; i < entries.length; i++)
                  _row(rc, state, i, entries[i]),
                if (_metric == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text(tx(context, 'lb_cap_note'),
                        style: RagaType.caption(rc.onCardMuted),
                        textAlign: TextAlign.center),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _rankCard(
      RagaColors rc, AppState state, List<LeaderboardEntry> entries) {
    // Prefer the board's own entry for "you": the card then always agrees
    // with the list below it, even when local records haven't synced yet.
    // Falls back to the local computation when you're not on the board.
    final meName = (state.accountName ?? '').trim().toLowerCase();
    LeaderboardEntry? boardMe;
    if (meName.isNotEmpty) {
      final matches = entries
          .where((e) => e.displayName.trim().toLowerCase() == meName)
          .toList();
      if (matches.isNotEmpty) {
        final local = _myValue(state);
        boardMe = matches.reduce((a, b) => local == null ||
                (a.value - local).abs() <= (b.value - local).abs()
            ? a
            : b);
      }
    }
    final double? mine;
    final int rank;
    if (boardMe != null) {
      mine = boardMe.value;
      rank = entries.indexOf(boardMe) + 1;
    } else {
      // Note: a fresh non-nullable local — Dart won't promote the
      // deferred-assignment `mine` inside the closure below.
      final fallback = _myValue(state);
      if (fallback == null) return const SizedBox.shrink();
      mine = fallback;
      rank = 1 + entries.where((e) => e.value > fallback).length;
    }
    final valueText = _metric == 0
        ? '${mine.toStringAsFixed(1)}%'
        : weeksN(state.locale, mine.round());
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text('#$rank',
              style: RagaType.title(rc.chipActive)
                  .copyWith(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(tx(context, 'lb_you'),
                style: RagaType.label(rc.onCard)),
          ),
          Text(valueText, style: RagaType.label(rc.onCard)),
        ],
      ),
    );
  }

  Widget _row(
      RagaColors rc, AppState state, int i, LeaderboardEntry e) {
    final valueText = _metric == 0
        ? '${e.value.toStringAsFixed(1)}%'
        : weeksN(state.locale, e.value.round());
    final name = e.displayName.isEmpty ? '–' : e.displayName;
    // Name-based: the old value-epsilon check failed whenever local
    // records hadn't synced to the board yet, showing you twice.
    final meName = (state.accountName ?? '').trim().toLowerCase();
    final isMe = state.leaderboardOptIn &&
        meName.isNotEmpty &&
        e.displayName.trim().toLowerCase() == meName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text('#${i + 1}',
                  style: RagaType.label(i < 3
                      ? rc.chipActive
                      : rc.onCardMuted)),
            ),
            _BoardAvatar(url: e.avatarUrl, name: name, rc: rc),
            const SizedBox(width: 12),
            Expanded(
              child: Text(isMe ? '${tx(context, 'lb_you')} ($name)' : name,
                  style: RagaType.label(rc.onCard),
                  overflow: TextOverflow.ellipsis),
            ),
            Text(valueText, style: RagaType.label(rc.onCard)),
          ],
        ),
      ),
    );
  }

  Widget _wrappedTab(RagaColors rc, AppState state) {
    final locale = state.locale;
    final monday = lastCompletedWeekMonday(DateTime.now());
    final sunday = monday.add(const Duration(days: 6));
    final data = computeWrapped(state.records, monday);
    final daysLeft = daysUntilNextWrapped(DateTime.now());
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined,
              size: 44, color: rc.chipActive),
          const SizedBox(height: 12),
          Text(tx(context, 'wrapped_title'),
              style: RagaType.title(rc.onCard)),
          const SizedBox(height: 4),
          Text(
              '${formatDateId(monday, locale: locale)} – ${formatDateId(sunday, locale: locale)}',
              style: RagaType.caption(rc.onCardMuted)),
          const SizedBox(height: 18),
          if (data != null) ...[
            RagaButton(
              label: tx(context, 'wrapped_view'),
              onPressed: () => _openWrapped(state, data),
            ),
          ] else ...[
            Text(tx(context, 'wrapped_empty_title'),
                style: RagaType.label(rc.onCard)),
            const SizedBox(height: 6),
            Text(tx(context, 'wrapped_empty_body'),
                style: RagaType.caption(rc.onCardMuted),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 14),
          Text(
              daysLeft == 1
                  ? tx(context, 'wrapped_unlocks_one')
                  : tx(context, 'wrapped_unlocks', {'d': daysLeft}),
              style: RagaType.caption(rc.onCardMuted)),
          if (state.devMode) ...[
            const SizedBox(height: 10),
            RagaTextButton(
              label: tx(context, 'wrapped_preview'),
              onPressed: () => _previewWrapped(state),
            ),
          ],
        ],
      ),
    );
  }

  /// Opens the real weekly Wrapped story. Firing the 'wrapped' quest
  /// trigger is safe: it only completes when the quest is in today's
  /// offer, and only once per day.
  void _openWrapped(AppState state, WrappedData data) {
    unawaited(state.completeDetakQuest('wrapped'));
    // Production Wrapped view: grants the weekly avatar XP. The dev
    // preview below deliberately never calls this.
    unawaited(state.onAvatarWrappedViewed());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WrappedStoryScreen(data: data),
      ),
    );
  }

  /// Dev-mode only: open the Wrapped story for the most recent week with
  /// real logs, so the story UI can be QA'd without waiting for Monday.
  /// Production behavior (last completed week) is untouched.
  void _previewWrapped(AppState state) {
    final weekMonday = previewWeekMonday(state.records, DateTime.now());
    final data = weekMonday == null
        ? null
        : computeWrapped(state.records, weekMonday);
    if (data == null) {
      _snack(tx(context, 'wrapped_preview_empty'));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WrappedStoryScreen(data: data),
      ),
    );
  }
}

class _BoardAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final RagaColors rc;

  const _BoardAvatar(
      {required this.url, required this.name, required this.rc});

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final initial = t.isNotEmpty ? t[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: rc.chipInactive,
      backgroundImage:
          url != null && url!.isNotEmpty ? NetworkImage(url!) : null,
      child: url != null && url!.isNotEmpty
          ? null
          : Text(initial, style: RagaType.label(rc.onCard)),
    );
  }
}
