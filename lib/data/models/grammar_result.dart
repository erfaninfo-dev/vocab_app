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
