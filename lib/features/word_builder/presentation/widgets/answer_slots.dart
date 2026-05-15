import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../word_builder_session_ambience.dart';
import '../../domain/word_builder_game_logic.dart';
import '../../domain/word_builder_models.dart';

class AnswerSlotsPanel extends StatelessWidget {
  const AnswerSlotsPanel({
    super.key,
    required this.level,
    required this.solvedLower,
    required this.revealedPositions,
    this.layoutScale = 1.0,
  });

  final WordBuilderLevel level;
  final Set<String> solvedLower;
  final Map<String, Set<int>> revealedPositions;
  final double layoutScale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targets = level.targetWords;
    const accentBlue = Color(0xFF1565C0);
    final sc = layoutScale;
    final cardR = (22 * sc).clamp(16.0, 22.0);
    final glossH = (36 * sc).clamp(28.0, 40.0);
    final pad = EdgeInsets.fromLTRB(12 * sc, 11 * sc, 12 * sc, 10 * sc);
    final headStyle = sc < 0.9
        ? Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.25,
              color: scheme.onSurface,
              fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * sc,
            )
        : Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              color: scheme.onSurface,
            );

    return DecoratedBox(
      decoration: WordBuilderSessionAmbience.parchmentPanel(
        scheme: scheme,
        isDark: isDark,
        radius: cardR,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardR),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: glossH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.06 : 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: pad,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: (20 * sc).clamp(16.0, 22.0),
                        color: accentBlue,
                      ),
                      SizedBox(width: 7 * sc),
                      Expanded(
                        child: Text(
                          l10n.wordBuilderTargetsHeading,
                          style: headStyle,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withValues(alpha: 0.35),
                              blurRadius: (7 * sc).clamp(4.0, 8.0),
                              offset: Offset(0, (2 * sc).clamp(1.0, 3.0)),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: (10 * sc).clamp(8.0, 11.0),
                            vertical: (4 * sc).clamp(3.0, 5.0),
                          ),
                          child: Text(
                            '${targets.length}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize:
                                      (Theme.of(context).textTheme.labelLarge?.fontSize ??
                                              14) *
                                          sc,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (10 * sc).clamp(6.0, 12.0)),
                  for (var wi = 0; wi < targets.length; wi++) ...[
                    if (wi > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: kWordBuilderParchmentBorder.withValues(alpha: 0.25),
                      ),
                    _TargetWordRow(
                      index: wi + 1,
                      target: targets[wi],
                      solved:
                          solvedLower.contains(normalizeWord(targets[wi].word)),
                      revealed: revealedPositions[
                              normalizeWord(targets[wi].word)] ??
                          const {},
                      scheme: scheme,
                      layoutScale: sc,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetWordRow extends StatelessWidget {
  const _TargetWordRow({
    required this.index,
    required this.target,
    required this.solved,
    required this.revealed,
    required this.scheme,
    required this.layoutScale,
  });

  final int index;
  final WordBuilderTargetWord target;
  final bool solved;
  final Set<int> revealed;
  final ColorScheme scheme;
  final double layoutScale;

  @override
  Widget build(BuildContext context) {
    final chars = <String>[
      for (final r in target.word.runes) String.fromCharCode(r),
    ];
    final sc = layoutScale;
    final rowPadV = (8 * sc).clamp(5.0, 10.0);
    final badgeD = (28 * sc).clamp(24.0, 32.0);
    final idxW = (34 * sc).clamp(28.0, 40.0);

    if (solved) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: rowPadV),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF2E7D32),
              size: (22 * sc).clamp(18.0, 24.0),
            ),
            SizedBox(width: 8 * sc),
            _TargetIndexCircle(
              index: index,
              diameter: badgeD,
              layoutScale: sc,
              success: true,
            ),
            SizedBox(width: 8 * sc),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < chars.length; i++) ...[
                        if (i > 0) SizedBox(width: (6 * sc).clamp(4.0, 7.0)),
                        _SlotCell(
                          letter: chars[i].toUpperCase(),
                          scheme: scheme,
                          layoutScale: sc,
                          solvedWord: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadV),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: idxW,
            child: Center(
              child: _TargetIndexCircle(
                index: index,
                diameter: badgeD,
                layoutScale: sc,
                success: false,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < chars.length; i++) ...[
                      if (i > 0) SizedBox(width: (6 * sc).clamp(4.0, 7.0)),
                      _SlotCell(
                        letter: revealed.contains(i)
                            ? chars[i].toUpperCase()
                            : null,
                        scheme: scheme,
                        layoutScale: sc,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetIndexCircle extends StatelessWidget {
  const _TargetIndexCircle({
    required this.index,
    required this.diameter,
    required this.layoutScale,
    required this.success,
  });

  final int index;
  final double diameter;
  final double layoutScale;
  final bool success;

  static const Color _accentBlue = Color(0xFF1565C0);
  static const Color _accentGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final sc = layoutScale;
    final accent = success ? _accentGreen : _accentBlue;
    final fs = ((Theme.of(context).textTheme.labelLarge?.fontSize ?? 13) * sc * 0.95)
        .clamp(11.0, 15.0);

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: success
            ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
            : const Color(0xFF1565C0).withValues(alpha: 0.1),
        border: Border.all(
          color: accent.withValues(alpha: success ? 0.55 : 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: (5 * sc).clamp(3.0, 6.0),
            offset: Offset(0, (1.5 * sc).clamp(1.0, 2.0)),
          ),
        ],
      ),
      child: Text(
        '$index',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
              fontSize: fs,
              height: 1,
            ),
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.letter,
    required this.scheme,
    required this.layoutScale,
    this.solvedWord = false,
  });

  final String? letter;
  final ColorScheme scheme;
  final double layoutScale;
  final bool solvedWord;

  static const Color _solvedGreenTop = Color(0xFF66BB6A);
  static const Color _solvedGreenBottom = Color(0xFF2E7D32);
  static const Color _solvedBorder = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final show = letter != null;
    final sc = layoutScale;
    final w = (32 * sc).clamp(26.0, 38.0);
    final h = (38 * sc).clamp(30.0, 44.0);
    final r = (10 * sc).clamp(8.0, 11.0);
    final fs = (Theme.of(context).textTheme.titleSmall?.fontSize ?? 15) * sc;

    final solvedStyle = solvedWord && show;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: solvedStyle
              ? _solvedBorder.withValues(alpha: 0.85)
              : show
                  ? const Color(0xFF1565C0).withValues(alpha: 0.5)
                  : kWordBuilderParchmentBorder.withValues(alpha: 0.45),
          width: show ? 1.6 : 1.1,
        ),
        gradient: solvedStyle
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_solvedGreenTop, _solvedGreenBottom],
              )
            : show
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.9),
                      scheme.primaryContainer.withValues(alpha: 0.55),
                    ],
                  )
                : null,
        color: solvedStyle
            ? null
            : show
                ? null
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        boxShadow: show
            ? [
                BoxShadow(
                  color: (solvedStyle
                          ? _solvedGreenBottom
                          : scheme.primary)
                      .withValues(alpha: solvedStyle ? 0.28 : 0.12),
                  blurRadius: (7 * sc).clamp(4.0, 8.0),
                  offset: Offset(0, (2 * sc).clamp(1.0, 3.0)),
                ),
              ]
            : null,
      ),
      child: Text(
        show ? letter! : '·',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              fontSize: fs,
              color: solvedStyle
                  ? Colors.white
                  : show
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
