/// A vocabulary book study PDF row from `GET /book_pdfs.php`.
/// A book may have multiple rows; use [sortOrder] for display order.
class BookPdf {
  const BookPdf({
    required this.id,
    required this.bookId,
    required this.title,
    required this.pdfUrl,
    required this.sortOrder,
    this.updatedAt,
  });

  final int id;
  final int bookId;
  final String title;
  final String pdfUrl;
  final int sortOrder;
  final DateTime? updatedAt;

  bool get hasValidUrl => pdfUrl.trim().isNotEmpty;

  /// Used by local cache to detect server-side file updates with the same URL.
  String get cacheVersion {
    final stamp = updatedAt?.toUtc().toIso8601String();
    if (stamp != null && stamp.isNotEmpty) return stamp;
    return 'id:$id';
  }

  factory BookPdf.fromJson(Map<String, dynamic> json) {
    final rawUpdatedAt = json['updated_at']?.toString();
    return BookPdf(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookId: (json['book_id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      pdfUrl: (json['pdf_url'] ?? '').toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
      updatedAt: rawUpdatedAt == null || rawUpdatedAt.isEmpty
          ? null
          : DateTime.tryParse(rawUpdatedAt.replaceFirst(' ', 'T')),
    );
  }

  String displayTitle({String fallbackPrefix = 'Part'}) {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return '$fallbackPrefix $sortOrder';
  }
}
