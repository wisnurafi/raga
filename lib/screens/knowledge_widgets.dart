import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../knowledge/knowledge_models.dart';
import '../widgets/glass.dart';

// Shared bits for the Knowledge Hub screens: section titles, article
// cards, and the offline banner. Nothing here touches the network.

/// Section label drawn on the background ("Unggulan", "Terbaru"...).
class KhSectionTitle extends StatelessWidget {
  final String text;

  const KhSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: RagaType.section(rc.onBg)),
    );
  }
}

/// One article row: title, summary, reading-time chip, an optional
/// "done" chip, and a chevron.
class KnowledgeArticleCard extends StatelessWidget {
  final KnowledgeArticle article;
  final VoidCallback onTap;
  final bool completed;

  const KnowledgeArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: RagaType.cardTitle(rc.onCard),
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      style: RagaType.caption(rc.onCardMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ReadingChip(minutes: article.readingMinutes),
                      if (completed) const _DoneChip(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: rc.onCardMuted),
          ],
        ),
      ),
    );
  }
}

class _DoneChip extends StatelessWidget {
  const _DoneChip();

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: rc.success.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 13, color: rc.success),
          const SizedBox(width: 4),
          Text(
            tx(context, 'kh_completed'),
            style: RagaType.caption(rc.success),
          ),
        ],
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  final int minutes;

  const _ReadingChip({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: rc.chipActive.withValues(alpha: 0.16),
      ),
      child: Text(
        tx(context, 'kh_min_read', {'n': minutes}),
        style: RagaType.caption(rc.onCard),
      ),
    );
  }
}

/// Slim banner shown when content came from the local cache while the
/// network was unreachable.
class KhOfflineBanner extends StatelessWidget {
  const KhOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: rc.chipActive.withValues(alpha: 0.16),
        border: Border.all(color: rc.chipBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 18, color: rc.onCardMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tx(context, 'kh_offline'),
              style: RagaType.caption(rc.onCardMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered error block with a retry button.
class KhErrorBlock extends StatelessWidget {
  final VoidCallback onRetry;

  const KhErrorBlock({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40, color: rc.onCardFaint),
          const SizedBox(height: 12),
          Text(
            tx(context, 'kh_error'),
            style: RagaType.body(rc.onCardMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text(
              tx(context, 'kh_retry'),
              style: RagaType.chip(rc.chipActive),
            ),
          ),
        ],
      ),
    );
  }
}

/// Search field in the hub/glossary style.
class KhSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const KhSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return TextField(
      onChanged: onChanged,
      style: RagaType.body(rc.onCard),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: RagaType.body(rc.onCardFaint),
        prefixIcon:
            Icon(Icons.search_outlined, color: rc.onCardMuted),
        filled: true,
        fillColor: rc.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: rc.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: rc.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: rc.chipActive, width: 1.5),
        ),
      ),
    );
  }
}
