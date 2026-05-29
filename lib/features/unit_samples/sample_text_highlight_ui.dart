import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'sample_text_highlights_controller.dart';

/// Tap targets inside this group do not dismiss highlight overlays.
final Object sampleHighlightTapRegionGroup = Object();

String sampleHighlightSelectionPreview(String plain, TextSelection sel) {
  final len = plain.length;
  if (len == 0) return '';
  var s = sel.start.clamp(0, len);
  var e = sel.end.clamp(0, len);
  if (e < s) {
    final t = s;
    s = e;
    e = t;
  }
  var t = plain.substring(s, e).trim();
  if (t.isEmpty) return '';
  if (t.length > 56) return '${t.substring(0, 53)}…';
  return t;
}

Future<void> applySampleHighlight({
  required WidgetRef ref,
  required Color color,
  required int sampleId,
  required String langKey,
  required int paragraphIndex,
  required TextSelection selection,
  required String plainText,
  bool replaceOverlapping = true,
}) async {
  final notifier = ref.read(sampleTextHighlightsProvider.notifier);
  if (replaceOverlapping) {
    await notifier.replaceHighlightForSelection(
      sampleId: sampleId,
      langKey: langKey,
      paragraphIndex: paragraphIndex,
      start: selection.start,
      end: selection.end,
      plainText: plainText,
      color: color,
    );
  } else {
    await notifier.addHighlight(
      sampleId: sampleId,
      langKey: langKey,
      paragraphIndex: paragraphIndex,
      start: selection.start,
      end: selection.end,
      plainText: plainText,
      color: color,
    );
  }
  HapticFeedback.lightImpact();
}

class _HighlightColorSwatch extends StatelessWidget {
  const _HighlightColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const outer = 30.0;
    const inner = 22.0;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: outer,
            height: outer,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.45),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Container(
              width: inner,
              height: inner,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: _contrastIconOn(color),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

Color _contrastIconOn(Color bg) {
  final lum = bg.computeLuminance();
  return lum > 0.62 ? const Color(0xFF1A1A1A) : Colors.white;
}

const double _kHighlightSwatchGap = 6;

class _HighlightColorCardShell extends StatelessWidget {
  const _HighlightColorCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          elevation: 2,
          shadowColor: scheme.primary.withValues(alpha: 0.18),
          color: scheme.surfaceContainerLowest,
          surfaceTintColor: scheme.primary,
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.35),
                  scheme.surfaceContainerLowest,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightColorPickerRow extends StatelessWidget {
  const _HighlightColorPickerRow({
    required this.selectedArgb,
    required this.onColorTap,
    this.trailing,
  });

  final int selectedArgb;
  final ValueChanged<Color> onColorTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final c in kSampleHighlightPalette)
        _HighlightColorSwatch(
          color: c,
          selected: c.toARGB32() == selectedArgb,
          onTap: () => onColorTap(c),
        ),
      if (trailing != null) trailing!,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _kHighlightSwatchGap),
          items[i],
        ],
      ],
    );
  }
}

/// Shown from the highlight tool-strip button — sets default color only.
class SampleDefaultColorPickerBar extends ConsumerWidget {
  const SampleDefaultColorPickerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultColor = ref.watch(
      sampleTextHighlightsProvider.select((s) => s.defaultColor),
    );

    return _HighlightColorCardShell(
      child: _HighlightColorPickerRow(
        selectedArgb: defaultColor.toARGB32(),
        onColorTap: (c) async {
          await ref
              .read(sampleTextHighlightsProvider.notifier)
              .setDefaultColor(c);
          HapticFeedback.selectionClick();
        },
      ),
    );
  }
}

class SampleHighlightSelectionBar extends ConsumerWidget {
  const SampleHighlightSelectionBar({
    super.key,
    required this.sampleId,
    required this.langKey,
    required this.paragraphIndex,
    required this.plainText,
    required this.selection,
    required this.onClearSelection,
  });

  final int sampleId;
  final String langKey;
  final int paragraphIndex;
  final String plainText;
  final TextSelection selection;
  final VoidCallback onClearSelection;

  Color _activeHighlightColor(
    SampleTextHighlightsController notifier,
    List<SampleTextHighlight> highlights,
    Color defaultColor,
    int selStart,
    int selEnd,
  ) {
    final normalized = notifier.normalizedSelectionRange(
      plainText,
      selStart,
      selEnd,
    );
    if (normalized == null) return defaultColor;
    final (s, e) = normalized;
    for (final h in highlights) {
      if (h.intersects(s, e)) return h.color;
    }
    return defaultColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final defaultColor = ref.watch(
      sampleTextHighlightsProvider.select((s) => s.defaultColor),
    );
    final highlights = ref.watch(
      sampleTextHighlightsProvider.select(
        (s) => s.forParagraph(
          sampleId: sampleId,
          langKey: langKey,
          paragraphIndex: paragraphIndex,
        ),
      ),
    );
    final hasOverlap = ref
        .read(sampleTextHighlightsProvider.notifier)
        .selectionOverlapsHighlights(
          plainText: plainText,
          sampleId: sampleId,
          langKey: langKey,
          paragraphIndex: paragraphIndex,
          start: selection.start,
          end: selection.end,
        );
    final notifier = ref.read(sampleTextHighlightsProvider.notifier);
    final activeColor = _activeHighlightColor(
      notifier,
      highlights,
      defaultColor,
      selection.start,
      selection.end,
    );

    return _HighlightColorCardShell(
      child: _HighlightColorPickerRow(
        selectedArgb: activeColor.toARGB32(),
        onColorTap: (c) => applySampleHighlight(
          ref: ref,
          color: c,
          sampleId: sampleId,
          langKey: langKey,
          paragraphIndex: paragraphIndex,
          selection: selection,
          plainText: plainText,
        ),
        trailing: hasOverlap
            ? _ToolbarIconChip(
                tooltip: l10n.sampleHighlightRemove,
                icon: Icons.delete_sweep_rounded,
                foreground: scheme.error,
                background: scheme.errorContainer.withValues(alpha: 0.55),
                onPressed: () async {
                  await ref
                      .read(sampleTextHighlightsProvider.notifier)
                      .removeIntersecting(
                        sampleId: sampleId,
                        langKey: langKey,
                        paragraphIndex: paragraphIndex,
                        start: selection.start,
                        end: selection.end,
                        plainText: plainText,
                      );
                  HapticFeedback.lightImpact();
                  onClearSelection();
                },
              )
            : null,
      ),
    );
  }
}

class _ToolbarIconChip extends StatelessWidget {
  const _ToolbarIconChip({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.foreground,
    this.background,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? scheme.surfaceContainerHigh,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              icon,
              size: 18,
              color: foreground ?? scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact tool strip for the sample highlight color and full-text TTS play.
class SampleParagraphToolStrip extends ConsumerWidget {
  const SampleParagraphToolStrip({
    super.key,
    required this.onHighlightTap,
    this.showHighlight = true,
    this.highlightPickerOpen = false,
    this.showPlay = false,
    this.playActive = false,
    this.playPaused = false,
    this.onPlayTap,
  });

  final VoidCallback onHighlightTap;
  final bool showHighlight;
  final bool highlightPickerOpen;
  final bool showPlay;
  final bool playActive;
  final bool playPaused;
  final VoidCallback? onPlayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final defaultColor = ref.watch(
      sampleTextHighlightsProvider.select((s) => s.defaultColor),
    );

    if (!showHighlight && !showPlay) return const SizedBox.shrink();

    return Material(
      elevation: 0,
      color: highlightPickerOpen || playActive
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : scheme.surfaceContainerHigh.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHighlight)
              _ToolStripButton(
                tooltip: l10n.sampleHighlightDefaultColor,
                onPressed: onHighlightTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.highlight_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: defaultColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: highlightPickerOpen
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.6),
                          width: highlightPickerOpen ? 2 : 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (showPlay && onPlayTap != null) ...[
              if (showHighlight) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    height: 28,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
              _ToolStripButton(
                tooltip: playActive && !playPaused
                    ? l10n.samplePauseFullText
                    : l10n.samplePlayFullText,
                onPressed: onPlayTap!,
                child: Icon(
                  playActive && !playPaused
                      ? Icons.pause_rounded
                      : Icons.headphones_rounded,
                  size: 22,
                  color: playActive ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolStripButton extends StatelessWidget {
  const _ToolStripButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}
