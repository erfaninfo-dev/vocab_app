import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/book_model.dart';
import '../data/models/game_word_category.dart';
import '../data/models/grammar_book.dart';
import '../data/models/grammar_question.dart';
import '../data/models/grammar_topic_summary.dart';
import '../data/models/grammar_unit.dart';
import '../data/models/grammar_unit_text.dart';
import '../data/models/class_schedule_slot.dart';
import '../data/models/schedule_attendance.dart';
import '../data/models/teacher_upcoming_slot.dart';
import '../data/models/temporary_class_schedule_slot.dart';
import '../features/teacher/teacher_week_upcoming.dart';
import '../data/models/grammar_result.dart';
import '../data/models/grammar_result_detail.dart';
import '../data/models/league.dart';
import '../data/models/unit_model.dart';
import '../data/models/section_info.dart';
import '../data/models/unit_sample.dart';
import '../data/models/vocab_entry.dart';
import '../data/models/vocab_quiz_result.dart';
import '../data/models/teacher_student.dart';
import '../data/models/teacher_message.dart';
import '../core/auth/auth_provider.dart';
import '../data/services/api_service.dart';
import 'api_remote_data_epoch.dart';

// ─── Shared service instance (includes auth bearer when logged in) ───────────

final apiServiceProvider = Provider<ApiService>((ref) {
  final auth = ref.watch(authProvider);
  final token = auth.valueOrNull?.token;
  return ApiService(authToken: token);
});

// ─── Books ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /books.php

final apiBooksProvider = FutureProvider<List<Book>>((ref) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchBooks(scope: 'public');
});

// ─── Word Builder theme categories ────────────────────────────────────────────
// Corresponds to: GET /game_word_categories.php

final apiGameWordCategoriesProvider = FutureProvider<List<GameWordCategory>>((
  ref,
) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchGameWordCategories();
});

// ─── Units ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /units.php?book_id={bookId}

final apiUnitsProvider = FutureProvider.family<List<UnitInfo>, int>((
  ref,
  bookId,
) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchUnits(bookId);
});

// ─── Sections ─────────────────────────────────────────────────────────────────
// Corresponds to: GET /sections.php?book_id={bookId}&unit={unit}
// Returns [] when the unit has no sections.

typedef BookUnit = ({int bookId, int unit});

final apiSectionsProvider = FutureProvider.family<List<SectionInfo>, BookUnit>((
  ref,
  arg,
) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchSections(arg.bookId, arg.unit);
});

// ─── Unit Samples (text samples per unit / optional section filter) ─────────
// Corresponds to: GET /unit_samples.php?book_id={bookId}&unit={unit}[&section=]

typedef BookUnitSamples = ({int bookId, int unit, int? section});

final apiUnitSamplesProvider =
    FutureProvider.family<List<UnitSample>, BookUnitSamples>((ref, arg) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref
          .read(apiServiceProvider)
          .fetchUnitSamples(arg.bookId, arg.unit, section: arg.section);
    });

// ─── Words ────────────────────────────────────────────────────────────────────
// Corresponds to:
//   GET /words.php?book_id={bookId}&unit={unit}&section={section}  (with section)
//   GET /words.php?book_id={bookId}&unit={unit}                    (no sections)

typedef BookUnitSection = ({int bookId, int unit, int? section});

final apiWordsProvider =
    FutureProvider.family<List<VocabEntry>, BookUnitSection>((ref, arg) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref
          .read(apiServiceProvider)
          .fetchWords(arg.bookId, arg.unit, section: arg.section);
    });

// ─── All words for a book (Favorites screen) ─────────────────────────────────
// Corresponds to: GET /words.php?book_id={bookId}

final apiAllWordsForBookProvider = FutureProvider.family<List<VocabEntry>, int>(
  (ref, bookId) {
    ref.watch(apiRemoteDataEpochProvider);
    return ref.read(apiServiceProvider).fetchAllWordsForBook(bookId);
  },
);

/// GET /words.php?global=1 — full vocabulary catalog (unit samples word tap).
final apiAllWordsCatalogProvider = FutureProvider<List<VocabEntry>>((ref) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchAllWordsGlobally();
});

// ─── Grammar (DB column `content` = topic name) ─────────────────────────────

final apiGrammarTopicsProvider = FutureProvider<List<GrammarTopicSummary>>((
  ref,
) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchGrammarTopics();
});

final apiGrammarBooksProvider = FutureProvider<List<GrammarBook>>((ref) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchGrammarBooks();
});

final apiGrammarUnitsProvider = FutureProvider.family<List<GrammarUnit>, int>((
  ref,
  bookId,
) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref.read(apiServiceProvider).fetchGrammarUnits(bookId);
});

final apiGrammarUnitTextsProvider =
    FutureProvider.family<List<GrammarUnitText>, int>((ref, unitId) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref.read(apiServiceProvider).fetchGrammarUnitTexts(unitId);
    });

final apiGrammarQuestionsProvider =
    FutureProvider.family<List<GrammarQuestion>, String>((ref, topic) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref.read(apiServiceProvider).fetchGrammarQuestions(topic);
    });

final apiGrammarUnitQuestionsProvider =
    FutureProvider.family<List<GrammarQuestion>, int>((ref, unitId) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref.read(apiServiceProvider).fetchGrammarQuestionsForUnit(unitId);
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

/// [apiGrammarQuizSessionProvider] arguments: topics key + desired session length + session seed.
typedef GrammarQuizSessionParams = ({
  String topicsKey,
  int? grammarUnitId,
  int questionCount,
  int seed,
});

/// Sort mode for grammar result screens (UI only; lists are fetched date-desc then reordered).
enum GrammarResultsListSort { newest, mostPractice }

final grammarResultsListSortProvider = StateProvider<GrammarResultsListSort>(
  (ref) => GrammarResultsListSort.newest,
);

/// GET /grammar_results_my.php (requires auth)
final myGrammarResultsProvider = FutureProvider<List<GrammarResult>>((ref) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref
      .read(apiServiceProvider)
      .fetchMyGrammarResults(sort: 'date', order: 'desc');
});

/// Paginated community grammar list (Grammar results → Users tab).
/// [rawItems] are rows returned by the API (before merging duplicates for «Most practice» UI).
/// [nextFetchOffset] is the server `offset` for the next page (length of raw rows fetched so far).
@immutable
class PublicGrammarPagedState {
  const PublicGrammarPagedState({
    required this.rawItems,
    required this.hasMore,
    required this.nextFetchOffset,
    this.isLoadingMore = false,
  });

  final List<GrammarResult> rawItems;
  final bool hasMore;
  final int nextFetchOffset;
  final bool isLoadingMore;

  PublicGrammarPagedState copyWith({
    List<GrammarResult>? rawItems,
    bool? hasMore,
    bool? isLoadingMore,
    int? nextFetchOffset,
  }) {
    return PublicGrammarPagedState(
      rawItems: rawItems ?? this.rawItems,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextFetchOffset: nextFetchOffset ?? this.nextFetchOffset,
    );
  }
}

/// GET /grammar_results_public.php (no auth), infinite scroll via [PublicGrammarCommunityNotifier.loadMore].
final publicGrammarCommunityProvider =
    AsyncNotifierProvider.autoDispose<
      PublicGrammarCommunityNotifier,
      PublicGrammarPagedState
    >(PublicGrammarCommunityNotifier.new);

class PublicGrammarCommunityNotifier
    extends AutoDisposeAsyncNotifier<PublicGrammarPagedState> {
  static const int pageSize = 30;

  String _sortApi(GrammarResultsListSort s) =>
      s == GrammarResultsListSort.mostPractice ? 'practice' : 'date';

  @override
  Future<PublicGrammarPagedState> build() async {
    ref.watch(grammarResultsListSortProvider);
    ref.watch(apiRemoteDataEpochProvider);
    final sort = ref.read(grammarResultsListSortProvider);
    final page = await ref
        .read(apiServiceProvider)
        .fetchPublicGrammarResultsPage(
          sort: _sortApi(sort),
          order: 'desc',
          limit: pageSize,
          offset: 0,
        );
    return PublicGrammarPagedState(
      rawItems: page.results,
      hasMore: page.hasMore,
      nextFetchOffset: page.results.length,
    );
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.isLoadingMore) return;
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final sort = ref.read(grammarResultsListSortProvider);
      final page = await ref
          .read(apiServiceProvider)
          .fetchPublicGrammarResultsPage(
            sort: _sortApi(sort),
            order: 'desc',
            limit: pageSize,
            offset: cur.nextFetchOffset,
          );
      state = AsyncData(
        PublicGrammarPagedState(
          rawItems: [...cur.rawItems, ...page.results],
          hasMore: page.hasMore,
          nextFetchOffset: cur.nextFetchOffset + page.results.length,
        ),
      );
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }
}

/// GET /grammar_result_detail.php?id= (auth). For review screen.
final grammarResultDetailProvider =
    FutureProvider.family<GrammarResultDetail, int>((ref, id) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref.read(apiServiceProvider).fetchGrammarResultDetail(id);
    });

/// GET /vocab_quiz_results_my.php (requires auth). Empty when logged out.
final myVocabQuizResultsProvider = FutureProvider<List<VocabQuizResultSummary>>(
  (ref) async {
    ref.watch(apiRemoteDataEpochProvider);
    final session = ref.watch(authProvider).valueOrNull;
    if (session == null) return [];
    return ref.read(apiServiceProvider).fetchMyVocabQuizResults();
  },
);

/// Lifetime vocabulary quiz points for the signed-in user.
/// This is not the leaderboard; admins keep points here even when hidden there.
final myVocabQuizTotalPointsProvider = FutureProvider<int>((ref) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) return 0;
  return ref.read(apiServiceProvider).fetchMyVocabQuizTotalPoints();
});

/// GET /vocab_quiz_result_detail.php?id= (auth).
final vocabQuizResultDetailProvider =
    FutureProvider.family<VocabQuizResultDetail, int>((ref, id) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref.read(apiServiceProvider).fetchVocabQuizResultDetail(id);
    });

/// GET /league.php?type=all|grammar|vocab|challenge|word_builder&period=...&sort=...
/// Public leaderboard; signed-in users additionally receive their own rank.
final leagueProvider = FutureProvider.family<LeagueResponse, LeagueQuery>((
  ref,
  query,
) {
  ref.watch(apiRemoteDataEpochProvider);
  return ref
      .read(apiServiceProvider)
      .fetchLeague(query.type, period: query.period, sort: query.sort);
});

/// GET /teacher_students.php — requires teacher role on server.
final teacherStudentsProvider = FutureProvider<List<TeacherStudentSummary>>((
  ref,
) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null || (!session.user.isTeacher && !session.user.isAdmin)) {
    return [];
  }
  return ref.read(apiServiceProvider).fetchTeacherStudents();
});

/// Same as [teacherStudentsProvider] but inbox sort (unread first, then newest activity).
final teacherInboxStudentsProvider =
    FutureProvider<List<TeacherStudentSummary>>((ref) async {
      ref.watch(apiRemoteDataEpochProvider);
      final session = ref.watch(authProvider).valueOrNull;
      if (session == null ||
          (!session.user.isTeacher && !session.user.isAdmin)) {
        return [];
      }
      return ref.read(apiServiceProvider).fetchTeacherStudents(inbox: true);
    });

/// Vocabulary quiz summaries for one student (teacher panel).
final teacherStudentVocabResultsProvider =
    FutureProvider.family<List<VocabQuizResultSummary>, int>((ref, studentId) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref
          .read(apiServiceProvider)
          .fetchTeacherStudentVocabResults(studentId);
    });

/// Grammar results for one student (teacher panel).
final teacherStudentGrammarResultsProvider =
    FutureProvider.family<List<GrammarResult>, int>((ref, studentId) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref
          .read(apiServiceProvider)
          .fetchTeacherStudentGrammarResults(studentId);
    });

/// Class session list (teacher panel — per-student).
final teacherStudentSessionsProvider =
    FutureProvider.family<TeacherSessionInfo, int>((ref, studentId) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref
          .read(apiServiceProvider)
          .fetchTeacherStudentSessions(studentId);
    });

final teacherStudentPricingProvider =
    FutureProvider.family<TeacherStudentPricing, int>((ref, studentId) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref.read(apiServiceProvider).fetchTeacherStudentPricing(studentId);
    });

final teacherFinancialSummaryProvider =
    FutureProvider.family<
      TeacherFinancialSummaryResponse,
      TeacherFinancialFilters
    >((ref, filters) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref
          .read(apiServiceProvider)
          .fetchTeacherFinancialSummary(
            studentId: filters.studentId,
            period: filters.period,
            from: filters.from,
            to: filters.to,
            paymentStatus: filters.paymentStatus,
            groupByStudent: filters.groupByStudent,
          );
    });

/// Student: read-only class sessions recorded by their teacher ([my_class_sessions.php]).
final myClassSessionsProvider = FutureProvider<TeacherSessionInfo>((ref) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null ||
      session.user.isTeacher ||
      session.user.isAdmin ||
      session.user.teacherUserId == null) {
    return const TeacherSessionInfo(
      sessionCount: 0,
      sessions: [],
      terms: [],
      usesTermsTable: false,
    );
  }
  return ref.read(apiServiceProvider).fetchMyClassSessions();
});

/// Teacher / admin: weekly schedule slots for one student.
final teacherStudentScheduleProvider =
    FutureProvider.family<List<ClassScheduleSlot>, int>((ref, studentId) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref
          .read(apiServiceProvider)
          .fetchTeacherStudentSchedule(studentId);
    });

/// Teacher / admin: one-off temporary class slots created from Schedule tab.
final teacherTemporaryScheduleProvider =
    FutureProvider<List<TemporaryClassScheduleSlot>>((ref) {
      ref.watch(apiRemoteDataEpochProvider);
      return ref.read(apiServiceProvider).fetchTeacherTemporarySchedule();
    });

String _hmFromDateTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Teacher dashboard: upcoming weekly and one-off class slots in the next 7 days,
/// excluding times already covered by a logged class session for that student.
final teacherWeekUpcomingProvider =
    FutureProvider<List<TeacherUpcomingSlotItem>>((ref) async {
      ref.watch(apiRemoteDataEpochProvider);
      final session = ref.watch(authProvider).valueOrNull;
      if (session == null ||
          (!session.user.isTeacher && !session.user.isAdmin)) {
        return [];
      }
      final api = ref.read(apiServiceProvider);
      final students = await api.fetchTeacherStudents();
      if (students.isEmpty) return [];

      final nowLocal = DateTime.now();
      final temporarySlots = await api
          .fetchTeacherTemporarySchedule()
          .catchError((_) => <TemporaryClassScheduleSlot>[]);
      final sessionsByStudent = <int, List<ClassSessionEntry>>{};
      final slotsByStudent = <int, List<ClassScheduleSlot>>{};
      final batches = await Future.wait(
        students.map((stu) async {
          try {
            final slots = await api.fetchTeacherStudentSchedule(stu.id);
            final info = await api.fetchTeacherStudentSessions(stu.id);
            slotsByStudent[stu.id] = slots;
            sessionsByStudent[stu.id] = info.sessions;
            return computeTeacherWeekUpcomingForStudent(
              nowLocal: nowLocal,
              student: stu,
              slots: slots,
              sessions: info.sessions,
            );
          } catch (_) {
            return <TeacherUpcomingSlotItem>[];
          }
        }),
      );

      final horizonExclusive = nowLocal.add(const Duration(days: 7));
      final dueHorizonStart = nowLocal.subtract(const Duration(hours: 6));
      final dueOccurrences = <ScheduleAttendanceDueOccurrence>[];

      for (final stu in students) {
        final sessions = sessionsByStudent[stu.id] ?? const [];
        for (final slot
            in slotsByStudent[stu.id] ?? const <ClassScheduleSlot>[]) {
          final occurrences = weeklySlotOccurrencesBetween(
            slot: slot,
            fromLocal: dueHorizonStart,
            toLocal: nowLocal,
          );
          for (final occ in occurrences) {
            if (slotOccurrenceHasRecordedSession(
              slot: slot,
              occurrenceStartLocal: occ,
              sessions: sessions,
            )) {
              continue;
            }
            dueOccurrences.add(
              ScheduleAttendanceDueOccurrence(
                studentId: stu.id,
                sourceType: 'weekly',
                sourceId: slot.id,
                startAt: occ,
                endAt: slotOccurrenceEndLocal(slot, occ),
                label: slot.label,
              ),
            );
          }
        }
      }

      for (final t in temporarySlots) {
        if (t.startLocal.isAfter(nowLocal) ||
            t.startLocal.isBefore(dueHorizonStart)) {
          continue;
        }
        final synthetic = ClassScheduleSlot(
          id: t.id,
          weekday: t.startLocal.weekday,
          startTime: _hmFromDateTime(t.startLocal),
          endTime: _hmFromDateTime(t.endLocal),
          label: t.label,
        );
        if (slotOccurrenceHasRecordedSession(
          slot: synthetic,
          occurrenceStartLocal: t.startLocal,
          sessions: sessionsByStudent[t.studentId] ?? const [],
        )) {
          continue;
        }
        dueOccurrences.add(
          ScheduleAttendanceDueOccurrence(
            studentId: t.studentId,
            sourceType: 'temporary',
            sourceId: t.id,
            startAt: t.startLocal,
            endAt: t.endLocal,
            label: t.label,
          ),
        );
      }

      var attendanceState = const ScheduleAttendanceState();
      try {
        attendanceState = await api.processTeacherScheduleAttendance(
          occurrences: dueOccurrences,
        );
        if (dueOccurrences.isNotEmpty) {
          for (final occ in dueOccurrences) {
            ref.invalidate(teacherStudentSessionsProvider(occ.studentId));
          }
          ref.invalidate(teacherStudentsProvider);
        }
      } catch (_) {
        if (dueOccurrences.isNotEmpty) rethrow;
        attendanceState = const ScheduleAttendanceState();
      }

      final temporaryItems = <TeacherUpcomingSlotItem>[];
      for (final t in temporarySlots) {
        if (!t.startLocal.isAfter(nowLocal)) continue;
        if (!t.startLocal.isBefore(horizonExclusive)) continue;
        final synthetic = ClassScheduleSlot(
          id: t.id,
          weekday: t.startLocal.weekday,
          startTime: _hmFromDateTime(t.startLocal),
          endTime: _hmFromDateTime(t.endLocal),
          label: t.label,
        );
        if (slotOccurrenceHasRecordedSession(
          slot: synthetic,
          occurrenceStartLocal: t.startLocal,
          sessions: sessionsByStudent[t.studentId] ?? const [],
        )) {
          continue;
        }
        temporaryItems.add(
          TeacherUpcomingSlotItem(
            studentId: t.studentId,
            studentDisplayLabel: t.studentDisplayLabel,
            studentEmail: t.studentEmail,
            avatarId: t.avatarId,
            startLocal: t.startLocal,
            slot: synthetic,
            isTemporary: true,
            temporarySlotId: t.id,
            temporaryEndLocal: t.endLocal,
            attendanceMode: attendanceState.modeFor(t.studentId),
          ),
        );
      }

      final upcomingWeeklyItems = batches
          .expand((e) => e)
          .map(
            (item) => TeacherUpcomingSlotItem(
              studentId: item.studentId,
              studentDisplayLabel: item.studentDisplayLabel,
              studentEmail: item.studentEmail,
              avatarId: item.avatarId,
              startLocal: item.startLocal,
              slot: item.slot,
              isTemporary: item.isTemporary,
              temporarySlotId: item.temporarySlotId,
              attendanceMode: attendanceState.modeFor(item.studentId),
            ),
          );

      final pendingItems = attendanceState.pending.map((p) {
        final end = p.endLocal ?? p.startLocal.add(const Duration(hours: 1));
        final synthetic = ClassScheduleSlot(
          id: p.sourceId,
          weekday: p.startLocal.weekday,
          startTime: _hmFromDateTime(p.startLocal),
          endTime: _hmFromDateTime(end),
          label: p.label,
        );
        return TeacherUpcomingSlotItem(
          studentId: p.studentId,
          studentDisplayLabel: p.studentDisplayLabel,
          studentEmail: p.studentEmail,
          avatarId: p.avatarId,
          startLocal: p.startLocal,
          slot: synthetic,
          isTemporary: p.sourceType == 'temporary',
          temporarySlotId: p.sourceType == 'temporary' ? p.sourceId : null,
          temporaryEndLocal: p.sourceType == 'temporary' ? p.endLocal : null,
          attendanceMode: attendanceState.modeFor(p.studentId),
          isManualPending: true,
          attendanceOccurrenceId: p.id,
        );
      });

      final aggregated = [
        ...pendingItems,
        ...upcomingWeeklyItems,
        ...temporaryItems,
      ]..sort((a, b) => a.startLocal.compareTo(b.startLocal));
      return aggregated;
    });

/// Learner: read-only weekly class times ([my_class_schedule.php]).
final myClassScheduleProvider = FutureProvider<List<ClassScheduleSlot>>((
  ref,
) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null || session.user.isTeacher || session.user.isAdmin) {
    return const [];
  }
  return ref.read(apiServiceProvider).fetchMyClassSchedule();
});

/// Preview row for You hub (student + assigned teacher). Empty when not applicable.
final teacherMessagesPreviewProvider = FutureProvider<TeacherMessagesPreview>((
  ref,
) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null || session.user.isTeacher || session.user.isAdmin) {
    return TeacherMessagesPreview.empty();
  }
  return ref.read(apiServiceProvider).fetchTeacherMessagesPreview();
});

/// Home FAB badge: teachers = distinct students with unread; students = unread msgs from teacher.
final teacherMessagesUnreadFabProvider = FutureProvider<int>((ref) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) return 0;
  final u = session.user;
  if (!u.isTeacher && !u.isAdmin && u.teacherUserId == null) return 0;
  final s = await ref
      .read(apiServiceProvider)
      .fetchTeacherMessagesUnreadSummary();
  return s.badgeForUser(userIsTeacher: u.isTeacher || u.isAdmin);
});

/// Grammar results for charts (date desc, newest first). Empty when logged out.
final grammarStatsChartResultsProvider = FutureProvider<List<GrammarResult>>((
  ref,
) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) return [];
  return ref
      .read(apiServiceProvider)
      .fetchMyGrammarResults(sort: 'date', order: 'desc');
});

/// Fetches questions for either one grammar unit or all topics in [params.topicsKey].
/// Then it shuffles and returns up to `min(params.questionCount, merged.length, [kGrammarQuizSessionSize])`.
/// One topic: random subset of that bank. Several topics: random mix from all banks (fair variety).
final apiGrammarQuizSessionProvider =
    FutureProvider.family<List<GrammarQuestion>, GrammarQuizSessionParams>((
      ref,
      params,
    ) async {
      ref.watch(apiRemoteDataEpochProvider);
      final unitId = params.grammarUnitId;
      if (unitId != null && unitId > 0) {
        final want = params.questionCount.clamp(1, kGrammarQuizSessionSize);
        final questions = await ref
            .read(apiServiceProvider)
            .fetchGrammarQuestionsForUnit(unitId);
        if (questions.isEmpty) return [];
        final merged = [...questions]..shuffle(Random(params.seed));
        final poolCap = min(merged.length, kGrammarQuizSessionSize);
        final take = min(want, poolCap);
        return merged.sublist(0, take);
      }

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
      // Seed ensures "Practice again" produces a different order even when repeated quickly.
      merged.shuffle(Random(params.seed));
      final poolCap = min(merged.length, kGrammarQuizSessionSize);
      final take = min(want, poolCap);
      return merged.sublist(0, take);
    });

// ─── New Providers for Search ───────────────────────────────────────────────

// Search query provider
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

// Books list with search
final apiSearchBooksProvider = FutureProvider<List<Book>>((ref) {
  ref.watch(apiRemoteDataEpochProvider);
  final query = ref.watch(bookSearchQueryProvider); // Watch the query state

  // If the query is empty, fetch all books (like before)
  // Otherwise, search using the query
  if (query.isEmpty) {
    return ref.read(apiServiceProvider).fetchBooks(scope: 'public');
  } else {
    return ref.read(apiServiceProvider).searchBooks(query, scope: 'public');
  }
});
