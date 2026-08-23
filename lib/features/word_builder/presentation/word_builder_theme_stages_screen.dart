import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../application/word_builder_theme_categories_provider.dart';
import '../application/word_builder_game_notifier.dart';
import '../data/word_builder_theme_categories.dart';
import '../data/word_builder_theme_progress.dart';
import '../data/word_builder_vocab.dart';
import '../word_builder_theme_session_key.dart';
import 'theme/word_builder_chapter_theme.dart';
import 'theme/word_builder_tokens.dart';
import 'widgets/magic_background.dart';

List<WbChapterTheme> _themeStageChapterHeaders(int stageCount) {
  if (stageCount <= 0) return const [];
  const chunk = 7;
  final out = <WbChapterTheme>[];
  for (var start = 1; start <= stageCount; start += chunk) {
    final end = start + chunk - 1 > stageCount ? stageCount : start + chunk - 1;
    final template =
        WbChapterTheme.all[((start - 1) ~/ chunk) % WbChapterTheme.all.length];
    out.add(
      WbChapterTheme(
        id: '${template.id}_$start',
        name: template.name,
        firstStage: start,
        lastStage: end,
        skyStops: template.skyStops,
        groundStops: template.groundStops,
        accent: template.accent,
        particles: template.particles,
        chromeBrightness: template.chromeBrightness,
        chromeSurface: template.chromeSurface,
        chromeOnSurface: template.chromeOnSurface,
        skyKind: template.skyKind,
      ),
    );
  }
  return out;
}

class WordBuilderThemeStagesScreen extends ConsumerStatefulWidget {
  const WordBuilderThemeStagesScreen({super.key, required this.categoryIndex});

  final int categoryIndex;

  @override
  ConsumerState<WordBuilderThemeStagesScreen> createState() =>
      _WordBuilderThemeStagesScreenState();
}

class _WordBuilderThemeStagesScreenState
    extends ConsumerState<WordBuilderThemeStagesScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _stageKeys = <int, GlobalKey>{};
  String? _lastAutoScrollKey;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _stageKeyFor(int stage) =>
      _stageKeys.putIfAbsent(stage, GlobalKey.new);

  void _scheduleScrollToStage(int targetStage) {
    final key = '${widget.categoryIndex}:$targetStage';
    if (_lastAutoScrollKey == key) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final context = _stageKeys[targetStage]?.currentContext;
      if (context == null) return;
      _lastAutoScrollKey = key;
      Scrollable.ensureVisible(
        context,
        alignment: 0.35,
        duration: WbTokens.dSlow,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final adminUnlockAll =
        ref.watch(authProvider).valueOrNull?.user.isAdmin ?? false;

    final categoriesAsync = ref.watch(wordBuilderThemeCategoriesProvider);

    if (categoriesAsync.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: scheme.primary,
          ),
        ),
      );
    }

    if (categoriesAsync.hasError) {
      return Scaffold(
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }

    final categories = categoriesAsync.value ?? const <WordBuilderThemeCategory>[];

    if (widget.categoryIndex < 0 || widget.categoryIndex >= categories.length) {
      return Scaffold(
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }

    final category = categories[widget.categoryIndex];
    final entries =
        wordBuilderThemeCategoryEntries(category, widget.categoryIndex);
    final levels = buildThemeCategoryStageLevels(
      entries: entries,
      categoryIndex: widget.categoryIndex,
      categoryLabel: 'theme_${category.id}',
    );
    final targetCounts =
        levels.map((l) => l.targetWords.length).toList(growable: false);
    final stageCount = levels.length;
    final chapters = _themeStageChapterHeaders(stageCount);

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
              title: Text(
                category.displayName(languageCode),
                style: GoogleFonts.fredoka(
                  fontSize: WbTokens.tLg,
                  fontWeight: FontWeight.w900,
                  color: isDark ? scheme.onSurface : const Color(0xFF5D4037),
                ),
              ),
            ),
            body: stageCount == 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.wordBuilderCategoryNoWordsYet,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  )
                : FutureBuilder(
                    future: ref.read(wordBuilderProgressRepoProvider).load(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFB300),
                          ),
                        );
                      }
                      final persisted = snap.data!;
                      final cleared = clearedThemeStages(
                        persisted: persisted,
                        categoryIndex: widget.categoryIndex,
                        targetCountsByStage: targetCounts,
                      );
                      final nextStage = (cleared + 1).clamp(1, stageCount);
                      _scheduleScrollToStage(nextStage);

                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            WbTokens.s4,
                            WbTokens.s2,
                            WbTokens.s4,
                            WbTokens.s5,
                          ),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              const spacing = WbTokens.s3;
                              const cols = 5;
                              final cell =
                                  (c.maxWidth - spacing * (cols - 1)) / cols;
                              final side = cell.clamp(52.0, 72.0);
                              final rowExtent = side + WbTokens.s2;

                              Widget stageCell(int stage) {
                                final levelIndex = stage - 1;
                                final levelId = wordBuilderThemeLevelId(
                                  widget.categoryIndex,
                                  stage,
                                );
                                final targets = targetCounts[levelIndex];
                                final unlocked = isThemeStageUnlocked(
                                  persisted: persisted,
                                  categoryIndex: widget.categoryIndex,
                                  stage1Based: stage,
                                  targetCountsByStage: targetCounts,
                                  unlockAll: adminUnlockAll,
                                );
                                final completed = isThemeStageCompleted(
                                  persisted,
                                  levelId,
                                  targets,
                                );
                                final poolEmpty =
                                    levelIndex >= levels.length ||
                                    levels[levelIndex].targetWords.isEmpty;

                                return KeyedSubtree(
                                  key: _stageKeyFor(stage),
                                  child: _ThemeStageCell(
                                    side: side,
                                    index: stage,
                                    unlocked: unlocked,
                                    completed: completed,
                                    poolEmpty: poolEmpty,
                                    l10n: l10n,
                                    onLockedTap: () {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n
                                                .wordBuilderCampaignStageLockedSnackbar,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    onOpenTap: () {
                                      final k =
                                          encodeWordBuilderThemeStageSessionKey(
                                        widget.categoryIndex,
                                        stage,
                                      );
                                      context.push(
                                        '/word-builder/session?bookId=$k',
                                      );
                                    },
                                  ),
                                );
                              }

                              return CustomScrollView(
                                controller: _scrollController,
                                slivers: [
                                  for (final chapter in chapters) ...[
                                    SliverToBoxAdapter(
                                      child: _ChapterIntroCard(theme: chapter),
                                    ),
                                    SliverPadding(
                                      padding: const EdgeInsets.only(
                                        top: WbTokens.s2,
                                        bottom: WbTokens.s4,
                                      ),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          mainAxisSpacing: WbTokens.s2,
                                          crossAxisSpacing: spacing,
                                          mainAxisExtent: rowExtent,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            final stage =
                                                chapter.firstStage + index;
                                            return Align(
                                              alignment: Alignment.center,
                                              child: stageCell(stage),
                                            );
                                          },
                                          childCount: chapter.lastStage -
                                              chapter.firstStage +
                                              1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ThemeStageCell extends StatelessWidget {
  const _ThemeStageCell({
    required this.side,
    required this.index,
    required this.unlocked,
    required this.completed,
    required this.poolEmpty,
    required this.l10n,
    required this.onLockedTap,
    required this.onOpenTap,
  });

  final double side;
  final int index;
  final bool unlocked;
  final bool completed;
  final bool poolEmpty;
  final AppLocalizations l10n;
  final VoidCallback onLockedTap;
  final VoidCallback onOpenTap;

  @override
  Widget build(BuildContext context) {
    if (poolEmpty && unlocked) {
      return SizedBox(
        width: side,
        height: side,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFFFCDD2),
            border: Border.all(color: const Color(0xFFD32F2F), width: 2),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB71C1C),
          ),
        ),
      );
    }

    if (!unlocked) {
      return Material(
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

    return Material(
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

class _ChapterIntroCard extends StatelessWidget {
  const _ChapterIntroCard({required this.theme});

  final WbChapterTheme theme;

  @override
  Widget build(BuildContext context) {
    final dark = theme.chromeBrightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: WbTokens.s2, bottom: WbTokens.s1),
      child: Material(
        color: theme.chromeSurface.withValues(alpha: 0.96),
        elevation: 1,
        borderRadius: BorderRadius.circular(WbTokens.rSm),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: WbTokens.s3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.accent,
                  ),
                ),
                const SizedBox(width: WbTokens.s3),
                Expanded(
                  child: Text(
                    theme.name,
                    style: WbTokens.textStyle(
                      fontSize: WbTokens.tMd,
                      fontWeight: FontWeight.w700,
                      color: theme.chromeOnSurface,
                    ),
                  ),
                ),
                Text(
                  '${theme.firstStage}–${theme.lastStage}',
                  style: WbTokens.textStyle(
                    fontSize: WbTokens.tSm,
                    fontWeight: FontWeight.w500,
                    color: theme.chromeOnSurface
                        .withValues(alpha: dark ? 0.7 : 0.55),
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
