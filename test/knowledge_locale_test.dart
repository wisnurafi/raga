import 'package:flutter_test/flutter_test.dart';
import 'package:raga/knowledge/knowledge_cache.dart';
import 'package:raga/knowledge/knowledge_daily.dart';
import 'package:raga/knowledge/knowledge_models.dart';
import 'package:raga/knowledge/knowledge_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _idArticle = KnowledgeArticle(
  id: 'a-id',
  slug: 'apa-itu-bmi',
  categoryId: 'c-id',
  title: 'Apa itu BMI',
  summary: '',
  contentMd: '',
  readingMinutes: 3,
  featured: true,
  locale: 'id',
);

const _enArticle = KnowledgeArticle(
  id: 'a-en',
  slug: 'apa-itu-bmi',
  categoryId: 'c-en',
  title: 'What is BMI',
  summary: '',
  contentMd: '',
  readingMinutes: 3,
  featured: true,
  locale: 'en',
);

void main() {
  group('fetchListWithFallback', () {
    test('returns the locale result when non-empty (no id call)', () async {
      var idCalls = 0;
      final got =
          await KnowledgeRepositoryImpl.fetchListWithFallback<String>(
        'en',
        (loc) async {
          if (loc == 'id') idCalls++;
          return loc == 'en' ? ['en-1'] : ['id-1'];
        },
      );
      expect(got, ['en-1']);
      expect(idCalls, 0);
    });

    test('falls back to id when the locale result is empty', () async {
      final calls = <String>[];
      final got =
          await KnowledgeRepositoryImpl.fetchListWithFallback<String>(
        'en',
        (loc) async {
          calls.add(loc);
          return loc == 'en' ? const <String>[] : ['id-1'];
        },
      );
      expect(got, ['id-1']);
      expect(calls, ['en', 'id']);
    });

    test('id locale never retries (no infinite loop)', () async {
      var calls = 0;
      final got =
          await KnowledgeRepositoryImpl.fetchListWithFallback<String>(
        'id',
        (loc) async {
          calls++;
          return const <String>[];
        },
      );
      expect(got, isEmpty);
      expect(calls, 1);
    });
  });

  group('fetchOneWithFallback', () {
    test('falls back to id when the locale row is missing', () async {
      final got =
          await KnowledgeRepositoryImpl.fetchOneWithFallback<String>(
        'en',
        (loc) async => loc == 'en' ? null : 'id-row',
      );
      expect(got, 'id-row');
    });

    test('keeps the locale row when present', () async {
      final got =
          await KnowledgeRepositoryImpl.fetchOneWithFallback<String>(
        'en',
        (loc) async => loc == 'en' ? 'en-row' : 'id-row',
      );
      expect(got, 'en-row');
    });

    test('returns null when both locales miss', () async {
      final got =
          await KnowledgeRepositoryImpl.fetchOneWithFallback<String>(
        'en',
        (_) async => null,
      );
      expect(got, isNull);
    });
  });

  group('KnowledgeCache per-locale keys', () {
    test('en and id caches do not overwrite each other', () async {
      SharedPreferences.setMockInitialValues({});
      final idCache = await KnowledgeCache.load(locale: 'id');
      final enCache = await KnowledgeCache.load(locale: 'en');

      await idCache.saveArticles([_idArticle]);
      await enCache.saveArticles([_enArticle]);

      final idBack = idCache.loadArticles()!;
      final enBack = enCache.loadArticles()!;
      expect(idBack.items.single.id, 'a-id');
      expect(idBack.items.single.locale, 'id');
      expect(enBack.items.single.id, 'a-en');
      expect(enBack.items.single.locale, 'en');

      // Raw keys confirm the separation.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('raga.knowledge.articles'), isTrue);
      expect(
          prefs.containsKey('raga.knowledge.articles.en'), isTrue);
    });

    test('missing locale cache reads as null (not the other locale)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final idCache = await KnowledgeCache.load(locale: 'id');
      await idCache.saveArticles([_idArticle]);

      final enCache = await KnowledgeCache.load(locale: 'en');
      expect(enCache.loadArticles(), isNull);
    });

    test('clear() wipes every locale', () async {
      SharedPreferences.setMockInitialValues({});
      final idCache = await KnowledgeCache.load(locale: 'id');
      final enCache = await KnowledgeCache.load(locale: 'en');
      await idCache.saveArticles([_idArticle]);
      await enCache.saveArticles([_enArticle]);

      await idCache.clear();
      expect(idCache.loadArticles(), isNull);
      expect(enCache.loadArticles(), isNull);
    });
  });

  group('pickOfDay is locale-agnostic', () {
    test('deterministic for the same list and date', () {
      final date = DateTime(2026, 10, 17);
      final idList = [_idArticle, _enArticle];
      expect(pickOfDay(idList, date)?.slug,
          pickOfDay(idList, date)?.slug);
    });

    test('same slug picked from either locale list for a date', () {
      // The function is pure: given equivalent lists it behaves
      // identically no matter which language the app is in.
      final date = DateTime(2026, 10, 18);
      final a = pickOfDay([_idArticle], date);
      final b = pickOfDay([_enArticle], date);
      expect(a?.slug, b?.slug);
      expect(a?.locale, 'id');
      expect(b?.locale, 'en');
    });

    test('empty list returns null', () {
      expect(pickOfDay(const [], DateTime(2026, 10, 17)), isNull);
    });
  });
}
