import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/word_builder_session_audio.dart';

class WordBuilderSessionAudioSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(ctx)!;
        return Consumer(
          builder: (context, ref2, _) {
            final bgmOn = ref2.watch(wordBuilderGameBgmEnabledProvider);
            final sfxOn = ref2.watch(wordBuilderGameSfxEnabledProvider);
            final bgmN = ref2.read(wordBuilderGameBgmEnabledProvider.notifier);
            final sfxN = ref2.read(wordBuilderGameSfxEnabledProvider.notifier);
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF2D2640),
                            Color(0xFF1E1B24),
                          ]
                        : const [
                            Color(0xFFFFF8E1),
                            Color(0xFFFFECB3),
                          ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withValues(
                      alpha: isDark ? 0.55 : 0.85,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: scheme.primary,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.wordBuilderSessionSoundTitle,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? scheme.onSurface
                                    : const Color(0xFF5D4037),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SoundTile(
                        icon: Icons.library_music_rounded,
                        title: l10n.wordBuilderSessionBgmSwitch,
                        subtitle: l10n.wordBuilderSessionBgmSubtitle,
                        value: bgmOn,
                        onChanged: (v) => bgmN.setEnabled(v),
                        scheme: scheme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _SoundTile(
                        icon: Icons.volume_up_rounded,
                        title: l10n.wordBuilderSessionSfxSwitch,
                        subtitle: l10n.wordBuilderSessionSfxSubtitle,
                        value: sfxOn,
                        onChanged: (v) => sfxN.setEnabled(v),
                        scheme: scheme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.scheme,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!value),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.35 : 0.65,
            ),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: value
                          ? [
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.75),
                            ]
                          : [
                              scheme.surfaceContainerHigh,
                              scheme.surfaceContainerHighest,
                            ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      icon,
                      size: 22,
                      color: value
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? scheme.onSurface
                              : const Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
