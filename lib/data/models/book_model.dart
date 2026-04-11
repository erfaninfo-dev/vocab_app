class Book {
  const Book({
    required this.id,
    required this.title,
    this.description,
    required this.sortOrder,
    this.track = 'ielts',
    this.seriesId,
    this.volumeOrder = 0,
    this.seriesTitle,
    this.seriesSortOrder = 999999,
    this.isPublic = true,
    this.isStudent = false,
  });

  final int id;
  final String title;
  final String? description;
  final int sortOrder;

  /// Server: `ielts` | `general` (default `ielts` if column missing).
  final String track;

  final int? seriesId;
  final int volumeOrder;
  final String? seriesTitle;
  final int seriesSortOrder;

  /// Catalog visibility (server `is_public` / `is_student`).
  final bool isPublic;
  final bool isStudent;

  bool get isIeltsTrack => track.toLowerCase() == 'ielts';
  bool get isGeneralTrack => track.toLowerCase() == 'general';

  /// Order volumes inside one series (API uses `volume_order`, then `sort_order`).
  static int compareSeriesVolumes(Book a, Book b) {
    var c = a.volumeOrder.compareTo(b.volumeOrder);
    if (c != 0) return c;
    c = a.sortOrder.compareTo(b.sortOrder);
    if (c != 0) return c;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      track: (json['track'] ?? 'ielts').toString().toLowerCase(),
      seriesId: (json['series_id'] as num?)?.toInt(),
      volumeOrder: (json['volume_order'] as num?)?.toInt() ?? 0,
      seriesTitle: json['series_title']?.toString(),
      seriesSortOrder: (json['series_sort_order'] as num?)?.toInt() ?? 999999,
      isPublic: json['is_public'] == false ? false : true,
      isStudent: json['is_student'] == true || json['is_student'] == 1,
    );
  }
}

/// Sorts [books] in place for display inside a series screen.
void sortBooksInSeriesDisplayOrder(List<Book> books) {
  books.sort(Book.compareSeriesVolumes);
}
