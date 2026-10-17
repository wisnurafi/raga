import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/cloud_sync.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/glass.dart';

/// The Profile tab's cloud-backup section: status, backup-code
/// on-demand generation, restore, and manual sync. Extracted from
/// `_ProfileScreenState` (L9) — the busy flag lives here now.
class ProfileBackupSection extends StatefulWidget {
  final AppState state;

  const ProfileBackupSection({super.key, required this.state});

  @override
  State<ProfileBackupSection> createState() => _ProfileBackupSectionState();
}

class _ProfileBackupSectionState extends State<ProfileBackupSection> {
  bool _generatingCode = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final rc = context.rc;
    final code = CloudSync.backupCode;
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
                      CloudSync.describe(state.records, locale: state.locale),
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
          if (code == null) ...[
            // No code yet: the user hasn't asked for one. Offer to
            // generate it on demand instead of showing a dead code box.
            Text(
              tx(context, 'profile_no_code_desc'),
              style: TextStyle(
                fontSize: 13.5,
                color: rc.onCardMuted,
              ),
            ),
            const SizedBox(height: 14),
            RagaButton(
              label: _generatingCode
                  ? tx(context, 'profile_generating')
                  : tx(context, 'profile_generate_code'),
              height: 56,
              onPressed:
                  _generatingCode ? null : () => _onGenerateCode(context),
            ),
          ] else ...[
            Text(
              tx(context, 'profile_backup_code'),
              style: RagaType.label(rc.onCardMuted),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    SnackBar(content: Text(tx(context, 'profile_code_copied'))),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            RagaOutlineButton(
              label: tx(context, 'profile_view_code'),
              height: 56,
              onPressed: () => _showBackupCodeModal(context, code, true),
            ),
            const SizedBox(height: 6),
            RagaTextButton(
              label: tx(context, 'profile_regenerate_code'),
              onPressed: () => _confirmRegenerate(context),
            ),
          ],
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
            onPressed: () => _restoreCodeDialog(context),
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

  // Generates the backup code on demand, then shows it in the modal with
  // usage instructions. The button shows a busy label while the cloud leg
  // (re-stamp + blob) runs.
  Future<void> _onGenerateCode(BuildContext context) async {
    setState(() => _generatingCode = true);
    late final GeneratedBackupCode result;
    try {
      result = await widget.state.generateBackupCode();
    } finally {
      if (mounted) setState(() => _generatingCode = false);
    }
    if (!context.mounted) return;
    _showBackupCodeModal(context, result.code, result.cloudOk);
  }

  // The modal shown right after generating (and on "view code"): the code
  // itself plus how to use it. When [cloudOk] is false the cloud leg
  // failed (offline) — say so honestly instead of pretending it's safe.
  void _showBackupCodeModal(BuildContext context, String code, bool cloudOk) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_code_modal_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: rc.chipInactive,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: rc.cardBorder, width: 1.2),
                ),
                child: SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              RagaOutlineButton(
                label: tx(ctx, 'profile_copy_code'),
                height: 56,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(tx(ctx, 'profile_code_copied'))),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              Text(
                tx(ctx, 'profile_code_modal_howto'),
                style: TextStyle(color: rc.onCardMuted),
              ),
              const SizedBox(height: 10),
              Text(
                tx(ctx, 'profile_code_modal_warn'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: rc.onCard,
                ),
              ),
              if (!cloudOk) ...[
                const SizedBox(height: 10),
                Text(
                  tx(ctx, 'profile_code_modal_offline'),
                  style: TextStyle(color: rc.onCardMuted),
                ),
              ],
              const SizedBox(height: 18),
              RagaButton(
                label: tx(ctx, 'profile_code_modal_close'),
                height: 56,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Regenerating kills the old code: confirm first, then run the same
  // generate flow (new code, re-stamp, new blob, modal).
  void _confirmRegenerate(BuildContext context) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_regen_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'profile_regen_body'),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: tx(ctx, 'profile_regen_ok'),
              onTap: () {
                Navigator.pop(ctx);
                _onGenerateCode(context);
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

  void _restoreCodeDialog(BuildContext context) {
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
                _chooseRestoreMode(context, ctl.text);
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

  // Restore choice: merge the backup into what's on this phone, or
  // replace everything (the old behavior, still behind a confirm).
  void _chooseRestoreMode(BuildContext context, String code) {
    final state = widget.state;
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_restore_mode_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'profile_restore_mode_body'),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            RagaButton(
              label: tx(ctx, 'profile_merge'),
              height: 56,
              onPressed: () async {
                Navigator.pop(ctx);
                final n = await state.mergeFromBackupCode(code);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(n < 0
                        ? tx(context, 'profile_restore_fail')
                        : n == 0
                            ? tx(context, 'profile_merge_empty')
                            : tx(context, 'profile_merged', {'n': n})),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            DangerPillButton(
              label: tx(ctx, 'profile_replace_ok'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRestore(context, code);
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

  void _confirmRestore(BuildContext context, String code) {
    final state = widget.state;
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
                final ok = await state.restoreFromBackupCode(code);
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
}
