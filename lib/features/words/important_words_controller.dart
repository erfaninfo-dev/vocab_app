import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/vocab_entry.dart';
import '../../data/services/api_service.dart';

class ImportantWordsState {
  const ImportantWordsState({
    required this.importantWordRowIds,
    required this.unimportantWordRowIds,
  });

  final Set<int> importantWordRowIds;
  final Set<int> unimportantWordRowIds;

  bool isMarked(VocabEntry e) {
    // Prefer explicit user overrides (local or synced), otherwise fall back to
    // the server-provided default flag on the word row.
    if (e.rowId > 0 && unimportantWordRowIds.contains(e.rowId)) return false;
    if (e.rowId > 0 && importantWordRowIds.contains(e.rowId)) return true;
    return e.isImportant;
  }

  ImportantWordsState copyWith({
    Set<int>? importantWordRowIds,
    Set<int>? unimportantWordRowIds,
  }) {
    return ImportantWordsState(
      importantWordRowIds: importantWordRowIds ?? this.importantWordRowIds,
      unimportantWordRowIds: unimportantWordRowIds ?? this.unimportantWordRowIds,
    );
  }
}

class ImportantWordsController extends Notifier<ImportantWordsState> {
  static const _rowIdsKey = 'important_word_row_ids_v1';
  static const _unrowIdsKey = 'unimportant_word_row_ids_v1';

  @override
  ImportantWordsState build() {
    _hydrate();
    return const ImportantWordsState(
      importantWordRowIds: <int>{},
      unimportantWordRowIds: <int>{},
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final rowRaw = prefs.getStringList(_rowIdsKey) ?? const <String>[];
    final unrowRaw = prefs.getStringList(_unrowIdsKey) ?? const <String>[];
    final rows = <int>{};
    for (final s in rowRaw) {
      final v = int.tryParse(s);
      if (v != null && v > 0) rows.add(v);
    }
    final unrows = <int>{};
    for (final s in unrowRaw) {
      final v = int.tryParse(s);
      if (v != null && v > 0) unrows.add(v);
    }
    state = ImportantWordsState(
      importantWordRowIds: rows,
      unimportantWordRowIds: unrows,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _rowIdsKey,
      state.importantWordRowIds.map((e) => '$e').toList()..sort(),
    );
    await prefs.setStringList(
      _unrowIdsKey,
      state.unimportantWordRowIds.map((e) => '$e').toList()..sort(),
    );
  }

  Future<void> pullFromServer(ApiService api) async {
    late final Set<int> server;
    try {
      server = await api.fetchUserVocabMarks(kind: 'important');
    } catch (_) {
      return;
    }
    final localRows = Set<int>.from(state.importantWordRowIds);
    final localUnrows = Set<int>.from(state.unimportantWordRowIds);
    final mergedImportant = {...localRows, ...server}..removeAll(localUnrows);
    state = state.copyWith(importantWordRowIds: mergedImportant);
    await _persist();
    for (final id in localRows) {
      if (!server.contains(id)) {
        try {
          await api.addUserVocabMark(kind: 'important', wordId: id);
        } catch (_) {}
      }
    }
  }

  Future<void> setImportant(
    VocabEntry entry,
    bool important,
    ApiService? api,
  ) async {
    if (entry.rowId <= 0) return;
    final rows = {...state.importantWordRowIds};
    final unrows = {...state.unimportantWordRowIds};
    if (important) {
      rows.add(entry.rowId);
      unrows.remove(entry.rowId);
    } else {
      rows.remove(entry.rowId);
      unrows.add(entry.rowId);
    }
    state = state.copyWith(importantWordRowIds: rows, unimportantWordRowIds: unrows);
    await _persist();
    if (api != null) {
      try {
        if (important) {
          await api.addUserVocabMark(kind: 'important', wordId: entry.rowId);
        } else {
          await api.removeUserVocabMark(kind: 'important', wordId: entry.rowId);
        }
      } catch (_) {}
    }
  }
}

final importantWordsProvider =
    NotifierProvider<ImportantWordsController, ImportantWordsState>(
      ImportantWordsController.new,
    );
