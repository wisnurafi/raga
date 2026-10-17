import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cloud_sync.dart';
import 'knowledge_cache.dart';
import 'knowledge_models.dart';
import 'knowledge_repository.dart';
import 'knowledge_search.dart';

// Cache-first repository over Supabase, locale-aware. Strategy per call:
// - online (CloudSync.isReady): fetch fresh for [locale], persist to the
//   per-locale cache, return it. When the locale has no translations
//   yet (empty result and locale != 'id'), the fetch is retried in 'id'
//   so untranslated content still shows instead of an empty screen.
//   A fetch failure falls back to cache when one exists.
// - offline: return the locale's cache when one exists, else throw
//   KnowledgeException.
// Quiz RPCs always need the network (answers are server-side by design).
class KnowledgeRepositoryImpl implements KnowledgeRepository {
  final KnowledgeCache _cache;

  /// Content locale: 'id' or 'en'. Every query and cache key is scoped
  /// to it; untranslated content falls back to 'id'.
  final String locale;

  KnowledgeRepositoryImpl(this._cache, {this.locale = 'id'});

  /// Production entry point: loads the per-locale SharedPreferences cache.
  static Future<KnowledgeRepositoryImpl> create(
          {String locale = 'id'}) async =>
      KnowledgeRepositoryImpl(
          await KnowledgeCache.load(locale: locale),
          locale: locale);

  /// Fetches [fetch] for [locale]; when the result is empty and the
  /// locale isn't already 'id', retries in 'id'. Pure decision logic,
  /// unit-tested without Supabase.
  static Future<List<T>> fetchListWithFallback<T>(
    String locale,
    Future<List<T>> Function(String locale) fetch,
  ) async {
    final fresh = await fetch(locale);
    if (fresh.isEmpty && locale != 'id') return fetch('id');
    return fresh;
  }

  /// Nullable variant of [fetchListWithFallback] for single-row fetches.
  static Future<T?> fetchOneWithFallback<T>(
    String locale,
    Future<T?> Function(String locale) fetch,
  ) async {
    final one = await fetch(locale);
    if (one == null && locale != 'id') return fetch('id');
    return one;
  }

  bool get _online => CloudSync.isReady;

  SupabaseClient get _db => Supabase.instance.client;

  // Runs [fetch] (locale-aware, with 'id' fallback), caches via [save],
  // and wraps the outcome. Shared by every collection-shaped endpoint.
  Future<KnowledgeLoad<List<T>>> _loadCollection<T>({
    required CachedCollection<T>? Function() readCache,
    required Future<List<T>> Function(String locale) fetch,
    required Future<void> Function(List<T>) save,
  }) async {
    final cached = readCache();
    if (_online) {
      try {
        final fresh =
            await fetchListWithFallback(locale, fetch);
        await save(fresh);
        return KnowledgeLoad(data: fresh);
      } catch (_) {
        // Refresh failed: serve stale cache rather than an error.
        if (cached != null) {
          return KnowledgeLoad(
              data: cached.items, fromCache: true);
        }
        throw const KnowledgeException('kh_error');
      }
    }
    if (cached != null) {
      return KnowledgeLoad(
          data: cached.items, fromCache: true, offline: true);
    }
    throw const KnowledgeException('kh_error');
  }

  List<Map<String, dynamic>> _rows(dynamic res) => ((res as List?) ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  @override
  Future<KnowledgeLoad<List<KnowledgeCategory>>> getCategories() =>
      _loadCollection(
        readCache: _cache.loadCategories,
        save: _cache.saveCategories,
        fetch: (loc) async {
          final res = await _db
              .from('knowledge_categories')
              .select()
              .eq('locale', loc)
              .order('sort_order');
          return _rows(res).map(KnowledgeCategory.fromJson).toList();
        },
      );

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getFeaturedArticles() =>
      _loadCollection(
        readCache: _cache.loadArticles,
        save: _cache.saveArticles,
        fetch: (loc) async {
          final res = await _db
              .from('knowledge_articles')
              .select()
              .eq('status', 'published')
              .eq('locale', loc)
              .eq('featured', true)
              .order('published_at', ascending: false);
          return _rows(res).map(KnowledgeArticle.fromJson).toList();
        },
      );

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getRecentArticles(
          {int limit = 10}) =>
      _loadCollection(
        readCache: _cache.loadArticles,
        save: _cache.saveArticles,
        fetch: (loc) async {
          final res = await _db
              .from('knowledge_articles')
              .select()
              .eq('status', 'published')
              .eq('locale', loc)
              .order('published_at', ascending: false)
              .limit(limit);
          return _rows(res).map(KnowledgeArticle.fromJson).toList();
        },
      );

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getArticlesByCategory(
          String categoryId) =>
      _loadCollection(
        readCache: _cache.loadArticles,
        save: _cache.saveArticles,
        fetch: (loc) async {
          Future<List<KnowledgeArticle>> byCat(
              String l, String catId) async {
            final res = await _db
                .from('knowledge_articles')
                .select()
                .eq('status', 'published')
                .eq('locale', l)
                .eq('category_id', catId)
                .order('published_at', ascending: false);
            return _rows(res).map(KnowledgeArticle.fromJson).toList();
          }

          final list = await byCat(loc, categoryId);
          if (list.isNotEmpty || loc == 'id') return list;
          // Category ids are per-locale: resolve the Indonesian
          // category through the stable slug before retrying, or the
          // 'id' retry below would query a nonexistent category.
          final catRes = await _db
              .from('knowledge_categories')
              .select('slug')
              .eq('id', categoryId)
              .maybeSingle();
          final slug = catRes == null
              ? null
              : (catRes as Map)['slug'] as String?;
          if (slug == null) return list;
          final idCatRes = await _db
              .from('knowledge_categories')
              .select('id')
              .eq('slug', slug)
              .eq('locale', 'id')
              .maybeSingle();
          final idCatId = idCatRes == null
              ? null
              : (idCatRes as Map)['id'] as String?;
          if (idCatId == null) return list;
          return byCat('id', idCatId);
        },
      );

  /// Fetches one article row (with tags/sources) for [slug] in the
  /// given locale. Returns null when the row doesn't exist; throws on
  /// transport errors so the caller can fall back to cache.
  Future<KnowledgeArticle?> _fetchDetail(
      String slug, String loc) async {
    final res = await _db
        .from('knowledge_articles')
        .select()
        .eq('status', 'published')
        .eq('locale', loc)
        .eq('slug', slug)
        .maybeSingle();
    if (res == null) return null;
    final row = Map<String, dynamic>.from(res as Map);
    final article = KnowledgeArticle.fromJson(row);

    // Tags and sources via the join tables (separate queries keep
    // the parsing simple and robust). The article id comes from the
    // fetched row, so joins always match its own locale.
    final tagRows = await _db
        .from('knowledge_article_tags')
        .select('knowledge_tags(*)')
        .eq('article_id', article.id);
    final tags = _rows(tagRows)
        .map((r) => r['knowledge_tags'])
        .whereType<Map>()
        .map((m) =>
            KnowledgeTag.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    final sourceRows = await _db
        .from('knowledge_article_sources')
        .select('sort_order, knowledge_sources(*)')
        .eq('article_id', article.id)
        .order('sort_order');
    final sources = _rows(sourceRows)
        .map((r) => r['knowledge_sources'])
        .whereType<Map>()
        .map((m) =>
            KnowledgeSource.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return article.withDetails(tags: tags, sources: sources);
  }

  @override
  Future<KnowledgeLoad<KnowledgeArticle>> getArticleDetail(String slug) async {
    KnowledgeArticle? fromRows(List<KnowledgeArticle> list) {
      for (final a in list) {
        if (a.slug == slug) return a;
      }
      return null;
    }

    if (_online) {
      try {
        // Slugs are stable across locales: an untranslated article
        // falls back to its Indonesian row rather than an error.
        final article = await fetchOneWithFallback(
            locale, (loc) => _fetchDetail(slug, loc));
        if (article != null) return KnowledgeLoad(data: article);
      } catch (_) {
        // Network or parse failure: fall through to the cached copy.
      }
      final cached = _cache.loadArticles();
      final hit = cached == null ? null : fromRows(cached.items);
      if (hit != null) {
        return KnowledgeLoad(data: hit, fromCache: true);
      }
      throw const KnowledgeException('kh_error');
    }
    final cached = _cache.loadArticles();
    final hit = cached == null ? null : fromRows(cached.items);
    if (hit != null) {
      return KnowledgeLoad(data: hit, fromCache: true, offline: true);
    }
    throw const KnowledgeException('kh_error');
  }

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> searchArticles(
      String query) async {
    // Search always runs over the cached article list: it works offline
    // and stays instant. The list itself is refreshed by the other
    // endpoints' cache-first flow.
    final load = await _loadCollection(
      readCache: _cache.loadArticles,
      save: _cache.saveArticles,
      fetch: (loc) async {
        final res = await _db
            .from('knowledge_articles')
            .select()
            .eq('status', 'published')
            .eq('locale', loc)
            .order('published_at', ascending: false)
            .limit(200);
        return _rows(res).map(KnowledgeArticle.fromJson).toList();
      },
    );
    return KnowledgeLoad(
      data: filterArticles(load.data, query),
      fromCache: load.fromCache,
      offline: load.offline,
    );
  }

  @override
  Future<KnowledgeLoad<List<GlossaryTerm>>> getGlossary(
      {String query = ''}) async {
    final load = await _loadCollection(
      readCache: _cache.loadGlossary,
      save: _cache.saveGlossary,
      fetch: (loc) async {
        final res = await _db
            .from('knowledge_glossary')
            .select()
            .eq('locale', loc)
            .order('term');
        return _rows(res).map(GlossaryTerm.fromJson).toList();
      },
    );
    return KnowledgeLoad(
      data: filterGlossaryTerms(load.data, query),
      fromCache: load.fromCache,
      offline: load.offline,
    );
  }

  @override
  Future<KnowledgeLoad<List<KnowledgeQuiz>>> getQuizzes() =>
      _loadCollection(
        readCache: _cache.loadQuizzes,
        save: _cache.saveQuizzes,
        fetch: (loc) async {
          final res = await _db
              .from('knowledge_quizzes')
              .select()
              .eq('status', 'published')
              .eq('locale', loc)
              .order('published_at', ascending: false);
          return _rows(res).map(KnowledgeQuiz.fromJson).toList();
        },
      );

  Future<List<QuizQuestion>> _rpcQuestions(
      String quizId, String loc) async {
    final res = await _db.rpc('get_quiz_questions', params: {
      'p_quiz_id': quizId,
      'p_locale': loc,
    });
    return _rows(res).map(QuizQuestion.fromJson).toList();
  }

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String quizId) async {
    // Quiz answers live server-side by design: no cache, online only.
    if (!_online) throw const KnowledgeException('kh_error');
    try {
      var qs = await _rpcQuestions(quizId, locale);
      if (qs.isEmpty && locale != 'id') {
        // Quiz ids are per-locale: resolve the Indonesian quiz through
        // the stable slug before retrying.
        final slugRes = await _db
            .from('knowledge_quizzes')
            .select('slug')
            .eq('id', quizId)
            .maybeSingle();
        final slug = slugRes == null
            ? null
            : (slugRes as Map)['slug'] as String?;
        if (slug != null) {
          final idRes = await _db
              .from('knowledge_quizzes')
              .select('id')
              .eq('slug', slug)
              .eq('locale', 'id')
              .eq('status', 'published')
              .maybeSingle();
          final idQuizId = idRes == null
              ? null
              : (idRes as Map)['id'] as String?;
          if (idQuizId != null) qs = await _rpcQuestions(idQuizId, 'id');
        }
      }
      return qs;
    } catch (_) {
      throw const KnowledgeException('kh_error');
    }
  }

  @override
  Future<QuizAnswerResult> submitQuizAnswer(
      String questionId, int chosenIndex) async {
    if (!_online) throw const KnowledgeException('kh_error');
    try {
      final res = await _db.rpc('submit_quiz_answer', params: {
        'p_question_id': questionId,
        'p_chosen_index': chosenIndex,
      });
      // RPC returns a table (list with one row).
      final rows = _rows(res);
      if (rows.isEmpty) throw const KnowledgeException('kh_error');
      return QuizAnswerResult.fromJson(rows.first);
    } catch (_) {
      throw const KnowledgeException('kh_error');
    }
  }
}
