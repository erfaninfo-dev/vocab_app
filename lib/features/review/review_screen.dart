import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/language/language_provider.dart';
import '../../core/srs/srs_model.dart';
import '../../core/srs/srs_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../you/you_jelly_style.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, this.embedded = false});

  final bool embedded;

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
    final l10n = AppLocalizations.of(context)!;

    // Load all books, then load all words, then filter by due today
    final booksValue = ref.watch(apiBooksProvider);

    final dueChip = Consumer(
      builder: (context, ref, _) {
        final count = ref.watch(
          srsProvider.select((s) => s.dueTodayCount),
        );
        if (count == 0) return const SizedBox.shrink();
        return Chip(
          label: Text(l10n.dueCount(count)),
          backgroundColor: scheme.primaryContainer,
        );
      },
    );

    final body = booksValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(l10n.fetchErrorRetry),
        ),
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
            return _EmptyState(l10n: l10n, totalStudied: srs.cards.length);
          }

          if (_sessionDone || _index >= dueWords.length) {
            return _DoneState(l10n: l10n, reviewed: dueWords.length);
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
                  l10n: l10n,
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
                              l10n: l10n,
                              word: current.word,
                              meaningEn: current.meaningEn,
                              meaningLocal: current.meaningFor(lang),
                              exampleEn: current.exampleEn,
                              isBack: true,
                            )
                          : _ReviewCardFace(
                              key: const ValueKey('front'),
                              l10n: l10n,
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
                  l10n: l10n,
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
                          l10n: l10n,
                          card: card,
                          onRate: (r) =>
                              _rate(current.id, r, dueWords.length),
                        )
                      : SizedBox(
                          key: const ValueKey('rating_hidden'),
                          height: 56,
                          child: Center(
                            child: Text(
                              l10n.tapCardToReveal,
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
      );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reviewToday,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                dueChip,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.reviewToday),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: dueChip,
          ),
        ],
      ),
      body: body,
    );
  }
}

// ─── Progress ─────────────────────────────────────────────────────────────────

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({
    required this.l10n,
    required this.current,
    required this.total,
  });

  final AppLocalizations l10n;
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
              l10n.wordsProgress(current, total),
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
    required this.l10n,
    required this.word,
    required this.meaningEn,
    required this.meaningLocal,
    required this.exampleEn,
    this.isBack = false,
  });

  final AppLocalizations l10n;
  final String word;
  final String meaningEn;
  final String meaningLocal;
  final String exampleEn;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: youJellyCardDecoration(context, scheme: scheme).copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBack
              ? (isDark
                  ? [
                      Color.lerp(scheme.secondaryContainer, scheme.surface, 0.2)!,
                      Color.lerp(scheme.tertiaryContainer, scheme.surface, 0.35)!,
                    ]
                  : [
                      Color.lerp(scheme.secondaryContainer, Colors.white, 0.35)!,
                      Color.lerp(scheme.tertiaryContainer, Colors.white, 0.5)!,
                    ])
              : (isDark
                  ? [
                      Color.lerp(scheme.primaryContainer, scheme.surface, 0.2)!,
                      Color.lerp(scheme.secondaryContainer, scheme.surface, 0.35)!,
                    ]
                  : [
                      Color.lerp(scheme.primaryContainer, Colors.white, 0.35)!,
                      Color.lerp(scheme.secondaryContainer, Colors.white, 0.5)!,
                    ]),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isBack ? l10n.answer : l10n.translateThisWord,
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
                decoration: youJellyInsetDecoration(context),
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
                  l10n.tapToSeeAnswer,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Rating Row ───────────────────────────────────────────────────────────────

class _ReviewRatingRow extends StatelessWidget {
  const _ReviewRatingRow({
    super.key,
    required this.l10n,
    required this.card,
    required this.onRate,
  });

  final AppLocalizations l10n;
  final SrsCard card;
  final void Function(SrsRating) onRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.howWellKnew,
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
                  l10n: l10n,
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
    required this.l10n,
    required this.rating,
    required this.nextDays,
    required this.onTap,
  });

  final AppLocalizations l10n;
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
              _ratingLabel(l10n, rating),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _fg(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.nextDaysShort(nextDays),
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

String _ratingLabel(AppLocalizations l10n, SrsRating rating) {
  switch (rating) {
    case SrsRating.again:
      return l10n.srsRatingAgain;
    case SrsRating.hard:
      return l10n.srsRatingHard;
    case SrsRating.good:
      return l10n.srsRatingGood;
    case SrsRating.easy:
      return l10n.srsRatingEasy;
  }
}

// ─── Speak Row ────────────────────────────────────────────────────────────────

class _ReviewSpeakRow extends ConsumerWidget {
  const _ReviewSpeakRow({
    required this.l10n,
    required this.word,
    required this.example,
  });

  final AppLocalizations l10n;
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
          label: Text(isSpeaking ? l10n.speaking : l10n.pronounce),
        ),
      ],
    );
  }
}

// ─── Empty / Done States ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.totalStudied});

  final AppLocalizations l10n;
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
              l10n.noWordsDueTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalStudied == 0
                  ? l10n.noWordsDueBodyFlashcards
                  : l10n.noWordsDueBodyGreat(totalStudied),
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
  const _DoneState({required this.l10n, required this.reviewed});

  final AppLocalizations l10n;
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
              l10n.sessionComplete,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.youReviewedToday(reviewed),
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
