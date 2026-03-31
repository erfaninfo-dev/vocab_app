import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';

import '../models/vocab_entry.dart';
import '../services/vocabulary_parser.dart';

class VocabularyRepository {
  VocabularyRepository({required this.assetPath, VocabularyParser? parser})
    : _parser = parser ?? const VocabularyParser();

  final String assetPath;
  final VocabularyParser _parser;

  Future<List<VocabEntry>> loadEntries() async {
    if (assetPath.endsWith('.xlsx') || assetPath.endsWith('.xls')) {
      return _loadFromExcel();
    }
    return _loadFromJson();
  }

  Future<List<VocabEntry>> _loadFromJson() async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Vocabulary dataset must be a JSON list.');
    }
    return _parser.parseRows(decoded, bookId: assetPath);
  }

  Future<List<VocabEntry>> _loadFromExcel() async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    final excel = Excel.decodeBytes(bytes);

    final sheetName =
        excel.tables.keys.isEmpty ? null : excel.tables.keys.first;
    if (sheetName == null) {
      throw FormatException('No sheets found in: $assetPath');
    }

    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      throw FormatException('Empty sheet in: $assetPath');
    }

    final header = sheet.rows.first.map(_cellToString).toList();
    final rows = <Map<String, dynamic>>[];

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => _cellToString(cell).trim().isEmpty)) continue;

      final map = <String, dynamic>{};
      for (var c = 0; c < header.length; c++) {
        final key = header[c].trim();
        if (key.isEmpty) continue;
        final cell = c < row.length ? row[c] : null;
        map[key] = _cellToString(cell).trim();
      }
      rows.add(map);
    }

    return _parser.parseRows(rows, bookId: assetPath);
  }

  static String _cellToString(Data? data) =>
      data?.value?.toString() ?? '';
}
