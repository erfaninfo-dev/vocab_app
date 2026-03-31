import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordPreferencesState {
  const WordPreferencesState({
    required this.favoriteIds,
    required this.difficultIds,
  });

  final Set<String> favoriteIds;
  final Set<String> difficultIds;

  WordPreferencesState copyWith({
    Set<String>? favoriteIds,
    Set<String>? difficultIds,
  }) {
    return WordPreferencesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      difficultIds: difficultIds ?? this.difficultIds,
    );
  }
}

class WordPreferencesController extends Notifier<WordPreferencesState> {
  static const _favoritesKey = 'favorite_words';
  static const _difficultKey = 'difficult_words';

  @override
  WordPreferencesState build() {
    _hydrate();
    return const WordPreferencesState(
      favoriteIds: <String>{},
      difficultIds: <String>{},
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    state = WordPreferencesState(
      favoriteIds: prefs.getStringList(_favoritesKey)?.toSet() ?? <String>{},
      difficultIds: prefs.getStringList(_difficultKey)?.toSet() ?? <String>{},
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

  Future<void> toggleDifficult(String id) async {
    final updated = {...state.difficultIds};
    if (!updated.add(id)) {
      updated.remove(id);
    }
    state = state.copyWith(difficultIds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_difficultKey, updated.toList());
  }
}

final wordPreferencesProvider =
    NotifierProvider<WordPreferencesController, WordPreferencesState>(
      WordPreferencesController.new,
    );
