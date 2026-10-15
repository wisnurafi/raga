import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../data/cloud_sync.dart';
import '../data/reminder_service.dart';
import '../widgets/glass.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/headers.dart';

// Profile tab: identity, profiles, reminder, units, appearance,
// cloud backup, developer tools, and the danger zone.
// (The weight target lives on the Streak tab as "Goals".)
// New visual language — every feature from the old screen is ported.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String _dayName(BuildContext context, int d) =>
      shortDays(AppState.of(context).locale)[d - 1];
  static String _hdot(int h, int m) =>
      '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        RagaHeader(title: tx(context, 'profile_title')),
        const SizedBox(height: 18),
        // Active profile identity card.
        GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rc.avatarBg,
                ),
                child: Center(
                  child: Text(
                    p.initial,
                    style: RagaType.hero(32, rc.avatarFg),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final updated = await showProfileSheet(
                    context,
                    existing: p,
                    metric: state.metricUnits,
                  );
                  if (updated != null) {
                    await state.updateActiveProfile((_) => updated);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: RagaType.title(rc.onCard),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: rc.onCardMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profileLine(context, state, p),
                style: RagaType.body(rc.onCardMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, tx(context, 'profile_title')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final prof in state.profiles) ...[
                GestureDetector(
                  onLongPress: () =>
                      _confirmDeleteProfile(context, state, prof),
                  child: ProfileChip(
                    label: prof.name,
                    selected: prof.id == state.activeProfileId,
                    showCheck: true,
                    onTap: () async {
                      if (prof.id != state.activeProfileId) {
                        await state.setActiveProfile(prof.id);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              ProfileChip(
                label: tx(context, 'add'),
                isAdd: true,
                selected: false,
                onTap: () => _addProfileSheet(context, state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tx(context, 'profile_longpress_hint'),
          style: RagaType.caption(rc.onCardMuted),
        ),
        const SizedBox(height: 18),
        _label(context, tx(context, 'profile_settings')),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx(context, 'profile_units'),
                  style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 10),
              RagaSegmented(
                options: const ['cm · kg', 'in · lb'],
                selected: state.metricUnits ? 0 : 1,
                onChanged: (i) => state.setMetricUnits(i == 0),
              ),
              _divider(context),
              Text(tx(context, 'profile_theme'),
                  style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 10),
              RagaSegmented(
                options: [
                  tx(context, 'theme_dark'),
                  tx(context, 'theme_light')
                ],
                selected: state.darkMode ? 0 : 1,
                onChanged: (i) => state.setDarkMode(i == 0),
              ),
              _divider(context),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx(context, 'profile_reminder'),
                          style: RagaType.cardTitle(rc.onCard),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.weeklyReminder
                              ? tx(context, 'profile_reminder_on')
                              : tx(context, 'profile_reminder_off'),
                          style: RagaType.caption(rc.onCardMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.weeklyReminder,
                    onChanged: (v) => _toggleReminder(context, v),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _reminderDialog(context, state),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: rc.chipInactive,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: rc.cardBorder, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 20, color: rc.onCardMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.weeklyReminder
                              ? reminderSummary(
                                  state.reminderWeekdays,
                                  state.reminderHour,
                                  state.reminderMinute,
                                  locale: state.locale,
                                )
                              : tx(context, 'rem_off'),
                          style: RagaType.chip(rc.onCard),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: rc.onCardMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, tx(context, 'profile_backup')),
        _backupCard(context, state),
        const SizedBox(height: 18),
        _label(context, tx(context, 'profile_others')),
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx(context, 'profile_devmode'),
                          style: RagaType.cardTitle(rc.onCard),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.devMode
                              ? tx(context, 'profile_dev_on')
                              : tx(context, 'profile_dev_off'),
                          style: RagaType.caption(rc.onCardMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.devMode,
                    onChanged: state.setDevMode,
                  ),
                ],
              ),
              if (state.devMode) ...[
                const SizedBox(height: 6),
                _devRow(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: tx(context, 'profile_test_notif'),
                  subtitle: tx(context, 'profile_test_notif_sub'),
                  onTap: () => _sendTestNotification(context),
                ),
                _devRow(
                  context,
                  icon: Icons.alarm_outlined,
                  title: tx(context, 'profile_alarms'),
                  subtitle: tx(context, 'profile_alarms_sub'),
                  onTap: () => _pendingAlarmsDialog(context),
                ),
                _devRow(
                  context,
                  icon: Icons.terminal_outlined,
                  title: tx(context, 'profile_log'),
                  subtitle: tx(context, 'profile_log_sub'),
                  onTap: () => _logsDialog(context),
                ),
              ],
              _divider(context),
              GestureDetector(
                onTap: () => _confirmClear(context, state),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 58,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(color: rc.danger, width: 1.5),
                    color: rc.danger.withValues(alpha: 0.10),
                  ),
                  child: Center(
                    child: Text(
                      tx(context, 'profile_wipe'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: rc.danger,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    tx(context, 'profile_version'),
                    style: RagaType.caption(rc.onCardMuted),
                  ),
                  const Spacer(),
                  Text(
                    'Raga 2.0.0',
                    style: RagaType.label(rc.onCard),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // "Pria · 21 th · 170 cm", converted for imperial.
  String _profileLine(BuildContext context, AppState state, Profile p) {
    final h = state.metricUnits
        ? '${p.heightCm.toStringAsFixed(0)} cm'
        : '${(p.heightCm * cmToIn).round()} in';
    return tx(context, 'profile_line', {
      'gender': tx(context, p.isMale ? 'male' : 'female'),
      'n': p.age,
      'h': h,
    });
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: RagaType.label(context.rc.onBgMuted),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 32,
      thickness: 1,
      color: context.rc.cardBorder,
    );
  }

  // "Hari ini · 07.00", "Besok · 07.00", or "Sen · 07.00" — the
  // earliest upcoming armed day.
  String _nextLabel(BuildContext context, Set<int> days, int h, int m) {
    if (days.isEmpty) return tx(context, 'profile_pick_day');
    var best = ReminderService.nextOccurrence(days.first, h, m);
    for (final d in days.skip(1)) {
      final c = ReminderService.nextOccurrence(d, h, m);
      if (c.isBefore(best)) best = c;
    }
    final now = DateTime.now();
    final diff = DateTime(best.year, best.month, best.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final when = diff == 0
        ? tx(context, 'profile_today')
        : diff == 1
            ? tx(context, 'profile_tomorrow')
            : _dayName(context, best.weekday);
    return '$when · ${_hdot(h, m)}';
  }

  // One arming flow for the toggle and the schedule dialog: permission
  // first (a denied permission must not flip the reminder on), then
  // exact alarms when allowed, and an honest message about which one
  // the OS actually gave us.
  Future<bool> _armDays(
    BuildContext context,
    ScaffoldMessengerState messenger,
    List<int> days,
    int hour,
    int minute,
  ) async {
    // Capture everything context-derived up front: using BuildContext
    // after an await trips use_build_context_synchronously.
    final locale = AppState.of(context).locale;
    final notifOff = tx(context, 'profile_arm_notif');
    final exactOff = tx(context, 'profile_arm_exact');
    final okMsg = tx(context, 'profile_arm_ok');
    final lateMsg = tx(context, 'profile_arm_late');
    final ok = await ReminderService.requestPermission();
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(notifOff),
        ),
      );
      return false;
    }
    // Exact alarms are required for a reliable weekly nudge.
    // requestExactAlarmsPermission() only OPENS Settings — it returns
    // immediately without waiting for the toggle. Scheduling right away
    // would silently fall back to an inexact alarm that may never fire
    // on aggressive OEM skins, so we stop here and let the user re-arm
    // after granting.
    if (!await ReminderService.canScheduleExact()) {
      await ReminderService.requestExactAlarmsPermission();
      messenger.showSnackBar(
        SnackBar(
          content: Text(exactOff),
        ),
      );
      return false;
    }
    final exact = await ReminderService.scheduleBestEffortDays(
      weekdays: days,
      hour: hour,
      minute: minute,
      locale: locale,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(exact ? okMsg : lateMsg),
      ),
    );
    return true;
  }

  Future<void> _toggleReminder(BuildContext context, bool v) async {
    final state = AppState.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (v) {
      final days = state.reminderWeekdays;
      await state.setReminderSchedule(
        weekdays: days,
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );
      final armed = await _armDays(
        context,
        messenger,
        days,
        state.reminderHour,
        state.reminderMinute,
      );
      if (!armed) return;
      await state.setWeeklyReminder(true);
    } else {
      await state.setWeeklyReminder(false);
      await ReminderService.cancelAll();
    }
  }

  void _reminderDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    final days = state.reminderWeekdays.toSet();
    var time =
        TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) => AlertDialog(
          title: Text(tx(ctx2, 'profile_sched_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var d = 1; d <= 7; d++) ...[
                      if (d > 1) const SizedBox(width: 8),
                      DayChip(
                        label: _dayName(ctx2, d),
                        selected: days.contains(d),
                        onTap: () => setLocal(() {
                          if (days.contains(d)) {
                            days.remove(d);
                          } else {
                            days.add(d);
                          }
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx2,
                    initialTime: time,
                  );
                  if (picked != null) setLocal(() => time = picked);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: rc.chipInactive,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: rc.cardBorder, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 22, color: rc.onCardMuted),
                      const SizedBox(width: 12),
                      Text(
                        _hdot(time.hour, time.minute),
                        style: RagaType.hero(40, rc.onCard),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tx(ctx2, 'profile_next', {
                  't': _nextLabel(ctx2, days, time.hour, time.minute)
                }),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              const SizedBox(height: 18),
              RagaButton(
                label: tx(ctx2, 'save'),
                height: 56,
                onPressed: days.isEmpty
                    ? null
                    : () async {
                        final messenger =
                            ScaffoldMessenger.of(ctx2);
                        final list = days.toList()..sort();
                        await state.setReminderSchedule(
                          weekdays: list,
                          hour: time.hour,
                          minute: time.minute,
                        );
                        if (state.weeklyReminder) {
                          await _armDays(
                            ctx2,
                            messenger,
                            list,
                            time.hour,
                            time.minute,
                          );
                        }
                        if (ctx2.mounted) Navigator.pop(ctx2);
                      },
              ),
              RagaTextButton(
                label: tx(ctx2, 'cancel'),
                onPressed: () => Navigator.pop(ctx2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backupCard(BuildContext context, AppState state) {
    final rc = context.rc;
    final code = CloudSync.backupCode ?? tx(context, 'profile_code_not_ready');
    final pending = CloudSync.pendingCount(state.records);
    final isError = CloudSync.state == SyncState.error;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx(context, 'profile_status'),
                      style: RagaType.label(rc.onCardMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CloudSync.describe(state.records,
                          locale: state.locale),
                      style: RagaType.cardTitle(rc.onCard),
                    ),
                  ],
                ),
              ),
              _syncDot(context),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 6),
            Text(
              tx(context, 'profile_pending', {'n': pending}),
              style: TextStyle(
                fontSize: 13,
                color: rc.onCardMuted,
              ),
            ),
          ],
          if (isError && CloudSync.lastError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Error: ${CloudSync.lastError}',
              style: TextStyle(fontSize: 13, color: rc.onCardMuted),
            ),
            if (CloudSync.hintFor(CloudSync.lastError) != null) ...[
              const SizedBox(height: 4),
              Text(
                CloudSync.hintFor(CloudSync.lastError)!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCard,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Text(
            tx(context, 'profile_backup_code'),
            style: RagaType.label(rc.onCardMuted),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: rc.chipInactive,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rc.cardBorder, width: 1.2),
            ),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: rc.onCard,
              ),
            ),
          ),
          const SizedBox(height: 14),
          RagaOutlineButton(
            label: tx(context, 'profile_copy_code'),
            height: 56,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(tx(context, 'profile_code_copied'))),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          RagaButton(
            label: tx(context, 'profile_sync_now'),
            height: 56,
            onPressed: () async {
              await state.refreshSync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(CloudSync.describe(state.records,
                          locale: state.locale))),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          RagaOutlineButton(
            label: tx(context, 'profile_restore'),
            height: 56,
            onPressed: () => _restoreCodeDialog(context, state),
          ),
          if (state.devMode) ...[
            const SizedBox(height: 10),
            Text(
              'Server: ${CloudSync.configuredHost}',
              style: TextStyle(
                fontSize: 12.5,
                color: rc.onCardMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            tx(context, 'profile_backup_note'),
            style: TextStyle(
              fontSize: 12.5,
              color: rc.onCardMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncDot(BuildContext context) {
    final rc = context.rc;
    final color = switch (CloudSync.state) {
      SyncState.ready => rc.badgeOk,
      SyncState.notConfigured => const Color(0xFFF2B544),
      SyncState.error => rc.danger,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _devRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rc.chipActive.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: rc.chipActive),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: rc.onCard,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: rc.onCardMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: rc.onCardMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _addProfileSheet(
      BuildContext context, AppState state) async {
    final p = await showProfileSheet(context, metric: state.metricUnits);
    if (p != null) {
      await state.addProfile(p);
    }
  }

  void _confirmDeleteProfile(
      BuildContext context, AppState state, Profile prof) {
    final rc = context.rc;
    if (state.profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(tx(context, 'profile_delete_last'))),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_delete_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'profile_delete_body', {'name': prof.name}),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: tx(ctx, 'delete'),
              onTap: () async {
                Navigator.pop(ctx);
                await state.removeProfile(prof.id);
              },
            ),
            RagaTextButton(
              label: tx(ctx, 'cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreCodeDialog(BuildContext context, AppState state) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_restore')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'XXXX-XXXX-XXXX-XXXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            RagaButton(
              label: tx(ctx, 'continue'),
              height: 56,
              onPressed: () {
                if (ctl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _confirmRestore(context, state, ctl.text);
              },
            ),
            RagaTextButton(
              label: tx(ctx, 'cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ).whenComplete(ctl.dispose);
  }

  void _confirmRestore(
      BuildContext context, AppState state, String code) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_replace_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'profile_replace_body'),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: tx(ctx, 'profile_replace_ok'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok =
                    await state.restoreFromBackupCode(code);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? tx(context, 'profile_restored')
                          : tx(context, 'profile_restore_fail')),
                    ),
                  );
                }
              },
            ),
            RagaTextButton(
              label: tx(ctx, 'cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestNotification(BuildContext context) async {
    final locale = AppState.of(context).locale;
    final sent = tx(context, 'profile_test_sent');
    final failed = tx(context, 'profile_test_fail');
    final ok = await ReminderService.showTest(locale: locale);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? sent : failed)),
      );
    }
  }

  // Log viewer, text-editor style: monospace, line numbers, one row
  // per line. Long-press a row to copy just that line; the actions
  // copy everything or wipe the session log.
  void _logsDialog(BuildContext context) {
    final rc = context.rc;
    final lines = CloudSync.logText.split('\n');
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 11.5);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_log')),
        content: SizedBox(
          width: double.maxFinite,
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx(ctx, 'log_hint'),
                style: RagaType.caption(rc.onCardMuted),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: lines.length,
                  itemBuilder: (_, i) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () async {
                      await Clipboard.setData(
                          ClipboardData(text: lines[i]));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text(
                                  tx(ctx, 'log_copied_line'))),
                        );
                      }
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${i + 1}',
                              textAlign: TextAlign.right,
                              style: mono.copyWith(
                                  color: rc.onCardMuted),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lines[i].isEmpty ? ' ' : lines[i],
                              style: mono.copyWith(color: rc.onCard),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: CloudSync.logText));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content:
                          Text(tx(ctx, 'log_copied_all'))),
                );
              }
            },
            child: Text(tx(ctx, 'log_copy_all')),
          ),
          TextButton(
            onPressed: () {
              CloudSync.clearLog();
              Navigator.pop(ctx);
            },
            child: Text(tx(ctx, 'delete')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tx(ctx, 'close')),
          ),
        ],
      ),
    );
  }

  // Developer inspector: lists the alarms the OS actually has
  // registered. If a reminder "never fires", this shows whether it
  // was even scheduled.
  Future<void> _pendingAlarmsDialog(BuildContext context) async {
    final alarms = await ReminderService.pendingAlarms();
    if (!context.mounted) return;
    final noTitle = tx(context, 'alarms_no_title');
    final body = alarms.isEmpty
        ? tx(context, 'profile_alarms_empty')
        : alarms
            .map((a) =>
                '#${a.id} — ${a.title ?? noTitle}\n  ${a.body ?? ""}')
            .join('\n');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_alarms')),
        content: SingleChildScrollView(
          child: SelectableText(
            body,
            style:
                const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tx(ctx, 'close')),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_wipe')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'profile_wipe_body'),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: tx(ctx, 'delete'),
              onTap: () {
                Navigator.pop(ctx);
                state.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(tx(context, 'profile_wiped'))),
                );
              },
            ),
            RagaTextButton(
              label: tx(ctx, 'cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
