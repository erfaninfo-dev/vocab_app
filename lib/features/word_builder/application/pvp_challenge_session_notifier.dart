import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pvp_scoring.dart';
import '../domain/word_builder_game_logic.dart';
import '../domain/word_builder_models.dart';

class PvpChallengePlayState {
  const PvpChallengePlayState({
    required this.circleLetters,
    this.path = const [],
    this.foundWords = const {},
    this.secondsLeft = 60,
    this.running = false,
    this.finished = false,
    this.pathWrong = false,
    this.lastFeedback,
    this.startedAt,
    this.submittedWords = const [],
  });

  final List<LetterInstance> circleLetters;
  final List<LetterInstance> path;
  final Set<String> foundWords;
  final int secondsLeft;
  final bool running;
  final bool finished;
  final bool pathWrong;
  final String? lastFeedback;
  final DateTime? startedAt;
  final List<String> submittedWords;

  int get liveScore => pvpTotalScore(foundWords);

  String get builtWord =>
      normalizeWord(path.map((e) => e.char).join());

  PvpChallengePlayState copyWith({
    List<LetterInstance>? circleLetters,
    List<LetterInstance>? path,
    Set<String>? foundWords,
    int? secondsLeft,
    bool? running,
    bool? finished,
    bool? pathWrong,
    String? lastFeedback,
    DateTime? startedAt,
    List<String>? submittedWords,
    bool clearFeedback = false,
    bool clearPathWrong = false,
  }) {
    return PvpChallengePlayState(
      circleLetters: circleLetters ?? this.circleLetters,
      path: path ?? this.path,
      foundWords: foundWords ?? this.foundWords,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      running: running ?? this.running,
      finished: finished ?? this.finished,
      pathWrong: clearPathWrong ? false : (pathWrong ?? this.pathWrong),
      lastFeedback: clearFeedback ? null : (lastFeedback ?? this.lastFeedback),
      startedAt: startedAt ?? this.startedAt,
      submittedWords: submittedWords ?? this.submittedWords,
    );
  }
}

class PvpChallengeSessionNotifier extends AutoDisposeNotifier<PvpChallengePlayState> {
  Set<String> _dictionary = {};
  Map<String, int> _letterPool = {};
  Timer? _timer;

  @override
  PvpChallengePlayState build() {
    ref.onDispose(_disposeTimer);
    return const PvpChallengePlayState(circleLetters: []);
  }

  void init({
    required List<String> letters,
    required Set<String> dictionary,
    required int durationSec,
  }) {
    _dictionary = dictionary;
    _letterPool = pvpLetterPoolFromLetters(letters);
    final instances = buildLetterInstances(letters);
    state = PvpChallengePlayState(
      circleLetters: instances,
      secondsLeft: durationSec,
    );
  }

  void start() {
    if (state.running || state.finished) return;
    _disposeTimer();
    state = state.copyWith(
      running: true,
      startedAt: DateTime.now().toUtc(),
      clearFeedback: true,
      clearPathWrong: true,
      path: const [],
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.running || state.finished) return;
    final next = state.secondsLeft - 1;
    if (next <= 0) {
      finish();
      return;
    }
    state = state.copyWith(secondsLeft: next);
  }

  void appendLetter(LetterInstance letter) {
    if (!state.running || state.finished) return;
    if (!state.circleLetters.any((e) => e.id == letter.id)) return;
  final path = List<LetterInstance>.of(state.path);
    if (path.isNotEmpty && path.last.id == letter.id) return;
    path.add(letter);
    state = state.copyWith(
      path: path,
      clearPathWrong: true,
      clearFeedback: true,
    );
  }

  void clearPath() {
    if (!state.running || state.finished) return;
    state = state.copyWith(path: const [], clearPathWrong: true);
  }

  void evaluatePathOnRelease() {
    if (!state.running || state.finished) return;
    final built = state.builtWord;
    if (built.length < kPvpMinWordLength) {
      state = state.copyWith(path: const []);
      return;
    }
    final rackOk = normalizeWord(state.path.map((e) => e.char).join()) == built;
    if (!rackOk) {
      state = state.copyWith(pathWrong: true, lastFeedback: 'invalid');
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        state = state.copyWith(path: const [], clearPathWrong: true);
      });
      return;
    }
    final valid = pvpIsValidLocalWord(
      word: built,
      dictionaryLower: _dictionary,
      letterPool: _letterPool,
      alreadyFound: state.foundWords,
    );
    if (!valid) {
      state = state.copyWith(pathWrong: true, lastFeedback: 'wrong');
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        state = state.copyWith(path: const [], clearPathWrong: true);
      });
      return;
    }
    final found = Set<String>.of(state.foundWords)..add(built);
    final submitted = List<String>.of(state.submittedWords)..add(built);
    state = state.copyWith(
      foundWords: found,
      submittedWords: submitted,
      path: const [],
      lastFeedback: built,
      clearPathWrong: true,
    );
  }

  void finish() {
    _disposeTimer();
    state = state.copyWith(
      running: false,
      finished: true,
      secondsLeft: 0,
      path: const [],
      clearPathWrong: true,
    );
  }

  void _disposeTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final pvpChallengeSessionProvider =
    NotifierProvider.autoDispose<PvpChallengeSessionNotifier, PvpChallengePlayState>(
  PvpChallengeSessionNotifier.new,
);
