import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../core/srs/srs_model.dart';
import '../../core/language/language_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_gradient_scaffold.dart';
import '../../features/words/important_words_controller.dart';
import '../../features/words/word_preferences_controller.dart';
import '../../l10n/app_localizations.dart';
import 'flashcard_session_controller.dart';
import 'models/flashcard_direction.dart';
import 'models/flashcard_pool.dart';
import 'models/flashcard_session.dart';
import 'widgets/flashcard_deck_card.dart';
import 'widgets/flashcard_empty_state.dart';
import 'widgets/flashcard_face.dart';
import 'widgets/flashcard_progress.dart';
import 'widgets/flashcard_rating_bar.dart';
import 'widgets/flashcard_summary.dart';

class FlashcardSessionScreen extends ConsumerStatefulWidget {
  const FlashcardSessionScreen({
    super.key,
    required this.bookId,
    required this.unit,
    required this.section,
    required this.pool,
    required this.direction,
    required this.shuffle,
    required this.srsEnabled,
    required this.swipeRatings,
  });

  final int bookId;
  final int unit;
  final int? section;
  final FlashcardPool pool;
  final FlashcardDirection direction;
  final bool shuffle;
  final bool srsEnabled;
  final bool swipeRatings;

  @override
  ConsumerState<FlashcardSessionScreen> createState() =>
      _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState
    extends ConsumerState<FlashcardSessionScreen> {
  final _deckKey = GlobalKey<FlashcardDeckCardState>();

  FlashcardSessionArgs get _args => (
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
        pool: widget.pool,
        direction: widget.direction,
        shuffle: widget.shuffle,
        srsEnabled: widget.srsEnabled,
        swipeRatings: widget.swipeRatings,
      );

  String get _wordsRoute => widget.section == null
      ? '/books/${widget.bookId}/units/${widget.unit}/words'
      : '/books/${widget.bookId}/units/${widget.unit}/sections/${widget.section}/words';

  @override
  void deactivate() {
    // Stop speech as the screen leaves (while still mounted) so the platform
    // completion callback cannot fire into a disposed listener.
    unawaited(ref.read(ttsProvider.notifier).stop());
    super.deactivate();
  }

  @override
  void dispose() {
    unawaited(ref.read(ttsProvider.notifier).stop());
    super.dispose();
  }

  void _goBackToWords(FlashcardSessionState s) {
    unawaited(ref.read(flashcardSessionProvider(_args).notifier).finishAndClear());
    if (mounted) context.go(_wordsRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final sessionAsync = ref.watch(flashcardSessionProvider(_args));

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(l10n.tooltipFlashcards),
    );
    final topInset =
        appGradientContentTopInset(context, appBar: appBar, extra: 12);

    return AppGradientScaffold(
      appBar: appBar,
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(userFriendlyErrorMessage(e, l10n)),
          ),
        ),
        data: (s) {
          if (!s.hasCards) {
            return FlashcardEmptyState(
              kind: switch (widget.pool) {
                FlashcardPool.important => FlashcardEmptyKind.important,
                FlashcardPool.favorites => FlashcardEmptyKind.favorites,
                FlashcardPool.all => FlashcardEmptyKind.noWords,
              },
              onAction: () => Navigator.of(context).maybePop(),
            );
          }

          if (s.completed) {
            return FlashcardSummary(
              total: s.total,
              counts: s.ratingCounts,
              weakCount: s.weakCount,
              duration: DateTime.now().difference(s.startedAt),
              onReviewAgain: () => ref
                  .read(flashcardSessionProvider(_args).notifier)
                  .reviewAgain(),
              onRestart: () => ref
                  .read(flashcardSessionProvider(_args).notifier)
                  .restart(),
              onBackToWords: () => _goBackToWords(s),
            );
          }

          final current = s.current!;
          final lang = ref.watch(langProvider);
          final important = ref.watch(importantWordsProvider).isMarked(current);
          final favorite =
              ref.watch(wordPreferencesProvider).isFavorite(current);
          final tts = ref.watch(ttsProvider);
          final ttsNotifier = ref.read(ttsProvider.notifier);
          final ctrl = ref.read(flashcardSessionProvider(_args).notifier);

          Future<void> onRate(SrsRating rating) async {
            final wasLast = s.isLast;
            await ctrl.applyRate(rating);
            if (!mounted) return;
            if (wasLast) {
              ctrl.next();
            } else {
              await _deckKey.currentState?.goNext();
            }
          }

          final frontFace = FlashcardFace(
            entry: current,
            lang: lang,
            isFront: true,
            direction: widget.direction,
            isImportant: important,
            isFavorite: favorite,
          );
          final backFace = FlashcardFace(
            entry: current,
            lang: lang,
            isFront: false,
            direction: widget.direction,
            isImportant: important,
            isFavorite: favorite,
          );

          final ttsVisible = s.showBack ||
              widget.direction == FlashcardDirection.wordToMeaning;

          return PopScope(
            canPop: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topInset, 16, 12),
              child: Column(
                children: [
                  FlashcardProgress(
                    current: s.index + 1,
                    total: s.total,
                  ),
                  if (s.resumed) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.tertiary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 13,
                            color: scheme.tertiary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.flashcardResumedHint,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: scheme.tertiary,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: FlashcardDeckCard(
                      key: _deckKey,
                      cardKey: current.id,
                      front: frontFace,
                      back: backFace,
                      showBack: s.showBack,
                      onFlip: ctrl.flip,
                      onNext: s.isLast ? null : ctrl.next,
                      onPrev: s.index == 0 ? null : ctrl.prev,
                      swipeEnabled: widget.swipeRatings,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (ttsVisible)
                    _SessionTtsRow(
                      word: current.word,
                      example: current.exampleEn,
                      showExample: s.showBack,
                      tts: tts,
                      onSpeakWord: () => ttsNotifier.speak(current.word),
                      onSpeakExample: () =>
                          ttsNotifier.speak(current.exampleEn),
                    ),
                  if (ttsVisible) const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: s.showBack
                        ? FlashcardRatingBar(
                            key: ValueKey('rate_${current.id}'),
                            wordId: current.id,
                            showInterval: widget.srsEnabled,
                            onRate: onRate,
                          )
                        : _RevealHint(
                            key: const ValueKey('rate_hidden'),
                            text: l10n.tapCardToRevealAndRate,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _CircleNavButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: s.index == 0
                            ? null
                            : () => _deckKey.currentState?.goPrev(),
                        scheme: scheme,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: s.isLast
                              ? null
                              : () => _deckKey.currentState?.goNext(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            l10n.next,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RevealHint extends StatelessWidget {
  const _RevealHint({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleNavButton extends StatelessWidget {
  const _CircleNavButton({
    required this.icon,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      height: 52,
      width: 52,
      child: Material(
        color: enabled
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Icon(
              icon,
              color: enabled
                  ? scheme.onSurfaceVariant
                  : scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionTtsRow extends StatelessWidget {
  const _SessionTtsRow({
    required this.word,
    required this.example,
    required this.showExample,
    required this.tts,
    required this.onSpeakWord,
    required this.onSpeakExample,
  });

  final String word;
  final String example;
  final bool showExample;
  final TtsState tts;
  final VoidCallback onSpeakWord;
  final VoidCallback onSpeakExample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final speakingWord = tts.isSpeakingText(word);
    final speakingExample = example.isNotEmpty && tts.isSpeakingText(example);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PillTtsButton(
          icon: speakingWord
              ? Icons.graphic_eq_rounded
              : Icons.volume_up_rounded,
          label: speakingWord ? l10n.speaking : l10n.flashcardWordLabel,
          active: speakingWord,
          activeColor: scheme.primary,
          onTap: onSpeakWord,
        ),
        if (showExample && example.isNotEmpty) ...[
          const SizedBox(width: 10),
          _PillTtsButton(
            icon: speakingExample
                ? Icons.graphic_eq_rounded
                : Icons.record_voice_over_rounded,
            label: speakingExample ? l10n.speaking : l10n.wordExample,
            active: speakingExample,
            activeColor: scheme.tertiary,
            onTap: onSpeakExample,
          ),
        ],
      ],
    );
  }
}

class _PillTtsButton extends StatelessWidget {
  const _PillTtsButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active
          ? activeColor
          : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
