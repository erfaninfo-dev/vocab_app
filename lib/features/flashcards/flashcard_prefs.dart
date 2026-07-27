import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/flashcard_direction.dart';
import 'models/flashcard_pool.dart';

class FlashcardPrefs {
  const FlashcardPrefs({
    this.defaultPool = FlashcardPool.all,
    this.defaultDirection = FlashcardDirection.wordToMeaning,
    this.shuffle = false,
    this.srsEnabled = true,
    this.swipeRatings = true,
  });

  final FlashcardPool defaultPool;
  final FlashcardDirection defaultDirection;
  final bool shuffle;
  final bool srsEnabled;
  final bool swipeRatings;

  FlashcardPrefs copyWith({
    FlashcardPool? defaultPool,
    FlashcardDirection? defaultDirection,
    bool? shuffle,
    bool? srsEnabled,
    bool? swipeRatings,
  }) {
    return FlashcardPrefs(
      defaultPool: defaultPool ?? this.defaultPool,
      defaultDirection: defaultDirection ?? this.defaultDirection,
      shuffle: shuffle ?? this.shuffle,
      srsEnabled: srsEnabled ?? this.srsEnabled,
      swipeRatings: swipeRatings ?? this.swipeRatings,
    );
  }
}

class FlashcardPrefsController extends Notifier<FlashcardPrefs> {
  static const _key = 'flashcard_prefs_v1';

  @override
  FlashcardPrefs build() {
    _hydrate();
    return const FlashcardPrefs();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    state = _decode(raw);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _encode(state));
  }

  Future<void> setPool(FlashcardPool pool) async {
    state = state.copyWith(defaultPool: pool);
    await _persist();
  }

  Future<void> setDirection(FlashcardDirection direction) async {
    state = state.copyWith(defaultDirection: direction);
    await _persist();
  }

  Future<void> setShuffle(bool value) async {
    state = state.copyWith(shuffle: value);
    await _persist();
  }

  Future<void> setSrsEnabled(bool value) async {
    state = state.copyWith(srsEnabled: value);
    await _persist();
  }

  Future<void> setSwipeRatings(bool value) async {
    state = state.copyWith(swipeRatings: value);
    await _persist();
  }

  String _encode(FlashcardPrefs p) =>
      '${p.defaultPool.key}\x1F${p.defaultDirection.key}\x1F${p.shuffle ? 1 : 0}\x1F${p.srsEnabled ? 1 : 0}\x1F${p.swipeRatings ? 1 : 0}';

  FlashcardPrefs _decode(String raw) {
    final parts = raw.split('\x1F');
    if (parts.length < 5) return const FlashcardPrefs();
    return FlashcardPrefs(
      defaultPool: FlashcardPool.values.firstWhere(
        (e) => e.key == parts[0],
        orElse: () => FlashcardPool.all,
      ),
      defaultDirection: FlashcardDirection.fromKey(parts[1]),
      shuffle: parts[2] == '1',
      srsEnabled: parts[3] == '1',
      swipeRatings: parts[4] == '1',
    );
  }
}

final flashcardPrefsProvider =
    NotifierProvider<FlashcardPrefsController, FlashcardPrefs>(
  FlashcardPrefsController.new,
);
