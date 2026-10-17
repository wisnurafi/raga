import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/theme.dart';
import 'package:raga/knowledge/knowledge_models.dart';
import 'package:raga/knowledge/knowledge_repository.dart';
import 'package:raga/screens/knowledge_quiz_screen.dart';
import 'package:raga/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake repository: canned quiz + questions. Option index 0 is always
// the correct answer, so the test can answer right and wrong on demand.
class _FakeQuizRepo implements KnowledgeRepository {
  @override
  Future<KnowledgeLoad<List<KnowledgeCategory>>> getCategories() =>
      throw UnimplementedError();
  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getFeaturedArticles() =>
      throw UnimplementedError();
  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getRecentArticles(
          {int limit = 10}) =>
      throw UnimplementedError();
  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> getArticlesByCategory(
          String categoryId) =>
      throw UnimplementedError();
  @override
  Future<KnowledgeLoad<KnowledgeArticle>> getArticleDetail(String slug) =>
      throw UnimplementedError();
  @override
  Future<KnowledgeLoad<List<KnowledgeArticle>>> searchArticles(
          String query) =>
      throw UnimplementedError();
  @override
  Future<KnowledgeLoad<List<GlossaryTerm>>> getGlossary(
          {String query = ''}) =>
      throw UnimplementedError();
  @override
  Future<KnowledgeLoad<List<KnowledgeQuiz>>> getQuizzes() =>
      throw UnimplementedError();

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String quizId) async =>
      const [
        QuizQuestion(
          id: 'q1',
          quizId: 'quiz1',
          sortOrder: 0,
          prompt: 'Berapa 1 + 1?',
          options: ['2', '3', '4', '5'],
        ),
        QuizQuestion(
          id: 'q2',
          quizId: 'quiz1',
          sortOrder: 1,
          prompt: 'Warna langit?',
          options: ['Biru', 'Hijau', 'Merah', 'Kuning'],
        ),
      ];

  @override
  Future<QuizAnswerResult> submitQuizAnswer(
      String questionId, int chosenIndex) async {
    final correct = chosenIndex == 0;
    return QuizAnswerResult(
      correct: correct,
      correctIndex: 0,
      explanation: correct ? 'Tepat sekali.' : 'Jawaban yang benar: opsi 1.',
    );
  }
}

const _quiz = KnowledgeQuiz(
  id: 'quiz1',
  slug: 'kuis-coba',
  title: 'Kuis Coba',
  description: '',
);

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final app = await tester.runAsync(() => AppState.load());
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AppStateScope(
        state: app!,
        child: KnowledgeQuizScreen(
          quiz: _quiz,
          repository: _FakeQuizRepo(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('full quiz flow: answer, explanation, next, score',
      (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    // Question 1.
    expect(find.text('Soal 1 dari 2'), findsOneWidget);
    expect(find.text('Berapa 1 + 1?'), findsOneWidget);

    // Answer correctly (index 0).
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);
    expect(find.text('Tepat sekali.'), findsOneWidget);

    // Next question.
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Soal 2 dari 2'), findsOneWidget);
    expect(find.text('Warna langit?'), findsOneWidget);

    // Answer wrongly (index 2).
    await tester.tap(find.text('Merah'));
    await tester.pumpAndSettle();
    expect(find.text('Kurang tepat'), findsOneWidget);
    expect(find.text('Jawaban yang benar: opsi 1.'), findsOneWidget);

    // Finish: score 1 of 2.
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Kuis selesai'), findsOneWidget);
    expect(find.text('Skormu: 1 dari 2'), findsOneWidget);

    // Retry resets to question 1.
    await tester.tap(find.text('Ulangi kuis'));
    await tester.pumpAndSettle();
    expect(find.text('Soal 1 dari 2'), findsOneWidget);
  });

  testWidgets('options are locked after submit', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.text('Kurang tepat'), findsOneWidget);

    // Tapping another option after submit does nothing.
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(find.text('Kurang tepat'), findsOneWidget);
    expect(find.text('Soal 1 dari 2'), findsOneWidget);
  });
}
