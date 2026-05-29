enum LeagueType {
  all('all'),
  grammar('grammar'),
  vocab('vocab'),
  challenge('challenge'),
  wordBuilder('word_builder');

  const LeagueType(this.apiValue);

  final String apiValue;

  String get label => switch (this) {
    LeagueType.all => 'All',
    LeagueType.grammar => 'Grammar',
    LeagueType.vocab => 'Vocab',
    LeagueType.challenge => 'Challenge',
    LeagueType.wordBuilder => 'Word Builder',
  };

  String get title => switch (this) {
    LeagueType.all => 'All League',
    LeagueType.grammar => 'Grammar Practice',
    LeagueType.vocab => 'Vocabulary League',
    LeagueType.challenge => 'Grammar Challenge',
    LeagueType.wordBuilder => 'Word Builder',
  };

  static LeagueType fromApi(String? value) {
    return LeagueType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => LeagueType.all,
    );
  }
}

enum LeaguePeriod {
  weekly('weekly'),
  monthly('monthly'),
  lifetime('lifetime');

  const LeaguePeriod(this.apiValue);

  final String apiValue;

  String get label => switch (this) {
    LeaguePeriod.weekly => 'Weekly',
    LeaguePeriod.monthly => 'This month',
    LeaguePeriod.lifetime => 'Lifetime',
  };

  String get compactLabel => switch (this) {
    LeaguePeriod.weekly => 'Week',
    LeaguePeriod.monthly => 'Month',
    LeaguePeriod.lifetime => 'Life',
  };

  static LeaguePeriod fromApi(String? value) {
    return LeaguePeriod.values.firstWhere(
      (period) => period.apiValue == value,
      orElse: () => LeaguePeriod.monthly,
    );
  }
}

enum LeagueSort {
  points('points'),
  accuracy('accuracy');

  const LeagueSort(this.apiValue);

  final String apiValue;

  String get label => switch (this) {
    LeagueSort.points => 'Points',
    LeagueSort.accuracy => 'Accuracy',
  };

  static LeagueSort fromApi(String? value) {
    return LeagueSort.values.firstWhere(
      (sort) => sort.apiValue == value,
      orElse: () => LeagueSort.points,
    );
  }
}

typedef LeagueQuery = ({LeagueType type, LeaguePeriod period, LeagueSort sort});

class LeagueSeason {
  const LeagueSeason({
    required this.id,
    required this.title,
    required this.seasonType,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final int id;
  final String title;
  final String seasonType;
  final String startsAt;
  final String endsAt;
  final String status;

  factory LeagueSeason.fromJson(Map<String, dynamic> json) {
    return LeagueSeason(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Weekly League',
      seasonType: (json['season_type'] as String?) ?? 'weekly',
      startsAt: (json['starts_at'] as String?) ?? '',
      endsAt: (json['ends_at'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'active',
    );
  }
}

class LeagueEntry {
  const LeagueEntry({
    required this.userId,
    required this.displayName,
    required this.avatar,
    required this.points,
    required this.accuracy,
    required this.correctCount,
    required this.wrongCount,
    required this.answeredCount,
    required this.completedCount,
    required this.sessionCount,
    required this.activeDays,
    required this.eligible,
    required this.badge,
    this.grammarReportCount = 0,
    this.bio,
    this.rank,
  });

  final int userId;
  final String displayName;
  final String avatar;
  final int? rank;
  final int points;
  final double accuracy;
  final int correctCount;
  final int wrongCount;
  final int answeredCount;
  final int completedCount;
  final int sessionCount;
  final int activeDays;
  final bool eligible;
  final String badge;
  final int grammarReportCount;
  final String? bio;

  int neededAnswers(int minimum) {
    final left = minimum - answeredCount;
    return left < 0 ? 0 : left;
  }

  factory LeagueEntry.fromJson(Map<String, dynamic> json) {
    return LeagueEntry(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
          ? (json['display_name'] as String).trim()
          : 'Learner',
      avatar: (json['avatar'] as String?)?.trim().isNotEmpty == true
          ? (json['avatar'] as String).trim()
          : 'm1',
      rank: (json['rank'] as num?)?.toInt(),
      points: (json['points'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      answeredCount: (json['answered_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      activeDays: (json['active_days'] as num?)?.toInt() ?? 0,
      eligible: json['eligible'] != false,
      badge: (json['badge'] as String?) ?? 'Rising Learner',
      grammarReportCount: (json['grammar_report_count'] as num?)?.toInt() ?? 0,
      bio: json['bio'] as String?,
    );
  }
}

class LeagueSummary {
  const LeagueSummary({required this.participants, required this.totalPoints});

  final int participants;
  final int totalPoints;

  factory LeagueSummary.fromJson(Map<String, dynamic>? json) {
    return LeagueSummary(
      participants: (json?['participants'] as num?)?.toInt() ?? 0,
      totalPoints: (json?['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeagueResponse {
  const LeagueResponse({
    required this.type,
    required this.period,
    required this.sort,
    required this.season,
    required this.leaderboard,
    required this.summary,
    required this.minimumAnswered,
    required this.activeChallenges,
    required this.hasMore,
    required this.nextOffset,
    this.currentUserRank,
  });

  final LeagueType type;
  final LeaguePeriod period;
  final LeagueSort sort;
  final LeagueSeason season;
  final List<LeagueEntry> leaderboard;
  final LeagueEntry? currentUserRank;
  final LeagueSummary summary;
  final int minimumAnswered;
  final int activeChallenges;
  final bool hasMore;
  final int nextOffset;

  factory LeagueResponse.fromJson(Map<String, dynamic> json) {
    final list = json['leaderboard'] as List<dynamic>? ?? const [];
    final current = json['current_user_rank'];
    return LeagueResponse(
      type: LeagueType.fromApi(json['type'] as String?),
      period: LeaguePeriod.fromApi(json['period'] as String?),
      sort: LeagueSort.fromApi(json['sort'] as String?),
      season: LeagueSeason.fromJson(
        (json['season'] as Map<String, dynamic>?) ?? const {},
      ),
      leaderboard: list
          .whereType<Map<String, dynamic>>()
          .map(LeagueEntry.fromJson)
          .toList(),
      currentUserRank: current is Map<String, dynamic>
          ? LeagueEntry.fromJson(current)
          : null,
      summary: LeagueSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      minimumAnswered: (json['minimum_answered'] as num?)?.toInt() ?? 0,
      activeChallenges: (json['active_challenges'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] == true,
      nextOffset: (json['next_offset'] as num?)?.toInt() ?? list.length,
    );
  }
}
