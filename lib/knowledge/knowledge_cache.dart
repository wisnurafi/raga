import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'knowledge_models.dart';

// Local cache for Knowledge Hub content. SharedPreferences (JSON), the
// same persistence the rest of Raga uses — no new database dependency.
// Each collection stores its items plus a fetchedAt timestamp so the UI
// can tell fresh content from stale cache.
//
// Cache keys are per-locale ('id' keeps the historical key, other
// locales get a suffix) so switching languages never serves the wrong
// language's content from cache.
class KnowledgeCache {
  static const _kCategories = 'raga.knowledge.categories';
  static const _kArticles = 'raga.knowledge.articles';
  static const _kGlossary = 'raga.knowledge.glossary';
  static const _kQuizzes = 'raga.knowledge.quizzes';

  final SharedPreferences _prefs;
  final String locale;

  KnowledgeCache(this._prefs, {this.locale = 'id'});

  static Future<KnowledgeCache> load({String locale = 'id'}) async =>
      KnowledgeCache(await SharedPreferences.getInstance(),
          locale: locale);

  String _key(String base) => locale == 'id' ? base : '$base.$locale';

  String? _raw(String key) => _prefs.getString(key);

  Future<void> _save(String key, List<Map<String, dynamic>> items) =>
      _prefs.setString(
        key,
        jsonEncode({
          'fetchedAt': DateTime.now().toIso8601String(),
          'items': items,
        }),
      );

  CachedCollection<T>? _load<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _raw(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = ((map['items'] as List?) ?? [])
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final fetchedAt =
          DateTime.tryParse((map['fetchedAt'] as String?) ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
      return CachedCollection(items: items, fetchedAt: fetchedAt);
    } catch (_) {
      // Corrupt cache reads as empty — the repository then falls back
      // to a network refresh or an error state, never a crash.
      return null;
    }
  }

  Future<void> saveCategories(List<KnowledgeCategory> v) =>
      _save(_key(_kCategories), v.map((e) => e.toJson()).toList());
  CachedCollection<KnowledgeCategory>? loadCategories() =>
      _load(_key(_kCategories), KnowledgeCategory.fromJson);

  Future<void> saveArticles(List<KnowledgeArticle> v) =>
      _save(_key(_kArticles), v.map((e) => e.toJson()).toList());
  CachedCollection<KnowledgeArticle>? loadArticles() =>
      _load(_key(_kArticles), KnowledgeArticle.fromJson);

  Future<void> saveGlossary(List<GlossaryTerm> v) =>
      _save(_key(_kGlossary), v.map((e) => e.toJson()).toList());
  CachedCollection<GlossaryTerm>? loadGlossary() =>
      _load(_key(_kGlossary), GlossaryTerm.fromJson);

  Future<void> saveQuizzes(List<KnowledgeQuiz> v) =>
      _save(_key(_kQuizzes), v.map((e) => e.toJson()).toList());
  CachedCollection<KnowledgeQuiz>? loadQuizzes() =>
      _load(_key(_kQuizzes), KnowledgeQuiz.fromJson);

  /// Clears every Knowledge Hub cache entry across all locales (used
  /// by tests and any future "clear cache" affordance).
  Future<void> clear() async {
    for (final k in _prefs.getKeys()) {
      if (k.startsWith('raga.knowledge.')) await _prefs.remove(k);
    }
  }
}

/// A cached collection plus when it was fetched.
class CachedCollection<T> {
  final List<T> items;
  final DateTime fetchedAt;

  const CachedCollection({required this.items, required this.fetchedAt});
}
