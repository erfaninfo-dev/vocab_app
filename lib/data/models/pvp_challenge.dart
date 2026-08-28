enum PvpMatchStatus {
  pending('pending'),
  accepted('accepted'),
  completed('completed'),
  declined('declined'),
  expired('expired'),
  cancelled('cancelled');

  const PvpMatchStatus(this.apiValue);

  final String apiValue;

  static PvpMatchStatus fromApi(String? value) {
    return PvpMatchStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => PvpMatchStatus.pending,
    );
  }
}

enum PvpPlayerStatus {
  waiting('waiting'),
  playing('playing'),
  submitted('submitted'),
  forfeited('forfeited');

  const PvpPlayerStatus(this.apiValue);

  final String apiValue;

  static PvpPlayerStatus fromApi(String? value) {
    return PvpPlayerStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => PvpPlayerStatus.waiting,
    );
  }
}

class PvpUserBrief {
  const PvpUserBrief({
    required this.userId,
    required this.displayName,
    required this.avatar,
  });

  final int userId;
  final String displayName;
  final String avatar;

  factory PvpUserBrief.fromJson(Map<String, dynamic> json) {
    return PvpUserBrief(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      displayName: (json['display_name'] ?? '').toString(),
      avatar: (json['avatar'] ?? 'm1').toString(),
    );
  }
}

class PvpCategorySummary {
  const PvpCategorySummary({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameFa,
    required this.nameCkb,
    required this.icon,
  });

  final int id;
  final String slug;
  final String nameEn;
  final String nameFa;
  final String nameCkb;
  final String icon;

  String label({required bool preferKur}) {
    if (preferKur && nameCkb.trim().isNotEmpty) return nameCkb.trim();
    if (nameFa.trim().isNotEmpty) return nameFa.trim();
    return nameEn.trim().isNotEmpty ? nameEn.trim() : slug;
  }

  factory PvpCategorySummary.fromJson(Map<String, dynamic> json) {
    return PvpCategorySummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: (json['slug'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
      nameFa: (json['name_fa'] ?? '').toString(),
      nameCkb: (json['name_ckb'] ?? '').toString(),
      icon: (json['icon'] ?? 'category_rounded').toString(),
    );
  }
}

class PvpViewerState {
  const PvpViewerState({
    required this.userId,
    required this.canAccept,
    required this.canDecline,
    required this.canPlay,
    required this.hideLetters,
    this.reasonIfBlocked,
    required this.isChallenger,
    required this.isOpponent,
  });

  final int userId;
  final bool canAccept;
  final bool canDecline;
  final bool canPlay;
  final bool hideLetters;
  final String? reasonIfBlocked;
  final bool isChallenger;
  final bool isOpponent;

  factory PvpViewerState.fromJson(Map<String, dynamic> json) {
    return PvpViewerState(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      canAccept: json['can_accept'] == true,
      canDecline: json['can_decline'] == true,
      canPlay: json['can_play'] == true,
      hideLetters: json['hide_letters'] == true,
      reasonIfBlocked: json['reason_if_blocked'] as String?,
      isChallenger: json['is_challenger'] == true,
      isOpponent: json['is_opponent'] == true,
    );
  }
}

class PvpMatchPlayer {
  const PvpMatchPlayer({
    required this.userId,
    required this.displayName,
    required this.avatar,
    required this.turnOrder,
    required this.playerStatus,
    this.score,
    this.words,
    this.startedAt,
    this.completedAt,
  });

  final int userId;
  final String displayName;
  final String avatar;
  final int turnOrder;
  final PvpPlayerStatus playerStatus;
  final int? score;
  final List<String>? words;
  final String? startedAt;
  final String? completedAt;

  factory PvpMatchPlayer.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'];
    List<String>? words;
    if (rawWords is List) {
      words = rawWords.map((e) => e.toString()).toList();
    }
    return PvpMatchPlayer(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      displayName: (json['display_name'] ?? '').toString(),
      avatar: (json['avatar'] ?? 'm1').toString(),
      turnOrder: (json['turn_order'] as num?)?.toInt() ?? 0,
      playerStatus: PvpPlayerStatus.fromApi(json['player_status'] as String?),
      score: (json['score'] as num?)?.toInt(),
      words: words,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }
}

class PvpMatch {
  const PvpMatch({
    required this.id,
    required this.status,
    required this.durationSec,
    required this.category,
    required this.letters,
    required this.anchorWords,
    required this.expiresAt,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.winnerId,
    required this.isDraw,
    this.challenger,
    this.opponent,
    required this.players,
    required this.viewer,
  });

  final int id;
  final PvpMatchStatus status;
  final int durationSec;
  final PvpCategorySummary category;
  final List<String> letters;
  final List<String> anchorWords;
  final String expiresAt;
  final String createdAt;
  final String? acceptedAt;
  final String? completedAt;
  final int? winnerId;
  final bool isDraw;
  final PvpUserBrief? challenger;
  final PvpUserBrief? opponent;
  final List<PvpMatchPlayer> players;
  final PvpViewerState viewer;

  PvpMatchPlayer? playerFor(int userId) {
    for (final p in players) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  factory PvpMatch.fromJson(Map<String, dynamic> json) {
    final rawLetters = json['letters'] as List<dynamic>? ?? const [];
    final rawAnchor = json['anchor_words'] as List<dynamic>? ?? const [];
    final rawPlayers = json['players'] as List<dynamic>? ?? const [];
    return PvpMatch(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: PvpMatchStatus.fromApi(json['status'] as String?),
      durationSec: (json['duration_sec'] as num?)?.toInt() ?? 60,
      category: PvpCategorySummary.fromJson(
        json['category'] as Map<String, dynamic>? ?? const {},
      ),
      letters: rawLetters.map((e) => e.toString().toLowerCase()).toList(),
      anchorWords: rawAnchor.map((e) => e.toString()).toList(),
      expiresAt: (json['expires_at'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      acceptedAt: json['accepted_at'] as String?,
      completedAt: json['completed_at'] as String?,
      winnerId: (json['winner_id'] as num?)?.toInt(),
      isDraw: json['is_draw'] == true,
      challenger: json['challenger'] is Map<String, dynamic>
          ? PvpUserBrief.fromJson(json['challenger'] as Map<String, dynamic>)
          : null,
      opponent: json['opponent'] is Map<String, dynamic>
          ? PvpUserBrief.fromJson(json['opponent'] as Map<String, dynamic>)
          : null,
      players: rawPlayers
          .map((e) => PvpMatchPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewer: PvpViewerState.fromJson(
        json['viewer'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PvpMatchSummaryCard {
  const PvpMatchSummaryCard({
    required this.id,
    required this.status,
    required this.category,
    required this.expiresAt,
    required this.isMyTurn,
    required this.isDraw,
    this.winnerId,
    this.otherUser,
    this.myScore,
    this.otherScore,
    required this.viewer,
  });

  final int id;
  final PvpMatchStatus status;
  final PvpCategorySummary category;
  final String expiresAt;
  final bool isMyTurn;
  final bool isDraw;
  final int? winnerId;
  final PvpUserBrief? otherUser;
  final int? myScore;
  final int? otherScore;
  final PvpViewerState viewer;

  factory PvpMatchSummaryCard.fromJson(Map<String, dynamic> json) {
    return PvpMatchSummaryCard(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: PvpMatchStatus.fromApi(json['status'] as String?),
      category: PvpCategorySummary.fromJson(
        json['category'] as Map<String, dynamic>? ?? const {},
      ),
      expiresAt: (json['expires_at'] ?? '').toString(),
      isMyTurn: json['is_my_turn'] == true,
      isDraw: json['is_draw'] == true,
      winnerId: (json['winner_id'] as num?)?.toInt(),
      otherUser: json['other_user'] is Map<String, dynamic>
          ? PvpUserBrief.fromJson(json['other_user'] as Map<String, dynamic>)
          : null,
      myScore: (json['my_score'] as num?)?.toInt(),
      otherScore: (json['other_score'] as num?)?.toInt(),
      viewer: PvpViewerState.fromJson(
        json['viewer'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PvpMatchListBuckets {
  const PvpMatchListBuckets({
    required this.incomingPending,
    required this.myTurn,
    required this.waitingOpponent,
    required this.completedRecent,
  });

  final List<PvpMatchSummaryCard> incomingPending;
  final List<PvpMatchSummaryCard> myTurn;
  final List<PvpMatchSummaryCard> waitingOpponent;
  final List<PvpMatchSummaryCard> completedRecent;

  int get actionCount => incomingPending.length + myTurn.length;

  factory PvpMatchListBuckets.fromJson(Map<String, dynamic> json) {
    List<PvpMatchSummaryCard> parseList(String key) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw
          .map((e) => PvpMatchSummaryCard.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PvpMatchListBuckets(
      incomingPending: parseList('incoming_pending'),
      myTurn: parseList('my_turn'),
      waitingOpponent: parseList('waiting_opponent'),
      completedRecent: parseList('completed_recent'),
    );
  }
}

class PvpSubmitValidation {
  const PvpSubmitValidation({
    required this.validWords,
    required this.invalidWords,
    required this.duplicateWords,
    required this.score,
  });

  final List<String> validWords;
  final List<String> invalidWords;
  final List<String> duplicateWords;
  final int score;

  factory PvpSubmitValidation.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.map((e) => e.toString()).toList();
    }

    return PvpSubmitValidation(
      validWords: list('valid_words'),
      invalidWords: list('invalid_words'),
      duplicateWords: list('duplicate_words'),
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}

class PvpSubmitResult {
  const PvpSubmitResult({
    required this.player,
    required this.match,
    required this.validation,
  });

  final PvpMatchPlayer player;
  final PvpMatch match;
  final PvpSubmitValidation validation;

  factory PvpSubmitResult.fromJson(Map<String, dynamic> json) {
    return PvpSubmitResult(
      player: PvpMatchPlayer.fromJson(
        json['player'] as Map<String, dynamic>? ?? const {},
      ),
      match: PvpMatch.fromJson(
        json['match'] as Map<String, dynamic>? ?? const {},
      ),
      validation: PvpSubmitValidation.fromJson(
        json['validation'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PvpActiveMatchException implements Exception {
  const PvpActiveMatchException(this.matchId, [this.message]);

  final int matchId;
  final String? message;

  @override
  String toString() =>
      message ?? 'Active challenge already exists (match $matchId)';
}
