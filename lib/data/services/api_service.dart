import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/cache/api_disk_cache.dart';
import '../models/auth_user.dart';
import '../models/teacher_student.dart';
import '../models/book_model.dart';
import '../models/grammar_question.dart';
import '../models/grammar_topic_summary.dart';
import '../models/grammar_result.dart';
import '../models/grammar_result_detail.dart';
import '../models/unit_model.dart';
import '../models/vocab_entry.dart';
import '../models/vocab_quiz_result.dart';
import '../models/teacher_message.dart';

// ─── Change this to your server's base URL ───────────────────────────────────
// Example: 'https://yourdomain.com/api'
const String kApiBaseUrl = 'http://erfaninfo.com/wordsapi';

// ─── GET response disk cache (never used for words.php — see [_httpCacheKey]). ─
const Duration _ttlBooks = Duration(minutes: 25);
const Duration _ttlUnitsSections = Duration(hours: 8);
const Duration _ttlGrammarCatalog = Duration(days: 3);
const Duration _ttlGrammarResultsPublic = Duration(hours: 1);
const Duration _ttlGrammarResultsMy = Duration(minutes: 6);
const Duration _ttlGrammarResultDetail = Duration(minutes: 12);
const Duration _ttlVocabQuizResultsList = Duration(minutes: 4);
const Duration _ttlUserVocabMarks = Duration(minutes: 6);

class ApiService {
  ApiService({this.baseUrl = kApiBaseUrl, this.authToken});

  final String baseUrl;

  /// When set, sent as `Authorization: Bearer …` on all requests.
  final String? authToken;

  Map<String, String> _mergeHeaders([Map<String, String>? extra]) {
    final out = <String, String>{if (extra != null) ...extra};
    final t = authToken;
    if (t != null && t.isNotEmpty) {
      out['Authorization'] = 'Bearer $t';
    }
    return out;
  }

  /// Isolates cache files per user session without storing the raw token in filenames.
  String _authCacheTag() {
    final t = authToken;
    if (t == null || t.isEmpty) return 'anon';
    var h = 2166136261;
    for (final x in utf8.encode(t)) {
      h ^= x;
      h = h * 16777619;
    }
    return '${h & 0x7fffffff}';
  }

  String _httpCacheKey(Uri uri) {
    return 'GET|${uri.toString()}|${_authCacheTag()}';
  }

  Future<String?> _readGetCache(Uri uri) =>
      ApiDiskCache.instance.read(_httpCacheKey(uri));

  Future<void> _writeGetCache(Uri uri, String body, Duration ttl) =>
      ApiDiskCache.instance.write(_httpCacheKey(uri), body, ttl: ttl);

  /// [scope] `public` (default) = main catalog; `student` = student tab (auth + server-side access).
  Future<List<Book>> fetchBooks({String scope = 'public'}) async {
    final uri = Uri.parse('$baseUrl/books.php').replace(
      queryParameters: {'scope': scope},
    );
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'books');
    await _writeGetCache(uri, response.body, _ttlBooks);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Book>> searchBooks(String query, {String scope = 'public'}) async {
    final uri = Uri.parse('$baseUrl/books.php').replace(
      queryParameters: {'search': query, 'scope': scope},
    );
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'books search');
    await _writeGetCache(uri, response.body, _ttlBooks);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /units.php?book_id={id} ───────────────────────────────────────────
  Future<List<UnitInfo>> fetchUnits(int bookId) async {
    final uri = Uri.parse('$baseUrl/units.php?book_id=$bookId');
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data
          .map((e) => UnitInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'units');
    await _writeGetCache(uri, response.body, _ttlUnitsSections);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => UnitInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /sections.php?book_id={id}&unit={unit} ────────────────────────────
  Future<List<int>> fetchSections(int bookId, int unit) async {
    final uri = Uri.parse('$baseUrl/sections.php?book_id=$bookId&unit=$unit');
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data.map((e) => (e['section'] as num).toInt()).toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'sections');
    await _writeGetCache(uri, response.body, _ttlUnitsSections);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => (e['section'] as num).toInt()).toList();
  }

  // ── GET /words.php?book_id={id}&unit={unit}[&section={section}] ───────────
  Future<List<VocabEntry>> fetchWords(
    int bookId,
    int unit, {
    int? section,
  }) async {
    var uriStr = '$baseUrl/words.php?book_id=$bookId&unit=$unit';
    if (section != null) uriStr += '&section=$section';
    final response = await http.get(
      Uri.parse(uriStr),
      headers: _mergeHeaders(),
    );
    _assertOk(response, 'words');
    final data = jsonDecode(response.body) as List<dynamic>;
    final bookIdStr = bookId.toString();
    return data
        .map(
          (e) =>
              VocabEntry.fromJson(e as Map<String, dynamic>, bookId: bookIdStr),
        )
        .toList();
  }

  // ── GET /grammar_topics.php ───────────────────────────────────────────────
  Future<List<GrammarTopicSummary>> fetchGrammarTopics() async {
    final uri = Uri.parse('$baseUrl/grammar_topics.php');
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data
          .map((e) => GrammarTopicSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'grammar topics');
    await _writeGetCache(uri, response.body, _ttlGrammarCatalog);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => GrammarTopicSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /grammar_questions.php?topic=... (never disk-cached — live question bank)
  Future<List<GrammarQuestion>> fetchGrammarQuestions(String topic) async {
    final uri = Uri.parse(
      '$baseUrl/grammar_questions.php',
    ).replace(queryParameters: {'topic': topic});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'grammar questions');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => GrammarQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /grammar_report_question.php
  Future<void> reportGrammarQuestion({
    required int questionId,
    required String reportType,
    String? detail,
  }) async {
    final uri = Uri.parse('$baseUrl/grammar_report_question.php');
    final payload = <String, dynamic>{
      'question_id': questionId,
      'report_type': reportType,
    };
    final t = detail?.trim();
    if (t != null && t.isNotEmpty) {
      payload['detail'] = t;
    }
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      var msg = 'HTTP ${response.statusCode}';
      try {
        final m = jsonDecode(response.body) as Map<String, dynamic>?;
        final e = m?['error'] as String?;
        if (e != null && e.isNotEmpty) {
          msg = e;
        }
      } catch (_) {}
      throw Exception(msg);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Report failed');
    }
  }

  /// POST /grammar_results_submit.php (auth optional). Returns server row id when present.
  Future<int?> submitGrammarResult({
    required String quizName,
    required int score,
    required int totalQuestions,
    required List<String> selectedGrammars,
    required bool isPublic,
    List<Map<String, dynamic>>? sessionItems,
  }) async {
    final uri = Uri.parse('$baseUrl/grammar_results_submit.php');
    final payload = <String, dynamic>{
      'quiz_name': quizName,
      'score': score,
      'total_questions': totalQuestions,
      'public': isPublic,
      'selected_grammars': selectedGrammars,
    };
    if (sessionItems != null && sessionItems.isNotEmpty) {
      payload['session'] = <String, dynamic>{'items': sessionItems};
    }
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(payload),
    );
    _assertAuthResponse(response);
    await bustGrammarResultsListCaches();
    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return (map['id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// GET /grammar_result_detail.php?id= (requires auth)
  Future<GrammarResultDetail> fetchGrammarResultDetail(int resultId) async {
    final uri = Uri.parse(
      '$baseUrl/grammar_result_detail.php',
    ).replace(queryParameters: {'id': '$resultId'});
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      return GrammarResultDetail.fromApiJson(map);
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    await _writeGetCache(uri, response.body, _ttlGrammarResultDetail);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return GrammarResultDetail.fromApiJson(map);
  }

  /// GET /grammar_results_my.php (requires auth). [sort] `date`|`score`, [order] `asc`|`desc`.
  Future<List<GrammarResult>> fetchMyGrammarResults({
    String sort = 'date',
    String order = 'desc',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/grammar_results_my.php',
    ).replace(queryParameters: {'sort': sort, 'order': order});
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      final list = (map['results'] as List<dynamic>? ?? const []);
      return list
          .map((e) => GrammarResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    await _writeGetCache(uri, response.body, _ttlGrammarResultsMy);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (map['results'] as List<dynamic>? ?? const []);
    return list
        .map((e) => GrammarResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /grammar_results_public.php
  Future<List<GrammarResult>> fetchPublicGrammarResults({
    String sort = 'date',
    String order = 'desc',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/grammar_results_public.php',
    ).replace(queryParameters: {'sort': sort, 'order': order});
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      final list = (map['results'] as List<dynamic>? ?? const []);
      return list
          .map((e) => GrammarResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'grammar results (public)');
    await _writeGetCache(uri, response.body, _ttlGrammarResultsPublic);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (map['results'] as List<dynamic>? ?? const []);
    return list
        .map((e) => GrammarResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /vocab_quiz_wrongs.php?book_id=&unit= (optional unit)
  Future<List<({int unit, String wordKey})>> fetchVocabQuizWrongs(
    int bookId, {
    int? unit,
  }) async {
    final q = <String, String>{'book_id': '$bookId'};
    if (unit != null) {
      q['unit'] = '$unit';
    }
    final uri = Uri.parse(
      '$baseUrl/vocab_quiz_wrongs.php',
    ).replace(queryParameters: q);
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final items = map['items'] as List<dynamic>? ?? const [];
    return items.map((e) {
      final m = e as Map<String, dynamic>;
      return (
        unit: (m['unit'] as num).toInt(),
        wordKey: (m['word_key'] ?? '').toString(),
      );
    }).toList();
  }

  /// POST /vocab_quiz_wrongs.php
  Future<void> addVocabQuizWrong({
    required int bookId,
    required int unit,
    required String wordKey,
  }) async {
    final uri = Uri.parse('$baseUrl/vocab_quiz_wrongs.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'book_id': bookId, 'unit': unit, 'word_key': wordKey}),
    );
    _assertAuthResponse(response);
  }

  /// DELETE /vocab_quiz_wrongs.php
  Future<void> removeVocabQuizWrong({
    required int bookId,
    required int unit,
    required String wordKey,
  }) async {
    final uri = Uri.parse('$baseUrl/vocab_quiz_wrongs.php').replace(
      queryParameters: {
        'book_id': '$bookId',
        'unit': '$unit',
        'word_key': wordKey,
      },
    );
    final response = await http.delete(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
  }

  /// POST /vocab_quiz_results_submit.php — requires auth.
  Future<int?> submitVocabQuizResult({
    required int bookId,
    required int score,
    required int totalQuestions,
    required Map<String, dynamic> session,
  }) async {
    final uri = Uri.parse('$baseUrl/vocab_quiz_results_submit.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'book_id': bookId,
        'score': score,
        'total_questions': totalQuestions,
        'session': session,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Submit failed');
    }
    await bustVocabQuizResultsMyCache();
    await bustVocabQuizResultsMyCache(bookId: bookId);
    return (map['id'] as num?)?.toInt();
  }

  /// GET /vocab_quiz_results_my.php — requires auth.
  /// List rows only (no word list). [words.php] and detail session are never cached.
  Future<List<VocabQuizResultSummary>> fetchMyVocabQuizResults({
    int? bookId,
    int limit = 100,
  }) async {
    final q = <String, String>{'limit': '$limit'};
    if (bookId != null) {
      q['book_id'] = '$bookId';
    }
    final uri = Uri.parse('$baseUrl/vocab_quiz_results_my.php')
        .replace(queryParameters: q);
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      final list = map['results'] as List<dynamic>? ?? const [];
      return list
          .map((e) => VocabQuizResultSummary.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    await _writeGetCache(uri, response.body, _ttlVocabQuizResultsList);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['results'] as List<dynamic>? ?? const [];
    return list
        .map((e) => VocabQuizResultSummary.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();
  }

  /// GET /vocab_quiz_result_detail.php?id= — requires auth.
  /// Not cached: response includes per-word session data (same policy as words.php).
  Future<VocabQuizResultDetail> fetchVocabQuizResultDetail(int id) async {
    final uri = Uri.parse('$baseUrl/vocab_quiz_result_detail.php').replace(
      queryParameters: {'id': '$id'},
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final r = map['result'] as Map<String, dynamic>?;
    if (r == null) {
      throw Exception('Invalid response');
    }
    return VocabQuizResultDetail.fromApiJson(r);
  }

  /// POST /word_important.php
  Future<int> setWordImportant({
    required int id,
    required int important,
  }) async {
    final uri = Uri.parse('$baseUrl/word_important.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'id': id, 'important': important}),
    );
    if (response.statusCode != 200) {
      _throwFromJsonBody(response);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Update failed');
    }
    await bustUserVocabMarksCache(kind: 'important');
    return (map['important'] as num?)?.toInt() ?? important;
  }

  /// GET /user_vocab_marks.php?kind=favorite|important — requires auth.
  /// Caches id sets only (not word text).
  Future<Set<int>> fetchUserVocabMarks({required String kind}) async {
    final uri = Uri.parse('$baseUrl/user_vocab_marks.php').replace(
      queryParameters: {'kind': kind},
    );
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      final list = map['word_ids'] as List<dynamic>? ?? const [];
      return list.map((e) => (e as num).toInt()).toSet();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    await _writeGetCache(uri, response.body, _ttlUserVocabMarks);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['word_ids'] as List<dynamic>? ?? const [];
    return list.map((e) => (e as num).toInt()).toSet();
  }

  /// POST /user_vocab_marks.php — requires auth.
  Future<void> addUserVocabMark({
    required String kind,
    required int wordId,
  }) async {
    final uri = Uri.parse('$baseUrl/user_vocab_marks.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'kind': kind, 'word_id': wordId}),
    );
    _assertAuthResponse(response);
    await bustUserVocabMarksCache(kind: kind);
  }

  /// DELETE /user_vocab_marks.php — requires auth.
  Future<void> removeUserVocabMark({
    required String kind,
    required int wordId,
  }) async {
    final uri = Uri.parse('$baseUrl/user_vocab_marks.php').replace(
      queryParameters: {'kind': kind, 'word_id': '$wordId'},
    );
    final response = await http.delete(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    await bustUserVocabMarksCache(kind: kind);
  }

  Future<List<VocabEntry>> fetchAllWordsForBook(int bookId) async {
    final uri = Uri.parse('$baseUrl/words.php?book_id=$bookId');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'words (all)');
    final data = jsonDecode(response.body) as List<dynamic>;
    final bookIdStr = bookId.toString();
    return data
        .map(
          (e) =>
              VocabEntry.fromJson(e as Map<String, dynamic>, bookId: bookIdStr),
        )
        .toList();
  }

  // ── Auth (no bearer token on login/register) ─────────────────────────────

  /// POST /login.php
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login.php');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession.fromAuthResponse(map);
  }

  /// POST /register.php
  Future<AuthSession> register({
    required String email,
    required String password,
    String? displayName,
    bool registerAsStudent = false,
    String? studentCode,
  }) async {
    final uri = Uri.parse('$baseUrl/register.php');
    final body = <String, dynamic>{'email': email.trim(), 'password': password};
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      body['display_name'] = dn;
    }
    if (registerAsStudent) {
      body['is_student'] = true;
      final c = studentCode?.trim();
      if (c != null && c.isNotEmpty) {
        body['student_code'] = c;
      }
    }
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession.fromAuthResponse(map);
  }

  /// POST /student_redeem_code.php — requires auth.
  Future<AuthUser> redeemStudentCode(String code) async {
    final uri = Uri.parse('$baseUrl/student_redeem_code.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'code': code.trim()}),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Redeem failed');
    }
    return AuthUser.fromJson(map['user'] as Map<String, dynamic>);
  }

  /// POST /logout.php — requires [authToken].
  Future<void> logout() async {
    final uri = Uri.parse('$baseUrl/logout.php');
    final response = await http.post(uri, headers: _mergeHeaders());
    if (response.statusCode != 200) {
      _throwFromJsonBody(response);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Logout failed');
    }
  }

  /// GET /me.php — requires [authToken].
  Future<AuthUser> fetchCurrentUser() async {
    final uri = Uri.parse('$baseUrl/me.php');
    final response = await http.get(uri, headers: _mergeHeaders());
    if (response.statusCode != 200) {
      _throwFromJsonBody(response);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(map['user'] as Map<String, dynamic>);
  }

  // ── Teacher panel (requires is_teacher on server) ───────────────────────────

  /// GET /teacher_students.php — [inbox] adds unread + last activity and server sort.
  Future<List<TeacherStudentSummary>> fetchTeacherStudents({
    bool inbox = false,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_students.php').replace(
      queryParameters: inbox ? const {'inbox': '1'} : null,
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['students'] as List<dynamic>? ?? const [];
    return list
        .map(
          (e) => TeacherStudentSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// GET /teacher_student_vocab_results.php
  Future<List<VocabQuizResultSummary>> fetchTeacherStudentVocabResults(
    int studentId, {
    int limit = 100,
  }) async {
    final uri =
        Uri.parse('$baseUrl/teacher_student_vocab_results.php').replace(
      queryParameters: {
        'student_id': '$studentId',
        'limit': '$limit',
      },
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['results'] as List<dynamic>? ?? const [];
    return list
        .map(
          (e) => VocabQuizResultSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// GET /teacher_student_grammar_results.php
  Future<List<GrammarResult>> fetchTeacherStudentGrammarResults(
    int studentId,
  ) async {
    final uri =
        Uri.parse('$baseUrl/teacher_student_grammar_results.php').replace(
      queryParameters: {'student_id': '$studentId'},
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['results'] as List<dynamic>? ?? const [];
    return list
        .map((e) => GrammarResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /teacher_student_sessions.php
  Future<TeacherSessionInfo> fetchTeacherStudentSessions(int studentId) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php').replace(
      queryParameters: {'student_id': '$studentId'},
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  TeacherSessionInfo _parseTeacherSessionInfo(Map<String, dynamic> map) {
    final rawList = map['sessions'] as List<dynamic>? ?? const [];
    final sessions = rawList
        .map(
          (e) => ClassSessionEntry.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    final fallbackCount = (map['session_count'] as num?)?.toInt() ?? 0;
    final count =
        sessions.isNotEmpty ? sessions.length : fallbackCount;
    final u = map['updated_at']?.toString();
    final rawNote = map['note']?.toString();
    return TeacherSessionInfo(
      sessionCount: count,
      updatedAt: (u != null && u.isNotEmpty) ? u : null,
      note: (rawNote != null && rawNote.trim().isNotEmpty) ? rawNote : null,
      sessions: sessions,
    );
  }

  /// POST — append one class session (`add_session` on server).
  Future<TeacherSessionInfo> addTeacherClassSession(int studentId) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'add_session': true,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  /// POST — update private note only (does not change session list).
  Future<TeacherSessionInfo> updateTeacherStudentNote({
    required int studentId,
    required String note,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'note': note,
        'note_only': true,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  /// GET /my_class_sessions.php — student: read-only session list from teacher.
  Future<TeacherSessionInfo> fetchMyClassSessions() async {
    final uri = Uri.parse('$baseUrl/my_class_sessions.php');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  /// Legacy POST /teacher_student_sessions.php — prefer [addTeacherClassSession] / [updateTeacherStudentNote].
  Future<TeacherSessionInfo> setTeacherStudentSessions({
    required int studentId,
    required int sessionCount,
    String note = '',
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'session_count': sessionCount,
        'note': note,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  /// POST /upload_avatar.php — multipart field `photo` (JPEG after client compression).
  Future<AuthUser> uploadProfilePhoto(Uint8List jpegBytes) async {
    final uri = Uri.parse('$baseUrl/upload_avatar.php');
    final req = http.MultipartRequest('POST', uri);
    final t = authToken;
    if (t != null && t.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $t';
    }
    req.files.add(
      http.MultipartFile.fromBytes('photo', jpegBytes, filename: 'photo.jpg'),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(map['user'] as Map<String, dynamic>);
  }

  /// GET /teacher_student_messages.php?summary=1 — unread counts for home FAB.
  Future<TeacherMessagesUnreadSummary> fetchTeacherMessagesUnreadSummary() async {
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php').replace(
      queryParameters: const {'summary': '1'},
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return TeacherMessagesUnreadSummary.fromJson(map);
  }

  /// GET /teacher_student_messages.php?preview=1 — auth; empty preview if no teacher.
  Future<TeacherMessagesPreview> fetchTeacherMessagesPreview() async {
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php').replace(
      queryParameters: const {'preview': '1'},
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return TeacherMessagesPreview.fromJson(map);
  }

  /// GET /teacher_student_messages.php — full thread (student: no params; teacher: student_id).
  Future<TeacherMessagesThread> fetchTeacherMessages({int? studentId}) async {
    final q = <String, String>{};
    if (studentId != null) q['student_id'] = '$studentId';
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php')
        .replace(queryParameters: q.isEmpty ? null : q);
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return TeacherMessagesThread.fromJson(map);
  }

  /// POST mark_read — student or teacher (with student_id).
  Future<void> markTeacherMessagesRead({int? studentId}) async {
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php');
    final body = <String, dynamic>{'mark_read': true};
    if (studentId != null) body['student_id'] = studentId;
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Mark read failed');
    }
  }

  /// POST new message — body text; teachers must pass [studentId].
  Future<TeacherMessageRow> sendTeacherMessage(
    String text, {
    int? studentId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php');
    final body = <String, dynamic>{'body': text.trim()};
    if (studentId != null) body['student_id'] = studentId;
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final m = map['message'] as Map<String, dynamic>?;
    if (m == null) {
      throw Exception(map['error']?.toString() ?? 'Send failed');
    }
    return TeacherMessageRow.fromJson(m);
  }

  /// POST /update_profile.php — requires [authToken].
  Future<AuthUser> updateProfile({
    required String displayName,
    required String avatar,
  }) async {
    final uri = Uri.parse('$baseUrl/update_profile.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'display_name': displayName, 'avatar': avatar}),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(map['user'] as Map<String, dynamic>);
  }

  /// Clears disk cache for GET [uri] so the next request uses the network.
  Future<void> bustHttpCacheForUri(Uri uri) async {
    await ApiDiskCache.instance.remove(_httpCacheKey(uri));
  }

  /// Busts `books.php` caches for catalog + optional search (both scopes), matching [fetchBooks] / [searchBooks].
  Future<void> bustBooksCatalogCache({String? searchQuery}) async {
    final q = searchQuery?.trim() ?? '';
    await bustHttpCacheForUri(
      Uri.parse('$baseUrl/books.php').replace(
        queryParameters: {'scope': 'public'},
      ),
    );
    await bustHttpCacheForUri(
      Uri.parse('$baseUrl/books.php').replace(
        queryParameters: {'scope': 'student'},
      ),
    );
    if (q.isNotEmpty) {
      await bustHttpCacheForUri(
        Uri.parse('$baseUrl/books.php').replace(
          queryParameters: {'search': q, 'scope': 'public'},
        ),
      );
      await bustHttpCacheForUri(
        Uri.parse('$baseUrl/books.php').replace(
          queryParameters: {'search': q, 'scope': 'student'},
        ),
      );
    }
  }

  Future<void> bustUnitsCache(int bookId) async {
    await bustHttpCacheForUri(Uri.parse('$baseUrl/units.php?book_id=$bookId'));
  }

  Future<void> bustGrammarTopicsCache() async {
    await bustHttpCacheForUri(Uri.parse('$baseUrl/grammar_topics.php'));
  }

  /// Clears GET caches for grammar result lists ([fetchPublicGrammarResults] / [fetchMyGrammarResults] defaults).
  Future<void> bustGrammarResultsListCaches() async {
    await bustHttpCacheForUri(
      Uri.parse('$baseUrl/grammar_results_public.php').replace(
        queryParameters: const {'sort': 'date', 'order': 'desc'},
      ),
    );
    await bustHttpCacheForUri(
      Uri.parse('$baseUrl/grammar_results_my.php').replace(
        queryParameters: const {'sort': 'date', 'order': 'desc'},
      ),
    );
  }

  /// GET [vocab_quiz_results_my.php] list cache — bust after submit or when forcing refresh.
  Future<void> bustVocabQuizResultsMyCache({int? bookId, int limit = 100}) async {
    final q = <String, String>{'limit': '$limit'};
    if (bookId != null) {
      q['book_id'] = '$bookId';
    }
    await bustHttpCacheForUri(
      Uri.parse('$baseUrl/vocab_quiz_results_my.php').replace(
        queryParameters: q,
      ),
    );
  }

  /// Clears [fetchUserVocabMarks] disk cache so the next pull matches server after add/remove.
  Future<void> bustUserVocabMarksCache({String? kind}) async {
    if (kind != null) {
      await bustHttpCacheForUri(
        Uri.parse('$baseUrl/user_vocab_marks.php').replace(
          queryParameters: {'kind': kind},
        ),
      );
      return;
    }
    await bustHttpCacheForUri(
      Uri.parse('$baseUrl/user_vocab_marks.php').replace(
        queryParameters: const {'kind': 'favorite'},
      ),
    );
    await bustHttpCacheForUri(
      Uri.parse('$baseUrl/user_vocab_marks.php').replace(
        queryParameters: const {'kind': 'important'},
      ),
    );
  }

  void _assertAuthResponse(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      return;
    }
    _throwFromJsonBody(response);
  }

  void _throwFromJsonBody(http.Response response) {
    var msg = 'HTTP ${response.statusCode}';
    try {
      final m = jsonDecode(response.body) as Map<String, dynamic>?;
      final e = m?['error'] as String?;
      if (e != null && e.isNotEmpty) {
        msg = e;
      }
    } catch (_) {}
    throw Exception(msg);
  }

  void _assertOk(http.Response response, String resource) {
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch $resource (HTTP ${response.statusCode})',
      );
    }
  }
}
