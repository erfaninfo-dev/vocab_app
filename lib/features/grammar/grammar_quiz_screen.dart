import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/grammar_question.dart';
import '../../domain/api_providers.dart';

enum _ExplanationTab { fa, kur }

String _explanationForTab(GrammarQuestion q, _ExplanationTab tab) {
  switch (tab) {
    case _ExplanationTab.fa:
      if ((q.faExplanation ?? '').trim().isNotEmpty)
        return q.faExplanation!.trim();
      if ((q.kurExplanation ?? '').trim().isNotEmpty)
        return q.kurExplanation!.trim();
      return (q.engExplanation ?? '').trim();
    case _ExplanationTab.kur:
      if ((q.kurExplanation ?? '').trim().isNotEmpty)
        return q.kurExplanation!.trim();
      if ((q.faExplanation ?? '').trim().isNotEmpty)
        return q.faExplanation!.trim();
      return (q.engExplanation ?? '').trim();
  }
}

const _optionKeys = ['option1', 'option2', 'option3', 'option4'];

/// LTR for Latin (e.g. English); RTL for Arabic/Persian script. Keeps [TextAlign.center]
/// visually centered while punctuation and word order follow the right direction.
TextDirection _grammarQuestionTextDirection(String? raw) {
  final s = raw ?? '';
  if (s.trim().isEmpty) return TextDirection.ltr;

  var arabicScript = 0;
  var latinLetters = 0;
  for (final r in s.runes) {
    if (_isArabicScriptRune(r)) {
      arabicScript++;
    } else if (_isLatinLetterRune(r)) {
      latinLetters++;
    }
  }
  if (arabicScript == 0 && latinLetters == 0) {
    return TextDirection.ltr;
  }
  return arabicScript >= latinLetters
      ? TextDirection.rtl
      : TextDirection.ltr;
}

bool _isArabicScriptRune(int r) {
  return (r >= 0x0600 && r <= 0x06FF) ||
      (r >= 0x0750 && r <= 0x077F) ||
      (r >= 0x08A0 && r <= 0x08FF) ||
      (r >= 0xFB50 && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF);
}

bool _isLatinLetterRune(int r) {
  return (r >= 0x0041 && r <= 0x005A) ||
      (r >= 0x0061 && r <= 0x007A);
}

class _GrammarReportKindOption {
  const _GrammarReportKindOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Must match [allowed] list in `api/grammar_report_question.php`.
const _kGrammarReportKinds = [
  _GrammarReportKindOption(
    id: 'wrong_correct_answer',
    label: 'Marked correct answer is wrong',
  ),
  _GrammarReportKindOption(
    id: 'typo_question',
    label: 'Typo in the question text',
  ),
  _GrammarReportKindOption(
    id: 'typo_options',
    label: 'Multiple options look correct',
  ),
  _GrammarReportKindOption(
    id: 'bad_explanation',
    label: 'Explanation is wrong or incomplete',
  ),
  _GrammarReportKindOption(
    id: 'unclear_question',
    label: 'Question wording is unclear',
  ),
  _GrammarReportKindOption(
    id: 'other',
    label: 'Other',
  ),
];

class _GrammarReportBottomSheet extends ConsumerStatefulWidget {
  const _GrammarReportBottomSheet({
    required this.question,
    required this.parentMessenger,
    required this.onReported,
  });

  final GrammarQuestion question;
  final ScaffoldMessengerState parentMessenger;
  final VoidCallback onReported;

  @override
  ConsumerState<_GrammarReportBottomSheet> createState() =>
      _GrammarReportBottomSheetState();
}

class _GrammarReportBottomSheetState
    extends ConsumerState<_GrammarReportBottomSheet> {
  late String _selectedId;
  late final TextEditingController _detailCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedId = _kGrammarReportKinds.first.id;
    _detailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(apiServiceProvider).reportGrammarQuestion(
            questionId: widget.question.id,
            reportType: _selectedId,
            detail: _detailCtrl.text,
          );
      if (!mounted) {
        return;
      }
      widget.onReported();
      Navigator.of(context).pop();
      widget.parentMessenger.showSnackBar(
        const SnackBar(content: Text('Report submitted')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit report. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Report a problem',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'What is wrong?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ..._kGrammarReportKinds.map((k) {
                return RadioListTile<String>(
                  dense: true,
                  value: k.id,
                  groupValue: _selectedId,
                  onChanged: _submitting
                      ? null
                      : (v) {
                          if (v == null) {
                            return;
                          }
                          setState(() => _selectedId = v);
                        },
                  title: Text(k.label),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: _detailCtrl,
                maxLines: 3,
                maxLength: 500,
                textAlign: TextAlign.start,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Correct-answer styling (light bar + solid green badge, same visual weight as before).
const Color _kCorrectOptionBg = Color(0xFFD8EDD9);
const Color _kCorrectOptionFg = Color(0xFF14532D);
const Color _kCorrectBadgeGreen = Color(0xFF2E7D32);

Future<bool> _confirmExitQuiz(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.quiz_outlined, size: 32, color: scheme.primary),
        title: const Text('Exit exercise?'),
        content: const Text(
          'If you go back now, your progress for this session will not be saved.',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

String _grammarAppBarTitle(List<String> topics) {
  if (topics.isEmpty) return 'Grammar';
  if (topics.length == 1) return topics.first;
  return '${topics.length} topics';
}

class GrammarQuizScreen extends ConsumerStatefulWidget {
  const GrammarQuizScreen({
    super.key,
    required this.topics,
    required this.questionCount,
  });

  /// One or more grammar topic names (DB column `content`).
  final List<String> topics;

  /// Target session length (actual list may be shorter if the bank is smaller).
  final int questionCount;

  @override
  ConsumerState<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
}

class _GrammarQuizScreenState extends ConsumerState<GrammarQuizScreen> {
  int _index = 0;

  /// Once set per question index, the choice cannot be changed (including after Back).
  final Map<int, String> _answers = {};
  int _score = 0;
  bool _sessionDone = false;
  bool _resultSubmitting = false;
  bool _resultSubmitted = false;
  _ExplanationTab _explanationTab = _ExplanationTab.fa;

  /// Question IDs successfully reported this session (disables duplicate submits).
  final Set<int> _reportedQuestionIds = {};

  int _scoreFromAnswers(List<GrammarQuestion> questions) {
    var n = 0;
    for (var i = 0; i < questions.length; i++) {
      final k = _answers[i];
      if (k != null && questions[i].isCorrectKey(k)) n++;
    }
    return n;
  }

  void _resetForNewQuestions() {
    ref.invalidate(
      apiGrammarQuizSessionProvider((
        topicsKey: grammarTopicsCacheKey(widget.topics),
        questionCount: widget.questionCount,
      )),
    );
    setState(() {
      _index = 0;
      _answers.clear();
      _score = 0;
      _sessionDone = false;
      _resultSubmitting = false;
      _resultSubmitted = false;
      _explanationTab = _ExplanationTab.fa;
      _reportedQuestionIds.clear();
    });
  }

  Future<void> _showGrammarReportSheet(
    BuildContext context,
    GrammarQuestion q,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _GrammarReportBottomSheet(
        question: q,
        parentMessenger: messenger,
        onReported: () => setState(() => _reportedQuestionIds.add(q.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicsKey = grammarTopicsCacheKey(widget.topics);
    if (topicsKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grammar')),
        body: const Center(child: Text('No topic selected.')),
      );
    }

    final async = ref.watch(
      apiGrammarQuizSessionProvider((
        topicsKey: topicsKey,
        questionCount: widget.questionCount,
      )),
    );
    final scheme = Theme.of(context).colorScheme;

    final needsExitConfirmation = async.maybeWhen(
      data: (q) => q.isNotEmpty && !_sessionDone,
      orElse: () => false,
    );

    return PopScope(
      canPop: !needsExitConfirmation,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmExitQuiz(context);
        if (!context.mounted) return;
        if (leave) context.pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            _grammarAppBarTitle(widget.topics),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(
            alpha: 0.88,
          ),
          actions: [
            if (async.hasValue &&
                async.value!.isNotEmpty &&
                !_sessionDone &&
                _index < async.value!.length)
              IconButton(
                tooltip: 'Report question',
                icon: Icon(
                  _reportedQuestionIds.contains(async.value![_index].id)
                      ? Icons.flag_rounded
                      : Icons.outlined_flag_rounded,
                ),
                onPressed: _reportedQuestionIds.contains(
                  async.value![_index].id,
                )
                    ? null
                    : () => _showGrammarReportSheet(
                          context,
                          async.value![_index],
                        ),
              ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load questions. Please try again.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (questions) {
            if (questions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No questions for the selected topic(s).',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (_sessionDone) {
              return _SessionDoneBody(
                score: _score,
                total: questions.length,
                submitting: _resultSubmitting,
                submitted: _resultSubmitted,
                onSavePrivate: () =>
                    _submitResult(questions, isPublic: false),
                onSavePublic: () => _submitResult(questions, isPublic: true),
                onAgain: _resetForNewQuestions,
                onBack: () => context.pop(),
              );
            }

            final q = questions[_index];
            final textTheme = Theme.of(context).textTheme;
            final selectedKey = _answers[_index];
            final answered = selectedKey != null;
            final explanation = _explanationForTab(q, _explanationTab);

            return Column(
              children: [
                SizedBox(
                  height: MediaQuery.paddingOf(context).top + kToolbarHeight,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: _SegmentedQuestionProgress(
                    total: questions.length,
                    currentIndex: _index,
                    scheme: scheme,
                  ),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.primary.withValues(alpha: 0.08),
                          scheme.secondary.withValues(alpha: 0.04),
                          scheme.surface,
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.surface.withValues(alpha: 0.95),
                                scheme.surfaceContainerHighest.withValues(
                                  alpha: 0.45,
                                ),
                              ],
                            ),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Directionality(
                            textDirection: _grammarQuestionTextDirection(
                              q.questionText,
                            ),
                            child: Text(
                              q.questionText ?? '',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                                fontSize:
                                    (textTheme.titleLarge?.fontSize ?? 22) * 0.9,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ..._optionKeys.map((key) {
                          final label = q.optionByKey(key) ?? '';
                          if (label.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OptionTile(
                              label: label,
                              optionKey: key,
                              selectedKey: selectedKey,
                              answered: answered,
                              correctKey: (q.correctAnswer ?? '')
                                  .trim()
                                  .toLowerCase(),
                              onTap: answered ? null : () => _onSelect(q, key),
                            ),
                          );
                        }),
                        if (answered) ...[
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.surfaceContainerHighest.withValues(
                                    alpha: 0.55,
                                  ),
                                  scheme.surface.withValues(alpha: 0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.shadow.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline_rounded,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Explanation',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: SegmentedButton<_ExplanationTab>(
                                      segments: const [
                                        ButtonSegment<_ExplanationTab>(
                                          value: _ExplanationTab.fa,
                                          label: Text('Persian'),
                                        ),
                                        ButtonSegment<_ExplanationTab>(
                                          value: _ExplanationTab.kur,
                                          label: Text('Kurdish'),
                                        ),
                                      ],
                                      selected: {_explanationTab},
                                      onSelectionChanged:
                                          (Set<_ExplanationTab> next) {
                                            setState(() {
                                              _explanationTab = next.first;
                                            });
                                          },
                                      showSelectedIcon: false,
                                      style: SegmentedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: SelectableText(
                                      explanation.isEmpty ? '—' : explanation,
                                      textAlign: TextAlign.right,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ),
                _QuizBottomBar(
                  scheme: scheme,
                  questionIndex: _index,
                  questionTotal: questions.length,
                  canGoBack: _index > 0,
                  onBack: () {
                    if (_index <= 0) return;
                    setState(() => _index -= 1);
                  },
                  answered: answered,
                  isLast: _index >= questions.length - 1,
                  onNext: answered
                      ? () {
                          if (_index >= questions.length - 1) {
                            setState(() {
                              _score = _scoreFromAnswers(questions);
                              _sessionDone = true;
                            });
                          } else {
                            setState(() => _index += 1);
                          }
                        }
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onSelect(GrammarQuestion q, String key) {
    if (_answers.containsKey(_index)) return;
    setState(() {
      _answers[_index] = key;
    });
  }

  List<Map<String, dynamic>> _sessionPayload(List<GrammarQuestion> questions) {
    return List<Map<String, dynamic>>.generate(questions.length, (i) {
      final q = questions[i];
      final sel = _answers[i];
      return <String, dynamic>{
        'question_id': q.id,
        'topic': q.topic,
        'question_text': q.questionText,
        'option1': q.option1,
        'option2': q.option2,
        'option3': q.option3,
        'option4': q.option4,
        'correct_answer': q.correctAnswer,
        'selected_answer': sel,
        'is_correct': sel != null && q.isCorrectKey(sel),
      };
    });
  }

  Future<void> _submitResult(
    List<GrammarQuestion> questions, {
    required bool isPublic,
  }) async {
    if (!mounted) return;
    setState(() => _resultSubmitting = true);
    try {
      final topics = widget.topics
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final quizName = topics.isEmpty ? 'Grammar practice' : topics.join(' + ');
      await ref.read(apiServiceProvider).submitGrammarResult(
            quizName: quizName,
            score: _score,
            totalQuestions: questions.length,
            selectedGrammars: topics,
            isPublic: isPublic,
            sessionItems: _sessionPayload(questions),
          );
      if (!mounted) return;
      ref.invalidate(myGrammarResultsProvider);
      ref.invalidate(publicGrammarResultsProvider);
      setState(() {
        _resultSubmitted = true;
        _resultSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resultSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your result. Please try again.'),
        ),
      );
    }
  }
}

/// One pill per question; gaps between; fills up to current question (step-wise).
class _SegmentedQuestionProgress extends StatelessWidget {
  const _SegmentedQuestionProgress({
    required this.total,
    required this.currentIndex,
    required this.scheme,
  });

  final int total;
  final int currentIndex;
  final ColorScheme scheme;

  static const double _gap = 5;
  static const double _height = 7;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final filled = (currentIndex + 1).clamp(1, total);
    final track = scheme.surfaceContainerHighest.withValues(alpha: 0.92);
    final fill = scheme.primary;

    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: _height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: i < filled ? fill : track,
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: _gap),
        ],
      ],
    );
  }
}

class _QuizBottomBar extends StatelessWidget {
  const _QuizBottomBar({
    required this.scheme,
    required this.questionIndex,
    required this.questionTotal,
    required this.canGoBack,
    required this.onBack,
    required this.answered,
    required this.isLast,
    required this.onNext,
  });

  final ColorScheme scheme;
  final int questionIndex;
  final int questionTotal;
  final bool canGoBack;
  final VoidCallback onBack;
  final bool answered;
  final bool isLast;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final nextLabel = isLast ? 'Finish' : 'Next';
    final nextIcon = isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Question ${questionIndex + 1} of $questionTotal',
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextButton.icon(
                      onPressed: canGoBack ? onBack : null,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: canGoBack
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.26),
                      ),
                      label: Text(
                        'Back',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: canGoBack
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.26),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onNext,
                      icon: Icon(nextIcon, size: 22),
                      label: Text(
                        nextLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: answered ? 1.5 : 0,
                        shadowColor: Colors.black26,
                        disabledBackgroundColor: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.9),
                        disabledForegroundColor: scheme.onSurface.withValues(
                          alpha: 0.38,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.optionKey,
    required this.selectedKey,
    required this.answered,
    required this.correctKey,
    this.onTap,
  });

  final String label;
  final String optionKey;
  final String? selectedKey;
  final bool answered;
  final String correctKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sel = (selectedKey ?? '').toLowerCase();
    final ok = optionKey.toLowerCase() == correctKey;

    Color? bg;
    Color? fg;
    if (answered) {
      if (ok) {
        bg = _kCorrectOptionBg;
        fg = _kCorrectOptionFg;
      } else if (sel == optionKey.toLowerCase()) {
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
      }
    }

    return Material(
      color: bg ?? scheme.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: answered
                  ? Colors.transparent
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_optionKeys.indexOf(optionKey) + 1}.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: fg ?? scheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: fg ?? scheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
              if (answered && ok)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: _kCorrectBadgeGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              if (answered && !ok && sel == optionKey.toLowerCase())
                Icon(Icons.cancel_rounded, color: scheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDoneBody extends StatelessWidget {
  const _SessionDoneBody({
    required this.score,
    required this.total,
    required this.submitting,
    required this.submitted,
    required this.onSavePrivate,
    required this.onSavePublic,
    required this.onAgain,
    required this.onBack,
  });

  final int score;
  final int total;
  final bool submitting;
  final bool submitted;
  final VoidCallback onSavePrivate;
  final VoidCallback onSavePublic;
  final VoidCallback onAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Session complete',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You got $score out of $total correct.',
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!submitted) ...[
              Text(
                'How should we save this result?',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (submitting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onSavePrivate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Keep private (only for me)'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onSavePublic,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Show in community results'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Private results appear only under My results; public results appear in the Users tab.',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Result saved',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (submitting && !submitted) ? null : onAgain,
              child: const Text('Practise again'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBack,
              child: const Text('Back to topics'),
            ),
          ],
        ),
      ),
    );
  }
}
