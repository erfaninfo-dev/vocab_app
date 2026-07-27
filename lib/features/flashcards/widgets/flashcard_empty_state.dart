import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

enum FlashcardEmptyKind { noWords, important, favorites }

class FlashcardEmptyState extends StatelessWidget {
  const FlashcardEmptyState({
    super.key,
    required this.kind,
    required this.onAction,
  });

  final FlashcardEmptyKind kind;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final (icon, title, body, action) = switch (kind) {
      FlashcardEmptyKind.noWords => (
          Icons.style_outlined,
          l10n.flashcardNoWordsTitle,
          l10n.flashcardNoWordsBody,
          null,
        ),
      FlashcardEmptyKind.important => (
          Icons.priority_high_rounded,
          l10n.flashcardImportantEmptyTitle,
          l10n.flashcardImportantEmptyBody,
          l10n.flashcardImportantEmptyAction,
        ),
      FlashcardEmptyKind.favorites => (
          Icons.star_outline_rounded,
          l10n.flashcardFavoritesEmptyTitle,
          l10n.flashcardFavoritesEmptyBody,
          l10n.flashcardFavoritesEmptyAction,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
