import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/cloud_sync.dart';
import '../data/reminder_service.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/glass.dart';

/// The Profile tab's "others" section: developer-mode toggle + rows,
/// destructive wipe, and the app version. Extracted from
/// `_ProfileScreenState` (L9).
class ProfileDevSection extends StatelessWidget {
  final AppState state;

  const ProfileDevSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return GlassCard(
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
          Divider(
            height: 32,
            thickness: 1,
            color: context.rc.cardBorder,
          ),
          GestureDetector(
            onTap: () => _confirmClear(context),
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
                'Raga ${state.appVersion}',
                style: RagaType.label(rc.onCard),
              ),
            ],
          ),
        ],
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
                      await Clipboard.setData(ClipboardData(text: lines[i]));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(tx(ctx, 'log_copied_line'))),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${i + 1}',
                              textAlign: TextAlign.right,
                              style: mono.copyWith(color: rc.onCardMuted),
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
              await Clipboard.setData(ClipboardData(text: CloudSync.logText));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(tx(ctx, 'log_copied_all'))),
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
            .map((a) => '#${a.id} — ${a.title ?? noTitle}\n  ${a.body ?? ""}')
            .join('\n');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_alarms')),
        content: SingleChildScrollView(
          child: SelectableText(
            body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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

  void _confirmClear(BuildContext context) {
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
                  SnackBar(content: Text(tx(context, 'profile_wiped'))),
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
