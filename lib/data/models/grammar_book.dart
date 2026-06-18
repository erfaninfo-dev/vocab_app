class GrammarBook {
  const GrammarBook({
    required this.id,
    required this.title,
    this.level,
    this.description,
    required this.sortOrder,
    required this.isActive,
    this.createdAt,
    required this.unitCount,
    required this.questionCount,
  });

  final int id;
  final String title;
  final String? level;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final int unitCount;
  final int questionCount;

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _asBool(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  factory GrammarBook.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at']?.toString();
    return GrammarBook(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      level: json['level']?.toString(),
      description: json['description']?.toString(),
      sortOrder: _asInt(json['sort_order']),
      isActive: _asBool(json['is_active']),
      createdAt: rawCreatedAt == null || rawCreatedAt.isEmpty
          ? null
          : DateTime.tryParse(rawCreatedAt.replaceFirst(' ', 'T')),
      unitCount: _asInt(json['unit_count']),
      questionCount: _asInt(json['question_count']),
    );
  }
}
