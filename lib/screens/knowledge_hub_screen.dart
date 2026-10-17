import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../knowledge/knowledge_daily.dart';
import '../knowledge/knowledge_models.dart';
import '../knowledge/knowledge_progress.dart';
import '../knowledge/knowledge_repository.dart';
import '../knowledge/knowledge_repository_impl.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';
import 'knowledge_article_screen.dart';
import 'knowledge_category_screen.dart';
import 'knowledge_glossary_screen.dart';
import 'knowledge_quiz_screen.dart';
import 'knowledge_widgets.dart';

// Knowledge Hub home: knowledge of the day, search, featured articles,
// recent articles, category cards, bookmarks, quizzes, and a link to
// the glossary. Entry point is the Home card / Health link — never a
// bottom-nav tab.
class KnowledgeHubScreen extends StatefulWidget {
  /// Injected for widget tests; production builds create the real one.
  final KnowledgeRepository? repository;

  const KnowledgeHubScreen({super.key, this.repository});

  @override
  State<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends State<KnowledgeHubScreen> {
  KnowledgeRepository? _repo;
  KnowledgeProgressStore? _store;
  bool _loading = true;
  bool _error = false;
  bool _offline = false;

  List<KnowledgeCategory> _categories = const [];
  List<KnowledgeArticle> _featured = const [];
  List<KnowledgeArticle> _recent = const [];
  List<KnowledgeArticle> _all = const [];
  List<KnowledgeQuiz> _quizzes = const [];

  String _query = '';
  bool _searching = false;
  List<KnowledgeArticle> _searchResults = const [];

  @override
  void initState() {
    super.initState();
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

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      // Bookmarks/progress are local-first: they load even when the
      // network is down, so the sections below never block on Supabase.
      final store = await KnowledgeProgressStore.load();
      final cats = await repo.getCategories();
      final feat = await repo.getFeaturedArticles();
      final recent = await repo.getRecentArticles(limit: 8);
      // Full list (up to 200, cached): resolves bookmarked slugs and
      // feeds the deterministic article-of-the-day pick.
      final all = await repo.searchArticles('');
      final quizzes = await repo.getQuizzes();
      if (!mounted) return;
      setState(() {
        _store = store;
        _categories = cats.data;
        _featured = feat.data;
        _recent = recent.data;
        _all = all.data;
        _quizzes = quizzes.data;
        _offline = cats.offline ||
            feat.offline ||
            recent.offline ||
            all.offline ||
            quizzes.offline;
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

  /// Re-reads local bookmarks/progress after returning from the
  /// article screen (the cloud mirror is best-effort; local is truth).
  Future<void> _refreshStore() async {
    final s = await KnowledgeProgressStore.load();
    if (!mounted) return;
    setState(() => _store = s);
  }

  Future<void> _onSearch(String q) async {
    final repo = _repo;
    if (repo == null) return;
    setState(() {
      _query = q;
      _searching = q.trim().isNotEmpty;
    });
    if (!_searching) return;
    try {
      final res = await repo.searchArticles(q);
      if (!mounted) return;
      // Drop stale responses: only the latest query paints.
      if (q != _query) return;
      setState(() {
        _searchResults = res.data;
        _offline = res.offline;
      });
    } catch (_) {
      if (!mounted || q != _query) return;
      setState(() => _searchResults = const []);
    }
  }

  Future<void> _openArticle(KnowledgeArticle a) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KnowledgeArticleScreen(slug: a.slug),
      ),
    );
    // The article screen may have toggled a bookmark or marked the
    // article done — refresh the local state so sections stay honest.
    await _refreshStore();
  }

  void _openQuiz(KnowledgeQuiz q) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KnowledgeQuizScreen(
          quiz: q,
          repository: _repo,
        ),
      ),
    );
  }

  bool _completed(String slug) => _store?.isCompleted(slug) ?? false;

  /// Bookmarked articles, resolved against the full cached list.
  List<KnowledgeArticle> _bookmarkedArticles() {
    final store = _store;
    if (store == null) return const [];
    final slugs = store.bookmarked.keys.toSet();
    if (slugs.isEmpty) return const [];
    return _all.where((a) => slugs.contains(a.slug)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
            children: [
              RagaHeader(
                title: tx(context, 'kh_title'),
                subtitle: tx(context, 'kh_subtitle'),
                showThemeToggle: false,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: rc.onBg),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 16),
              if (_offline) const KhOfflineBanner(),
              KhSearchField(
                hint: tx(context, 'kh_search_hint'),
                onChanged: _onSearch,
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error)
                KhErrorBlock(onRetry: _load)
              else if (_searching)
                _searchBody(rc)
              else
                _hubBody(rc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBody(RagaColors rc) {
    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            tx(context, 'kh_no_results'),
            style: RagaType.body(rc.onCardMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in _searchResults)
          KnowledgeArticleCard(
            article: a,
            completed: _completed(a.slug),
            onTap: () => _openArticle(a),
          ),
      ],
    );
  }

  Widget _hubBody(RagaColors rc) {
    final empty = _categories.isEmpty &&
        _featured.isEmpty &&
        _recent.isEmpty;
    if (empty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            tx(context, 'kh_empty'),
            style: RagaType.body(rc.onCardMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final daily = pickOfDay(_all, DateTime.now());
    final bookmarked = _bookmarkedArticles();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (daily != null) ...[
          KhSectionTitle(tx(context, 'kh_daily')),
          _dailyHero(context.rc, daily),
          const SizedBox(height: 10),
        ],
        if (bookmarked.isNotEmpty) ...[
          KhSectionTitle(tx(context, 'kh_bookmarks')),
          for (final a in bookmarked)
            KnowledgeArticleCard(
              article: a,
              completed: _completed(a.slug),
              onTap: () => _openArticle(a),
            ),
          const SizedBox(height: 10),
        ],
        if (_featured.isNotEmpty) ...[
          KhSectionTitle(tx(context, 'kh_featured')),
          for (final a in _featured)
            KnowledgeArticleCard(
              article: a,
              completed: _completed(a.slug),
              onTap: () => _openArticle(a),
            ),
          const SizedBox(height: 10),
        ],
        KhSectionTitle(tx(context, 'kh_categories')),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, i) {
            final c = _categories[i];
            return GlassCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => KnowledgeCategoryScreen(
                    category: c,
                    repository: _repo,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 26, color: rc.chipActive),
                  const SizedBox(height: 8),
                  Text(
                    c.title,
                    style: RagaType.label(rc.onCard),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        if (_recent.isNotEmpty) ...[
          KhSectionTitle(tx(context, 'kh_recent')),
          for (final a in _recent)
            KnowledgeArticleCard(
              article: a,
              completed: _completed(a.slug),
              onTap: () => _openArticle(a),
            ),
          const SizedBox(height: 10),
        ],
        if (_quizzes.isNotEmpty) ...[
          KhSectionTitle(tx(context, 'kh_quiz')),
          for (final q in _quizzes) _quizCard(rc, q),
          const SizedBox(height: 10),
        ],
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  KnowledgeGlossaryScreen(repository: _repo),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.spellcheck_outlined,
                  size: 24, color: rc.chipActive),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tx(context, 'kh_glossary'),
                  style: RagaType.cardTitle(rc.onCard),
                ),
              ),
              Icon(Icons.chevron_right, color: rc.onCardMuted),
            ],
          ),
        ),
      ],
    );
  }

  /// Hero card for the deterministic article of the day.
  Widget _dailyHero(RagaColors rc, KnowledgeArticle a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(18),
        onTap: () => _openArticle(a),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rc.chipActive.withValues(alpha: 0.18),
              ),
              child: Icon(
                Icons.wb_sunny_outlined,
                color: rc.chipActive,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: RagaType.cardTitle(rc.onCard),
                  ),
                  if (a.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      a.summary,
                      style: RagaType.caption(rc.onCardMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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

  Widget _quizCard(RagaColors rc, KnowledgeQuiz q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        onTap: () => _openQuiz(q),
        child: Row(
          children: [
            Icon(Icons.quiz_outlined, size: 24, color: rc.chipActive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.title,
                    style: RagaType.cardTitle(rc.onCard),
                  ),
                  if (q.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      q.description,
                      style: RagaType.caption(rc.onCardMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: rc.onCardMuted),
          ],
        ),
      ),
    );
  }
}
