import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../application/word_builder_coins_provider.dart';
import '../application/word_builder_game_notifier.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';
import 'widgets/magic_background.dart';
import 'widgets/word_builder_coins_chip.dart';

class WordBuilderLobbyScreen extends ConsumerWidget {
  const WordBuilderLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progAsync = ref.watch(wordBuilderCampaignProgressProvider);
    final coinsAsync = ref.watch(wordBuilderCoinsProvider);
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
              toolbarHeight: kToolbarHeight,
              title: const SizedBox.shrink(),
              centerTitle: false,
              automaticallyImplyLeading: false,
              leading: canPop
                  ? IconButton(
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
                    )
                  : null,
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: Center(
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
                child: SingleChildScrollView(
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
                            '${progress.intermediateStagesCleared}/$kWordBuilderStagesPerTier',
                        onTap: () => context.push(
                          '/word-builder/campaign?difficulty=intermediate',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TierLaunchCard(
                        title: l10n.wordBuilderDifficultyAdvanced,
                        subtitle:
                            '${progress.advancedStagesCleared}/$kWordBuilderStagesPerTier',
                        onTap: () => context.push(
                          '/word-builder/campaign?difficulty=advanced',
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ResetProgressCard(
                        title: l10n.wordBuilderCampaignReset,
                        subtitle: l10n.wordBuilderCampaignResetConfirm,
                        onTap: () => _confirmReset(context, ref, l10n),
                      ),
                    ],
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
    ref.invalidate(wordBuilderCampaignProgressProvider);
    for (final d in WordBuilderDifficulty.values) {
      for (var s = 1; s <= kWordBuilderStagesPerTier; s++) {
        ref.invalidate(
          wordBuilderGameProvider(encodeWordBuilderCampaignSessionKey(d, s)),
        );
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wordBuilderCampaignResetDone)),
      );
    }
  }
}

class _TierLaunchCard extends StatelessWidget {
  const _TierLaunchCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
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
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8D6E63),
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: Color(0xFF5D4037),
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

class _ResetProgressCard extends StatelessWidget {
  const _ResetProgressCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
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
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.restart_alt_rounded,
                      size: 30,
                      color: Colors.white,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFBF360C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6D4C41),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFBF360C),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
