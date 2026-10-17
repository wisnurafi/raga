import 'knowledge_models.dart';

// A load result plus where it came from. The UI shows an offline banner
// when [fromCache] is true and [offline] is true; a silent cache serve
// (refresh failed but we were online) only sets [fromCache].
class KnowledgeLoad<T> {
  final T data;
  final bool fromCache;
  final bool offline;

  const KnowledgeLoad({
    required this.data,
    this.fromCache = false,
    this.offline = false,
  });
}

/// Thrown when content can't be served from cache or Supabase.
class KnowledgeException implements Exception {
  final String message;
  const KnowledgeException(this.message);

  @override
  String toString() => 'KnowledgeException: $message';
}

// The only way the UI touches Knowledge Hub data. Screens must never
// query Supabase or SharedPreferences directly.
abstract class KnowledgeRepository {
  Future<KnowledgeLoad<List<KnowledgeCategory>>> getCategories();
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getFeaturedArticles();
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getRecentArticles(
      {int limit = 10});
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getArticlesByCategory(
      String categoryId);
  Future<KnowledgeLoad<KnowledgeArticle>> getArticleDetail(String slug);
  Future<KnowledgeLoad<List<KnowledgeArticle>>> searchArticles(String query);
  Future<KnowledgeLoad<List<GlossaryTerm>>> getGlossary({String query = ''});
  Future<KnowledgeLoad<List<KnowledgeQuiz>>> getQuizzes();
  Future<List<QuizQuestion>> getQuizQuestions(String quizId);
  Future<QuizAnswerResult> submitQuizAnswer(
      String questionId, int chosenIndex);
}
