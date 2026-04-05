import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../srs/srs_provider.dart';

// ─── Keys ─────────────────────────────────────────────────────────────────────

const _kStudyDays     = 'study_days_v1';       // List<String> of 'yyyy-MM-dd'
const _kQuizSessions  = 'quiz_sessions_v1';    // List<{date, score, total}>
const _kWordsReviewed = 'words_reviewed_v1';   // Map<date, count>

// ─── Models ───────────────────────────────────────────────────────────────────

class DayActivity {
  const DayActivity({
    required this.date,
    this.wordsReviewed = 0,
    this.quizCorrect = 0,
    this.quizTotal = 0,
  });

  final DateTime date;
  final int wordsReviewed;
  final int quizCorrect;
  final int quizTotal;

  bool get hasActivity => wordsReviewed > 0 || quizTotal > 0;

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class StatsState {
  const StatsState({
    this.studyDays = const {},
    this.wordsReviewedPerDay = const {},
    this.quizSessionsPerDay = const {},
  });

  /// Set of 'yyyy-MM-dd' strings where user studied
  final Set<String> studyDays;

  /// date string → words reviewed count
  final Map<String, int> wordsReviewedPerDay;

  /// date string → {correct, total}
  final Map<String, Map<String, int>> quizSessionsPerDay;

  // ── Streak ──────────────────────────────────────────────────────────────────

  int get currentStreak {
    if (studyDays.isEmpty) return 0;
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    // streak counts only if studied today or yesterday
    if (!studyDays.contains(today) && !studyDays.contains(yesterday)) return 0;

    int streak = 0;
    var day = studyDays.contains(today)
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    while (studyDays.contains(_dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    if (studyDays.isEmpty) return 0;
    final sorted = studyDays.toList()..sort();
    int longest = 1;
    int current = 1;

    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final curr = DateTime.parse(sorted[i]);
      final diff = curr.difference(prev).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  int get totalStudyDays => studyDays.length;

  // ── Weekly activity (last 7 days) ────────────────────────────────────────────

  List<DayActivity> get last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final key = _dateKey(date);
      return DayActivity(
        date: date,
        wordsReviewed: wordsReviewedPerDay[key] ?? 0,
        quizCorrect: quizSessionsPerDay[key]?['correct'] ?? 0,
        quizTotal: quizSessionsPerDay[key]?['total'] ?? 0,
      );
    });
  }

  int get totalWordsReviewed =>
      wordsReviewedPerDay.values.fold(0, (a, b) => a + b);

  int get totalQuizAnswered =>
      quizSessionsPerDay.values.fold(0, (a, b) => a + (b['total'] ?? 0));

  int get totalQuizCorrect =>
      quizSessionsPerDay.values.fold(0, (a, b) => a + (b['correct'] ?? 0));

  double get quizAccuracy {
    if (totalQuizAnswered == 0) return 0;
    return totalQuizCorrect / totalQuizAnswered;
  }

  // ── Today ────────────────────────────────────────────────────────────────────

  bool get studiedToday => studyDays.contains(_dateKey(DateTime.now()));

  StatsState copyWith({
    Set<String>? studyDays,
    Map<String, int>? wordsReviewedPerDay,
    Map<String, Map<String, int>>? quizSessionsPerDay,
  }) =>
      StatsState(
        studyDays: studyDays ?? this.studyDays,
        wordsReviewedPerDay: wordsReviewedPerDay ?? this.wordsReviewedPerDay,
        quizSessionsPerDay: quizSessionsPerDay ?? this.quizSessionsPerDay,
      );
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ─── Notifier ─────────────────────────────────────────────────────────────────

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier() : super(const StatsState()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    final daysRaw = p.getString(_kStudyDays);
    final Set<String> days = daysRaw != null
        ? Set<String>.from(jsonDecode(daysRaw) as List)
        : {};

    final reviewRaw = p.getString(_kWordsReviewed);
    final Map<String, int> reviewed = reviewRaw != null
        ? Map<String, int>.from(jsonDecode(reviewRaw) as Map)
        : {};

    final quizRaw = p.getString(_kQuizSessions);
    final Map<String, Map<String, int>> quiz = {};
    if (quizRaw != null) {
      final decoded = jsonDecode(quizRaw) as Map;
      decoded.forEach((k, v) {
        quiz[k as String] = Map<String, int>.from(v as Map);
      });
    }

    state = StatsState(
      studyDays: days,
      wordsReviewedPerDay: reviewed,
      quizSessionsPerDay: quiz,
    );
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStudyDays, jsonEncode(state.studyDays.toList()));
    await p.setString(_kWordsReviewed, jsonEncode(state.wordsReviewedPerDay));
    await p.setString(_kQuizSessions, jsonEncode(state.quizSessionsPerDay));
  }

  /// Call when user reviews a word via SRS
  Future<void> logWordReview() async {
    final today = _dateKey(DateTime.now());
    final updated = Map<String, int>.from(state.wordsReviewedPerDay);
    updated[today] = (updated[today] ?? 0) + 1;

    state = state.copyWith(
      studyDays: {...state.studyDays, today},
      wordsReviewedPerDay: updated,
    );
    await _save();
  }

  /// Call when user finishes a quiz question
  Future<void> logQuizAnswer({required bool correct}) async {
    final today = _dateKey(DateTime.now());
    final updated = Map<String, Map<String, int>>.from(state.quizSessionsPerDay);
    final day = Map<String, int>.from(updated[today] ?? {});
    day['total'] = (day['total'] ?? 0) + 1;
    if (correct) day['correct'] = (day['correct'] ?? 0) + 1;
    updated[today] = day;

    state = state.copyWith(
      studyDays: {...state.studyDays, today},
      quizSessionsPerDay: updated,
    );
    await _save();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
  (_) => StatsNotifier(),
);

// ─── SRS Word Mastery (derived from srsProvider) ──────────────────────────────

class WordMastery {
  const WordMastery({
    required this.mastered,
    required this.learning,
    required this.seen,
  });

  final int mastered;  // interval >= 21
  final int learning;  // interval 2-20
  final int seen;      // interval == 1, repetitions > 0

  int get total => mastered + learning + seen;
}

final wordMasteryProvider = Provider<WordMastery>((ref) {
  final cards = ref.watch(srsProvider).cards.values.toList();
  int mastered = 0, learning = 0, seen = 0;
  for (final c in cards) {
    if (c.interval >= 21) {
      mastered++;
    } else if (c.interval >= 2) {
      learning++;
    } else {
      seen++;
    }
  }
  return WordMastery(mastered: mastered, learning: learning, seen: seen);
});
