class GrammarUnit {
  const GrammarUnit({
    required this.id,
    required this.grammarBookId,
    required this.unitNumber,
    required this.title,
    this.subtitle,
    required this.sortOrder,
    required this.isActive,
    this.createdAt,
    required this.textCount,
    required this.questionCount,
  });

  final int id;
  final int grammarBookId;
  final int unitNumber;
  final String title;
  final String? subtitle;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final int textCount;
  final int questionCount;

  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Unit $unitNumber';
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _asBool(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  factory GrammarUnit.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at']?.toString();
    return GrammarUnit(
      id: _asInt(json['id']),
      grammarBookId: _asInt(json['grammar_book_id']),
      unitNumber: _asInt(json['unit_number']),
      title: (json['title'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
      sortOrder: _asInt(json['sort_order']),
      isActive: _asBool(json['is_active']),
      createdAt: rawCreatedAt == null || rawCreatedAt.isEmpty
          ? null
          : DateTime.tryParse(rawCreatedAt.replaceFirst(' ', 'T')),
      textCount: _asInt(json['text_count']),
      questionCount: _asInt(json['question_count']),
    );
  }
}
