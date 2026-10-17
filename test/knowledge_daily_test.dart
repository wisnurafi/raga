import 'package:flutter_test/flutter_test.dart';
import 'package:raga/knowledge/knowledge_daily.dart';
import 'package:raga/knowledge/knowledge_models.dart';

KnowledgeArticle _a(String slug) => KnowledgeArticle(
      id: slug,
      slug: slug,
      categoryId: 'c1',
      title: 'Title $slug',
      summary: '',
      contentMd: '',
      readingMinutes: 3,
      featured: false,
    );

void main() {
  final articles = [_a('a'), _a('b'), _a('c'), _a('d'), _a('e')];

  test('returns null for an empty list', () {
    expect(pickOfDay(const [], DateTime(2026, 10, 17)), isNull);
  });

  test('deterministic: same day always yields the same article', () {
    final d = DateTime(2026, 10, 17, 8, 30);
    final first = pickOfDay(articles, d);
    final second = pickOfDay(articles, DateTime(2026, 10, 17, 23, 59));
    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.slug, second!.slug);
  });

  test('always picks an element of the list', () {
    for (var day = 1; day <= 28; day++) {
      final pick = pickOfDay(articles, DateTime(2026, 10, day));
      expect(pick, isNotNull);
      expect(articles.map((a) => a.slug), contains(pick!.slug));
    }
  });

  test('varies across days (not stuck on one article)', () {
    final picks = {
      for (var day = 1; day <= 28; day++)
        pickOfDay(articles, DateTime(2026, 10, day))!.slug,
    };
    expect(picks.length, greaterThan(1));
  });

  test('single article list always returns it', () {
    final one = [_a('only')];
    expect(pickOfDay(one, DateTime(2026, 1, 1))!.slug, 'only');
    expect(pickOfDay(one, DateTime(2027, 5, 9))!.slug, 'only');
  });
}
