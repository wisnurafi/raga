import 'package:flutter/material.dart';

import '../avatar/avatar_manifest.dart';
import '../avatar/avatar_models.dart';
import '../avatar/avatar_unlock_ui.dart';
import '../avatar/avatar_view.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/chips.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';

/// The Collection screen (inside the Profile tab): progress card,
/// category filter, and a grid of every item rendered on the avatar.
///
/// Tapping an unlocked item previews it on the avatar; tapping a locked
/// item opens a bottom sheet with its requirement and current progress.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  /// 'all' or an [AvatarCategory].
  String _filter = 'all';
  AvatarItem? _previewItem;

  AvatarConfig _withItem(AvatarConfig base, AvatarItem item) {
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

  void _showLockedSheet(BuildContext context, AvatarItem item) {
    final app = AppState.of(context);
    final st = app.avatarState!;
    final prog = app.avatarService!.progression;
    final level = prog.levelForXp(st.totalXp);
    final records = app.recordsOf(app.activeProfileId).length;
    final progress = item.unlock == null
        ? null
        : unlockProgress(
            item.unlock!,
            level: level,
            bestStreak: st.bestStreak,
            records: records,
          );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LockedSheet(
        item: item,
        progress: progress,
        manifest: app.avatarService!.manifest,
        config: st.config,
        locale: app.locale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final app = AppState.of(context);
    final svc = app.avatarService;
    final st = app.avatarState;
    if (svc == null || st == null) {
      return RagaBg(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(child: Text(tx(context, 'avatar_collection'))),
          ),
        ),
      );
    }

    final manifest = svc.manifest;
    final saved = st.config;
    final previewConfig =
        _previewItem == null ? saved : _withItem(saved, _previewItem!);

    final allItems = manifest.items;
    final items = _filter == 'all'
        ? allItems
        : allItems.where((i) => i.category == _filter).toList();

    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
            children: [
              RagaHeader(
                title: tx(context, 'avatar_collection'),
                showThemeToggle: false,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: rc.onBg),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  children: [
                    AvatarView(
                      manifest: manifest,
                      config: previewConfig,
                      size: 120,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tx(context, 'avatar_collected', {
                        'n': st.unlockedItemIds.length,
                        'total': manifest.totalItems,
                      }),
                      style: RagaType.title(rc.onCard),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: st.unlockedItemIds.length /
                            manifest.totalItems,
                        minHeight: 8,
                        backgroundColor: rc.isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFFEDF0F8),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(rc.chipActive),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                children: [
                  SelectChip(
                    label: tx(context, 'avatar_cat_all'),
                    selected: _filter == 'all',
                    onTap: () => setState(() {
                      _filter = 'all';
                    }),
                  ),
                  for (final c in [
                    AvatarCategory.shirt,
                    AvatarCategory.accessory,
                    AvatarCategory.frame,
                  ])
                    SelectChip(
                      label: _categoryLabel(context, c),
                      selected: _filter == c,
                      onTap: () => setState(() => _filter = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final unlocked =
                      st.unlockedItemIds.contains(item.id);
                  return _CollectionTile(
                    key: ValueKey('collection_${item.id}'),
                    manifest: manifest,
                    item: item,
                    config: _withItem(saved, item),
                    unlocked: unlocked,
                    onTap: () => unlocked
                        ? setState(() => _previewItem = item)
                        : _showLockedSheet(context, item),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(BuildContext context, String category) {
    switch (category) {
      case AvatarCategory.shirt:
        return tx(context, 'avatar_cat_shirt');
      case AvatarCategory.accessory:
        return tx(context, 'avatar_cat_accessory');
      case AvatarCategory.frame:
        return tx(context, 'avatar_cat_frame');
      default:
        return category;
    }
  }
}

class _CollectionTile extends StatelessWidget {
  final AvatarManifest manifest;
  final AvatarItem item;
  final AvatarConfig config;
  final bool unlocked;
  final VoidCallback onTap;

  const _CollectionTile({
    super.key,
    required this.manifest,
    required this.item,
    required this.config,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final statusText = unlocked
        ? tx(context, 'avatar_unlocked')
        : (item.unlock == null
            ? ''
            : unlockRequirementText(context, item.unlock!));
    return Semantics(
      button: true,
      enabled: true,
      label: '${item.name}, $statusText',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: rc.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: AvatarView(
                    manifest: manifest,
                    config: config,
                    size: 90,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                style: RagaType.label(rc.onCard),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!unlocked) ...[
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: rc.onCardMuted,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      statusText,
                      style: RagaType.label(rc.onCardMuted)
                          .copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedSheet extends StatelessWidget {
  final AvatarItem item;
  final ({int have, int need})? progress;
  final AvatarManifest manifest;
  final AvatarConfig config;
  final String locale;

  const _LockedSheet({
    required this.item,
    required this.progress,
    required this.manifest,
    required this.config,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    // Note: tx() needs AppState, which the modal route doesn't have —
    // use txl() with the locale captured from the parent context.
    final reqText = item.unlock == null
        ? ''
        : _reqText(item.unlock!);
    final ratio = progress == null
        ? 0.0
        : (progress!.have / progress!.need).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: rc.isDark ? const Color(0xFF1E1B3A) : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: rc.onCardMuted.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          AvatarView(
            manifest: manifest,
            config: _configWearing(config, item),
            size: 96,
          ),
          const SizedBox(height: 12),
          Text(item.name, style: RagaType.title(rc.onCard)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 16, color: rc.onCardMuted),
              const SizedBox(width: 6),
              Text(
                '${txl(locale, 'avatar_req_label')}: $reqText',
                style: RagaType.body(rc.onCardMuted),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            Text(
              '${txl(locale, 'avatar_progress_label')}: '
              '${progress!.have} / ${progress!.need}',
              style: RagaType.body(rc.onCard),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: rc.isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFEDF0F8),
                valueColor:
                    AlwaysStoppedAnimation<Color>(rc.chipActive),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _reqText(AvatarUnlock unlock) {
    switch (unlock.type) {
      case UnlockType.level:
        return txl(locale, 'avatar_unlock_level', {'n': unlock.value});
      case UnlockType.streakDays:
        return txl(locale, 'avatar_unlock_streak', {'n': unlock.value});
      case UnlockType.recordsCount:
        return txl(locale, 'avatar_unlock_records', {'n': unlock.value});
      case UnlockType.goalReached:
        return txl(locale, 'avatar_unlock_goal');
      default:
        return '';
    }
  }

  AvatarConfig _configWearing(AvatarConfig base, AvatarItem item) {
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
}
