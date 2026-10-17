import 'package:flutter/material.dart';

import '../avatar/avatar_manifest.dart';
import '../avatar/avatar_models.dart';
import '../avatar/avatar_progress.dart';
import '../avatar/avatar_unlock_ui.dart';
import '../avatar/avatar_view.dart';
import '../avatar/avatar_xp_ring.dart';
import '../avatar/progression.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';

/// The Avatar screen (inside the Profile tab): live avatar preview in
/// the XP ring, level chip, habit stats, and the item picker.
///
/// Edits go to a local draft; nothing is persisted until
/// "Simpan penampilan" is tapped.
class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  late AvatarConfig _draft;
  String _category = AvatarCategory.hair;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      final st = AppState.of(context).avatarState;
      _draft = st?.config ??
          AvatarConfig.defaults(
              AppState.of(context).avatarService!.manifest);
      _ready = true;
    }
  }

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

  bool _isSelected(AvatarConfig draft, AvatarItem item) {
    switch (item.category) {
      case AvatarCategory.hair:
        return draft.hair == item.id;
      case AvatarCategory.shirt:
        return draft.shirt == item.id;
      case AvatarCategory.accessory:
        return draft.accessory == item.id;
      case AvatarCategory.frame:
        return draft.frame == item.id;
      default:
        return false;
    }
  }

  void _onTapItem(AvatarItem item, bool selected) {
    setState(() {
      switch (item.category) {
        case AvatarCategory.hair:
          _draft = _draft.copyWith(hair: item.id);
        case AvatarCategory.shirt:
          _draft = _draft.copyWith(shirt: item.id);
        case AvatarCategory.accessory:
          _draft = selected
              ? _draft.copyWith(clearAccessory: true)
              : _draft.copyWith(accessory: item.id);
        case AvatarCategory.frame:
          _draft = selected
              ? _draft.copyWith(clearFrame: true)
              : _draft.copyWith(frame: item.id);
      }
    });
  }

  Future<void> _save() async {
    final app = AppState.of(context);
    await app.saveAvatarConfig(app.activeProfileId, _draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tx(context, 'avatar_saved'))),
    );
  }

  String _levelChipText(
      BuildContext context, ProgressionConfig prog, int totalXp) {
    final level = prog.levelForXp(totalXp);
    final title = prog.titleFor(level);
    final toNext = prog.xpToNextLevel(level);
    if (toNext == 0) {
      return tx(context, 'avatar_level_max',
          {'title': title, 'level': level});
    }
    return tx(context, 'avatar_level_chip', {
      'title': title,
      'level': level,
      'into': prog.xpIntoLevel(totalXp, level),
      'tonext': toNext,
    });
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
            child: Center(child: Text(tx(context, 'avatar_title'))),
          ),
        ),
      );
    }

    final manifest = svc.manifest;
    final prog = svc.progression;
    final totalXp = st.totalXp;
    final level = prog.levelForXp(totalXp);
    final toNext = prog.xpToNextLevel(level);
    final ringPercent =
        toNext == 0 ? 1.0 : prog.xpIntoLevel(totalXp, level) / toNext;

    final profile = app.activeProfile;
    final records = app.recordsOf(profile.id);
    final streak = AvatarProgressService.computeDailyStreak(
        records.map((r) => r.createdAt), DateTime.now()).current;

    final items = manifest.itemsIn(_category);

    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
            children: [
              RagaHeader(
                title: tx(context, 'avatar_title'),
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
                    XpRing(
                      percent: ringPercent,
                      child: AvatarView(
                        manifest: manifest,
                        config: _draft,
                        size: 144,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.name,
                      style: RagaType.title(rc.onCard),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: rc.chipActive.withValues(alpha: 0.16),
                      ),
                      child: Text(
                        _levelChipText(context, prog, totalXp),
                        style: RagaType.label(rc.onCard),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatTile(
                          value: '$streak',
                          label: tx(context, 'avatar_stat_streak'),
                        ),
                        _StatTile(
                          value: '${records.length}',
                          label: tx(context, 'avatar_stat_records'),
                        ),
                        _StatTile(
                          value:
                              '${st.unlockedItemIds.length}/${manifest.totalItems}',
                          label: tx(context, 'avatar_stat_collection'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tx(context, 'avatar_tagline'),
                style: RagaType.body(rc.onBgMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                children: [
                  for (final c in [
                    AvatarCategory.hair,
                    AvatarCategory.shirt,
                    AvatarCategory.accessory,
                    AvatarCategory.frame,
                  ])
                    SelectChip(
                      label: _categoryLabel(context, c),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final unlocked =
                      st.unlockedItemIds.contains(item.id);
                  final selected = _isSelected(_draft, item);
                  return _OptionTile(
                    key: ValueKey('avatar_option_${item.id}'),
                    manifest: manifest,
                    item: item,
                    config: _withItem(_draft, item),
                    unlocked: unlocked,
                    selected: selected,
                    onTap: unlocked
                        ? () => _onTapItem(item, selected)
                        : null,
                  );
                },
              ),
              const SizedBox(height: 22),
              RagaButton(
                label: tx(context, 'avatar_save'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(BuildContext context, String category) {
    switch (category) {
      case AvatarCategory.hair:
        return tx(context, 'avatar_cat_hair');
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

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: RagaType.hero(24, rc.onCard)),
          const SizedBox(height: 2),
          Text(
            label,
            style: RagaType.label(rc.onCardMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final AvatarManifest manifest;
  final AvatarItem item;
  final AvatarConfig config;
  final bool unlocked;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionTile({
    super.key,
    required this.manifest,
    required this.item,
    required this.config,
    required this.unlocked,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final reqText =
        item.unlock == null ? '' : unlockRequirementText(context, item.unlock!);
    return Semantics(
      button: true,
      selected: selected,
      enabled: unlocked,
      label: unlocked
          ? '${item.name}, ${tx(context, 'avatar_unlocked')}'
          : '${item.name}, $reqText',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? rc.chipActive : Colors.transparent,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AvatarView(
                  manifest: manifest,
                  config: config,
                  size: 80,
                ),
                if (!unlocked)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reqText,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
