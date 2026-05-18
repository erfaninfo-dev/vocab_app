import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../core/language/language_provider.dart';
import '../../core/srs/srs_model.dart';
import '../../core/srs/srs_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({
    super.key,
    required this.bookId,
    required this.unit,
    required this.section,
  });

  final int bookId;
  final int unit;
  final int? section;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  var _index = 0;
  var _showBack = false;

  void _goTo(int index) => setState(() {
    _index = index;
    _showBack = false;
  });

  Future<void> _rate(String wordId, SrsRating rating, int total) async {
    await ref.read(srsProvider.notifier).rate(wordId, rating);
    if (_index < total - 1) {
      _goTo(_index + 1);
    } else {
      if (mounted) {
        final msg = AppLocalizations.of(context)!.allCardsReviewed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(
      apiWordsProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tooltipFlashcards)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(userFriendlyErrorMessage(error, l10n))),
        data: (words) {
          if (words.isEmpty) {
            return Center(child: Text(l10n.noWordsForSection));
          }
          final current = words[_index];
          final lang = ref.watch(langProvider);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // ── Progress ─────────────────────────────────────────────────
                _ProgressRow(
                  l10n: l10n,
                  current: _index + 1,
                  total: words.length,
                ),
                const SizedBox(height: 12),

                // ── Card ─────────────────────────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showBack = !_showBack),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _showBack
                          ? _CardFace(
                              key: const ValueKey('back'),
                              l10n: l10n,
                              title: current.meaningEn.isEmpty
                                  ? '-'
                                  : current.meaningEn,
                              subtitle: current.meaningFor(lang),
                              example: current.exampleEn,
                              subtitleRtl: true,
                              isBack: true,
                            )
                          : _CardFace(
                              key: const ValueKey('front'),
                              l10n: l10n,
                              title: current.word,
                              subtitle: current.type,
                              example: current.exampleEn,
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── TTS ───────────────────────────────────────────────────────
                _FlashcardSpeakRow(
                  l10n: l10n,
                  word: current.word,
                  example: current.exampleEn,
                ),

                const SizedBox(height: 10),

                // ── SRS Rating (visible after flip) ───────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _showBack
                      ? _SrsRatingRow(
                          key: ValueKey('srs_${current.id}'),
                          l10n: l10n,
                          wordId: current.id,
                          total: words.length,
                          onRate: (rating) =>
                              _rate(current.id, rating, words.length),
                        )
                      : SizedBox(
                          key: const ValueKey('srs_hidden'),
                          height: 48,
                          child: Center(
                            child: Text(
                              l10n.tapCardToRevealAndRate,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                // ── Prev / Next ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(l10n.previous),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _index == words.length - 1
                            ? null
                            : () => _goTo(_index + 1),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.next),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Progress Row ─────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
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
              l10n.flashcardCardProgress(current, total),
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
          child: LinearProgressIndicator(value: current / total, minHeight: 6),
        ),
      ],
    );
  }
}

// ─── Card Face ────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    required this.l10n,
    required this.title,
    required this.subtitle,
    this.example,
    this.subtitleRtl = false,
    this.isBack = false,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final String? example;
  final bool subtitleRtl;
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
              isBack ? l10n.flashcardMeaningLabel : l10n.flashcardWordLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 14),
              subtitleRtl
                  ? Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
            ],
            if (example != null && example!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                example!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 14),
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
                  l10n.tapToFlip,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SRS Rating Row ───────────────────────────────────────────────────────────

class _SrsRatingRow extends ConsumerWidget {
  const _SrsRatingRow({
    super.key,
    required this.l10n,
    required this.wordId,
    required this.total,
    required this.onRate,
  });

  final AppLocalizations l10n;
  final String wordId;
  final int total;
  final void Function(SrsRating) onRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(srsProvider).cardFor(wordId);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          l10n.howWellKnew,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: SrsRating.values.map((rating) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _RatingButton(
                  rating: rating,
                  card: card,
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

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.rating,
    required this.card,
    required this.onTap,
  });

  final SrsRating rating;
  final SrsCard card;
  final VoidCallback onTap;

  Color _bgColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (rating) {
      case SrsRating.again:
        return Colors.red.shade100;
      case SrsRating.hard:
        return Colors.orange.shade100;
      case SrsRating.good:
        return Colors.green.shade100;
      case SrsRating.easy:
        return scheme.primaryContainer;
    }
  }

  Color _fgColor(BuildContext context) {
    switch (rating) {
      case SrsRating.again:
        return Colors.red.shade800;
      case SrsRating.hard:
        return Colors.orange.shade800;
      case SrsRating.good:
        return Colors.green.shade800;
      case SrsRating.easy:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextInterval = Sm2.rate(card, rating).interval;
    final label = rating == SrsRating.easy
        ? '🙂 Easy'
        : rating.label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: _bgColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _fgColor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              nextInterval == 1 ? '1d' : '${nextInterval}d',
              style: TextStyle(
                fontSize: 10,
                color: _fgColor(context).withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Flashcard TTS Row ────────────────────────────────────────────────────────

class _FlashcardSpeakRow extends ConsumerWidget {
  const _FlashcardSpeakRow({
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

    final isSpeakingWord = tts.isSpeakingText(word);
    final isSpeakingExample = example.isNotEmpty && tts.isSpeakingText(example);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => notifier.speak(word),
          style: FilledButton.styleFrom(
            backgroundColor: isSpeakingWord
                ? scheme.primary
                : scheme.primaryContainer,
            foregroundColor: isSpeakingWord
                ? scheme.onPrimary
                : scheme.onPrimaryContainer,
          ),
          icon: Icon(
            isSpeakingWord ? Icons.volume_up_rounded : Icons.volume_up_outlined,
            size: 18,
          ),
          label: Text(
            isSpeakingWord ? l10n.speaking : l10n.flashcardWordLabel,
          ),
        ),
        if (example.isNotEmpty) ...[
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => notifier.speak(example),
            style: FilledButton.styleFrom(
              backgroundColor: isSpeakingExample
                  ? scheme.secondary
                  : scheme.secondaryContainer,
              foregroundColor: isSpeakingExample
                  ? scheme.onSecondary
                  : scheme.onSecondaryContainer,
            ),
            icon: Icon(
              isSpeakingExample
                  ? Icons.record_voice_over_rounded
                  : Icons.record_voice_over_outlined,
              size: 18,
            ),
            label: Text(
              isSpeakingExample ? l10n.speaking : l10n.wordExample,
            ),
          ),
        ],
      ],
    );
  }
}
