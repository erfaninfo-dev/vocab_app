import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../core/errors/user_friendly_error.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/locale/ui_locale_provider.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../domain/vocab_quiz_providers.dart';
import '../../l10n/app_localizations.dart';
import '../words/important_words_controller.dart';
import 'quiz_screen.dart';

/// Pick unit(s), question count (min 10 when enough words exist), and scope for book-level quiz.
class BookVocabQuizSetupScreen extends ConsumerStatefulWidget {
  const BookVocabQuizSetupScreen({
    super.key,
    required this.bookId,
    this.initialSelectedUnits,
  });

  final int bookId;
  final Set<int>? initialSelectedUnits;

  @override
  ConsumerState<BookVocabQuizSetupScreen> createState() =>
      _BookVocabQuizSetupScreenState();
}

class _BookVocabQuizSetupScreenState
    extends ConsumerState<BookVocabQuizSetupScreen> {
  final Set<int> _selectedUnits = {};
  _WordPoolChoice _wordPool = _WordPoolChoice.all;
  int _questionCount = 20;
  bool _seededUnits = false;

  Set<VocabQuestionMode> _questionModes = {VocabQuestionMode.mcqWordToMeaning};

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(uiLocaleProvider);
    final l10n = lookupAppLocalizations(locale);
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    final scheme = Theme.of(context).colorScheme;
    final unitsAsync = ref.watch(apiUnitsProvider(widget.bookId));
    final allWordsAsync = ref.watch(apiAllWordsForBookProvider(widget.bookId));
    final wrongsAsync = ref.watch(
      vocabQuizWrongsProvider((bookId: widget.bookId, unit: null)),
    );
    final loggedIn = ref.watch(authProvider).valueOrNull != null;
    final importantState = ref.watch(importantWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vocabularyQuizTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: l10n.vocabQuizHistoryTitle,
            onPressed: () => context.push('/vocab-quiz/history'),
          ),
        ],
      ),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userFriendlyErrorMessage(e, l10n))),
        data: (units) {
          if (!_seededUnits && units.isNotEmpty) {
            _seededUnits = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                final available = units.map((e) => e.unit).toSet();
                final seed =
                    widget.initialSelectedUnits
                        ?.where((u) => available.contains(u))
                        .toSet() ??
                    <int>{};
                _selectedUnits
                  ..clear()
                  ..addAll(seed.isNotEmpty ? seed : available);
              });
            });
          }

          return allWordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text(userFriendlyErrorMessage(e, l10n))),
            data: (allWords) {
              return wrongsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    Center(child: Text(l10n.couldNotLoadMistakesShort)),
                data: (wrongs) {
                  final wrongsInSelectedUnits = wrongs
                      .where((w) => _selectedUnits.contains(w.unit))
                      .toList();
                  final wrongKeys = wrongsInSelectedUnits
                      .map((w) => w.wordKey)
                      .toList();
                  final wrongsOnly = _wordPool == _WordPoolChoice.mistakesOnly;
                  final quizImportantOnly =
                      _wordPool == _WordPoolChoice.importantOnly;

                  bool userImp(VocabEntry e) => importantState.isMarked(e);
                  final allInUnits = allWords
                      .where((e) => _selectedUnits.contains(e.unit))
                      .toList();
                  final hasImportantInSelection = allInUnits.any(userImp);

                  List<VocabEntry> basePoolForSelection() {
                    final us = _selectedUnits;
                    var w = allWords.where((e) => us.contains(e.unit)).toList();
                    if (wrongsOnly) {
                      w = w
                          .where(
                            (e) => wrongKeys.any((k) => e.matchesWrongKey(k)),
                          )
                          .toList();
                    }
                    return w;
                  }

                  final basePool = basePoolForSelection();
                  final effectivePool =
                      hasImportantInSelection && quizImportantOnly
                      ? basePool.where(userImp).toList()
                      : basePool;

                  final poolSize = effectivePool.length;
                  final mistakeCount = wrongsInSelectedUnits.length;
                  final maxQ = wrongsOnly && mistakeCount > 0
                      ? math.min(poolSize, mistakeCount)
                      : poolSize;
                  final needsMcq = _questionModes.any((m) => m.isMcq);
                  final distractorPool =
                      hasImportantInSelection && quizImportantOnly
                      ? allInUnits.where(userImp).toList()
                      : allInUnits;
                  final baseMinQ = maxQ >= 10 ? 10 : (maxQ > 0 ? maxQ : 0);
                  // Keep min questions >= selected units (when possible).
                  final minByUnits = _selectedUnits.length.clamp(0, maxQ);
                  final minQ = maxQ == 0 ? 0 : math.max(baseMinQ, minByUnits);
                  if (_questionCount > maxQ && maxQ > 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _questionCount = maxQ);
                    });
                  }
                  if (maxQ > 0 && _questionCount < minQ) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _questionCount = minQ);
                    });
                  }

                  final canStart =
                      maxQ >= 1 &&
                      (needsMcq
                          ? (wrongsOnly
                                ? (poolSize >= 1 && distractorPool.length >= 4)
                                : poolSize >= 4)
                          : poolSize >= 1);

                  final disabledReason =
                      canStart
                          ? null
                          : poolSize == 0 &&
                                  hasImportantInSelection &&
                                  quizImportantOnly
                          ? l10n.bookQuizPoolTooSmallImportant
                          : poolSize == 0 && loggedIn && wrongsOnly
                          ? l10n.quizNotEnoughWrongs
                          : needsMcq &&
                                  poolSize > 0 &&
                                  distractorPool.length < 4
                          ? l10n.quizNeedFourWords
                          : l10n.bookQuizPoolTooSmall;

                  void startQuiz() {
                    final u = _selectedUnits.toList()..sort();
                    final scope = wrongsOnly ? 'wrongs' : 'all';
                    var path =
                        '/books/${widget.bookId}/quiz?units=${u.join(',')}&count=$_questionCount&scope=$scope&important=${quizImportantOnly ? 1 : 0}';
                    final csv = _questionModes.map((m) => m.name).toList()
                      ..sort();
                    path += '&modes=${Uri.encodeQueryComponent(csv.join(','))}';
                    context.push(path);
                  }

                  // Keep enough padding so the bottom CTA never overlaps content.
                  const bottomCtaSpace = 120.0;

                  if (_wordPool == _WordPoolChoice.importantOnly &&
                      !hasImportantInSelection) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _wordPool = _WordPoolChoice.all);
                    });
                  }
                  if (_wordPool == _WordPoolChoice.mistakesOnly &&
                      (!loggedIn || wrongsInSelectedUnits.isEmpty)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _wordPool = _WordPoolChoice.all);
                    });
                  }

                  return Scaffold(
                    body: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, bottomCtaSpace),
                      children: [
                      Text(
                        l10n.unitsSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final u in units)
                              FilterChip(
                                label: Text(
                                  l10nEn.unitLabel(u.unit),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontSize: 13),
                                ),
                                selected: _selectedUnits.contains(u.unit),
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _selectedUnits.add(u.unit);
                                    } else {
                                      _selectedUnits.remove(u.unit);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.bookQuizWordPoolTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Column(
                          children: [
                            _WordPoolToggleTile(
                              title: Text(l10n.allWordsChip),
                              value: _wordPool == _WordPoolChoice.all,
                              onChanged: (v) {
                                if (!v) return;
                                setState(() => _wordPool = _WordPoolChoice.all);
                              },
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                            _WordPoolToggleTile(
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.importantOnlyChip),
                                ],
                              ),
                              value: _wordPool == _WordPoolChoice.importantOnly,
                              onChanged: hasImportantInSelection
                                  ? (v) {
                                      if (!v) return;
                                      setState(() => _wordPool =
                                          _WordPoolChoice.importantOnly);
                                    }
                                  : null,
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                            _WordPoolToggleTile(
                              title: Text(
                                '${l10n.onlyPastMistakes} (${wrongsInSelectedUnits.length})',
                              ),
                              value: _wordPool == _WordPoolChoice.mistakesOnly,
                              onChanged: loggedIn &&
                                      wrongsInSelectedUnits.isNotEmpty
                                  ? (v) {
                                      if (!v) return;
                                      setState(() => _wordPool =
                                          _WordPoolChoice.mistakesOnly);
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.questionModes,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in VocabQuestionMode.values)
                            FilterChip(
                              label: Text(m.l10nLabel(l10n)),
                              selected: _questionModes.contains(m),
                              showCheckmark: false,
                              onSelected: (v) {
                                setState(() {
                                  final next = {..._questionModes};
                                  if (v) {
                                    next.add(m);
                                  } else {
                                    next.remove(m);
                                  }
                                  if (next.isEmpty) next.add(m);
                                  _questionModes = next;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.bookQuizQuestionsSlider(maxQ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Slider(
                        min: minQ > 0 ? minQ.toDouble() : 1,
                        max: maxQ > 0 ? maxQ.toDouble() : 1,
                        divisions: maxQ > minQ ? maxQ - minQ : null,
                        label: '$_questionCount',
                        value: _questionCount
                            .clamp(minQ, maxQ > 0 ? maxQ : 1)
                            .toDouble(),
                        onChanged: maxQ <= 0
                            ? null
                            : (v) => setState(() => _questionCount = v.round()),
                      ),
                    ],
                    ),
                    bottomNavigationBar: SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.98),
                          border: Border(
                            top: BorderSide(
                              color: scheme.outlineVariant.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (disabledReason != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  disabledReason,
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.error,
                                        height: 1.3,
                                      ),
                                ),
                              ),
                            FilledButton.icon(
                              onPressed: canStart ? startQuiz : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(l10n.startQuiz),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

enum _WordPoolChoice {
  all,
  importantOnly,
  mistakesOnly,
}

class _WordPoolToggleTile extends StatelessWidget {
  const _WordPoolToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final Widget title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final effective = onChanged == null ? null : (bool v) => onChanged!(v);
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      title: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        child: title,
      ),
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch(
          value: value,
          onChanged: effective,
        ),
      ),
      onTap: effective == null
          ? null
          : () {
              if (!value) effective(true);
            },
    );
  }
}
