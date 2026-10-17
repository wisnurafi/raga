import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../knowledge/knowledge_models.dart';
import '../knowledge/knowledge_progress.dart';
import '../knowledge/knowledge_repository.dart';
import '../knowledge/knowledge_repository_impl.dart';
import '../widgets/buttons.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';
import 'knowledge_widgets.dart';

// Article reader: markdown body in Raga typography, reading-time +
// review-date metadata, and the cited sources. Cover images are
// intentionally skipped in the MVP (nullable column, never rendered).
class KnowledgeArticleScreen extends StatefulWidget {
  final String slug;

  /// Injected for tests; production builds create the real one.
  final KnowledgeRepository? repository;

  const KnowledgeArticleScreen({
    super.key,
    required this.slug,
    this.repository,
  });

  @override
  State<KnowledgeArticleScreen> createState() =>
      _KnowledgeArticleScreenState();
}

class _KnowledgeArticleScreenState extends State<KnowledgeArticleScreen> {
  KnowledgeRepository? _repo;
  KnowledgeProgressStore? _store;
  bool _loading = true;
  bool _error = false;
  bool _offline = false;
  bool _bookmarked = false;
  bool _done = false;
  KnowledgeArticle? _article;

  @override
  void initState() {
    super.initState();
    // Local-first progress: loads even offline, never blocks the read.
    KnowledgeProgressStore.load().then((s) {
      if (!mounted) return;
      setState(() {
        _store = s;
        _bookmarked = s.isBookmarked(widget.slug);
        _done = s.isCompleted(widget.slug);
      });
    });
    if (widget.repository != null) {
      _repo = widget.repository;
      _load();
    } else {
      KnowledgeRepositoryImpl.create().then((r) {
        if (!mounted) return;
        _repo = r;
        _load();
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final store = _store;
    final a = _article;
    if (store == null || a == null) return;
    await store.toggleBookmark(slug: a.slug, articleId: a.id);
    if (!mounted) return;
    final now = store.isBookmarked(a.slug);
    setState(() => _bookmarked = now);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tx(context,
            now ? 'kh_bookmark_added' : 'kh_bookmark_removed')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markDone() async {
    final store = _store;
    final a = _article;
    if (store == null || a == null || _done) return;
    await store.markCompleted(slug: a.slug, articleId: a.id);
    if (!mounted) return;
    setState(() => _done = true);
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final res = await repo.getArticleDetail(widget.slug);
      if (!mounted) return;
      setState(() {
        _article = res.data;
        _offline = res.offline;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  MarkdownStyleSheet _mdStyle(RagaColors rc) => MarkdownStyleSheet(
        p: RagaType.body(rc.onCard),
        h1: RagaType.title(rc.onCard),
        h2: RagaType.section(rc.onCard),
        h3: RagaType.cardTitle(rc.onCard),
        h4: RagaType.label(rc.onCard),
        listBullet: RagaType.body(rc.onCard),
        a: RagaType.body(rc.chipActive).copyWith(
          decoration: TextDecoration.underline,
        ),
        blockquote: RagaType.body(rc.onCardMuted),
        code: RagaType.body(rc.onCard).copyWith(
          fontFamily: 'monospace',
        ),
        blockSpacing: 14,
        listIndent: 20,
      );

  /// Locale-neutral numeric date (no month names to translate).
  String _dateLine(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error
                  ? ListView(
                      padding:
                          const EdgeInsets.fromLTRB(22, 8, 22, 40),
                      children: [
                          RagaHeader(
                            title: tx(context, 'kh_title'),
                            showThemeToggle: false,
                            leading: IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: rc.onBg),
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                            ),
                          ),
                          KhErrorBlock(onRetry: _load),
                        ])
                  : _reader(rc),
        ),
      ),
    );
  }

  Widget _reader(RagaColors rc) {
    final a = _article!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        RagaHeader(
          title: tx(context, 'kh_title'),
          showThemeToggle: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: rc.onBg),
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: _store == null
              ? null
              : IconButton(
                  icon: Icon(
                    _bookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined,
                    color: _bookmarked ? rc.chipActive : rc.onBg,
                  ),
                  tooltip: tx(context, 'kh_bookmark'),
                  onPressed: _toggleBookmark,
                ),
        ),
        const SizedBox(height: 16),
        if (_offline) const KhOfflineBanner(),
        Text(a.title, style: RagaType.title(rc.onBg)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaChip(
              icon: Icons.schedule_outlined,
              label: tx(context, 'kh_min_read',
                  {'n': a.readingMinutes}),
            ),
            if (a.reviewedAt != null)
              _MetaChip(
                icon: Icons.verified_outlined,
                label: tx(context, 'kh_reviewed',
                    {'d': _dateLine(a.reviewedAt!)}),
              ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          radius: 20,
          child: MarkdownBody(
            data: a.contentMd,
            selectable: true,
            styleSheet: _mdStyle(rc),
          ),
        ),
        if (a.tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in a.tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: rc.chipBorder),
                    color: rc.chipInactive,
                  ),
                  child: Text(
                    t.label,
                    style: RagaType.caption(rc.onChipInactive),
                  ),
                ),
            ],
          ),
        ],
        if (a.sources.isNotEmpty) ...[
          const SizedBox(height: 22),
          KhSectionTitle(tx(context, 'kh_sources')),
          for (final s in a.sources) _sourceRow(rc, s),
        ],
        // Explicit "mark done": robust by design — no scroll-position
        // heuristics, one clear tap, idempotent in the store.
        const SizedBox(height: 22),
        RagaButton(
          label: tx(context, _done ? 'kh_completed' : 'kh_mark_done'),
          onPressed: _done || _store == null ? null : _markDone,
        ),
      ],
    );
  }

  Widget _sourceRow(RagaColors rc, KnowledgeSource s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link_outlined,
                size: 20, color: rc.chipActive),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: RagaType.label(rc.onCard)),
                  if (s.publisher.isNotEmpty)
                    Text(s.publisher,
                        style:
                            RagaType.caption(rc.onCardMuted)),
                  const SizedBox(height: 4),
                  SelectableText(
                    s.url,
                    style: RagaType.caption(rc.chipActive),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy_outlined,
                  size: 18, color: rc.onCardMuted),
              tooltip: tx(context, 'kh_copy_link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: s.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(tx(context, 'kh_link_copied')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: rc.chipActive.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: rc.onBgMuted),
          const SizedBox(width: 6),
          Text(label, style: RagaType.caption(rc.onBg)),
        ],
      ),
    );
  }
}
