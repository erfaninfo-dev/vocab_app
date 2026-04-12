import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/book_model.dart';
import '../data/models/grammar_question.dart';
import '../data/models/grammar_topic_summary.dart';
import '../data/models/grammar_result.dart';
import '../data/models/grammar_result_detail.dart';
import '../data/models/unit_model.dart';
import '../data/models/vocab_entry.dart';
import '../data/models/vocab_quiz_result.dart';
import '../data/models/teacher_student.dart';
import '../data/models/teacher_message.dart';
import '../core/auth/auth_provider.dart';
import '../data/services/api_service.dart';

// ─── Shared service instance (includes auth bearer when logged in) ───────────

final apiServiceProvider = Provider<ApiService>((ref) {
  final auth = ref.watch(authProvider);
  final token = auth.valueOrNull?.token;
  return ApiService(authToken: token);
});

// ─── Books ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /books.php

final apiBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.read(apiServiceProvider).fetchBooks(scope: 'public');
});

// ─── Units ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /units.php?book_id={bookId}

final apiUnitsProvider = FutureProvider.family<List<UnitInfo>, int>((
  ref,
  bookId,
) {
  return ref.read(apiServiceProvider).fetchUnits(bookId);
});

// ─── Sections ─────────────────────────────────────────────────────────────────
// Corresponds to: GET /sections.php?book_id={bookId}&unit={unit}
// Returns [] when the unit has no sections.

typedef BookUnit = ({int bookId, int unit});

final apiSectionsProvider = FutureProvider.family<List<int>, BookUnit>((
  ref,
  arg,
) {
  return ref.read(apiServiceProvider).fetchSections(arg.bookId, arg.unit);
});

// ─── Words ────────────────────────────────────────────────────────────────────
// Corresponds to:
//   GET /words.php?book_id={bookId}&unit={unit}&section={section}  (with section)
//   GET /words.php?book_id={bookId}&unit={unit}                    (no sections)

typedef BookUnitSection = ({int bookId, int unit, int? section});

final apiWordsProvider =
    FutureProvider.family<List<VocabEntry>, BookUnitSection>((ref, arg) {
      return ref
          .read(apiServiceProvider)
          .fetchWords(arg.bookId, arg.unit, section: arg.section);
    });

// ─── All words for a book (Favorites screen) ─────────────────────────────────
// Corresponds to: GET /words.php?book_id={bookId}

final apiAllWordsForBookProvider = FutureProvider.family<List<VocabEntry>, int>(
  (ref, bookId) {
    return ref.read(apiServiceProvider).fetchAllWordsForBook(bookId);
  },
);

// ─── Grammar (DB column `content` = topic name) ─────────────────────────────

final apiGrammarTopicsProvider = FutureProvider<List<GrammarTopicSummary>>((
  ref,
) {
  return ref.read(apiServiceProvider).fetchGrammarTopics();
});

final apiGrammarQuestionsProvider =
    FutureProvider.family<List<GrammarQuestion>, String>((ref, topic) {
      return ref.read(apiServiceProvider).fetchGrammarQuestions(topic);
    });

/// Stable cache key for one or more grammar topic names (sorted, joined).
String grammarTopicsCacheKey(List<String> topics) {
  final copy = topics.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
    ..sort();
  return copy.join('\x1E');
}

/// Upper bound on how many questions we load in one grammar session (shuffle then take).
const int kGrammarQuizSessionSize = 100;

/// Default count when opening `/grammar/practice` without `count=`.
const int kGrammarQuizDefaultQuestionCount = 15;

/// Floor for question count: at least this many, or [topicCount] if higher (multi-topic).
const int kGrammarQuizMinBaseQuestions = 5;

/// At least [kGrammarQuizMinBaseQuestions], or [topicCount] when more topics are selected.
int grammarQuizMinQuestionsForTopics(int topicCount) {
  if (topicCount <= 0) return 1;
  return max(kGrammarQuizMinBaseQuestions, topicCount);
}

/// [apiGrammarQuizSessionProvider] arguments: topics key + desired session length.
typedef GrammarQuizSessionParams = ({String topicsKey, int questionCount});

/// Sort mode for grammar result screens (UI only; lists are fetched date-desc then reordered).
enum GrammarResultsListSort { newest, mostPractice }

final grammarResultsListSortProvider =
    StateProvider<GrammarResultsListSort>(
  (ref) => GrammarResultsListSort.newest,
);

/// GET /grammar_results_my.php (requires auth)
final myGrammarResultsProvider = FutureProvider<List<GrammarResult>>((ref) {
  return ref
      .read(apiServiceProvider)
      .fetchMyGrammarResults(sort: 'date', order: 'desc');
});

/// GET /grammar_results_public.php (no auth)
final publicGrammarResultsProvider = FutureProvider<List<GrammarResult>>((ref) {
  return ref
      .read(apiServiceProvider)
      .fetchPublicGrammarResults(sort: 'date', order: 'desc');
});

/// GET /grammar_result_detail.php?id= (auth). For review screen.
final grammarResultDetailProvider =
    FutureProvider.family<GrammarResultDetail, int>((ref, id) {
      return ref.read(apiServiceProvider).fetchGrammarResultDetail(id);
    });

/// GET /vocab_quiz_results_my.php (requires auth). Empty when logged out.
final myVocabQuizResultsProvider =
    FutureProvider<List<VocabQuizResultSummary>>((ref) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) return [];
  return ref.read(apiServiceProvider).fetchMyVocabQuizResults();
});

/// GET /vocab_quiz_result_detail.php?id= (auth).
final vocabQuizResultDetailProvider =
    FutureProvider.family<VocabQuizResultDetail, int>((ref, id) {
      return ref.read(apiServiceProvider).fetchVocabQuizResultDetail(id);
    });

/// GET /teacher_students.php — requires teacher role on server.
final teacherStudentsProvider =
    FutureProvider<List<TeacherStudentSummary>>((ref) async {
      final session = ref.watch(authProvider).valueOrNull;
      if (session == null || !session.user.isTeacher) {
        return [];
      }
      return ref.read(apiServiceProvider).fetchTeacherStudents();
    });

/// Same as [teacherStudentsProvider] but inbox sort (unread first, then newest activity).
final teacherInboxStudentsProvider =
    FutureProvider<List<TeacherStudentSummary>>((ref) async {
      final session = ref.watch(authProvider).valueOrNull;
      if (session == null || !session.user.isTeacher) {
        return [];
      }
      return ref.read(apiServiceProvider).fetchTeacherStudents(inbox: true);
    });

/// Vocabulary quiz summaries for one student (teacher panel).
final teacherStudentVocabResultsProvider =
    FutureProvider.family<List<VocabQuizResultSummary>, int>((ref, studentId) {
      return ref
          .read(apiServiceProvider)
          .fetchTeacherStudentVocabResults(studentId);
    });

/// Grammar results for one student (teacher panel).
final teacherStudentGrammarResultsProvider =
    FutureProvider.family<List<GrammarResult>, int>((ref, studentId) {
      return ref
          .read(apiServiceProvider)
          .fetchTeacherStudentGrammarResults(studentId);
    });

/// Class session list (teacher panel — per-student).
final teacherStudentSessionsProvider =
    FutureProvider.family<TeacherSessionInfo, int>((ref, studentId) {
      return ref.read(apiServiceProvider).fetchTeacherStudentSessions(studentId);
    });

/// Student: read-only class sessions recorded by their teacher ([my_class_sessions.php]).
final myClassSessionsProvider = FutureProvider<TeacherSessionInfo>((ref) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null ||
      session.user.isTeacher ||
      session.user.teacherUserId == null) {
    return const TeacherSessionInfo(sessionCount: 0, sessions: []);
  }
  return ref.read(apiServiceProvider).fetchMyClassSessions();
});

/// Preview row for You hub (student + assigned teacher). Empty when not applicable.
final teacherMessagesPreviewProvider =
    FutureProvider<TeacherMessagesPreview>((ref) async {
      final session = ref.watch(authProvider).valueOrNull;
      if (session == null || session.user.isTeacher) {
        return TeacherMessagesPreview.empty();
      }
      return ref.read(apiServiceProvider).fetchTeacherMessagesPreview();
    });

/// Home FAB badge: teachers = distinct students with unread; students = unread msgs from teacher.
final teacherMessagesUnreadFabProvider =
    FutureProvider<int>((ref) async {
      final session = ref.watch(authProvider).valueOrNull;
      if (session == null) return 0;
      final u = session.user;
      if (!u.isTeacher && u.teacherUserId == null) return 0;
      final s = await ref.read(apiServiceProvider).fetchTeacherMessagesUnreadSummary();
      return s.badgeForUser(userIsTeacher: u.isTeacher);
    });

/// Grammar results for charts (date desc, newest first). Empty when logged out.
final grammarStatsChartResultsProvider = FutureProvider<List<GrammarResult>>((
  ref,
) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) return [];
  return ref
      .read(apiServiceProvider)
      .fetchMyGrammarResults(sort: 'date', order: 'desc');
});

/// Fetches questions for all topics in [params.topicsKey], merges, shuffles, returns up to
/// `min(params.questionCount, merged.length, [kGrammarQuizSessionSize])`.
/// One topic: random subset of that bank. Several topics: random mix from all banks (fair variety).
final apiGrammarQuizSessionProvider =
    FutureProvider.family<List<GrammarQuestion>, GrammarQuizSessionParams>((
      ref,
      params,
    ) async {
      final topicsKey = params.topicsKey;
      if (topicsKey.isEmpty) return [];
      final topics = topicsKey
          .split('\x1E')
          .where((s) => s.isNotEmpty)
          .toList();
      if (topics.isEmpty) return [];
      final floor = grammarQuizMinQuestionsForTopics(topics.length);
      final want = max(
        floor,
        params.questionCount,
      ).clamp(1, kGrammarQuizSessionSize);
      final svc = ref.read(apiServiceProvider);
      final lists = await Future.wait(
        topics.map((t) => svc.fetchGrammarQuestions(t)),
      );
      final merged = <GrammarQuestion>[];
      for (final list in lists) {
        merged.addAll(list);
      }
      if (merged.isEmpty) return [];
      merged.shuffle(Random());
      final poolCap = min(merged.length, kGrammarQuizSessionSize);
      final take = min(want, poolCap);
      return merged.sublist(0, take);
    });

// ─── New Providers for Search ───────────────────────────────────────────────

// Search query provider
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

// Books list with search
final apiSearchBooksProvider = FutureProvider<List<Book>>((ref) {
  final query = ref.watch(bookSearchQueryProvider); // Watch the query state

  // If the query is empty, fetch all books (like before)
  // Otherwise, search using the query
  if (query.isEmpty) {
    return ref.read(apiServiceProvider).fetchBooks(scope: 'public');
  } else {
    return ref.read(apiServiceProvider).searchBooks(query, scope: 'public');
  }
});
