import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../knowledge/knowledge_models.dart';
import '../knowledge/knowledge_repository.dart';
import '../knowledge/knowledge_repository_impl.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';
import 'knowledge_article_screen.dart';
import 'knowledge_widgets.dart';

// Articles inside one category.
class KnowledgeCategoryScreen extends StatefulWidget {
  final KnowledgeCategory category;

  /// Injected for tests / reuse; built lazily in production.
  final KnowledgeRepository? repository;

  const KnowledgeCategoryScreen({
    super.key,
    required this.category,
    this.repository,
  });

  @override
  State<KnowledgeCategoryScreen> createState() =>
      _KnowledgeCategoryScreenState();
}

class _KnowledgeCategoryScreenState
    extends State<KnowledgeCategoryScreen> {
  KnowledgeRepository? _repo;
  bool _loading = true;
  bool _error = false;
  bool _offline = false;
  List<KnowledgeArticle> _articles = const [];

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
      final res =
          await repo.getArticlesByCategory(widget.category.id);
      if (!mounted) return;
      setState(() {
        _articles = res.data;
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
                title: widget.category.title,
                showThemeToggle: false,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: rc.onBg),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 16),
              if (_offline) const KhOfflineBanner(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error)
                KhErrorBlock(onRetry: _load)
              else if (_articles.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      tx(context, 'kh_empty'),
                      style: RagaType.body(rc.onCardMuted),
                    ),
                  ),
                )
              else
                for (final a in _articles)
                  KnowledgeArticleCard(
                    article: a,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            KnowledgeArticleScreen(slug: a.slug),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
