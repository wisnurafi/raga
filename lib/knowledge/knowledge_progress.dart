import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';
import '../data/cloud_sync.dart';

// Local-first bookmark + reading-progress store for the Knowledge Hub.
// SharedPreferences is the source of truth — it works for every user,
// logged in or not, and fully offline. When a Google account is linked
// and Supabase is reachable, writes are mirrored best-effort to the
// per-user tables (RLS-locked to auth.uid()). A sync failure never
// surfaces in the UI: the local state is always what the user sees.
class KnowledgeProgressStore {
  static const _kBookmarks = 'raga.knowledge.bookmarks';
  static const _kProgress = 'raga.knowledge.progress';

  final SharedPreferences _prefs;

  KnowledgeProgressStore(this._prefs);

  static Future<KnowledgeProgressStore> load() async =>
      KnowledgeProgressStore(await SharedPreferences.getInstance());

  Map<String, String> _map(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map)
          .map((k, v) => MapEntry(k as String, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(String key, Map<String, String> m) =>
      _prefs.setString(key, jsonEncode(m));

  /// slug -> article id, so the cloud sync can resolve the uuid.
  Map<String, String> get bookmarked => _map(_kBookmarks);

  bool isBookmarked(String slug) => bookmarked.containsKey(slug);

  /// slug -> article id for finished articles.
  Map<String, String> get completed => _map(_kProgress);

  bool isCompleted(String slug) => completed.containsKey(slug);

  /// Toggles a bookmark. Fire-and-forget cloud mirror on success.
  Future<void> toggleBookmark(
      {required String slug, required String articleId}) async {
    final m = bookmarked;
    final adding = !m.containsKey(slug);
    if (adding) {
      m[slug] = articleId;
    } else {
      m.remove(slug);
    }
    await _save(_kBookmarks, m);
    // Best-effort: local state already persisted above.
    _syncBookmark(articleId, adding);
  }

  /// Marks an article finished. Idempotent.
  Future<void> markCompleted(
      {required String slug, required String articleId}) async {
    final m = completed;
    if (m.containsKey(slug)) return;
    m[slug] = articleId;
    await _save(_kProgress, m);
    // Best-effort: local state already persisted above.
    _syncProgress(articleId);
  }

  bool get _canSync =>
      AuthService.instance.isLoggedIn &&
      CloudSync.isReady &&
      AuthService.instance.userId != null;

  Future<void> _syncBookmark(String articleId, bool adding) async {
    try {
      if (!_canSync) return;
      final uid = AuthService.instance.userId!;
      final db = Supabase.instance.client;
      if (adding) {
        await db.from('user_knowledge_bookmarks').insert({
          'user_id': uid,
          'article_id': articleId,
        });
      } else {
        await db
            .from('user_knowledge_bookmarks')
            .delete()
            .eq('user_id', uid)
            .eq('article_id', articleId);
      }
    } catch (_) {
      // Best-effort only: a duplicate insert or a dropped connection
      // just means this device stays the source of truth.
    }
  }

  Future<void> _syncProgress(String articleId) async {
    try {
      if (!_canSync) return;
      final uid = AuthService.instance.userId!;
      await Supabase.instance.client
          .from('user_knowledge_progress')
          .upsert(
        {
          'user_id': uid,
          'article_id': articleId,
          'completed': true,
        },
        onConflict: 'user_id,article_id',
      );
    } catch (_) {
      // Best-effort only — see _syncBookmark.
    }
  }
}
