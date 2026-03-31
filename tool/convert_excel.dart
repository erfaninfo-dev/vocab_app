import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stdout.writeln(
      'Usage: dart run tool/convert_excel.dart <input.xlsx> <output.json> [sheetName]',
    );
    exitCode = 64;
    return;
  }

  final inputPath = args[0];
  final outputPath = args[1];
  final sheetName = args.length > 2 ? args[2] : null;

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('Input file does not exist: $inputPath');
    exitCode = 66;
    return;
  }

  final bytes = await inputFile.readAsBytes();
  final excel = Excel.decodeBytes(bytes);
  final targetSheet = sheetName == null
      ? (excel.tables.keys.isEmpty ? null : excel.tables.keys.first)
      : excel.tables.keys.firstWhere(
          (name) => name == sheetName,
          orElse: () => '',
        );

  if (targetSheet == null || targetSheet.isEmpty) {
    stderr.writeln('No valid sheet found.');
    exitCode = 65;
    return;
  }

  final sheet = excel.tables[targetSheet];
  if (sheet == null || sheet.rows.isEmpty) {
    stderr.writeln('Sheet is empty: $targetSheet');
    exitCode = 65;
    return;
  }

  final header = sheet.rows.first.map(_cellToString).toList();
  final rows = <Map<String, dynamic>>[];
  for (var i = 1; i < sheet.rows.length; i++) {
    final row = sheet.rows[i];
    if (row.every((cell) => _cellToString(cell).trim().isEmpty)) {
      continue;
    }

    final map = <String, dynamic>{};
    for (var c = 0; c < header.length; c++) {
      final key = header[c].trim();
      if (key.isEmpty) {
        continue;
      }
      final cell = c < row.length ? row[c] : null;
      map[key] = _cellToString(cell).trim();
    }
    rows.add(map);
  }

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(rows),
    flush: true,
  );

  stdout.writeln('Converted ${rows.length} rows from "$targetSheet".');
  stdout.writeln('Saved to: $outputPath');
}

String _cellToString(Data? data) {
  return data?.value.toString() ?? '';
}
