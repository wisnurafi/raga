// Pure search/filter helpers for the Knowledge Hub. Deliberately free
// of Supabase, widgets, or singletons so they stay unit-testable.

import 'knowledge_models.dart';

/// Case-insensitive substring match across title, summary, and the
/// markdown body. Empty/blank queries return the input untouched.
List<KnowledgeArticle> filterArticles(
    List<KnowledgeArticle> articles, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return articles;
  return articles.where((a) {
    return a.title.toLowerCase().contains(q) ||
        a.summary.toLowerCase().contains(q) ||
        a.contentMd.toLowerCase().contains(q);
  }).toList();
}

/// Case-insensitive substring match across term and definition.
List<GlossaryTerm> filterGlossaryTerms(
    List<GlossaryTerm> terms, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return terms;
  return terms.where((t) {
    return t.term.toLowerCase().contains(q) ||
        t.definition.toLowerCase().contains(q);
  }).toList();
}
