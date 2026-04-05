import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../words/widgets/word_card.dart';
import '../words/word_preferences_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(wordPreferencesProvider).favoriteIds;
    final booksValue = ref.watch(apiBooksProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.06),
              scheme.surface,
            ],
          ),
        ),
        child: booksValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (books) {
            final allWordsValues = books
                .map((book) => ref.watch(apiAllWordsForBookProvider(book.id)))
                .toList();

            final isLoading = allWordsValues.any((v) => v is AsyncLoading);
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allEntries = <VocabEntry>[];
            for (final value in allWordsValues) {
              value.whenData(allEntries.addAll);
            }

            final favEntries = _filter(allEntries, favorites);
            if (favEntries.isEmpty) {
              return const Center(child: Text('No favorite words yet.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemBuilder: (context, index) =>
                  WordCard(entry: favEntries[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: favEntries.length,
            );
          },
        ),
      ),
    );
  }

  List<VocabEntry> _filter(List<VocabEntry> source, Set<String> ids) {
    return source.where((entry) => ids.contains(entry.id)).toList();
  }
}
