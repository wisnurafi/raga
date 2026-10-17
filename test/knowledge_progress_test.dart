import 'package:flutter_test/flutter_test.dart';
import 'package:raga/knowledge/knowledge_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<KnowledgeProgressStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return KnowledgeProgressStore.load();
}

void main() {
  test('bookmark toggle adds then removes', () async {
    final s = await _store();
    expect(s.isBookmarked('apa-itu-bmi'), isFalse);

    await s.toggleBookmark(slug: 'apa-itu-bmi', articleId: 'id-1');
    expect(s.isBookmarked('apa-itu-bmi'), isTrue);
    expect(s.bookmarked['apa-itu-bmi'], 'id-1');

    await s.toggleBookmark(slug: 'apa-itu-bmi', articleId: 'id-1');
    expect(s.isBookmarked('apa-itu-bmi'), isFalse);
  });

  test('bookmarks persist across store instances', () async {
    SharedPreferences.setMockInitialValues({});
    final s1 = await KnowledgeProgressStore.load();
    await s1.toggleBookmark(slug: 'a', articleId: 'id-a');
    await s1.toggleBookmark(slug: 'b', articleId: 'id-b');

    final s2 = await KnowledgeProgressStore.load();
    expect(s2.isBookmarked('a'), isTrue);
    expect(s2.isBookmarked('b'), isTrue);
    expect(s2.bookmarked['b'], 'id-b');
  });

  test('markCompleted is idempotent and persists', () async {
    final s = await _store();
    expect(s.isCompleted('x'), isFalse);

    await s.markCompleted(slug: 'x', articleId: 'id-x');
    expect(s.isCompleted('x'), isTrue);
    // Second call is a no-op, never throws.
    await s.markCompleted(slug: 'x', articleId: 'id-x');
    expect(s.isCompleted('x'), isTrue);

    final s2 = await KnowledgeProgressStore.load();
    expect(s2.isCompleted('x'), isTrue);
  });

  test('corrupt json reads as empty, never crashes', () async {
    SharedPreferences.setMockInitialValues({
      'raga.knowledge.bookmarks': 'not-json{{{',
      'raga.knowledge.progress': '[1,2,3]',
    });
    final s = await KnowledgeProgressStore.load();
    expect(s.bookmarked, isEmpty);
    expect(s.completed, isEmpty);
    expect(s.isBookmarked('a'), isFalse);
  });

  test('sync is a silent no-op when logged out', () async {
    // No Supabase session in tests: toggle/mark must not throw even
    // though the cloud mirror is attempted fire-and-forget.
    final s = await _store();
    await s.toggleBookmark(slug: 'a', articleId: 'id-a');
    await s.markCompleted(slug: 'a', articleId: 'id-a');
    expect(s.isBookmarked('a'), isTrue);
    expect(s.isCompleted('a'), isTrue);
  });
}
