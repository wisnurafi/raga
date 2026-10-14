import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../data/cloud_sync.dart';
import '../data/reminder_service.dart';
import '../widgets/glass.dart';

// The "Profile" screen: active profile info + app settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final p = state.activeProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: rc.onImage,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 18),
        GlassContainer(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
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
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B1B2F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: rc.onImage,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.isMale ? 'Male' : 'Female'} · ${p.age} yrs old',
                      style:
                          TextStyle(fontSize: 13.5, color: rc.onImageMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _renameDialog(context, state, p.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: rc.primaryBtn.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: rc.primaryBtn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionLabel(context, 'Settings'),
        _tile(
          context,
          icon: Icons.straighten_outlined,
          title: 'Units',
          subtitle:
              state.metricUnits ? 'Centimeters · kilograms' : 'Inches · pounds',
          trailing: Switch(
            value: state.metricUnits,
            onChanged: state.setMetricUnits,
          ),
        ),
        const SizedBox(height: 10),
        _tile(
          context,
          icon: Icons.notifications_outlined,
          title: 'Weekly reminder',
          subtitle: state.weeklyReminder
              ? 'Every ${_dayName(state.reminderWeekday)}, ${TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute).format(context)}'
              : 'A gentle nudge every week',
          trailing: Switch(
            value: state.weeklyReminder,
            onChanged: (v) => _toggleReminder(context, v),
          ),
          onTap: () => _reminderDialog(context, state),
        ),
        const SizedBox(height: 22),
        _sectionLabel(context, 'Data'),
        _tile(
          context,
          icon: Icons.cloud_outlined,
          title: 'Cloud backup',
          subtitle: CloudSync.describe(state.records),
          trailing: _syncDot(context),
          onTap: () => _syncDialog(context, state),
        ),
        _tile(
          context,
          icon: Icons.delete_outline,
          title: 'Delete all data',
          subtitle: 'History and profiles on this device',
          trailing: null,
          danger: true,
          onTap: () => _confirmClear(context, state),
        ),
        const SizedBox(height: 22),
        _sectionLabel(context, 'About'),
        _tile(
          context,
          icon: Icons.info_outline,
          title: 'Raga v1.0.0',
          subtitle: 'BMI Calculator',
          trailing: null,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 14, color: rc.onImageMuted),
              const SizedBox(width: 6),
              Text(
                'Your data stays on this phone & your private cloud',
                style: TextStyle(fontSize: 12.5, color: rc.onImageMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _syncDot(BuildContext context) {
    final rc = context.rc;
    final color = switch (CloudSync.state) {
      SyncState.ready => rc.mint,
      SyncState.notConfigured => const Color(0xFFF2B544),
      SyncState.error => const Color(0xFFF2555A),
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  void _toggleReminder(BuildContext context, bool v) async {
    final state = AppState.of(context);
    if (v) {
      final ok = await ReminderService.requestPermission();
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turn on notifications in system settings first'),
            ),
          );
        }
        return;
      }
      await ReminderService.scheduleWeekly(
        weekday: state.reminderWeekday,
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );
    } else {
      await ReminderService.cancel();
    }
    if (context.mounted) await state.setWeeklyReminder(v);
  }

  String _dayName(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  // "Today", "Tomorrow", or the weekday — so the user sees exactly when
  // the next reminder fires instead of guessing.
  String _nextLabel(int weekday, TimeOfDay time, BuildContext context) {
    final next =
        ReminderService.nextOccurrence(weekday, time.hour, time.minute);
    final now = DateTime.now();
    final diff =
        DateTime(next.year, next.month, next.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
    final when =
        diff == 0 ? 'Today' : diff == 1 ? 'Tomorrow' : _dayName(next.weekday);
    return '$when, ${time.format(context)}';
  }

  // Day + time picker for the weekly reminder.
  void _reminderDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    var day = state.reminderWeekday;
    var time =
        TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute);
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: rc.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reminder schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    ChoiceChip(
                      label: Text(_dayName(d)),
                      selected: day == d,
                      onSelected: (_) => setLocal(() => day = d),
                      selectedColor: rc.primaryBtn,
                      labelStyle: TextStyle(
                        color: day == d ? rc.onPrimaryBtn : rc.onCard,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: time,
                  );
                  if (picked != null) setLocal(() => time = picked);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: rc.panel,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: rc.onCardMuted),
                      const SizedBox(width: 10),
                      Text(
                        time.format(ctx),
                        style: TextStyle(
                          fontSize: 17,
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
                'Next: ${_nextLabel(day, time, ctx)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await state.setReminderSchedule(
                  weekday: day,
                  hour: time.hour,
                  minute: time.minute,
                );
                if (state.weeklyReminder) {
                  await ReminderService.scheduleWeekly(
                    weekday: day,
                    hour: time.hour,
                    minute: time.minute,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _syncDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    final pending = CloudSync.pendingCount(state.records);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cloud backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _syncDot(ctx),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CloudSync.describe(state.records),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (pending > 0) ...[
              const SizedBox(height: 8),
              Text('$pending ${pending == 1 ? 'entry' : 'entries'} waiting to upload.',
                  style: TextStyle(color: rc.onCardMuted)),
            ],
            if (CloudSync.lastError.isNotEmpty &&
                CloudSync.state == SyncState.error) ...[
              const SizedBox(height: 8),
              Text('Error: ${CloudSync.lastError}',
                  style: TextStyle(color: rc.onCardMuted)),
              if (CloudSync.hintFor(CloudSync.lastError) != null) ...[
                const SizedBox(height: 4),
                Text(CloudSync.hintFor(CloudSync.lastError)!,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: rc.onCard)),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              'Sent anonymously to your private Supabase database.',
              style: TextStyle(fontSize: 12.5, color: rc.onCardMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Server: ${CloudSync.configuredHost}',
              style: TextStyle(fontSize: 12.5, color: rc.onCardMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await state.refreshSync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          CloudSync.describe(state.records))),
                );
              }
            },
            child: const Text('Sync now'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: context.rc.onImageMuted,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget? trailing,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final rc = context.rc;
    final dangerColor = const Color(0xFFF2555A);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        borderRadius: 22,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger
                    ? dangerColor.withValues(alpha: 0.14)
                    : rc.primaryBtn.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: danger ? dangerColor : rc.primaryBtn,
              ),
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
                      color: danger ? dangerColor : rc.onBg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 12.5, color: rc.onBgMuted),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
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
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (_) {
            Navigator.pop(ctx);
            _applyRename(state, ctrl.text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applyRename(state, ctrl.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applyRename(AppState state, String name) {
    final n = name.trim();
    if (n.isNotEmpty) {
      state.updateActiveProfile((p) => p.copyWith(name: n));
    }
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
            'Your history and profiles on this device will be gone for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF2555A)),
            onPressed: () {
              Navigator.pop(ctx);
              state.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
