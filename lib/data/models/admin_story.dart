class StoryTextStyle {
  const StoryTextStyle({
    this.fontSize = 34,
    this.fontFamily = 'Default',
    this.textColor = 0xFFFFFFFF,
    this.backgroundStart = 0xFF833AB4,
    this.backgroundEnd = 0xFFF77737,
    this.alignment = 'center',
    this.layers = const [],
    this.imageTransform = const StoryImageTransform(),
    this.poll,
    this.grammarGame,
    this.videoDurationMs = 0,
  });

  final double fontSize;
  final String fontFamily;
  final int textColor;
  final int backgroundStart;
  final int backgroundEnd;
  final String alignment;
  final List<StoryTextLayer> layers;
  final StoryImageTransform imageTransform;
  final StoryPoll? poll;
  final StoryGrammarGame? grammarGame;
  final int videoDurationMs;

  factory StoryTextStyle.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StoryTextStyle();
    final rawLayers = json['layers'];
    return StoryTextStyle(
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 34,
      fontFamily: (json['font_family'] as String?) ?? 'Default',
      textColor: _parseColor(json['text_color'], 0xFFFFFFFF),
      backgroundStart: _parseColor(json['background_start'], 0xFF833AB4),
      backgroundEnd: _parseColor(json['background_end'], 0xFFF77737),
      alignment: (json['alignment'] as String?) ?? 'center',
      layers: rawLayers is List
          ? rawLayers
                .whereType<Map<String, dynamic>>()
                .map(StoryTextLayer.fromJson)
                .toList()
          : const [],
      imageTransform: StoryImageTransform.fromJson(
        (json['image_transform'] ?? json['imageTransform'])
            as Map<String, dynamic>?,
      ),
      poll: StoryPoll.fromJsonOrNull(
        (json['poll'] ?? json['story_poll']) as Map<String, dynamic>?,
      ),
      grammarGame: StoryGrammarGame.fromJsonOrNull(
        (json['grammar_game'] ?? json['grammarGame']) as Map<String, dynamic>?,
      ),
      videoDurationMs:
          ((json['video_duration_ms'] ?? json['videoDurationMs']) as num?)
              ?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'font_size': fontSize,
    'font_family': fontFamily,
    'text_color': textColor,
    'background_start': backgroundStart,
    'background_end': backgroundEnd,
    'alignment': alignment,
    if (layers.isNotEmpty)
      'layers': layers.map((layer) => layer.toJson()).toList(),
    if (!imageTransform.isIdentity) 'image_transform': imageTransform.toJson(),
    if (poll != null) 'poll': poll!.toJson(),
    if (grammarGame != null) 'grammar_game': grammarGame!.toJson(),
    if (videoDurationMs > 0) 'video_duration_ms': videoDurationMs,
  };

  StoryTextStyle copyWith({
    double? fontSize,
    String? fontFamily,
    int? textColor,
    int? backgroundStart,
    int? backgroundEnd,
    String? alignment,
    List<StoryTextLayer>? layers,
    StoryImageTransform? imageTransform,
    StoryPoll? poll,
    StoryGrammarGame? grammarGame,
    int? videoDurationMs,
    bool clearPoll = false,
    bool clearGrammarGame = false,
  }) {
    return StoryTextStyle(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      backgroundStart: backgroundStart ?? this.backgroundStart,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      alignment: alignment ?? this.alignment,
      layers: layers ?? this.layers,
      imageTransform: imageTransform ?? this.imageTransform,
      poll: clearPoll ? null : poll ?? this.poll,
      grammarGame: clearGrammarGame ? null : grammarGame ?? this.grammarGame,
      videoDurationMs: videoDurationMs ?? this.videoDurationMs,
    );
  }

  static int _parseColor(Object? value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.replaceFirst('#', '');
      return int.tryParse(normalized, radix: 16) ?? fallback;
    }
    return fallback;
  }
}

class StoryPoll {
  const StoryPoll({
    required this.id,
    required this.question,
    required this.options,
    this.x = 0.5,
    this.y = 0.58,
    this.scale = 1,
    this.totalVotes = 0,
    this.selectedOptionId,
  });

  final int id;
  final String question;
  final List<StoryPollOption> options;

  /// Normalized center point inside the 9:16 story canvas.
  final double x;
  final double y;
  final double scale;
  final int totalVotes;
  final String? selectedOptionId;

  bool get hasVoted => selectedOptionId != null && selectedOptionId!.isNotEmpty;
  bool get usesCompactTwoOptionLayout => options.length == 2;

  factory StoryPoll.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return StoryPoll(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: (json['question'] as String?) ?? '',
      options: rawOptions is List
          ? rawOptions
                .whereType<Map<String, dynamic>>()
                .map(StoryPollOption.fromJson)
                .toList()
          : const [],
      x: StoryTextLayer._parseDouble(json['x'] ?? json['position_x'], 0.5),
      y: StoryTextLayer._parseDouble(json['y'] ?? json['position_y'], 0.58),
      scale: StoryTextLayer._parseDouble(json['scale'], 1),
      totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      selectedOptionId:
          (json['selected_option_id'] ?? json['selectedOptionId']) as String?,
    );
  }

  static StoryPoll? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final poll = StoryPoll.fromJson(json);
    if (poll.question.trim().isEmpty || poll.options.length < 2) return null;
    return poll;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id > 0) 'id': id,
    'question': question,
    'options': options.map((option) => option.toJson()).toList(),
    'x': x,
    'y': y,
    'scale': scale,
    if (totalVotes > 0) 'total_votes': totalVotes,
    if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
  };

  StoryPoll copyWith({
    int? id,
    String? question,
    List<StoryPollOption>? options,
    double? x,
    double? y,
    double? scale,
    int? totalVotes,
    String? selectedOptionId,
    bool clearSelectedOption = false,
  }) {
    return StoryPoll(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      totalVotes: totalVotes ?? this.totalVotes,
      selectedOptionId: clearSelectedOption
          ? null
          : selectedOptionId ?? this.selectedOptionId,
    );
  }
}

class StoryPollOption {
  const StoryPollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.percent = 0,
  });

  final String id;
  final String text;
  final int voteCount;
  final double percent;

  factory StoryPollOption.fromJson(Map<String, dynamic> json) {
    return StoryPollOption(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      percent: StoryTextLayer._parseDouble(json['percent'], 0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'text': text,
    if (voteCount > 0) 'vote_count': voteCount,
    if (percent > 0) 'percent': percent,
  };

  StoryPollOption copyWith({
    String? id,
    String? text,
    int? voteCount,
    double? percent,
  }) {
    return StoryPollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voteCount: voteCount ?? this.voteCount,
      percent: percent ?? this.percent,
    );
  }
}

class StoryGrammarGame {
  const StoryGrammarGame({
    required this.id,
    required this.questionId,
    required this.topic,
    required this.questionText,
    required this.options,
    this.gameType = 'water_rescue',
    this.selectedOptionId,
    this.isCorrect,
  });

  final int id;
  final int questionId;
  final String topic;
  final String questionText;
  final List<StoryGrammarGameOption> options;
  final String gameType;
  final String? selectedOptionId;
  final bool? isCorrect;

  bool get hasAnswered =>
      selectedOptionId != null && selectedOptionId!.trim().isNotEmpty;

  factory StoryGrammarGame.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return StoryGrammarGame(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionId: (json['question_id'] as num?)?.toInt() ?? 0,
      topic: (json['topic'] as String?) ?? '',
      questionText:
          (json['question_text'] ?? json['question']) as String? ?? '',
      options: rawOptions is List
          ? rawOptions
                .whereType<Map<String, dynamic>>()
                .map(StoryGrammarGameOption.fromJson)
                .toList()
          : const [],
      gameType: (json['game_type'] as String?) ?? 'water_rescue',
      selectedOptionId:
          (json['selected_option_id'] ?? json['selectedOptionId']) as String?,
      isCorrect: json['is_correct'] == null
          ? null
          : json['is_correct'] == true || json['is_correct'] == 1,
    );
  }

  static StoryGrammarGame? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final game = StoryGrammarGame.fromJson(json);
    if (game.questionText.trim().isEmpty || game.options.length < 2) {
      return null;
    }
    return game;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id > 0) 'id': id,
    if (questionId > 0) 'question_id': questionId,
    'topic': topic,
    'question_text': questionText,
    'options': options.map((option) => option.toJson()).toList(),
    'game_type': gameType,
    if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
    if (isCorrect != null) 'is_correct': isCorrect,
  };

  StoryGrammarGame copyWith({
    int? id,
    int? questionId,
    String? topic,
    String? questionText,
    List<StoryGrammarGameOption>? options,
    String? gameType,
    String? selectedOptionId,
    bool? isCorrect,
    bool clearAttempt = false,
  }) {
    return StoryGrammarGame(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      topic: topic ?? this.topic,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      gameType: gameType ?? this.gameType,
      selectedOptionId: clearAttempt
          ? null
          : selectedOptionId ?? this.selectedOptionId,
      isCorrect: clearAttempt ? null : isCorrect ?? this.isCorrect,
    );
  }
}

class StoryGrammarGameOption {
  const StoryGrammarGameOption({required this.id, required this.text});

  final String id;
  final String text;

  factory StoryGrammarGameOption.fromJson(Map<String, dynamic> json) {
    return StoryGrammarGameOption(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'text': text};
}

class StoryTextLayer {
  const StoryTextLayer({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.scale = 1,
    this.rotation = 0,
    this.fontSize = 34,
    this.fontFamily = 'Default',
    this.textColor = 0xFFFFFFFF,
    this.alignment = 'center',
    this.lineHeight = 1.25,
  });

  final String id;
  final String text;

  /// Normalized center point inside the 9:16 story canvas.
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double fontSize;
  final String fontFamily;
  final int textColor;
  final String alignment;
  final double lineHeight;

  factory StoryTextLayer.fromJson(Map<String, dynamic> json) {
    return StoryTextLayer(
      id: (json['id'] as String?) ?? '${json['x']}_${json['y']}',
      text: (json['text'] as String?) ?? '',
      x: _parseDouble(json['x'], 0.5),
      y: _parseDouble(json['y'], 0.5),
      scale: _parseDouble(json['scale'], 1),
      rotation: _parseDouble(json['rotation'], 0),
      fontSize: _parseDouble(json['font_size'] ?? json['fontSize'], 34),
      fontFamily:
          (json['font_family'] as String?) ??
          (json['fontFamily'] as String?) ??
          'Default',
      textColor: StoryTextStyle._parseColor(
        json['text_color'] ?? json['textColor'],
        0xFFFFFFFF,
      ),
      alignment: (json['alignment'] as String?) ?? 'center',
      lineHeight: _parseDouble(json['line_height'] ?? json['lineHeight'], 1.25),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'text': text,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
    'font_size': fontSize,
    'font_family': fontFamily,
    'text_color': textColor,
    'alignment': alignment,
    'line_height': lineHeight,
  };

  StoryTextLayer copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    double? fontSize,
    String? fontFamily,
    int? textColor,
    String? alignment,
    double? lineHeight,
  }) {
    return StoryTextLayer(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      alignment: alignment ?? this.alignment,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  static double _parseDouble(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}

class StoryImageTransform {
  const StoryImageTransform({
    this.x = 0,
    this.y = 0,
    this.scale = 1,
    this.aspectRatio = 0,
  });

  /// Normalized offset by canvas size.
  final double x;
  final double y;
  final double scale;
  final double aspectRatio;

  bool get isIdentity => x == 0 && y == 0 && scale == 1 && aspectRatio <= 0;

  factory StoryImageTransform.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StoryImageTransform();
    return StoryImageTransform(
      x: StoryTextLayer._parseDouble(json['x'], 0),
      y: StoryTextLayer._parseDouble(json['y'], 0),
      scale: StoryTextLayer._parseDouble(json['scale'], 1),
      aspectRatio: StoryTextLayer._parseDouble(
        json['aspect_ratio'] ?? json['aspectRatio'],
        0,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'scale': scale,
    if (aspectRatio > 0) 'aspect_ratio': aspectRatio,
  };

  StoryImageTransform copyWith({
    double? x,
    double? y,
    double? scale,
    double? aspectRatio,
  }) {
    return StoryImageTransform(
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }
}

enum StoryVisibilityDuration {
  hours24(24, '24'),
  hours48(48, '48'),
  week1(168, '1W'),
  month1(720, '1M');

  const StoryVisibilityDuration(this.hours, this.label);

  final int hours;
  final String label;

  StoryVisibilityDuration get next {
    const values = StoryVisibilityDuration.values;
    return values[(index + 1) % values.length];
  }

  static StoryVisibilityDuration fromHours(int hours) {
    for (final option in StoryVisibilityDuration.values) {
      if (option.hours == hours) return option;
    }
    return StoryVisibilityDuration.hours24;
  }
}

class StoryItem {
  const StoryItem({
    required this.id,
    required this.adminUserId,
    required this.adminName,
    required this.adminAvatar,
    required this.contentType,
    required this.createdAt,
    required this.seen,
    required this.liked,
    required this.viewCount,
    required this.likeCount,
    this.imagePath,
    this.textContent,
    this.textStyle = const StoryTextStyle(),
    this.targetMode = 'all',
    this.visibilityHours = 24,
    this.viewedAt,
  });

  final int id;
  final int adminUserId;
  final String adminName;
  final String adminAvatar;
  final String contentType;
  final String? imagePath;
  final String? textContent;
  final StoryTextStyle textStyle;
  final String targetMode;
  final int visibilityHours;
  final String createdAt;
  final String? viewedAt;
  final bool seen;
  final bool liked;
  final int viewCount;
  final int likeCount;

  bool get isImage => contentType.trim().toLowerCase() == 'image';
  bool get isText => contentType.trim().toLowerCase() == 'text';
  bool get isVideo {
    if (contentType.trim().toLowerCase() == 'video') return true;
    return looksLikeStoryVideoPath(imagePath);
  }

  bool get hasGrammarGame => textStyle.grammarGame != null;

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: (json['id'] as num).toInt(),
      adminUserId: (json['admin_user_id'] as num?)?.toInt() ?? 0,
      adminName: (json['admin_name'] as String?) ?? '',
      adminAvatar: (json['admin_avatar'] as String?) ?? 'm1',
      contentType: ((json['content_type'] as String?) ?? 'text')
          .trim()
          .toLowerCase(),
      imagePath: (json['image_path'] as String?)?.trim(),
      textContent: json['text_content'] as String?,
      textStyle: StoryTextStyle.fromJson(
        _mergeStoryExtrasIntoTextStyleJson(json),
      ),
      targetMode: (json['target_mode'] as String?) ?? 'all',
      visibilityHours: (json['visibility_hours'] as num?)?.toInt() ?? 24,
      createdAt: (json['created_at'] as String?) ?? '',
      viewedAt: json['viewed_at'] as String?,
      seen: json['seen'] == true || json['seen'] == 1,
      liked: json['liked'] == true || json['liked'] == 1,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    );
  }

  StoryItem copyWith({
    bool? liked,
    bool? seen,
    int? likeCount,
    int? viewCount,
    String? viewedAt,
    StoryTextStyle? textStyle,
    int? visibilityHours,
  }) {
    return StoryItem(
      id: id,
      adminUserId: adminUserId,
      adminName: adminName,
      adminAvatar: adminAvatar,
      contentType: contentType,
      imagePath: imagePath,
      textContent: textContent,
      textStyle: textStyle ?? this.textStyle,
      targetMode: targetMode,
      visibilityHours: visibilityHours ?? this.visibilityHours,
      createdAt: createdAt,
      viewedAt: viewedAt ?? this.viewedAt,
      seen: seen ?? this.seen,
      liked: liked ?? this.liked,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}

Map<String, dynamic>? _mergeStoryExtrasIntoTextStyleJson(
  Map<String, dynamic> json,
) {
  final rawStyle = json['text_style'];
  final style = rawStyle is Map<String, dynamic>
      ? Map<String, dynamic>.from(rawStyle)
      : <String, dynamic>{};
  final rawPoll = json['poll'];
  if (rawPoll is Map<String, dynamic> && style['poll'] == null) {
    style['poll'] = rawPoll;
  }
  final rawGrammarGame = json['grammar_game'];
  if (rawGrammarGame is Map<String, dynamic> && style['grammar_game'] == null) {
    style['grammar_game'] = rawGrammarGame;
  }
  return style.isEmpty ? null : style;
}

bool looksLikeStoryVideoPath(String? path) {
  final lower = (path ?? '').trim().toLowerCase();
  if (lower.isEmpty) return false;
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.3gp') ||
      lower.endsWith('.3gpp');
}

class StoryAudienceUser {
  const StoryAudienceUser({
    required this.id,
    required this.email,
    required this.happenedAt,
    this.displayName,
    this.avatar = 'm1',
    this.pollOptionId,
    this.pollOptionText,
  });

  final int id;
  final String email;
  final String? displayName;
  final String avatar;
  final String happenedAt;
  final String? pollOptionId;
  final String? pollOptionText;

  String get displayLabel {
    final name = displayName?.trim() ?? '';
    return name.isNotEmpty ? name : email;
  }

  factory StoryAudienceUser.fromJson(Map<String, dynamic> json) {
    return StoryAudienceUser(
      id: (json['id'] as num).toInt(),
      email: (json['email'] as String?) ?? '',
      displayName: json['display_name'] as String?,
      avatar: (json['avatar'] as String?)?.trim().isNotEmpty == true
          ? (json['avatar'] as String).trim()
          : 'm1',
      happenedAt: (json['happened_at'] as String?) ?? '',
      pollOptionId: json['poll_option_id'] as String?,
      pollOptionText: json['poll_option_text'] as String?,
    );
  }
}

class StoryAudienceSummary {
  const StoryAudienceSummary({
    required this.storyId,
    required this.viewCount,
    required this.likeCount,
    required this.viewers,
    required this.likers,
    this.poll,
  });

  final int storyId;
  final int viewCount;
  final int likeCount;
  final List<StoryAudienceUser> viewers;
  final List<StoryAudienceUser> likers;
  final StoryPoll? poll;

  factory StoryAudienceSummary.fromJson(Map<String, dynamic> json) {
    final viewers = json['viewers'] as List<dynamic>? ?? const [];
    final likers = json['likers'] as List<dynamic>? ?? const [];
    return StoryAudienceSummary(
      storyId: (json['story_id'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? viewers.length,
      likeCount: (json['like_count'] as num?)?.toInt() ?? likers.length,
      viewers: viewers
          .map((e) => StoryAudienceUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      likers: likers
          .map((e) => StoryAudienceUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      poll: StoryPoll.fromJsonOrNull(json['poll'] as Map<String, dynamic>?),
    );
  }
}
