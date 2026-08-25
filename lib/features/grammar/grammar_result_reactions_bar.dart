import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/grammar_result_reaction.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class GrammarResultReactionsBar extends ConsumerWidget {
  const GrammarResultReactionsBar({
    super.key,
    required this.resultId,
    this.summary,
    this.compact = false,
    this.accentColor,
  });

  final int resultId;
  final GrammarResultReactionSummary? summary;
  final bool compact;
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (resultId < 1) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final live = ref.watch(grammarResultReactionsProvider)[resultId] ?? summary;
    final counts = live?.counts ?? const {};
    final myEmoji = live?.myEmoji;
    final session = ref.watch(authProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final emoji in kGrammarResultReactionEmojis)
          _ReactionChip(
            emoji: emoji,
            count: counts[emoji] ?? 0,
            selected: myEmoji == emoji,
            compact: compact,
            scheme: scheme,
            accentColor: accentColor,
            onTap: () async {
              if (session == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.grammarReactionSignInRequired)),
                );
                return;
              }
              try {
                await ref
                    .read(grammarResultReactionsProvider.notifier)
                    .toggleReaction(resultId: resultId, emoji: emoji);
              } catch (e) {
                if (!context.mounted) return;
                final message = e.toString().replaceFirst('Exception: ', '');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      message.isEmpty || message == 'HTTP 500'
                          ? l10n.errorConnectionTryAgain
                          : message,
                    ),
                  ),
                );
              }
            },
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.compact,
    required this.scheme,
    this.accentColor,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool selected;
  final bool compact;
  final ColorScheme scheme;
  final Color? accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final showCount = count > 0;
    final accent = accentColor ?? scheme.primary;
    final useCardStyle = compact && accentColor != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: useCardStyle ? 7 : (compact ? 8 : 10),
            vertical: useCardStyle ? 5 : (compact ? 4 : 6),
          ),
          decoration: BoxDecoration(
            color: useCardStyle
                ? Colors.white.withValues(alpha: 0.96)
                : selected
                ? accent.withValues(alpha: 0.16)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: useCardStyle ? 0.75 : 0.55)
                  : useCardStyle
                  ? Colors.white.withValues(alpha: 0.9)
                  : scheme.outlineVariant.withValues(alpha: 0.45),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: useCardStyle
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: compact ? 16 : 18)),
              if (showCount) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? accent : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
