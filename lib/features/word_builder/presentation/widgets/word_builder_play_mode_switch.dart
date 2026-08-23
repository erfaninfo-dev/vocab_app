import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/word_builder_play_mode_controller.dart';
import '../../domain/word_builder_play_mode.dart';

/// Lobby / settings control to switch Classic Tray ↔ Angry Words.
class WordBuilderPlayModeSwitch extends ConsumerWidget {
  const WordBuilderPlayModeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(wordBuilderPlayModeProvider);
    final notifier = ref.read(wordBuilderPlayModeProvider.notifier);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.72),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.7),
          width: 1.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.wordBuilderPlayModeTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? scheme.onSurface : const Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.wordBuilderPlayModeSwitchHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    selected: mode == WordBuilderPlayMode.classic,
                    icon: Icons.blur_circular_rounded,
                    title: l10n.wordBuilderPlayModeClassic,
                    subtitle: l10n.wordBuilderPlayModeClassicSubtitle,
                    onTap: () =>
                        notifier.setMode(WordBuilderPlayMode.classic),
                    isDark: isDark,
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeCard(
                    selected: mode == WordBuilderPlayMode.angryWords,
                    icon: Icons.gps_fixed_rounded,
                    title: l10n.wordBuilderPlayModeAngryWords,
                    subtitle: l10n.wordBuilderPlayModeAngryWordsSubtitle,
                    onTap: () =>
                        notifier.setMode(WordBuilderPlayMode.angryWords),
                    isDark: isDark,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.scheme,
    this.featured = false,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme scheme;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final accent = featured ? const Color(0xFFFF7043) : const Color(0xFFFFB300);
    final accentDeep =
        featured ? const Color(0xFFE64A19) : const Color(0xFFFF8F00);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: EdgeInsets.fromLTRB(
            featured ? 14 : 10,
            featured ? 14 : 12,
            featured ? 14 : 10,
            featured ? 14 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected && featured
                ? LinearGradient(
                    colors: [
                      accent.withValues(alpha: isDark ? 0.32 : 0.4),
                      const Color(0xFFFFD54F)
                          .withValues(alpha: isDark ? 0.2 : 0.28),
                    ],
                  )
                : null,
            color: selected && !featured
                ? accent.withValues(alpha: isDark ? 0.28 : 0.35)
                : selected
                    ? null
                    : scheme.surface.withValues(alpha: isDark ? 0.25 : 0.55),
            border: Border.all(
              color: selected ? accentDeep : scheme.outline.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: featured
              ? Row(
                  children: [
                    Icon(
                      icon,
                      size: 30,
                      color: selected ? accentDeep : scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? scheme.onSurface
                                  : const Color(0xFF5D4037),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      icon,
                      size: 28,
                      color: selected ? const Color(0xFFE65100) : scheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? scheme.onSurface : const Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontSize: 10,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
