import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/vocab_entry.dart';
import '../../data/services/api_service.dart';

class WordPreferencesState {
  const WordPreferencesState({
    required this.favoriteWordRowIds,
    required this.favoriteLegacyCompositeIds,
  });

  final Set<int> favoriteWordRowIds;
  final Set<String> favoriteLegacyCompositeIds;

  bool isFavorite(VocabEntry e) {
    if (e.rowId > 0 && favoriteWordRowIds.contains(e.rowId)) return true;
    return favoriteLegacyCompositeIds.contains(e.id);
  }

  WordPreferencesState copyWith({
    Set<int>? favoriteWordRowIds,
    Set<String>? favoriteLegacyCompositeIds,
  }) {
    return WordPreferencesState(
      favoriteWordRowIds: favoriteWordRowIds ?? this.favoriteWordRowIds,
      favoriteLegacyCompositeIds:
          favoriteLegacyCompositeIds ?? this.favoriteLegacyCompositeIds,
    );
  }
}

class WordPreferencesController extends Notifier<WordPreferencesState> {
  static const _legacyFavoritesKey = 'favorite_words';
  static const _rowIdsKey = 'favorite_word_row_ids_v1';

  @override
  WordPreferencesState build() {
    _hydrate();
    return const WordPreferencesState(
      favoriteWordRowIds: <int>{},
      favoriteLegacyCompositeIds: <String>{},
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy =
        prefs.getStringList(_legacyFavoritesKey)?.toSet() ?? <String>{};
    final rowRaw = prefs.getStringList(_rowIdsKey) ?? const <String>[];
    final rows = <int>{};
    for (final s in rowRaw) {
      final v = int.tryParse(s);
      if (v != null && v > 0) rows.add(v);
    }
    state = WordPreferencesState(
      favoriteWordRowIds: rows,
      favoriteLegacyCompositeIds: legacy,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _rowIdsKey,
      state.favoriteWordRowIds.map((e) => '$e').toList()..sort(),
    );
    await prefs.setStringList(
      _legacyFavoritesKey,
      state.favoriteLegacyCompositeIds.toList()..sort(),
    );
  }

  /// Merges server ids with local row ids, persists, uploads local-only rows.
  Future<void> pullFromServer(ApiService api) async {
    late final Set<int> server;
    try {
      server = await api.fetchUserVocabMarks(kind: 'favorite');
    } catch (_) {
      return;
    }
    final localRows = Set<int>.from(state.favoriteWordRowIds);
    final merged = {...localRows, ...server};
    state = state.copyWith(favoriteWordRowIds: merged);
    await _persist();
    for (final id in localRows) {
      if (!server.contains(id)) {
        try {
          await api.addUserVocabMark(kind: 'favorite', wordId: id);
        } catch (_) {}
      }
    }
  }

  Future<void> toggleFavorite(VocabEntry entry, ApiService? api) async {
    if (entry.rowId > 0) {
      final rows = {...state.favoriteWordRowIds};
      final legacy = {...state.favoriteLegacyCompositeIds}..remove(entry.id);
      final add = !rows.contains(entry.rowId);
      if (add) {
        rows.add(entry.rowId);
      } else {
        rows.remove(entry.rowId);
      }
      state = state.copyWith(
        favoriteWordRowIds: rows,
        favoriteLegacyCompositeIds: legacy,
      );
      await _persist();
      if (api != null) {
        try {
          if (add) {
            await api.addUserVocabMark(kind: 'favorite', wordId: entry.rowId);
          } else {
            await api.removeUserVocabMark(
              kind: 'favorite',
              wordId: entry.rowId,
            );
          }
        } catch (_) {}
      }
      return;
    }

    final legacy = {...state.favoriteLegacyCompositeIds};
    if (!legacy.add(entry.id)) {
      legacy.remove(entry.id);
    }
    state = state.copyWith(favoriteLegacyCompositeIds: legacy);
    await _persist();
  }
}

final wordPreferencesProvider =
    NotifierProvider<WordPreferencesController, WordPreferencesState>(
      WordPreferencesController.new,
    );
