import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/word_builder_sound_service.dart';
import '../../../data/models/vocab_entry.dart';
import '../../../domain/api_providers.dart';
import '../data/word_builder_progress_repository.dart';
import '../data/word_builder_vocab.dart';
import '../word_builder_campaign_session_key.dart';
import '../word_builder_campaign_constants.dart';
import 'word_builder_campaign_providers.dart';
import '../domain/tray_water_constants.dart';
import '../domain/word_builder_game_logic.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_coin_constants.dart';
import '../word_builder_constants.dart';
import 'word_builder_coins_provider.dart';
import 'word_builder_session_audio.dart';
import 'word_builder_tray_water_audio.dart';

final wordBuilderProgressRepoProvider = Provider<WordBuilderProgressRepository>(
  (ref) => WordBuilderProgressRepository(),
);

final wordBuilderGameProvider = AsyncNotifierProvider.autoDispose
    .family<WordBuilderGameNotifier, WordBuilderViewState, int>(
      WordBuilderGameNotifier.new,
    );

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
    required this.hintTargetCycleIndex,
    required this.feedbackMessage,
    this.lastSolvedWord,
    this.pathWrongHighlight = false,
    this.trayWaterLevel = 0,
    this.isInletValveOpen = false,
    this.isOutletValveOpen = false,
    this.faceMood = TrayFaceMood.neutral,
    this.wrongAnswerCount = 0,
    this.isTrayGameOver = false,
  });

  final WordBuilderPersistedProgress persisted;
  final List<WordBuilderLevel> sessionLevels;
  final int levelIndex;
  final List<LetterInstance> circleLetters;
  final List<LetterInstance> path;
  final Set<String> solvedLower;
  final Map<String, Set<int>> revealedPositions;
  final int hintTargetCycleIndex;
  final String? feedbackMessage;
  final WordBuilderTargetWord? lastSolvedWord;
  final bool pathWrongHighlight;
  final double trayWaterLevel;
  final bool isInletValveOpen;
  final bool isOutletValveOpen;
  final TrayFaceMood faceMood;
  final int wrongAnswerCount;
  final bool isTrayGameOver;

  bool get trayInputBlocked => pathWrongHighlight || isTrayGameOver;

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
    int? hintTargetCycleIndex,
    String? feedbackMessage,
    Object? lastSolvedWord = _unsetLastSolved,
    bool clearFeedback = false,
    bool? pathWrongHighlight,
    double? trayWaterLevel,
    bool? isInletValveOpen,
    bool? isOutletValveOpen,
    TrayFaceMood? faceMood,
    int? wrongAnswerCount,
    bool? isTrayGameOver,
  }) {
    return WordBuilderViewState(
      persisted: persisted ?? this.persisted,
      sessionLevels: sessionLevels ?? this.sessionLevels,
      levelIndex: levelIndex ?? this.levelIndex,
      circleLetters: circleLetters ?? this.circleLetters,
      path: path ?? this.path,
      solvedLower: solvedLower ?? this.solvedLower,
      revealedPositions: revealedPositions ?? this.revealedPositions,
      hintTargetCycleIndex: hintTargetCycleIndex ?? this.hintTargetCycleIndex,
      feedbackMessage: clearFeedback
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      lastSolvedWord: identical(lastSolvedWord, _unsetLastSolved)
          ? this.lastSolvedWord
          : lastSolvedWord as WordBuilderTargetWord?,
      pathWrongHighlight: pathWrongHighlight ?? this.pathWrongHighlight,
      trayWaterLevel: trayWaterLevel ?? this.trayWaterLevel,
      isInletValveOpen: isInletValveOpen ?? this.isInletValveOpen,
      isOutletValveOpen: isOutletValveOpen ?? this.isOutletValveOpen,
      faceMood: faceMood ?? this.faceMood,
      wrongAnswerCount: wrongAnswerCount ?? this.wrongAnswerCount,
      isTrayGameOver: isTrayGameOver ?? this.isTrayGameOver,
    );
  }

  static WordBuilderViewState createInitial({
    required WordBuilderPersistedProgress persisted,
    required List<WordBuilderLevel> sessionLevels,
    required int levelIndex,
    required Random random,
  }) {
    final level = sessionLevels[levelIndex];
    final prev =
        persisted.perLevel[level.levelId] ??
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
      hintTargetCycleIndex: 0,
      feedbackMessage: null,
      lastSolvedWord: null,
      pathWrongHighlight: false,
    );
  }
}

class WordBuilderGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<WordBuilderViewState, int> {
  final Random _random = Random();
  Timer? _passiveWaterTimer;
  Map<String, WordBuilderTargetWord> _globalTargetsByLemma = const {};

  WordBuilderProgressRepository get _repo =>
      ref.read(wordBuilderProgressRepoProvider);

  Map<String, WordBuilderTargetWord> _targetsByLemma(
    Iterable<VocabEntry> entries,
  ) {
    final out = <String, WordBuilderTargetWord>{};
    for (final e in entries) {
      final lemma = wordBuilderGameLemma(e);
      if (lemma == null || lemma.isEmpty || out.containsKey(lemma)) continue;
      out[lemma] = targetFromVocab(e, lemma);
    }
    return out;
  }

  bool _wasSolvedAnywhere(
    String norm,
    WordBuilderPersistedProgress persisted,
    Set<String> currentSolved,
  ) {
    if (currentSolved.contains(norm)) return true;
    for (final progress in persisted.perLevel.values) {
      if (progress.solvedWordsLower.contains(norm)) return true;
    }
    return false;
  }

  bool _isCurrentLevelTarget(WordBuilderLevel level, String norm) {
    for (final target in level.targetWords) {
      if (normalizeWord(target.word) == norm) return true;
    }
    return false;
  }

  WordBuilderTargetWord? _catalogMatchForBuilt(
    WordBuilderViewState s,
    String builtLower,
  ) {
    final norm = normalizeWord(builtLower);
    if (norm.length < 2) return null;
    if (_isCurrentLevelTarget(s.level, norm)) return null;
    if (_wasSolvedAnywhere(norm, s.persisted, s.solvedLower)) return null;
    final target = _globalTargetsByLemma[norm];
    if (target == null) return null;
    if (!canSpellFromPool(norm, letterCounts(s.level.letters))) return null;
    return target;
  }

  bool _isKnownDuplicateBuilt(WordBuilderViewState s, String builtLower) {
    final norm = normalizeWord(builtLower);
    if (norm.length < 2) return false;
    if (!_wasSolvedAnywhere(norm, s.persisted, s.solvedLower)) return false;
    return _isCurrentLevelTarget(s.level, norm) ||
        _globalTargetsByLemma.containsKey(norm);
  }

  bool _catalogCanExtendBuilt(WordBuilderViewState s, String builtLower) {
    final prefix = normalizeWord(builtLower);
    if (prefix.isEmpty) return false;
    final pool = letterCounts(s.level.letters);
    for (final entry in _globalTargetsByLemma.entries) {
      final word = entry.key;
      if (word.length <= prefix.length || !word.startsWith(prefix)) continue;
      if (_isCurrentLevelTarget(s.level, word)) continue;
      if (_wasSolvedAnywhere(word, s.persisted, s.solvedLower)) continue;
      if (canSpellFromPool(word, pool)) return true;
    }
    return false;
  }

  WordBuilderLevel _levelWithTargets(
    WordBuilderLevel level,
    List<WordBuilderTargetWord> targets, {
    required bool preserveLetters,
  }) {
    final letters = preserveLetters
        ? List<String>.of(level.letters)
        : expandPoolLetters(
            poolMaxPerLetterAcrossWords(
              targets.map((t) => normalizeWord(t.word)),
            ),
          );
    return WordBuilderLevel(
      levelId: level.levelId,
      difficulty: level.difficulty,
      category: level.category,
      letters: letters,
      targetWords: List<WordBuilderTargetWord>.unmodifiable(targets),
    );
  }

  int _firstReplaceableTargetIndex(
    WordBuilderLevel level,
    Set<String> solvedLower, {
    int? preferredLength,
  }) {
    var fallback = -1;
    for (var i = 0; i < level.targetWords.length; i++) {
      final target = level.targetWords[i];
      if (solvedLower.contains(normalizeWord(target.word))) continue;
      fallback = fallback == -1 ? i : fallback;
      if (preferredLength != null &&
          normalizeWord(target.word).length == preferredLength) {
        return i;
      }
    }
    return fallback;
  }

  List<WordBuilderLevel> _carryDisplacedTargetForward({
    required List<WordBuilderLevel> levels,
    required int startIndex,
    required WordBuilderTargetWord displaced,
    required String acceptedNorm,
    required WordBuilderPersistedProgress persisted,
  }) {
    var pending = displaced;
    final nextLevels = List<WordBuilderLevel>.of(levels);

    for (
      var levelIndex = startIndex;
      levelIndex < nextLevels.length;
      levelIndex++
    ) {
      final level = nextLevels[levelIndex];
      final progress = persisted.perLevel[level.levelId];
      if (progress?.completed == true) continue;
      final solved = progress?.solvedWordsLower ?? const <String>{};
      final targets = List<WordBuilderTargetWord>.of(level.targetWords);

      var replaceIndex = -1;
      for (var i = 0; i < targets.length; i++) {
        final norm = normalizeWord(targets[i].word);
        if (solved.contains(norm)) continue;
        if (norm == acceptedNorm) {
          replaceIndex = i;
          break;
        }
      }
      if (replaceIndex == -1) {
        replaceIndex = _firstReplaceableTargetIndex(
          level,
          solved,
          preferredLength: normalizeWord(pending.word).length,
        );
      }
      if (replaceIndex == -1) continue;

      final outgoing = targets[replaceIndex];
      targets[replaceIndex] = pending;
      nextLevels[levelIndex] = _levelWithTargets(
        level,
        targets,
        preserveLetters: false,
      );

      if (normalizeWord(outgoing.word) == acceptedNorm) {
        return nextLevels;
      }
      pending = outgoing;
    }

    return nextLevels;
  }

  WordBuilderViewState? _replaceUnsolvedTargetWithCatalogWord(
    WordBuilderViewState s,
    WordBuilderTargetWord accepted,
  ) {
    final acceptedNorm = normalizeWord(accepted.word);
    final currentReplaceIndex = _firstReplaceableTargetIndex(
      s.level,
      s.solvedLower,
      preferredLength: acceptedNorm.length,
    );
    if (currentReplaceIndex == -1) return null;

    final currentTargets = List<WordBuilderTargetWord>.of(s.level.targetWords);
    final displaced = currentTargets[currentReplaceIndex];
    currentTargets[currentReplaceIndex] = accepted;

    var nextLevels = List<WordBuilderLevel>.of(s.sessionLevels);
    nextLevels[s.levelIndex] = _levelWithTargets(
      s.level,
      currentTargets,
      preserveLetters: true,
    );
    nextLevels = _carryDisplacedTargetForward(
      levels: nextLevels,
      startIndex: s.levelIndex + 1,
      displaced: displaced,
      acceptedNorm: acceptedNorm,
      persisted: s.persisted,
    );

    final revealed = Map<String, Set<int>>.from(s.revealedPositions)
      ..remove(normalizeWord(displaced.word));

    return s.copyWith(sessionLevels: nextLevels, revealedPositions: revealed);
  }

  Future<void> _commitDuplicateSelection(WordBuilderViewState s) async {
    await _commit(
      s.copyWith(
        path: const [],
        pathWrongHighlight: false,
        feedbackMessage: '__already_found',
      ),
    );
  }

  TrayFaceMood _faceMoodForWater(double level, {required bool overflow}) {
    if (overflow || level >= 1.0) return TrayFaceMood.dead;
    if (level >= 0.8) return TrayFaceMood.panic;
    if (level >= TrayWaterConstants.waterPerWrong) return TrayFaceMood.stressed;
    return TrayFaceMood.neutral;
  }

  void _startPassiveWaterTimer() {
    _passiveWaterTimer?.cancel();
    _passiveWaterTimer = Timer.periodic(
      TrayWaterConstants.passiveWaterTickInterval,
      (_) => unawaited(_tickPassiveWater()),
    );
  }

  Future<void> _tickPassiveWater() async {
    final s = state.valueOrNull;
    if (s == null ||
        s.isTrayGameOver ||
        s.levelComplete ||
        s.pathWrongHighlight ||
        s.isInletValveOpen ||
        s.isOutletValveOpen) {
      return;
    }

    final nextLevel =
        (s.trayWaterLevel + TrayWaterConstants.passiveWaterIncrement).clamp(
          0.0,
          1.0,
        );
    if ((nextLevel - s.trayWaterLevel) < 0.0005) return;

    final overflow = nextLevel >= 1.0;
    await _commit(
      s.copyWith(
        trayWaterLevel: nextLevel,
        isOutletValveOpen: false,
        faceMood: _faceMoodForWater(nextLevel, overflow: overflow),
        isTrayGameOver: overflow,
      ),
    );
    if (overflow) _stopTrayWaterAudio();
  }

  void _playSound(WordBuilderSound sound) {
    final enabled = ref.read(wordBuilderGameSfxEnabledProvider);
    unawaited(
      ref.read(wordBuilderSoundServiceProvider).play(sound, enabled: enabled),
    );
  }

  void _stopTrayWaterAudio() {
    unawaited(ref.read(wordBuilderTrayWaterAudioProvider(arg)).stopAll());
  }

  bool get _waterSfxEnabled => ref.read(wordBuilderGameWaterSfxEnabledProvider);

  void _onTrayWrongWaterAudio(int wrongCount, {required bool overflow}) {
    final enabled = _waterSfxEnabled;
    final audio = ref.read(wordBuilderTrayWaterAudioProvider(arg));
    if (overflow) {
      unawaited(audio.playPillOnly(enabled: enabled));
      unawaited(audio.stopLoops());
      return;
    }
    unawaited(audio.onWrongAnswer(wrongCount, enabled: enabled));
  }

  void _syncTrayWaterStageAudio(int wrongCount) {
    final enabled = _waterSfxEnabled;
    unawaited(
      ref
          .read(wordBuilderTrayWaterAudioProvider(arg))
          .syncWaterStage(wrongCount, enabled: enabled),
    );
  }

  Future<void> _closeInletValve() async {
    final s = state.valueOrNull;
    if (s == null || !s.isInletValveOpen) return;
    await _commit(s.copyWith(isInletValveOpen: false));
  }

  Future<void> _closeOutletValveOnly() async {
    final s = state.valueOrNull;
    if (s == null || !s.isOutletValveOpen) return;
    await _commit(s.copyWith(isOutletValveOpen: false));
  }

  Future<void> _setFaceMoodNeutral() async {
    final s = state.valueOrNull;
    if (s == null || s.isTrayGameOver) return;
    if (s.faceMood == TrayFaceMood.neutral) return;
    await _commit(s.copyWith(faceMood: TrayFaceMood.neutral));
  }

  Future<void> _setFaceMoodAfterHappy() async {
    final s = state.valueOrNull;
    if (s == null || s.isTrayGameOver) return;
    if (s.trayWaterLevel >= TrayWaterConstants.waterPerWrong) {
      final mood = _faceMoodForWater(s.trayWaterLevel, overflow: false);
      if (s.faceMood == mood) return;
      await _commit(s.copyWith(faceMood: mood));
      return;
    }
    await _setFaceMoodNeutral();
  }

  Future<void> _commitWrongWithTray(WordBuilderViewState s) async {
    if (s.isTrayGameOver) return;
    final nextLevel = (s.trayWaterLevel + TrayWaterConstants.waterPerWrong)
        .clamp(0.0, 1.0);
    final nextCount = s.wrongAnswerCount + 1;
    final overflow = nextLevel >= 1.0;
    await _commit(
      s.copyWith(
        pathWrongHighlight: true,
        clearFeedback: true,
        trayWaterLevel: nextLevel,
        wrongAnswerCount: nextCount,
        isInletValveOpen: true,
        isOutletValveOpen: false,
        faceMood: _faceMoodForWater(nextLevel, overflow: overflow),
        isTrayGameOver: overflow,
      ),
    );
    _playSound(WordBuilderSound.wrong);
    _onTrayWrongWaterAudio(nextCount, overflow: overflow);
    unawaited(
      Future<void>.delayed(TrayWaterConstants.inletOpenDuration, () {
        if (state.valueOrNull != null) unawaited(_closeInletValve());
      }),
    );
  }

  Future<void> _commitCorrectWithTrayDrain(WordBuilderViewState next) async {
    final s = state.valueOrNull;
    final prevLevel = s?.trayWaterLevel ?? 0.0;
    final prevWrong = s?.wrongAnswerCount ?? 0;
    final drainedLevel = (prevLevel - TrayWaterConstants.waterPerWrong).clamp(
      0.0,
      1.0,
    );
    final nextWrong = max(0, prevWrong - 1);

    await _commit(
      next.copyWith(
        trayWaterLevel: drainedLevel,
        wrongAnswerCount: nextWrong,
        isInletValveOpen: false,
        isOutletValveOpen: true,
        faceMood: TrayFaceMood.happy,
        pathWrongHighlight: false,
      ),
    );
    _syncTrayWaterStageAudio(nextWrong);
    unawaited(
      Future<void>.delayed(TrayWaterConstants.outletOpenDuration, () {
        if (state.valueOrNull != null) unawaited(_closeOutletValveOnly());
      }),
    );
    unawaited(
      Future<void>.delayed(TrayWaterConstants.happyMoodDuration, () {
        if (state.valueOrNull != null) unawaited(_setFaceMoodAfterHappy());
      }),
    );
  }

  Future<void> resetTrayAfterGameOver() async {
    final s = state.valueOrNull;
    if (s == null || !s.isTrayGameOver) return;
    final fresh = WordBuilderViewState.createInitial(
      persisted: s.persisted,
      sessionLevels: s.sessionLevels,
      levelIndex: s.levelIndex,
      random: _random,
    );
    await _commit(fresh);
    _stopTrayWaterAudio();
  }

  @override
  Future<WordBuilderViewState> build(int bookKey) async {
    ref.onDispose(() => _passiveWaterTimer?.cancel());

    final persisted = await _repo.load();
    final globalCatalog = await ref.read(apiAllWordsCatalogProvider.future);
    _globalTargetsByLemma = _targetsByLemma(globalCatalog);
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
      final initial = WordBuilderViewState.createInitial(
        persisted: persisted,
        sessionLevels: [level],
        levelIndex: 0,
        random: _random,
      );
      _startPassiveWaterTimer();
      return initial;
    }

    final entries = bookKey == kWordBuilderAllBooksKey
        ? globalCatalog
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

    final initial = WordBuilderViewState.createInitial(
      persisted: persisted,
      sessionLevels: levels,
      levelIndex: 0,
      random: _random,
    );
    _startPassiveWaterTimer();
    return initial;
  }

  Future<void> _commit(WordBuilderViewState next) async {
    state = AsyncValue.data(next);
    await _repo.save(next.persisted);
  }

  Future<void> _deferEvaluationForFullPathPaint(
    WordBuilderViewState afterPathCommit,
    int pathLength,
  ) async {
    final builtLower = normalizeWord(
      afterPathCommit.path.map((e) => e.char).join(),
    );
    if (anyUnsolvedTargetHasLength(
          afterPathCommit.level,
          afterPathCommit.solvedLower,
          pathLength,
        ) ||
        _catalogMatchForBuilt(afterPathCommit, builtLower) != null) {
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
    if (s == null || s.trayInputBlocked) return;
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
    if (s == null || s.trayInputBlocked) return;
    if (s.path.any((e) => e.id == letter.id)) return;
    final newPath = List<LetterInstance>.of(s.path)..add(letter);
    await _commit(s.copyWith(path: newPath, clearFeedback: true));
  }

  Future<void> evaluatePathOnDragRelease() async {
    final s = state.valueOrNull;
    if (s == null || s.trayInputBlocked || s.path.isEmpty) return;
    if (s.path.length == 1) {
      await clearPathOnly();
      return;
    }

    await _deferEvaluationForFullPathPaint(s, s.path.length);
    final current = state.requireValue;
    if (unsolvedTargets(current.level, current.solvedLower).isEmpty) {
      await clearPathOnly();
      return;
    }

    final builtLower = normalizeWord(current.path.map((e) => e.char).join());
    final matched = findUnsolvedTargetMatchingBuilt(
      current.level,
      current.solvedLower,
      builtLower,
    );
    if (matched != null) {
      await _applyCorrectWord(current, normalizeWord(matched.word), matched);
      return;
    }

    if (_isKnownDuplicateBuilt(current, builtLower)) {
      await _commitDuplicateSelection(current);
      return;
    }

    final catalogMatch = _catalogMatchForBuilt(current, builtLower);
    if (catalogMatch != null) {
      final replaced = _replaceUnsolvedTargetWithCatalogWord(
        current,
        catalogMatch,
      );
      if (replaced != null) {
        await _applyCorrectWord(replaced, builtLower, catalogMatch);
        return;
      }
    }

    final plen = current.path.length;
    final maxLen = maxUnsolvedTargetLength(current.level, current.solvedLower);

    if (plen > maxLen && !_catalogCanExtendBuilt(current, builtLower)) {
      await _commitWrongWithTray(current);
      return;
    }

    if (pathCanExtendToLongerUnsolvedTarget(
          current.level,
          current.solvedLower,
          builtLower,
        ) ||
        _catalogCanExtendBuilt(current, builtLower)) {
      await clearPathOnly();
      return;
    }

    if (anyUnsolvedTargetHasLength(current.level, current.solvedLower, plen)) {
      await _commitWrongWithTray(current);
      return;
    }

    await clearPathOnly();
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
    if (unsolvedTargets(s.level, s.solvedLower).isEmpty) return;

    final plen = s.path.length;
    final builtLower = normalizeWord(s.path.map((e) => e.char).join());
    final matched = findUnsolvedTargetMatchingBuilt(
      s.level,
      s.solvedLower,
      builtLower,
    );
    if (matched != null) {
      await _applyCorrectWord(s, normalizeWord(matched.word), matched);
      return;
    }

    if (_isKnownDuplicateBuilt(s, builtLower)) {
      await _commitDuplicateSelection(s);
      return;
    }

    final catalogMatch = _catalogMatchForBuilt(s, builtLower);
    if (catalogMatch != null) {
      final replaced = _replaceUnsolvedTargetWithCatalogWord(s, catalogMatch);
      if (replaced != null) {
        await _applyCorrectWord(replaced, builtLower, catalogMatch);
        return;
      }
    }

    final maxLen = maxUnsolvedTargetLength(s.level, s.solvedLower);
    if (plen > maxLen && !_catalogCanExtendBuilt(s, builtLower)) {
      await _commitWrongWithTray(s);
      return;
    }

    if (pathCanExtendToLongerUnsolvedTarget(
          s.level,
          s.solvedLower,
          builtLower,
        ) ||
        _catalogCanExtendBuilt(s, builtLower)) {
      return;
    }

    if (anyUnsolvedTargetHasLength(s.level, s.solvedLower, plen)) {
      await _commitWrongWithTray(s);
    }
  }

  Future<void> _applyCorrectWord(
    WordBuilderViewState s,
    String norm,
    WordBuilderTargetWord matched,
  ) async {
    var persisted = s.persisted;
    final levelId = s.level.levelId;
    var lp =
        persisted.perLevel[levelId] ??
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

    final next = WordBuilderViewState(
      persisted: persisted,
      sessionLevels: s.sessionLevels,
      levelIndex: s.levelIndex,
      circleLetters: newCircle,
      path: const [],
      solvedLower: newSolved,
      revealedPositions: s.revealedPositions,
      hintTargetCycleIndex: s.hintTargetCycleIndex,
      feedbackMessage: '__correct',
      lastSolvedWord: null,
      pathWrongHighlight: false,
      wrongAnswerCount: s.wrongAnswerCount,
    );
    await _commitCorrectWithTrayDrain(next);
    if (isLevelComplete(s.level, newSolved)) {
      _stopTrayWaterAudio();
    }
    var coinReward = wordBuilderCoinsPerCorrectWord();
    if (isLevelComplete(s.level, newSolved)) {
      coinReward += wordBuilderCoinsLevelCompleteBonus();
    }
    await ref.read(wordBuilderCoinsProvider.notifier).addCoins(coinReward);
    _playSound(
      isLevelComplete(s.level, newSolved)
          ? WordBuilderSound.levelComplete
          : WordBuilderSound.correct,
    );
  }

  Future<void> goToNextLevel() async {
    final s = state.valueOrNull;
    if (s == null || !s.levelComplete) return;
    final nextIndex = s.levelIndex + 1;
    if (nextIndex >= s.sessionLevels.length) {
      _stopTrayWaterAudio();
      await _commit(s.copyWith(feedbackMessage: '__all_levels_done'));
      return;
    }
    final next = WordBuilderViewState.createInitial(
      persisted: s.persisted,
      sessionLevels: s.sessionLevels,
      levelIndex: nextIndex,
      random: _random,
    );
    _stopTrayWaterAudio();
    await _commit(next);
  }

  Future<void> hintRevealLetter() async {
    final s = state.valueOrNull;
    if (s == null || s.trayInputBlocked) return;

    final targets = s.level.targetWords;
    if (targets.isEmpty) return;

    final n = targets.length;
    final revealed = Map<String, Set<int>>.from(s.revealedPositions);
    final start = s.hintTargetCycleIndex % n;

    int? chosenSlot;
    String? chosenLw;
    int? chosenIdx;
    Set<int>? baseSetFor;

    for (var i = 0; i < n; i++) {
      final slot = (start + i) % n;
      final target = targets[slot];
      final lw = normalizeWord(target.word);
      if (s.solvedLower.contains(lw)) continue;

      final setFor = Set<int>.from(revealed[lw] ?? {});
      final idx = pickHiddenIndexForReveal(lw, setFor, _random);
      if (idx == null) continue;

      chosenSlot = slot;
      chosenLw = lw;
      chosenIdx = idx;
      baseSetFor = setFor;
      break;
    }

    if (chosenSlot == null ||
        chosenLw == null ||
        chosenIdx == null ||
        baseSetFor == null) {
      return;
    }

    final cost = wordBuilderCoinsCostHintLetter();
    final paid = await ref
        .read(wordBuilderCoinsProvider.notifier)
        .trySpend(cost);
    if (!paid) {
      await _commit(s.copyWith(feedbackMessage: '__not_enough_coins'));
      return;
    }

    final setFor = Set<int>.from(baseSetFor)..add(chosenIdx);
    revealed[chosenLw] = setFor;
    await _commit(
      s.copyWith(
        revealedPositions: revealed,
        hintTargetCycleIndex: (chosenSlot + 1) % n,
        feedbackMessage: '__hint_letter',
        clearFeedback: false,
      ),
    );
  }

  Future<void> hintRemoveWrongLetter() async {
    final s = state.valueOrNull;
    if (s == null || s.path.isEmpty || s.trayInputBlocked) return;
    if (unsolvedTargets(s.level, s.solvedLower).isEmpty) return;
    final allowed = multisetUnsolvedTargets(s.level, s.solvedLower);
    final before = List<LetterInstance>.of(s.path);
    final newPath = List<LetterInstance>.of(s.path);
    final ok = removeOneExcessLetterFromRack(newPath, allowed);
    if (!ok) {
      await _commit(s.copyWith(feedbackMessage: '__hint_remove_none'));
      return;
    }
    final removeCost = wordBuilderCoinsCostHintRemoveWrong();
    final paidRemove = await ref
        .read(wordBuilderCoinsProvider.notifier)
        .trySpend(removeCost);
    if (!paidRemove) {
      await _commit(s.copyWith(feedbackMessage: '__not_enough_coins'));
      return;
    }
    final remainingIds = newPath.map((e) => e.id).toSet();
    final removed = before.where((e) => !remainingIds.contains(e.id)).toList();
    if (removed.length != 1) return;
    await _commit(s.copyWith(path: newPath, feedbackMessage: '__hint_removed'));
  }

  Future<void> hintMeaning({required bool preferKur}) async {
    final s = state.valueOrNull;
    if (s == null || s.trayInputBlocked) return;
    final target = firstUnsolvedTarget(s.level, s.solvedLower);
    if (target == null) return;
    final meaningCost = wordBuilderCoinsCostHintMeaning();
    final paid = await ref
        .read(wordBuilderCoinsProvider.notifier)
        .trySpend(meaningCost);
    if (!paid) {
      await _commit(s.copyWith(feedbackMessage: '__not_enough_coins'));
      return;
    }
    final m = target.meaningForLang(preferKur: preferKur);
    await _commit(s.copyWith(feedbackMessage: '$kWordBuilderMeaningPrefix$m'));
  }
}
