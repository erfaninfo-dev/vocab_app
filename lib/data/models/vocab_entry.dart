class VocabEntry {
  const VocabEntry({
    required this.rowId,
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

  /// DB row id from server `words` table.
  final int rowId;

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

  /// Backward-compatible match for vocab-quiz "wrong" keys stored on server.
  ///
  /// Historical keys used [id], which included `meaningFa` and could change when
  /// translations/content changed. We therefore also accept the legacy *prefix*
  /// without the meaning part, so existing mistakes still match current words.
  bool matchesWrongKey(String rawKey) {
    final key = rawKey.trim();
    if (key.isEmpty) return false;
    if (key == id) return true;
    // Some servers/clients may store the DB row id as the key.
    if (key == rowId.toString()) return true;
    final lower = key.toLowerCase();
    final legacyPrefix =
        '${bookId.toLowerCase()}|${word.toLowerCase()}|${section ?? 0}-$unit|';
    return lower.startsWith(legacyPrefix);
  }

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
      rowId: (json['id'] as num?)?.toInt() ?? 0,
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
