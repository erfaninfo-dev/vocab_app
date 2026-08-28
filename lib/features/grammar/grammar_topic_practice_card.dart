import 'package:flutter/material.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../l10n/app_localizations.dart';

/// Six rotating accent colors for grammar topic cards.
Color grammarTopicCardAccent(int index) {
  const accents = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF0D9488),
  ];
  return accents[index % accents.length];
}

class GrammarTopicPracticeCard extends StatelessWidget {
  const GrammarTopicPracticeCard({
    super.key,
    required this.title,
    required this.questionCount,
    required this.index,
    required this.selected,
    required this.onSelectionToggle,
    required this.onQuizTap,
    required this.onLearnTap,
    this.learnEnabled = false,
    this.quizEnabled = true,
    this.showNewBadge = false,
    this.showAdminNewToggle = false,
    this.adminNewFadingOut = false,
    this.adminNewChecked = false,
    this.adminNewSaving = false,
    this.onLongPress,
    this.onAdminNewToggle,
  });

  final String title;
  final int questionCount;
  final int index;
  final bool selected;
  final VoidCallback onSelectionToggle;
  final VoidCallback? onQuizTap;
  final VoidCallback? onLearnTap;
  final bool learnEnabled;
  final bool quizEnabled;
  final bool showNewBadge;
  final bool showAdminNewToggle;
  final bool adminNewFadingOut;
  final bool adminNewChecked;
  final bool adminNewSaving;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onAdminNewToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = grammarTopicCardAccent(index);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: appJellyAccentCardSurfaceDecoration(
            context,
            accent: accent,
            accentEnd: Color.lerp(accent, Colors.white, 0.18)!,
            selected: selected,
            intensity: 0.24,
            scheme: scheme,
          ).copyWith(
            boxShadow: appJellyCardShadows(context, glowColor: accent),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.72)
                  : Colors.white.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.12
                          : 0.75,
                    ),
              width: selected ? 2.2 : 1.4,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _SelectionCheckbox(
                        selected: selected,
                        accent: accent,
                        onTap: onSelectionToggle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppJellyIconBubble(
                          color: accent,
                          size: 48,
                          child: const Icon(
                            Icons.rule_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.grammarTopicsQuestionsCount(questionCount),
                                style: tt.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: showAdminNewToggle
                          ? _AdminNewToggleChip(
                              checked: adminNewChecked,
                              saving: adminNewSaving,
                              fadingOut: adminNewFadingOut,
                              onToggle: onAdminNewToggle,
                              scheme: scheme,
                              textTheme: tt,
                            )
                          : showNewBadge
                          ? _NewTopicBadge(scheme: scheme)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TopicActionTile(
                      accent: accent,
                      quizStyle: true,
                      icon: Icons.fact_check_outlined,
                      title: l10n.grammarTopicsCardQuizTitle,
                      description: l10n.grammarTopicsCardQuizDesc,
                      enabled: quizEnabled,
                      onTap: onQuizTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopicActionTile(
                      accent: const Color(0xFF2563EB),
                      quizStyle: false,
                      icon: Icons.menu_book_outlined,
                      title: l10n.grammarTopicsCardLearnTitle,
                      description: l10n.grammarTopicsCardLearnDesc,
                      enabled: learnEnabled,
                      onTap: onLearnTap,
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

class _SelectionCheckbox extends StatelessWidget {
  const _SelectionCheckbox({
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : scheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? accent
                  : scheme.outlineVariant.withValues(alpha: 0.65),
              width: selected ? 2 : 1.4,
            ),
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 18, color: accent)
              : null,
        ),
      ),
    );
  }
}

class _TopicActionTile extends StatelessWidget {
  const _TopicActionTile({
    required this.accent,
    required this.quizStyle,
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    this.onTap,
  });

  final Color accent;
  final bool quizStyle;
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bg = quizStyle
        ? accent.withValues(alpha: 0.10)
        : const Color(0xFF2563EB).withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (quizStyle ? accent : const Color(0xFF2563EB))
                    .withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: quizStyle ? accent : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    _ActionArrow(
                      color: quizStyle ? accent : const Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
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

class _ActionArrow extends StatelessWidget {
  const _ActionArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.arrow_forward_rounded, size: 16, color: color),
    );
  }
}

class _NewTopicBadge extends StatelessWidget {
  const _NewTopicBadge({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD166), Color(0xFFFF6B6B), Color(0xFF9B5DE5)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surface.withValues(alpha: 0.92)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'New',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNewToggleChip extends StatelessWidget {
  const _AdminNewToggleChip({
    required this.checked,
    required this.saving,
    required this.fadingOut,
    required this.onToggle,
    required this.scheme,
    required this.textTheme,
  });

  final bool checked;
  final bool saving;
  final bool fadingOut;
  final ValueChanged<bool>? onToggle;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: saving || fadingOut ? null : () => onToggle?.call(!checked),
      child: AnimatedOpacity(
        opacity: fadingOut ? 0 : 1,
        duration: const Duration(milliseconds: 480),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: checked
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saving)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              else
                Icon(
                  checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: checked ? scheme.primary : scheme.onSurfaceVariant,
                ),
              const SizedBox(width: 4),
              Text(
                'New',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GrammarTopicsSelectionBar extends StatelessWidget {
  const GrammarTopicsSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onStartQuiz,
  });

  final int selectedCount;
  final VoidCallback? onStartQuiz;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final enabled = selectedCount > 0 && onStartQuiz != null;

    return Material(
      color: scheme.surface.withValues(alpha: 0.98),
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.grammarTopicsSelectedCount(selectedCount),
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? l10n.grammarTopicsSelectionReadyHint
                          : l10n.grammarTopicsSelectionEmptyHint,
                      style: tt.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: enabled
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        )
                      : null,
                  color: enabled ? null : scheme.surfaceContainerHighest,
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: FilledButton.icon(
                  onPressed: enabled ? onStartQuiz : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: enabled
                        ? Colors.transparent
                        : scheme.surfaceContainerHighest,
                    foregroundColor: enabled
                        ? Colors.white
                        : scheme.onSurfaceVariant.withValues(alpha: 0.55),
                    disabledBackgroundColor: scheme.surfaceContainerHighest,
                    disabledForegroundColor: scheme.onSurfaceVariant.withValues(
                      alpha: 0.55,
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    l10n.grammarTopicsStartQuiz,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
