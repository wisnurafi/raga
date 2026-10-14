import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../data/cloud_sync.dart';
import '../data/reminder_service.dart';
import '../widgets/glass.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/controls.dart';

// Profile tab: identity, profiles, goal, reminder, units, appearance,
// cloud backup, developer tools, and the danger zone.
// New visual language — every feature from the old screen is ported.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static String _dayName(int d) => _days[d - 1];
  static String _hhmm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;
    final goal = state.goalFor(p.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        // Centered identity header.
        Column(
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
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: rc.avatarFg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _renameDialog(context, state, p.name),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: rc.onBg,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: rc.onBgMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _profileLine(state, p),
              style: TextStyle(fontSize: 13.5, color: rc.onBgMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _label(context, 'Profiles'),
        GlassCard(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              for (final prof in state.profiles)
                _profileRow(
                  context,
                  state,
                  prof,
                  prof.id == state.activeProfileId,
                ),
              _addProfileRow(context, state),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Goal'),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight goal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: rc.onCardMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal == null
                          ? 'No goal set'
                          : _goalText(state.metricUnits, p.weightKg, goal),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: rc.onCard,
                      ),
                    ),
                    if (goal != null)
                      GestureDetector(
                        onTap: () =>
                            state.setGoalWeight(p.id, null),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: 8, bottom: 2),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: rc.danger,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 118,
                child: RagaGhostButton(
                  label: goal == null ? 'Set goal' : 'Change',
                  onPressed: () => _goalDialog(context, state),
                  height: 48,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Weigh-in reminder'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly reminder',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: rc.onCardMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.weeklyReminder
                              ? _summary(
                                  state.reminderWeekdays,
                                  state.reminderHour,
                                  state.reminderMinute,
                                )
                              : 'Off',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: rc.onCard,
                          ),
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
              RagaGhostButton(
                label: 'Edit schedule',
                onPressed: () => _reminderDialog(context, state),
                height: 50,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Units'),
        GlassCard(
          child: Segmented<String>(
            options: const ['cm · kg', 'in · lb'],
            value: state.metricUnits ? 'cm · kg' : 'in · lb',
            onChanged: (v) =>
                state.setMetricUnits(v == 'cm · kg'),
            labelOf: (s) => s,
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Appearance'),
        GlassCard(
          child: Segmented<String>(
            options: const ['Dark', 'Light'],
            value: state.darkMode ? 'Dark' : 'Light',
            onChanged: (v) => state.setDarkMode(v == 'Dark'),
            labelOf: (s) => s,
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Cloud backup'),
        _backupCard(context, state),
        const SizedBox(height: 18),
        _label(context, 'Developer'),
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
                          'Developer mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: rc.onCard,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.devMode
                              ? 'Logs, test notification, server info'
                              : 'Extra tools for debugging',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: rc.onCardMuted,
                          ),
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
                  title: 'Send test notification',
                  subtitle: 'Fires one right now',
                  onTap: () => _sendTestNotification(context),
                ),
                _devRow(
                  context,
                  icon: Icons.alarm_outlined,
                  title: 'Pending alarms',
                  subtitle: 'What the OS actually registered',
                  onTap: () => _pendingAlarmsDialog(context),
                ),
                _devRow(
                  context,
                  icon: Icons.terminal_outlined,
                  title: 'Session sync log',
                  subtitle: 'This session only',
                  onTap: () => _logsDialog(context),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Danger zone'),
        GestureDetector(
          onTap: () => _confirmClear(context, state),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 62,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31),
              border: Border.all(color: rc.danger, width: 1.5),
              color: rc.danger.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Text(
                'Erase all data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: rc.danger,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // "Male · 21 yrs · 170 cm · 65 kg", converted for imperial.
  String _profileLine(AppState state, Profile p) {
    final w = state.metricUnits
        ? '${p.weightKg.toStringAsFixed(0)} kg'
        : '${(p.weightKg * 2.20462).round()} lb';
    final h = state.metricUnits
        ? '${p.heightCm.toStringAsFixed(0)} cm'
        : '${(p.heightCm / 2.54).round()} in';
    return '${p.isMale ? 'Male' : 'Female'} · ${p.age} yrs · $h · $w';
  }

  String _fmtW(double kg, bool metric) => metric
      ? '${kg.toStringAsFixed(1)} kg'
      : '${(kg * 2.20462).round()} lb';

  String _goalText(bool metric, double curKg, double goalKg) {
    final d = goalKg - curKg;
    final g = _fmtW(goalKg, metric);
    if (d.abs() < 0.5) return 'Maintain $g';
    return d < 0 ? 'Lose to $g' : 'Gain to $g';
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: context.rc.onBgMuted,
        ),
      ),
    );
  }

  Widget _profileRow(
    BuildContext context,
    AppState state,
    Profile prof,
    bool active,
  ) {
    final rc = context.rc;
    return GestureDetector(
      onTap: () async {
        if (!active) await state.setActiveProfile(prof.id);
      },
      onLongPress: () => _confirmDeleteProfile(context, state, prof),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rc.avatarBg,
              ),
              child: Center(
                child: Text(
                  prof.initial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: rc.avatarFg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prof.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: rc.onCard,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prof.isMale ? 'Male' : 'Female'} · ${prof.age} yrs',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: rc.onCardMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle, color: rc.badgeOk, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _addProfileRow(BuildContext context, AppState state) {
    final rc = context.rc;
    return GestureDetector(
      onTap: () => _addProfileDialog(context, state),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rc.chipActive.withValues(alpha: 0.18),
                border: Border.all(
                  color: rc.chipActive.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Icon(Icons.add, color: rc.chipActive, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Add profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: rc.onCardAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "2× a week · Mon & Thu · 07:00" / "1× a week · Mon · 07:00" /
  // "Every day · 07:00".
  String _summary(List<int> days, int h, int m) {
    if (days.isEmpty) return 'Off';
    final t = _hhmm(h, m);
    if (days.length == 7) return 'Every day · $t';
    final names = days.map(_dayName).toList();
    final joined = names.length == 1
        ? names.first
        : names.length == 2
            ? '${names[0]} & ${names[1]}'
            : '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
    return '${names.length}× a week · $joined · $t';
  }

  // "Today · 07:00", "Tomorrow · 07:00", or "Mon · 07:00" — the
  // earliest upcoming armed day.
  String _nextLabel(Set<int> days, int h, int m) {
    if (days.isEmpty) return 'Pick at least one day';
    var best = ReminderService.nextOccurrence(days.first, h, m);
    for (final d in days.skip(1)) {
      final c = ReminderService.nextOccurrence(d, h, m);
      if (c.isBefore(best)) best = c;
    }
    final now = DateTime.now();
    final diff =
        DateTime(best.year, best.month, best.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
    final when =
        diff == 0 ? 'Today' : diff == 1 ? 'Tomorrow' : _dayName(best.weekday);
    return '$when · ${_hhmm(h, m)}';
  }

  // One arming flow for the toggle and the schedule dialog: permission
  // first (a denied permission must not flip the reminder on), then
  // exact alarms when allowed, and an honest message about which one
  // the OS actually gave us.
  Future<bool> _armDays(
    ScaffoldMessengerState messenger,
    List<int> days,
    int hour,
    int minute,
  ) async {
    final ok = await ReminderService.requestPermission();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Turn on notifications in system settings first'),
        ),
      );
      return false;
    }
    if (!await ReminderService.canScheduleExact()) {
      await ReminderService.requestExactAlarmsPermission();
    }
    final exact = await ReminderService.scheduleBestEffortDays(
      weekdays: days,
      hour: hour,
      minute: minute,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(exact
            ? 'Weekly reminder set'
            : 'Reminder set, but exact alarms are off — it may arrive '
                'late. Allow "Alarms & reminders" in system settings '
                'for on-time nudges.'),
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
          title: const Text('Reminder schedule'),
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
                      DayPill(
                        label: _dayName(d),
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
                        _hhmm(time.hour, time.minute),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: rc.onCard,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Next: ${_nextLabel(days, time.hour, time.minute)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              const SizedBox(height: 18),
              RagaButton(
                label: 'Save',
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
                            messenger,
                            list,
                            time.hour,
                            time.minute,
                          );
                        }
                        if (ctx2.mounted) Navigator.pop(ctx2);
                      },
              ),
              RagaTextLink(
                label: 'Cancel',
                onTap: () => Navigator.pop(ctx2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Goal dialog in the onboarding language: direction segmented +
  // weight stepper + a live "−3.0 kg to go" line.
  void _goalDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    final p = state.activeProfile;
    final metric = state.metricUnits;
    final cur = p.weightKg;
    final unit = metric ? 'kg' : 'lb';
    final min = metric ? 30.0 : 66.0;
    final max = metric ? 150.0 : 330.0;
    final step = metric ? 0.5 : 1.0;
    double toDisplay(double kg) => metric ? kg : kg * 2.20462;
    double toKg(double v) => metric ? v : v / 2.20462;
    String dirOf(double v) {
      final d = toKg(v) - cur;
      if (d.abs() < 0.5) return 'Maintain';
      return d < 0 ? 'Lose' : 'Gain';
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
              ? 'Stay at ${_fmtW(cur, metric)}'
              : d < 0
                  ? '−${_fmtW(d.abs(), metric)} to go'
                  : '+${_fmtW(d, metric)} to go';
          return AlertDialog(
            title: const Text('Weight goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Segmented<String>(
                  options: const ['Lose', 'Maintain', 'Gain'],
                  value: dir,
                  onChanged: (v) => setLocal(() {
                    dir = v;
                    final kgNow = toKg(value);
                    if (v == 'Maintain') {
                      value = toDisplay(cur);
                    } else if (v == 'Lose' && kgNow >= cur) {
                      value = toDisplay(cur - 3).clamp(min, max);
                    } else if (v == 'Gain' && kgNow <= cur) {
                      value = toDisplay(cur + 3).clamp(min, max);
                    }
                  }),
                  labelOf: (s) => s,
                ),
                const SizedBox(height: 18),
                StepperRow(
                  value: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value.toStringAsFixed(metric ? 1 : 0),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: rc.onCard,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: rc.onCardMuted,
                        ),
                      ),
                    ],
                  ),
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
                  label: 'Save goal',
                  height: 56,
                  onPressed: () async {
                    await state.setGoalWeight(
                        p.id, toKg(value));
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                ),
                if (hasGoal)
                  RagaTextLink(
                    label: 'Clear goal',
                    onTap: () async {
                      await state.setGoalWeight(p.id, null);
                      if (ctx2.mounted) Navigator.pop(ctx2);
                    },
                  )
                else
                  RagaTextLink(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(ctx2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _backupCard(BuildContext context, AppState state) {
    final rc = context.rc;
    final code = CloudSync.backupCode ?? '(not ready yet)';
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
                      'Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: rc.onCardMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CloudSync.describe(state.records),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: rc.onCard,
                      ),
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
              '$pending ${pending == 1 ? 'entry' : 'entries'} waiting to upload.',
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
            'Backup code',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: rc.onCardMuted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: rc.chipInactive,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: rc.cardBorder, width: 1.2),
                  ),
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: rc.onCard,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _circleBtn(
                context,
                icon: Icons.copy_outlined,
                onTap: () async {
                  await Clipboard.setData(
                      ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Backup code copied')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          RagaButton(
            label: 'Sync now',
            height: 56,
            onPressed: () async {
              await state.refreshSync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(CloudSync.describe(state.records))),
                );
              }
            },
          ),
          const SizedBox(height: 4),
          RagaGhostButton(
            label: 'Restore from code',
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
            'Backed up to your private cloud. No account needed — it just works.',
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

  Widget _circleBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rc.chipInactive,
          border: Border.all(color: rc.cardBorder, width: 1.2),
        ),
        child: Icon(icon, color: rc.onCard, size: 20),
      ),
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

  void _addProfileDialog(BuildContext context, AppState state) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                Navigator.pop(ctx);
                state.addProfile(ctl.text);
              },
            ),
            const SizedBox(height: 18),
            RagaButton(
              label: 'Add',
              height: 56,
              onPressed: () {
                Navigator.pop(ctx);
                state.addProfile(ctl.text);
              },
            ),
            RagaTextLink(
              label: 'Cancel',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _renameDialog(
      BuildContext context, AppState state, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                Navigator.pop(ctx);
                _applyRename(state, ctrl.text);
              },
            ),
            const SizedBox(height: 18),
            RagaButton(
              label: 'Save',
              height: 56,
              onPressed: () {
                Navigator.pop(ctx);
                _applyRename(state, ctrl.text);
              },
            ),
            RagaTextLink(
              label: 'Cancel',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _applyRename(AppState state, String name) {
    final n = name.trim();
    if (n.isNotEmpty) {
      state.updateActiveProfile((p) => p.copyWith(name: n));
    }
  }

  void _confirmDeleteProfile(
      BuildContext context, AppState state, Profile prof) {
    final rc = context.rc;
    if (state.profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You can't delete your last profile")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${prof.name} and their history will be gone for good.',
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await state.removeProfile(prof.id);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: rc.danger.withValues(alpha: 0.12),
                      border:
                          Border.all(color: rc.danger, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: rc.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            RagaTextLink(
              label: 'Cancel',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _backupCodeDialog(BuildContext context) {
    final rc = context.rc;
    final code = CloudSync.backupCode ?? '(not ready yet)';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keep this code somewhere safe. If you reinstall Raga, enter it to get your data back.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: rc.onCardMuted,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: rc.chipInactive,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: rc.cardBorder, width: 1.2),
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: rc.onCard,
                ),
              ),
            ),
            const SizedBox(height: 18),
            RagaButton(
              label: 'Copy',
              height: 56,
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: code));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Backup code copied')),
                  );
                }
              },
            ),
            RagaTextLink(
              label: 'Close',
              onTap: () => Navigator.pop(ctx),
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
        title: const Text('Restore from backup code'),
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
              label: 'Next',
              height: 56,
              onPressed: () {
                if (ctl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _confirmRestore(context, state, ctl.text);
              },
            ),
            RagaTextLink(
              label: 'Cancel',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(
      BuildContext context, AppState state, String code) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace everything?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will replace all profiles and history on this phone with the backup. This cannot be undone.',
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok =
                        await state.restoreFromBackupCode(code);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Backup restored — welcome back.'
                              : 'Code not found or cloud unreachable. Check the code and try again.'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: rc.danger.withValues(alpha: 0.12),
                      border:
                          Border.all(color: rc.danger, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Restore',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: rc.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            RagaTextLink(
              label: 'Cancel',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestNotification(BuildContext context) async {
    final ok = await ReminderService.showTest();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok
                ? 'Test notification sent'
                : "Couldn't show a notification — check the permission")),
      );
    }
  }

  void _logsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync logs'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              CloudSync.logText,
              style:
                  const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              CloudSync.clearLog();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
    final body = alarms.isEmpty
        ? 'No alarms registered with the OS.'
        : alarms
            .map((a) =>
                '#${a.id} — ${a.title ?? "(no title)"}\n  ${a.body ?? ""}')
            .join('\n');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pending alarms'),
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
            child: const Text('Close'),
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
        title: const Text('Delete all data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your history and profiles on this device will be gone for good.',
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    Navigator.pop(ctx);
                    state.clearAllData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('All data deleted')),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: rc.danger.withValues(alpha: 0.12),
                      border:
                          Border.all(color: rc.danger, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: rc.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            RagaTextLink(
              label: 'Cancel',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

}
