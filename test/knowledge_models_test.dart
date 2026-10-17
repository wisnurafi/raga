import 'package:flutter_test/flutter_test.dart';
import 'package:raga/knowledge/knowledge_models.dart';

void main() {
  group('KnowledgeCategory', () {
    test('fromJson/toJson round-trip', () {
      const c = KnowledgeCategory(
        id: 'c1',
        slug: 'bmi-academy',
        title: 'BMI Academy',
        description: 'desc',
        sortOrder: 2,
      );
      final back = KnowledgeCategory.fromJson(c.toJson());
      expect(back.id, 'c1');
      expect(back.slug, 'bmi-academy');
      expect(back.title, 'BMI Academy');
      expect(back.description, 'desc');
      expect(back.sortOrder, 2);
      // Locale defaults to 'id' when the key is absent (pre-i18n rows).
      expect(back.locale, 'id');
    });

    test('locale round-trips when present', () {
      const c = KnowledgeCategory(
        id: 'c2',
        slug: 'bmi-academy',
        title: 'BMI Academy',
        description: '',
        sortOrder: 0,
        locale: 'en',
      );
      final back = KnowledgeCategory.fromJson(c.toJson());
      expect(back.locale, 'en');
    });
  });

  group('KnowledgeArticle', () {
    test('fromJson parses a Supabase row, toJson round-trips', () {
      final row = {
        'id': 'a1',
        'slug': 'apa-itu-bmi',
        'category_id': 'c1',
        'title': 'Apa itu BMI',
        'summary': 'ringkasan',
        'content_md': '# Halo\n\nIsi.',
        'cover_image_url': null,
        'reading_minutes': 5,
        'featured': true,
        'published_at': '2026-10-17T10:00:00Z',
        'reviewed_at': '2026-10-16T00:00:00Z',
      };
      final a = KnowledgeArticle.fromJson(row);
      expect(a.id, 'a1');
      expect(a.slug, 'apa-itu-bmi');
      expect(a.coverImageUrl, isNull);
      expect(a.readingMinutes, 5);
      expect(a.featured, isTrue);
      expect(a.publishedAt?.year, 2026);
      expect(a.reviewedAt?.day, 16);
      expect(a.tags, isEmpty);
      expect(a.sources, isEmpty);

      final back = KnowledgeArticle.fromJson(a.toJson());
      expect(back.title, 'Apa itu BMI');
      expect(back.contentMd, '# Halo\n\nIsi.');
      expect(back.publishedAt?.toIso8601String(),
          a.publishedAt?.toIso8601String());
    });

    test('withDetails attaches tags and sources', () {
      const a = KnowledgeArticle(
        id: 'a1',
        slug: 's',
        categoryId: 'c1',
        title: 'T',
        summary: '',
        contentMd: '',
        readingMinutes: 3,
        featured: false,
      );
      const tag = KnowledgeTag(id: 't1', slug: 'bmi', label: 'BMI');
      const src = KnowledgeSource(
        id: 's1',
        title: 'WHO',
        publisher: 'WHO',
        url: 'https://who.int',
      );
      final detailed =
          a.withDetails(tags: [tag], sources: [src]);
      expect(detailed.tags.single.label, 'BMI');
      expect(detailed.sources.single.publisher, 'WHO');
      // Original untouched.
      expect(a.tags, isEmpty);
    });

    test('fromJson tolerates missing optional keys', () {
      final a = KnowledgeArticle.fromJson({
        'id': 'a2',
        'slug': 's2',
        'title': 'T2',
      });
      expect(a.summary, '');
      expect(a.contentMd, '');
      expect(a.readingMinutes, 0);
      expect(a.featured, isFalse);
      expect(a.publishedAt, isNull);
      expect(a.locale, 'id');
    });

    test('locale survives round-trip and withDetails', () {
      const a = KnowledgeArticle(
        id: 'a3',
        slug: 's3',
        categoryId: 'c1',
        title: 'T',
        summary: '',
        contentMd: '',
        readingMinutes: 3,
        featured: false,
        locale: 'en',
      );
      final back = KnowledgeArticle.fromJson(a.toJson());
      expect(back.locale, 'en');
      expect(a.withDetails().locale, 'en');
    });
  });

  group('GlossaryTerm', () {
    test('round-trip', () {
      const g = GlossaryTerm(
        id: 'g1',
        term: 'BMR',
        definition: 'Basal Metabolic Rate...',
        relatedArticleSlug: 'apa-itu-bmr',
      );
      final back = GlossaryTerm.fromJson(g.toJson());
      expect(back.term, 'BMR');
      expect(back.relatedArticleSlug, 'apa-itu-bmr');
      expect(back.locale, 'id');
    });
  });

  group('KnowledgeQuiz locale', () {
    test('round-trips, defaults to id', () {
      const q = KnowledgeQuiz(
        id: 'z1',
        slug: 'kuis-bmi',
        title: 'Kuis',
        description: '',
        locale: 'en',
      );
      final back = KnowledgeQuiz.fromJson(q.toJson());
      expect(back.locale, 'en');
      expect(
        KnowledgeQuiz.fromJson(
            {'id': 'z2', 'slug': 's', 'title': 'T'}).locale,
        'id',
      );
    });
  });

  group('QuizQuestion / QuizAnswerResult', () {
    test('question has no answer fields', () {
      final q = QuizQuestion.fromJson({
        'id': 'q1',
        'quiz_id': 'z1',
        'sort_order': 0,
        'prompt': 'BMI singkatan dari?',
        'options': ['Body Mass Index', 'Basic Metabolic Info'],
        // Even if the server ever leaked these, the model ignores them.
        'correct_index': 0,
        'explanation': 'leaked',
      });
      expect(q.prompt, 'BMI singkatan dari?');
      expect(q.options, hasLength(2));
      final json = q.toJson();
      expect(json.containsKey('correct_index'), isFalse);
      expect(json.containsKey('explanation'), isFalse);
    });

    test('answer result parses', () {
      final r = QuizAnswerResult.fromJson({
        'correct': true,
        'correct_index': 0,
        'explanation': 'Betul!',
      });
      expect(r.correct, isTrue);
      expect(r.explanation, 'Betul!');
    });
  });
}
