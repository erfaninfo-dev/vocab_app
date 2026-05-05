import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/language/language_provider.dart';
import '../../core/stats/stats_service.dart';
import '../../core/tts/tts_service.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../domain/vocab_quiz_providers.dart';
import '../../l10n/app_localizations.dart';
import '../words/important_words_controller.dart';
import 'widgets/slider_with_value_below.dart';

/// Upper bound for deep-link `?count=` only; UI max is always the live pool size.
const int kVocabQuizRouteCountCap = 10000;

bool _writtenFirstLetterMismatch(String typed, String correctAnswer) {
  final left = typed.trimLeft();
  if (left.isEmpty) return false;
  final ca = correctAnswer.trim();
  if (ca.isEmpty) return false;
  final tFirst = left.characters.first.toLowerCase();
  final cFirst = ca.characters.first.toLowerCase();
  return tFirst != cFirst;
}

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
  mcqWordToMeaning(Icons.translate_rounded),
  mcqMeaningToWord(Icons.text_fields_rounded),
  writtenMeaningToWord(Icons.edit_rounded),
  spellingListenAndType(Icons.hearing_rounded);

  const VocabQuestionMode(this.icon);
  final IconData icon;

  String l10nLabel(AppLocalizations l10n) {
    switch (this) {
      case VocabQuestionMode.mcqWordToMeaning:
        return l10n.quizMcqWordToMeaning;
      case VocabQuestionMode.mcqMeaningToWord:
        return l10n.quizMcqMeaningToWord;
      case VocabQuestionMode.writtenMeaningToWord:
        return l10n.quizWrittenMeaningToWord;
      case VocabQuestionMode.spellingListenAndType:
        return l10n.quizSpellingListenAndType;
    }
  }

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
    required this.questionMode,
    this.playsAudio = false,
  });

  final VocabEntry entry;
  final String prompt;
  final String promptSub; // secondary line (e.g. type or fa meaning)
  final String correctAnswer;
  final List<String> options;
  final _QuestionKind kind;
  final VocabQuestionMode questionMode;

  /// TTS auto-play + replay for listen-and-spell questions.
  final bool playsAudio;
}

// ─── Quiz Screen ──────────────────────────────────────────────────────────────

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.bookId, this.unit, this.section});

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

  /// Per-question log for server sync (same order as [_questions] after session ends).
  final List<Map<String, dynamic>> _sessionAnswerLog = [];

  /// From setup: all words in pool, or wrong-words only.
  bool _scopeWrongsOnly = false;
  int _questionBudget = 20;
  bool _removingLearned = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late final TextEditingController _writtenCtrl;
  bool _autoStartScheduled = false;

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
    List<VocabEntry> questionWords,
    List<VocabEntry> distractorWords,
    TranslationLang lang,
    int maxQuestions,
    Set<VocabQuestionMode> modes,
  ) {
    if (questionWords.isEmpty) return [];
    final rng = Random();

    // Filter: only words with both word and at least one meaning
    final usable = questionWords
        .where(
          (w) =>
              w.word.isNotEmpty &&
              (w.meaningEn.isNotEmpty || w.meaningFor(lang).isNotEmpty),
        )
        .toList();

    if (usable.isEmpty) return [];

    final usableDistractors = distractorWords
        .where(
          (w) =>
              w.word.isNotEmpty &&
              (w.meaningEn.isNotEmpty || w.meaningFor(lang).isNotEmpty),
        )
        .toList();
    if (usableDistractors.isEmpty) return [];

    final cap = max(1, maxQuestions);
    final selected = modes.isEmpty
        ? <VocabQuestionMode>{VocabQuestionMode.mcqWordToMeaning}
        : {...modes};

    String meaningForQuiz(VocabEntry w) {
      final local = w.meaningFor(lang);
      return local.isNotEmpty ? local : w.meaningEn;
    }

    final Map<VocabQuestionMode, List<_Question>> buckets = {
      for (final m in selected) m: <_Question>[],
    };

    final shuffledWords = [...usable]..shuffle(rng);
    for (final word in shuffledWords) {
      // Mistakes pool is small: one question per word so the same headword
      // does not repeat back-to-back in different modes. Full mix stays for
      // normal (non-mistakes) quizzes.
      final modesThisWord = _scopeWrongsOnly
          ? ([...selected]..shuffle(rng))
          : selected.toList();
      for (final m in modesThisWord) {
        if (m == VocabQuestionMode.writtenMeaningToWord ||
            m == VocabQuestionMode.spellingListenAndType) {
          final localMeaning = word.meaningFor(lang);
          final prompt = localMeaning.isNotEmpty
              ? localMeaning
              : word.meaningEn;
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
              questionMode: m,
              playsAudio: m == VocabQuestionMode.spellingListenAndType,
            ),
          );
          if (_scopeWrongsOnly) break;
          continue;
        }

        // Distractor preference order (fast + higher quality):
        // 1) same section (if any) → 2) same unit → 3) rest of distractor scope
        final candidates = usableDistractors
            .where((w) => w.id != word.id)
            .toList();

        List<VocabEntry> shuffled(List<VocabEntry> xs) {
          final out = [...xs]..shuffle(rng);
          return out;
        }

        final sameSection = <VocabEntry>[];
        if (word.section != null) {
          for (final w in candidates) {
            if (w.unit == word.unit && w.section == word.section) {
              sameSection.add(w);
            }
          }
        }

        final sameUnit = <VocabEntry>[];
        for (final w in candidates) {
          if (w.unit == word.unit &&
              (word.section == null || w.section != word.section)) {
            sameUnit.add(w);
          }
        }

        final rest = <VocabEntry>[];
        for (final w in candidates) {
          if (w.unit != word.unit) rest.add(w);
        }

        final ordered = <VocabEntry>[
          ...shuffled(sameSection),
          ...shuffled(sameUnit),
          ...shuffled(rest),
        ];

        final wrongPool = ordered.take(3).toList();
        if (wrongPool.length < 3) continue;

        if (m == VocabQuestionMode.mcqWordToMeaning) {
          final correct = meaningForQuiz(word);
          final wrongs = wrongPool.map(meaningForQuiz).toList();
          final opts = [correct, ...wrongs]..shuffle(rng);
          buckets[m]!.add(
            _Question(
              entry: word,
              prompt: word.word,
              promptSub: word.type,
              correctAnswer: correct,
              options: opts,
              kind: _QuestionKind.mcq,
              questionMode: m,
            ),
          );
          if (_scopeWrongsOnly) break;
        } else if (m == VocabQuestionMode.mcqMeaningToWord) {
          final localMeaning = word.meaningFor(lang);
          final prompt = localMeaning.isNotEmpty
              ? localMeaning
              : word.meaningEn;
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
              questionMode: m,
            ),
          );
          if (_scopeWrongsOnly) break;
        }
      }
    }

    // Break lock-step order between modes (same word was always adjacent).
    for (final m in selected) {
      buckets[m]!.shuffle(rng);
    }

    final out = <_Question>[];
    final keys = selected.toList();
    var cursor = 0;
    String? lastEntryId;

    while (out.length < cap) {
      var addedAny = false;
      for (var k = 0; k < keys.length && out.length < cap; k++) {
        final m = keys[(cursor + k) % keys.length];
        final b = buckets[m]!;
        if (b.isEmpty) continue;

        var takeIndex = 0;
        if (lastEntryId != null) {
          final prefer = b.indexWhere((q) => q.entry.id != lastEntryId);
          takeIndex = prefer >= 0 ? prefer : 0;
        }

        final q = b.removeAt(takeIndex);
        out.add(q);
        lastEntryId = q.entry.id;
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

  void _startQuiz(
    List<VocabEntry> words,
    TranslationLang lang,
    int budget, {
    List<VocabEntry>? distractors,
  }) {
    setState(() {
      _questions = _buildQuestions(
        words,
        distractors ?? words,
        lang,
        budget,
        _effectiveModes(),
      );
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _sessionDone = false;
      _sessionAnswerLog.clear();
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
          await ref
              .read(apiServiceProvider)
              .addVocabQuizWrong(
                bookId: widget.bookId,
                unit: q.entry.unit,
                wordKey: q.entry.id,
              );
          _invalidateWrongs();
        } catch (_) {}
      }
    } else if (_scopeWrongsOnly) {
      // In mistakes-only drill, a correct recall should clear this word from the
      // server list so counts (e.g. setup "Only past mistakes (n)") stay honest.
      final session = ref.read(authProvider).valueOrNull;
      if (session != null) {
        final api = ref.read(apiServiceProvider);
        unawaited(() async {
          try {
            await api.removeVocabQuizWrong(
              bookId: widget.bookId,
              unit: q.entry.unit,
              wordKey: q.entry.id,
            );
            _invalidateWrongs();
          } catch (_) {}
        }());
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
      await ref
          .read(apiServiceProvider)
          .removeVocabQuizWrong(
            bookId: widget.bookId,
            unit: q.entry.unit,
            wordKey: q.entry.id,
          );
      _invalidateWrongs();
      if (mounted) {
        final msg = AppLocalizations.of(context)!;
        // Advance first so feedback is not stuck on the answered question;
        // show SnackBar after layout so it targets the updated screen.
        ScaffoldMessenger.of(context).clearSnackBars();
        _next();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg.removedFromMistakes)));
        });
      }
    } catch (_) {
      if (mounted) {
        final msg = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg.couldNotUpdateServer)));
      }
    } finally {
      if (mounted) setState(() => _removingLearned = false);
    }
  }

  void _appendSessionAnswerLog() {
    if (_questions.isEmpty || !_answered) return;
    final q = _questions[_currentIndex];
    final ans = _selectedAnswer ?? '';
    _sessionAnswerLog.add({
      'word_key': q.entry.id,
      'unit': q.entry.unit,
      'word': q.entry.word,
      'correct': _isCorrect(q, ans),
      'given': ans,
      'mode': q.questionMode.name,
    });
  }

  Future<void> _submitVocabQuizSessionToServer() async {
    final auth = ref.read(authProvider).valueOrNull;
    if (auth == null) return;
    if (_sessionAnswerLog.length != _questions.length) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final unitSet = <int>{};
    for (final q in _questions) {
      unitSet.add(q.entry.unit);
    }
    final unitsList = unitSet.toList()..sort();
    String? bookTitle;
    try {
      final books = await ref.read(apiBooksProvider.future);
      for (final b in books) {
        if (b.id == widget.bookId) {
          bookTitle = b.title;
          break;
        }
      }
      if (bookTitle == null || bookTitle.isEmpty) {
        final studentBooks = await ref
            .read(apiServiceProvider)
            .fetchBooks(scope: 'student');
        for (final b in studentBooks) {
          if (b.id == widget.bookId) {
            bookTitle = b.title;
            break;
          }
        }
      }
    } catch (_) {}
    try {
      await ref
          .read(apiServiceProvider)
          .submitVocabQuizResult(
            bookId: widget.bookId,
            score: _score,
            totalQuestions: _questions.length,
            session: {
              'meta': <String, dynamic>{
                if (bookTitle != null && bookTitle.isNotEmpty)
                  'book_title': bookTitle,
                'quiz_name': l10n.vocabularyQuizTitle,
                'units': unitsList,
              },
              'items': List<Map<String, dynamic>>.from(_sessionAnswerLog),
            },
          );
      ref.invalidate(myVocabQuizResultsProvider);
    } catch (_) {}
  }

  void _next() {
    unawaited(ref.read(ttsProvider.notifier).stop());
    _appendSessionAnswerLog();
    if (_currentIndex >= _questions.length - 1) {
      setState(() => _sessionDone = true);
      unawaited(_submitVocabQuizSessionToServer());
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
      _questionBudget = c.clamp(1, kVocabQuizRouteCountCap);
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
      final parts = modesCsv
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
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

  List<VocabEntry> _applyImportantFilter(
    List<VocabEntry> pool,
    int scope,
    bool Function(VocabEntry) userImportant,
  ) {
    if (scope == 1) {
      return pool.where(userImportant).toList();
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
      pool = pool
          .where((w) => wrongKeys.any((k) => w.matchesWrongKey(k)))
          .toList();
    }
    return pool;
  }

  bool get _inActiveSession => _questions.isNotEmpty && !_sessionDone;

  Future<bool> _confirmExitQuiz() async {
    if (!_inActiveSession) return true;

    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vocabQuizExitTitle),
        content: Text(l10n.vocabQuizExitBody),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.continueLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.exit),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  int? _firstUnitFromQuery(GoRouterState route) {
    final unitsCsv = route.uri.queryParameters['units'] ?? '';
    for (final part in unitsCsv.split(',')) {
      final v = int.tryParse(part.trim());
      if (v != null) return v;
    }
    return null;
  }

  void _openWordsList(BuildContext context) {
    final route = GoRouterState.of(context);
    if (widget.unit != null) {
      final u = widget.unit!;
      final s = widget.section;
      if (s != null) {
        context.go('/books/${widget.bookId}/units/$u/sections/$s/words');
      } else {
        context.go('/books/${widget.bookId}/units/$u/words');
      }
      return;
    }
    if (_questions.isNotEmpty) {
      final e = _questions.first.entry;
      if (e.section != null) {
        context.go(
          '/books/${widget.bookId}/units/${e.unit}/sections/${e.section}/words',
        );
      } else {
        context.go('/books/${widget.bookId}/units/${e.unit}/words');
      }
      return;
    }
    final u = _firstUnitFromQuery(route);
    if (u != null) {
      context.go('/books/${widget.bookId}/units/$u/words');
      return;
    }
    context.go('/books/${widget.bookId}/units');
  }

  void _backToVocabQuizSetup(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/books/${widget.bookId}/vocab-quiz');
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureRouteDefaults();
    final lang = ref.watch(langProvider);
    final route = GoRouterState.of(context);
    final qp = route.uri.queryParameters;
    final autoStartFromRoute =
        qp.containsKey('count') || qp.containsKey('modes');
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
      vocabQuizWrongsProvider((bookId: widget.bookId, unit: widget.unit)),
    );
    final importantState = ref.watch(importantWordsProvider);

    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.quizTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: l10n.vocabQuizHistoryTitle,
            onPressed: () => context.push('/vocab-quiz/history'),
          ),
          if (_questions.isNotEmpty && !_sessionDone)
            Padding(
              padding: const EdgeInsets.only(right: 8),
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
        canPop: !_inActiveSession,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final ok = await _confirmExitQuiz();
          if (!ok || !context.mounted) return;
          Navigator.of(context).pop();
        },
        child: wordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.couldNotLoadWords)),
          data: (words) {
            return wrongsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l10n.couldNotLoadMistakes)),
              data: (wrongs) {
                final wrongsForUnits = widget.unit != null
                    ? wrongs
                    : (unitFilter.isEmpty
                          ? wrongs
                          : wrongs
                                .where((w) => unitFilter.contains(w.unit))
                                .toList());
                final wrongKeys = wrongsForUnits.map((w) => w.wordKey).toSet();
                final basePool = _filterPool(
                  words,
                  widget.unit == null ? unitFilter : <int>{},
                  _scopeWrongsOnly,
                  wrongKeys,
                );
                final basePoolAllSelected = _filterPool(
                  words,
                  widget.unit == null ? unitFilter : <int>{},
                  false,
                  wrongKeys,
                );
                bool userImp(VocabEntry w) => importantState.isMarked(w);
                final hasImportant = basePool.any(userImp);
                final resolvedScope = _resolvedImportantScope(hasImportant);
                if (hasImportant && resolvedScope == null) {
                  final nImp = basePool.where(userImp).length;
                  return _ImportantChoicePanel(
                    l10n: l10n,
                    allCount: basePool.length,
                    importantCount: nImp,
                    onAllWords: () => setState(() => _userImportantScope = 0),
                    onImportantOnly: () =>
                        setState(() => _userImportantScope = 1),
                  );
                }

                final pool = _applyImportantFilter(
                  basePool,
                  resolvedScope!,
                  userImp,
                );
                final distractorPool = _applyImportantFilter(
                  basePoolAllSelected,
                  resolvedScope,
                  userImp,
                );

                final selectedModes = _effectiveModes();
                final needsMcq = selectedModes.any((m) => m.isMcq);
                final canMcq =
                    !needsMcq ||
                    (_scopeWrongsOnly
                        ? pool.isNotEmpty && distractorPool.length >= 4
                        : pool.length >= 4);
                final canStart = needsMcq ? canMcq : pool.isNotEmpty;

                if (!canStart) {
                  final importantTooSmall =
                      resolvedScope == 1 &&
                      hasImportant &&
                      basePool.length >= 4;
                  final message = importantTooSmall
                      ? l10n.quizNotEnoughImportant
                      : _scopeWrongsOnly && pool.isEmpty
                          ? l10n.quizNotEnoughWrongs
                          : needsMcq
                              ? l10n.quizNeedFourWords
                              : l10n.quizNeedOneWord;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _backToVocabQuizSetup(context),
                                icon: const Icon(Icons.quiz_outlined),
                                label: Text(l10n.backToQuiz),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => _openWordsList(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(l10n.backToWords),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final loggedIn = ref.watch(authProvider).valueOrNull != null;
                final maxQ = pool.length;
                final minPick = _scopeWrongsOnly
                    ? (maxQ > 0 ? 1 : 0)
                    : (pool.length >= 10 ? 10 : pool.length);

                if (_questions.isEmpty) {
                  if (autoStartFromRoute) {
                    if (!_autoStartScheduled) {
                      _autoStartScheduled = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final b = _questionBudget.clamp(minPick, maxQ);
                        _startQuiz(
                          pool,
                          lang,
                          b,
                          distractors: _scopeWrongsOnly ? distractorPool : null,
                        );
                      });
                    }
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _ModeSelector(
                    selectedModes: selectedModes,
                    poolSize: pool.length,
                    scopeWrongsOnly: _scopeWrongsOnly,
                    wrongOnServer: wrongsForUnits.length,
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
                      _startQuiz(
                        pool,
                        lang,
                        b,
                        distractors: _scopeWrongsOnly ? distractorPool : null,
                      );
                    },
                  );
                }

                if (_sessionDone) {
                  return _ResultScreen(
                    l10n: l10n,
                    score: _score,
                    total: _questions.length,
                    onRetry: () {
                      final b = _questionBudget.clamp(minPick, maxQ);
                      _startQuiz(pool, lang, b);
                    },
                    onBackToQuiz: () => _backToVocabQuizSetup(context),
                    onBackToWords: () => _openWordsList(context),
                  );
                }

                final q = _questions[_currentIndex];
                final showLearned =
                    _scopeWrongsOnly &&
                    loggedIn &&
                    _answered &&
                    _selectedAnswer == q.correctAnswer;

                return SingleChildScrollView(
                  child: _QuizBody(
                    l10n: l10n,
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
    required this.l10n,
    required this.allCount,
    required this.importantCount,
    required this.onAllWords,
    required this.onImportantOnly,
  });

  final AppLocalizations l10n;
  final int allCount;
  final int importantCount;
  final VoidCallback onAllWords;
  final VoidCallback onImportantOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 52, color: scheme.primary),
            const SizedBox(height: 20),
            Text(
              l10n.quizScopeTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.quizScopeImportantDescription,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onAllWords,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.allWordsCount(allCount)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onImportantOnly,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.importantWordsOnlyCount(importantCount)),
              ),
            ),
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.quizSetupTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.quizPoolSummary(poolSize, minQuestionPick, maxQuestionPick),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (loggedIn) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                value: scopeWrongsOnly,
                onChanged: wrongOnServer == 0 ? null : (v) => onScopeChanged(v),
                title: Text(l10n.onlyPastMistakes),
                subtitle: Text(
                  wrongOnServer == 0
                      ? l10n.noMistakesYet
                      : l10n.mistakesOnServer(wrongOnServer),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                l10n.signInForMistakes,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.numberOfQuestions,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SliderWithValueBelow(
              min: low,
              max: high,
              divisions: divisions,
              displayValue:
                  questionBudget.clamp(minQuestionPick, maxQuestionPick),
              sliderValue: questionBudget
                  .clamp(minQuestionPick, maxQuestionPick)
                  .toDouble(),
              onChanged: maxQuestionPick < 1
                  ? null
                  : (v) => onQuestionBudgetChanged(v.round()),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.questionModes,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
                        Text(m.l10nLabel(l10n)),
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
                label: Text(l10n.startQuiz),
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

class _QuizBody extends ConsumerStatefulWidget {
  const _QuizBody({
    required this.l10n,
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

  final AppLocalizations l10n;
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
  ConsumerState<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends ConsumerState<_QuizBody> {
  late final TtsNotifier _ttsNotifier;

  void _onWrittenTextChanged() {
    if (!mounted) return;
    if (widget.answered) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _ttsNotifier = ref.read(ttsProvider.notifier);
    widget.writtenController.addListener(_onWrittenTextChanged);
    _scheduleAutoSpeak();
  }

  @override
  void didUpdateWidget(covariant _QuizBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.writtenController != widget.writtenController) {
      oldWidget.writtenController.removeListener(_onWrittenTextChanged);
      widget.writtenController.addListener(_onWrittenTextChanged);
    }
    if (oldWidget.question.entry.id != widget.question.entry.id ||
        oldWidget.question.playsAudio != widget.question.playsAudio) {
      unawaited(_ttsNotifier.stop());
      _scheduleAutoSpeak();
    }
  }

  @override
  void dispose() {
    widget.writtenController.removeListener(_onWrittenTextChanged);
    unawaited(_ttsNotifier.stop());
    super.dispose();
  }

  void _scheduleAutoSpeak() {
    if (!widget.question.playsAudio) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final w = widget.question.entry.word.trim();
      if (w.isEmpty) return;
      unawaited(ref.read(ttsProvider.notifier).speak(w));
    });
  }

  void _replayAudio() {
    final w = widget.question.entry.word.trim();
    if (w.isEmpty) return;
    unawaited(ref.read(ttsProvider.notifier).speak(w));
  }

  /// Soft tinted surface + subtle colored shadow for written-answer feedback.
  BoxDecoration _writtenFeedbackCardDecoration(
    BuildContext context, {
    required bool isCorrect,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final base = isCorrect ? Colors.green : Colors.red;
    final dark = scheme.brightness == Brightness.dark;
    return BoxDecoration(
      color: base.withValues(alpha: dark ? 0.16 : 0.09),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: base.withValues(alpha: dark ? 0.38 : 0.22)),
      boxShadow: [
        BoxShadow(
          color: base.withValues(alpha: dark ? 0.35 : 0.16),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildWrittenFeedback(BuildContext context) {
    final l10n = widget.l10n;
    final scheme = Theme.of(context).colorScheme;
    final body =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 15);

    if (_isWrittenCorrect()) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: _writtenFeedbackCardDecoration(
              context,
              isCorrect: true,
            ),
            child: Text(
              l10n.correctLine((widget.selectedAnswer ?? '').trim()),
              style: body.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ),
      );
    }

    final given = (widget.selectedAnswer ?? '').trim();
    final correct = widget.question.correctAnswer;
    if (given.isEmpty) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: _writtenFeedbackCardDecoration(
              context,
              isCorrect: false,
            ),
            child: RichText(
              text: TextSpan(
                style: body.copyWith(color: scheme.onSurfaceVariant),
                children: [
                  TextSpan(text: '${l10n.quizWrongBlankIntro} '),
                  TextSpan(
                    text: '${l10n.quizFeedbackCorrectLabel} ',
                    style: body.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: correct,
                    style: body.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final labelStyle = body.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final wrongAnswerStyle = body.copyWith(
      color: Colors.red.shade700,
      fontWeight: FontWeight.w600,
    );
    final correctWordStyle = body.copyWith(
      color: Colors.green.shade700,
      fontWeight: FontWeight.w600,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _writtenFeedbackCardDecoration(context, isCorrect: false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: body,
                  children: [
                    TextSpan(
                      text: '${l10n.quizFeedbackWrongPrefix} ',
                      style: labelStyle,
                    ),
                    TextSpan(text: given, style: wrongAnswerStyle),
                  ],
                ),
              ),
              if (_writtenFirstLetterMismatch(given, correct)) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.quizWrittenFirstLetterMismatch,
                  style: body.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: body,
                  children: [
                    TextSpan(
                      text: '${l10n.quizFeedbackCorrectLabel} ',
                      style: labelStyle,
                    ),
                    TextSpan(text: correct, style: correctWordStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TextDirection _meaningDirection(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'fa' || code == 'ckb') return TextDirection.rtl;
    return TextDirection.ltr;
  }

  static TextAlign _meaningAlign(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'fa' || code == 'ckb') return TextAlign.right;
    return TextAlign.center;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = widget.questionNumber == widget.total;
    final q = widget.question;
    final l10n = widget.l10n;
    final tts = ref.watch(ttsProvider);
    final speakingWord =
        q.playsAudio && tts.isSpeakingText(q.entry.word.trim());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          // ── Progress ────────────────────────────────────────────────────────
          _QuizProgress(
            l10n: l10n,
            current: widget.questionNumber,
            total: widget.total,
            score: widget.score,
          ),
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
                    q.playsAudio
                        ? l10n.quizSpellingListenPrompt
                        : (widget.mode == QuizMode.wordToMeaning
                              ? l10n.whatIsMeaningOf
                              : l10n.whichWordMeans),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.entry.section == null
                        ? l10n.wordsUnitOnly(q.entry.unit)
                        : l10n.wordsUnitSection(q.entry.unit, q.entry.section!),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Directionality(
                    textDirection: q.kind == _QuestionKind.written
                        ? _meaningDirection(context)
                        : TextDirection.ltr,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        q.prompt,
                        textAlign: q.kind == _QuestionKind.written
                            ? _meaningAlign(context)
                            : TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (q.promptSub.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: q.kind == _QuestionKind.written
                          ? _meaningDirection(context)
                          : TextDirection.ltr,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          q.promptSub,
                          textAlign: q.kind == _QuestionKind.written
                              ? _meaningAlign(context)
                              : TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ),
                  ],
                  if (q.playsAudio) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: Tooltip(
                        message: l10n.quizReplayAudio,
                        child: IconButton.filledTonal(
                          onPressed: widget.answered ? null : _replayAudio,
                          icon: speakingWord
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                )
                              : const Icon(Icons.volume_up_rounded),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Answer area ─────────────────────────────────────────────────────
          if (q.kind == _QuestionKind.written) ...[
            TextField(
              controller: widget.writtenController,
              enabled: !widget.answered,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => widget.onSubmitWritten(),
              decoration: InputDecoration(
                labelText: q.playsAudio
                    ? l10n.quizSpellingTypeEnglish
                    : l10n.typeTheWord,
                hintText: l10n.typeYourAnswer,
                border: const OutlineInputBorder(),
                errorText:
                    !widget.answered &&
                        _writtenFirstLetterMismatch(
                          widget.writtenController.text,
                          q.correctAnswer,
                        )
                    ? l10n.quizWrittenFirstLetterMismatch
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.answered ? null : widget.onSubmitWritten,
                child: Text(l10n.submit),
              ),
            ),
            if (widget.answered) ...[
              const SizedBox(height: 10),
              _buildWrittenFeedback(context),
            ],
          ] else ...[
            ...q.options.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile(
                  text: opt,
                  state: _optionState(opt),
                  shakeAnimation: widget.shakeAnimation,
                  onTap: () => widget.onSelect(opt),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ── Next button ─────────────────────────────────────────────────────
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: widget.answered ? Offset.zero : const Offset(0, 0.3),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: widget.answered ? 1 : 0,
              child: Column(
                children: [
                  if (widget.showLearnedButton && widget.onLearned != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.learnedBusy ? null : widget.onLearned,
                        icon: widget.learnedBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          widget.learnedBusy
                              ? l10n.updating
                              : l10n.learnedRemoveMistakes,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.answered ? widget.onNext : null,
                      icon: Icon(
                        isLast
                            ? Icons.emoji_events_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(isLast ? l10n.seeResults : l10n.nextQuestion),
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
    if (!widget.answered) return _OptionState.idle;
    if (opt == widget.question.correctAnswer) return _OptionState.correct;
    if (opt == widget.selectedAnswer) return _OptionState.wrong;
    return _OptionState.idle;
  }

  bool _isWrittenCorrect() {
    if (widget.question.kind != _QuestionKind.written) return false;
    final a = (widget.selectedAnswer ?? '').trim().toLowerCase();
    final c = widget.question.correctAnswer.trim().toLowerCase();
    return a.isNotEmpty && a == c;
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
    required this.l10n,
    required this.current,
    required this.total,
    required this.score,
  });

  final AppLocalizations l10n;
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
              l10n.questionProgress(current, total),
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
                  l10n.scoreCorrect(score),
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
    required this.l10n,
    required this.score,
    required this.total,
    required this.onRetry,
    required this.onBackToQuiz,
    required this.onBackToWords,
  });

  final AppLocalizations l10n;
  final int score;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onBackToQuiz;
  final VoidCallback onBackToWords;

  String get _emoji {
    final pct = score / total;
    if (pct == 1.0) return '🏆';
    if (pct >= 0.8) return '🎉';
    if (pct >= 0.6) return '👍';
    if (pct >= 0.4) return '📚';
    return '💪';
  }

  String _message() {
    final pct = score / total;
    if (pct == 1.0) return l10n.perfectScore;
    if (pct >= 0.8) return l10n.excellentWork;
    if (pct >= 0.6) return l10n.goodJob;
    if (pct >= 0.4) return l10n.keepPracticing;
    return l10n.dontGiveUp;
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
              _message(),
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
                label: Text(l10n.tryAgain),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBackToQuiz,
                icon: const Icon(Icons.quiz_outlined),
                label: Text(l10n.backToQuiz),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onBackToWords,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.backToWords),
            ),
          ],
        ),
      ),
    );
  }
}
