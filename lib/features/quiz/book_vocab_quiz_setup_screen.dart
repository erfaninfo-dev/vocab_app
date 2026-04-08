import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../domain/vocab_quiz_providers.dart';

/// Pick unit(s), question count (min 10 when enough words exist), and scope for book-level quiz.
class BookVocabQuizSetupScreen extends ConsumerStatefulWidget {
  const BookVocabQuizSetupScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<BookVocabQuizSetupScreen> createState() =>
      _BookVocabQuizSetupScreenState();
}

class _BookVocabQuizSetupScreenState extends ConsumerState<BookVocabQuizSetupScreen> {
  final Set<int> _selectedUnits = {};
  bool _wrongsOnly = false;
  int _questionCount = 20;
  bool _seededUnits = false;
  /// When the selected pool includes important words, quiz can be all words or important-only.
  bool _quizImportantOnly = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unitsAsync = ref.watch(apiUnitsProvider(widget.bookId));
    final allWordsAsync = ref.watch(apiAllWordsForBookProvider(widget.bookId));
    final wrongsAsync = ref.watch(
      vocabQuizWrongsProvider((bookId: widget.bookId, unit: null)),
    );
    final loggedIn = ref.watch(authProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (units) {
          if (!_seededUnits && units.isNotEmpty) {
            _seededUnits = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedUnits
                  ..clear()
                  ..addAll(units.map((e) => e.unit));
              });
            });
          }

          return allWordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allWords) {
              return wrongsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Could not load mistakes')),
                data: (wrongs) {
                  final wrongKeys = wrongs.map((w) => w.wordKey).toSet();

                  List<VocabEntry> basePoolForSelection() {
                    final us = _selectedUnits;
                    var w = allWords.where((e) => us.contains(e.unit)).toList();
                    if (_wrongsOnly) {
                      w = w.where((e) => wrongKeys.contains(e.id)).toList();
                    }
                    return w;
                  }

                  final basePool = basePoolForSelection();
                  final hasImportant = basePool.any((e) => e.isImportant);
                  final effectivePool = hasImportant && _quizImportantOnly
                      ? basePool.where((e) => e.isImportant).toList()
                      : basePool;

                  final pool = effectivePool.length;
                  final maxQ = pool.clamp(0, 60);
                  final minQ = pool >= 10 ? 10 : (pool > 0 ? pool : 0);
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

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      Text(
                        'Choose units, how many questions, and whether to drill past mistakes.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Units',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final u in units)
                            FilterChip(
                              label: Text('Unit ${u.unit}'),
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
                      const SizedBox(height: 20),
                      if (loggedIn) ...[
                        SwitchListTile(
                          value: _wrongsOnly,
                          onChanged: wrongs.isEmpty
                              ? null
                              : (v) => setState(() => _wrongsOnly = v),
                          title: const Text('Only past mistakes'),
                          subtitle: Text(
                            wrongs.isEmpty
                                ? 'No recorded mistakes for this book yet.'
                                : '${wrongs.length} mistake(s) on server',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        Text(
                          'Sign in to sync wrong words and use “past mistakes” mode.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (hasImportant) ...[
                        Text(
                          'Important words',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This selection includes words marked important on the server.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All words'),
                              selected: !_quizImportantOnly,
                              onSelected: (_) =>
                                  setState(() => _quizImportantOnly = false),
                            ),
                            ChoiceChip(
                              label: const Text('Important only'),
                              selected: _quizImportantOnly,
                              onSelected: (_) =>
                                  setState(() => _quizImportantOnly = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        'Questions (max $maxQ)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Slider(
                        min: minQ > 0 ? minQ.toDouble() : 1,
                        max: maxQ > 0 ? maxQ.toDouble() : 1,
                        divisions: maxQ > minQ ? maxQ - minQ : null,
                        label: '$_questionCount',
                        value: _questionCount.clamp(minQ, maxQ > 0 ? maxQ : 1).toDouble(),
                        onChanged: maxQ <= 0
                            ? null
                            : (v) => setState(() => _questionCount = v.round()),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: pool < 4 || maxQ < 1
                            ? null
                            : () {
                                final u = _selectedUnits.toList()..sort();
                                final scope = _wrongsOnly ? 'wrongs' : 'all';
                                var path =
                                    '/books/${widget.bookId}/quiz?units=${u.join(',')}&count=$_questionCount&scope=$scope';
                                if (hasImportant) {
                                  path +=
                                      '&important=${_quizImportantOnly ? 1 : 0}';
                                }
                                context.push(path);
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start quiz'),
                      ),
                      if (pool < 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            hasImportant &&
                                    _quizImportantOnly &&
                                    basePool.length >= 4
                                ? 'Not enough important words in this selection (need at least 4). '
                                    'Choose all words or adjust units / mistakes.'
                                : 'Need at least 4 words in the pool (check units / mistakes).',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.error,
                                ),
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
