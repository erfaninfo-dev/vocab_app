import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/api_providers.dart';
import '../data/word_builder_theme_categories.dart';

/// Resolved list of Word Builder theme categories for the current session.
///
/// On a successful API response, returns **only** what `game_word_categories.php`
/// sends — no merge with bundled words and no extra local topics. Topics with
/// an empty `words` array stay in the list but are shown disabled in the UI.
///
/// Bundled [kWordBuilderThemeCategories] is used only when the request fails
/// (offline / server down) so the picker still works without network.
final wordBuilderThemeCategoriesProvider =
    FutureProvider<List<WordBuilderThemeCategory>>((ref) async {
      try {
        final remote = await ref.watch(apiGameWordCategoriesProvider.future);
        return [
          for (final c in remote) WordBuilderThemeCategory.fromRemote(c),
        ];
      } catch (_) {
        return kWordBuilderThemeCategories;
      }
    });
