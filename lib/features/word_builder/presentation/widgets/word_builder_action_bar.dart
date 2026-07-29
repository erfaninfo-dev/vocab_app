import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/app_haptics.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/word_builder_game_notifier.dart';
import '../theme/word_builder_tokens.dart';
import 'word_builder_tray_circle_button.dart';

/// Unified hint / shuffle / translate bar (Phase 4) — replaces floating circles.
class WordBuilderActionBar extends ConsumerWidget {
  const WordBuilderActionBar({
    super.key,
    required this.bookKey,
    required this.l10n,
    required this.canHint,
    required this.canShuffle,
    required this.canTranslate,
    required this.hintCost,
    required this.hintTooltip,
    required this.translateTooltip,
  });

  final int bookKey;
  final AppLocalizations l10n;
  final bool canHint;
  final bool canShuffle;
  final bool canTranslate;
  final int hintCost;
  final String hintTooltip;
  final String translateTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(WbTokens.rPill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: isDark ? 0.45 : 0.62,
            ),
            borderRadius: BorderRadius.circular(WbTokens.rPill),
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(
                alpha: isDark ? 0.4 : 0.55,
              ),
              width: 1.4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WbTokens.s2,
              vertical: WbTokens.s1,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBarItem(
                    kind: WordBuilderTrayActionKind.hint,
                    bookKey: bookKey,
                    enabled: canHint,
                    label: l10n.wordBuilderHints,
                    tooltip: hintTooltip,
                    coinBadge: hintCost,
                  ),
                ),
                Expanded(
                  child: _ActionBarItem(
                    kind: WordBuilderTrayActionKind.shuffle,
                    bookKey: bookKey,
                    enabled: canShuffle,
                    label: l10n.wordBuilderShuffle,
                    tooltip: l10n.wordBuilderShuffle,
                  ),
                ),
                Expanded(
                  child: _ActionBarItem(
                    kind: WordBuilderTrayActionKind.translate,
                    bookKey: bookKey,
                    enabled: canTranslate,
                    label: l10n.wordBuilderTranslation,
                    tooltip: translateTooltip,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBarItem extends ConsumerStatefulWidget {
  const _ActionBarItem({
    required this.kind,
    required this.bookKey,
    required this.enabled,
    required this.label,
    required this.tooltip,
    this.coinBadge,
  });

  final WordBuilderTrayActionKind kind;
  final int bookKey;
  final bool enabled;
  final String label;
  final String tooltip;
  final int? coinBadge;

  @override
  ConsumerState<_ActionBarItem> createState() => _ActionBarItemState();
}

class _ActionBarItemState extends ConsumerState<_ActionBarItem> {
  bool _pressed = false;

  Future<void> _run() async {
    if (!widget.enabled) return;
    final notifier = ref.read(
      wordBuilderGameProvider(widget.bookKey).notifier,
    );
    switch (widget.kind) {
      case WordBuilderTrayActionKind.hint:
        notifier.hintRevealLetter();
      case WordBuilderTrayActionKind.shuffle:
        notifier.shuffleCircle();
      case WordBuilderTrayActionKind.translate:
        final preferKur = ref.read(langProvider) == TranslationLang.kur;
        notifier.hintMeaning(preferKur: preferKur);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final short = _shortLabel(widget.label);
    final icon = switch (widget.kind) {
      WordBuilderTrayActionKind.hint => Icons.lightbulb_rounded,
      WordBuilderTrayActionKind.shuffle => Icons.shuffle_rounded,
      WordBuilderTrayActionKind.translate => Icons.translate_rounded,
    };
    final accent = switch (widget.kind) {
      WordBuilderTrayActionKind.hint => const Color(0xFFFFB300),
      WordBuilderTrayActionKind.shuffle => scheme.primary,
      WordBuilderTrayActionKind.translate => scheme.secondary,
    };

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.tooltip.isNotEmpty ? widget.tooltip : widget.label,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.42,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.enabled
                ? (_) => setState(() => _pressed = true)
                : null,
            onTapUp: widget.enabled
                ? (_) {
                    setState(() => _pressed = false);
                    appHapticSelection(ref);
                    _run();
                  }
                : null,
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: WbTokens.dFast,
              curve: WbTokens.cEnter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 48,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WbTokens.s1,
                    vertical: WbTokens.s1,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            icon,
                            size: 22,
                            color: widget.enabled
                                ? accent
                                : scheme.onSurface.withValues(alpha: 0.45),
                          ),
                          if (widget.coinBadge != null)
                            Positioned(
                              right: -10,
                              top: -6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300),
                                  borderRadius: BorderRadius.circular(
                                    WbTokens.rPill,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF3E2723)
                                        : Colors.white,
                                    width: 1.2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  child: Text(
                                    '${widget.coinBadge}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      color: isDark
                                          ? const Color(0xFF3E2723)
                                          : const Color(0xFF5D4037),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        short,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: WbTokens.tXs,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: scheme.onSurface.withValues(
                            alpha: widget.enabled ? 0.88 : 0.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortLabel(String full) {
    final t = full.trim();
    if (t.length <= 10) return t;
    final space = t.indexOf(' ');
    if (space > 0 && space <= 10) return t.substring(0, space);
    return t.substring(0, 9);
  }
}
