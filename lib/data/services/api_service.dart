import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/cache/api_disk_cache.dart';
import '../models/admin_user_row.dart';
import '../models/admin_story.dart';
import '../models/auth_user.dart';
import '../models/teacher_student.dart';
import '../models/book_model.dart';
import '../models/section_info.dart';
import '../models/unit_sample.dart';
import '../models/grammar_question.dart';
import '../models/grammar_topic_summary.dart';
import '../models/grammar_result.dart';
import '../models/grammar_result_detail.dart';
import '../models/unit_model.dart';
import '../models/app_update_manifest.dart';
import '../models/vocab_entry.dart';
import '../models/vocab_quiz_result.dart';
import '../models/teacher_message.dart';
import '../models/class_schedule_slot.dart';
import '../models/schedule_attendance.dart';
import '../models/temporary_class_schedule_slot.dart';

// ─── Change this to your server's base URL ───────────────────────────────────
// Example: 'https://yourdomain.com/api'
const String kApiBaseUrl = 'http://erfaninfo.com/wordsapi';
const Duration _storyUploadTimeout = Duration(seconds: 45);
const Duration _storyCreateTimeout = Duration(seconds: 20);

/// Thrown when the server explicitly rejects the current bearer token (HTTP
/// 401). Call sites use this to distinguish "token is truly invalid — sign the
/// user out" from transient network issues (timeout, DNS, 5xx) where the token
/// is still valid and we should simply retry later.
class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message]);
  final String? message;
  @override
  String toString() => message == null
      ? 'UnauthorizedException'
      : 'UnauthorizedException: $message';
}

// ─── GET response disk cache (never used for words.php — see [_httpCacheKey]). ─
const Duration _ttlBooks = Duration(minutes: 25);
const Duration _ttlUnitsSections = Duration(hours: 8);
const Duration _ttlGrammarCatalog = Duration(days: 3);
const Duration _ttlGrammarResultsPublic = Duration(hours: 1);
const Duration _ttlGrammarResultsMy = Duration(minutes: 6);
const Duration _ttlGrammarResultDetail = Duration(minutes: 12);
const Duration _ttlVocabQuizResultsList = Duration(minutes: 4);
const Duration _ttlUserVocabMarks = Duration(minutes: 6);

String apiAbsoluteMediaUrl(String path) {
  final p = path.trim();
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  final base = kApiBaseUrl.replaceAll(RegExp(r'/$'), '');
  final clean = p.replaceFirst(RegExp(r'^/+'), '');
  return '$base/$clean';
}

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
    final uri = Uri.parse(
      '$baseUrl/books.php',
    ).replace(queryParameters: {'scope': scope});
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

  Future<List<Book>> searchBooks(
    String query, {
    String scope = 'public',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/books.php',
    ).replace(queryParameters: {'search': query, 'scope': scope});
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

  /// GET /app_update.php — sideload APK manifest (no auth, not disk-cached).
  ///
  /// Pass [installedVersion] (buildNumber / versionCode) to receive
  /// `release_notes` for the Home banner for that installed build.
  Future<AppUpdateManifest?> fetchAppUpdateManifest({
    int? installedVersion,
  }) async {
    final query = <String, String>{};
    if (installedVersion != null && installedVersion > 0) {
      query['installed_version'] = '$installedVersion';
    }
    final uri = Uri.parse(
      '$baseUrl/app_update.php',
    ).replace(queryParameters: query.isEmpty ? null : query);
    try {
      final response = await http.get(uri, headers: _mergeHeaders());
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return AppUpdateManifest.fromJson(map);
    } catch (_) {
      return null;
    }
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
  Future<List<SectionInfo>> fetchSections(int bookId, int unit) async {
    final uri = Uri.parse('$baseUrl/sections.php?book_id=$bookId&unit=$unit');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'sections');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => SectionInfo.fromJson(e as Map<String, dynamic>))
        .where((s) => s.section > 0)
        .toList();
  }

  // ── GET /unit_samples.php?book_id={id}&unit={unit}[&section={n}] ───────────
  Future<List<UnitSample>> fetchUnitSamples(
    int bookId,
    int unit, {
    int? section,
  }) async {
    var uriStr = '$baseUrl/unit_samples.php?book_id=$bookId&unit=$unit';
    if (section != null && section > 0) {
      uriStr += '&section=$section';
    }
    final response = await http.get(
      Uri.parse(uriStr),
      headers: _mergeHeaders(),
    );
    _assertOk(response, 'unit samples');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => UnitSample.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /words.php?book_id={id}&unit={unit}[&section={section}] ───────────
  Future<List<VocabEntry>> fetchWords(
    int bookId,
    int unit, {
    int? section,
  }) async {
    var uriStr = '$baseUrl/words.php?book_id=$bookId&unit=$unit';
    if (section != null && section > 0) uriStr += '&section=$section';
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

  /// GET /grammar_results_public.php — paginated; [sort] `date`|`score`|`practice`.
  Future<PublicGrammarResultsPage> fetchPublicGrammarResultsPage({
    required String sort,
    String order = 'desc',
    int limit = 30,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/grammar_results_public.php').replace(
      queryParameters: <String, String>{
        'sort': sort,
        'order': order,
        'limit': '${limit.clamp(1, 100)}',
        'offset': '${offset < 0 ? 0 : offset}',
      },
    );
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      final list = (map['results'] as List<dynamic>? ?? const []);
      final hasMore = map['has_more'] == true;
      return PublicGrammarResultsPage(
        results: list
            .map((e) => GrammarResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: hasMore,
      );
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'grammar results (public)');
    await _writeGetCache(uri, response.body, _ttlGrammarResultsPublic);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (map['results'] as List<dynamic>? ?? const []);
    final hasMore = map['has_more'] == true;
    return PublicGrammarResultsPage(
      results: list
          .map((e) => GrammarResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: hasMore,
    );
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
    final uri = Uri.parse(
      '$baseUrl/vocab_quiz_results_my.php',
    ).replace(queryParameters: q);
    final cached = await _readGetCache(uri);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      final list = map['results'] as List<dynamic>? ?? const [];
      return list
          .map(
            (e) => VocabQuizResultSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    await _writeGetCache(uri, response.body, _ttlVocabQuizResultsList);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['results'] as List<dynamic>? ?? const [];
    return list
        .map((e) => VocabQuizResultSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /vocab_quiz_result_detail.php?id= — requires auth.
  /// Not cached: response includes per-word session data (same policy as words.php).
  Future<VocabQuizResultDetail> fetchVocabQuizResultDetail(int id) async {
    final uri = Uri.parse(
      '$baseUrl/vocab_quiz_result_detail.php',
    ).replace(queryParameters: {'id': '$id'});
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
    final uri = Uri.parse(
      '$baseUrl/user_vocab_marks.php',
    ).replace(queryParameters: {'kind': kind});
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
    final uri = Uri.parse(
      '$baseUrl/user_vocab_marks.php',
    ).replace(queryParameters: {'kind': kind, 'word_id': '$wordId'});
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

  /// GET /words.php?global=1 — entire `words` table (all books).
  Future<List<VocabEntry>> fetchAllWordsGlobally() async {
    final uri = Uri.parse(
      '$baseUrl/words.php',
    ).replace(queryParameters: {'global': '1'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'words (global)');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      final bid = (m['book_id'] as num?)?.toInt() ?? 0;
      return VocabEntry.fromJson(m, bookId: bid.toString());
    }).toList();
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

  /// POST /password_reset_request.php
  Future<void> requestPasswordResetEmailCode(String email) async {
    final uri = Uri.parse('$baseUrl/password_reset_request.php');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email.trim()}),
    );
    if (response.statusCode != 200) {
      _throwFromJsonBody(response);
    }
  }

  /// POST /password_reset_confirm.php
  Future<void> confirmPasswordResetEmailCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/password_reset_confirm.php');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      _throwFromJsonBody(response);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Password reset failed');
    }
  }

  /// POST /teacher_student_codes.php — teacher/admin only.
  Future<String> createTeacherStudentCode(String code) async {
    final uri = Uri.parse('$baseUrl/teacher_student_codes.php');
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
      throw Exception(map['error']?.toString() ?? 'Create failed');
    }
    return map['code']?.toString() ?? code.trim();
  }

  /// GET /teacher_student_codes.php — unused codes for this teacher.
  Future<List<String>> fetchTeacherUnusedStudentCodes() async {
    final uri = Uri.parse('$baseUrl/teacher_student_codes.php');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['codes'] as List<dynamic>? ?? const [];
    return list
        .map((e) => (e as Map<String, dynamic>)['code']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
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
  /// Resolves the current user from the bearer token.
  ///
  /// The optional [timeout] caps how long we wait before giving up; slow
  /// networks used to block the splash screen indefinitely, which in turn led
  /// to the auth layer mistaking the timeout for an invalid token and wiping
  /// the user's saved session.
  ///
  /// Throws [UnauthorizedException] **only** when the server explicitly
  /// rejects the token (HTTP 401). Every other failure — network, DNS, 5xx,
  /// timeout — surfaces as a plain [Exception] so callers can distinguish
  /// "token is dead" from "network is flaky".
  Future<AuthUser> fetchCurrentUser({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse('$baseUrl/me.php');
    final response = await http
        .get(uri, headers: _mergeHeaders())
        .timeout(timeout);
    if (response.statusCode == 401) {
      throw UnauthorizedException(_errorMessageFromBody(response));
    }
    if (response.statusCode != 200) {
      _throwFromJsonBody(response);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(map['user'] as Map<String, dynamic>);
  }

  /// GET /admin_users.php — requires [authToken] and server `is_admin`.
  Future<List<AdminUserRow>> fetchAdminUsers({String? q}) async {
    final uri = Uri.parse('$baseUrl/admin_users.php').replace(
      queryParameters: (q != null && q.trim().isNotEmpty)
          ? {'q': q.trim()}
          : null,
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['users'] as List<dynamic>? ?? const [];
    return list
        .map((e) => AdminUserRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin_user_student.php — requires admin. Student and/or teacher flags.
  Future<AdminUserRow> adminSetUserStudentFlags({
    required int userId,
    required bool studentAccess,
    int? teacherUserId,
    bool? isTeacher,
  }) async {
    final uri = Uri.parse('$baseUrl/admin_user_student.php');
    final body = <String, dynamic>{
      'user_id': userId,
      'student_access': studentAccess,
      'teacher_user_id': studentAccess ? teacherUserId : null,
    };
    if (isTeacher != null) {
      body['is_teacher'] = isTeacher;
    }
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AdminUserRow.fromJson(map['user'] as Map<String, dynamic>);
  }

  /// GET /admin_stories.php — visible stories for current user.
  Future<List<StoryItem>> fetchVisibleStories() async {
    final uri = Uri.parse('$baseUrl/admin_stories.php').replace(
      queryParameters: {'_': DateTime.now().millisecondsSinceEpoch.toString()},
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['stories'] as List<dynamic>? ?? const [];
    return list
        .map((e) => StoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /admin_stories.php?mode=admin — admin story management list.
  Future<List<StoryItem>> fetchAdminStories() async {
    final uri = Uri.parse('$baseUrl/admin_stories.php').replace(
      queryParameters: {
        'mode': 'admin',
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['stories'] as List<dynamic>? ?? const [];
    return list
        .map((e) => StoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin_story_upload.php — admin multipart image upload.
  Future<String> uploadStoryImage(Uint8List imageBytes) async {
    final uri = Uri.parse('$baseUrl/admin_story_upload.php');
    final req = http.MultipartRequest('POST', uri);
    final t = authToken;
    if (t != null && t.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $t';
    }
    req.files.add(
      http.MultipartFile.fromBytes('photo', imageBytes, filename: 'story.jpg'),
    );
    final streamed = await req.send().timeout(
      _storyUploadTimeout,
      onTimeout: () {
        throw TimeoutException(
          'Story image upload timed out. Please try again with a smaller image or a better connection.',
        );
      },
    );
    final response = await http.Response.fromStream(streamed).timeout(
      _storyCreateTimeout,
      onTimeout: () {
        throw TimeoutException(
          'Story upload response timed out. Please try again.',
        );
      },
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Upload failed');
    }
    final path = (map['image_path'] as String?)?.trim() ?? '';
    if (path.isEmpty) {
      throw Exception('Upload succeeded but image path was empty');
    }
    return path;
  }

  /// POST /admin_stories.php — admin creates text or image story.
  Future<int> createAdminStory({
    required String clientRequestId,
    required String contentType,
    String? imagePath,
    String? textContent,
    StoryTextStyle? textStyle,
    required String targetMode,
    required List<int> targetUserIds,
  }) async {
    final uri = Uri.parse('$baseUrl/admin_stories.php');
    final payload = <String, dynamic>{
      'client_request_id': clientRequestId,
      'content_type': contentType,
      'target_mode': targetMode,
      'target_user_ids': targetUserIds,
    };
    if (imagePath != null) payload['image_path'] = imagePath;
    if (textContent != null) payload['text_content'] = textContent;
    if (textStyle != null) payload['text_style'] = textStyle.toJson();
    final response = await http
        .post(
          uri,
          headers: _mergeHeaders({
            'Content-Type': 'application/json; charset=utf-8',
          }),
          body: jsonEncode(payload),
        )
        .timeout(
          _storyCreateTimeout,
          onTimeout: () {
            throw TimeoutException(
              'The server took too long to create the story. Please try again in a moment.',
            );
          },
        );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Story creation failed');
    }
    return (map['id'] as num?)?.toInt() ?? 0;
  }

  /// DELETE /admin_stories.php?id= — admin soft delete.
  Future<void> deleteAdminStory(int storyId) async {
    final uri = Uri.parse(
      '$baseUrl/admin_stories.php',
    ).replace(queryParameters: {'id': '$storyId'});
    final response = await http.delete(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
  }

  /// POST /admin_story_view.php — mark story viewed once.
  Future<void> markStoryViewed(int storyId) async {
    final uri = Uri.parse('$baseUrl/admin_story_view.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'story_id': storyId}),
    );
    _assertAuthResponse(response);
  }

  /// POST /admin_story_like.php — like/unlike story.
  Future<({bool liked, int likeCount})> toggleStoryLike({
    required int storyId,
    required bool liked,
  }) async {
    final uri = Uri.parse('$baseUrl/admin_story_like.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'story_id': storyId, 'liked': liked}),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      liked: map['liked'] == true || map['liked'] == 1,
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// POST /admin_story_poll_vote.php — vote once on a story poll.
  Future<StoryPoll> voteStoryPoll({
    required int storyId,
    required int pollId,
    required String optionId,
  }) async {
    final uri = Uri.parse('$baseUrl/admin_story_poll_vote.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'story_id': storyId,
        'poll_id': pollId,
        'option_id': optionId,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final poll = map['poll'] as Map<String, dynamic>?;
    if (poll == null) {
      throw Exception(map['error']?.toString() ?? 'Poll vote failed');
    }
    return StoryPoll.fromJson(poll);
  }

  /// GET /admin_story_audience.php?story_id= — admin viewers/likers.
  Future<StoryAudienceSummary> fetchStoryAudience(int storyId) async {
    final uri = Uri.parse(
      '$baseUrl/admin_story_audience.php',
    ).replace(queryParameters: {'story_id': '$storyId'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return StoryAudienceSummary.fromJson(map);
  }

  // ── Teacher panel (requires is_teacher on server) ───────────────────────────

  /// GET /teacher_students.php — [inbox] adds unread + last activity and server sort.
  Future<List<TeacherStudentSummary>> fetchTeacherStudents({
    bool inbox = false,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/teacher_students.php',
    ).replace(queryParameters: inbox ? const {'inbox': '1'} : null);
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['students'] as List<dynamic>? ?? const [];
    return list
        .map((e) => TeacherStudentSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /teacher_student_vocab_results.php
  Future<List<VocabQuizResultSummary>> fetchTeacherStudentVocabResults(
    int studentId, {
    int limit = 100,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/teacher_student_vocab_results.php',
    ).replace(queryParameters: {'student_id': '$studentId', 'limit': '$limit'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['results'] as List<dynamic>? ?? const [];
    return list
        .map((e) => VocabQuizResultSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /teacher_student_grammar_results.php
  Future<List<GrammarResult>> fetchTeacherStudentGrammarResults(
    int studentId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/teacher_student_grammar_results.php',
    ).replace(queryParameters: {'student_id': '$studentId'});
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
    final uri = Uri.parse(
      '$baseUrl/teacher_student_sessions.php',
    ).replace(queryParameters: {'student_id': '$studentId'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  TeacherSessionInfo _parseTeacherSessionInfo(Map<String, dynamic> map) {
    final rawList = map['sessions'] as List<dynamic>? ?? const [];
    final sessions = rawList
        .map((e) => ClassSessionEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawTerms = map['terms'] as List<dynamic>? ?? const [];
    final terms = rawTerms
        .map((e) => ClassSessionTerm.fromJson(e as Map<String, dynamic>))
        .toList();
    final usesTermsTable = map.containsKey('terms');
    final fallbackCount = (map['session_count'] as num?)?.toInt() ?? 0;
    final count = sessions.isNotEmpty ? sessions.length : fallbackCount;
    final u = map['updated_at']?.toString();
    final rawNote = map['note']?.toString();
    return TeacherSessionInfo(
      sessionCount: count,
      updatedAt: (u != null && u.isNotEmpty) ? u : null,
      note: (rawNote != null && rawNote.trim().isNotEmpty) ? rawNote : null,
      sessions: sessions,
      terms: terms,
      usesTermsTable: usesTermsTable,
    );
  }

  /// POST — append one class session (`add_session` on server).
  /// When the server has terms migrated, pass [termId]; otherwise omit for legacy installs.
  Future<TeacherSessionInfo> addTeacherClassSession({
    required int studentId,
    int? termId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final body = <String, dynamic>{
      'student_id': studentId,
      'add_session': true,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (termId != null) {
      body['term_id'] = termId;
    }
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  Future<TeacherSessionInfo> addTeacherStudentTerm({
    required int studentId,
    required int sessionCap,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'add_term': true,
        'session_cap': sessionCap,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  Future<TeacherSessionInfo> updateTeacherStudentTerm({
    required int studentId,
    required int termId,
    required int sessionCap,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'update_term': true,
        'term_id': termId,
        'session_cap': sessionCap,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  Future<TeacherSessionInfo> deleteTeacherStudentTerm({
    required int studentId,
    required int termId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'student_id': studentId, 'delete_term_id': termId}),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  Future<TeacherSessionInfo> setTeacherTermPayment({
    required int studentId,
    required int termId,
    required bool isPaid,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'set_term_payment': true,
        'term_id': termId,
        'is_paid': isPaid,
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

  /// POST — delete one class session row by server id.
  Future<TeacherSessionInfo> deleteTeacherClassSession({
    required int studentId,
    required int sessionId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'delete_session_id': sessionId,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTeacherSessionInfo(map);
  }

  /// POST — change [recordedAt] for an existing session.
  /// [recordedAt] is the calendar date and clock time on the device; sent as a UTC instant (ISO8601 Z).
  Future<TeacherSessionInfo> updateTeacherClassSessionTime({
    required int studentId,
    required int sessionId,
    required DateTime recordedAt,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_sessions.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'update_session': true,
        'session_id': sessionId,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
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

  List<ClassScheduleSlot> _parseScheduleSlots(Map<String, dynamic> map) {
    final raw = map['slots'] as List<dynamic>? ?? const [];
    return raw
        .map((e) => ClassScheduleSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /teacher_student_schedule.php?student_id=
  Future<List<ClassScheduleSlot>> fetchTeacherStudentSchedule(
    int studentId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/teacher_student_schedule.php',
    ).replace(queryParameters: {'student_id': '$studentId'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleSlots(map);
  }

  /// GET /my_class_schedule.php — learner: weekly slots for this account.
  Future<List<ClassScheduleSlot>> fetchMyClassSchedule() async {
    final uri = Uri.parse('$baseUrl/my_class_schedule.php');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleSlots(map);
  }

  Future<List<ClassScheduleSlot>> addTeacherScheduleSlot({
    required int studentId,
    required int weekday,
    required String startTimeHm,
    String? endTimeHm,
    String? label,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_schedule.php');
    final body = <String, dynamic>{
      'student_id': studentId,
      'add_schedule_slot': true,
      'weekday': weekday,
      'start_time': startTimeHm,
    };
    if (endTimeHm != null && endTimeHm.isNotEmpty) {
      body['end_time'] = endTimeHm;
    }
    if (label != null && label.trim().isNotEmpty) {
      body['label'] = label.trim();
    }
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleSlots(map);
  }

  Future<List<ClassScheduleSlot>> updateTeacherScheduleSlot({
    required int studentId,
    required int slotId,
    required int weekday,
    required String startTimeHm,
    String? endTimeHm,
    String? label,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_schedule.php');
    final body = <String, dynamic>{
      'student_id': studentId,
      'update_schedule_slot': true,
      'slot_id': slotId,
      'weekday': weekday,
      'start_time': startTimeHm,
      'end_time': endTimeHm,
      'label': label,
    };
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleSlots(map);
  }

  Future<List<ClassScheduleSlot>> deleteTeacherScheduleSlot({
    required int studentId,
    required int slotId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_schedule.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'student_id': studentId,
        'delete_schedule_slot_id': slotId,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleSlots(map);
  }

  List<TemporaryClassScheduleSlot> _parseTemporaryScheduleSlots(
    Map<String, dynamic> map,
  ) {
    final raw = map['slots'] as List<dynamic>? ?? const [];
    return raw
        .map(
          (e) => TemporaryClassScheduleSlot.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// GET /teacher_temporary_schedule.php — one-off classes for the schedule tab.
  Future<List<TemporaryClassScheduleSlot>>
  fetchTeacherTemporarySchedule() async {
    final uri = Uri.parse('$baseUrl/teacher_temporary_schedule.php');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTemporaryScheduleSlots(map);
  }

  /// Adds a one-off temporary class. [startAt] is sent as UTC and displayed local.
  Future<List<TemporaryClassScheduleSlot>> addTeacherTemporaryScheduleSlot({
    required int studentId,
    required DateTime startAt,
    String? label,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_temporary_schedule.php');
    final body = <String, dynamic>{
      'student_id': studentId,
      'add_temporary_slot': true,
      'start_at': startAt.toUtc().toIso8601String(),
      'duration_minutes': 60,
    };
    if (label != null && label.trim().isNotEmpty) {
      body['label'] = label.trim();
    }
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTemporaryScheduleSlots(map);
  }

  Future<List<TemporaryClassScheduleSlot>> updateTeacherTemporaryScheduleSlot({
    required int slotId,
    required int studentId,
    required DateTime startAt,
    String? label,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_temporary_schedule.php');
    final body = <String, dynamic>{
      'slot_id': slotId,
      'student_id': studentId,
      'update_temporary_slot': true,
      'start_at': startAt.toUtc().toIso8601String(),
      'duration_minutes': 60,
      'label': label?.trim(),
    };
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(body),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTemporaryScheduleSlots(map);
  }

  Future<List<TemporaryClassScheduleSlot>> deleteTeacherTemporaryScheduleSlot({
    required int slotId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_temporary_schedule.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({'delete_temporary_slot_id': slotId}),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTemporaryScheduleSlots(map);
  }

  ScheduleAttendanceState _parseScheduleAttendanceState(
    Map<String, dynamic> map,
  ) {
    return ScheduleAttendanceState.fromJson(map);
  }

  Future<ScheduleAttendanceState> processTeacherScheduleAttendance({
    required List<ScheduleAttendanceDueOccurrence> occurrences,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_schedule_attendance.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'process_due': true,
        'occurrences': occurrences.map((e) => e.toJson()).toList(),
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleAttendanceState(map);
  }

  Future<ScheduleAttendanceState> setTeacherScheduleAttendanceMode({
    required int studentId,
    required ScheduleAttendanceMode mode,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_schedule_attendance.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'set_mode': true,
        'student_id': studentId,
        'mode': mode.apiValue,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleAttendanceState(map);
  }

  Future<ScheduleAttendanceState> resolveTeacherSchedulePendingOccurrence({
    required int occurrenceId,
    required bool didHappen,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_schedule_attendance.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'resolve_occurrence': true,
        'occurrence_id': occurrenceId,
        'did_happen': didHappen,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseScheduleAttendanceState(map);
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
  Future<TeacherMessagesUnreadSummary>
  fetchTeacherMessagesUnreadSummary() async {
    final uri = Uri.parse(
      '$baseUrl/teacher_student_messages.php',
    ).replace(queryParameters: const {'summary': '1'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return TeacherMessagesUnreadSummary.fromJson(map);
  }

  /// GET /teacher_student_messages.php?preview=1 — auth; empty preview if no teacher.
  Future<TeacherMessagesPreview> fetchTeacherMessagesPreview() async {
    final uri = Uri.parse(
      '$baseUrl/teacher_student_messages.php',
    ).replace(queryParameters: const {'preview': '1'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return TeacherMessagesPreview.fromJson(map);
  }

  /// GET /teacher_student_messages.php — full thread (teacher: student_id; learner: peer_teacher_id).
  Future<TeacherMessagesThread> fetchTeacherMessages({
    int? studentId,
    int? peerTeacherId,
  }) async {
    final q = <String, String>{};
    if (studentId != null) q['student_id'] = '$studentId';
    if (peerTeacherId != null) q['peer_teacher_id'] = '$peerTeacherId';
    final uri = Uri.parse(
      '$baseUrl/teacher_student_messages.php',
    ).replace(queryParameters: q.isEmpty ? null : q);
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return TeacherMessagesThread.fromJson(map);
  }

  /// GET ?student_peers=1 — learner: list chats (teacher + admin).
  Future<List<StudentMessagePeerRow>> fetchStudentMessagePeers() async {
    final uri = Uri.parse(
      '$baseUrl/teacher_student_messages.php',
    ).replace(queryParameters: const {'student_peers': '1'});
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final list = map['peers'] as List<dynamic>? ?? const [];
    return list
        .map((e) => StudentMessagePeerRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST mark_read — student or teacher (with student_id).
  Future<void> markTeacherMessagesRead({
    int? studentId,
    int? peerTeacherId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php');
    final body = <String, dynamic>{'mark_read': true};
    if (studentId != null) body['student_id'] = studentId;
    if (peerTeacherId != null) body['peer_teacher_id'] = peerTeacherId;
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
    int? peerTeacherId,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php');
    final body = <String, dynamic>{'body': text.trim()};
    if (studentId != null) body['student_id'] = studentId;
    if (peerTeacherId != null) body['peer_teacher_id'] = peerTeacherId;
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

  /// POST edit — rewrites an own message that the recipient has not read yet.
  ///
  /// Throws [TeacherMessageAlreadyReadException] when the recipient already saw
  /// the message (HTTP 409 from the server), so callers can surface a friendly
  /// message ("You can't edit a read message").
  Future<TeacherMessageRow> editTeacherMessage({
    required int messageId,
    required String newBody,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher_student_messages.php');
    final payload = <String, dynamic>{
      'edit': true,
      'message_id': messageId,
      'body': newBody.trim(),
    };
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 409) {
      throw const TeacherMessageAlreadyReadException();
    }
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final m = map['message'] as Map<String, dynamic>?;
    if (m == null) {
      throw Exception(map['error']?.toString() ?? 'Edit failed');
    }
    return TeacherMessageRow.fromJson(m);
  }

  /// POST /update_profile.php — requires [authToken].
  Future<AuthUser> updateProfile({
    required String displayName,
    required String bio,
    required String avatar,
  }) async {
    final uri = Uri.parse('$baseUrl/update_profile.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'display_name': displayName,
        'bio': bio,
        'avatar': avatar,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    await bustGrammarResultsListCaches();
    return AuthUser.fromJson(map['user'] as Map<String, dynamic>);
  }

  /// POST /change_password.php — requires [authToken].
  ///
  /// On success other devices are signed out; this session stays valid.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/change_password.php');
    final response = await http.post(
      uri,
      headers: _mergeHeaders({
        'Content-Type': 'application/json; charset=utf-8',
      }),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    final code = response.statusCode;
    Map<String, dynamic>? map;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      }
    } catch (_) {}

    if (code >= 200 && code < 300 && map?['ok'] == true) {
      return;
    }

    if (code == 401) {
      throw UnauthorizedException(map?['error']?.toString() ?? 'Unauthorized');
    }

    final errorCode = map?['error_code']?.toString().trim();
    if (errorCode != null && errorCode.isNotEmpty) {
      throw Exception(errorCode);
    }
    final msg = map?['error']?.toString().trim();
    if (msg != null && msg.isNotEmpty) {
      throw Exception(msg);
    }
    _throwFromJsonBody(response);
  }

  /// Clears disk cache for GET [uri] so the next request uses the network.
  Future<void> bustHttpCacheForUri(Uri uri) async {
    await ApiDiskCache.instance.remove(_httpCacheKey(uri));
  }

  /// Drops every persisted GET body (books, units, sections, grammar lists, quiz lists,
  /// user vocab marks, …). Use with a global UI refresh so providers refetch from network.
  Future<void> bustAllHttpGetDiskCache() async {
    await ApiDiskCache.instance.clearAll();
  }

  /// Busts `books.php` caches for catalog + optional search (both scopes), matching [fetchBooks] / [searchBooks].
  Future<void> bustBooksCatalogCache({String? searchQuery}) async {
    final q = searchQuery?.trim() ?? '';
    await bustHttpCacheForUri(
      Uri.parse(
        '$baseUrl/books.php',
      ).replace(queryParameters: {'scope': 'public'}),
    );
    await bustHttpCacheForUri(
      Uri.parse(
        '$baseUrl/books.php',
      ).replace(queryParameters: {'scope': 'student'}),
    );
    if (q.isNotEmpty) {
      await bustHttpCacheForUri(
        Uri.parse(
          '$baseUrl/books.php',
        ).replace(queryParameters: {'search': q, 'scope': 'public'}),
      );
      await bustHttpCacheForUri(
        Uri.parse(
          '$baseUrl/books.php',
        ).replace(queryParameters: {'search': q, 'scope': 'student'}),
      );
    }
  }

  Future<void> bustUnitsCache(int bookId) async {
    await bustHttpCacheForUri(Uri.parse('$baseUrl/units.php?book_id=$bookId'));
  }

  Future<void> bustGrammarTopicsCache() async {
    await bustHttpCacheForUri(Uri.parse('$baseUrl/grammar_topics.php'));
  }

  /// Clears GET caches for grammar result lists ([fetchPublicGrammarResultsPage] / [fetchMyGrammarResults] defaults).
  Future<void> bustGrammarResultsListCaches() async {
    await bustHttpCacheForUri(
      Uri.parse(
        '$baseUrl/grammar_results_public.php',
      ).replace(queryParameters: const {'sort': 'date', 'order': 'desc'}),
    );
    for (final sort in const ['date', 'practice']) {
      for (var off = 0; off <= 360; off += 30) {
        await bustHttpCacheForUri(
          Uri.parse('$baseUrl/grammar_results_public.php').replace(
            queryParameters: <String, String>{
              'sort': sort,
              'order': 'desc',
              'limit': '30',
              'offset': '$off',
            },
          ),
        );
      }
    }
    await bustHttpCacheForUri(
      Uri.parse(
        '$baseUrl/grammar_results_my.php',
      ).replace(queryParameters: const {'sort': 'date', 'order': 'desc'}),
    );
  }

  /// GET [vocab_quiz_results_my.php] list cache — bust after submit or when forcing refresh.
  Future<void> bustVocabQuizResultsMyCache({
    int? bookId,
    int limit = 100,
  }) async {
    final q = <String, String>{'limit': '$limit'};
    if (bookId != null) {
      q['book_id'] = '$bookId';
    }
    await bustHttpCacheForUri(
      Uri.parse(
        '$baseUrl/vocab_quiz_results_my.php',
      ).replace(queryParameters: q),
    );
  }

  /// Clears [fetchUserVocabMarks] disk cache so the next pull matches server after add/remove.
  Future<void> bustUserVocabMarksCache({String? kind}) async {
    if (kind != null) {
      await bustHttpCacheForUri(
        Uri.parse(
          '$baseUrl/user_vocab_marks.php',
        ).replace(queryParameters: {'kind': kind}),
      );
      return;
    }
    await bustHttpCacheForUri(
      Uri.parse(
        '$baseUrl/user_vocab_marks.php',
      ).replace(queryParameters: const {'kind': 'favorite'}),
    );
    await bustHttpCacheForUri(
      Uri.parse(
        '$baseUrl/user_vocab_marks.php',
      ).replace(queryParameters: const {'kind': 'important'}),
    );
  }

  void _assertAuthResponse(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      return;
    }
    if (code == 401) {
      throw UnauthorizedException(_errorMessageFromBody(response));
    }
    _throwFromJsonBody(response);
  }

  void _throwFromJsonBody(http.Response response) {
    final msg =
        _errorMessageFromBody(response) ?? 'HTTP ${response.statusCode}';
    throw Exception(msg);
  }

  /// Best-effort decode of a server `{"error":"..."}` payload; returns null
  /// when the body isn't a JSON object with an error message.
  String? _errorMessageFromBody(http.Response response) {
    try {
      final m = jsonDecode(response.body) as Map<String, dynamic>?;
      final e = m?['error'] as String?;
      if (e != null && e.isNotEmpty) return e;
    } catch (_) {}
    return null;
  }

  void _assertOk(http.Response response, String resource) {
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch $resource (HTTP ${response.statusCode})',
      );
    }
  }
}
