import '../../../data/models/vocab_entry.dart';
import 'flashcard_direction.dart';
import 'flashcard_pool.dart';

/// Stable per-deck storage key. Two sessions resume against each other only when
/// every component matches, so changing pool/direction/shuffle starts a fresh
/// session and changing important marks invalidates the saved word-id list.
String flashcardDeckKey(
  int bookId,
  int unit,
  int? section,
  FlashcardPool pool,
  FlashcardDirection direction,
  bool shuffle,
) {
  return 'flashcard_session_v1|$bookId|$unit|${section ?? 0}|${pool.key}|${direction.key}|${shuffle ? 1 : 0}';
}

typedef FlashcardSessionArgs = ({
  int bookId,
  int unit,
  int? section,
  FlashcardPool pool,
  FlashcardDirection direction,
  bool shuffle,
  bool srsEnabled,
  bool swipeRatings,
});

({int bookId, int unit, int? section}) flashcardBookUnitSection(
  FlashcardSessionArgs args,
) {
  return (bookId: args.bookId, unit: args.unit, section: args.section);
}

class FlashcardSessionModel {
  const FlashcardSessionModel({
    required this.deckKey,
    required this.wordIds,
    required this.currentIndex,
    required this.ratedIds,
    required this.startedAt,
    required this.updatedAt,
  });

  final String deckKey;
  final List<String> wordIds;
  final int currentIndex;
  final Set<String> ratedIds;
  final DateTime startedAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'deckKey': deckKey,
        'wordIds': wordIds,
        'currentIndex': currentIndex,
        'ratedIds': ratedIds.toList(),
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FlashcardSessionModel.fromJson(Map<String, dynamic> json) {
    final ids = (json['wordIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final rated = (json['ratedIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toSet();
    return FlashcardSessionModel(
      deckKey: json['deckKey'] as String? ?? '',
      wordIds: ids,
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      ratedIds: rated,
      startedAt: _parseDate(json['startedAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

bool flashcardWordListsEqual(List<String> a, List<VocabEntry> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i].id) return false;
  }
  return true;
}
