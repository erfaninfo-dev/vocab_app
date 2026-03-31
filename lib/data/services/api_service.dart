import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book_model.dart';
import '../models/vocab_entry.dart';

// ─── Change this to your server's base URL ───────────────────────────────────
// Example: 'https://yourdomain.com/api'
const String kApiBaseUrl = 'http://erfaninfo.com/wordsapi';

class ApiService {
  const ApiService({this.baseUrl = kApiBaseUrl});

  final String baseUrl;

  // ── GET /books.php ────────────────────────────────────────────────────────
  Future<List<Book>> fetchBooks() async {
    final uri = Uri.parse('$baseUrl/books.php');
    final response = await http.get(uri);
    _assertOk(response, 'books');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /units.php?book_id={id} ───────────────────────────────────────────
  Future<List<int>> fetchUnits(int bookId) async {
    final uri = Uri.parse('$baseUrl/units.php?book_id=$bookId');
    final response = await http.get(uri);
    _assertOk(response, 'units');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => (e['unit'] as num).toInt()).toList();
  }

  // ── GET /sections.php?book_id={id}&unit={unit} ────────────────────────────
  // Returns an empty list when the unit has no sections.
  Future<List<int>> fetchSections(int bookId, int unit) async {
    final uri = Uri.parse('$baseUrl/sections.php?book_id=$bookId&unit=$unit');
    final response = await http.get(uri);
    _assertOk(response, 'sections');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => (e['section'] as num).toInt()).toList();
  }

  // ── GET /words.php?book_id={id}&unit={unit}[&section={section}] ───────────
  // If [section] is null the server returns all words for that unit
  // (used when the unit has no sections).
  Future<List<VocabEntry>> fetchWords(
    int bookId,
    int unit, {
    int? section,
  }) async {
    var uriStr = '$baseUrl/words.php?book_id=$bookId&unit=$unit';
    if (section != null) uriStr += '&section=$section';
    final response = await http.get(Uri.parse(uriStr));
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

  // ── GET /words.php?book_id={id} ───────────────────────────────────────────
  // Returns ALL words for a book (used for the Favorites screen).
  Future<List<VocabEntry>> fetchAllWordsForBook(int bookId) async {
    final uri = Uri.parse('$baseUrl/words.php?book_id=$bookId');
    final response = await http.get(uri);
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

  void _assertOk(http.Response response, String resource) {
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch $resource (HTTP ${response.statusCode})',
      );
    }
  }
}
