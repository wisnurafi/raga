// Data models for the Knowledge Hub. JSON shapes mirror the Supabase
// tables in supabase/migrations/20261017_knowledge_hub.sql (snake_case).
// fromJson reads server rows; toJson writes the local SharedPreferences
// cache — both directions are unit-tested.

/// Article category (e.g. "BMI Academy").
class KnowledgeCategory {
  final String id;
  final String slug;
  final String title;
  final String description;
  final int sortOrder;

  const KnowledgeCategory({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.sortOrder,
  });

  factory KnowledgeCategory.fromJson(Map<String, dynamic> j) =>
      KnowledgeCategory(
        id: j['id'] as String,
        slug: j['slug'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'description': description,
        'sort_order': sortOrder,
      };
}

/// Tag attached to articles (many-to-many).
class KnowledgeTag {
  final String id;
  final String slug;
  final String label;

  const KnowledgeTag({
    required this.id,
    required this.slug,
    required this.label,
  });

  factory KnowledgeTag.fromJson(Map<String, dynamic> j) => KnowledgeTag(
        id: j['id'] as String,
        slug: j['slug'] as String,
        label: j['label'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'label': label,
      };
}

/// A cited reference (WHO, CDC, NHS, journals...).
class KnowledgeSource {
  final String id;
  final String title;
  final String publisher;
  final String url;

  const KnowledgeSource({
    required this.id,
    required this.title,
    required this.publisher,
    required this.url,
  });

  factory KnowledgeSource.fromJson(Map<String, dynamic> j) => KnowledgeSource(
        id: j['id'] as String,
        title: j['title'] as String,
        publisher: (j['publisher'] as String?) ?? '',
        url: j['url'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'publisher': publisher,
        'url': url,
      };
}

/// A published article. Tags and sources are only populated by
/// [KnowledgeRepository.getArticleDetail]; list endpoints leave them
/// empty to keep payloads small.
class KnowledgeArticle {
  final String id;
  final String slug;
  final String categoryId;
  final String title;
  final String summary;
  final String contentMd;
  final String? coverImageUrl;
  final int readingMinutes;
  final bool featured;
  final DateTime? publishedAt;
  final DateTime? reviewedAt;
  final List<KnowledgeTag> tags;
  final List<KnowledgeSource> sources;

  const KnowledgeArticle({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.contentMd,
    this.coverImageUrl,
    required this.readingMinutes,
    required this.featured,
    this.publishedAt,
    this.reviewedAt,
    this.tags = const [],
    this.sources = const [],
  });

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v as String);
  }

  factory KnowledgeArticle.fromJson(Map<String, dynamic> j) =>
      KnowledgeArticle(
        id: j['id'] as String,
        slug: j['slug'] as String,
        categoryId: (j['category_id'] as String?) ?? '',
        title: j['title'] as String,
        summary: (j['summary'] as String?) ?? '',
        contentMd: (j['content_md'] as String?) ?? '',
        coverImageUrl: j['cover_image_url'] as String?,
        readingMinutes: (j['reading_minutes'] as num?)?.toInt() ?? 0,
        featured: (j['featured'] as bool?) ?? false,
        publishedAt: _dt(j['published_at']),
        reviewedAt: _dt(j['reviewed_at']),
        tags: ((j['tags'] as List?) ?? [])
            .map((e) =>
                KnowledgeTag.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        sources: ((j['sources'] as List?) ?? [])
            .map((e) =>
                KnowledgeSource.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'category_id': categoryId,
        'title': title,
        'summary': summary,
        'content_md': contentMd,
        'cover_image_url': coverImageUrl,
        'reading_minutes': readingMinutes,
        'featured': featured,
        'published_at': publishedAt?.toIso8601String(),
        'reviewed_at': reviewedAt?.toIso8601String(),
        'tags': tags.map((t) => t.toJson()).toList(),
        'sources': sources.map((s) => s.toJson()).toList(),
      };

  /// Copy with tags/sources attached (used by getArticleDetail).
  KnowledgeArticle withDetails({
    List<KnowledgeTag>? tags,
    List<KnowledgeSource>? sources,
  }) =>
      KnowledgeArticle(
        id: id,
        slug: slug,
        categoryId: categoryId,
        title: title,
        summary: summary,
        contentMd: contentMd,
        coverImageUrl: coverImageUrl,
        readingMinutes: readingMinutes,
        featured: featured,
        publishedAt: publishedAt,
        reviewedAt: reviewedAt,
        tags: tags ?? this.tags,
        sources: sources ?? this.sources,
      );
}

/// A glossary entry.
class GlossaryTerm {
  final String id;
  final String term;
  final String definition;
  final String? relatedArticleSlug;

  const GlossaryTerm({
    required this.id,
    required this.term,
    required this.definition,
    this.relatedArticleSlug,
  });

  factory GlossaryTerm.fromJson(Map<String, dynamic> j) => GlossaryTerm(
        id: j['id'] as String,
        term: j['term'] as String,
        definition: j['definition'] as String,
        relatedArticleSlug: j['related_article_slug'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'term': term,
        'definition': definition,
        'related_article_slug': relatedArticleSlug,
      };
}

/// A quiz (questions are fetched separately, without answers).
class KnowledgeQuiz {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String? articleId;

  const KnowledgeQuiz({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.articleId,
  });

  factory KnowledgeQuiz.fromJson(Map<String, dynamic> j) => KnowledgeQuiz(
        id: j['id'] as String,
        slug: j['slug'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        articleId: j['article_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'description': description,
        'article_id': articleId,
      };
}

/// A quiz question WITHOUT the answer: this is exactly what the
/// get_quiz_questions RPC returns, so the key never reaches the client
/// before submit.
class QuizQuestion {
  final String id;
  final String quizId;
  final int sortOrder;
  final String prompt;
  final List<String> options;

  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.sortOrder,
    required this.prompt,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        quizId: j['quiz_id'] as String,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        prompt: j['prompt'] as String,
        options: ((j['options'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'quiz_id': quizId,
        'sort_order': sortOrder,
        'prompt': prompt,
        'options': options,
      };
}

/// Result of submit_quiz_answer: graded on the server.
class QuizAnswerResult {
  final bool correct;
  final int correctIndex;
  final String explanation;

  const QuizAnswerResult({
    required this.correct,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizAnswerResult.fromJson(Map<String, dynamic> j) =>
      QuizAnswerResult(
        correct: (j['correct'] as bool?) ?? false,
        correctIndex: (j['correct_index'] as num?)?.toInt() ?? 0,
        explanation: (j['explanation'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'correct': correct,
        'correct_index': correctIndex,
        'explanation': explanation,
      };
}
