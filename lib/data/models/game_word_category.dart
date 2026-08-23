/// A single themed word (e.g. "cat") as returned by
/// `GET /game_word_categories.php`.
class GameCategoryWord {
  const GameCategoryWord({
    required this.word,
    this.meaningEn = '',
    required this.meaningFa,
    required this.meaningKur,
    this.exampleEn,
    this.exampleFa,
    this.exampleKur,
  });

  final String word;
  final String meaningEn;
  final String meaningFa;
  final String meaningKur;
  final String? exampleEn;
  final String? exampleFa;
  final String? exampleKur;

  factory GameCategoryWord.fromJson(Map<String, dynamic> json) {
    return GameCategoryWord(
      word: (json['word'] ?? '').toString(),
      meaningEn: (json['meaning_en'] ?? '').toString(),
      meaningFa: (json['meaning_fa'] ?? '').toString(),
      meaningKur: (json['meaning_kur'] ?? '').toString(),
      exampleEn: json['example_en'] as String?,
      exampleFa: json['example_fa'] as String?,
      exampleKur: json['example_kur'] as String?,
    );
  }
}

/// A themed Word Builder category (e.g. "Animals") as returned by
/// `GET /game_word_categories.php`, with its full word bank nested inside.
class GameWordCategory {
  const GameWordCategory({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameFa,
    required this.nameCkb,
    required this.icon,
    required this.sortOrder,
    required this.words,
  });

  final int id;
  final String slug;
  final String nameEn;
  final String nameFa;
  final String nameCkb;

  /// Material icon identifier, e.g. `'pets_rounded'`. Mapped to an actual
  /// `IconData` by the Word Builder feature layer (kept out of this plain
  /// data model to avoid a Flutter dependency here).
  final String icon;
  final int sortOrder;
  final List<GameCategoryWord> words;

  factory GameWordCategory.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>? ?? const [];
    return GameWordCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: (json['slug'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
      nameFa: (json['name_fa'] ?? '').toString(),
      nameCkb: (json['name_ckb'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      words: rawWords
          .map((w) => GameCategoryWord.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}
