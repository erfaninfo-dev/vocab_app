import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/profile/profile_avatar.dart';
import '../../../data/models/league.dart';
import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../application/word_builder_coins_provider.dart';
import '../application/word_builder_game_notifier.dart';
import '../application/word_builder_league_provider.dart';
import '../data/word_builder_campaign_progress_repository.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';
import 'widgets/magic_background.dart';
import 'widgets/word_builder_coins_chip.dart';

class WordBuilderLobbyScreen extends ConsumerStatefulWidget {
  const WordBuilderLobbyScreen({super.key});

  @override
  ConsumerState<WordBuilderLobbyScreen> createState() =>
      _WordBuilderLobbyScreenState();
}

class _WordBuilderLobbyScreenState extends ConsumerState<WordBuilderLobbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshWordBuilderLobby();
    });
  }

  Future<void> _refreshWordBuilderLobby() async {
    ref.invalidate(wordBuilderCampaignProgressProvider);
    ref.invalidate(wordBuilderCoinsProvider);
    if (ref.read(authProvider).valueOrNull != null) {
      ref.invalidate(wordBuilderLeagueProvider);
    }

    final futures = <Future<Object?>>[
      ref.read(wordBuilderCampaignProgressProvider.future),
      ref.read(wordBuilderCoinsProvider.future),
    ];
    if (ref.read(authProvider).valueOrNull != null) {
      futures.add(ref.read(wordBuilderLeagueProvider.future));
    }
    try {
      await Future.wait(futures);
    } catch (_) {
      // Pull-to-refresh should settle even if the network is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progAsync = ref.watch(wordBuilderCampaignProgressProvider);
    final coinsAsync = ref.watch(wordBuilderCoinsProvider);
    final auth = ref.watch(authProvider).valueOrNull;
    final leagueAsync = auth == null
        ? null
        : ref.watch(wordBuilderLeagueProvider);
    final canPop = context.canPop();

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
              toolbarHeight: 76,
              title: const SizedBox.shrink(),
              centerTitle: false,
              automaticallyImplyLeading: false,
              leadingWidth: canPop ? 52 : 0,
              leading: canPop
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark
                                ? scheme.onSurface
                                : const Color(0xFF5D4037),
                          ),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () => context.pop(),
                        ),
                      ),
                    )
                  : null,
          actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 14, end: 8),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _ResetTopCard(
                      label: 'Reset',
                      onTap: () => _confirmReset(context, ref, l10n),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 14, end: 10),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: coinsAsync.when(
                      data: (c) => WordBuilderCoinsChip(
                        balanceLabel: l10n.wordBuilderCoinsBalance(c),
                        isDark: isDark,
                        scheme: scheme,
                      ),
                      loading: () =>
                          WordBuilderCoinsChipLoading(scheme: scheme),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
              ),
            ),
          ],
        ),
        body: progAsync.when(
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
          data: (progress) => SafeArea(
                child: RefreshIndicator(
                  color: const Color(0xFFFFB300),
                  onRefresh: _refreshWordBuilderLobby,
            child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                        if (l10n.wordBuilderCampaignHubSubtitle
                            .trim()
                            .isNotEmpty) ...[
                  Text(
                    l10n.wordBuilderCampaignHubSubtitle,
                    textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                              color: const Color(0xFF5D4037),
                    ),
                  ),
                          const SizedBox(height: 18),
                        ],
                  _TierLaunchCard(
                    title: l10n.wordBuilderDifficultyBeginner,
                          subtitle:
                              '${progress.beginnerStagesCleared}/$kWordBuilderStagesPerTier',
                          onTap: () => context.push(
                            '/word-builder/campaign?difficulty=beginner',
                          ),
                  ),
                  const SizedBox(height: 14),
                  _TierLaunchCard(
                    title: l10n.wordBuilderDifficultyIntermediate,
                          subtitle:
                              progress.isDifficultyUnlocked(
                                WordBuilderDifficulty.intermediate,
                              )
                              ? '${progress.intermediateStagesCleared}/$kWordBuilderStagesPerTier'
                              : l10n.wordBuilderTierLockedIntermediateSubtitle,
                          locked: !progress.isDifficultyUnlocked(
                            WordBuilderDifficulty.intermediate,
                          ),
                          onTap: () {
                            if (!progress.isDifficultyUnlocked(
                              WordBuilderDifficulty.intermediate,
                            )) {
                              _showLockedTierMessage(
                                context,
                                l10n.wordBuilderTierLockedIntermediateMessage,
                              );
                              return;
                            }
                            context.push(
                              '/word-builder/campaign?difficulty=intermediate',
                            );
                          },
                  ),
                  const SizedBox(height: 14),
                  _TierLaunchCard(
                    title: l10n.wordBuilderDifficultyAdvanced,
                          subtitle:
                              progress.isDifficultyUnlocked(
                                WordBuilderDifficulty.advanced,
                              )
                              ? '${progress.advancedStagesCleared}/$kWordBuilderStagesPerTier'
                              : l10n.wordBuilderTierLockedAdvancedSubtitle,
                          locked: !progress.isDifficultyUnlocked(
                            WordBuilderDifficulty.advanced,
                          ),
                          onTap: () {
                            if (!progress.isDifficultyUnlocked(
                              WordBuilderDifficulty.advanced,
                            )) {
                              _showLockedTierMessage(
                                context,
                                l10n.wordBuilderTierLockedAdvancedMessage,
                              );
                              return;
                            }
                            context.push(
                              '/word-builder/campaign?difficulty=advanced',
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        _WordBuilderLeagueCard(
                          progress: progress,
                          coins: coinsAsync.valueOrNull,
                          leagueAsync: leagueAsync,
                          signedIn: auth != null,
                        ),
                        const SizedBox(height: 44),
                ],
              ),
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.wordBuilderCampaignReset,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.wordBuilderCampaignResetConfirm,
          style: GoogleFonts.fredoka(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.wordBuilderCampaignReset),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await ref.read(wordBuilderProgressRepoProvider).stripCampaignLevelEntries();
    await ref.read(wordBuilderCampaignProgressRepositoryProvider).reset();
    for (final d in WordBuilderDifficulty.values) {
      for (var s = 1; s <= kWordBuilderStagesPerTier; s++) {
        ref.invalidate(
          wordBuilderGameProvider(encodeWordBuilderCampaignSessionKey(d, s)),
        );
      }
    }
    await _refreshWordBuilderLobby();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wordBuilderCampaignResetDone)),
      );
    }
  }

  void _showLockedTierMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w800),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5D4037),
      ),
    );
  }
}

class _TierLaunchCard extends StatelessWidget {
  const _TierLaunchCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? const [
                      Color(0xFFFFF8E1),
                      Color(0xFFFFE0E8),
                      Color(0xFFE9E4FF),
                    ]
                  : const [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
            border: Border.all(
              color: locked
                  ? const Color(0xFFFFB300).withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.55),
              width: locked ? 2.2 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (locked ? const Color(0xFFE1306C) : Colors.orange)
                    .withValues(alpha: locked ? 0.18 : 0.35),
                blurRadius: locked ? 20 : 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
              if (locked)
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: locked
                              ? const Color(0xFF5D4037)
                              : const Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: locked
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: locked
                              ? const Color(0xFF7A4E32)
                              : const Color(0xFF8D6E63),
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: locked
                          ? const [Color(0xFFFFB300), Color(0xFFE1306C)]
                          : const [Color(0xFFFFD54F), Color(0xFFFFB300)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (locked ? const Color(0xFFE1306C) : Colors.orange)
                                .withValues(alpha: 0.45),
                        blurRadius: locked ? 16 : 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                      size: 32,
                      color: locked ? Colors.white : const Color(0xFF5D4037),
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

class _ResetTopCard extends StatelessWidget {
  const _ResetTopCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF3E0), Color(0xFFFFCCBC)],
            ),
            border: Border.all(
              color: const Color(0xFFFF7043).withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7043).withValues(alpha: 0.22),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFAB91), Color(0xFFFF7043)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7043).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(
                      Icons.restart_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFBF360C),
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

class _WordBuilderLeagueCard extends StatelessWidget {
  const _WordBuilderLeagueCard({
    required this.progress,
    required this.coins,
    required this.leagueAsync,
    required this.signedIn,
  });

  final WordBuilderCampaignProgressSnapshot progress;
  final int? coins;
  final AsyncValue<WordBuilderLeaguePagedState>? leagueAsync;
  final bool signedIn;

  int get _currentStage {
    return wordBuilderOverallStageFromProgress(
      beginnerStagesCleared: progress.beginnerStagesCleared,
      intermediateStagesCleared: progress.intermediateStagesCleared,
      advancedStagesCleared: progress.advancedStagesCleared,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColors = isDark
        ? const [Color(0xFF24152B), Color(0xFF4A2341), Color(0xFF2D2640)]
        : const [Color(0xFFFFF8E1), Color(0xFFFFDDE8), Color(0xFFFFECB3)];
    final titleColor = isDark
        ? const Color(0xFFFFF8E1)
        : const Color(0xFF4E342E);
    final subColor = isDark
        ? const Color(0xFFFFECB3).withValues(alpha: 0.86)
        : const Color(0xFF7A4E32);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final tight = constraints.maxWidth < 340;
        final titleSize = tight ? 15.5 : (compact ? 17.0 : 19.0);
        final subtitleSize = tight ? 10.8 : (compact ? 11.4 : 12.5);
        final iconBoxPadding = compact ? 9.0 : 11.0;
        final iconSize = compact ? 26.0 : 30.0;
        final gap = compact ? 9.0 : 12.0;
        const cardRadius = 26.0;
        final cardContent = Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 13 : 16,
            16,
            compact ? 13 : 16,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFE1306C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFE1306C,
                          ).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(iconBoxPadding),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Word Builder League',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          compact
                              ? 'Lifetime players and progress'
                              : 'Lifetime players, coins, and level progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontSize: subtitleSize,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LeagueOpenArrow(color: titleColor),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _LeagueMetricPill(
                      icon: Icons.monetization_on_rounded,
                      label: 'Your coins',
                      value: coins == null ? '-' : '$coins',
                      isDark: isDark,
                      compact: compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LeagueMetricPill(
                      icon: Icons.flag_rounded,
                      label: 'Your level',
                      value: _wordBuilderLeagueLevelLabel(_currentStage),
                      isDark: isDark,
                      compact: compact,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _LeaguePreviewBody(
                    leagueAsync: leagueAsync,
                    signedIn: signedIn,
                    isDark: isDark,
                    scheme: scheme,
                    expanded: false,
                  ),
                ),
              ),
            ],
          ),
        );

        return GestureDetector(
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -160) {
              _showWordBuilderLeagueOverlay(context);
            }
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFE1306C,
                  ).withValues(alpha: isDark ? 0.28 : 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.28 : 0.06,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cardRadius),
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showWordBuilderLeagueOverlay(context),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: cardColors,
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFFFFB300,
                        ).withValues(alpha: isDark ? 0.7 : 0.95),
                        width: 2,
                      ),
                    ),
                    child: cardContent,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWordBuilderLeagueOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.30 : 0.18),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(curved);

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * animation.value,
            sigmaY: 5 * animation.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SlideTransition(
                      position: slide,
                      child: GestureDetector(
                        onTap: () {},
                        child: _WordBuilderLeagueOverlayPanel(
                          progress: progress,
                          coins: coins,
                          signedIn: signedIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeagueOpenArrow extends StatefulWidget {
  const _LeagueOpenArrow({required this.color});

  final Color color;

  @override
  State<_LeagueOpenArrow> createState() => _LeagueOpenArrowState();
}

class _LeagueOpenArrowState extends State<_LeagueOpenArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _lift = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _lift,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _lift.value),
          child: child,
        );
      },
      child: Icon(
        Icons.keyboard_arrow_up_rounded,
        color: widget.color.withValues(alpha: 0.82),
        size: 34,
      ),
    );
  }
}

class _WordBuilderLeagueOverlayPanel extends ConsumerStatefulWidget {
  const _WordBuilderLeagueOverlayPanel({
    required this.progress,
    required this.coins,
    required this.signedIn,
  });

  final WordBuilderCampaignProgressSnapshot progress;
  final int? coins;
  final bool signedIn;

  @override
  ConsumerState<_WordBuilderLeagueOverlayPanel> createState() =>
      _WordBuilderLeagueOverlayPanelState();
}

class _WordBuilderLeagueOverlayPanelState
    extends ConsumerState<_WordBuilderLeagueOverlayPanel> {
  void _maybeLoadMore(ScrollMetrics metrics) {
    if (!metrics.hasViewportDimension) return;
    if (metrics.maxScrollExtent <= 0) return;
    if (metrics.pixels < metrics.maxScrollExtent - 220) return;
    ref.read(wordBuilderLeagueProvider.notifier).loadMore();
  }

  int get _currentStage {
    return wordBuilderOverallStageFromProgress(
      beginnerStagesCleared: widget.progress.beginnerStagesCleared,
      intermediateStagesCleared: widget.progress.intermediateStagesCleared,
      advancedStagesCleared: widget.progress.advancedStagesCleared,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFFFF8E1)
        : const Color(0xFF4E342E);
    final subColor = isDark
        ? const Color(0xFFFFECB3).withValues(alpha: 0.86)
        : const Color(0xFF7A4E32);
    final leagueAsync = widget.signedIn
        ? ref.watch(wordBuilderLeagueProvider)
        : null;
    final screenSize = MediaQuery.sizeOf(context);
    final panelWidth = math.min(screenSize.width - 36, 520.0);
    final compact = panelWidth < 390;
    final tight = panelWidth < 340;
    final titleSize = tight ? 16.5 : (compact ? 18.0 : 20.0);
    final subtitleSize = tight ? 10.8 : (compact ? 11.5 : 12.5);
    final leagueState = leagueAsync?.valueOrNull;
    final knownPlayers =
        leagueState?.response.summary.participants ??
        leagueState?.entries.length ??
        0;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final reservedVerticalSpace = viewPadding.top + viewPadding.bottom + 86;
    final availablePanelHeight = math.max(
      360.0,
      screenSize.height - reservedVerticalSpace,
    );
    final targetMaxHeight =
        screenSize.height * (knownPlayers >= 8 ? 0.88 : 0.76);
    final maxPanelHeight = math.min(targetMaxHeight, availablePanelHeight);
    final minPanelHeight = knownPlayers >= 8
        ? math.min(screenSize.height * 0.74, maxPanelHeight)
        : 0.0;
    final cardColors = isDark
        ? const [Color(0xFF24152B), Color(0xFF4A2341), Color(0xFF2D2640)]
        : const [Color(0xFFFFF8E1), Color(0xFFFFDDE8), Color(0xFFFFECB3)];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: maxPanelHeight,
        minHeight: minPanelHeight,
      ),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardColors,
            ),
            border: Border.all(
              color: const Color(
                0xFFFFB300,
              ).withValues(alpha: isDark ? 0.78 : 0.95),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFE1306C,
                ).withValues(alpha: isDark ? 0.34 : 0.24),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification ||
                    notification is ScrollEndNotification) {
                  _maybeLoadMore(notification.metrics);
                }
                return false;
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB300), Color(0xFFE1306C)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE1306C,
                                ).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(11),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Word Builder League',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.fredoka(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                compact
                                    ? 'Lifetime players and progress'
                                    : 'Lifetime players, coins, and level progress',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.fredoka(
                                  fontSize: subtitleSize,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _LeagueMetricPill(
                            icon: Icons.monetization_on_rounded,
                            label: 'Your coins',
                            value: widget.coins == null
                                ? '-'
                                : '${widget.coins}',
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LeagueMetricPill(
                            icon: Icons.flag_rounded,
                            label: 'Your level',
                            value: _wordBuilderLeagueLevelLabel(_currentStage),
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _LeaguePreviewBody(
                      leagueAsync: leagueAsync,
                      signedIn: widget.signedIn,
                      isDark: isDark,
                      scheme: scheme,
                      expanded: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _wordBuilderLeagueLevelLabel(int overallStage) {
  final maxStages =
      kWordBuilderStagesPerTier * WordBuilderDifficulty.values.length;
  final safeStage = overallStage.clamp(1, maxStages);
  final difficultyIndex = (safeStage - 1) ~/ kWordBuilderStagesPerTier;
  final level = ((safeStage - 1) % kWordBuilderStagesPerTier) + 1;
  final difficulty = WordBuilderDifficulty.values[difficultyIndex];
  final difficultyName = switch (difficulty) {
    WordBuilderDifficulty.beginner => 'Beginner',
    WordBuilderDifficulty.intermediate => 'Intermediate',
    WordBuilderDifficulty.advanced => 'Advanced',
  };
  return '$difficultyName • Level $level';
}

class _LeagueMetricPill extends StatelessWidget {
  const _LeagueMetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.58);
    final fg = isDark ? const Color(0xFFFFF8E1) : const Color(0xFF5D4037);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFFFFB300,
          ).withValues(alpha: isDark ? 0.34 : 0.44),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB300), size: compact ? 19 : 22),
            SizedBox(width: compact ? 6 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      color: fg.withValues(alpha: 0.72),
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      color: fg,
                      fontSize: compact ? 12.5 : 14.5,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
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

class _LeaguePreviewBody extends StatelessWidget {
  const _LeaguePreviewBody({
    required this.leagueAsync,
    required this.signedIn,
    required this.isDark,
    required this.scheme,
    required this.expanded,
  });

  final AsyncValue<WordBuilderLeaguePagedState>? leagueAsync;
  final bool signedIn;
  final bool isDark;
  final ColorScheme scheme;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (!signedIn) {
      return _LeaguePreviewMessage(
        icon: Icons.login_rounded,
        title: 'Sign in to join the lifetime race',
        body: 'Your coins and progress can compete with other learners.',
        isDark: isDark,
      );
    }
    final async = leagueAsync;
    if (async == null) return const SizedBox.shrink();
    return async.when(
      loading: () => const _LeaguePreviewSkeleton(),
      error: (_, __) => _LeaguePreviewMessage(
        icon: Icons.wifi_off_rounded,
        title: 'League is unavailable',
        body: 'Check your connection and try again later.',
        isDark: isDark,
      ),
      data: (state) {
        final league = state.response;
        final entries = expanded
            ? state.entries
            : state.entries.take(3).toList();
        if (entries.isEmpty) {
          return _LeaguePreviewMessage(
            icon: Icons.groups_rounded,
            title: 'No players yet',
            body: 'Play and earn coins to become the first leader.',
            isDark: isDark,
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Text(
                  '${league.summary.participants} players lifetime',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFFFECB3)
                        : const Color(0xFF6D4C41),
                  ),
                ),
                const Spacer(),
                Text(
                  'Top players',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(height: 7),
              _LeagueMiniRow(entry: entries[i], isDark: isDark),
            ],
            if (expanded && (state.hasMore || state.isLoadingMore)) ...[
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: state.isLoadingMore
                      ? const CircularProgressIndicator(strokeWidth: 2.4)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LeagueMiniRow extends StatelessWidget {
  const _LeagueMiniRow({required this.entry, required this.isDark});

  final LeagueEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? const Color(0xFFFFF8E1) : const Color(0xFF4E342E);
    final sub = isDark
        ? const Color(0xFFFFECB3).withValues(alpha: 0.72)
        : const Color(0xFF7A4E32);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.5);
    final rank = entry.rank;
    final stage = entry.completedCount > 0
        ? entry.completedCount
        : entry.activeDays;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showWordBuilderLeagueProfile(context, entry),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.36),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                _LeagueRankBadge(
                  rank: rank,
                  isDark: isDark,
                  hasScore: entry.points > 0,
                ),
                ProfileAvatar(
                  avatarId: entry.avatar,
                  userId: entry.userId,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _wordBuilderLeagueLevelLabel(stage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          color: sub,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFB300,
                    ).withValues(alpha: isDark ? 0.16 : 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFFFB300),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.points}',
                          style: GoogleFonts.fredoka(
                            color: fg,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
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

void _showWordBuilderLeagueProfile(BuildContext context, LeagueEntry entry) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => _WordBuilderLeagueProfileDialog(entry: entry),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _WordBuilderLeagueProfileDialog extends StatelessWidget {
  const _WordBuilderLeagueProfileDialog({required this.entry});

  final LeagueEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFFFF8E1)
        : const Color(0xFF4E342E);
    final subColor = isDark
        ? const Color(0xFFFFECB3).withValues(alpha: 0.82)
        : const Color(0xFF6D4C41);
    final bio = (entry.bio ?? '').trim();
    final rank = entry.rank == null
        ? entry.badge
        : '${entry.rank} • ${entry.badge}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF24152B),
                      Color(0xFF4A2341),
                      Color(0xFF2D2640),
                    ]
                  : const [
                      Color(0xFFFFF8E1),
                      Color(0xFFFFDDE8),
                      Color(0xFFFFECB3),
                    ],
            ),
            border: Border.all(
              color: const Color(
                0xFFFFB300,
              ).withValues(alpha: isDark ? 0.72 : 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileAvatar(
                      avatarId: entry.avatar,
                      userId: entry.userId,
                      size: 104,
                      showBorder: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      entry.displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        color: titleColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.28 : 0.72,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF9800,
                            ).withValues(alpha: isDark ? 0.24 : 0.34),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        child: Text(
                          rank,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF4E342E),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.07 : 0.48,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.08 : 0.34,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  size: 22,
                                  color: Color(0xFFFFB300),
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  'Bio',
                                  style: GoogleFonts.fredoka(
                                    color: const Color(0xFFFFB300),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bio.isEmpty ? 'No bio yet.' : bio,
                              style: GoogleFonts.fredoka(
                                color: bio.isEmpty
                                    ? subColor.withValues(alpha: 0.78)
                                    : titleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                                fontStyle: bio.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueRankBadge extends StatelessWidget {
  const _LeagueRankBadge({
    required this.rank,
    required this.isDark,
    required this.hasScore,
  });

  final int? rank;
  final bool isDark;
  final bool hasScore;

  @override
  Widget build(BuildContext context) {
    final value = rank == null ? '-' : '${rank!}';
    final medalRank = hasScore && rank != null && rank! <= 3 ? rank : null;
    final activeNonMedal = hasScore && medalRank == null;
    final colors = switch (medalRank) {
      1 => const [Color(0xFFFFD54F), Color(0xFFFF9800)],
      2 => const [Color(0xFFECEFF1), Color(0xFF90A4AE)],
      3 => const [Color(0xFFFFCC80), Color(0xFFBF6D2F)],
      _ =>
        activeNonMedal
            ? (isDark
                  ? const [Color(0xFF1565C0), Color(0xFF7E57C2)]
                  : const [Color(0xFF42A5F5), Color(0xFF7E57C2)])
            : (isDark
                  ? const [Color(0xFF3A302B), Color(0xFF5D4037)]
                  : const [Color(0xFFFFF8E1), Color(0xFFFFE0B2)]),
    };
    final fg = switch (medalRank) {
      1 => const Color(0xFF4E342E),
      2 => const Color(0xFF263238),
      null =>
        activeNonMedal
            ? Colors.white
            : (isDark ? const Color(0xFFFFF8E1) : const Color(0xFF5D4037)),
      _ => Colors.white,
    };
    final borderColor = hasScore
        ? Colors.white.withValues(alpha: isDark ? 0.28 : 0.74)
        : const Color(0xFFFFB300).withValues(alpha: isDark ? 0.36 : 0.48);
    final shadowColor = hasScore
        ? colors.last.withValues(alpha: isDark ? 0.24 : 0.32)
        : const Color(0xFFFFB300).withValues(alpha: isDark ? 0.08 : 0.14);

    return SizedBox(
      width: 42,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(
              color: borderColor,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: hasScore ? 10 : 6,
                offset: Offset(0, hasScore ? 4 : 2),
              ),
            ],
          ),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: Text(
                value,
                style: GoogleFonts.fredoka(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaguePreviewMessage extends StatelessWidget {
  const _LeaguePreviewMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? const Color(0xFFFFF8E1) : const Color(0xFF4E342E);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB300), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: GoogleFonts.fredoka(
                      color: fg.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
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

class _LeaguePreviewSkeleton extends StatelessWidget {
  const _LeaguePreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ],
    );
  }
}
