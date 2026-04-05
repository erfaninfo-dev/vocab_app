import 'dart:convert';

// ─── SRS Card ─────────────────────────────────────────────────────────────────
// Stores per-word spaced-repetition state.

class SrsCard {
  const SrsCard({
    required this.wordId,
    this.interval = 1,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    DateTime? dueDate,
  }) : _dueDate = dueDate;

  final String wordId;
  final int interval;       // days until next review
  final double easeFactor;  // difficulty multiplier (min 1.3)
  final int repetitions;    // consecutive correct answers
  final DateTime? _dueDate;

  DateTime get dueDate => _dueDate ?? DateTime.now();

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return !due.isAfter(today);
  }

  SrsCard copyWith({
    int? interval,
    double? easeFactor,
    int? repetitions,
    DateTime? dueDate,
  }) {
    return SrsCard(
      wordId: wordId,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'interval': interval,
    'easeFactor': easeFactor,
    'repetitions': repetitions,
    'dueDate': dueDate.toIso8601String(),
  };

  factory SrsCard.fromJson(Map<String, dynamic> json) => SrsCard(
    wordId: json['wordId'] as String,
    interval: (json['interval'] as num).toInt(),
    easeFactor: (json['easeFactor'] as num).toDouble(),
    repetitions: (json['repetitions'] as num).toInt(),
    dueDate: DateTime.parse(json['dueDate'] as String),
  );

  static String encodeList(List<SrsCard> cards) =>
      jsonEncode(cards.map((c) => c.toJson()).toList());

  static List<SrsCard> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => SrsCard.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ─── Rating enum ──────────────────────────────────────────────────────────────

enum SrsRating {
  again(0, '❌ Again'),
  hard(2, '😐 Hard'),
  good(4, '✅ Good'),
  easy(5, '🔥 Easy');

  const SrsRating(this.quality, this.label);
  final int quality;
  final String label;
}

// ─── SM-2 Algorithm ───────────────────────────────────────────────────────────
// Based on the SuperMemo SM-2 algorithm.
// quality: 0 = complete blackout, 5 = perfect response

class Sm2 {
  static SrsCard rate(SrsCard card, SrsRating rating) {
    final q = rating.quality;
    int n = card.repetitions;
    double ef = card.easeFactor;
    int interval = card.interval;

    if (q >= 3) {
      // Correct response
      if (n == 0) {
        interval = 1;
      } else if (n == 1) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
      n++;
      ef = ef + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
      if (ef < 1.3) ef = 1.3;
    } else {
      // Incorrect: reset
      n = 0;
      interval = 1;
    }

    final nextDue = DateTime.now().add(Duration(days: interval));

    return card.copyWith(
      interval: interval,
      easeFactor: ef,
      repetitions: n,
      dueDate: nextDue,
    );
  }
}
