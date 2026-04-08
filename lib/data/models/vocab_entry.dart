class VocabEntry {
  const VocabEntry({
    required this.bookId,
    required this.word,
    required this.type,
    required this.meaningEn,
    required this.meaningFa,
    required this.meaningKur,
    required this.exampleEn,
    required this.exampleFa,
    required this.exampleKur,
    required this.unit,
    required this.section,
    this.important = 0,
  });

  final String bookId;
  final String word;
  final String type;
  final String meaningEn;
  final String meaningFa;
  final String meaningKur;
  final String exampleEn;
  final String exampleFa;
  final String exampleKur;
  final int unit;
  // Nullable: words that belong to a unit with no sections have section == null.
  final int? section;

  /// Server: 1 = important word, 0 = normal.
  final int important;

  bool get isImportant => important == 1;

  String get example => exampleEn;

  String get id =>
      '${bookId.toLowerCase()}|${word.toLowerCase()}|${section ?? 0}-$unit|${meaningFa.toLowerCase()}';

  bool matchesQuery(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return word.toLowerCase().contains(query) ||
        meaningEn.toLowerCase().contains(query) ||
        meaningFa.toLowerCase().contains(query) ||
        meaningKur.toLowerCase().contains(query) ||
        exampleEn.toLowerCase().contains(query) ||
        exampleFa.toLowerCase().contains(query) ||
        exampleKur.toLowerCase().contains(query);
  }

  /// Words screen: search matches the English headword only (not meanings/examples).
  bool matchesWordQuery(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return word.toLowerCase().contains(query);
  }

  // ── API mode ─────────────────────────────────────────────────────────────
  // Parses a word row returned by the server API.
  // Expected JSON keys match the database column names:
  //   id, book_id, unit, section (nullable), word, type,
  //   meaning_en, meaning_fa, meaning_kur, example_en, example_fa, example_kur
  factory VocabEntry.fromJson(
    Map<String, dynamic> json, {
    required String bookId,
  }) {
    return VocabEntry(
      bookId: bookId,
      word: (json['word'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      meaningEn: (json['meaning_en'] ?? '').toString(),
      meaningFa: (json['meaning_fa'] ?? '').toString(),
      meaningKur: (json['meaning_kur'] ?? '').toString(),
      exampleEn: (json['example_en'] ?? '').toString(),
      exampleFa: (json['example_fa'] ?? '').toString(),
      exampleKur: (json['example_kur'] ?? '').toString(),
      unit: (json['unit'] as num?)?.toInt() ?? 0,
      section: (json['section'] as num?)?.toInt(),
      important: (json['important'] as num?)?.toInt() ?? 0,
    );
  }
}
