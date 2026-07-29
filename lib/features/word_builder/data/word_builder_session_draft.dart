import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/word_builder_game_notifier.dart';

const String kWordBuilderSessionDraftPrefsKey = 'word_builder_session_draft_v1';

/// Mid-stage progress so kill/reopen does not lose the current word path (Phase 9).
@immutable
class WordBuilderSessionDraft {
  const WordBuilderSessionDraft({
    required this.bookKey,
    required this.levelIndex,
    required this.pathChars,
    required this.pathIds,
    required this.solvedLower,
    required this.wrongAnswerCount,
    required this.savedAtMs,
  });

  final int bookKey;
  final int levelIndex;
  final List<String> pathChars;
  final List<int> pathIds;
  final List<String> solvedLower;
  final int wrongAnswerCount;
  final int savedAtMs;

  Map<String, Object?> toJson() => {
        'v': 1,
        'bookKey': bookKey,
        'levelIndex': levelIndex,
        'pathChars': pathChars,
        'pathIds': pathIds,
        'solvedLower': solvedLower,
        'wrongAnswerCount': wrongAnswerCount,
        'savedAtMs': savedAtMs,
      };

  static WordBuilderSessionDraft? fromJson(Map<String, Object?> map) {
    final bookKey = (map['bookKey'] as num?)?.toInt();
    final levelIndex = (map['levelIndex'] as num?)?.toInt();
    if (bookKey == null || levelIndex == null) return null;
    final pathChars = (map['pathChars'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];
    final pathIds = (map['pathIds'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList(growable: false) ??
        const <int>[];
    final solved = (map['solvedLower'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];
    return WordBuilderSessionDraft(
      bookKey: bookKey,
      levelIndex: levelIndex,
      pathChars: pathChars,
      pathIds: pathIds,
      solvedLower: solved,
      wrongAnswerCount: (map['wrongAnswerCount'] as num?)?.toInt() ?? 0,
      savedAtMs: (map['savedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  static WordBuilderSessionDraft fromViewState({
    required int bookKey,
    required WordBuilderViewState s,
  }) {
    return WordBuilderSessionDraft(
      bookKey: bookKey,
      levelIndex: s.levelIndex,
      pathChars: [for (final L in s.path) L.char],
      pathIds: [for (final L in s.path) L.id],
      solvedLower: s.solvedLower.toList(growable: false),
      wrongAnswerCount: s.wrongAnswerCount,
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class WordBuilderSessionDraftRepository {
  Future<WordBuilderSessionDraft?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(kWordBuilderSessionDraftPrefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return WordBuilderSessionDraft.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(WordBuilderSessionDraft draft) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      kWordBuilderSessionDraftPrefsKey,
      jsonEncode(draft.toJson()),
    );
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(kWordBuilderSessionDraftPrefsKey);
  }

  Future<void> clearIfBook(int bookKey) async {
    final cur = await load();
    if (cur?.bookKey == bookKey) await clear();
  }
}
