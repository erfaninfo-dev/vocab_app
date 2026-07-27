import 'package:flutter/material.dart';

import '../../domain/word_builder_game_logic.dart';

/// GlobalKeys for AnswerSlots cells so Angry Words can fly letters into them.
class AnswerSlotKeyBag {
  final Map<String, List<GlobalKey>> _keys = {};

  GlobalKey keyFor(String word, int letterIndex) {
    final norm = normalizeWord(word);
    final list = _keys.putIfAbsent(norm, () => <GlobalKey>[]);
    while (list.length <= letterIndex) {
      list.add(GlobalKey(debugLabel: 'slot:$norm:${list.length}'));
    }
    return list[letterIndex];
  }

  /// Center of each letter cell in global coordinates (null if not laid out).
  List<Offset?> globalCentersFor(String word) {
    final norm = normalizeWord(word);
    final list = _keys[norm];
    if (list == null || list.isEmpty) return const [];
    return [
      for (final key in list) _centerOf(key),
    ];
  }

  static Offset? _centerOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}
