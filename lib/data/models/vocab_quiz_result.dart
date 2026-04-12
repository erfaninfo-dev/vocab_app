class VocabQuizResultSummary {
  const VocabQuizResultSummary({
    required this.id,
    required this.bookId,
    this.bookTitle,
    required this.score,
    required this.totalQuestions,
    required this.createdAt,
  });

  final int id;
  final int bookId;
  final String? bookTitle;
  final int score;
  final int totalQuestions;
  final String createdAt;

  factory VocabQuizResultSummary.fromJson(Map<String, dynamic> json) {
    return VocabQuizResultSummary(
      id: (json['id'] as num).toInt(),
      bookId: (json['book_id'] as num).toInt(),
      bookTitle: json['book_title']?.toString(),
      score: (json['score'] as num).toInt(),
      totalQuestions: (json['total_questions'] as num).toInt(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class VocabQuizSessionItem {
  const VocabQuizSessionItem({
    required this.wordKey,
    required this.unit,
    required this.word,
    required this.correct,
    required this.given,
    required this.mode,
  });

  final String wordKey;
  final int unit;
  final String word;
  final bool correct;
  final String given;
  final String mode;

  factory VocabQuizSessionItem.fromJson(Map<String, dynamic> json) {
    return VocabQuizSessionItem(
      wordKey: (json['word_key'] ?? '').toString(),
      unit: (json['unit'] as num?)?.toInt() ?? 0,
      word: (json['word'] ?? '').toString(),
      correct: json['correct'] == true || json['correct'] == 1,
      given: (json['given'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
    );
  }
}

class VocabQuizResultDetail {
  const VocabQuizResultDetail({
    required this.id,
    required this.bookId,
    this.bookTitle,
    required this.score,
    required this.totalQuestions,
    required this.createdAt,
    required this.items,
    this.meta,
  });

  final int id;
  final int bookId;
  final String? bookTitle;
  final int score;
  final int totalQuestions;
  final String createdAt;
  final List<VocabQuizSessionItem> items;
  final Map<String, dynamic>? meta;

  factory VocabQuizResultDetail.fromApiJson(Map<String, dynamic> map) {
    final session = map['session'];
    List<VocabQuizSessionItem> items = [];
    Map<String, dynamic>? meta;
    if (session is Map<String, dynamic>) {
      meta = session['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(session['meta'] as Map)
          : null;
      final rawItems = session['items'];
      if (rawItems is List) {
        items = rawItems
            .map((e) => VocabQuizSessionItem.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
    }
    return VocabQuizResultDetail(
      id: (map['id'] as num).toInt(),
      bookId: (map['book_id'] as num).toInt(),
      bookTitle: map['book_title']?.toString(),
      score: (map['score'] as num).toInt(),
      totalQuestions: (map['total_questions'] as num).toInt(),
      createdAt: map['created_at']?.toString() ?? '',
      items: items,
      meta: meta,
    );
  }
}
