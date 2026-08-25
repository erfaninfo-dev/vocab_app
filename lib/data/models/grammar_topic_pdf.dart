/// A grammar topic study PDF row from `GET /grammar_topic_pdfs.php`.
/// A topic may have multiple rows; use [sortOrder] for display order.
class GrammarTopicPdf {
  const GrammarTopicPdf({
    required this.id,
    required this.topic,
    required this.title,
    required this.pdfUrl,
    required this.sortOrder,
    this.updatedAt,
  });

  final int id;
  final String topic;
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

  factory GrammarTopicPdf.fromJson(Map<String, dynamic> json) {
    final rawUpdatedAt = json['updated_at']?.toString();
    return GrammarTopicPdf(
      id: (json['id'] as num?)?.toInt() ?? 0,
      topic: (json['topic'] ?? '').toString(),
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
