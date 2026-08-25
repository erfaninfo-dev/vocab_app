/// Allowed Telegram-style reactions on grammar community result cards.
const kGrammarResultReactionEmojis = ['👍', '❤️', '🔥', '👏', '🎯'];

class GrammarResultReactionSummary {
  const GrammarResultReactionSummary({
    required this.counts,
    this.myEmoji,
  });

  final Map<String, int> counts;
  final String? myEmoji;

  factory GrammarResultReactionSummary.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['counts'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (key.isEmpty || value is! num) continue;
        counts[key] = value.toInt();
      }
    }
    final my = json['my_emoji']?.toString();
    return GrammarResultReactionSummary(
      counts: counts,
      myEmoji: my == null || my.isEmpty ? null : my,
    );
  }

  GrammarResultReactionSummary copyWith({
    Map<String, int>? counts,
    String? myEmoji,
    bool clearMyEmoji = false,
  }) {
    return GrammarResultReactionSummary(
      counts: counts ?? this.counts,
      myEmoji: clearMyEmoji ? null : (myEmoji ?? this.myEmoji),
    );
  }

  int totalCount() => counts.values.fold(0, (a, b) => a + b);
}

class GrammarResultReactionsBatch {
  const GrammarResultReactionsBatch({required this.byResultId});

  final Map<int, GrammarResultReactionSummary> byResultId;

  factory GrammarResultReactionsBatch.fromJson(Map<String, dynamic> json) {
    final raw = json['reactions'];
    final map = <int, GrammarResultReactionSummary>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final id = int.tryParse(entry.key.toString());
        if (id == null || id < 1) continue;
        if (entry.value is Map) {
          map[id] = GrammarResultReactionSummary.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }
    return GrammarResultReactionsBatch(byResultId: map);
  }
}
