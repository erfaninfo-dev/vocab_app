import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/sync/pending_word_updates.dart';
import '../../../core/tts/tts_service.dart';
import '../../../data/models/vocab_entry.dart';
import '../../../domain/api_providers.dart';
import '../word_preferences_controller.dart';

class WordCard extends ConsumerStatefulWidget {
  const WordCard({super.key, required this.entry});

  final VocabEntry entry;

  @override
  ConsumerState<WordCard> createState() => _WordCardState();
}

class _WordCardState extends ConsumerState<WordCard> {
  bool? _optimisticImportant;
  bool _busyImportant = false;

  bool get _isImportant =>
      _optimisticImportant ?? widget.entry.isImportant;

  Future<void> _toggleImportant(BuildContext context) async {
    if (_busyImportant) return;
    final messenger = ScaffoldMessenger.of(context);
    final entry = widget.entry;
    final bookId = int.tryParse(entry.bookId) ?? 0;
    if (entry.rowId <= 0 || bookId <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update important flag')),
      );
      return;
    }

    final next = _isImportant ? 0 : 1;
    setState(() {
      _busyImportant = true;
      _optimisticImportant = next == 1;
    });

    try {
      await ref.read(apiServiceProvider).setWordImportant(
            id: entry.rowId,
            important: next,
          );
      ref.invalidate(apiAllWordsForBookProvider(bookId));
      ref.invalidate(
        apiWordsProvider((
          bookId: bookId,
          unit: entry.unit,
          section: entry.section,
        )),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            next == 1 ? 'Marked as important' : 'Removed from important',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimisticImportant = null);
      await enqueuePendingImportant(id: entry.rowId, important: next);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Saved locally. Will sync on refresh.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyImportant = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state      = ref.watch(wordPreferencesProvider);
    final controller = ref.read(wordPreferencesProvider.notifier);
    final lang       = ref.watch(langProvider);
    final isFav      = state.favoriteIds.contains(widget.entry.id);
    final scheme     = Theme.of(context).colorScheme;
    final accent     = _accent(widget.entry.section);

    final localMeaning = widget.entry.meaningFor(lang);
    final localExample = widget.entry.exampleLocalFor(lang);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Card(
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: scheme.surface.withValues(alpha: 0.92),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Word + type ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.entry.word,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (widget.entry.type.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      widget.entry.type,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── English meaning ───────────────────────────────────────────────
            if (widget.entry.meaningEn.isNotEmpty)
              Text(
                widget.entry.meaningEn,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            // ── Local meaning (fa or kur) ─────────────────────────────────────
            if (localMeaning.isNotEmpty) ...[
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  // Slightly larger right inset for local meaning.
                  padding: const EdgeInsets.only(right: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      localMeaning,
                      textAlign: TextAlign.right,
                      strutStyle: const StrutStyle(forceStrutHeight: true),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── Example box ───────────────────────────────────────────────────
            if (widget.entry.exampleEn.isNotEmpty || localExample.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.entry.exampleEn.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.entry.exampleEn,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (localExample.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              localExample,
                              textAlign: TextAlign.right,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Action buttons ────────────────────────────────────────────────
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Favorite',
                  onPressed: () => controller.toggleFavorite(widget.entry.id),
                  icon: Icon(
                    isFav
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: 'Important',
                  onPressed: _busyImportant ? null : () => _toggleImportant(context),
                  style: _isImportant
                      ? IconButton.styleFrom(
                          backgroundColor:
                              Colors.orange.withValues(alpha: 0.22),
                          foregroundColor: Colors.deepOrange.shade700,
                        )
                      : null,
                  icon: Icon(
                    _isImportant
                        ? Icons.local_fire_department_rounded
                        : Icons.local_fire_department_outlined,
                  ),
                ),
                const SizedBox(width: 4),
                _SpeakButton(word: widget.entry.word, example: widget.entry.exampleEn),
                const Spacer(),
                Text(
                  'U${widget.entry.unit}  S${widget.entry.section}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

Color _accent(int? section) {
  switch (section) {
    case 1:
      return const Color(0xFF5B6CFF);
    case 2:
      return const Color(0xFF7A5FFF);
    default:
      return const Color(0xFF4D8DFF);
  }
}

// ─── Speak Button ─────────────────────────────────────────────────────────────

class _SpeakButton extends ConsumerWidget {
  const _SpeakButton({required this.word, required this.example});

  final String word;
  final String example;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);
    final isSpeakingWord = tts.isSpeakingText(word);
    final isSpeakingExample =
        example.isNotEmpty && tts.isSpeakingText(example);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: 'Pronounce word',
          onPressed: () => notifier.speak(word),
          style: isSpeakingWord
              ? IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                )
              : null,
          icon: Icon(
            isSpeakingWord
                ? Icons.volume_up_rounded
                : Icons.volume_up_outlined,
          ),
        ),
        if (example.isNotEmpty) ...[
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'Pronounce example',
            onPressed: () => notifier.speak(example),
            style: isSpeakingExample
                ? IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  )
                : null,
            icon: Icon(
              isSpeakingExample
                  ? Icons.record_voice_over_rounded
                  : Icons.record_voice_over_outlined,
            ),
          ),
        ],
      ],
    );
  }
}
