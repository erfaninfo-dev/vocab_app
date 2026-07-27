import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../data/word_builder_campaign_progress_repository.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';
import 'widgets/magic_background.dart';

class WordBuilderCampaignStagesScreen extends ConsumerStatefulWidget {
  const WordBuilderCampaignStagesScreen({super.key, required this.difficulty});

  final WordBuilderDifficulty difficulty;

  @override
  ConsumerState<WordBuilderCampaignStagesScreen> createState() =>
      _WordBuilderCampaignStagesScreenState();
}

class _WordBuilderCampaignStagesScreenState
    extends ConsumerState<WordBuilderCampaignStagesScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _stageKeys = <int, GlobalKey>{};
  String? _lastAutoScrollKey;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _nextStageFor(WordBuilderCampaignProgressSnapshot progress) {
    final cleared = progress.clearedFor(widget.difficulty);
    return (cleared + 1).clamp(1, kWordBuilderStagesPerTier);
  }

  void _scheduleScrollToStage({
    required WordBuilderCampaignProgressSnapshot progress,
  }) {
    final targetStage = _nextStageFor(progress);
    final key = '${widget.difficulty.name}:$targetStage';
    if (_lastAutoScrollKey == key) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final context = _stageKeys[targetStage]?.currentContext;
      if (context == null) return;
      _lastAutoScrollKey = key;
      Scrollable.ensureVisible(
        context,
        alignment: 0.35,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  GlobalKey _stageKeyFor(int stage) =>
      _stageKeys.putIfAbsent(stage, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final difficulty = widget.difficulty;
    final planAsync = ref.watch(wordBuilderCampaignPlanProvider);
    final progAsync = ref.watch(wordBuilderCampaignProgressProvider);
    final adminUnlockAll =
        ref.watch(authProvider).valueOrNull?.user.isAdmin ?? false;

    final funTheme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.fredokaTextTheme(Theme.of(context).textTheme),
    );

    return Theme(
      data: funTheme,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MagicBackground(isDark: isDark),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: kToolbarHeight,
              title: const SizedBox.shrink(),
              centerTitle: false,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? scheme.onSurface : const Color(0xFF5D4037),
                ),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/word-builder'),
              ),
            ),
            body: planAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB300)),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.wordBuilderCampaignPlanError,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D4037),
                        ),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                ),
                error: (_, __) => Center(
                  child: Text(
                    l10n.errorGeneric,
                    style: GoogleFonts.fredoka(
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                data: (progress) {
                  final stages = plan.stagesFor(difficulty);
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          const spacing = 12.0;
                          const runSpacing = 14.0;
                          const cols = 5;
                          final cell =
                              (c.maxWidth - spacing * (cols - 1)) / cols;
                          final side = cell.clamp(52.0, 72.0);
                          _scheduleScrollToStage(progress: progress);
                          return SingleChildScrollView(
                            controller: _scrollController,
                            child: Wrap(
                              spacing: spacing,
                              runSpacing: runSpacing,
                              alignment: WrapAlignment.center,
                              children: [
                                for (
                                  var i = 1;
                                  i <= kWordBuilderStagesPerTier;
                                  i++
                                )
                                  KeyedSubtree(
                                    key: _stageKeyFor(i),
                                    child: _StageCell(
                                      side: side,
                                      index: i,
                                      difficulty: difficulty,
                                      progress: progress,
                                      unlockAll: adminUnlockAll,
                                      stagePoolEmpty:
                                          i <= stages.length &&
                                          stages[i - 1].isEmpty,
                                      l10n: l10n,
                                      onLockedTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.wordBuilderCampaignStageLockedSnackbar,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      onOpenTap: () {
                                        final k =
                                            encodeWordBuilderCampaignSessionKey(
                                              difficulty,
                                              i,
                                            );
                                        context.push(
                                          '/word-builder/session?bookId=$k',
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
    required this.unlockAll,
    required this.stagePoolEmpty,
    required this.l10n,
    required this.onLockedTap,
    required this.onOpenTap,
  });

  final double side;
  final int index;
  final WordBuilderDifficulty difficulty;
  final WordBuilderCampaignProgressSnapshot progress;
  final bool unlockAll;
  final bool stagePoolEmpty;
  final AppLocalizations l10n;
  final VoidCallback onLockedTap;
  final VoidCallback onOpenTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isStageUnlocked(
      difficulty,
      index,
      unlockAll: unlockAll,
    );
    final completed = progress.isStageCompleted(difficulty, index);

    if (stagePoolEmpty && unlocked) {
      return Semantics(
        label: l10n.wordBuilderCampaignStageN(index),
        child: Tooltip(
          message: l10n.wordBuilderCampaignPlanError,
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFFFCDD2),
                border: Border.all(color: const Color(0xFFD32F2F), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB71C1C),
              ),
            ),
          ),
        ),
      );
    }

    if (!unlocked) {
      return Semantics(
        button: true,
        label:
            '${l10n.wordBuilderCampaignStageN(index)} — ${l10n.wordBuilderCampaignStageLockedSnackbar}',
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
                colors: const [Color(0xFFB0BEC5), Color(0xFF78909C)],
                glow: Colors.blueGrey,
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
        ? const [Color(0xFFFFD54F), Color(0xFFFFB300)]
        : isCurrent
        ? const [Color(0xFF81C784), Color(0xFF2E7D32)]
        : const [Color(0xFFFFECB3), Color(0xFFFFB300)];

    final glow = completed
        ? Colors.orange
        : isCurrent
        ? const Color(0xFF43A047)
        : Colors.amber;

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
                  glow: glow,
                  child: Text(
                    '$index',
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: (side * 0.38).clamp(18.0, 26.0),
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
    this.glow = Colors.orange,
  });

  final double borderRadius;
  final List<Color> colors;
  final Widget child;
  final Color glow;

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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.45),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 0,
            offset: const Offset(0, 4),
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
                    Colors.white.withValues(alpha: 0.6),
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
