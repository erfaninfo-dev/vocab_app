class GrammarUnitText {
  const GrammarUnitText({
    required this.id,
    required this.grammarUnitId,
    required this.title,
    required this.textEnFa,
    required this.textEnKur,
    required this.sortOrder,
    required this.isActive,
    this.createdAt,
  });

  final int id;
  final int grammarUnitId;
  final String title;
  final String textEnFa;
  final String textEnKur;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _asBool(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  factory GrammarUnitText.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at']?.toString();
    return GrammarUnitText(
      id: _asInt(json['id']),
      grammarUnitId: _asInt(json['grammar_unit_id']),
      title: (json['title'] ?? '').toString(),
      textEnFa: (json['text_en_fa'] ?? '').toString(),
      textEnKur: (json['text_en_kur'] ?? '').toString(),
      sortOrder: _asInt(json['sort_order']),
      isActive: _asBool(json['is_active']),
      createdAt: rawCreatedAt == null || rawCreatedAt.isEmpty
          ? null
          : DateTime.tryParse(rawCreatedAt.replaceFirst(' ', 'T')),
    );
  }
}
