class VocabQuizResultSummary {
  const VocabQuizResultSummary({
    required this.id,
    required this.bookId,
    this.bookTitle,
    this.quizName,
    this.units = const [],
    required this.correct,
    required this.wrong,
    this.createdAt,
  });

  final int id;
  final int bookId;
  final String? bookTitle;

  /// Server `vocab_quiz_results.created_at` (e.g. `YYYY-MM-DD HH:MM:SS`).
  final String? createdAt;

  /// From session meta (e.g. localized "Vocabulary quiz").
  final String? quizName;

  /// Distinct unit numbers included in the session.
  final List<int> units;
  final int correct;
  final int wrong;

  factory VocabQuizResultSummary.fromJson(Map<String, dynamic> json) {
    final units = <int>[];
    final rawU = json['units'];
    if (rawU is List) {
      for (final e in rawU) {
        if (e is num) units.add(e.toInt());
      }
    }
    final score = (json['score'] as num?)?.toInt();
    final total = (json['total_questions'] as num?)?.toInt();
    final correct = (json['correct'] as num?)?.toInt() ?? score ?? 0;
    int? wrong = (json['wrong'] as num?)?.toInt();
    if (wrong == null && total != null) {
      wrong = (total - correct).clamp(0, 1 << 30);
    }
    wrong ??= 0;

    return VocabQuizResultSummary(
      id: (json['id'] as num).toInt(),
      bookId: (json['book_id'] as num).toInt(),
      bookTitle: json['book_title']?.toString(),
      quizName: json['quiz_name']?.toString(),
      units: units,
      correct: correct,
      wrong: wrong,
      createdAt: json['created_at']?.toString(),
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

  String? get quizNameFromMeta {
    final m = meta;
    if (m == null) return null;
    final q = m['quiz_name']?.toString().trim();
    return (q != null && q.isNotEmpty) ? q : null;
  }

  List<int> get unitsFromMeta {
    final m = meta;
    if (m == null) return const [];
    final u = m['units'];
    if (u is! List) return const [];
    final out = <int>[];
    for (final e in u) {
      if (e is num) out.add(e.toInt());
    }
    out.sort();
    return out;
  }

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
            .map(
              (e) => VocabQuizSessionItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
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
