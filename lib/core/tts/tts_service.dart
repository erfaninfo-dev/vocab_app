import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum TtsStatus { idle, speaking, paused }

/// Extra bottom inset when the global [TtsPlayerOverlay] is visible (FAB dialogs use it).
const double kTtsMiniPlayerBottomReserve = 88;

class TtsState {
  const TtsState({
    this.status = TtsStatus.idle,
    this.activeText = '',
    this.spokenTextOffset = 0,
    this.progressStart = -1,
    this.progressEnd = -1,
    this.progressWord = '',
    this.lingeringReadText,
    this.showMiniPlayer = true,
  });
  final TtsStatus status;
  final String activeText;
  final int spokenTextOffset;
  final int progressStart;
  final int progressEnd;
  final String progressWord;
  final String? lingeringReadText;

  /// When false, [TtsPlayerOverlay] stays hidden (e.g. word/example taps on cards).
  final bool showMiniPlayer;

  bool get isSpeaking => status == TtsStatus.speaking;
  bool get isPaused => status == TtsStatus.paused;
  bool get hasActivePlayback =>
      status == TtsStatus.speaking || status == TtsStatus.paused;

  bool isSpeakingText(String text) => hasActivePlayback && activeText == text;

  bool showsLingeringFullRead(String text) =>
      !hasActivePlayback &&
      lingeringReadText != null &&
      lingeringReadText == text;

  TtsState copyWith({
    TtsStatus? status,
    String? activeText,
    int? spokenTextOffset,
    int? progressStart,
    int? progressEnd,
    String? progressWord,
    String? lingeringReadText,
    bool clearLingeringReadText = false,
    bool? showMiniPlayer,
  }) => TtsState(
    status: status ?? this.status,
    activeText: activeText ?? this.activeText,
    spokenTextOffset: spokenTextOffset ?? this.spokenTextOffset,
    progressStart: progressStart ?? this.progressStart,
    progressEnd: progressEnd ?? this.progressEnd,
    progressWord: progressWord ?? this.progressWord,
    lingeringReadText: clearLingeringReadText
        ? null
        : (lingeringReadText ?? this.lingeringReadText),
    showMiniPlayer: showMiniPlayer ?? this.showMiniPlayer,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TtsNotifier extends StateNotifier<TtsState> {
  TtsNotifier() : super(const TtsState()) {
    _init();
  }

  final _tts = FlutterTts();
  int _suppressNextResets = 0;

  Timer? _progressTimer;
  Timer? _fallbackGraceTimer;
  Timer? _stallFillerTimer;
  DateTime? _lastPlatformProgressAt;
  DateTime? _progressSimAnchorTime;
  int _progressSimAnchorChar = 0;
  double _speechRate = 0.45;

  /// True after at least one [speak.onProgress] for the current utterance — word-aware.
  bool _platformReportsProgress = false;

  /// Time-based filler only when the OS never sends [speak.onProgress] (Web, old APIs).
  bool _simulatedProgressActive = false;

  /// When [speak.onProgress] is missing or sparse (Web, older Android, some engines),
  /// drive the seek bar from elapsed time; when the platform reports ranges, we resync.
  double get _estimatedCharsPerSecond => 14.0 * (0.25 + 0.75 * _speechRate);

  void _cancelProgressTicker() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _simulatedProgressActive = false;
  }

  void _cancelFallbackGrace() {
    _fallbackGraceTimer?.cancel();
    _fallbackGraceTimer = null;
  }

  void _cancelStallFiller() {
    _stallFillerTimer?.cancel();
    _stallFillerTimer = null;
  }

  /// If the engine stops emitting ranges mid-utterance (sparse callbacks), resume smooth progress.
  void _scheduleStallFiller() {
    _cancelStallFiller();
    _stallFillerTimer = Timer(const Duration(milliseconds: 650), () {
      _stallFillerTimer = null;
      if (!mounted) return;
      if (state.status != TtsStatus.speaking) return;
      final last = _lastPlatformProgressAt;
      if (last == null) return;
      if (DateTime.now().difference(last) < const Duration(milliseconds: 520)) {
        return;
      }
      if (_simulatedProgressActive) return;
      _startSimulatedProgressTicker(despitePlatformProgress: true);
    });
  }

  void _resyncProgressSimulation(int charIndexInFullText) {
    final t = state.activeText;
    if (t.isEmpty) return;
    final n = t.length;
    _progressSimAnchorChar = charIndexInFullText.clamp(0, n);
    _progressSimAnchorTime = DateTime.now();
  }

  void _scheduleFallbackSimulationIfNeeded() {
    _cancelFallbackGrace();
    _fallbackGraceTimer = Timer(const Duration(milliseconds: 450), () {
      _fallbackGraceTimer = null;
      if (!mounted) return;
      if (state.status != TtsStatus.speaking) return;
      if (_platformReportsProgress) return;
      _startSimulatedProgressTicker(despitePlatformProgress: false);
    });
  }

  void _startSimulatedProgressTicker({required bool despitePlatformProgress}) {
    if (state.status != TtsStatus.speaking) return;
    if (_platformReportsProgress && !despitePlatformProgress) return;
    _cancelProgressTicker();
    _simulatedProgressActive = true;
    final t = state.activeText;
    if (t.isEmpty) return;
    final n = t.length;
    _resyncProgressSimulation(state.progressEnd.clamp(0, n));
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => _onSimulatedProgressTick(),
    );
  }

  void _onSimulatedProgressTick() {
    if (!mounted) return;
    if (!_simulatedProgressActive) return;
    if (state.status != TtsStatus.speaking) {
      _cancelProgressTicker();
      return;
    }
    final t = state.activeText;
    final n = t.length;
    if (n == 0) return;
    final anchorTime = _progressSimAnchorTime;
    if (anchorTime == null) return;

    final elapsedSec =
        DateTime.now().difference(anchorTime).inMilliseconds / 1000.0;
    final estimated =
        (_progressSimAnchorChar + elapsedSec * _estimatedCharsPerSecond)
            .round()
            .clamp(0, n);
    final plat = state.progressEnd.clamp(0, n);
    final next = math.max(estimated, plat);

    if (next != state.progressEnd) {
      state = state.copyWith(progressEnd: next);
    }
  }

  /// Platform TTS callbacks can run while a [Consumer] is disposing; defer reset.
  void _deferResetIdle() {
    Future.microtask(() {
      if (!mounted) return;
      if (_suppressNextResets > 0) {
        _suppressNextResets--;
        return;
      }
      _cancelFallbackGrace();
      _cancelStallFiller();
      _cancelProgressTicker();
      state = const TtsState();
    });
  }

  void _onUtteranceComplete() {
    Future.microtask(() {
      if (!mounted) return;
      if (_suppressNextResets > 0) {
        _suppressNextResets--;
        return;
      }
      _cancelFallbackGrace();
      _cancelStallFiller();
      _cancelProgressTicker();
      final read = state.activeText;
      state = TtsState(
        status: TtsStatus.idle,
        lingeringReadText: read.isEmpty ? null : read,
      );
    });
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _speechRate = 0.45;
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      Future.microtask(() {
        if (!mounted) return;
        if (!state.isSpeaking) return;
        _scheduleFallbackSimulationIfNeeded();
      });
    });

    _tts.setCompletionHandler(_onUtteranceComplete);

    _tts.setCancelHandler(_deferResetIdle);

    _tts.setPauseHandler(() {
      Future.microtask(() {
        if (!mounted) return;
        if (state.status == TtsStatus.speaking) {
          state = state.copyWith(status: TtsStatus.paused);
        }
      });
    });

    _tts.setContinueHandler(() {
      Future.microtask(() {
        if (!mounted) return;
        if (state.status == TtsStatus.paused) {
          state = state.copyWith(status: TtsStatus.speaking);
        }
        if (state.isSpeaking) {
          _scheduleFallbackSimulationIfNeeded();
        }
      });
    });

    _tts.setErrorHandler((_) => _deferResetIdle());

    _tts.setProgressHandler((text, start, end, word) {
      // Word/range indices from the engine (e.g. Android API 26+ onRangeStart).
      // Smooth timer runs only as fallback when no callbacks or after long gaps (see [_scheduleStallFiller]).
      Future.microtask(() {
        if (!mounted) return;
        if (!state.isSpeaking) return;
        if (state.activeText.isEmpty) return;
        _platformReportsProgress = true;
        _lastPlatformProgressAt = DateTime.now();
        _cancelFallbackGrace();
        _cancelProgressTicker();
        final base = state.spokenTextOffset;
        final newStart = start + base;
        final newEnd = end + base;
        state = state.copyWith(
          progressStart: newStart,
          progressEnd: newEnd,
          progressWord: word,
        );
        _resyncProgressSimulation(newEnd);
        _scheduleStallFiller();
      });
    });
  }

  /// Speak [text]. If [text] is already playing, stops it instead.
  Future<void> speak(String text, {bool showMiniPlayer = true}) async {
    await speakFrom(text, 0, showMiniPlayer: showMiniPlayer);
  }

  Future<void> speakFrom(
    String fullText,
    int startIndex, {
    bool showMiniPlayer = true,
  }) async {
    final t = fullText;
    if (t.trim().isEmpty) return;

    final safeStart = startIndex.clamp(0, t.length);
    final chunk = t.substring(safeStart);
    if (chunk.trim().isEmpty) return;

    if (state.status != TtsStatus.paused &&
        state.isSpeakingText(t) &&
        state.spokenTextOffset == safeStart) {
      await stop();
      return;
    }

    // When switching between two texts, FlutterTts emits cancel/completion
    // callbacks for the previous utterance. Those callbacks can race with the
    // new `state = speaking` assignment and incorrectly reset the UI to idle.
    _suppressNextResets++;
    _platformReportsProgress = false;
    _lastPlatformProgressAt = null;
    _cancelFallbackGrace();
    _cancelStallFiller();
    _cancelProgressTicker();
    await _tts.stop();
    state = state.copyWith(
      clearLingeringReadText: true,
      status: TtsStatus.speaking,
      activeText: t,
      spokenTextOffset: safeStart,
      progressStart: safeStart,
      progressEnd: safeStart,
      progressWord: '',
      showMiniPlayer: showMiniPlayer,
    );
    await _tts.speak(chunk);
    if (mounted && state.isSpeaking && state.activeText.isNotEmpty) {
      _scheduleFallbackSimulationIfNeeded();
    }
  }

  Future<void> pause() async {
    if (state.status != TtsStatus.speaking) return;
    _cancelFallbackGrace();
    _cancelStallFiller();
    _cancelProgressTicker();
    await _tts.pause();
    if (mounted) {
      state = state.copyWith(status: TtsStatus.paused);
    }
  }

  Future<void> resume() async {
    if (state.status != TtsStatus.paused) return;
    if (state.activeText.isEmpty) return;
    _platformReportsProgress = false;
    _lastPlatformProgressAt = null;
    state = state.copyWith(status: TtsStatus.speaking);
    await _tts.speak(state.activeText);
    if (!mounted) return;
    if (!state.isSpeaking) return;
    _scheduleFallbackSimulationIfNeeded();
  }

  Future<void> stop() async {
    _suppressNextResets++;
    _platformReportsProgress = false;
    _lastPlatformProgressAt = null;
    _cancelFallbackGrace();
    _cancelStallFiller();
    _cancelProgressTicker();
    await _tts.stop();
    state = const TtsState();
  }

  @override
  void dispose() {
    _cancelFallbackGrace();
    _cancelStallFiller();
    _cancelProgressTicker();
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {});
    _tts.setCancelHandler(() {});
    _tts.setPauseHandler(() {});
    _tts.setContinueHandler(() {});
    _tts.setErrorHandler((_) {});
    unawaited(_tts.stop());
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>(
  (_) => TtsNotifier(),
);

/// Karaoke-style background highlighting for TTS (toggle from the mini player).
final ttsTextHighlightEnabledProvider = StateProvider<bool>((ref) => true);

/// Stops app TTS when a [Navigator] pops or removes a route (Back, go, replace).
///
/// [GoRouter] passes observers to the **root** navigator only; book flows live
/// under [ShellRoute]'s nested navigator, so attach one instance per navigator.
class TtsNavigatorSilencer extends NavigatorObserver {
  TtsNavigatorSilencer(this._stopTts);

  final Future<void> Function() _stopTts;

  void _fire() {
    unawaited(_stopTts());
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _fire();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _fire();
    super.didRemove(route, previousRoute);
  }
}
