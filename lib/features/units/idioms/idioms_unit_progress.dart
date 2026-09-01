import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/vocab_entry.dart';
import '../../words/word_preferences_controller.dart';
import '../../../domain/api_providers.dart';

class IdiomsUnitProgress {
  const IdiomsUnitProgress({required this.done, required this.total});

  final int done;
  final int total;

  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);

  bool get isNotStarted => done <= 0;

  bool get isInProgress => done > 0 && done < total;

  bool get isCompleted => total > 0 && done >= total;
}

/// Per-unit progress for an idioms book: favorites in that unit / total idioms.
final idiomsUnitProgressMapProvider =
    Provider.family<Map<int, IdiomsUnitProgress>, int>((ref, bookId) {
      final wordsAsync = ref.watch(apiAllWordsForBookProvider(bookId));
      final words = wordsAsync.valueOrNull ?? const <VocabEntry>[];
      final prefs = ref.watch(wordPreferencesProvider);

      final byUnit = <int, List<VocabEntry>>{};
      for (final entry in words) {
        byUnit.putIfAbsent(entry.unit, () => []).add(entry);
      }

      final out = <int, IdiomsUnitProgress>{};
      for (final e in byUnit.entries) {
        final total = e.value.length;
        final done = e.value.where(prefs.isFavorite).length;
        out[e.key] = IdiomsUnitProgress(done: done, total: total);
      }
      return out;
    });
