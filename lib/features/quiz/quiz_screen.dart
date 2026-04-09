import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/language/language_provider.dart';
import '../../core/stats/stats_service.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../domain/vocab_quiz_providers.dart';

const int kVocabQuizMaxQuestions = 60;

// ─── Quiz Mode ────────────────────────────────────────────────────────────────

enum QuizMode {
  wordToMeaning('Word → Meaning', Icons.translate_rounded),
  meaningToWord('Meaning → Word', Icons.text_fields_rounded);

  const QuizMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ─── Answer Format ────────────────────────────────────────────────────────────

enum VocabAnswerFormat {
  mcq('Multiple choice'),
  written('Fill in the blank'),
  both('Both');

  const VocabAnswerFormat(this.label);
  final String label;
}

// ─── Question Modes (multi-select) ────────────────────────────────────────────

enum VocabQuestionMode {
  mcqWordToMeaning('Word → Meaning', Icons.translate_rounded),
  mcqMeaningToWord('Meaning → Word', Icons.text_fields_rounded),
  writtenMeaningToWord('Fill in the blank', Icons.edit_rounded);

  const VocabQuestionMode(this.label, this.icon);
  final String label;
  final IconData icon;

  bool get isMcq =>
      this == VocabQuestionMode.mcqWordToMeaning ||
      this == VocabQuestionMode.mcqMeaningToWord;
}

// ─── Question model ───────────────────────────────────────────────────────────

enum _QuestionKind { mcq, written }

class _Question {
  const _Question({
    required this.entry,
    required this.prompt,
    required this.promptSub,
    required this.correctAnswer,
    required this.options, // 4 items, shuffled (empty for written)
    required this.kind,
  });

  final VocabEntry entry;
  final String prompt;
  final String promptSub; // secondary line (e.g. type or fa meaning)
  final String correctAnswer;
  final List<String> options;
  final _QuestionKind kind;
}

// ─── Quiz Screen ──────────────────────────────────────────────────────────────

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.bookId,
    this.unit,
    this.section,
  });

  final int bookId;
  /// Null when using `/books/:bookId/quiz` (multi-unit from query).
  final int? unit;
  final int? section;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  QuizMode _mode = QuizMode.wordToMeaning;
  VocabAnswerFormat _answerFormat = VocabAnswerFormat.mcq;
  Set<VocabQuestionMode> _questionModes = {VocabQuestionMode.mcqWordToMeaning};
  List<_Question> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _sessionDone = false;
  /// From setup: all words in pool, or wrong-words only.
  bool _scopeWrongsOnly = false;
  int _questionBudget = 20;
  bool _removingLearned = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late final TextEditingController _writtenCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _writtenCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _writtenCtrl.dispose();
    super.dispose();
  }

  static String _normalizeAnswer(String s) {
    return s.trim().toLowerCase();
  }

  static bool _isCorrect(_Question q, String answer) {
    if (q.kind == _QuestionKind.written) {
      return _normalizeAnswer(answer) == _normalizeAnswer(q.correctAnswer);
    }
    return answer == q.correctAnswer;
  }

  Set<VocabQuestionMode> _effectiveModes() {
    if (_questionModes.isNotEmpty) return _questionModes;
    if (_answerFormat == VocabAnswerFormat.written) {
      return {VocabQuestionMode.writtenMeaningToWord};
    }
    if (_answerFormat == VocabAnswerFormat.both) {
      return {
        _mode == QuizMode.wordToMeaning
            ? VocabQuestionMode.mcqWordToMeaning
            : VocabQuestionMode.mcqMeaningToWord,
        VocabQuestionMode.writtenMeaningToWord,
      };
    }
    return {
      _mode == QuizMode.wordToMeaning
          ? VocabQuestionMode.mcqWordToMeaning
          : VocabQuestionMode.mcqMeaningToWord,
    };
  }

  List<_Question> _buildQuestions(
    List<VocabEntry> words,
    TranslationLang lang,
    int maxQuestions,
    Set<VocabQuestionMode> modes,
  ) {
    if (words.isEmpty) return [];
    final rng = Random();

    // Filter: only words with both word and at least one meaning
    final usable = words
        .where(
          (w) =>
              w.word.isNotEmpty &&
              (w.meaningEn.isNotEmpty || w.meaningFor(lang).isNotEmpty),
        )
        .toList();

    if (usable.isEmpty) return [];

    final cap = maxQuestions.clamp(1, kVocabQuizMaxQuestions);
    final selected = modes.isEmpty
        ? <VocabQuestionMode>{VocabQuestionMode.mcqWordToMeaning}
        : {...modes};

    final Map<VocabQuestionMode, List<_Question>> buckets = {
      for (final m in selected) m: <_Question>[],
    };

    final shuffledWords = [...usable]..shuffle(rng);
    for (final word in shuffledWords) {
      for (final m in selected) {
        if (m == VocabQuestionMode.writtenMeaningToWord) {
          final localMeaning = word.meaningFor(lang);
          final prompt = localMeaning.isNotEmpty ? localMeaning : word.meaningEn;
          if (prompt.trim().isEmpty) continue;
          final promptSub =
              (localMeaning.isNotEmpty && word.meaningEn.isNotEmpty)
                  ? word.meaningEn
                  : word.type;
          buckets[m]!.add(
            _Question(
              entry: word,
              prompt: prompt,
              promptSub: promptSub,
              correctAnswer: word.word,
              options: const [],
              kind: _QuestionKind.written,
            ),
          );
          continue;
        }

        final others = usable.where((w) => w.id != word.id).toList()
          ..shuffle(rng);
        final wrongPool = others.take(3).toList();
        if (wrongPool.length < 3) continue;

        if (m == VocabQuestionMode.mcqWordToMeaning) {
          final correct = word.meaningEn.isNotEmpty
              ? word.meaningEn
              : word.meaningFor(lang);
          final wrongs = wrongPool
              .map(
                (w) => w.meaningEn.isNotEmpty ? w.meaningEn : w.meaningFor(lang),
              )
              .toList();
          final opts = [correct, ...wrongs]..shuffle(rng);
          buckets[m]!.add(
            _Question(
              entry: word,
              prompt: word.word,
              promptSub: word.type,
              correctAnswer: correct,
              options: opts,
              kind: _QuestionKind.mcq,
            ),
          );
        } else if (m == VocabQuestionMode.mcqMeaningToWord) {
          final localMeaning = word.meaningFor(lang);
          final prompt = localMeaning.isNotEmpty ? localMeaning : word.meaningEn;
          final correct = word.word;
          final wrongs = wrongPool.map((w) => w.word).toList();
          final opts = [correct, ...wrongs]..shuffle(rng);
          final promptSub =
              (localMeaning.isNotEmpty && word.meaningEn.isNotEmpty)
                  ? word.meaningEn
                  : '';
          buckets[m]!.add(
            _Question(
              entry: word,
              prompt: prompt,
              promptSub: promptSub,
              correctAnswer: correct,
              options: opts,
              kind: _QuestionKind.mcq,
            ),
          );
        }
      }
    }

    final out = <_Question>[];
    final keys = selected.toList();
    var cursor = 0;
    while (out.length < cap) {
      var addedAny = false;
      for (var k = 0; k < keys.length && out.length < cap; k++) {
        final m = keys[(cursor + k) % keys.length];
        final b = buckets[m]!;
        if (b.isEmpty) continue;
        out.add(b.removeAt(0));
        addedAny = true;
      }
      cursor = (cursor + 1) % keys.length;
      if (!addedAny) break;
    }
    return out;

  }

  void _resetWrittenInput() {
    _writtenCtrl
      ..text = ''
      ..selection = const TextSelection.collapsed(offset: 0);
  }

  Future<void> _submitWritten() async {
    if (_answered) return;
    final answer = _writtenCtrl.text;
    await _selectAnswer(answer);
  }

  void _startQuiz(List<VocabEntry> words, TranslationLang lang, int budget) {
    setState(() {
      _questions = _buildQuestions(words, lang, budget, _effectiveModes());
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _sessionDone = false;
    });
    _resetWrittenInput();
  }

  void _invalidateWrongs() {
    ref.invalidate(
      vocabQuizWrongsProvider((bookId: widget.bookId, unit: null)),
    );
    if (widget.unit != null) {
      ref.invalidate(
        vocabQuizWrongsProvider((bookId: widget.bookId, unit: widget.unit)),
      );
    }
  }

  Future<void> _selectAnswer(String answer) async {
    if (_answered) return;
    final q = _questions[_currentIndex];
    final isCorrect = _isCorrect(q, answer);
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) _score++;
    });
    ref.read(statsProvider.notifier).logQuizAnswer(correct: isCorrect);
    if (!isCorrect) {
      _shakeCtrl.forward(from: 0);
      final session = ref.read(authProvider).valueOrNull;
      if (session != null) {
        try {
          await ref.read(apiServiceProvider).addVocabQuizWrong(
                bookId: widget.bookId,
                unit: q.entry.unit,
                wordKey: q.entry.id,
              );
          _invalidateWrongs();
        } catch (_) {}
      }
    }
  }

  Future<void> _onLearnedCurrent() async {
    if (!_answered || _removingLearned) return;
    final q = _questions[_currentIndex];
    final answer = _selectedAnswer;
    if (answer == null || !_isCorrect(q, answer)) return;
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    setState(() => _removingLearned = true);
    try {
      await ref.read(apiServiceProvider).removeVocabQuizWrong(
            bookId: widget.bookId,
            unit: q.entry.unit,
            wordKey: q.entry.id,
          );
      _invalidateWrongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from your mistake list')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update server')),
        );
      }
    } finally {
      if (mounted) setState(() => _removingLearned = false);
    }
  }

  void _next() {
    if (_currentIndex >= _questions.length - 1) {
      setState(() => _sessionDone = true);
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _resetWrittenInput();
    }
  }

  bool _parsedRouteOnce = false;
  /// From `?important=0|1`; when set, skips the in-quiz important-word choice.
  int? _routeImportant;
  /// User choice when pool has important words and URL did not specify `important`.
  int? _userImportantScope;

  void _ensureRouteDefaults() {
    if (_parsedRouteOnce) return;
    final route = GoRouterState.of(context);
    final scope = route.uri.queryParameters['scope'] ?? 'all';
    final c = int.tryParse(route.uri.queryParameters['count'] ?? '');
    final imp = route.uri.queryParameters['important'];
    final fmt = route.uri.queryParameters['format'];
    final modesCsv = route.uri.queryParameters['modes'];
    _scopeWrongsOnly = scope == 'wrongs';
    if (c != null && c > 0) {
      _questionBudget = c.clamp(1, kVocabQuizMaxQuestions);
    }
    if (imp == '0' || imp == '1') {
      _routeImportant = imp == '0' ? 0 : 1;
    }
    if (fmt != null) {
      VocabAnswerFormat? parsed;
      for (final v in VocabAnswerFormat.values) {
        if (v.name == fmt) {
          parsed = v;
          break;
        }
      }
      if (parsed != null) {
        _answerFormat = parsed;
        if (parsed == VocabAnswerFormat.written) {
          _mode = QuizMode.meaningToWord;
        }
      }
    }

    if (modesCsv != null && modesCsv.trim().isNotEmpty) {
      final parts = modesCsv.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      final next = <VocabQuestionMode>{};
      for (final p in parts) {
        for (final m in VocabQuestionMode.values) {
          if (m.name == p) {
            next.add(m);
            break;
          }
        }
      }
      if (next.isNotEmpty) {
        _questionModes = next;
      }
    }
    _parsedRouteOnce = true;
  }

  int? _resolvedImportantScope(bool hasImportant) {
    if (_routeImportant != null) return _routeImportant;
    if (!hasImportant) return 0;
    return _userImportantScope;
  }

  List<VocabEntry> _applyImportantFilter(List<VocabEntry> pool, int scope) {
    if (scope == 1) {
      return pool.where((w) => w.isImportant).toList();
    }
    return pool;
  }

  List<VocabEntry> _filterPool(
    List<VocabEntry> words,
    Set<int> unitFilter,
    bool wrongsOnly,
    Set<String> wrongKeys,
  ) {
    var pool = words;
    if (unitFilter.isNotEmpty) {
      pool = pool.where((w) => unitFilter.contains(w.unit)).toList();
    }
    if (wrongsOnly) {
      pool = pool.where((w) => wrongKeys.contains(w.id)).toList();
    }
    return pool;
  }

  bool get _inActiveSession => _questions.isNotEmpty && !_sessionDone;

  Future<bool> _confirmExitQuiz() async {
    if (!_inActiveSession) return true;

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از کوییز؟'),
        content: const Text('اگر خارج شوید، پیشرفت این کوییز از بین می‌رود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ادامه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    _ensureRouteDefaults();
    final lang = ref.watch(langProvider);
    final route = GoRouterState.of(context);
    final unitsCsv = route.uri.queryParameters['units'] ?? '';
    final unitFilter = unitsCsv
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();

    final wordsAsync = widget.unit != null
        ? ref.watch(
            apiWordsProvider((
              bookId: widget.bookId,
              unit: widget.unit!,
              section: widget.section,
            )),
          )
        : ref.watch(apiAllWordsForBookProvider(widget.bookId));

    final wrongsAsync = ref.watch(
      vocabQuizWrongsProvider((
        bookId: widget.bookId,
        unit: widget.unit,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            final nav = Navigator.of(context);
            final ok = await _confirmExitQuiz();
            if (!ok || !mounted) return;
            nav.pop();
          },
        ),
        title: const Text('Quiz'),
        actions: [
          if (_questions.isNotEmpty && !_sessionDone)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_score / ${_currentIndex + (_answered ? 1 : 0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PopScope(
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final ok = await _confirmExitQuiz();
          if (!ok || !mounted) return;
          Navigator.of(context).pop();
        },
        child: wordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('دریافت اطلاعات انجام نشد. لطفاً دوباره تلاش کنید'),
          ),
          data: (words) {
            return wrongsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Could not load mistake list'),
            ),
            data: (wrongs) {
              final wrongKeys = wrongs.map((w) => w.wordKey).toSet();
              final basePool = _filterPool(
                words,
                widget.unit == null ? unitFilter : <int>{},
                _scopeWrongsOnly,
                wrongKeys,
              );
              final hasImportant = basePool.any((w) => w.isImportant);
              final resolvedScope = _resolvedImportantScope(hasImportant);
              if (hasImportant && resolvedScope == null) {
                final nImp = basePool.where((w) => w.isImportant).length;
                return _ImportantChoicePanel(
                  allCount: basePool.length,
                  importantCount: nImp,
                  onAllWords: () => setState(() => _userImportantScope = 0),
                  onImportantOnly: () => setState(() => _userImportantScope = 1),
                );
              }

              final pool = _applyImportantFilter(basePool, resolvedScope!);

              final selectedModes = _effectiveModes();
              final needsMcq =
                  selectedModes.any((m) => m.isMcq);
              final minPoolNeeded = needsMcq ? 4 : 1;

              if (pool.length < minPoolNeeded) {
                final importantTooSmall =
                    resolvedScope == 1 && hasImportant && basePool.length >= 4;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      importantTooSmall
                          ? 'Not enough important words for this quiz (need at least 4). '
                              'Choose all words, change scope, or pick more units.'
                          : _scopeWrongsOnly
                              ? 'Not enough words in mistake list for this quiz (need 4+).'
                              : needsMcq
                                  ? 'Need at least 4 words to start this quiz.'
                                  : 'Need at least 1 word to start this quiz.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final loggedIn = ref.watch(authProvider).valueOrNull != null;
              final maxQ = pool.length.clamp(1, kVocabQuizMaxQuestions);
              final minPick = pool.length >= 10 ? 10 : pool.length;

              if (_questions.isEmpty) {
                return _ModeSelector(
                  selectedModes: selectedModes,
                  poolSize: pool.length,
                  scopeWrongsOnly: _scopeWrongsOnly,
                  wrongOnServer: wrongs.length,
                  questionBudget: _questionBudget.clamp(minPick, maxQ),
                  minQuestionPick: minPick,
                  maxQuestionPick: maxQ,
                  loggedIn: loggedIn,
                  onModesChanged: (modes) =>
                      setState(() => _questionModes = modes),
                  onScopeChanged: (v) => setState(() => _scopeWrongsOnly = v),
                  onQuestionBudgetChanged: (n) =>
                      setState(() => _questionBudget = n),
                  onStart: () {
                    final b = _questionBudget.clamp(minPick, maxQ);
                    _startQuiz(pool, lang, b);
                  },
                );
              }

              if (_sessionDone) {
                return _ResultScreen(
                  score: _score,
                  total: _questions.length,
                  onRetry: () {
                    final b = _questionBudget.clamp(minPick, maxQ);
                    _startQuiz(pool, lang, b);
                  },
                  onChangeMode: () => setState(() => _questions = []),
                );
              }

              final q = _questions[_currentIndex];
              final showLearned = _scopeWrongsOnly &&
                  loggedIn &&
                  _answered &&
                  _selectedAnswer == q.correctAnswer;

              return SingleChildScrollView(
                child: _QuizBody(
                  question: q,
                  questionNumber: _currentIndex + 1,
                  total: _questions.length,
                  score: _score,
                  mode: _mode,
                  selectedAnswer: _selectedAnswer,
                  answered: _answered,
                  shakeAnimation: _shakeAnim,
                  onSelect: _selectAnswer,
                  writtenController: _writtenCtrl,
                  onSubmitWritten: _submitWritten,
                  onNext: _next,
                  showLearnedButton: showLearned,
                  learnedBusy: _removingLearned,
                  onLearned: _onLearnedCurrent,
                ),
              );
            },
          );
          },
        ),
      ),
    );
  }
}

// ─── Important-word scope (before mode setup) ─────────────────────────────────

class _ImportantChoicePanel extends StatelessWidget {
  const _ImportantChoicePanel({
    required this.allCount,
    required this.importantCount,
    required this.onAllWords,
    required this.onImportantOnly,
  });

  final int allCount;
  final int importantCount;
  final VoidCallback onAllWords;
  final VoidCallback onImportantOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canQuizImportantOnly = importantCount >= 4;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 52, color: scheme.primary),
            const SizedBox(height: 20),
            Text(
              'Quiz scope',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This list includes important words. Choose whether the quiz '
              'uses every word here or only important ones.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onAllWords,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('All words ($allCount)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canQuizImportantOnly ? onImportantOnly : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Important words only ($importantCount)'),
              ),
            ),
            if (!canQuizImportantOnly) ...[
              const SizedBox(height: 12),
              Text(
                'Important-only mode needs at least four important words in this scope.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Mode Selector ────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedModes,
    required this.poolSize,
    required this.scopeWrongsOnly,
    required this.wrongOnServer,
    required this.questionBudget,
    required this.minQuestionPick,
    required this.maxQuestionPick,
    required this.loggedIn,
    required this.onModesChanged,
    required this.onScopeChanged,
    required this.onQuestionBudgetChanged,
    required this.onStart,
  });

  final Set<VocabQuestionMode> selectedModes;
  final int poolSize;
  final bool scopeWrongsOnly;
  final int wrongOnServer;
  final int questionBudget;
  final int minQuestionPick;
  final int maxQuestionPick;
  final bool loggedIn;
  final ValueChanged<Set<VocabQuestionMode>> onModesChanged;
  final ValueChanged<bool> onScopeChanged;
  final ValueChanged<int> onQuestionBudgetChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = minQuestionPick.toDouble();
    final high = maxQuestionPick.toDouble();
    final divisions = maxQuestionPick > minQuestionPick
        ? maxQuestionPick - minQuestionPick
        : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.quiz_rounded,
                size: 52,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quiz setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '$poolSize words in pool · min $minQuestionPick question(s) · max $maxQuestionPick',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (loggedIn) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                value: scopeWrongsOnly,
                onChanged: wrongOnServer == 0 ? null : (v) => onScopeChanged(v),
                title: const Text('Only past mistakes'),
                subtitle: Text(
                  wrongOnServer == 0
                      ? 'No mistakes recorded yet for this scope.'
                      : '$wrongOnServer mistake(s) on server',
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Sign in to sync mistakes and use “past mistakes” mode.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Number of questions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Slider(
              min: low,
              max: high,
              divisions: divisions,
              label: '$questionBudget',
              value: questionBudget.clamp(minQuestionPick, maxQuestionPick).toDouble(),
              onChanged: maxQuestionPick < 1
                  ? null
                  : (v) => onQuestionBudgetChanged(v.round()),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Question modes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final m in VocabQuestionMode.values)
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.icon,
                          size: 18,
                          color: selectedModes.contains(m)
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(m.label),
                      ],
                    ),
                    selected: selectedModes.contains(m),
                    onSelected: (v) {
                      final next = {...selectedModes};
                      if (v) {
                        next.add(m);
                      } else {
                        next.remove(m);
                      }
                      if (next.isEmpty) {
                        // Keep at least one mode.
                        next.add(m);
                      }
                      onModesChanged(next);
                    },
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start quiz'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quiz Body ────────────────────────────────────────────────────────────────

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.question,
    required this.questionNumber,
    required this.total,
    required this.score,
    required this.mode,
    required this.selectedAnswer,
    required this.answered,
    required this.shakeAnimation,
    required this.onSelect,
    required this.writtenController,
    required this.onSubmitWritten,
    required this.onNext,
    this.showLearnedButton = false,
    this.learnedBusy = false,
    this.onLearned,
  });

  final _Question question;
  final int questionNumber;
  final int total;
  final int score;
  final QuizMode mode;
  final String? selectedAnswer;
  final bool answered;
  final Animation<double> shakeAnimation;
  final ValueChanged<String> onSelect;
  final TextEditingController writtenController;
  final VoidCallback onSubmitWritten;
  final VoidCallback onNext;
  final bool showLearnedButton;
  final bool learnedBusy;
  final VoidCallback? onLearned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = questionNumber == total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          // ── Progress ────────────────────────────────────────────────────────
          _QuizProgress(current: questionNumber, total: total, score: score),
          const SizedBox(height: 14),

          // ── Prompt card ─────────────────────────────────────────────────────
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [scheme.primaryContainer, scheme.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mode == QuizMode.wordToMeaning
                        ? 'What is the meaning of:'
                        : 'Which word means:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    question.prompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (question.promptSub.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      question.promptSub,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Answer area ─────────────────────────────────────────────────────
          if (question.kind == _QuestionKind.written) ...[
            TextField(
              controller: writtenController,
              enabled: !answered,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitWritten(),
              decoration: InputDecoration(
                labelText: 'Type the word',
                hintText: 'Type your answer…',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: answered ? null : onSubmitWritten,
                child: const Text('Submit'),
              ),
            ),
            if (answered) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _resultLine(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _isWrittenCorrect()
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ] else ...[
            ...question.options.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile(
                  text: opt,
                  state: _optionState(opt),
                  shakeAnimation: shakeAnimation,
                  onTap: () => onSelect(opt),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ── Next button ─────────────────────────────────────────────────────
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: answered ? Offset.zero : const Offset(0, 0.3),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: answered ? 1 : 0,
              child: Column(
                children: [
                  if (showLearnedButton && onLearned != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: learnedBusy ? null : onLearned,
                        icon: learnedBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          learnedBusy ? 'Updating…' : 'I learned it — remove from mistakes',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: answered ? onNext : null,
                      icon: Icon(
                        isLast
                            ? Icons.emoji_events_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(isLast ? 'See Results' : 'Next Question'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _OptionState _optionState(String opt) {
    if (!answered) return _OptionState.idle;
    if (opt == question.correctAnswer) return _OptionState.correct;
    if (opt == selectedAnswer) return _OptionState.wrong;
    return _OptionState.idle;
  }

  bool _isWrittenCorrect() {
    if (question.kind != _QuestionKind.written) return false;
    final a = (selectedAnswer ?? '').trim().toLowerCase();
    final c = question.correctAnswer.trim().toLowerCase();
    return a.isNotEmpty && a == c;
  }

  String _resultLine() {
    final a = (selectedAnswer ?? '').trim();
    final correct = question.correctAnswer;
    if (_isWrittenCorrect()) {
      return 'Correct: $a';
    }
    if (a.isEmpty) return 'Wrong (blank). Correct answer: $correct';
    return 'Wrong: $a · Correct answer: $correct';
  }
}

// ─── Option State ─────────────────────────────────────────────────────────────

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.shakeAnimation,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final Animation<double> shakeAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    Widget? trailing;

    switch (state) {
      case _OptionState.correct:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        trailing = const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 22,
        );
      case _OptionState.wrong:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        trailing = const Icon(
          Icons.cancel_rounded,
          color: Colors.red,
          size: 22,
        );
      case _OptionState.idle:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurface;
        trailing = null;
    }

    Widget tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: state == _OptionState.correct
                ? Colors.green.shade400
                : state == _OptionState.wrong
                ? Colors.red.shade400
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );

    if (state == _OptionState.wrong) {
      tile = AnimatedBuilder(
        animation: shakeAnimation,
        builder: (context, child) {
          final offset = sin(shakeAnimation.value * pi * 4) * 6;
          return Transform.translate(offset: Offset(offset, 0), child: child);
        },
        child: tile,
      );
    }

    return tile;
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _QuizProgress extends StatelessWidget {
  const _QuizProgress({
    required this.current,
    required this.total,
    required this.score,
  });

  final int current;
  final int total;
  final int score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question $current / $total',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '$score correct',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: current / total, minHeight: 6),
        ),
      ],
    );
  }
}

// ─── Result Screen ────────────────────────────────────────────────────────────

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({
    required this.score,
    required this.total,
    required this.onRetry,
    required this.onChangeMode,
  });

  final int score;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onChangeMode;

  String get _emoji {
    final pct = score / total;
    if (pct == 1.0) return '🏆';
    if (pct >= 0.8) return '🎉';
    if (pct >= 0.6) return '👍';
    if (pct >= 0.4) return '📚';
    return '💪';
  }

  String get _message {
    final pct = score / total;
    if (pct == 1.0) return 'Perfect score!';
    if (pct >= 0.8) return 'Excellent work!';
    if (pct >= 0.6) return 'Good job!';
    if (pct >= 0.4) return 'Keep practicing!';
    return 'Don\'t give up!';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (score / total * 100).toInt();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              _message,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // Score circle
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score/$total',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onChangeMode,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Change Mode'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Words'),
            ),
          ],
        ),
      ),
    );
  }
}
