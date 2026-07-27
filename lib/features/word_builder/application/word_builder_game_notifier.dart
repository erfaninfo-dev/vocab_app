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
import '../domain/tray_prison_constants.dart';
import '../domain/tray_prison_moment.dart';
import '../domain/tray_scenario_kind.dart';
import '../domain/tray_train_constants.dart';
import '../domain/tray_train_moment.dart';
import '../domain/tray_water_constants.dart';
import '../domain/word_builder_game_logic.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_coin_constants.dart';
import '../word_builder_constants.dart';
import 'word_builder_coins_provider.dart';
import 'word_builder_play_mode_controller.dart';
import 'word_builder_session_audio.dart';
import 'word_builder_tray_prison_audio.dart';
import 'word_builder_tray_train_audio.dart';
import 'word_builder_tray_water_audio.dart';
import '../domain/word_builder_play_mode.dart';

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
    this.trayScenario = TrayScenarioKind.water,
    this.trainMoment = TrayTrainMoment.none,
    this.prisonMoment = TrayPrisonMoment.none,
    this.angryWordsVictoryHold = false,
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

  /// Which visuals fill the tray center this level (water tub vs train rails).
  final TrayScenarioKind trayScenario;

  /// Transient animation beat for the train scenario.
  final TrayTrainMoment trainMoment;

  /// Transient animation beat for the prison scenario.
  final TrayPrisonMoment prisonMoment;

  /// True while Angry Words pops remaining balls one-by-one before the panel.
  final bool angryWordsVictoryHold;

  /// True while the train-escape victory sequence plays.
  bool get trainVictoryActive =>
      trainMoment == TrayTrainMoment.escape ||
      trainMoment == TrayTrainMoment.trainPass;

  /// True while the prison-escape victory sequence plays.
  bool get prisonVictoryActive => prisonMoment == TrayPrisonMoment.escape;

  /// True while any scenario's victory sequence plays; the session screen
  /// keeps showing the tray (instead of the level-complete panel) and input
  /// stays blocked until it finishes.
  bool get trayVictorySequenceActive =>
      trainVictoryActive || prisonVictoryActive || angryWordsVictoryHold;

  bool get trayInputBlocked =>
      pathWrongHighlight || isTrayGameOver || trayVictorySequenceActive;

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
    TrayScenarioKind? trayScenario,
    TrayTrainMoment? trainMoment,
    TrayPrisonMoment? prisonMoment,
    bool? angryWordsVictoryHold,
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
      trayScenario: trayScenario ?? this.trayScenario,
      trainMoment: trainMoment ?? this.trainMoment,
      prisonMoment: prisonMoment ?? this.prisonMoment,
      angryWordsVictoryHold:
          angryWordsVictoryHold ?? this.angryWordsVictoryHold,
    );
  }

  static WordBuilderViewState createInitial({
    required WordBuilderPersistedProgress persisted,
    required List<WordBuilderLevel> sessionLevels,
    required int levelIndex,
    required Random random,
    TrayScenarioKind? scenarioOverride,
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
      trayScenario: scenarioOverride ?? trayScenarioForLevelIndex(levelIndex),
    );
  }
}

class WordBuilderGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<WordBuilderViewState, int> {
  final Random _random = Random();
  Timer? _passiveWaterTimer;
  Map<String, WordBuilderTargetWord> _globalTargetsByLemma = const {};

  /// Last lemma shown by Translate — avoid immediate repeat when possible.
  String? _lastHintMeaningLemma;

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

  Set<int> _unsolvedTargetLengths(WordBuilderLevel level, Set<String> solved) {
    return {
      for (final target in level.targetWords)
        if (!solved.contains(normalizeWord(target.word)))
          normalizeWord(target.word).length,
    };
  }

  WordBuilderTargetWord? _catalogMatchForBuilt(
    WordBuilderViewState s,
    String builtLower,
  ) {
    final norm = normalizeWord(builtLower);
    if (norm.length < 2) return null;
    if (!_unsolvedTargetLengths(s.level, s.solvedLower).contains(norm.length)) {
      return null;
    }
    if (_isCurrentLevelTarget(s.level, norm)) return null;
    if (_wasSolvedAnywhere(norm, s.persisted, s.solvedLower)) return null;
    final target = _globalTargetsByLemma[norm];
    if (target == null) return null;
    if (!canSpellFromPool(norm, letterCounts(s.level.letters))) return null;
    return target;
  }

  /// True when [builtLower] can still grow into an unsolved longer word
  /// (stage slot or catalog fill for an open length).
  bool _canContinueBuiltTowardUnsolved(
    WordBuilderViewState s,
    String builtLower,
  ) {
    final prefix = normalizeWord(builtLower);
    if (prefix.isEmpty) return false;
    return pathCanExtendToLongerUnsolvedTarget(
          s.level,
          s.solvedLower,
          prefix,
        ) ||
        isValidUnsolvedTargetPrefix(s.level, s.solvedLower, prefix) ||
        _catalogCanExtendBuilt(s, prefix);
  }

  bool _isKnownDuplicateBuilt(WordBuilderViewState s, String builtLower) {
    final norm = normalizeWord(builtLower);
    if (norm.length < 2) return false;
    if (!_wasSolvedAnywhere(norm, s.persisted, s.solvedLower)) return false;
    // e.g. solved "ad" while "add" is still open — not a finished duplicate.
    if (_canContinueBuiltTowardUnsolved(s, norm)) return false;
    return _isCurrentLevelTarget(s.level, norm) ||
        _globalTargetsByLemma.containsKey(norm);
  }

  bool _catalogCanExtendBuilt(WordBuilderViewState s, String builtLower) {
    final prefix = normalizeWord(builtLower);
    if (prefix.isEmpty) return false;
    final pool = letterCounts(s.level.letters);
    final allowedLengths = _unsolvedTargetLengths(s.level, s.solvedLower);
    for (final entry in _globalTargetsByLemma.entries) {
      final word = entry.key;
      if (word.length <= prefix.length || !word.startsWith(prefix)) continue;
      if (!allowedLengths.contains(word.length)) continue;
      // Allow extending into an unsolved stage target (e.g. "ad" → "add").
      if (_isCurrentLevelTarget(s.level, word)) {
        if (s.solvedLower.contains(word)) continue;
      } else if (_wasSolvedAnywhere(word, s.persisted, s.solvedLower)) {
        continue;
      }
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
    required int length,
  }) {
    for (var i = 0; i < level.targetWords.length; i++) {
      final target = level.targetWords[i];
      if (solvedLower.contains(normalizeWord(target.word))) continue;
      if (normalizeWord(target.word).length == length) return i;
    }
    return -1;
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
          length: normalizeWord(pending.word).length,
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
      length: acceptedNorm.length,
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
        s.trayVictorySequenceActive ||
        s.pathWrongHighlight ||
        s.isInletValveOpen ||
        s.isOutletValveOpen) {
      return;
    }
    // Physics letter boards have no tray tension.
    if (ref.read(wordBuilderPlayModeProvider).skipsTrayTension) {
      return;
    }

    final nextLevel =
        (s.trayWaterLevel + TrayWaterConstants.passiveWaterIncrement).clamp(
          0.0,
          1.0,
        );
    if ((nextLevel - s.trayWaterLevel) < 0.0005) return;

    final overflow = nextLevel >= 1.0;
    final isWater = s.trayScenario == TrayScenarioKind.water;
    await _commit(
      s.copyWith(
        trayWaterLevel: nextLevel,
        isOutletValveOpen: false,
        faceMood: isWater
            ? _faceMoodForWater(nextLevel, overflow: overflow)
            : s.faceMood,
        isTrayGameOver: overflow,
      ),
    );
    if (overflow) _silenceTrayLoopsForGameOver(s.trayScenario);
  }

  void _playSound(WordBuilderSound sound) {
    final enabled = ref.read(wordBuilderGameSfxEnabledProvider);
    unawaited(
      ref.read(wordBuilderSoundServiceProvider).play(sound, enabled: enabled),
    );
  }

  void _stopTrayScenarioAudio() {
    unawaited(ref.read(wordBuilderTrayWaterAudioProvider(arg)).stopAll());
    unawaited(ref.read(wordBuilderTrayTrainAudioProvider(arg)).stopAll());
    unawaited(ref.read(wordBuilderTrayPrisonAudioProvider(arg)).stopAll());
  }

  /// On overflow only the ambient loops stop; one-shot game-over sounds
  /// (water pill / train brake) keep playing from the scene.
  void _silenceTrayLoopsForGameOver(TrayScenarioKind scenario) {
    switch (scenario) {
      case TrayScenarioKind.water:
        unawaited(ref.read(wordBuilderTrayWaterAudioProvider(arg)).stopLoops());
      case TrayScenarioKind.train:
        unawaited(ref.read(wordBuilderTrayTrainAudioProvider(arg)).stopLoops());
      case TrayScenarioKind.prison:
        unawaited(
          ref.read(wordBuilderTrayPrisonAudioProvider(arg)).stopLoops(),
        );
    }
  }

  bool get _traySfxEnabled => ref.read(wordBuilderGameWaterSfxEnabledProvider);

  void _onTrayWrongScenarioAudio(
    TrayScenarioKind scenario,
    int wrongCount, {
    required bool overflow,
  }) {
    final enabled = _traySfxEnabled;
    switch (scenario) {
      case TrayScenarioKind.water:
        final audio = ref.read(wordBuilderTrayWaterAudioProvider(arg));
        if (overflow) {
          unawaited(audio.playPillOnly(enabled: enabled));
          unawaited(audio.stopLoops());
          return;
        }
        unawaited(audio.onWrongAnswer(wrongCount, enabled: enabled));
      case TrayScenarioKind.train:
        final audio = ref.read(wordBuilderTrayTrainAudioProvider(arg));
        if (overflow) {
          // The train scene plays the brake as part of its game-over
          // sequence; here we only silence the approach loop.
          unawaited(audio.stopLoops());
          return;
        }
        unawaited(audio.onWrongAnswer(wrongCount, enabled: enabled));
      case TrayScenarioKind.prison:
        final audio = ref.read(wordBuilderTrayPrisonAudioProvider(arg));
        if (overflow) {
          // The prison scene plays the guard-wake sound as part of its
          // game-over sequence; here we only silence the heartbeat loop.
          unawaited(audio.stopLoops());
          return;
        }
        unawaited(audio.onWrongAnswer(wrongCount, enabled: enabled));
    }
  }

  void _syncTrayStageAudio(TrayScenarioKind scenario, int wrongCount) {
    final enabled = _traySfxEnabled;
    switch (scenario) {
      case TrayScenarioKind.water:
        unawaited(
          ref
              .read(wordBuilderTrayWaterAudioProvider(arg))
              .syncWaterStage(wrongCount, enabled: enabled),
        );
      case TrayScenarioKind.train:
        unawaited(
          ref
              .read(wordBuilderTrayTrainAudioProvider(arg))
              .syncTensionStage(wrongCount, enabled: enabled),
        );
      case TrayScenarioKind.prison:
        unawaited(
          ref
              .read(wordBuilderTrayPrisonAudioProvider(arg))
              .syncTensionStage(wrongCount, enabled: enabled),
        );
    }
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
    if (s.trayVictorySequenceActive) return;

    // Physics boards: wrong only flashes the path — no water / game-over lock.
    if (ref.read(wordBuilderPlayModeProvider).skipsTrayTension) {
      await _commit(
        s.copyWith(
          pathWrongHighlight: true,
          clearFeedback: true,
          isTrayGameOver: false,
        ),
      );
      _playSound(WordBuilderSound.wrong);
      return;
    }

    if (s.isTrayGameOver) return;

    final isWater = s.trayScenario == TrayScenarioKind.water;
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
        isInletValveOpen: isWater,
        isOutletValveOpen: false,
        faceMood: isWater
            ? _faceMoodForWater(nextLevel, overflow: overflow)
            : s.faceMood,
        isTrayGameOver: overflow,
        trainMoment: TrayTrainMoment.none,
        prisonMoment: TrayPrisonMoment.none,
      ),
    );
    _playSound(WordBuilderSound.wrong);
    _onTrayWrongScenarioAudio(s.trayScenario, nextCount, overflow: overflow);
    if (isWater) {
      unawaited(
        Future<void>.delayed(TrayWaterConstants.inletOpenDuration, () {
          if (state.valueOrNull != null) unawaited(_closeInletValve());
        }),
      );
    }
  }

  Future<void> _commitCorrectWithTrayDrain(
    WordBuilderViewState next, {
    required bool levelNowComplete,
  }) async {
    final s = state.valueOrNull;
    final scenario = s?.trayScenario ?? next.trayScenario;
    final prevLevel = s?.trayWaterLevel ?? 0.0;
    final prevWrong = s?.wrongAnswerCount ?? 0;
    final drainedLevel = (prevLevel - TrayWaterConstants.waterPerWrong).clamp(
      0.0,
      1.0,
    );
    final nextWrong = max(0, prevWrong - 1);
    final isWater = scenario == TrayScenarioKind.water;
    final isTrain = scenario == TrayScenarioKind.train;
    final isPrison = scenario == TrayScenarioKind.prison;
    final isAngryWords =
        ref.read(wordBuilderPlayModeProvider) == WordBuilderPlayMode.angryWords;

    await _commit(
      next.copyWith(
        trayWaterLevel: drainedLevel,
        wrongAnswerCount: nextWrong,
        isInletValveOpen: false,
        isOutletValveOpen: isWater,
        faceMood: isWater ? TrayFaceMood.happy : next.faceMood,
        pathWrongHighlight: false,
        trayScenario: scenario,
        prisonMoment: isPrison && levelNowComplete
            ? TrayPrisonMoment.escape
            : TrayPrisonMoment.none,
        trainMoment: isTrain
            ? (levelNowComplete
                  ? TrayTrainMoment.escape
                  : TrayTrainMoment.ropeBreak)
            : TrayTrainMoment.none,
        angryWordsVictoryHold: isAngryWords && levelNowComplete,
      ),
    );
    _syncTrayStageAudio(scenario, nextWrong);
    if (isWater) {
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
    if (isTrain) {
      final audio = ref.read(wordBuilderTrayTrainAudioProvider(arg));
      if (levelNowComplete) {
        unawaited(_runTrainVictorySequence());
      } else {
        unawaited(audio.onRopeBreak(enabled: _traySfxEnabled));
        unawaited(
          Future<void>.delayed(TrayTrainConstants.ropeSnapDuration, () {
            final cur = state.valueOrNull;
            if (cur != null && cur.trainMoment == TrayTrainMoment.ropeBreak) {
              unawaited(
                _commit(cur.copyWith(trainMoment: TrayTrainMoment.none)),
              );
            }
          }),
        );
      }
    }
    if (isPrison) {
      final audio = ref.read(wordBuilderTrayPrisonAudioProvider(arg));
      if (levelNowComplete) {
        unawaited(_runPrisonVictorySequence());
      } else {
        unawaited(audio.onKeyJingle(enabled: _traySfxEnabled));
      }
    }
  }

  /// Clears the Angry Words pop celebration so the level-complete panel can show.
  Future<void> clearAngryWordsVictoryHold() async {
    final s = state.valueOrNull;
    if (s == null || !s.angryWordsVictoryHold) return;
    await _commit(s.copyWith(angryWordsVictoryHold: false));
  }

  /// Key grab → door unlock → tiptoe escape, then clear the moment so the
  /// level-complete panel can appear. Input stays blocked via
  /// [WordBuilderViewState.prisonVictoryActive].
  Future<void> _runPrisonVictorySequence() async {
    final audio = ref.read(wordBuilderTrayPrisonAudioProvider(arg));
    unawaited(audio.stopLoops());
    unawaited(audio.onKeyJingle(enabled: _traySfxEnabled));
    await Future<void>.delayed(TrayPrisonConstants.keyGrabDuration);
    var cur = state.valueOrNull;
    if (cur == null || cur.prisonMoment != TrayPrisonMoment.escape) return;
    unawaited(audio.onDoorUnlock(enabled: _traySfxEnabled));
    await Future<void>.delayed(
      TrayPrisonConstants.escapeDuration +
          TrayPrisonConstants.victoryEndPadding,
    );
    cur = state.valueOrNull;
    if (cur == null || cur.prisonMoment != TrayPrisonMoment.escape) return;
    await _commit(cur.copyWith(prisonMoment: TrayPrisonMoment.none));
  }

  /// Escape → train pass → clear the moment so the level-complete panel
  /// can appear. Input stays blocked via [WordBuilderViewState.trainVictoryActive].
  Future<void> _runTrainVictorySequence() async {
    final audio = ref.read(wordBuilderTrayTrainAudioProvider(arg));
    unawaited(audio.stopLoops());
    unawaited(audio.onRopeBreak(enabled: _traySfxEnabled));
    await Future<void>.delayed(TrayTrainConstants.escapeDuration);
    var cur = state.valueOrNull;
    if (cur == null || cur.trainMoment != TrayTrainMoment.escape) return;
    await _commit(cur.copyWith(trainMoment: TrayTrainMoment.trainPass));
    unawaited(audio.onTrainPass(enabled: _traySfxEnabled));
    await Future<void>.delayed(
      TrayTrainConstants.trainPassDuration +
          TrayTrainConstants.victoryEndPadding,
    );
    cur = state.valueOrNull;
    if (cur == null || cur.trainMoment != TrayTrainMoment.trainPass) return;
    await _commit(cur.copyWith(trainMoment: TrayTrainMoment.none));
  }

  Future<void> resetTrayAfterGameOver() async {
    final s = state.valueOrNull;
    if (s == null || !s.isTrayGameOver) return;
    final fresh = WordBuilderViewState.createInitial(
      persisted: s.persisted,
      sessionLevels: s.sessionLevels,
      levelIndex: s.levelIndex,
      random: _random,
      scenarioOverride: s.trayScenario,
    );
    await _commit(fresh);
    _stopTrayScenarioAudio();
  }

  /// Clears solved words for the current level and restarts it in place
  /// (same scenario). Campaign stages re-pick/order targets with a fresh RNG
  /// so Translate is not stuck on the previous first word. Coins kept.
  Future<void> replayCurrentLevel() async {
    final s = state.valueOrNull;
    if (s == null || !s.levelComplete) return;
    final levelId = s.level.levelId;
    final prev = s.persisted.perLevel[levelId];
    final cleared = WordBuilderLevelProgress(
      completed: false,
      attempts: prev?.attempts ?? 0,
      correctSubmissions: 0,
      solvedWordsLower: const {},
    );
    final persisted = s.persisted.copyWith(
      perLevel: {...s.persisted.perLevel, levelId: cleared},
    );

    var sessionLevels = List<WordBuilderLevel>.of(s.sessionLevels);
    final campaign = decodeWordBuilderCampaignSessionKey(arg);
    if (campaign != null) {
      final plan = await ref.read(wordBuilderCampaignPlanProvider.future);
      final stageLists = plan.stagesFor(campaign.difficulty);
      final idx = campaign.stage1Based - 1;
      if (idx >= 0 && idx < stageLists.length) {
        final rebuilt = buildCampaignStageLevel(
          entries: stageLists[idx],
          difficulty: campaign.difficulty,
          categoryLabel:
              'campaign_${campaign.difficulty.name}_${campaign.stage1Based}',
          stage1Based: campaign.stage1Based,
          random: _random,
        );
        if (rebuilt.targetWords.isNotEmpty) {
          final shuffled = List<WordBuilderTargetWord>.of(rebuilt.targetWords)
            ..shuffle(_random);
          sessionLevels = [
            WordBuilderLevel(
              levelId: rebuilt.levelId,
              difficulty: rebuilt.difficulty,
              category: rebuilt.category,
              letters: List<String>.of(rebuilt.letters),
              targetWords: List<WordBuilderTargetWord>.unmodifiable(shuffled),
            ),
          ];
        }
      }
    } else {
      // Free play: reshuffle target order so hints don't stick to slot 0.
      final level = s.level;
      final shuffled = List<WordBuilderTargetWord>.of(level.targetWords)
        ..shuffle(_random);
      sessionLevels[s.levelIndex] = WordBuilderLevel(
        levelId: level.levelId,
        difficulty: level.difficulty,
        category: level.category,
        letters: List<String>.of(level.letters),
        targetWords: List<WordBuilderTargetWord>.unmodifiable(shuffled),
      );
    }

    _lastHintMeaningLemma = null;
    final fresh = WordBuilderViewState.createInitial(
      persisted: persisted,
      sessionLevels: sessionLevels,
      levelIndex: campaign != null ? 0 : s.levelIndex,
      random: _random,
      scenarioOverride: s.trayScenario,
    );
    await _commit(fresh);
    _stopTrayScenarioAudio();
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
        // Single-level campaign session: rotate by stage number instead of
        // levelIndex so consecutive stages cycle water → train → prison.
        scenarioOverride: trayScenarioForLevelIndex(campaign.stage1Based - 1),
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
    if (s == null) return;
    final physics = ref
        .read(wordBuilderPlayModeProvider)
        .usesPhysicsLetterBoard;
    if (physics) {
      if (s.pathWrongHighlight || s.trayVictorySequenceActive) return;
    } else if (s.trayInputBlocked) {
      return;
    }
    if (s.path.any((e) => e.id == letter.id)) return;
    final newPath = List<LetterInstance>.of(s.path)..add(letter);
    await _commit(s.copyWith(path: newPath, clearFeedback: true));
  }

  /// Arkanoid PREFIX_CHECK after every letter (stage targets only).
  Future<void> evaluateArkanoidAfterLetter({bool pathClean = true}) =>
      evaluatePhysicsLetterAfterLetter(pathClean: pathClean);

  /// PREFIX_CHECK after every letter for Arkanoid / Angry Words.
  ///
  /// Same catalog rules as Classic: a non-duplicate full catalog word that
  /// matches an unsolved slot length is accepted and swaps into that slot.
  /// Catalog prefixes also keep the path alive (not marked wrong).
  Future<void> evaluatePhysicsLetterAfterLetter({bool pathClean = true}) async {
    if (!ref.read(wordBuilderPlayModeProvider).usesPhysicsLetterBoard) {
      return;
    }
    final s = state.valueOrNull;
    if (s == null || s.path.isEmpty) return;
    if (s.pathWrongHighlight || s.trayVictorySequenceActive) return;

    final builtLower = normalizeWord(s.path.map((e) => e.char).join());
    final matched = findUnsolvedTargetMatchingBuilt(
      s.level,
      s.solvedLower,
      builtLower,
    );
    if (matched != null) {
      await _applyCorrectWord(
        s,
        normalizeWord(matched.word),
        matched,
        perfectRun: pathClean,
      );
      return;
    }

    // Prefer open longer slots (e.g. "ad"→"add") over "already found".
    if (_canContinueBuiltTowardUnsolved(s, builtLower)) {
      await _commit(s.copyWith(feedbackMessage: '__arkanoid_prefix'));
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
        await _applyCorrectWord(
          replaced,
          builtLower,
          catalogMatch,
          perfectRun: pathClean,
        );
        return;
      }
    }

    await _commitWrongWithTray(s);
  }

  /// Whether appending [nextChar] is still a valid physics path step:
  /// stage target / prefix, or Classic-style catalog match / catalog prefix.
  bool isPhysicsNextLetterProgress(String nextChar) {
    final s = state.valueOrNull;
    if (s == null || nextChar.trim().isEmpty) return false;
    if (s.pathWrongHighlight || s.trayVictorySequenceActive) return false;

    final built = normalizeWord('${s.path.map((e) => e.char).join()}$nextChar');
    if (findUnsolvedTargetMatchingBuilt(s.level, s.solvedLower, built) !=
        null) {
      return true;
    }
    if (_canContinueBuiltTowardUnsolved(s, built)) return true;
    if (_catalogMatchForBuilt(s, built) != null) return true;
    return false;
  }

  Future<void> evaluatePathOnDragRelease() async {
    final s = state.valueOrNull;
    if (s == null || s.path.isEmpty) return;
    final physics = ref
        .read(wordBuilderPlayModeProvider)
        .usesPhysicsLetterBoard;
    if (physics) {
      if (s.pathWrongHighlight || s.trayVictorySequenceActive) return;
    } else if (s.trayInputBlocked) {
      return;
    }
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

    final plen = current.path.length;
    final maxLen = maxUnsolvedTargetLength(current.level, current.solvedLower);

    if (plen > maxLen && !_catalogCanExtendBuilt(current, builtLower)) {
      await _commitWrongWithTray(current);
      return;
    }

    // Incomplete path toward a longer open word — clear without "already found".
    if (_canContinueBuiltTowardUnsolved(current, builtLower)) {
      await clearPathOnly();
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

  /// Clears tray water / game-over so physics boards are never locked by
  /// classic tray tension left over from earlier wrongs.
  Future<void> prepareArkanoidMode() => preparePhysicsLetterMode();

  Future<void> preparePhysicsLetterMode() async {
    final s = state.valueOrNull;
    if (s == null) return;
    if (!s.isTrayGameOver &&
        s.trayWaterLevel <= 0 &&
        s.wrongAnswerCount == 0 &&
        !s.pathWrongHighlight) {
      return;
    }
    await _commit(
      s.copyWith(
        isTrayGameOver: false,
        trayWaterLevel: 0,
        wrongAnswerCount: 0,
        path: const [],
        pathWrongHighlight: false,
        clearFeedback: true,
        isInletValveOpen: false,
        isOutletValveOpen: false,
        trainMoment: TrayTrainMoment.none,
        prisonMoment: TrayPrisonMoment.none,
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

    final maxLen = maxUnsolvedTargetLength(s.level, s.solvedLower);
    if (plen > maxLen && !_catalogCanExtendBuilt(s, builtLower)) {
      await _commitWrongWithTray(s);
      return;
    }

    // Keep path while it can still become an open longer word (ad → add).
    if (_canContinueBuiltTowardUnsolved(s, builtLower)) {
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

    if (anyUnsolvedTargetHasLength(s.level, s.solvedLower, plen)) {
      await _commitWrongWithTray(s);
    }
  }

  /// Checks each row's left-to-right spelling against any unsolved target.
  /// Returns row indexes that were newly solved this pass.
  Future<List<int>> evaluatePuzzleRows(List<String?> rowWords) async {
    if (!ref.read(wordBuilderPlayModeProvider).usesPuzzleLetterBoard) {
      return const [];
    }
    final s = state.valueOrNull;
    if (s == null || s.trayVictorySequenceActive) return const [];

    var current = s;
    final newlySolvedRows = <int>[];
    for (var i = 0; i < rowWords.length; i++) {
      final built = rowWords[i];
      if (built == null || built.isEmpty) continue;
      final matched = findUnsolvedTargetMatchingBuilt(
        current.level,
        current.solvedLower,
        built,
      );
      if (matched == null) continue;
      newlySolvedRows.add(i);
      await _applyCorrectWord(
        current,
        normalizeWord(matched.word),
        matched,
        perfectRun: true,
      );
      current = state.valueOrNull ?? current;
      if (current.trayVictorySequenceActive || current.levelComplete) {
        return newlySolvedRows;
      }
    }
    return newlySolvedRows;
  }

  Future<void> _applyCorrectWord(
    WordBuilderViewState s,
    String norm,
    WordBuilderTargetWord matched, {
    bool perfectRun = false,
  }) async {
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

    // Train/prison victory: keep the ring visible so the tray can play the
    // escape sequence before the complete panel.
    final keepRingForVictory =
        isLevelComplete(s.level, newSolved) &&
        (s.trayScenario == TrayScenarioKind.train ||
            s.trayScenario == TrayScenarioKind.prison);
    final newCircle = isLevelComplete(s.level, newSolved)
        ? (keepRingForVictory
              ? List<LetterInstance>.of(s.circleLetters)
              : const <LetterInstance>[])
        : shuffleInstances(
            buildLetterInstances(activeTargetLetterChars(s.level)),
            _random,
          );

    final levelNowComplete = isLevelComplete(s.level, newSolved);
    final next = WordBuilderViewState(
      persisted: persisted,
      sessionLevels: s.sessionLevels,
      levelIndex: s.levelIndex,
      circleLetters: newCircle,
      path: const [],
      solvedLower: newSolved,
      revealedPositions: s.revealedPositions,
      hintTargetCycleIndex: s.hintTargetCycleIndex,
      feedbackMessage: perfectRun ? '__correct_perfect' : '__correct',
      lastSolvedWord: matched,
      pathWrongHighlight: false,
      wrongAnswerCount: s.wrongAnswerCount,
      trayScenario: s.trayScenario,
    );
    await _commitCorrectWithTrayDrain(next, levelNowComplete: levelNowComplete);
    if (levelNowComplete && s.trayScenario == TrayScenarioKind.water) {
      _stopTrayScenarioAudio();
    }
    var coinReward = wordBuilderCoinsPerCorrectWord();
    if (perfectRun &&
        ref.read(wordBuilderPlayModeProvider).usesPhysicsLetterBoard) {
      coinReward += wordBuilderCoinsArkanoidPerfectBonus();
    }
    if (isLevelComplete(s.level, newSolved)) {
      coinReward += wordBuilderCoinsLevelCompleteBonus();
    }
    await ref.read(wordBuilderCoinsProvider.notifier).addCoins(coinReward);
    final levelDone = isLevelComplete(s.level, newSolved);
    final deferLevelSfx =
        levelDone &&
        ref.read(wordBuilderPlayModeProvider) == WordBuilderPlayMode.angryWords;
    // Angry Words plays pops then levelComplete after the celebration board
    // finishes — overlapping just_audio loads on Windows crash the engine.
    if (!deferLevelSfx) {
      _playSound(
        levelDone ? WordBuilderSound.levelComplete : WordBuilderSound.correct,
      );
    }
  }

  Future<void> goToNextLevel() async {
    final s = state.valueOrNull;
    if (s == null || !s.levelComplete) return;
    final nextIndex = s.levelIndex + 1;
    if (nextIndex >= s.sessionLevels.length) {
      _stopTrayScenarioAudio();
      await _commit(s.copyWith(feedbackMessage: '__all_levels_done'));
      return;
    }
    final next = WordBuilderViewState.createInitial(
      persisted: s.persisted,
      sessionLevels: s.sessionLevels,
      levelIndex: nextIndex,
      random: _random,
    );
    _stopTrayScenarioAudio();
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
    final target = _pickRandomUnsolvedTargetForMeaning(s);
    if (target == null) return;
    final meaningCost = wordBuilderCoinsCostHintMeaning();
    final paid = await ref
        .read(wordBuilderCoinsProvider.notifier)
        .trySpend(meaningCost);
    if (!paid) {
      await _commit(s.copyWith(feedbackMessage: '__not_enough_coins'));
      return;
    }
    _lastHintMeaningLemma = normalizeWord(target.word);
    final m = target.meaningForLang(preferKur: preferKur);
    await _commit(s.copyWith(feedbackMessage: '$kWordBuilderMeaningPrefix$m'));
  }

  /// Random unsolved target for Translate; avoids repeating the last lemma
  /// when another unsolved word is available.
  WordBuilderTargetWord? _pickRandomUnsolvedTargetForMeaning(
    WordBuilderViewState s,
  ) {
    final open = unsolvedTargets(s.level, s.solvedLower);
    if (open.isEmpty) return null;
    if (open.length == 1) return open.first;
    final avoid = _lastHintMeaningLemma;
    final fresh = avoid == null
        ? open
        : [
            for (final t in open)
              if (normalizeWord(t.word) != avoid) t,
          ];
    final pool = fresh.isNotEmpty ? fresh : open;
    return pool[_random.nextInt(pool.length)];
  }
}
