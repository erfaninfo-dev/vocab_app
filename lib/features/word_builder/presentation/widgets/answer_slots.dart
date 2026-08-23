import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/word_builder_game_logic.dart';
import '../../domain/word_builder_models.dart';
import '../theme/word_builder_chapter_theme.dart';
import 'angry_words/angry_words_celebrate.dart';
import 'answer_slot_key_bag.dart';

class AnswerSlotsPanel extends ConsumerWidget {
  const AnswerSlotsPanel({
    super.key,
    required this.level,
    required this.solvedLower,
    required this.revealedPositions,
    this.layoutScale = 1.0,
    this.onSolvedWordTap,
    this.slotKeyBag,
  });

  final WordBuilderLevel level;
  final Set<String> solvedLower;
  final Map<String, Set<int>> revealedPositions;
  final double layoutScale;
  final void Function(WordBuilderTargetWord target)? onSolvedWordTap;
  final AnswerSlotKeyBag? slotKeyBag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final targets = level.targetWords;
    final sc = layoutScale;
    final celebrate = ref.watch(angryWordsSlotRevealProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var wi = 0; wi < targets.length; wi++) ...[
          if (wi > 0) SizedBox(height: (10 * sc).clamp(6.0, 14.0)),
          _TargetWordRow(
            target: targets[wi],
            solved: solvedLower.contains(normalizeWord(targets[wi].word)),
            revealed:
                revealedPositions[normalizeWord(targets[wi].word)] ?? const {},
            scheme: scheme,
            layoutScale: sc,
            onSolvedTap: onSolvedWordTap,
            slotKeyBag: slotKeyBag,
            celebrate: celebrate,
          ),
        ],
      ],
    );
  }
}

class _TargetWordRow extends StatelessWidget {
  const _TargetWordRow({
    required this.target,
    required this.solved,
    required this.revealed,
    required this.scheme,
    required this.layoutScale,
    this.onSolvedTap,
    this.slotKeyBag,
    this.celebrate,
  });

  final WordBuilderTargetWord target;
  final bool solved;
  final Set<int> revealed;
  final ColorScheme scheme;
  final double layoutScale;
  final void Function(WordBuilderTargetWord target)? onSolvedTap;
  final AnswerSlotKeyBag? slotKeyBag;
  final AngryWordsSlotReveal? celebrate;

  @override
  Widget build(BuildContext context) {
    final chars = <String>[
      for (final r in target.word.runes) String.fromCharCode(r),
    ];
    final sc = layoutScale;
    final gap = (10 * sc).clamp(8.0, 14.0);
    final norm = normalizeWord(target.word);
    final celebrating = celebrate?.wordNorm == norm;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < chars.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Builder(
                builder: (context) {
                  final arrived =
                      !celebrating || i < (celebrate?.revealedCount ?? 0);
                  final showSolved = solved && arrived;
                  return _SlotCell(
                    key: slotKeyBag?.keyFor(target.word, i),
                    letter: showSolved
                        ? chars[i].toUpperCase()
                        : revealed.contains(i) && !solved
                        ? chars[i].toUpperCase()
                        : null,
                    scheme: scheme,
                    layoutScale: sc,
                    solvedWord: showSolved,
                    hintRevealed: !solved && revealed.contains(i),
                    awaitingFlight: celebrating && solved && !arrived,
                    onTap: showSolved ? () => onSolvedTap?.call(target) : null,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    super.key,
    required this.letter,
    required this.scheme,
    required this.layoutScale,
    this.solvedWord = false,
    this.hintRevealed = false,
    this.awaitingFlight = false,
    this.onTap,
  });

  final String? letter;
  final ColorScheme scheme;
  final double layoutScale;
  final bool solvedWord;
  final bool hintRevealed;
  final bool awaitingFlight;
  final VoidCallback? onTap;

  static const Color _solvedGreenTop = Color(0xFF66BB6A);
  static const Color _solvedGreenBottom = Color(0xFF2E7D32);
  static const Color _solvedBorder = Color(0xFF1B5E20);

  static const Color _hintGreenTop = Color(0xFFC8E6C9);
  static const Color _hintGreenBottom = Color(0xFF81C784);
  static const Color _hintGreenBorder = Color(0xFF43A047);
  static const Color _hintGreenText = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final show = letter != null;
    final sc = layoutScale;
    final w = (46 * sc).clamp(40.0, 56.0);
    final h = (54 * sc).clamp(46.0, 62.0);
    final r = (14 * sc).clamp(11.0, 16.0);
    final fs = ((Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) * sc)
        .clamp(18.0, 28.0);

    final solvedStyle = solvedWord && show;
    final hintStyle = hintRevealed && show && !solvedStyle;
    final chapter = WbChapterThemeScope.maybeOf(context);
    final emptyFill = chapter != null
        ? chapter.chromeSurface.withValues(
            alpha: chapter.chromeBrightness == Brightness.dark ? 0.45 : 0.55,
          )
        : Colors.white.withValues(alpha: 0.35);
    final emptyBorder = chapter != null
        ? chapter.chromeOnSurface.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.55);
    final emptyText = chapter?.chromeOnSurface.withValues(alpha: 0.55) ??
        scheme.onSurfaceVariant.withValues(alpha: 0.5);

    final cell = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: awaitingFlight
              ? const Color(0xFFFFD54F).withValues(alpha: 0.85)
              : solvedStyle
              ? _solvedBorder.withValues(alpha: 0.85)
              : hintStyle
              ? _hintGreenBorder.withValues(alpha: 0.7)
              : emptyBorder,
          width: show || awaitingFlight ? 2.0 : 1.5,
        ),
        gradient: solvedStyle
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_solvedGreenTop, _solvedGreenBottom],
              )
            : hintStyle
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_hintGreenTop, _hintGreenBottom],
              )
            : awaitingFlight
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFF8E1).withValues(alpha: 0.55),
                  const Color(0xFFFFECB3).withValues(alpha: 0.4),
                ],
              )
            : null,
        color: solvedStyle || hintStyle || awaitingFlight ? null : emptyFill,
        boxShadow: [
          BoxShadow(
            color:
                (awaitingFlight
                        ? const Color(0xFFFFD54F)
                        : solvedStyle
                        ? _solvedGreenBottom
                        : hintStyle
                        ? _hintGreenBottom
                        : Colors.black)
                    .withValues(
                      alpha: awaitingFlight
                          ? 0.35
                          : solvedStyle
                          ? 0.32
                          : hintStyle
                          ? 0.22
                          : 0.08,
                    ),
            blurRadius: (10 * sc).clamp(6.0, 12.0),
            offset: Offset(0, (3 * sc).clamp(2.0, 4.0)),
          ),
        ],
      ),
      child: Text(
        show
            ? letter!
            : awaitingFlight
            ? ''
            : '·',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          fontSize: fs,
          color: solvedStyle
              ? Colors.white
              : hintStyle
              ? _hintGreenText
              : emptyText,
        ),
      ),
    );

    if (onTap == null) return cell;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: cell,
      ),
    );
  }
}
