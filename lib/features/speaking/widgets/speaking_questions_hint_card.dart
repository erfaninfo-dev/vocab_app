import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../speaking_constants.dart';

class SpeakingQuestionsHintCard extends StatelessWidget {
  const SpeakingQuestionsHintCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = kSpeakingBrandCyan;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark
            ? accent.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.speakingQuestionsHintTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    height: 1.3,
                    color: speakingQuestionsTitleColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.speakingQuestionsHintSubtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.35,
                    color: scheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
