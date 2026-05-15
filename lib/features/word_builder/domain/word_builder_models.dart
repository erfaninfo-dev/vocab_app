import 'package:flutter/foundation.dart';

enum WordBuilderDifficulty { beginner, intermediate, advanced }

@immutable
class WordBuilderTargetWord {
  const WordBuilderTargetWord({
    required this.word,
    required this.translationFa,
    this.translationKur = '',
    this.pronunciation = '',
    required this.exampleEn,
    this.meaningEn = '',
    this.type = '',
    this.exampleFa = '',
    this.exampleKur = '',
    this.rowId = 0,
    this.bookId = '',
    this.unit = 0,
    this.section,
  });

  final String word;
  final String translationFa;
  final String translationKur;
  final String pronunciation;
  final String exampleEn;
  final String meaningEn;
  final String type;
  final String exampleFa;
  final String exampleKur;
  final int rowId;
  final String bookId;
  final int unit;
  final int? section;

  String meaningForLang({required bool preferKur}) {
    if (preferKur && translationKur.trim().isNotEmpty) {
      return translationKur.trim();
    }
    if (translationFa.trim().isNotEmpty) return translationFa.trim();
    return translationKur.trim();
  }
}

@immutable
class WordBuilderLevel {
  const WordBuilderLevel({
    required this.levelId,
    required this.difficulty,
    required this.category,
    required this.letters,
    required this.targetWords,
  });

  final int levelId;
  final WordBuilderDifficulty difficulty;
  final String category;
  final List<String> letters;
  final List<WordBuilderTargetWord> targetWords;

  int get targetCount => targetWords.length;

  int xpPerCorrectWord() {
    switch (difficulty) {
      case WordBuilderDifficulty.beginner:
        return 12;
      case WordBuilderDifficulty.intermediate:
        return 18;
      case WordBuilderDifficulty.advanced:
        return 24;
    }
  }

  int xpLevelCompleteBonus() {
    switch (difficulty) {
      case WordBuilderDifficulty.beginner:
        return 30;
      case WordBuilderDifficulty.intermediate:
        return 45;
      case WordBuilderDifficulty.advanced:
        return 60;
    }
  }
}

@immutable
class LetterInstance {
  const LetterInstance({required this.id, required this.char});

  final int id;
  final String char;
}

@immutable
class WordBuilderLevelProgress {
  const WordBuilderLevelProgress({
    required this.completed,
    required this.attempts,
    required this.correctSubmissions,
    required this.solvedWordsLower,
  });

  final bool completed;
  final int attempts;
  final int correctSubmissions;
  final Set<String> solvedWordsLower;

  double get accuracy =>
      attempts == 0 ? 1.0 : correctSubmissions / attempts;

  Map<String, Object?> toJson() => {
        'completed': completed,
        'attempts': attempts,
        'correctSubmissions': correctSubmissions,
        'solved': solvedWordsLower.toList(),
      };

  static WordBuilderLevelProgress fromJson(Map<String, Object?>? map) {
    if (map == null) {
      return const WordBuilderLevelProgress(
        completed: false,
        attempts: 0,
        correctSubmissions: 0,
        solvedWordsLower: {},
      );
    }
    final solved = <String>{};
    final raw = map['solved'];
    if (raw is List) {
      for (final e in raw) {
        if (e is String && e.isNotEmpty) solved.add(e.toLowerCase());
      }
    }
    return WordBuilderLevelProgress(
      completed: map['completed'] == true,
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      correctSubmissions:
          (map['correctSubmissions'] as num?)?.toInt() ?? 0,
      solvedWordsLower: solved,
    );
  }

  WordBuilderLevelProgress copyWith({
    bool? completed,
    int? attempts,
    int? correctSubmissions,
    Set<String>? solvedWordsLower,
  }) {
    return WordBuilderLevelProgress(
      completed: completed ?? this.completed,
      attempts: attempts ?? this.attempts,
      correctSubmissions:
          correctSubmissions ?? this.correctSubmissions,
      solvedWordsLower: solvedWordsLower ?? this.solvedWordsLower,
    );
  }
}

@immutable
class WordBuilderPersistedProgress {
  const WordBuilderPersistedProgress({
    required this.totalXp,
    required this.globalAttempts,
    required this.globalCorrect,
    required this.perLevel,
  });

  final int totalXp;
  final int globalAttempts;
  final int globalCorrect;
  final Map<int, WordBuilderLevelProgress> perLevel;

  double get globalAccuracy =>
      globalAttempts == 0 ? 1.0 : globalCorrect / globalAttempts;

  Map<String, Object?> toJson() => {
        'v': 1,
        'totalXp': totalXp,
        'globalAttempts': globalAttempts,
        'globalCorrect': globalCorrect,
        'perLevel': perLevel.map(
          (k, v) => MapEntry('$k', v.toJson()),
        ),
      };

  static WordBuilderPersistedProgress empty() =>
      const WordBuilderPersistedProgress(
        totalXp: 0,
        globalAttempts: 0,
        globalCorrect: 0,
        perLevel: {},
      );

  static WordBuilderPersistedProgress fromJson(Map<String, Object?> map) {
    final per = <int, WordBuilderLevelProgress>{};
    final rawLevels = map['perLevel'];
    if (rawLevels is Map) {
      for (final e in rawLevels.entries) {
        final id = int.tryParse(e.key.toString());
        if (id == null) continue;
        final v = e.value;
        if (v is Map<String, Object?>) {
          per[id] = WordBuilderLevelProgress.fromJson(v);
        } else if (v is Map) {
          per[id] = WordBuilderLevelProgress.fromJson(
            v.map((k, val) => MapEntry(k.toString(), val)),
          );
        }
      }
    }
    return WordBuilderPersistedProgress(
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      globalAttempts: (map['globalAttempts'] as num?)?.toInt() ?? 0,
      globalCorrect: (map['globalCorrect'] as num?)?.toInt() ?? 0,
      perLevel: per,
    );
  }

  WordBuilderPersistedProgress copyWith({
    int? totalXp,
    int? globalAttempts,
    int? globalCorrect,
    Map<int, WordBuilderLevelProgress>? perLevel,
  }) {
    return WordBuilderPersistedProgress(
      totalXp: totalXp ?? this.totalXp,
      globalAttempts: globalAttempts ?? this.globalAttempts,
      globalCorrect: globalCorrect ?? this.globalCorrect,
      perLevel: perLevel ?? this.perLevel,
    );
  }
}
