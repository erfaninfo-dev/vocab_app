import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/vocab_entry.dart';
import '../../data/services/api_service.dart';

class ImportantWordsState {
  const ImportantWordsState({required this.importantWordRowIds});

  final Set<int> importantWordRowIds;

  bool isMarked(VocabEntry e) =>
      e.rowId > 0 && importantWordRowIds.contains(e.rowId);

  ImportantWordsState copyWith({Set<int>? importantWordRowIds}) {
    return ImportantWordsState(
      importantWordRowIds: importantWordRowIds ?? this.importantWordRowIds,
    );
  }
}

class ImportantWordsController extends Notifier<ImportantWordsState> {
  static const _rowIdsKey = 'important_word_row_ids_v1';

  @override
  ImportantWordsState build() {
    _hydrate();
    return const ImportantWordsState(importantWordRowIds: <int>{});
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final rowRaw = prefs.getStringList(_rowIdsKey) ?? const <String>[];
    final rows = <int>{};
    for (final s in rowRaw) {
      final v = int.tryParse(s);
      if (v != null && v > 0) rows.add(v);
    }
    state = ImportantWordsState(importantWordRowIds: rows);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _rowIdsKey,
      state.importantWordRowIds.map((e) => '$e').toList()..sort(),
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
    final merged = {...localRows, ...server};
    state = state.copyWith(importantWordRowIds: merged);
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
    if (important) {
      rows.add(entry.rowId);
    } else {
      rows.remove(entry.rowId);
    }
    state = state.copyWith(importantWordRowIds: rows);
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
