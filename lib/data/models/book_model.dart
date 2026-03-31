class Book {
  const Book({
    required this.id,
    required this.title,
    this.description,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String? description;
  final int sortOrder;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
