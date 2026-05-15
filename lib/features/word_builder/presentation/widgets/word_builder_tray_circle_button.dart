import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/word_builder_game_notifier.dart';

enum WordBuilderTrayActionKind { hint, shuffle, translate }

class _TrayActionPalette {
  const _TrayActionPalette({
    required this.accent,
    required this.container,
    required this.onAccent,
  });

  final Color accent;
  final Color container;
  final Color onAccent;
}

class _HintLampStyle {
  const _HintLampStyle._();

  static const Color rim = Color(0xFFC99400);
  static const Color brass = Color(0xFFB8860B);
  static const Color glowAmber = Color(0xFFFFB300);
  static const Color glowSoft = Color(0xFFFFE082);
  static const Color bulbSilhouette = Color(0xFF5D4037);
}

_TrayActionPalette _palette(WordBuilderTrayActionKind kind, ColorScheme scheme) {
  switch (kind) {
    case WordBuilderTrayActionKind.hint:
      return _TrayActionPalette(
        accent: _HintLampStyle.brass,
        container: const Color(0xFFFFF8E1),
        onAccent: _HintLampStyle.bulbSilhouette,
      );
    case WordBuilderTrayActionKind.shuffle:
      return _TrayActionPalette(
        accent: scheme.primary,
        container: scheme.primaryContainer,
        onAccent: scheme.onPrimaryContainer,
      );
    case WordBuilderTrayActionKind.translate:
      return _TrayActionPalette(
        accent: scheme.secondary,
        container: scheme.secondaryContainer,
        onAccent: scheme.onSecondaryContainer,
      );
  }
}

Gradient _lampFaceGradient(bool isDark) {
  return RadialGradient(
    center: const Alignment(-0.32, -0.48),
    radius: 1.05,
    colors: [
      const Color(0xFFFFFDE7),
      const Color(0xFFFFECB3),
      Color.alphaBlend(
        _HintLampStyle.glowAmber.withValues(alpha: isDark ? 0.42 : 0.28),
        const Color(0xFFFFE082),
      ),
    ],
    stops: const [0.0, 0.42, 1.0],
  );
}

List<BoxShadow> _outerGlows(
  WordBuilderTrayActionKind kind,
  _TrayActionPalette palette,
  bool isDark,
  double blurNear,
  double blurFar,
) {
  if (kind == WordBuilderTrayActionKind.hint) {
    return [
      BoxShadow(
        color: _HintLampStyle.glowAmber.withValues(alpha: isDark ? 0.52 : 0.44),
        blurRadius: blurNear * 1.15,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: _HintLampStyle.glowSoft.withValues(alpha: isDark ? 0.32 : 0.26),
        blurRadius: blurFar,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: Colors.amberAccent.withValues(alpha: isDark ? 0.14 : 0.1),
        blurRadius: blurFar * 1.25,
        spreadRadius: 2,
      ),
    ];
  }
  return [
    BoxShadow(
      color: palette.accent.withValues(alpha: isDark ? 0.58 : 0.45),
      blurRadius: blurNear,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: palette.accent.withValues(alpha: isDark ? 0.22 : 0.16),
      blurRadius: blurFar,
      spreadRadius: 1,
    ),
  ];
}

class WordBuilderTrayCircleButton extends ConsumerWidget {
  const WordBuilderTrayCircleButton({
    super.key,
    required this.bookKey,
    required this.kind,
    required this.diameter,
    required this.l10n,
  });

  final int bookKey;
  final WordBuilderTrayActionKind kind;
  final double diameter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(wordBuilderGameProvider(bookKey).notifier);
    final palette = _palette(kind, scheme);

    late final IconData icon;
    late final String tooltip;
    late final VoidCallback onTap;

    switch (kind) {
      case WordBuilderTrayActionKind.hint:
        icon = Icons.lightbulb_rounded;
        tooltip = l10n.wordBuilderHintReveal;
        onTap = () => notifier.hintRevealLetter();
        break;
      case WordBuilderTrayActionKind.shuffle:
        icon = Icons.shuffle_rounded;
        tooltip = l10n.wordBuilderShuffle;
        onTap = () => notifier.shuffleCircle();
        break;
      case WordBuilderTrayActionKind.translate:
        icon = Icons.translate_rounded;
        tooltip = l10n.wordBuilderTranslation;
        final lang = ref.watch(langProvider);
        final preferKur = lang == TranslationLang.kur;
        onTap = () => notifier.hintMeaning(preferKur: preferKur);
        break;
    }

    final d = diameter.clamp(44.0, 60.0);
    final iconSize = d * 0.44;
    final blurNear = (14 * d / 52).clamp(10.0, 18.0);
    final blurFar = (30 * d / 52).clamp(24.0, 38.0);

    final Gradient cardFill = kind == WordBuilderTrayActionKind.hint
        ? _lampFaceGradient(isDark)
        : RadialGradient(
            center: const Alignment(-0.4, -0.45),
            radius: 1.05,
            colors: [
              Color.alphaBlend(
                Colors.white.withValues(alpha: isDark ? 0.1 : 0.34),
                palette.container,
              ),
              Color.alphaBlend(
                palette.accent.withValues(alpha: isDark ? 0.42 : 0.2),
                palette.container,
              ),
            ],
          );

    final borderColor = kind == WordBuilderTrayActionKind.hint
        ? _HintLampStyle.rim.withValues(alpha: isDark ? 0.78 : 0.72)
        : palette.accent.withValues(alpha: isDark ? 0.62 : 0.52);

    final iconShadows = kind == WordBuilderTrayActionKind.hint
        ? <Shadow>[
            Shadow(
              color: _HintLampStyle.glowAmber.withValues(alpha: 0.65),
              blurRadius: 10,
            ),
            Shadow(
              color: _HintLampStyle.glowSoft.withValues(alpha: 0.45),
              blurRadius: 5,
            ),
            Shadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.55 : 0.18),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ]
        : <Shadow>[
            Shadow(
              color: palette.accent.withValues(alpha: 0.55),
              blurRadius: 9,
            ),
            Shadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.65 : 0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ];

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: d,
        height: d,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: _outerGlows(kind, palette, isDark, blurNear, blurFar),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: kind == WordBuilderTrayActionKind.hint ? 2 : 1.75,
                  ),
                  gradient: cardFill,
                ),
                child: SizedBox(
                  width: d,
                  height: d,
                  child: Center(
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: palette.onAccent,
                      shadows: iconShadows,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
