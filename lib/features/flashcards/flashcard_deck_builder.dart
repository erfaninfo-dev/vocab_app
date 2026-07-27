import 'dart:math';

import '../../data/models/vocab_entry.dart';
import 'models/flashcard_pool.dart';

class FlashcardDeckBuilder {
  const FlashcardDeckBuilder._();

  /// Filters [source] by [pool] and optionally shuffles with a deterministic
  /// [seed] so that a resumed session reproduces the exact same card order.
  static List<VocabEntry> build({
    required List<VocabEntry> source,
    required FlashcardPool pool,
    required bool Function(VocabEntry) isImportant,
    required bool Function(VocabEntry) isFavorite,
    bool shuffle = false,
    int? seed,
  }) {
    final filtered = switch (pool) {
      FlashcardPool.all => List<VocabEntry>.of(source),
      FlashcardPool.important =>
        source.where(isImportant).toList(growable: false),
      FlashcardPool.favorites =>
        source.where(isFavorite).toList(growable: false),
    };

    if (shuffle) {
      filtered.shuffle(Random(seed));
    }
    return filtered;
  }

  static int countForPool({
    required List<VocabEntry> source,
    required FlashcardPool pool,
    required bool Function(VocabEntry) isImportant,
    required bool Function(VocabEntry) isFavorite,
  }) {
    return build(
      source: source,
      pool: pool,
      isImportant: isImportant,
      isFavorite: isFavorite,
    ).length;
  }
}
