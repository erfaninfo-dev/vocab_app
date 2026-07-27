import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/srs/srs_model.dart';
import '../../core/srs/srs_provider.dart';
import '../../data/models/vocab_entry.dart';
import '../../features/words/important_words_controller.dart';
import '../../features/words/word_preferences_controller.dart';
import '../../domain/api_providers.dart';
import 'flashcard_deck_builder.dart';
import 'flashcard_session_storage.dart';
import 'models/flashcard_direction.dart';
import 'models/flashcard_session.dart';

@immutable
class FlashcardSessionState {
  const FlashcardSessionState({
    required this.deck,
    required this.deckKey,
    required this.index,
    required this.showBack,
    required this.ratedIds,
    required this.weakIds,
    required this.ratingCounts,
    required this.completed,
    required this.startedAt,
    required this.direction,
    required this.srsEnabled,
    required this.swipeRatings,
    required this.resumed,
  });

  final List<VocabEntry> deck;
  final String deckKey;
  final int index;
  final bool showBack;
  final Set<String> ratedIds;
  final Set<String> weakIds;
  final Map<SrsRating, int> ratingCounts;
  final bool completed;
  final DateTime startedAt;
  final FlashcardDirection direction;
  final bool srsEnabled;
  final bool swipeRatings;
  final bool resumed;

  int get total => deck.length;
  bool get hasCards => deck.isNotEmpty;
  bool get inRange => index >= 0 && index < deck.length;
  VocabEntry? get current => inRange ? deck[index] : null;
  bool get isLast => index >= total - 1;
  double get progress => total == 0 ? 0 : (index / total).clamp(0.0, 1.0);
  int get weakCount => weakIds.length;

  FlashcardSessionState copyWith({
    List<VocabEntry>? deck,
    String? deckKey,
    int? index,
    bool? showBack,
    Set<String>? ratedIds,
    Set<String>? weakIds,
    Map<SrsRating, int>? ratingCounts,
    bool? completed,
    DateTime? startedAt,
    FlashcardDirection? direction,
    bool? srsEnabled,
    bool? swipeRatings,
    bool? resumed,
  }) {
    return FlashcardSessionState(
      deck: deck ?? this.deck,
      deckKey: deckKey ?? this.deckKey,
      index: index ?? this.index,
      showBack: showBack ?? this.showBack,
      ratedIds: ratedIds ?? this.ratedIds,
      weakIds: weakIds ?? this.weakIds,
      ratingCounts: ratingCounts ?? this.ratingCounts,
      completed: completed ?? this.completed,
      startedAt: startedAt ?? this.startedAt,
      direction: direction ?? this.direction,
      srsEnabled: srsEnabled ?? this.srsEnabled,
      swipeRatings: swipeRatings ?? this.swipeRatings,
      resumed: resumed ?? this.resumed,
    );
  }
}

class FlashcardSessionController
    extends AutoDisposeFamilyAsyncNotifier<
        FlashcardSessionState,
        FlashcardSessionArgs
    > {
  @override
  Future<FlashcardSessionState> build(FlashcardSessionArgs args) async {
    final words = await ref.watch(
      apiWordsProvider(flashcardBookUnitSection(args)).future,
    );

    final deckKey = flashcardDeckKey(
      args.bookId,
      args.unit,
      args.section,
      args.pool,
      args.direction,
      args.shuffle,
    );
    final seed = args.shuffle ? deckKey.hashCode : 0;

    final deck = FlashcardDeckBuilder.build(
      source: words,
      pool: args.pool,
      isImportant: ref.read(importantWordsProvider).isMarked,
      isFavorite: ref.read(wordPreferencesProvider).isFavorite,
      shuffle: args.shuffle,
      seed: seed,
    );

    final saved = await FlashcardSessionStorage.loadSession(deckKey);
    int startIndex = 0;
    var rated = <String>{};
    final weak = <String>{};
    var startedAt = DateTime.now();
    var resumed = false;
    if (saved != null && flashcardWordListsEqual(saved.wordIds, deck)) {
      final savedIndex = saved.currentIndex;
      if (savedIndex > 0 && savedIndex < deck.length) {
        startIndex = savedIndex;
        rated = {...saved.ratedIds};
        startedAt = saved.startedAt;
        resumed = true;
      } else if (savedIndex >= deck.length) {
        unawaited(FlashcardSessionStorage.clearSession(deckKey));
      }
    }

    return FlashcardSessionState(
      deck: deck,
      deckKey: deckKey,
      index: startIndex,
      showBack: false,
      ratedIds: rated,
      weakIds: weak,
      ratingCounts: const {},
      completed: false,
      startedAt: startedAt,
      direction: args.direction,
      srsEnabled: args.srsEnabled,
      swipeRatings: args.swipeRatings,
      resumed: resumed,
    );
  }

  void flip() {
    final s = state.valueOrNull;
    if (s == null || !s.inRange) return;
    state = AsyncData(s.copyWith(showBack: !s.showBack));
  }

  void goTo(int index) {
    final s = state.valueOrNull;
    if (s == null || s.total == 0) return;
    final clamped = index.clamp(0, s.total - 1);
    state = AsyncData(s.copyWith(index: clamped, showBack: false));
    _persist();
  }

  void next() {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.index < s.total - 1) {
      state = AsyncData(s.copyWith(index: s.index + 1, showBack: false));
      _persist();
    } else {
      state = AsyncData(s.copyWith(completed: true));
      _persist();
    }
  }

  void prev() {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.index > 0) {
      state = AsyncData(s.copyWith(index: s.index - 1, showBack: false));
      _persist();
    }
  }

  /// Records SRS + session stats for the current card without advancing.
  Future<void> applyRate(SrsRating rating) async {
    final s = state.valueOrNull;
    if (s == null || s.current == null) return;
    final wordId = s.current!.id;

    if (s.srsEnabled) {
      await ref.read(srsProvider.notifier).rate(wordId, rating);
    }

    final rated = {...s.ratedIds, wordId};
    final weak = rating == SrsRating.again || rating == SrsRating.hard
        ? {...s.weakIds, wordId}
        : s.weakIds.difference({wordId});
    final counts = Map<SrsRating, int>.from(s.ratingCounts)
      ..update(rating, (v) => v + 1, ifAbsent: () => 1);

    state = AsyncData(
      s.copyWith(
        ratedIds: rated,
        weakIds: weak,
        ratingCounts: counts,
        showBack: false,
      ),
    );
    _persist();
  }

  Future<void> rate(SrsRating rating) async {
    await applyRate(rating);
    next();
  }

  void restart() {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(
      s.copyWith(
        index: 0,
        showBack: false,
        ratedIds: const {},
        weakIds: const {},
        ratingCounts: const {},
        completed: false,
        startedAt: DateTime.now(),
        resumed: false,
      ),
    );
    _persist();
  }

  /// Rebuild the deck from only the cards rated Again/Hard and start over.
  void reviewAgain() {
    final s = state.valueOrNull;
    if (s == null || s.weakIds.isEmpty) return;
    final weakSet = s.weakIds;
    final subDeck = s.deck.where((e) => weakSet.contains(e.id)).toList();
    if (subDeck.isEmpty) return;
    state = AsyncData(
      FlashcardSessionState(
        deck: subDeck,
        deckKey: s.deckKey,
        index: 0,
        showBack: false,
        ratedIds: const {},
        weakIds: const {},
        ratingCounts: const {},
        completed: false,
        startedAt: DateTime.now(),
        direction: s.direction,
        srsEnabled: s.srsEnabled,
        swipeRatings: s.swipeRatings,
        resumed: false,
      ),
    );
    _persist();
  }

  /// Called when the user dismisses the summary — clears the saved session.
  Future<void> finishAndClear() async {
    final s = state.valueOrNull;
    if (s == null) return;
    await FlashcardSessionStorage.clearSession(s.deckKey);
  }

  void _persist() {
    final s = state.valueOrNull;
    if (s == null || s.deckKey.isEmpty || s.deck.isEmpty) return;
    final persistIndex = s.completed ? s.total : s.index;
    unawaited(
      FlashcardSessionStorage.saveSession(
        FlashcardSessionModel(
          deckKey: s.deckKey,
          wordIds: s.deck.map((e) => e.id).toList(),
          currentIndex: persistIndex,
          ratedIds: s.ratedIds,
          startedAt: s.startedAt,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }
}

final flashcardSessionProvider =
    AutoDisposeAsyncNotifierProvider.family<
        FlashcardSessionController,
        FlashcardSessionState,
        FlashcardSessionArgs
    >(FlashcardSessionController.new);
