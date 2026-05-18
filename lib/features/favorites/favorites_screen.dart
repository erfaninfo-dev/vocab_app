import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../words/widgets/word_card.dart';
import '../words/important_words_controller.dart';
import '../words/word_preferences_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    final api = ref.read(apiServiceProvider);
    await refreshAllRemoteApiData(ref);
    if (api.authToken != null && api.authToken!.isNotEmpty) {
      await ref.read(wordPreferencesProvider.notifier).pullFromServer(api);
      await ref.read(importantWordsProvider.notifier).pullFromServer(api);
    }
    try {
      final books = await ref.read(apiBooksProvider.future);
      await Future.wait(
        books.map((b) => ref.read(apiAllWordsForBookProvider(b.id).future)),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(wordPreferencesProvider);
    final booksValue = ref.watch(apiBooksProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favorites)),
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
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: booksValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(userFriendlyErrorMessage(error, l10n))),
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

            final favEntries =
                allEntries.where((e) => prefs.isFavorite(e)).toList();
            if (favEntries.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 220),
                  Center(child: Text(l10n.noFavoriteWordsYet)),
                ],
              );
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
      ),
    );
  }
}
