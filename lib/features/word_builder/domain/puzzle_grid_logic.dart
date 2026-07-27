import '../word_builder_campaign_constants.dart';
import 'word_builder_game_logic.dart';
import 'word_builder_models.dart';

enum PuzzleCellKind { letter, spare, block }

/// Row-major grid: each row spells one target word (left → right).
///
/// Letter homes: cols `0 .. rowWordLengths[r]-1`.
/// One spare cell at bottom of the extra column holds the sliding gap.
/// All other non-letter cells are immovable blocks.
class PuzzleGridLayout {
  const PuzzleGridLayout({required this.rowWordLengths});

  final List<int> rowWordLengths;

  int get rowCount => rowWordLengths.length;

  int get letterCols =>
      rowWordLengths.isEmpty ? 0 : rowWordLengths.reduce((a, b) => a > b ? a : b);

  int get totalCols => letterCols + 1;

  int get totalCells => rowCount * totalCols;

  int get letterSlotCount =>
      rowWordLengths.fold<int>(0, (sum, len) => sum + len);

  int get spareIndex => indexOf(rowCount - 1, letterCols);

  int indexOf(int row, int col) => row * totalCols + col;

  (int row, int col) coordsOf(int index) =>
      (index ~/ totalCols, index % totalCols);

  PuzzleCellKind kindAt(int index) {
    final (row, col) = coordsOf(index);
    if (col < rowWordLengths[row]) return PuzzleCellKind.letter;
    if (col < letterCols) return PuzzleCellKind.block;
    if (col == letterCols && row == rowCount - 1) return PuzzleCellKind.spare;
    return PuzzleCellKind.block;
  }

  bool isSlideable(int index) {
    final kind = kindAt(index);
    return kind == PuzzleCellKind.letter || kind == PuzzleCellKind.spare;
  }

  bool areAdjacent(int a, int b) {
    if (a == b) return false;
    final (ar, ac) = coordsOf(a);
    final (br, bc) = coordsOf(b);
    return (ar == br && (ac - bc).abs() == 1) ||
        (ac == bc && (ar - br).abs() == 1);
  }

  List<int> adjacentSlideable(int index) {
    final (r, c) = coordsOf(index);
    final out = <int>[];
    for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      final nr = r + d.$1;
      final nc = c + d.$2;
      if (nr < 0 || nr >= rowCount || nc < 0 || nc >= totalCols) continue;
      final idx = indexOf(nr, nc);
      if (isSlideable(idx)) out.add(idx);
    }
    return out;
  }

  String? readRowWord(int row, List<LetterInstance?> cells) {
    if (row < 0 || row >= rowCount) return null;
    final buf = StringBuffer();
    for (var c = 0; c < rowWordLengths[row]; c++) {
      final letter = cells[indexOf(row, c)];
      if (letter == null) return null;
      buf.write(letter.char);
    }
    return normalizeWord(buf.toString());
  }

  List<String?> readAllRowWords(List<LetterInstance?> cells) {
    return List<String?>.generate(
      rowCount,
      (row) => readRowWord(row, cells),
    );
  }

  static PuzzleGridLayout forLevel(WordBuilderLevel level) {
    final lengths = level.targetWords
        .map((t) => normalizeWord(t.word).length)
        .toList(growable: false);
    if (lengths.length != kWordBuilderCampaignWordsPerStage) {
      throw ArgumentError('Puzzle mode expects three target words.');
    }
    return PuzzleGridLayout(rowWordLengths: lengths);
  }
}
