class UnitSample {
  const UnitSample({
    required this.id,
    required this.bookId,
    required this.unit,
    this.section,
    required this.title,
    required this.textEnFa,
    required this.textEnKur,
    required this.sortOrder,
  });

  final int id;
  final int bookId;
  final int unit;

  /// Null or 0 = unit-wide; > 0 = belongs to that section (when filtering by section).
  final int? section;

  final String title;
  final String textEnFa;
  final String textEnKur;
  final int sortOrder;

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory UnitSample.fromJson(Map<String, dynamic> json) {
    final secRaw = json['section'];
    final sec = secRaw == null ? null : _asInt(secRaw);

    return UnitSample(
      id: _asInt(json['id']),
      bookId: _asInt(json['book_id']),
      unit: _asInt(json['unit']),
      section: sec == null || sec <= 0 ? null : sec,
      title: (json['title'] ?? '').toString(),
      textEnFa: (json['text_en_fa'] ?? '').toString(),
      textEnKur: (json['text_en_kur'] ?? '').toString(),
      sortOrder: _asInt(json['sort_order']),
    );
  }
}
