import 'package:flutter/material.dart';

import '../../../data/models/speaking_model_summary.dart';
import '../../../l10n/app_localizations.dart';
import 'speaking_constants.dart';

class SpeakingModelQuestionRowCard extends StatelessWidget {
  const SpeakingModelQuestionRowCard({
    super.key,
    required this.l10n,
    required this.model,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final SpeakingModelSummary model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = speakingThemeForTopic(model.id);
    final title = model.title.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: speakingTopicCardSurface(context, theme),
            border: Border.all(color: theme.accent.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.accent, theme.glow.withValues(alpha: 0.9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.speakingModelNumber(model.modelNumber),
                        style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.isEmpty ? '—' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: speakingCardSubtitleColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.speakingTopicQuestionCount(model.questionCount),
                        style: TextStyle(
                          color: theme.accent.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: theme.accent,
                      size: 18,
                    ),
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
