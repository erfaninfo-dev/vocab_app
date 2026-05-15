import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../application/word_builder_game_notifier.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';

class WordBuilderLobbyScreen extends ConsumerWidget {
  const WordBuilderLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progAsync = ref.watch(wordBuilderCampaignProgressProvider);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF87CEEB), scheme.surface, isDark ? 0.35 : 0.12) ??
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
          title: Text(l10n.wordBuilderTitle),
          actions: [
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.wordBuilderCampaignReset),
                    content: Text(l10n.wordBuilderCampaignResetConfirm),
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
                if (ok == true && context.mounted) {
                  await ref
                      .read(wordBuilderProgressRepoProvider)
                      .stripCampaignLevelEntries();
                  await ref
                      .read(wordBuilderCampaignProgressRepositoryProvider)
                      .reset();
                  ref.invalidate(wordBuilderCampaignProgressProvider);
                  for (final d in WordBuilderDifficulty.values) {
                    for (var s = 1; s <= kWordBuilderStagesPerTier; s++) {
                      ref.invalidate(
                        wordBuilderGameProvider(
                          encodeWordBuilderCampaignSessionKey(d, s),
                        ),
                      );
                    }
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.wordBuilderCampaignResetDone)),
                    );
                  }
                }
              },
              child: Text(
                l10n.wordBuilderCampaignReset,
                style: TextStyle(color: scheme.error),
              ),
            ),
          ],
        ),
        body: progAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: scheme.primary)),
          error: (_, __) => Center(child: Text(l10n.errorGeneric)),
          data: (progress) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (l10n.wordBuilderCampaignHubSubtitle.trim().isNotEmpty) ...[
                    Text(
                      l10n.wordBuilderCampaignHubSubtitle,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _TierLaunchCard(
                    title: l10n.wordBuilderDifficultyBeginner,
                    subtitle:
                        '${progress.beginnerStagesCleared}/$kWordBuilderStagesPerTier',
                    scheme: scheme,
                    onTap: () =>
                        context.push('/word-builder/campaign?difficulty=beginner'),
                  ),
                  const SizedBox(height: 14),
                  _TierLaunchCard(
                    title: l10n.wordBuilderDifficultyIntermediate,
                    subtitle:
                        '${progress.intermediateStagesCleared}/$kWordBuilderStagesPerTier',
                    scheme: scheme,
                    onTap: () => context
                        .push('/word-builder/campaign?difficulty=intermediate'),
                  ),
                  const SizedBox(height: 14),
                  _TierLaunchCard(
                    title: l10n.wordBuilderDifficultyAdvanced,
                    subtitle:
                        '${progress.advancedStagesCleared}/$kWordBuilderStagesPerTier',
                    scheme: scheme,
                    onTap: () =>
                        context.push('/word-builder/campaign?difficulty=advanced'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TierLaunchCard extends StatelessWidget {
  const _TierLaunchCard({
    required this.title,
    required this.subtitle,
    required this.scheme,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E7), Color(0xFFFFECB3)],
            ),
            border: Border.all(
              color: const Color(0xFFC4956A).withValues(alpha: 0.75),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.14),
                blurRadius: 16,
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
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: tt.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 44,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
