import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/word_builder_game_notifier.dart';
import '../../../domain/puzzle_grid_logic.dart';
import '../../../domain/word_builder_game_logic.dart';
import '../../../domain/word_builder_models.dart';

/// Sliding letter grid where each row spells one target word (left → right).
class PuzzleLetterBoard extends ConsumerStatefulWidget {
  const PuzzleLetterBoard({
    super.key,
    required this.bookKey,
    required this.level,
    required this.letters,
  });

  final int bookKey;
  final WordBuilderLevel level;
  final List<LetterInstance> letters;

  @override
  ConsumerState<PuzzleLetterBoard> createState() => _PuzzleLetterBoardState();
}

class _PuzzleLetterBoardState extends ConsumerState<PuzzleLetterBoard> {
  late PuzzleGridLayout _layout;
  List<LetterInstance?> _cells = const [];
  int _emptyIndex = 0;
  String? _layoutSig;
  bool _busy = false;
  final Set<int> _frozenRows = <int>{};
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _layout = PuzzleGridLayout.forLevel(widget.level);
    _applyRebuild(force: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(wordBuilderGameProvider(widget.bookKey).notifier)
            .preparePhysicsLetterMode(),
      );
    });
  }

  @override
  void didUpdateWidget(covariant PuzzleLetterBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final levelChanged = oldWidget.level.levelId != widget.level.levelId ||
        !_sameTargets(oldWidget.level, widget.level);
    if (levelChanged) {
      _layout = PuzzleGridLayout.forLevel(widget.level);
      _rebuildFromLevel(force: true);
      return;
    }
    // Ignore mid-level letter-instance rebuilds (new ids / shuffle). The board
    // owns tile positions until the level changes.
  }

  bool _sameTargets(WordBuilderLevel a, WordBuilderLevel b) {
    if (a.targetWords.length != b.targetWords.length) return false;
    for (var i = 0; i < a.targetWords.length; i++) {
      if (normalizeWord(a.targetWords[i].word) !=
          normalizeWord(b.targetWords[i].word)) {
        return false;
      }
    }
    return true;
  }

  String _sigFor(WordBuilderLevel level, List<LetterInstance> letters) {
    final words = level.targetWords.map((t) => normalizeWord(t.word)).join('|');
    final ids = letters.map((e) => '${e.id}:${e.char}').join(',');
    return '$words#$ids';
  }

  void _rebuildFromLevel({required bool force}) {
    if (!mounted) {
      _applyRebuild(force: force);
      return;
    }
    setState(() => _applyRebuild(force: force));
  }

  void _applyRebuild({required bool force}) {
    final sig = _sigFor(widget.level, widget.letters);
    if (!force && _layoutSig == sig && _cells.isNotEmpty) return;

    final solvedLayout = _buildSolvedCells(widget.level, widget.letters);
    if (solvedLayout == null) {
      _layoutSig = sig;
      _cells = List<LetterInstance?>.filled(_layout.totalCells, null);
      _emptyIndex = _layout.spareIndex;
      return;
    }

    var cells = solvedLayout;
    var empty = _layout.spareIndex;
    final scrambleSteps = math.max(24, _layout.letterSlotCount * 6);
    for (var i = 0; i < scrambleSteps; i++) {
      final neighbors = _layout.adjacentSlideable(empty);
      if (neighbors.isEmpty) break;
      final pick = neighbors[_random.nextInt(neighbors.length)];
      cells = List<LetterInstance?>.of(cells);
      cells[empty] = cells[pick];
      cells[pick] = null;
      empty = pick;
    }

    _layoutSig = sig;
    _cells = cells;
    _emptyIndex = empty;
    _frozenRows.clear();
  }

  List<LetterInstance?>? _buildSolvedCells(
    WordBuilderLevel level,
    List<LetterInstance> letters,
  ) {
    if (letters.length < _layout.letterSlotCount) return null;

    final byChar = <String, List<LetterInstance>>{};
    for (final letter in letters) {
      byChar.putIfAbsent(letter.char.toLowerCase(), () => []).add(letter);
    }

    final cells = List<LetterInstance?>.filled(_layout.totalCells, null);
    for (var row = 0; row < _layout.rowCount; row++) {
      final word = normalizeWord(level.targetWords[row].word);
      for (var col = 0; col < word.length; col++) {
        final ch = word[col];
        final pool = byChar[ch];
        if (pool == null || pool.isEmpty) return null;
        cells[_layout.indexOf(row, col)] = pool.removeLast();
      }
    }
    return cells;
  }

  bool _isFrozenIndex(int index) {
    final (row, col) = _layout.coordsOf(index);
    if (col >= _layout.rowWordLengths[row]) return false;
    return _frozenRows.contains(row);
  }

  Future<void> _onCellTap(int index) async {
    if (_busy || _cells[index] == null) return;
    if (!_layout.isSlideable(index)) return;
    if (_isFrozenIndex(index)) {
      HapticFeedback.selectionClick();
      return;
    }
    if (!_layout.areAdjacent(index, _emptyIndex)) {
      HapticFeedback.selectionClick();
      return;
    }
    final neighbors = _layout
        .adjacentSlideable(_emptyIndex)
        .where((i) => !_isFrozenIndex(i))
        .toList();
    if (!neighbors.contains(index)) {
      HapticFeedback.selectionClick();
      return;
    }

    final game = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (game == null || game.trayInputBlocked) return;

    _busy = true;
    setState(() {
      _cells[_emptyIndex] = _cells[index];
      _cells[index] = null;
      _emptyIndex = index;
    });
    HapticFeedback.lightImpact();

    try {
      final solvedRows = await ref
          .read(wordBuilderGameProvider(widget.bookKey).notifier)
          .evaluatePuzzleRows(_layout.readAllRowWords(_cells));
      if (mounted && solvedRows.isNotEmpty) {
        setState(() => _frozenRows.addAll(solvedRows));
      }
    } finally {
      if (mounted) _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(wordBuilderGameProvider(widget.bookKey), (prev, next) {
      final p = prev?.valueOrNull;
      final n = next.valueOrNull;
      if (p == null || n == null) return;
      if (p.level.levelId != n.level.levelId ||
          !_sameTargets(p.level, n.level)) {
        _layout = PuzzleGridLayout.forLevel(n.level);
        _rebuildFromLevel(force: true);
      }
    });

    final game = ref.watch(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (game == null || widget.letters.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_cells.isEmpty) {
      _rebuildFromLevel(force: true);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = (constraints.maxWidth * 0.018).clamp(4.0, 8.0);
        final pad = (constraints.maxWidth * 0.02).clamp(6.0, 12.0);
        final innerW = constraints.maxWidth - pad * 2;
        final innerH = constraints.maxHeight - pad * 2 - 28;
        final cellSide = math.min(
          (innerW - gap * (_layout.totalCols - 1)) / _layout.totalCols,
          (innerH - gap * (_layout.rowCount - 1)) / _layout.rowCount,
        );
        final boardW =
            cellSide * _layout.totalCols + gap * (_layout.totalCols - 1);
        final boardH =
            cellSide * _layout.rowCount + gap * (_layout.rowCount - 1);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF3E2723),
                              const Color(0xFF263238),
                            ]
                          : [
                              const Color(0xFFFFF8E1),
                              const Color(0xFFFFECB3),
                            ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.75),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.12,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: SizedBox(
                      width: boardW,
                      height: boardH,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _layout.totalCols,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                        ),
                        itemCount: _cells.length,
                        itemBuilder: (context, index) {
                          final kind = _layout.kindAt(index);
                          if (kind == PuzzleCellKind.block) {
                            return const SizedBox.shrink();
                          }
                          final letter = _cells[index];
                          final (row, _) = _layout.coordsOf(index);
                          final rowSolved = _frozenRows.contains(row);
                          if (letter == null) {
                            return _EmptyPuzzleCell(
                              isDarkSquare: _isDarkSquare(index),
                              isDarkTheme: isDark,
                            );
                          }
                          return _PuzzleLetterTile(
                            letter: letter,
                            size: cellSide,
                            isDarkSquare: _isDarkSquare(index),
                            isDarkTheme: isDark,
                            selected: rowSolved,
                            wrong: false,
                            enabled: !_busy &&
                                !game.trayInputBlocked &&
                                !rowSolved,
                            onTap: () => unawaited(_onCellTap(index)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(
                l10n.wordBuilderPuzzleSlideHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isDarkSquare(int index) {
    final (r, c) = _layout.coordsOf(index);
    return (r + c).isOdd;
  }
}

class _EmptyPuzzleCell extends StatelessWidget {
  const _EmptyPuzzleCell({
    required this.isDarkSquare,
    required this.isDarkTheme,
  });

  final bool isDarkSquare;
  final bool isDarkTheme;

  @override
  Widget build(BuildContext context) {
    final base = isDarkSquare
        ? (isDarkTheme ? const Color(0xFF37474F) : const Color(0xFFD7CCC8))
        : (isDarkTheme ? const Color(0xFF455A64) : const Color(0xFFEFEBE9));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: base.withValues(alpha: isDarkTheme ? 0.55 : 0.65),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.space_bar_rounded,
          size: 22,
          color: Colors.black.withValues(alpha: isDarkTheme ? 0.18 : 0.12),
        ),
      ),
    );
  }
}

class _PuzzleLetterTile extends StatelessWidget {
  const _PuzzleLetterTile({
    required this.letter,
    required this.size,
    required this.isDarkSquare,
    required this.isDarkTheme,
    required this.selected,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  final LetterInstance letter;
  final double size;
  final bool isDarkSquare;
  final bool isDarkTheme;
  final bool selected;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lightSquare =
        isDarkTheme ? const Color(0xFF546E7A) : const Color(0xFFFFF3E0);
    final darkSquare =
        isDarkTheme ? const Color(0xFF455A64) : const Color(0xFFFFE0B2);
    var face = isDarkSquare ? darkSquare : lightSquare;
    if (selected && !wrong) {
      face = isDarkTheme ? const Color(0xFF33691E) : const Color(0xFFC8E6C9);
    }
    if (wrong) {
      face = isDarkTheme ? const Color(0xFF4E342E) : const Color(0xFFFFCDD2);
    }

    final borderColor = wrong
        ? const Color(0xFFD32F2F)
        : selected
        ? const Color(0xFF2E7D32)
        : const Color(0xFFFFB300).withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: face,
            border: Border.all(color: borderColor, width: selected ? 2.4 : 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDarkTheme ? 0.28 : 0.14,
                ),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter.char.toUpperCase(),
              style: GoogleFonts.fredoka(
                fontSize: (size * 0.46).clamp(18.0, 34.0),
                fontWeight: FontWeight.w700,
                color: wrong
                    ? const Color(0xFFB71C1C)
                    : isDarkTheme
                    ? const Color(0xFFFFF8E1)
                    : const Color(0xFF5D4037),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
