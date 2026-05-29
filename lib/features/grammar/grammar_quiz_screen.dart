import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/grammar_question.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/widgets/vocab_quiz_league_style.dart';
import '../stories/story_providers.dart';

enum _ExplanationTab { fa, kur }

String _explanationForTab(GrammarQuestion q, _ExplanationTab tab) {
  switch (tab) {
    case _ExplanationTab.fa:
      if ((q.faExplanation ?? '').trim().isNotEmpty) {
        return q.faExplanation!.trim();
      }
      if ((q.kurExplanation ?? '').trim().isNotEmpty) {
        return q.kurExplanation!.trim();
      }
      return (q.engExplanation ?? '').trim();
    case _ExplanationTab.kur:
      if ((q.kurExplanation ?? '').trim().isNotEmpty) {
        return q.kurExplanation!.trim();
      }
      if ((q.faExplanation ?? '').trim().isNotEmpty) {
        return q.faExplanation!.trim();
      }
      return (q.engExplanation ?? '').trim();
  }
}

const int _kQuizLeaguePointsPerCorrect = 2;

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
  return arabicScript >= latinLetters ? TextDirection.rtl : TextDirection.ltr;
}

bool _isArabicScriptRune(int r) {
  return (r >= 0x0600 && r <= 0x06FF) ||
      (r >= 0x0750 && r <= 0x077F) ||
      (r >= 0x08A0 && r <= 0x08FF) ||
      (r >= 0xFB50 && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF);
}

bool _isLatinLetterRune(int r) {
  return (r >= 0x0041 && r <= 0x005A) || (r >= 0x0061 && r <= 0x007A);
}

class _GrammarReportKindOption {
  const _GrammarReportKindOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Labels from [AppLocalizations]; ids must match `api/grammar_report_question.php`.
List<_GrammarReportKindOption> _grammarReportKinds(AppLocalizations l10n) => [
  _GrammarReportKindOption(
    id: 'wrong_correct_answer',
    label: l10n.grammarReportKindWrongAnswer,
  ),
  _GrammarReportKindOption(
    id: 'typo_question',
    label: l10n.grammarReportKindTypoQuestion,
  ),
  _GrammarReportKindOption(
    id: 'typo_options',
    label: l10n.grammarReportKindTypoOptions,
  ),
  _GrammarReportKindOption(
    id: 'bad_explanation',
    label: l10n.grammarReportKindBadExplanation,
  ),
  _GrammarReportKindOption(
    id: 'unclear_question',
    label: l10n.grammarReportKindUnclear,
  ),
  _GrammarReportKindOption(id: 'other', label: l10n.grammarReportKindOther),
];

class _GrammarReportBottomSheet extends ConsumerStatefulWidget {
  const _GrammarReportBottomSheet({
    required this.l10n,
    required this.question,
    required this.parentMessenger,
    required this.onReported,
  });

  /// Resolved from the quiz screen so the sheet always matches app language.
  final AppLocalizations l10n;
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
    _selectedId = 'wrong_correct_answer';
    _detailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    setState(() => _submitting = true);
    try {
      await ref
          .read(apiServiceProvider)
          .reportGrammarQuestion(
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
        SnackBar(content: Text(l10n.reportSubmitted)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final kinds = _grammarReportKinds(l10n);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.grammarReportProblemTitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.grammarReportWhatWrong,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...kinds.map((k) {
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
                decoration: InputDecoration(
                  labelText: l10n.grammarReportDetailsOptional,
                  border: const OutlineInputBorder(),
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
                    : Text(l10n.submitReport),
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
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.quiz_outlined, size: 32, color: scheme.primary),
        title: Text(l10n.exitExerciseTitle),
        content: Text(l10n.exitExerciseBody),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.stay),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.exit),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

int? _grammarTopicNumber(String topic) {
  final buffer = StringBuffer();
  for (final codeUnit in topic.codeUnits) {
    if (codeUnit >= 0x0660 && codeUnit <= 0x0669) {
      buffer.writeCharCode(0x30 + codeUnit - 0x0660);
    } else if (codeUnit >= 0x06F0 && codeUnit <= 0x06F9) {
      buffer.writeCharCode(0x30 + codeUnit - 0x06F0);
    } else {
      buffer.writeCharCode(codeUnit);
    }
  }
  final match = RegExp(r'^\s*(\d+)').firstMatch(buffer.toString());
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

String? _currentGrammarTopicTitle(
  List<String> topics,
  GrammarQuestion? currentQuestion,
) {
  if (topics.length == 1) {
    final topic = topics.first.trim();
    return topic.isEmpty ? null : topic;
  }
  if (currentQuestion == null) return null;
  final currentTopic = currentQuestion.topic.trim();
  if (currentTopic.isEmpty) return null;
  final currentOrder =
      currentQuestion.orderNum ?? _grammarTopicNumber(currentTopic);
  return currentOrder == 1 || currentOrder == 3 ? currentTopic : null;
}

String _grammarAppBarTitle(AppLocalizations l10n, List<String> topics) {
  if (topics.isEmpty) return l10n.grammarAppBar;
  if (topics.length == 1) return topics.first;
  return l10n.grammarTopicsCountAppBar(topics.length);
}

class _GrammarStoryAddTitleButton extends StatelessWidget {
  const _GrammarStoryAddTitleButton({
    required this.topicCount,
    required this.loading,
    required this.onTap,
  });

  final int topicCount;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Create $topicCount grammar stories',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF58529),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDD2A7B).withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: loading
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.auto_stories_rounded,
                              color: scheme.onSurface,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
              if (!loading)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1306C),
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
  int _sessionSeed = DateTime.now().microsecondsSinceEpoch;

  /// Once set per question index, the choice cannot be changed (including after Back).
  final Map<int, String> _answers = {};
  int _score = 0;
  bool _sessionDone = false;
  bool _resultSubmitting = false;
  bool _resultSubmitted = false;
  bool _creatingGrammarStory = false;
  _ExplanationTab _explanationTab = _ExplanationTab.fa;

  /// Question IDs successfully reported this session (disables duplicate submits).
  final Set<int> _reportedQuestionIds = {};

  /// Stable shuffled option order per question for this session (Back/forward).
  final Map<int, List<String>> _optionOrderByQuestionId = {};

  List<String> _optionOrderFor(GrammarQuestion q) {
    return _optionOrderByQuestionId.putIfAbsent(
      q.id,
      () => q.shuffledOptionKeys(Object.hash(_sessionSeed, q.id)),
    );
  }

  int _scoreFromAnswers(List<GrammarQuestion> questions) {
    var n = 0;
    for (var i = 0; i < questions.length; i++) {
      final k = _answers[i];
      if (k != null && questions[i].isCorrectKey(k)) n++;
    }
    return n;
  }

  void _resetForNewQuestions() {
    final oldSeed = _sessionSeed;
    final newSeed = DateTime.now().microsecondsSinceEpoch;
    // Drop the old session from Riverpod cache, then switch to a new seeded session.
    ref.invalidate(
      apiGrammarQuizSessionProvider((
        topicsKey: grammarTopicsCacheKey(widget.topics),
        questionCount: widget.questionCount,
        seed: oldSeed,
      )),
    );
    setState(() {
      _index = 0;
      _sessionSeed = newSeed;
      _answers.clear();
      _score = 0;
      _sessionDone = false;
      _resultSubmitting = false;
      _resultSubmitted = false;
      _explanationTab = _ExplanationTab.fa;
      _reportedQuestionIds.clear();
      _optionOrderByQuestionId.clear();
    });
  }

  Future<void> _showGrammarReportSheet(
    BuildContext context,
    GrammarQuestion q,
  ) async {
    final parentContext = context;
    final l10n = AppLocalizations.of(parentContext)!;
    final messenger = ScaffoldMessenger.of(parentContext);
    await showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Localizations.override(
        context: parentContext,
        locale: Localizations.localeOf(parentContext),
        child: _GrammarReportBottomSheet(
          l10n: l10n,
          question: q,
          parentMessenger: messenger,
          onReported: () => setState(() => _reportedQuestionIds.add(q.id)),
        ),
      ),
    );
  }

  bool _canCreateStoryFromQuestion(GrammarQuestion q) {
    final question = (q.questionText ?? '').trim();
    final correct = (q.correctAnswer ?? '').trim();
    final options = q.nonEmptyOptionKeys().length;
    return question.isNotEmpty &&
        options >= 2 &&
        correct.isNotEmpty &&
        (q.optionByKey(correct)?.trim().isNotEmpty ?? false);
  }

  Future<void> _createGrammarStoriesFromTopics() async {
    if (_creatingGrammarStory) return;
    final topics = widget.topics
        .map((topic) => topic.trim())
        .where((topic) => topic.isNotEmpty)
        .toList();
    if (topics.isEmpty) return;
    setState(() => _creatingGrammarStory = true);
    try {
      final api = ref.read(apiServiceProvider);
      final random = math.Random();
      final shuffledTopics = [...topics]..shuffle(random);
      var createdCount = 0;
      for (final topic in shuffledTopics) {
        final questions = await api.fetchGrammarQuestions(topic);
        final validQuestions = questions
            .where(_canCreateStoryFromQuestion)
            .toList();
        if (validQuestions.isEmpty) {
          continue;
        }
        final q = validQuestions[random.nextInt(validQuestions.length)];
        final clientRequestId =
            'grammar-topic-${q.id}-${DateTime.now().microsecondsSinceEpoch}';
        await api.createGrammarStoryFromQuestion(
          clientRequestId: clientRequestId,
          questionId: q.id,
        );
        createdCount++;
      }
      if (createdCount < 1) {
        throw Exception('No valid grammar questions found for story');
      }
      ref.invalidate(visibleStoriesProvider);
      ref.invalidate(adminStoriesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$createdCount grammar stories created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingGrammarStory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topicsKey = grammarTopicsCacheKey(widget.topics);
    if (topicsKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.grammarAppBar)),
        body: Center(child: Text(l10n.noTopicSelected)),
      );
    }

    final async = ref.watch(
      apiGrammarQuizSessionProvider((
        topicsKey: topicsKey,
        questionCount: widget.questionCount,
        seed: _sessionSeed,
      )),
    );
    final session = ref.watch(authProvider).valueOrNull;
    final canCreateGrammarStory = session?.user.isAdmin == true;
    final scheme = Theme.of(context).colorScheme;
    final currentQuestions = async.valueOrNull;
    final currentQuestion =
        currentQuestions != null &&
            !_sessionDone &&
            _index < currentQuestions.length
        ? currentQuestions[_index]
        : null;
    final currentTopicTitle = _currentGrammarTopicTitle(
      widget.topics,
      currentQuestion,
    );

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
          leadingWidth: canCreateGrammarStory ? 104 : null,
          leading: canCreateGrammarStory
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BackButton(),
                    _GrammarStoryAddTitleButton(
                      topicCount: widget.topics.length,
                      loading: _creatingGrammarStory,
                      onTap: _createGrammarStoriesFromTopics,
                    ),
                  ],
                )
              : null,
          title: Text(
            currentTopicTitle ?? _grammarAppBarTitle(l10n, widget.topics),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.88),
          actions: [
            if (async.hasValue && async.value!.isNotEmpty && !_sessionDone)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Center(
                  child: QuizLeaguePointsChip.grammar(
                    points: _score * _kQuizLeaguePointsPerCorrect,
                  ),
                ),
              ),
            if (async.hasValue &&
                async.value!.isNotEmpty &&
                !_sessionDone &&
                _index < async.value!.length)
              IconButton(
                tooltip: l10n.grammarReportQuestionTooltip,
                icon: Icon(
                  _reportedQuestionIds.contains(async.value![_index].id)
                      ? Icons.flag_rounded
                      : Icons.outlined_flag_rounded,
                ),
                onPressed:
                    _reportedQuestionIds.contains(async.value![_index].id)
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
                l10n.grammarCouldNotLoadQuestions,
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
                    l10n.grammarNoQuestionsForTopics,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (_sessionDone) {
              return _SessionDoneBody(
                l10n: l10n,
                score: _score,
                total: questions.length,
                submitting: _resultSubmitting,
                submitted: _resultSubmitted,
                onSavePrivate: () => _submitResult(questions, isPublic: false),
                onSavePublic: () => _submitResult(questions, isPublic: true),
                onAgain: () => _practiceAgain(questions),
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
                                      (textTheme.titleLarge?.fontSize ?? 22) *
                                      0.9,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ..._optionOrderFor(q).asMap().entries.map((entry) {
                            final displayNumber = entry.key + 1;
                            final key = entry.value;
                            final label = q.optionByKey(key) ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OptionTile(
                                label: label,
                                displayNumber: displayNumber,
                                optionKey: key,
                                selectedKey: selectedKey,
                                answered: answered,
                                correctKey: (q.correctAnswer ?? '')
                                    .trim()
                                    .toLowerCase(),
                                onTap: answered
                                    ? null
                                    : () => _onSelect(q, key),
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
                                    color: scheme.shadow.withValues(
                                      alpha: 0.04,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline_rounded,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.grammarExplanationHeading,
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
                                        segments: [
                                          ButtonSegment<_ExplanationTab>(
                                            value: _ExplanationTab.fa,
                                            label: Text(
                                              l10n.grammarExplanationTabFa,
                                            ),
                                          ),
                                          ButtonSegment<_ExplanationTab>(
                                            value: _ExplanationTab.kur,
                                            label: Text(
                                              l10n.grammarExplanationTabCkb,
                                            ),
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
      if (q.isCorrectKey(key)) {
        _score++;
      }
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
        'fa_explanation': q.faExplanation,
        'kur_explanation': q.kurExplanation,
        'eng_explanation': q.engExplanation,
      };
    });
  }

  Future<void> _submitResult(
    List<GrammarQuestion> questions, {
    required bool isPublic,
  }) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _resultSubmitting = true);
    try {
      final topics = widget.topics
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final quizName = topics.isEmpty
          ? l10n.grammarPracticeAppBar
          : topics.join(' + ');
      await ref
          .read(apiServiceProvider)
          .submitGrammarResult(
            quizName: quizName,
            score: _score,
            totalQuestions: questions.length,
            selectedGrammars: topics,
            isPublic: isPublic,
            sessionItems: _sessionPayload(questions),
          );
      if (!mounted) return;
      ref.invalidate(myGrammarResultsProvider);
      ref.invalidate(publicGrammarCommunityProvider);
      setState(() {
        _resultSubmitted = true;
        _resultSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resultSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotSaveResult)));
    }
  }

  Future<void> _practiceAgain(List<GrammarQuestion> questions) async {
    if (_resultSubmitting) return;
    if (!_resultSubmitted) {
      await _submitResult(questions, isPublic: false);
      if (!mounted || !_resultSubmitted) return;
    }
    _resetForNewQuestions();
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
    final l10n = AppLocalizations.of(context)!;
    final nextLabel = isLast ? l10n.finish : l10n.next;
    final nextIcon = isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
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
                        l10n.questionProgress(questionIndex + 1, questionTotal),
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
                        l10n.back,
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
    required this.displayNumber,
    required this.optionKey,
    required this.selectedKey,
    required this.answered,
    required this.correctKey,
    this.onTap,
  });

  final String label;
  final int displayNumber;
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
          child: Directionality(
            textDirection: _grammarQuestionTextDirection(label),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$displayNumber.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg ?? scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.start,
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
      ),
    );
  }
}

class _SessionDoneBody extends StatelessWidget {
  const _SessionDoneBody({
    required this.l10n,
    required this.score,
    required this.total,
    required this.submitting,
    required this.submitted,
    required this.onSavePrivate,
    required this.onSavePublic,
    required this.onAgain,
    required this.onBack,
  });

  final AppLocalizations l10n;
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
    final l = l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              l.grammarSessionCompleteTitle,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.grammarScoreOutOf(score, total),
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!submitted) ...[
              Text(
                l.grammarHowSaveResult,
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
                  child: FilledButton.tonalIcon(
                    onPressed: onSavePrivate,
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: Text(l.keepPrivate),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSavePublic,
                    icon: const Icon(Icons.groups_rounded),
                    label: Text(l.showCommunity),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l.grammarSaveResultFootnote,
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
                    l.grammarResultSavedShort,
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
              child: Text(l.practiseAgain),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onBack, child: Text(l.backToTopics)),
          ],
        ),
      ),
    );
  }
}
