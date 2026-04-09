import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordPreferencesState {
  const WordPreferencesState({
    required this.favoriteIds,
  });

  final Set<String> favoriteIds;

  WordPreferencesState copyWith({
    Set<String>? favoriteIds,
  }) {
    return WordPreferencesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

class WordPreferencesController extends Notifier<WordPreferencesState> {
  static const _favoritesKey = 'favorite_words';

  @override
  WordPreferencesState build() {
    _hydrate();
    return const WordPreferencesState(
      favoriteIds: <String>{},
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    state = WordPreferencesState(
      favoriteIds: prefs.getStringList(_favoritesKey)?.toSet() ?? <String>{},
    );
  }

  Future<void> toggleFavorite(String id) async {
    final updated = {...state.favoriteIds};
    if (!updated.add(id)) {
      updated.remove(id);
    }
    state = state.copyWith(favoriteIds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, updated.toList());
  }
}

final wordPreferencesProvider =
    NotifierProvider<WordPreferencesController, WordPreferencesState>(
      WordPreferencesController.new,
    );
