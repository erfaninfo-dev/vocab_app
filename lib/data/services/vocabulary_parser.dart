import '../models/vocab_entry.dart';

class VocabularyParser {
  const VocabularyParser();

  List<VocabEntry> parseRows(List<dynamic> rows, {required String bookId}) {
    final unitMapping = _detectUnitMapping(rows);
    final parsed = <VocabEntry>[];

    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        continue;
      }

      final word = _readString(row, ['Word', 'word']);
      final unitRaw = _readString(row, ['Unit', 'unit']);
      if (word.isEmpty || unitRaw.isEmpty) {
        continue;
      }

      final pair = _parseUnitAndSection(unitRaw, unitMapping);
      if (pair == null) {
        continue;
      }

      parsed.add(
        VocabEntry(
          bookId: bookId,
          word: word,
          type: _readString(row, ['type', 'Type']),
          meaningEn: _readString(row, [
            'meaning_en',
            'meaningEn',
            'meaning_en_us',
            'meaning',
          ]),
          meaningFa: _readString(row, [
            'meaning_fa',
            'meaningFa',
            'fa_meaning',
            'meaning_farsi',
          ]),
          exampleEn: _readString(row, [
            'English Example',
            'english_example',
            'example_en',
            'exampleEn',
            'example',
            'Example',
          ]),
          exampleFa: _readString(row, [
            'Persian Translation',
            'persian_translation',
            'example_fa',
            'exampleFa',
            'example_translation_fa',
          ]),
          unit: pair.$1,
          section: pair.$2,
        ),
      );
    }

    parsed.sort((a, b) {
      final byUnit = a.unit.compareTo(b.unit);
      if (byUnit != 0) {
        return byUnit;
      }
      final bySection = (a.section ?? 0).compareTo(b.section ?? 0);
      if (bySection != 0) {
        return bySection;
      }
      return a.word.toLowerCase().compareTo(b.word.toLowerCase());
    });

    return parsed;
  }

  _UnitMapping _detectUnitMapping(List<dynamic> rows) {
    var unitSectionScore = 0;
    var sectionUnitScore = 0;

    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final unitRaw = _readString(row, ['Unit', 'unit']);
      if (unitRaw.isEmpty) {
        continue;
      }
      final pair = _extractPair(unitRaw);
      if (pair == null) {
        continue;
      }
      final first = pair.$1;
      final second = pair.$2;

      if (_isSection(first) && second >= 1) {
        sectionUnitScore++;
      }
      if (_isSection(second) && first >= 1) {
        unitSectionScore++;
      }
    }

    return unitSectionScore >= sectionUnitScore
        ? _UnitMapping.unitSection
        : _UnitMapping.sectionUnit;
  }

  (int, int)? _parseUnitAndSection(String raw, _UnitMapping mapping) {
    final pair = _extractPair(raw);
    if (pair == null) {
      return null;
    }

    final first = pair.$1;
    final second = pair.$2;

    final unit = mapping == _UnitMapping.unitSection ? first : second;
    final section = mapping == _UnitMapping.unitSection ? second : first;

    if (unit < 1 || !_isSection(section)) {
      return null;
    }
    return (unit, section);
  }

  (int, int)? _extractPair(String raw) {
    final normalized = _normalizeDigits(raw).replaceAll(RegExp(r'\s+'), '');
    final match = RegExp(r'^(\d+)\D+(\d+)$').firstMatch(normalized);
    if (match == null) {
      return null;
    }
    final first = int.tryParse(match.group(1)!);
    final second = int.tryParse(match.group(2)!);
    if (first == null || second == null) {
      return null;
    }
    return (first, second);
  }

  bool _isSection(int value) => value >= 1 && value <= 3;

  String _normalizeDigits(String input) {
    const faDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arDigits = '٠١٢٣٤٥٦٧٨٩';
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result
          .replaceAll(faDigits[i], '$i')
          .replaceAll(arDigits[i], '$i');
    }
    return result;
  }

  String _readString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }
}

enum _UnitMapping { unitSection, sectionUnit }
