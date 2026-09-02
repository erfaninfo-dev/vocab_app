import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/language_provider.dart';
import '../../../data/models/speaking_question.dart';
import '../../../data/models/speaking_question_lang.dart';
import '../../../l10n/app_localizations.dart';
import '../speaking_constants.dart';
import 'speaking_topic_questions_header.dart';

class SpeakingQuestionCard extends ConsumerWidget {
  const SpeakingQuestionCard({
    super.key,
    required this.l10n,
    required this.index,
    required this.question,
    required this.isExpanded,
    required this.onToggle,
    this.topicLabel,
    this.accentColor,
  });

  final AppLocalizations l10n;
  final int index;
  final SpeakingQuestion question;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String? topicLabel;
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        accentColor ?? speakingThemeForTopic(question.model.id).accent;
    final lang = ref.watch(langProvider);
    final localizedAnswer = question.answerTranslationFor(lang);
    final translationLabel = lang == TranslationLang.kur
        ? l10n.translationLangKurdiTab
        : l10n.grammarExplanationTabFa;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.98),
        border: Border.all(
          color: isExpanded
              ? accent.withValues(alpha: 0.28)
              : scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: isExpanded ? 18 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -18,
                bottom: -18,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 4,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.1 : 0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$index',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (topicLabel != null &&
                                    topicLabel!.trim().isNotEmpty) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      topicLabel!.trim(),
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                                Text(
                                  question.questionText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.35,
                                    color: speakingQuestionsTitleColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: onToggle,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.speakingModelAnswer,
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: _ExpandIconButton(
                            accent: accent,
                            isExpanded: isExpanded,
                            onPressed: onToggle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: _SpeakingModelQuestionPanel(
                        l10n: l10n,
                        question: question,
                        accent: accent,
                        localizedAnswer: localizedAnswer,
                        translationLabel: localizedAnswer.isEmpty
                            ? null
                            : translationLabel,
                        onCopyAnswer: () {
                          Clipboard.setData(
                            ClipboardData(text: question.answer),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.speakingAnswerCopied),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandIconButton extends StatelessWidget {
  const _ExpandIconButton({
    required this.accent,
    required this.isExpanded,
    required this.onPressed,
  });

  final Color accent;
  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SpeakingCircleIconButton(
      icon: isExpanded
          ? Icons.keyboard_arrow_up_rounded
          : Icons.keyboard_arrow_down_rounded,
      tooltip: isExpanded ? 'Collapse' : 'Expand',
      onPressed: onPressed,
    );
  }
}

class _SpeakingModelQuestionPanel extends StatelessWidget {
  const _SpeakingModelQuestionPanel({
    required this.l10n,
    required this.question,
    required this.accent,
    required this.localizedAnswer,
    required this.onCopyAnswer,
    this.translationLabel,
  });

  final AppLocalizations l10n;
  final SpeakingQuestion question;
  final Color accent;
  final String localizedAnswer;
  final VoidCallback onCopyAnswer;
  final String? translationLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modelTitle = question.model.title.trim();
    final panelColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.22 : 0.1),
      isDark ? scheme.surfaceContainerHigh : const Color(0xFFF4F8FF),
    );

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.14 : 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.speakingModelNumber(
                                question.model.modelNumber,
                              ),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              modelTitle.isEmpty
                                  ? question.model.formula.trim()
                                  : modelTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.3,
                                color: speakingQuestionsTitleColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ModelInfoBlock(
                    label: l10n.speakingFormula,
                    text: question.model.formula,
                    accent: accent,
                    monospace: true,
                  ),
                  const SizedBox(height: 8),
                  _ModelInfoBlock(
                    label: l10n.speakingTemplate,
                    text: question.model.template,
                    accent: accent,
                  ),
                  const SizedBox(height: 8),
                  _ModelAnswerBlock(
                    label: l10n.speakingSampleAnswer,
                    text: question.answer,
                    accent: accent,
                    translationLabel: translationLabel,
                    translationText:
                        localizedAnswer.isEmpty ? null : localizedAnswer,
                    onCopy: onCopyAnswer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelInfoBlock extends StatelessWidget {
  const _ModelInfoBlock({
    required this.label,
    required this.text,
    required this.accent,
    this.monospace = false,
  });

  final String label;
  final String text;
  final Color accent;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontFamily: monospace ? 'monospace' : null,
              fontStyle: monospace ? FontStyle.normal : FontStyle.italic,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelAnswerBlock extends StatelessWidget {
  const _ModelAnswerBlock({
    required this.label,
    required this.text,
    required this.accent,
    required this.onCopy,
    this.translationLabel,
    this.translationText,
  });

  final String label;
  final String text;
  final Color accent;
  final VoidCallback onCopy;
  final String? translationLabel;
  final String? translationText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surface.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                onPressed: onCopy,
                icon: Icon(Icons.copy_rounded, size: 18, color: accent),
              ),
            ],
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (translationText != null && translationText!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: accent.withValues(alpha: 0.22)),
            const SizedBox(height: 10),
            Text(
              translationLabel ?? '',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  translationText!.trim(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
