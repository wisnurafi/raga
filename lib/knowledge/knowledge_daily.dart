import 'knowledge_models.dart';

// Deterministic "article of the day": the same calendar day always
// yields the same article, with no server call and no stored state.
// Pure and unit-tested.
KnowledgeArticle? pickOfDay(
    List<KnowledgeArticle> articles, DateTime date) {
  if (articles.isEmpty) return null;
  final key = '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return articles[h % articles.length];
}
