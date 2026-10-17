import 'package:flutter_test/flutter_test.dart';
import 'package:raga/knowledge/knowledge_models.dart';
import 'package:raga/knowledge/knowledge_search.dart';

KnowledgeArticle _a(String id, String title, String summary, String body) =>
    KnowledgeArticle(
      id: id,
      slug: id,
      categoryId: 'c1',
      title: title,
      summary: summary,
      contentMd: body,
      readingMinutes: 3,
      featured: false,
    );

void main() {
  final articles = [
    _a('1', 'Apa itu BMI', 'Indeks massa tubuh',
        'BMI dihitung dari berat dan tinggi badan.'),
    _a('2', 'Protein untuk Pemula', 'Fondasi otot',
        'Protein membantu pemulihan setelah latihan.'),
    _a('3', 'Tidur dan Berat Badan', 'Istirahat cukup',
        'Kurang tidur mengacaukan hormon lapar.'),
  ];

  group('filterArticles', () {
    test('matches title', () {
      expect(filterArticles(articles, 'protein').single.id, '2');
    });

    test('matches summary', () {
      expect(filterArticles(articles, 'massa tubuh').single.id, '1');
    });

    test('matches body content', () {
      expect(filterArticles(articles, 'hormon lapar').single.id, '3');
    });

    test('is case-insensitive', () {
      expect(filterArticles(articles, 'BMI').single.id, '1');
      expect(filterArticles(articles, 'bmi').single.id, '1');
    });

    test('empty query returns everything', () {
      expect(filterArticles(articles, ''), hasLength(3));
      expect(filterArticles(articles, '   '), hasLength(3));
    });

    test('no match returns empty', () {
      expect(filterArticles(articles, 'kalkulus'), isEmpty);
    });
  });

  group('filterGlossaryTerms', () {
    final terms = [
      const GlossaryTerm(
          id: 'g1', term: 'BMR', definition: 'Basal Metabolic Rate'),
      const GlossaryTerm(
          id: 'g2', term: 'TDEE', definition: 'Total Daily Energy Expenditure'),
    ];

    test('matches term', () {
      expect(filterGlossaryTerms(terms, 'bmr').single.id, 'g1');
    });

    test('matches definition', () {
      expect(
          filterGlossaryTerms(terms, 'energy expenditure').single.id,
          'g2');
    });

    test('empty query returns everything', () {
      expect(filterGlossaryTerms(terms, ''), hasLength(2));
    });
  });
}
