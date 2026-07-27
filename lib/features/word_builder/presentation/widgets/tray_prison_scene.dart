import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/word_builder_sound_service.dart';
import '../../application/word_builder_game_notifier.dart';
import '../../application/word_builder_session_audio.dart';
import '../../application/word_builder_tray_prison_audio.dart';
import '../../domain/tray_prison_constants.dart';
import '../../domain/tray_prison_moment.dart';
import 'tray_game_over_dialog.dart';
import 'tray_prison_figures_layer.dart';
import 'tray_prison_painter.dart';

/// Center tray for the prison-escape scenario: barred cell, sleeping guard,
/// swinging key, reaching prisoner arm, victory tiptoe escape and the
/// family-friendly game-over wake sequence. Same footprint as [TrayWaterScene]
/// / [TrayTrainScene] — letter ring and gameplay stay untouched.
class TrayPrisonScene extends ConsumerStatefulWidget {
  const TrayPrisonScene({
    super.key,
    required this.bookKey,
    required this.size,
    required this.center,
    required this.sceneRadius,
    required this.saucerRadius,
    required this.characterRadius,
  });

  final int bookKey;
  final Size size;
  final Offset center;
  final double sceneRadius;
  final double saucerRadius;
  final double characterRadius;

  @override
  ConsumerState<TrayPrisonScene> createState() => _TrayPrisonSceneState();
}

class _TrayPrisonSceneState extends ConsumerState<TrayPrisonScene>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _idle;
  late final AnimationController _tensionTween;
  late final AnimationController _reachTween;
  late final AnimationController _wakePulse;
  late final AnimationController _keyGrab;
  late final AnimationController _escape;
  late final AnimationController _shake;
  late final AnimationController _gameOver;

  double _fromTension = 0;
  double _toTension = 0;
  double _fromReach = 0;
  double _toReach = 0;
  bool _wasWrongHighlight = false;
  TrayPrisonMoment _lastMoment = TrayPrisonMoment.none;
  bool _victoryDone = false;
  bool _gameOverStarted = false;
  bool _gameOverModalShown = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    // Slower idle = calmer breath / blink; stir still comes from wakePulse.
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _tensionTween = AnimationController(
      vsync: this,
      duration: TrayPrisonConstants.tensionTweenFast,
    );
    _reachTween = AnimationController(
      vsync: this,
      duration: TrayPrisonConstants.reachTweenDuration,
    );
    _wakePulse = AnimationController(
      vsync: this,
      duration: TrayPrisonConstants.guardPulseDuration,
    );
    _keyGrab = AnimationController(
      vsync: this,
      duration: TrayPrisonConstants.keyGrabDuration,
    );
    _escape = AnimationController(
      vsync: this,
      duration: TrayPrisonConstants.escapeDuration,
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _gameOver = AnimationController(
      vsync: this,
      duration: TrayPrisonConstants.gameOverGrabDuration,
    );
    _gameOver.addStatusListener(_onGameOverStatus);

    final initial =
        ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (initial != null) {
      _toTension = initial.trayWaterLevel.clamp(0.0, 1.0);
      _fromTension = _toTension;
      _toReach = _reachForState(initial);
      _fromReach = _toReach;
      _victoryDone = initial.levelComplete && !initial.prisonVictoryActive;
      if (_victoryDone) {
        _keyGrab.value = 1;
        _escape.value = 1;
      }
      if (initial.isTrayGameOver) {
        _startGameOverSequence();
      }
    }
  }

  void _onGameOverStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _gameOverModalShown) return;
    Future<void>.delayed(TrayPrisonConstants.gameOverModalDelay, () {
      if (!mounted || _gameOverModalShown) return;
      _presentGameOverModal();
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _idle.dispose();
    _tensionTween.dispose();
    _reachTween.dispose();
    _wakePulse.dispose();
    _keyGrab.dispose();
    _escape.dispose();
    _shake.dispose();
    _gameOver.removeStatusListener(_onGameOverStatus);
    _gameOver.dispose();
    super.dispose();
  }

  double _reachForState(WordBuilderViewState s) {
    if (s.levelComplete || s.prisonVictoryActive) return 1.0;
    final targets = s.level.targetCount;
    if (targets <= 0) return 0.0;
    return (s.solvedCount / targets).clamp(0.0, 1.0) *
        TrayPrisonConstants.maxReachBeforeComplete;
  }

  void _playGameOverSounds() {
    final traySfx = ref.read(wordBuilderGameWaterSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderTrayPrisonAudioProvider(widget.bookKey))
          .onGameOverWake(enabled: traySfx),
    );
    final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderSoundServiceProvider)
          .play(WordBuilderSound.gameOver, enabled: sfx),
    );
  }

  void _startGameOverSequence() {
    if (_gameOverStarted) return;
    _gameOverStarted = true;
    _fromTension = 1.0;
    _toTension = 1.0;
    _gameOver
      ..stop()
      ..reset();
    _playGameOverSounds();
    unawaited(_gameOver.forward());
    unawaited(_shake.forward(from: 0));
  }

  void _resetGameOverSequence() {
    _gameOverStarted = false;
    _gameOverModalShown = false;
    _gameOver
      ..stop()
      ..reset();
  }

  Future<void> _presentGameOverModal() async {
    if (_gameOverModalShown || !mounted) return;
    _gameOverModalShown = true;
    await TrayGameOverDialog.show(context, bookKey: widget.bookKey);
    if (mounted) _gameOverModalShown = false;
  }

  Future<void> _runVictoryAnimations() async {
    _keyGrab
      ..stop()
      ..reset();
    await _keyGrab.forward();
    if (!mounted) return;
    final cur = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (cur == null || cur.prisonMoment != TrayPrisonMoment.escape) return;
    _escape
      ..stop()
      ..reset();
    await _escape.forward();
  }

  void _applyGameState(WordBuilderViewState s) {
    if (!s.isTrayGameOver && _gameOverStarted) {
      _resetGameOverSequence();
    }
    if (s.isTrayGameOver && !_gameOverStarted) {
      _startGameOverSequence();
    }

    if (!s.isTrayGameOver) {
      final target = s.trayWaterLevel.clamp(0.0, 1.0);
      final delta = (target - _toTension).abs();
      if (delta > 0.001) {
        _fromTension = _currentTension;
        _toTension = target;
        _tensionTween
          ..stop()
          ..reset()
          ..duration = delta < TrayPrisonConstants.smallTensionDelta
              ? TrayPrisonConstants.tensionTweenCreep
              : TrayPrisonConstants.tensionTweenFast;
        unawaited(_tensionTween.forward());
      }
    }

    final nextReach = _reachForState(s);
    if ((nextReach - _toReach).abs() > 0.001) {
      _fromReach = _currentReach;
      _toReach = nextReach;
      _reachTween
        ..stop()
        ..reset();
      unawaited(_reachTween.forward());
    }

    if (s.pathWrongHighlight && !_wasWrongHighlight && !s.isTrayGameOver) {
      _wakePulse
        ..stop()
        ..reset();
      unawaited(_wakePulse.forward());
      _shake
        ..stop()
        ..reset();
      unawaited(_shake.forward());
    }
    _wasWrongHighlight = s.pathWrongHighlight;

    if (s.prisonMoment != _lastMoment) {
      if (s.prisonMoment == TrayPrisonMoment.escape) {
        unawaited(_runVictoryAnimations());
      }
      _lastMoment = s.prisonMoment;
    }

    final victoryDoneNow = s.levelComplete && !s.prisonVictoryActive;
    if (victoryDoneNow && !_victoryDone) {
      _keyGrab.value = 1;
      _escape.value = 1;
    }
    if (!s.levelComplete && _victoryDone) {
      _keyGrab.value = 0;
      _escape.value = 0;
    }
    _victoryDone = victoryDoneNow;
  }

  double get _currentTension {
    if (_gameOverStarted) return 1.0;
    if (_tensionTween.value >= 1 || !_tensionTween.isAnimating) {
      return _toTension;
    }
    final t = Curves.easeInOut.transform(_tensionTween.value);
    return _fromTension + (_toTension - _fromTension) * t;
  }

  double get _currentReach {
    if (_reachTween.value >= 1 || !_reachTween.isAnimating) {
      return _toReach;
    }
    final t = Curves.easeOutCubic.transform(_reachTween.value);
    return _fromReach + (_toReach - _fromReach) * t;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      wordBuilderGameProvider(widget.bookKey),
      (prev, next) {
        final s = next.valueOrNull;
        if (s != null) _applyGameState(s);
      },
    );

    final async = ref.watch(wordBuilderGameProvider(widget.bookKey));
    final s = async.valueOrNull;
    if (s == null) return const SizedBox.shrink();

    final isGameOver = s.isTrayGameOver;
    final escaping = s.prisonVictoryActive ||
        (s.levelComplete && (_escape.value > 0 || _keyGrab.value > 0));

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _ambient,
          _idle,
          _tensionTween,
          _reachTween,
          _wakePulse,
          _keyGrab,
          _escape,
          _shake,
          _gameOver,
        ]),
        builder: (context, _) {
          final tension = _currentTension;
          // Sharp stir that settles — readable on every wrong answer.
          final pulse = _wakePulse.isAnimating || _wakePulse.value > 0
              ? Curves.elasticOut.transform(1 - _wakePulse.value)
              : 0.0;

          final shakeT = _shake.value;
          final shakeStrength = isGameOver
              ? 1.7
              : (0.5 + tension) * (escaping ? 0.55 : 1.0);
          final dx = shakeT > 0 && shakeT < 1
              ? math.sin(shakeT * math.pi * 7) *
                  7 *
                  (1 - shakeT) *
                  shakeStrength
              : 0.0;

          final fear = isGameOver
              ? 1.0
              : escaping
                  ? 0.0
                  : (tension * 0.82 + pulse * 0.22).clamp(0.0, 1.0);

          final celebrate =
              escaping && _escape.value >= 0.5 && !isGameOver;

          // Pass raw linear 0..1 — stage curves live in the figures painter.
          final keyGrab = escaping
              ? (_keyGrab.value < 1 ? _keyGrab.value : 1.0)
              : 0.0;
          final escapeProgress = escaping && _keyGrab.value >= 1
              ? _escape.value
              : (_victoryDone ? 1.0 : 0.0);
          final gameOverProgress =
              _gameOverStarted ? _gameOver.value : 0.0;

          return Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: widget.size,
                  painter: TrayPrisonPainter(
                    size: widget.size,
                    center: widget.center,
                    sceneRadius: widget.sceneRadius,
                    saucerRadius: widget.saucerRadius,
                    ambientPhase: _ambient.value,
                    tension: isGameOver ? 1.0 : tension,
                    isGameOver: isGameOver,
                  ),
                ),
                CustomPaint(
                  size: widget.size,
                  painter: TrayPrisonFiguresPainter(
                    center: widget.center,
                    sceneRadius: widget.sceneRadius,
                    idlePhase: _idle.value,
                    ambientPhase: _ambient.value,
                    reachProgress: isGameOver
                        ? _currentReach
                        : (escaping ? 1.0 : _currentReach),
                    guardWake: isGameOver ? 1.0 : tension,
                    wakePulse: isGameOver ? 0.0 : pulse,
                    keyGrabProgress: keyGrab,
                    escapeProgress: escapeProgress,
                    gameOverProgress: gameOverProgress,
                    fear: fear,
                    celebrate: celebrate,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
