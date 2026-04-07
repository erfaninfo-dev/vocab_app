import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/book_model.dart';
import '../models/grammar_question.dart';
import '../models/grammar_topic_summary.dart';
import '../models/unit_model.dart';
import '../models/vocab_entry.dart';

// ─── Change this to your server's base URL ───────────────────────────────────
// Example: 'https://yourdomain.com/api'
const String kApiBaseUrl = 'http://erfaninfo.com/wordsapi';

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

  // ── GET /books.php ────────────────────────────────────────────────────────
  Future<List<Book>> fetchBooks() async {
    final uri = Uri.parse('$baseUrl/books.php');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'books');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Book>> searchBooks(String query) async {
    final uri = Uri.parse('$baseUrl/books.php?search=$query');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'books search');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /units.php?book_id={id} ───────────────────────────────────────────
  Future<List<UnitInfo>> fetchUnits(int bookId) async {
    final uri = Uri.parse('$baseUrl/units.php?book_id=$bookId');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'units');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => UnitInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /sections.php?book_id={id}&unit={unit} ────────────────────────────
  Future<List<int>> fetchSections(int bookId, int unit) async {
    final uri = Uri.parse('$baseUrl/sections.php?book_id=$bookId&unit=$unit');
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'sections');
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
    final response = await http.get(Uri.parse(uriStr), headers: _mergeHeaders());
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
    final response = await http.get(uri, headers: _mergeHeaders());
    _assertOk(response, 'grammar topics');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => GrammarTopicSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /grammar_questions.php?topic=... ─────────────────────────────────
  Future<List<GrammarQuestion>> fetchGrammarQuestions(String topic) async {
    final uri = Uri.parse('$baseUrl/grammar_questions.php').replace(
      queryParameters: {'topic': topic},
    );
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
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
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
  }) async {
    final uri = Uri.parse('$baseUrl/register.php');
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
    };
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      body['display_name'] = dn;
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
      body: jsonEncode({
        'display_name': displayName,
        'avatar': avatar,
      }),
    );
    _assertAuthResponse(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(map['user'] as Map<String, dynamic>);
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
