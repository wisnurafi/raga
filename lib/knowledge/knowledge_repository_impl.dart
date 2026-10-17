import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cloud_sync.dart';
import 'knowledge_cache.dart';
import 'knowledge_models.dart';
import 'knowledge_repository.dart';
import 'knowledge_search.dart';

// Cache-first repository over Supabase. Strategy per call:
// - online (CloudSync.isReady): fetch fresh, persist to cache, return it.
//   A fetch failure falls back to cache when one exists.
// - offline: return cache when one exists, else throw KnowledgeException.
// Quiz RPCs always need the network (answers are server-side by design).
class KnowledgeRepositoryImpl implements KnowledgeRepository {
  final KnowledgeCache _cache;

  KnowledgeRepositoryImpl(this._cache);

  /// Production entry point: loads the SharedPreferences cache.
  static Future<KnowledgeRepositoryImpl> create() async =>
      KnowledgeRepositoryImpl(await KnowledgeCache.load());

  bool get _online => CloudSync.isReady;

  SupabaseClient get _db => Supabase.instance.client;

  // Runs [fetch], caches via [save], and wraps the outcome. Shared by
  // every collection-shaped endpoint.
  Future<KnowledgeLoad<List<T>>> _loadCollection<T>({
    required CachedCollection<T>? Function() readCache,
    required Future<List<T>> Function() fetch,
    required Future<void> Function(List<T>) save,
  }) async {
    final cached = readCache();
    if (_online) {
      try {
        final fresh = await fetch();
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
        fetch: () async {
          final res = await _db
              .from('knowledge_categories')
              .select()
              .order('sort_order');
          return _rows(res).map(KnowledgeCategory.fromJson).toList();
        },
      );

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getFeaturedArticles() =>
      _loadCollection(
        readCache: _cache.loadArticles,
        save: _cache.saveArticles,
        fetch: () async {
          final res = await _db
              .from('knowledge_articles')
              .select()
              .eq('status', 'published')
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
        fetch: () async {
          final res = await _db
              .from('knowledge_articles')
              .select()
              .eq('status', 'published')
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
        fetch: () async {
          final res = await _db
              .from('knowledge_articles')
              .select()
              .eq('status', 'published')
              .eq('category_id', categoryId)
              .order('published_at', ascending: false);
          return _rows(res).map(KnowledgeArticle.fromJson).toList();
        },
      );

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
        final res = await _db
            .from('knowledge_articles')
            .select()
            .eq('status', 'published')
            .eq('slug', slug)
            .maybeSingle();
        if (res == null) throw const KnowledgeException('kh_error');
        final row = Map<String, dynamic>.from(res as Map);
        final article = KnowledgeArticle.fromJson(row);

        // Tags and sources via the join tables (separate queries keep
        // the parsing simple and robust).
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

        return KnowledgeLoad(
            data: article.withDetails(tags: tags, sources: sources));
      } catch (_) {
        // Network or parse failure: fall back to the cached copy.
        final cached = _cache.loadArticles();
        final hit = cached == null ? null : fromRows(cached.items);
        if (hit != null) {
          return KnowledgeLoad(data: hit, fromCache: true);
        }
        throw const KnowledgeException('kh_error');
      }
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
      fetch: () async {
        final res = await _db
            .from('knowledge_articles')
            .select()
            .eq('status', 'published')
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
      fetch: () async {
        final res =
            await _db.from('knowledge_glossary').select().order('term');
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
        fetch: () async {
          final res = await _db
              .from('knowledge_quizzes')
              .select()
              .eq('status', 'published')
              .order('published_at', ascending: false);
          return _rows(res).map(KnowledgeQuiz.fromJson).toList();
        },
      );

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String quizId) async {
    // Quiz answers live server-side by design: no cache, online only.
    if (!_online) throw const KnowledgeException('kh_error');
    try {
      final res = await _db.rpc('get_quiz_questions', params: {
        'p_quiz_id': quizId,
      });
      return _rows(res).map(QuizQuestion.fromJson).toList();
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
