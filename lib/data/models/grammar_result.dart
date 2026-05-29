class GrammarResult {
  const GrammarResult({
    required this.id,
    required this.createdAt,
    required this.quizName,
    required this.score,
    required this.totalQuestions,
    this.userId,
    this.userName,
    this.bio,
    this.public,
    this.selectedGrammarsRaw,
    this.avatar,
    this.grammarQuizTotal,
  });

  final int id;
  final int? userId;
  final String createdAt;
  final String quizName;
  final int? score;
  final int? totalQuestions;
  final String? userName;
  final String? bio;
  final int? public;
  final String? selectedGrammarsRaw;

  /// Preset avatar id from `users.avatar` when joined (e.g. m1, f2).
  final String? avatar;

  /// Public grammar leaderboard (`sort=practice`): number of shared quiz rows for this user.
  final int? grammarQuizTotal;

  factory GrammarResult.fromJson(Map<String, dynamic> json) {
    return GrammarResult(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      createdAt: (json['created_at'] as String?) ?? '',
      userName: json['user_name'] as String?,
      bio: json['bio'] as String?,
      quizName: (json['quiz_name'] as String?) ?? '',
      score: (json['score'] as num?)?.toInt(),
      totalQuestions: (json['total_questions'] as num?)?.toInt(),
      public: (json['public'] as num?)?.toInt(),
      selectedGrammarsRaw: json['selected_grammars'] as String?,
      avatar: json['avatar'] as String?,
      grammarQuizTotal: (json['quiz_count'] as num?)?.toInt(),
    );
  }
}

/// One page from [ApiService.fetchPublicGrammarResultsPage].
class PublicGrammarResultsPage {
  const PublicGrammarResultsPage({
    required this.results,
    required this.hasMore,
  });

  final List<GrammarResult> results;
  final bool hasMore;
}

class LegacyGrammarResultSample {
  const LegacyGrammarResultSample({
    required this.id,
    required this.createdAt,
    required this.quizName,
    this.score,
    this.totalQuestions,
  });

  final int id;
  final String createdAt;
  final String quizName;
  final int? score;
  final int? totalQuestions;

  factory LegacyGrammarResultSample.fromJson(Map<String, dynamic> json) {
    return LegacyGrammarResultSample(
      id: (json['id'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] as String?) ?? '',
      quizName: (json['quiz_name'] as String?) ?? '',
      score: (json['score'] as num?)?.toInt(),
      totalQuestions: (json['total_questions'] as num?)?.toInt(),
    );
  }
}

class LegacyGrammarResultLinkPreview {
  const LegacyGrammarResultLinkPreview({
    required this.legacyName,
    required this.email,
    required this.displayName,
    required this.matchedResultCount,
    required this.samples,
    this.userId,
  });

  final String legacyName;
  final String email;
  final String displayName;
  final int matchedResultCount;
  final List<LegacyGrammarResultSample> samples;
  final int? userId;

  factory LegacyGrammarResultLinkPreview.fromJson(Map<String, dynamic> json) {
    final samples = json['samples'] as List<dynamic>? ?? const [];
    return LegacyGrammarResultLinkPreview(
      legacyName: (json['legacy_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      matchedResultCount: (json['matched_result_count'] as num?)?.toInt() ?? 0,
      samples: samples
          .whereType<Map<String, dynamic>>()
          .map(LegacyGrammarResultSample.fromJson)
          .toList(),
      userId: (json['user_id'] as num?)?.toInt(),
    );
  }
}
