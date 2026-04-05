import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';

import '../../core/language/language_provider.dart';
import '../../core/srs/srs_model.dart';
import '../../core/srs/srs_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  var _index = 0;
  var _showBack = false;
  var _sessionDone = false;

  void _goNext(int total) {
    if (_index < total - 1) {
      setState(() {
        _index++;
        _showBack = false;
      });
    } else {
      setState(() => _sessionDone = true);
    }
  }

  Future<void> _rate(
    String wordId,
    SrsRating rating,
    int total,
  ) async {
    await ref.read(srsProvider.notifier).rate(wordId, rating);
    _goNext(total);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Load all books, then load all words, then filter by due today
    final booksValue = ref.watch(apiBooksProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Review Today'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(
                srsProvider.select((s) => s.dueTodayCount),
              );
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  label: Text('$count due'),
                  backgroundColor: scheme.primaryContainer,
                ),
              );
            },
          ),
        ],
      ),
      body: booksValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (books) {
          // Watch all words providers for all books
          final allWordsValues = books
              .map((b) => ref.watch(apiAllWordsForBookProvider(b.id)))
              .toList();

          final isLoading = allWordsValues.any((v) => v is AsyncLoading);
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allWords = <VocabEntry>[];
          for (final v in allWordsValues) {
            v.whenData(allWords.addAll);
          }

          final srs = ref.watch(srsProvider);
          final dueIds = srs.dueToday.map((c) => c.wordId).toSet();

          // Only words that have been studied at least once AND are due
          final dueWords = allWords
              .where((w) => dueIds.contains(w.id))
              .toList();

          if (dueWords.isEmpty) {
            return _EmptyState(totalStudied: srs.cards.length);
          }

          if (_sessionDone || _index >= dueWords.length) {
            return _DoneState(reviewed: dueWords.length);
          }

          final current = dueWords[_index];
          final card    = srs.cardFor(current.id);
          final lang    = ref.watch(langProvider);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Progress
                _ReviewProgress(
                  current: _index + 1,
                  total: dueWords.length,
                ),
                const SizedBox(height: 12),

                // Card
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _showBack = !_showBack),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child:                       _showBack
                          ? _ReviewCardFace(
                              key: const ValueKey('back'),
                              word: current.word,
                              meaningEn: current.meaningEn,
                              meaningLocal: current.meaningFor(lang),
                              exampleEn: current.exampleEn,
                              isBack: true,
                            )
                          : _ReviewCardFace(
                              key: const ValueKey('front'),
                              word: current.word,
                              meaningEn: '',
                              meaningLocal: '',
                              exampleEn: '',
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // TTS
                _ReviewSpeakRow(
                  word: current.word,
                  example: current.exampleEn,
                ),

                const SizedBox(height: 10),

                // SRS Rating
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showBack
                      ? _ReviewRatingRow(
                          key: ValueKey('rating_${current.id}'),
                          card: card,
                          onRate: (r) =>
                              _rate(current.id, r, dueWords.length),
                        )
                      : SizedBox(
                          key: const ValueKey('rating_hidden'),
                          height: 56,
                          child: Center(
                            child: Text(
                              'Tap card to reveal answer',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Progress ─────────────────────────────────────────────────────────────────

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$current / $total words',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            Text(
              '${((current / total) * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
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

// ─── Card Face ────────────────────────────────────────────────────────────────

class _ReviewCardFace extends StatelessWidget {
  const _ReviewCardFace({
    super.key,
    required this.word,
    required this.meaningEn,
    required this.meaningLocal,
    required this.exampleEn,
    this.isBack = false,
  });

  final String word;
  final String meaningEn;
  final String meaningLocal;
  final String exampleEn;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isBack
                ? [scheme.secondaryContainer, scheme.surface]
                : [scheme.primaryContainer, scheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isBack ? 'Answer' : 'Translate this word',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              word,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isBack) ...[
              if (meaningEn.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  meaningEn,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              if (meaningLocal.isNotEmpty) ...[
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    meaningLocal,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (exampleEn.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"$exampleEn"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to see answer',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Rating Row ───────────────────────────────────────────────────────────────

class _ReviewRatingRow extends StatelessWidget {
  const _ReviewRatingRow({
    super.key,
    required this.card,
    required this.onRate,
  });

  final SrsCard card;
  final void Function(SrsRating) onRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'How well did you know this?',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: SrsRating.values.map((rating) {
            final next = Sm2.rate(card, rating).interval;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _RatingChip(
                  rating: rating,
                  nextDays: next,
                  onTap: () => onRate(rating),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.rating,
    required this.nextDays,
    required this.onTap,
  });

  final SrsRating rating;
  final int nextDays;
  final VoidCallback onTap;

  Color _bg(BuildContext context) {
    switch (rating) {
      case SrsRating.again: return Colors.red.shade100;
      case SrsRating.hard:  return Colors.orange.shade100;
      case SrsRating.good:  return Colors.green.shade100;
      case SrsRating.easy:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  Color _fg(BuildContext context) {
    switch (rating) {
      case SrsRating.again: return Colors.red.shade800;
      case SrsRating.hard:  return Colors.orange.shade800;
      case SrsRating.good:  return Colors.green.shade800;
      case SrsRating.easy:  return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: _bg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              rating.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _fg(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${nextDays}d',
              style: TextStyle(
                fontSize: 10,
                color: _fg(context).withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Speak Row ────────────────────────────────────────────────────────────────

class _ReviewSpeakRow extends ConsumerWidget {
  const _ReviewSpeakRow({required this.word, required this.example});

  final String word;
  final String example;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final isSpeaking = tts.isSpeakingText(word);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => notifier.speak(word),
          style: FilledButton.styleFrom(
            backgroundColor: isSpeaking
                ? scheme.primary
                : scheme.primaryContainer,
            foregroundColor: isSpeaking
                ? scheme.onPrimary
                : scheme.onPrimaryContainer,
          ),
          icon: Icon(
            isSpeaking
                ? Icons.volume_up_rounded
                : Icons.volume_up_outlined,
            size: 18,
          ),
          label: Text(isSpeaking ? 'Speaking...' : 'Pronounce'),
        ),
      ],
    );
  }
}

// ─── Empty / Done States ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.totalStudied});

  final int totalStudied;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No words due today!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalStudied == 0
                  ? 'Start studying words using Flashcards to build your review queue.'
                  : 'Great job! Come back tomorrow for more reviews.\n$totalStudied words in your queue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneState extends StatelessWidget {
  const _DoneState({required this.reviewed});

  final int reviewed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Session Complete!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $reviewed word${reviewed == 1 ? '' : 's'} today.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
