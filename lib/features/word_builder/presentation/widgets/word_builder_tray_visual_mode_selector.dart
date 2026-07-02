import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/word_builder_tray_visual_mode_provider.dart';
import '../../domain/word_builder_tray_visual_mode.dart';

class WordBuilderTrayVisualModeSelector extends ConsumerWidget {
  const WordBuilderTrayVisualModeSelector({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(wordBuilderTrayVisualModeProvider);
    final notifier = ref.read(wordBuilderTrayVisualModeProvider.notifier);
    final glassSfxOn = ref.watch(wordBuilderGameGlassSfxEnabledProvider);
    final glassSfxN = ref.read(wordBuilderGameGlassSfxEnabledProvider.notifier);

    final children = <Widget>[
      _ModeChip(
        selected: mode == WordBuilderTrayVisualMode.water,
        icon: Icons.water_drop_rounded,
        label: l10n.wordBuilderTrayModeWater,
        subtitle: compact ? null : l10n.wordBuilderTrayModeWaterSubtitle,
        onTap: () => notifier.setMode(WordBuilderTrayVisualMode.water),
        scheme: scheme,
        isDark: isDark,
      ),
      SizedBox(width: compact ? 8 : 0, height: compact ? 0 : 10),
      _ModeChip(
        selected: mode == WordBuilderTrayVisualMode.glassCrack,
        icon: Icons.broken_image_outlined,
        label: l10n.wordBuilderTrayModeGlass,
        subtitle: compact ? null : l10n.wordBuilderTrayModeGlassSubtitle,
        onTap: () => notifier.setMode(WordBuilderTrayVisualMode.glassCrack),
        scheme: scheme,
        isDark: isDark,
      ),
    ];

    if (mode == WordBuilderTrayVisualMode.glassCrack && !compact) {
      children.addAll([
        const SizedBox(height: 12),
        _GlassSfxTile(
          value: glassSfxOn,
          onChanged: (v) => glassSfxN.setEnabled(v),
          scheme: scheme,
          isDark: isDark,
          title: l10n.wordBuilderSessionGlassSfxSwitch,
          subtitle: l10n.wordBuilderSessionGlassSfxSubtitle,
        ),
      ]);
    }

    if (compact) {
      return Row(children: children);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.wordBuilderTrayVisualModeTitle,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? scheme.onSurface : const Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wordBuilderTrayVisualModeSubtitle,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            height: 1.25,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.scheme,
    required this.isDark,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (subtitle == null) {
      return Expanded(
        child: _chipBody(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: _iconColor),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _chipBody(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                Text(
                  subtitle!,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    height: 1.25,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: scheme.primary, size: 22),
        ],
      ),
    );
  }

  Color get _iconColor =>
      selected ? scheme.primary : scheme.onSurfaceVariant;

  Color get _textColor =>
      isDark ? scheme.onSurface : const Color(0xFF5D4037);

  Widget _chipBody({required EdgeInsets padding, required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? scheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.55)
                : scheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.65,
                  ),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.65)
                  : scheme.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _GlassSfxTile extends StatelessWidget {
  const _GlassSfxTile({
    required this.value,
    required this.onChanged,
    required this.scheme,
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme scheme;
  final bool isDark;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.28 : 0.55,
            ),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.vibration_rounded,
                  color: value ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark
                              ? scheme.onSurface
                              : const Color(0xFF5D4037),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
