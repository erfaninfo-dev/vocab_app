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
  bool _filterImportant = false;
  bool _filterMistakes = false;
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
                final seed = widget.initialSelectedUnits
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
                  final wrongKeys =
                      wrongsInSelectedUnits.map((w) => w.wordKey).toList();
                  final wrongsOnly = _filterMistakes;
                  final quizImportantOnly = _filterImportant;

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

                  final canStart = maxQ >= 1 &&
                      (needsMcq
                          ? (wrongsOnly
                              ? (poolSize >= 1 &&
                                  distractorPool.length >= 4)
                              : poolSize >= 4)
                          : poolSize >= 1);

                  if (_filterImportant && !hasImportantInSelection) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _filterImportant = false);
                    });
                  }
                  if (_filterMistakes &&
                      (!loggedIn || wrongsInSelectedUnits.isEmpty)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _filterMistakes = false);
                    });
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      Text(
                        l10n.bookQuizSetupIntro,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: Text(l10n.allWordsChip),
                            selected:
                                !_filterImportant && !_filterMistakes,
                            showCheckmark: false,
                            onSelected: (v) {
                              if (v) {
                                setState(() {
                                  _filterImportant = false;
                                  _filterMistakes = false;
                                });
                              }
                            },
                          ),
                          FilterChip(
                            avatar: Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                              color: !hasImportantInSelection
                                  ? scheme.onSurfaceVariant
                                  : _filterImportant
                                      ? scheme.onSecondaryContainer
                                      : scheme.primary,
                            ),
                            label: Text(l10n.importantOnlyChip),
                            selected: _filterImportant,
                            showCheckmark: false,
                            onSelected: hasImportantInSelection
                                ? (v) =>
                                    setState(() => _filterImportant = v)
                                : null,
                          ),
                          FilterChip(
                            label: Text(
                              '${l10n.onlyPastMistakes} (${wrongsInSelectedUnits.length})',
                            ),
                            selected: _filterMistakes,
                            showCheckmark: false,
                            onSelected: loggedIn &&
                                    wrongsInSelectedUnits.isNotEmpty
                                ? (v) =>
                                    setState(() => _filterMistakes = v)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (quizImportantOnly && hasImportantInSelection)
                        Text(
                          l10n.importantWordsServerHint,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      if (wrongsOnly && loggedIn && wrongsInSelectedUnits.isEmpty)
                        Text(
                          l10n.noMistakesYet,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      if (!loggedIn) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.signInForMistakes,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
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
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: canStart
                            ? () {
                                final u = _selectedUnits.toList()..sort();
                                final scope = wrongsOnly ? 'wrongs' : 'all';
                                var path =
                                    '/books/${widget.bookId}/quiz?units=${u.join(',')}&count=$_questionCount&scope=$scope&important=${_filterImportant ? 1 : 0}';
                                final csv =
                                    _questionModes.map((m) => m.name).toList()
                                      ..sort();
                                path +=
                                    '&modes=${Uri.encodeQueryComponent(csv.join(','))}';
                                context.push(path);
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.startQuiz),
                      ),
                      if (!canStart)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            poolSize == 0 &&
                                hasImportantInSelection &&
                                quizImportantOnly
                                ? l10n.bookQuizPoolTooSmallImportant
                                : poolSize == 0 && loggedIn && wrongsOnly
                                ? l10n.quizNotEnoughWrongs
                                : needsMcq &&
                                        poolSize > 0 &&
                                        distractorPool.length < 4
                                ? l10n.quizNeedFourWords
                                : l10n.bookQuizPoolTooSmall,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.error),
                          ),
                        ),
                    ],
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
