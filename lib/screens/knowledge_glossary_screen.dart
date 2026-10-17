import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../knowledge/knowledge_models.dart';
import '../knowledge/knowledge_repository.dart';
import '../knowledge/knowledge_repository_impl.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';
import 'knowledge_article_screen.dart';
import 'knowledge_widgets.dart';

// Health glossary with search.
class KnowledgeGlossaryScreen extends StatefulWidget {
  /// Injected for tests; production builds create the real one.
  final KnowledgeRepository? repository;

  const KnowledgeGlossaryScreen({super.key, this.repository});

  @override
  State<KnowledgeGlossaryScreen> createState() =>
      _KnowledgeGlossaryScreenState();
}

class _KnowledgeGlossaryScreenState
    extends State<KnowledgeGlossaryScreen> {
  KnowledgeRepository? _repo;
  bool _loading = true;
  bool _error = false;
  bool _offline = false;
  List<GlossaryTerm> _terms = const [];

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repo = widget.repository;
      _load('');
    } else {
      KnowledgeRepositoryImpl.create().then((r) {
        if (!mounted) return;
        _repo = r;
        _load('');
      });
    }
  }

  Future<void> _load(String query) async {
    final repo = _repo;
    if (repo == null) return;
    if (query.isEmpty) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      final res = await repo.getGlossary(query: query);
      if (!mounted) return;
      setState(() {
        _terms = res.data;
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
                title: tx(context, 'kh_glossary'),
                showThemeToggle: false,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: rc.onBg),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 16),
              if (_offline) const KhOfflineBanner(),
              KhSearchField(
                hint: tx(context, 'kh_glossary_hint'),
                onChanged: _load,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error)
                KhErrorBlock(onRetry: () => _load(''))
              else if (_terms.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      tx(context, 'kh_no_results'),
                      style: RagaType.body(rc.onCardMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                for (final t in _terms) _termCard(rc, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _termCard(RagaColors rc, GlossaryTerm t) {
    final linked = t.relatedArticleSlug != null &&
        t.relatedArticleSlug!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        onTap: linked
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KnowledgeArticleScreen(
                        slug: t.relatedArticleSlug!),
                  ),
                )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.term,
                      style: RagaType.cardTitle(rc.onCard)),
                  const SizedBox(height: 4),
                  Text(t.definition,
                      style: RagaType.body(rc.onCardMuted)),
                ],
              ),
            ),
            if (linked) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  color: rc.onCardMuted),
            ],
          ],
        ),
      ),
    );
  }
}
