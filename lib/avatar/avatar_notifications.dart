import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import 'avatar_manifest.dart';
import 'avatar_models.dart';
import 'avatar_view.dart';

/// Surfaces avatar side effects to the user: the one-time migration
/// notice, level-up toasts, and new-unlock notifications.
///
/// Called from MainShell after the frame. Guarded against re-entry and
/// against showing anything twice: the migration counter and the
/// pending result are consumed, and unlocks are marked seen.
bool _showing = false;

Future<void> checkAvatarNotifications(BuildContext context) async {
  if (_showing) return;
  final state = AppState.of(context);
  if (state.avatarService == null) return;

  _showing = true;
  try {
    // 1. One brief migration notice.
    if (state.avatarMigratedProfiles > 0) {
      final n = state.avatarMigratedProfiles;
      state.consumeAvatarMigrationNotice();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tx(context, 'avatar_migrated', {'n': n})),
          ),
        );
      }
    }

    // 2. Level-up toast (in-memory result, best-effort).
    final result = state.pendingAvatarResult;
    if (result != null) {
      state.consumeAvatarResult();
      if (result.leveledUp && context.mounted) {
        final title = state.avatarService!.progression
            .titleFor(result.newLevel);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tx(context, 'avatar_levelup', {
              'level': result.newLevel,
              'title': title,
            })),
          ),
        );
      }
    }

    // 3. New unlocks: diff unseen (survives restart), notified once
    // per item, then marked seen.
    final st = state.avatarState;
    if (st != null) {
      final unseen =
          st.unlockedItemIds.difference(st.unlockSeenIds);
      if (unseen.isNotEmpty && context.mounted) {
        final manifest = state.avatarService!.manifest;
        final byId = {for (final i in manifest.items) i.id: i};
        final items = unseen
            .map((id) => byId[id])
            .whereType<AvatarItem>()
            .toList();
        if (items.isNotEmpty) {
          await showDialog(
            context: context,
            builder: (ctx) => _UnlockDialog(
              items: items,
              manifest: manifest,
              config: st.config,
            ),
          );
        }
        await state.markAvatarUnlocksSeen(unseen);
      }
    }
  } finally {
    _showing = false;
  }
}

class _UnlockDialog extends StatelessWidget {
  final List<AvatarItem> items;
  final AvatarManifest manifest;
  final AvatarConfig config;

  const _UnlockDialog({
    required this.items,
    required this.manifest,
    required this.config,
  });

  AvatarConfig _wearing(AvatarConfig base, AvatarItem item) {
    switch (item.category) {
      case AvatarCategory.hair:
        return base.copyWith(hair: item.id);
      case AvatarCategory.shirt:
        return base.copyWith(shirt: item.id);
      case AvatarCategory.accessory:
        return base.copyWith(accessory: item.id);
      case AvatarCategory.frame:
        return base.copyWith(frame: item.id);
      default:
        return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return AlertDialog(
      backgroundColor:
          rc.isDark ? const Color(0xFF1E1B3A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        tx(context, 'avatar_unlocked_title'),
        style: RagaType.title(rc.onCard),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items) ...[
            Row(
              children: [
                AvatarView(
                  manifest: manifest,
                  config: _wearing(config, item),
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: RagaType.body(rc.onCard),
                  ),
                ),
                Icon(
                  Icons.lock_open,
                  size: 20,
                  color: rc.chipActive,
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 12),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            tx(context, 'avatar_unlocked'),
            style: RagaType.body(rc.chipActive),
          ),
        ),
      ],
    );
  }
}
