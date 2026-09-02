import 'package:flutter/material.dart';

import '../../../core/widgets/app_gradient_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../speaking_constants.dart';

PreferredSizeWidget speakingTopicQuestionsAppBar({
  required BuildContext context,
  required AppLocalizations l10n,
  required String title,
  required VoidCallback onBack,
}) {
  return styledAppGradientAppBar(
    context: context,
    leading: IconButton(
      onPressed: onBack,
      tooltip: l10n.back,
      icon: const Icon(Icons.arrow_back_rounded),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}

class SpeakingCircleIconButton extends StatelessWidget {
  const SpeakingCircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? scheme.surfaceContainerHigh.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.95),
      elevation: isDark ? 0 : 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 18,
              color: speakingQuestionsTitleColor(context),
            ),
          ),
        ),
      ),
    );
  }
}
