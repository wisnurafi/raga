import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/cloud_sync.dart';
import '../knowledge/knowledge_models.dart';
import '../knowledge/knowledge_repository.dart';
import '../knowledge/knowledge_repository_impl.dart';
import '../widgets/buttons.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';
import 'knowledge_widgets.dart';

// Quiz runner: one question per screen, options as tappable cards.
// Answers are graded server-side via the submit_quiz_answer RPC, so the
// explanation only appears AFTER the user submits — the key never
// reaches the client early. Quizzes need the network by design; offline
// users get a clear message instead of a spinner.
class KnowledgeQuizScreen extends StatefulWidget {
  final KnowledgeQuiz quiz;

  /// Injected for tests; production builds create the real one.
  final KnowledgeRepository? repository;

  const KnowledgeQuizScreen({
    super.key,
    required this.quiz,
    this.repository,
  });

  @override
  State<KnowledgeQuizScreen> createState() =>
      _KnowledgeQuizScreenState();
}

enum _Phase { loading, error, offline, answering, done }

class _KnowledgeQuizScreenState extends State<KnowledgeQuizScreen> {
  KnowledgeRepository? _repo;
  _Phase _phase = _Phase.loading;

  List<QuizQuestion> _questions = const [];
  int _index = 0;
  int? _picked;
  QuizAnswerResult? _result;
  bool _submitting = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repo = widget.repository;
      _load();
    } else {
      KnowledgeRepositoryImpl.create().then((r) {
        if (!mounted) return;
        _repo = r;
        _load();
      });
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) return;
    setState(() => _phase = _Phase.loading);
    try {
      final qs = await repo.getQuizQuestions(widget.quiz.id);
      if (!mounted) return;
      setState(() {
        _questions = qs;
        _phase = qs.isEmpty ? _Phase.error : _Phase.answering;
      });
    } catch (_) {
      if (!mounted) return;
      // The repository throws for offline too (quiz is online-only):
      // say so explicitly instead of a generic error.
      setState(() => _phase =
          CloudSync.isReady ? _Phase.error : _Phase.offline);
    }
  }

  Future<void> _pick(int i) async {
    if (_submitting || _result != null) return;
    final repo = _repo;
    if (repo == null) return;
    setState(() {
      _picked = i;
      _submitting = true;
    });
    try {
      final res = await repo.submitQuizAnswer(
          _questions[_index].id, i);
      if (!mounted) return;
      setState(() {
        _result = res;
        _submitting = false;
        if (res.correct) _score++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _picked = null;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tx(context, 'kh_error'))),
      );
    }
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      setState(() => _phase = _Phase.done);
      return;
    }
    setState(() {
      _index++;
      _picked = null;
      _result = null;
    });
  }

  void _retry() {
    setState(() {
      _index = 0;
      _picked = null;
      _result = null;
      _score = 0;
      _phase = _Phase.answering;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
            children: [
              RagaHeader(
                title: widget.quiz.title,
                showThemeToggle: false,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: rc.onBg),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 16),
              switch (_phase) {
                _Phase.loading => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(
                        child: CircularProgressIndicator()),
                  ),
                _Phase.error => KhErrorBlock(onRetry: _load),
                _Phase.offline => _offlineBlock(rc),
                _Phase.answering => _questionBody(rc),
                _Phase.done => _doneBody(rc),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _offlineBlock(RagaColors rc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40, color: rc.onCardFaint),
          const SizedBox(height: 12),
          Text(
            tx(context, 'kh_quiz_offline'),
            style: RagaType.body(rc.onCardMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
            child: Text(
              tx(context, 'kh_retry'),
              style: RagaType.chip(rc.chipActive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionBody(RagaColors rc) {
    final q = _questions[_index];
    final answered = _result != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tx(context, 'kh_quiz_question',
              {'n': _index + 1, 't': _questions.length}),
          style: RagaType.caption(rc.onBgMuted),
        ),
        const SizedBox(height: 8),
        Text(q.prompt, style: RagaType.cardTitle(rc.onBg)),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          _optionCard(rc, q, i, answered),
        if (_submitting)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (answered) ...[
          const SizedBox(height: 6),
          _verdictCard(rc),
          const SizedBox(height: 18),
          RagaButton(
            label: tx(context, 'kh_quiz_next'),
            onPressed: _next,
          ),
        ],
      ],
    );
  }

  Widget _optionCard(
      RagaColors rc, QuizQuestion q, int i, bool answered) {
    final res = _result;
    Color? border;
    if (answered && res != null) {
      if (i == res.correctIndex) {
        border = rc.success;
      } else if (i == _picked) {
        border = rc.danger;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(16),
        onTap: answered ? null : () => _pick(i),
        child: Container(
          decoration: border == null
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.5),
                ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  q.options[i],
                  style: RagaType.body(rc.onCard),
                ),
              ),
              if (answered && res != null && i == res.correctIndex)
                Icon(Icons.check_circle_outline,
                    color: rc.success, size: 22),
              if (answered &&
                  res != null &&
                  i == _picked &&
                  !res.correct)
                Icon(Icons.cancel_outlined,
                    color: rc.danger, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verdictCard(RagaColors rc) {
    final res = _result!;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                res.correct
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                color: res.correct ? rc.success : rc.danger,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                tx(context,
                    res.correct ? 'kh_quiz_correct' : 'kh_quiz_wrong'),
                style: RagaType.label(
                    res.correct ? rc.success : rc.danger),
              ),
            ],
          ),
          if (res.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              res.explanation,
              style: RagaType.body(rc.onCardMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _doneBody(RagaColors rc) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(Icons.emoji_events_outlined,
            size: 56, color: rc.chipActive),
        const SizedBox(height: 16),
        Text(
          tx(context, 'kh_quiz_done'),
          style: RagaType.section(rc.onBg),
        ),
        const SizedBox(height: 8),
        Text(
          tx(context, 'kh_quiz_score',
              {'s': _score, 't': _questions.length}),
          style: RagaType.title(rc.onBg),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        RagaButton(
          label: tx(context, 'kh_quiz_retry'),
          onPressed: _retry,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            tx(context, 'close'),
            style: RagaType.chip(rc.onCardMuted),
          ),
        ),
      ],
    );
  }
}
