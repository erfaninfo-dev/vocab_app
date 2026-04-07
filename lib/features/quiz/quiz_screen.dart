import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/language/language_provider.dart';
import '../../core/stats/stats_service.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';

// ─── Quiz Mode ────────────────────────────────────────────────────────────────

enum QuizMode {
  wordToMeaning('Word → Meaning', Icons.translate_rounded),
  meaningToWord('Meaning → Word', Icons.text_fields_rounded);

  const QuizMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ─── Question model ───────────────────────────────────────────────────────────

class _Question {
  const _Question({
    required this.prompt,
    required this.promptSub,
    required this.correctAnswer,
    required this.options, // 4 items, shuffled
  });

  final String prompt;
  final String promptSub; // secondary line (e.g. type or fa meaning)
  final String correctAnswer;
  final List<String> options;
}

// ─── Quiz Screen ──────────────────────────────────────────────────────────────

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.bookId,
    required this.unit,
    this.section,
  });

  final int bookId;
  final int unit;
  final int? section;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  QuizMode _mode = QuizMode.wordToMeaning;
  List<_Question> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _sessionDone = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  List<_Question> _buildQuestions(List<VocabEntry> words, QuizMode mode, TranslationLang lang) {
    if (words.length < 2) return [];
    final rng = Random();

    // Filter: only words with both word and at least one meaning
    final usable = words
        .where((w) =>
            w.word.isNotEmpty &&
            (w.meaningEn.isNotEmpty || w.meaningFor(lang).isNotEmpty))
        .toList();

    if (usable.length < 2) return [];

    final questions = <_Question>[];

    for (final word in usable) {
      // Build wrong options from other words in the list
      final others = usable.where((w) => w.id != word.id).toList()..shuffle(rng);
      final wrongPool = others.take(3).toList();

      if (wrongPool.length < 3) continue;

      if (mode == QuizMode.wordToMeaning) {
        final correct = word.meaningEn.isNotEmpty
            ? word.meaningEn
            : word.meaningFor(lang);
        final wrongs = wrongPool.map((w) =>
            w.meaningEn.isNotEmpty ? w.meaningEn : w.meaningFor(lang)).toList();

        final opts = [correct, ...wrongs]..shuffle(rng);
        questions.add(_Question(
          prompt: word.word,
          promptSub: word.type,
          correctAnswer: correct,
          options: opts,
        ));
      } else {
        // Meaning → Word: use selected language meaning as prompt
        final localMeaning = word.meaningFor(lang);
        final prompt = localMeaning.isNotEmpty
            ? localMeaning
            : word.meaningEn;
        final correct = word.word;
        final wrongs = wrongPool.map((w) => w.word).toList();

        final opts = [correct, ...wrongs]..shuffle(rng);
        // promptSub: show English meaning only if prompt is the local meaning
        final promptSub = (localMeaning.isNotEmpty &&
                word.meaningEn.isNotEmpty)
            ? word.meaningEn
            : '';
        questions.add(_Question(
          prompt: prompt,
          promptSub: promptSub,
          correctAnswer: correct,
          options: opts,
        ));
      }
    }

    questions.shuffle(rng);
    // Limit to 20 questions per session
    return questions.take(20).toList();
  }

  void _startQuiz(List<VocabEntry> words, TranslationLang lang) {
    setState(() {
      _questions = _buildQuestions(words, _mode, lang);
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _sessionDone = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final isCorrect = answer == _questions[_currentIndex].correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) _score++;
    });
    // Log to stats
    ref.read(statsProvider.notifier).logQuizAnswer(correct: isCorrect);
    if (!isCorrect) {
      _shakeCtrl.forward(from: 0);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(
      apiWordsProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
    );
    final lang = ref.watch(langProvider);

    return Scaffold(
      appBar: AppBar(
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
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('دریافت اطلاعات انجام نشد. لطفاً دوباره تلاش کنید'),
        ),
        data: (words) {
          if (words.length < 4) {
            return const Center(
              child: Text('Need at least 4 words to start a quiz.'),
            );
          }

          if (_questions.isEmpty) {
            return _ModeSelector(
              selectedMode: _mode,
              wordCount: words.length,
              onModeChanged: (m) => setState(() => _mode = m),
              onStart: () => _startQuiz(words, lang),
            );
          }

          if (_sessionDone) {
            return _ResultScreen(
              score: _score,
              total: _questions.length,
              onRetry: () => _startQuiz(words, lang),
              onChangeMode: () => setState(() => _questions = []),
            );
          }

          final q = _questions[_currentIndex];

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
              onNext: _next,
            ),
          );
        },
      ),
    );
  }
}

// ─── Mode Selector ────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.wordCount,
    required this.onModeChanged,
    required this.onStart,
  });

  final QuizMode selectedMode;
  final int wordCount;
  final ValueChanged<QuizMode> onModeChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
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
              'Quiz Mode',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$wordCount words available • up to 20 questions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            ...QuizMode.values.map((mode) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModeTile(
                mode: mode,
                selected: selectedMode == mode,
                onTap: () => onModeChanged(mode),
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Quiz'),
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

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final QuizMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              mode.icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Text(
              mode.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle_rounded, color: scheme.primary),
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
    required this.onNext,
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
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = questionNumber == total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          // ── Progress ────────────────────────────────────────────────────────
          _QuizProgress(
            current: questionNumber,
            total: total,
            score: score,
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
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
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

          // ── Options ─────────────────────────────────────────────────────────
          ...question.options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              text: opt,
              state: _optionState(opt),
              shakeAnimation: shakeAnimation,
              onTap: () => onSelect(opt),
            ),
          )),

          const SizedBox(height: 8),

          // ── Next button ─────────────────────────────────────────────────────
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: answered ? Offset.zero : const Offset(0, 0.3),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: answered ? 1 : 0,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: answered ? onNext : null,
                  icon: Icon(
                    isLast ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(isLast ? 'See Results' : 'Next Question'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
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
        trailing = const Icon(Icons.check_circle_rounded,
            color: Colors.green, size: 22);
      case _OptionState.wrong:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        trailing =
            const Icon(Icons.cancel_rounded, color: Colors.red, size: 22);
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
          final offset =
              sin(shakeAnimation.value * pi * 4) * 6;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
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
                Icon(Icons.star_rounded,
                    size: 16, color: Colors.amber.shade600),
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
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 6,
          ),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
