import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/api_providers.dart';
import '../data/word_builder_progress_repository.dart';
import '../data/word_builder_vocab.dart';
import '../word_builder_campaign_session_key.dart';
import '../word_builder_campaign_constants.dart';
import 'word_builder_campaign_providers.dart';
import '../domain/word_builder_game_logic.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_constants.dart';

final wordBuilderProgressRepoProvider =
    Provider<WordBuilderProgressRepository>(
  (ref) => WordBuilderProgressRepository(),
);

final wordBuilderGameProvider =
    AsyncNotifierProvider.autoDispose.family<WordBuilderGameNotifier,
        WordBuilderViewState, int>(WordBuilderGameNotifier.new);

@immutable
class WordBuilderViewState {
  static const Object _unsetLastSolved = Object();

  const WordBuilderViewState({
    required this.persisted,
    required this.sessionLevels,
    required this.levelIndex,
    required this.circleLetters,
    required this.path,
    required this.solvedLower,
    required this.revealedPositions,
    required this.feedbackMessage,
    this.lastSolvedWord,
    this.pathWrongHighlight = false,
  });

  final WordBuilderPersistedProgress persisted;
  final List<WordBuilderLevel> sessionLevels;
  final int levelIndex;
  final List<LetterInstance> circleLetters;
  final List<LetterInstance> path;
  final Set<String> solvedLower;
  final Map<String, Set<int>> revealedPositions;
  final String? feedbackMessage;
  final WordBuilderTargetWord? lastSolvedWord;
  final bool pathWrongHighlight;

  WordBuilderLevel get level => sessionLevels[levelIndex];

  int get totalLevels => sessionLevels.length;

  int get solvedCount => solvedTargetCount(level, solvedLower);

  double get levelProgress =>
      level.targetCount == 0 ? 1.0 : solvedCount / level.targetCount;

  bool get levelComplete => isLevelComplete(level, solvedLower);

  WordBuilderViewState copyWith({
    WordBuilderPersistedProgress? persisted,
    List<WordBuilderLevel>? sessionLevels,
    int? levelIndex,
    List<LetterInstance>? circleLetters,
    List<LetterInstance>? path,
    Set<String>? solvedLower,
    Map<String, Set<int>>? revealedPositions,
    String? feedbackMessage,
    Object? lastSolvedWord = _unsetLastSolved,
    bool clearFeedback = false,
    bool? pathWrongHighlight,
  }) {
    return WordBuilderViewState(
      persisted: persisted ?? this.persisted,
      sessionLevels: sessionLevels ?? this.sessionLevels,
      levelIndex: levelIndex ?? this.levelIndex,
      circleLetters: circleLetters ?? this.circleLetters,
      path: path ?? this.path,
      solvedLower: solvedLower ?? this.solvedLower,
      revealedPositions: revealedPositions ?? this.revealedPositions,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      lastSolvedWord: identical(lastSolvedWord, _unsetLastSolved)
          ? this.lastSolvedWord
          : lastSolvedWord as WordBuilderTargetWord?,
      pathWrongHighlight: pathWrongHighlight ?? this.pathWrongHighlight,
    );
  }

  static WordBuilderViewState createInitial({
    required WordBuilderPersistedProgress persisted,
    required List<WordBuilderLevel> sessionLevels,
    required int levelIndex,
    required Random random,
  }) {
    final level = sessionLevels[levelIndex];
    final prev = persisted.perLevel[level.levelId] ??
        const WordBuilderLevelProgress(
          completed: false,
          attempts: 0,
          correctSubmissions: 0,
          solvedWordsLower: {},
        );
    final solved = sanitizeSolvedForLevel(
      sessionLevels[levelIndex],
      Set<String>.from(prev.solvedWordsLower),
    );
    final activeChars = activeTargetLetterChars(sessionLevels[levelIndex]);
    final circle = activeChars.isEmpty
        ? const <LetterInstance>[]
        : shuffleInstances(buildLetterInstances(activeChars), random);
    return WordBuilderViewState(
      persisted: persisted,
      sessionLevels: sessionLevels,
      levelIndex: levelIndex,
      circleLetters: circle,
      path: const [],
      solvedLower: solved,
      revealedPositions: {},
      feedbackMessage: null,
      lastSolvedWord: null,
      pathWrongHighlight: false,
    );
  }
}

class WordBuilderGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<WordBuilderViewState, int> {
  final Random _random = Random();

  WordBuilderProgressRepository get _repo =>
      ref.read(wordBuilderProgressRepoProvider);

  @override
  Future<WordBuilderViewState> build(int bookKey) async {
    final persisted = await _repo.load();
    final campaign = decodeWordBuilderCampaignSessionKey(bookKey);
    if (campaign != null) {
      final plan = await ref.read(wordBuilderCampaignPlanProvider.future);
      final stageLists = plan.stagesFor(campaign.difficulty);
      final idx = campaign.stage1Based - 1;
      if (idx < 0 || idx >= stageLists.length) {
        throw StateError('NO_WORDS');
      }
      final entries = stageLists[idx];
      if (entries.length < kWordBuilderCampaignWordsPerStage) {
        throw StateError('NO_WORDS');
      }
      final level = buildCampaignStageLevel(
        entries: entries,
        difficulty: campaign.difficulty,
        categoryLabel:
            'campaign_${campaign.difficulty.name}_${campaign.stage1Based}',
        stage1Based: campaign.stage1Based,
        random: _random,
      );
      if (level.targetWords.isEmpty) {
        throw StateError('NO_WORDS');
      }
      return WordBuilderViewState.createInitial(
        persisted: persisted,
        sessionLevels: [level],
        levelIndex: 0,
        random: _random,
      );
    }

    final entries = bookKey == kWordBuilderAllBooksKey
        ? await ref.read(apiAllWordsCatalogProvider.future)
        : await ref.read(apiAllWordsForBookProvider(bookKey).future);

    String categoryLabel = '__LOCAL_ALL__';
    if (bookKey != kWordBuilderAllBooksKey) {
      final books = await ref.read(apiBooksProvider.future);
      String? title;
      for (final b in books) {
        if (b.id == bookKey) {
          title = b.title;
          break;
        }
      }
      categoryLabel = title ?? 'Book $bookKey';
    }

    final levels = buildWordBuilderLevelsFromEntries(
      entries,
      _random,
      categoryLabel: categoryLabel,
    );
    if (levels.isEmpty) {
      throw StateError('NO_WORDS');
    }

    return WordBuilderViewState.createInitial(
      persisted: persisted,
      sessionLevels: levels,
      levelIndex: 0,
      random: _random,
    );
  }

  Future<void> _commit(WordBuilderViewState next) async {
    state = AsyncValue.data(next);
    await _repo.save(next.persisted);
  }

  Future<void> _deferEvaluationForFullPathPaint(
    WordBuilderViewState afterPathCommit,
    int pathLength,
  ) async {
    final active =
        firstUnsolvedTarget(afterPathCommit.level, afterPathCommit.solvedLower);
    if (active != null && pathLength == active.word.length) {
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  void clearLastSolvedWord() {
    state.whenData((s) {
      if (s.lastSolvedWord != null) {
        state = AsyncValue.data(s.copyWith(lastSolvedWord: null));
      }
    });
  }

  Future<void> tapCircleLetter(LetterInstance letter) async {
    final s = state.valueOrNull;
    if (s == null || s.pathWrongHighlight) return;
    if (!s.circleLetters.any((e) => e.id == letter.id)) return;

    if (s.path.isNotEmpty && s.path.last.id == letter.id) {
      final newPath = List<LetterInstance>.of(s.path)..removeLast();
      await _commit(
        s.copyWith(
          path: newPath,
          clearFeedback: true,
          pathWrongHighlight: false,
        ),
      );
      return;
    }

    if (s.path.any((e) => e.id == letter.id)) {
      return;
    }

    final newPath = List<LetterInstance>.of(s.path)..add(letter);
    await _commit(s.copyWith(path: newPath, clearFeedback: true));
    final afterCommit = state.requireValue;
    await _deferEvaluationForFullPathPaint(afterCommit, newPath.length);
    await _evaluatePathAfterChange(state.requireValue);
  }

  Future<void> appendLetterFromDrag(LetterInstance letter) async {
    final s = state.valueOrNull;
    if (s == null || s.pathWrongHighlight) return;
    if (s.path.any((e) => e.id == letter.id)) return;
    final newPath = List<LetterInstance>.of(s.path)..add(letter);
    await _commit(s.copyWith(path: newPath, clearFeedback: true));
    final afterCommit = state.requireValue;
    await _deferEvaluationForFullPathPaint(afterCommit, newPath.length);
    await _evaluatePathAfterChange(state.requireValue);
  }

  Future<void> shuffleCircle() async {
    final s = state.valueOrNull;
    if (s == null) return;
    final shuffled = shuffleInstances(
      List<LetterInstance>.of(s.circleLetters),
      _random,
    );
    await _commit(
      s.copyWith(
        circleLetters: shuffled,
        path: const [],
        clearFeedback: true,
        pathWrongHighlight: false,
      ),
    );
  }

  Future<void> clearPathOnly() async {
    final s = state.valueOrNull;
    if (s == null || s.path.isEmpty) return;
    await _commit(
      s.copyWith(
        path: const [],
        clearFeedback: true,
        pathWrongHighlight: false,
      ),
    );
  }

  Future<void> clearWrongSelectionAfterFade() async {
    final s = state.valueOrNull;
    if (s == null || !s.pathWrongHighlight) return;
    await _commit(
      s.copyWith(
        path: const [],
        pathWrongHighlight: false,
        clearFeedback: true,
      ),
    );
  }

  Future<void> _evaluatePathAfterChange(WordBuilderViewState s) async {
    if (s.path.isEmpty) return;

    final active = firstUnsolvedTarget(s.level, s.solvedLower);
    if (active == null) return;

    final plen = s.path.length;
    if (plen > active.word.length) {
      await _commit(
        s.copyWith(pathWrongHighlight: true, clearFeedback: true),
      );
      return;
    }
    if (plen < active.word.length) return;

    final builtLower = normalizeWord(s.path.map((e) => e.char).join());
    if (normalizeWord(active.word) == builtLower) {
      await _applyCorrectWord(s, normalizeWord(active.word), active);
    } else {
      await _commit(
        s.copyWith(pathWrongHighlight: true, clearFeedback: true),
      );
    }
  }

  Future<void> _applyCorrectWord(
    WordBuilderViewState s,
    String norm,
    WordBuilderTargetWord matched,
  ) async {
    var persisted = s.persisted;
    final levelId = s.level.levelId;
    var lp = persisted.perLevel[levelId] ??
        const WordBuilderLevelProgress(
          completed: false,
          attempts: 0,
          correctSubmissions: 0,
          solvedWordsLower: {},
        );

    lp = lp.copyWith(attempts: lp.attempts + 1);
    persisted = persisted.copyWith(
      globalAttempts: persisted.globalAttempts + 1,
      perLevel: {...persisted.perLevel, levelId: lp},
    );

    final newSolved = Set<String>.from(
      sanitizeSolvedForLevel(s.level, s.solvedLower),
    )..add(norm);
    lp = lp.copyWith(
      correctSubmissions: lp.correctSubmissions + 1,
      solvedWordsLower: newSolved,
    );
    var totalXp = persisted.totalXp + s.level.xpPerCorrectWord();
    var globalCorrect = persisted.globalCorrect + 1;
    var completed = lp.completed;
    if (isLevelComplete(s.level, newSolved)) {
      completed = true;
      totalXp += s.level.xpLevelCompleteBonus();
    }
    lp = lp.copyWith(completed: completed, solvedWordsLower: newSolved);
    persisted = persisted.copyWith(
      totalXp: totalXp,
      globalCorrect: globalCorrect,
      perLevel: {...persisted.perLevel, levelId: lp},
    );

    final newCircle = isLevelComplete(s.level, newSolved)
        ? const <LetterInstance>[]
        : shuffleInstances(
            buildLetterInstances(activeTargetLetterChars(s.level)),
            _random,
          );

    await _commit(
      WordBuilderViewState(
        persisted: persisted,
        sessionLevels: s.sessionLevels,
        levelIndex: s.levelIndex,
        circleLetters: newCircle,
        path: const [],
        solvedLower: newSolved,
        revealedPositions: s.revealedPositions,
        feedbackMessage: '__correct',
        lastSolvedWord: matched,
        pathWrongHighlight: false,
      ),
    );
  }

  Future<void> goToNextLevel() async {
    final s = state.valueOrNull;
    if (s == null || !s.levelComplete) return;
    final nextIndex = s.levelIndex + 1;
    if (nextIndex >= s.sessionLevels.length) {
      await _commit(
        s.copyWith(
          feedbackMessage: '__all_levels_done',
        ),
      );
      return;
    }
    final next = WordBuilderViewState.createInitial(
      persisted: s.persisted,
      sessionLevels: s.sessionLevels,
      levelIndex: nextIndex,
      random: _random,
    );
    await _commit(next);
  }

  Future<void> hintRevealLetter() async {
    final s = state.valueOrNull;
    if (s == null || s.pathWrongHighlight) return;
    final target = firstUnsolvedTarget(s.level, s.solvedLower);
    if (target == null) return;
    final lw = normalizeWord(target.word);
    final revealed = Map<String, Set<int>>.from(s.revealedPositions);
    final setFor = Set<int>.from(revealed[lw] ?? {});
    final idx = pickHiddenIndexForReveal(lw, setFor, _random);
    if (idx == null) return;
    setFor.add(idx);
    revealed[lw] = setFor;
    await _commit(
      s.copyWith(
        revealedPositions: revealed,
        feedbackMessage: '__hint_letter',
        clearFeedback: false,
      ),
    );
  }

  Future<void> hintRemoveWrongLetter() async {
    final s = state.valueOrNull;
    if (s == null || s.path.isEmpty || s.pathWrongHighlight) return;
    final active = firstUnsolvedTarget(s.level, s.solvedLower);
    if (active == null) return;
    final allowed = multisetForWords([normalizeWord(active.word)]);
    final before = List<LetterInstance>.of(s.path);
    final newPath = List<LetterInstance>.of(s.path);
    final ok = removeOneExcessLetterFromRack(newPath, allowed);
    if (!ok) {
      await _commit(
        s.copyWith(
          feedbackMessage: '__hint_remove_none',
        ),
      );
      return;
    }
    final remainingIds = newPath.map((e) => e.id).toSet();
    final removed = before.where((e) => !remainingIds.contains(e.id)).toList();
    if (removed.length != 1) return;
    await _commit(
      s.copyWith(
        path: newPath,
        feedbackMessage: '__hint_removed',
      ),
    );
  }

  Future<void> hintMeaning({required bool preferKur}) async {
    final s = state.valueOrNull;
    if (s == null || s.pathWrongHighlight) return;
    final target = firstUnsolvedTarget(s.level, s.solvedLower);
    if (target == null) return;
    final m = target.meaningForLang(preferKur: preferKur);
    await _commit(
      s.copyWith(
        feedbackMessage: '$kWordBuilderMeaningPrefix$m',
      ),
    );
  }
}
