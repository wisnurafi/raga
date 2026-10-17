import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/theme.dart';
import 'package:raga/knowledge/knowledge_models.dart';
import 'package:raga/knowledge/knowledge_repository.dart';
import 'package:raga/screens/knowledge_hub_screen.dart';
import 'package:raga/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake repository: canned data, controllable failure, optional hang for
// the loading-state test.
class FakeKnowledgeRepository implements KnowledgeRepository {
  final List<KnowledgeCategory> categories;
  final List<KnowledgeArticle> featured;
  final List<KnowledgeArticle> recent;
  final bool fail;
  final bool hang;

  FakeKnowledgeRepository({
    this.categories = const [],
    this.featured = const [],
    this.recent = const [],
    this.fail = false,
    this.hang = false,
  });

  Future<T> _gate<T>(T value) async {
    if (hang) await Completer<void>().future;
    if (fail) throw const KnowledgeException('kh_error');
    return value;
  }

  @override
  Future<KnowledgeLoad<List<KnowledgeCategory>>> getCategories() =>
      _gate(KnowledgeLoad(data: categories));

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getFeaturedArticles() =>
      _gate(KnowledgeLoad(data: featured));

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getRecentArticles(
          {int limit = 10}) =>
      _gate(KnowledgeLoad(data: recent.take(limit).toList()));

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getArticlesByCategory(
          String categoryId) =>
      _gate(KnowledgeLoad(data: const []));

  @override
  Future<KnowledgeLoad<KnowledgeArticle>> getArticleDetail(String slug) =>
      _gate(KnowledgeLoad(
          data: featured.firstWhere((a) => a.slug == slug)));

  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> searchArticles(
          String query) =>
      _gate(KnowledgeLoad(data: const []));

  @override
  Future<KnowledgeLoad<List<GlossaryTerm>>> getGlossary(
          {String query = ''}) =>
      _gate(KnowledgeLoad(data: const []));

  @override
  Future<KnowledgeLoad<List<KnowledgeQuiz>>> getQuizzes() =>
      _gate(KnowledgeLoad(data: const []));

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String quizId) =>
      _gate(const <QuizQuestion>[]);

  @override
  Future<QuizAnswerResult> submitQuizAnswer(
          String questionId, int chosenIndex) =>
      _gate(const QuizAnswerResult(
          correct: true, correctIndex: 0, explanation: ''));
}

const _cat = KnowledgeCategory(
  id: 'c1',
  slug: 'bmi-academy',
  title: 'BMI Academy',
  description: '',
  sortOrder: 0,
);

const _article = KnowledgeArticle(
  id: 'a1',
  slug: 'apa-itu-bmi',
  categoryId: 'c1',
  title: 'Apa itu BMI',
  summary: 'Penjelasan singkat.',
  contentMd: '# Halo',
  readingMinutes: 4,
  featured: true,
);

Future<AppState> _pumpHub(
    WidgetTester tester, KnowledgeRepository repo) async {
  SharedPreferences.setMockInitialValues({});
  final app = await tester.runAsync(() => AppState.load());
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AppStateScope(
        state: app!,
        child: KnowledgeHubScreen(repository: repo),
      ),
    ),
  );
  return app;
}

void main() {
  testWidgets('shows loading indicator while repository hangs',
      (tester) async {
    await _pumpHub(tester, FakeKnowledgeRepository(hang: true));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no content', (tester) async {
    await _pumpHub(tester, FakeKnowledgeRepository());
    await tester.pumpAndSettle();
    expect(find.text('Belum ada konten.'), findsOneWidget);
  });

  testWidgets('shows error + retry when repository fails',
      (tester) async {
    await _pumpHub(tester, FakeKnowledgeRepository(fail: true));
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat. Cek koneksimu.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('renders categories, featured, and recent', (tester) async {
    await _pumpHub(
      tester,
      FakeKnowledgeRepository(
        categories: [_cat],
        featured: [_article],
        recent: [_article],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Header + sections.
    expect(find.text('Pusat Pengetahuan'), findsOneWidget);
    expect(find.text('Unggulan'), findsOneWidget);
    expect(find.text('Terbaru'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('BMI Academy'), findsOneWidget);
    // Article appears in both featured and recent.
    expect(find.text('Apa itu BMI'), findsNWidgets(2));
    // Glossary link card.
    expect(find.text('Glosarium'), findsOneWidget);
  });
}
