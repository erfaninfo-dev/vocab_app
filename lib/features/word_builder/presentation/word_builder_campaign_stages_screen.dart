import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../data/word_builder_campaign_progress_repository.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';

class WordBuilderCampaignStagesScreen extends ConsumerWidget {
  const WordBuilderCampaignStagesScreen({super.key, required this.difficulty});

  final WordBuilderDifficulty difficulty;

  String _tierTitle(AppLocalizations l10n) {
    switch (difficulty) {
      case WordBuilderDifficulty.beginner:
        return l10n.wordBuilderDifficultyBeginner;
      case WordBuilderDifficulty.intermediate:
        return l10n.wordBuilderDifficultyIntermediate;
      case WordBuilderDifficulty.advanced:
        return l10n.wordBuilderDifficultyAdvanced;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planAsync = ref.watch(wordBuilderCampaignPlanProvider);
    final progAsync = ref.watch(wordBuilderCampaignProgressProvider);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF87CEEB), scheme.surface, isDark ? 0.35 : 0.15) ??
            scheme.primaryContainer,
        scheme.surface,
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: scheme.surface.withValues(alpha: 0.72),
          title: Text(_tierTitle(l10n)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/word-builder'),
          ),
        ),
        body: planAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: scheme.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.wordBuilderCampaignPlanError,
                    textAlign: TextAlign.center,
                    style: tt.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(wordBuilderCampaignPlanProvider);
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (plan) => progAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: scheme.primary)),
            error: (_, __) => Center(child: Text(l10n.errorGeneric)),
            data: (progress) {
              final stages = plan.stagesFor(difficulty);
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      if (l10n.wordBuilderCampaignStagesHint.trim().isNotEmpty) ...[
                        Text(
                          l10n.wordBuilderCampaignStagesHint,
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7)
                                .withValues(alpha: isDark ? 0.14 : 0.92),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFC4956A)
                                  .withValues(alpha: isDark ? 0.4 : 0.65),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
                            child: LayoutBuilder(
                              builder: (context, c) {
                                const spacing = 12.0;
                                const runSpacing = 14.0;
                                const cols = 5;
                                final cell = (c.maxWidth - spacing * (cols - 1)) / cols;
                                final side = cell.clamp(52.0, 72.0);
                                return SingleChildScrollView(
                                  child: Wrap(
                                    spacing: spacing,
                                    runSpacing: runSpacing,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      for (var i = 1; i <= kWordBuilderStagesPerTier; i++)
                                        _StageCell(
                                          side: side,
                                          index: i,
                                          difficulty: difficulty,
                                          progress: progress,
                                          stagePoolEmpty: i <= stages.length &&
                                              stages[i - 1].isEmpty,
                                          l10n: l10n,
                                          scheme: scheme,
                                          onLockedTap: () {
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.wordBuilderCampaignStageLockedSnackbar,
                                                ),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          onOpenTap: () {
                                            final k = encodeWordBuilderCampaignSessionKey(
                                              difficulty,
                                              i,
                                            );
                                            context.push(
                                              '/word-builder/session?bookId=$k',
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StageCell extends StatelessWidget {
  const _StageCell({
    required this.side,
    required this.index,
    required this.difficulty,
    required this.progress,
    required this.stagePoolEmpty,
    required this.l10n,
    required this.scheme,
    required this.onLockedTap,
    required this.onOpenTap,
  });

  final double side;
  final int index;
  final WordBuilderDifficulty difficulty;
  final WordBuilderCampaignProgressSnapshot progress;
  final bool stagePoolEmpty;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final VoidCallback onLockedTap;
  final VoidCallback onOpenTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isStageUnlocked(difficulty, index);
    final completed = progress.isStageCompleted(difficulty, index);

    if (stagePoolEmpty && unlocked) {
      return Semantics(
        label: l10n.wordBuilderCampaignStageN(index),
        child: Tooltip(
          message: l10n.wordBuilderCampaignPlanError,
          child: SizedBox(
            width: side,
            height: side,
            child: Material(
              color: scheme.errorContainer.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              child: Icon(Icons.warning_amber_rounded, color: scheme.error),
            ),
          ),
        ),
      );
    }

    if (!unlocked) {
      return Semantics(
        button: true,
        label: '${l10n.wordBuilderCampaignStageN(index)} — ${l10n.wordBuilderCampaignStageLockedSnackbar}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onLockedTap,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: side,
              height: side,
              child: _GlossyTile(
                borderRadius: 18,
                colors: [
                  const Color(0xFFB0BEC5),
                  const Color(0xFF90A4AE),
                ],
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.blueGrey.shade900,
                  size: side * 0.38,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isCurrent = unlocked && !completed;
    final colors = completed
        ? const [Color(0xFFFFD54F), Color(0xFFFFA000)]
        : isCurrent
            ? const [Color(0xFF66BB6A), Color(0xFF2E7D32)]
            : const [Color(0xFF42A5F5), Color(0xFF1565C0)];

    return Semantics(
      button: true,
      label: completed
          ? '${l10n.wordBuilderCampaignStageN(index)} — ${l10n.wordBuilderCampaignStageCompleted}'
          : l10n.wordBuilderCampaignStageN(index),
      hint: completed ? l10n.wordBuilderCampaignStageReplayHint : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _GlossyTile(
                  borderRadius: 18,
                  colors: colors,
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                ),
                if (completed)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: side * 0.28,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                if (isCurrent)
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: side * 0.42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
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

class _GlossyTile extends StatelessWidget {
  const _GlossyTile({
    required this.borderRadius,
    required this.colors,
    required this.child,
  });

  final double borderRadius;
  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.45),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 0,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            right: 8,
            top: 6,
            height: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}
