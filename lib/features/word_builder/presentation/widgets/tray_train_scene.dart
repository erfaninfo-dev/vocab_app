import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/word_builder_sound_service.dart';
import '../../application/word_builder_game_notifier.dart';
import '../../application/word_builder_session_audio.dart';
import '../../application/word_builder_tray_train_audio.dart';
import '../../domain/tray_train_constants.dart';
import '../../domain/tray_train_moment.dart';
import 'tray_game_over_dialog.dart';
import 'tray_train_character_layer.dart';
import 'tray_train_painter.dart';

/// Center tray for the train-escape scenario: night rails, tied character,
/// approaching headlight, rope snaps, escape/train-pass victory and the
/// game-over collision (train hits the character and flings them out of
/// the tray). Same footprint as [TrayWaterScene].
class TrayTrainScene extends ConsumerStatefulWidget {
  const TrayTrainScene({
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
  ConsumerState<TrayTrainScene> createState() => _TrayTrainSceneState();
}

class _TrayTrainSceneState extends ConsumerState<TrayTrainScene>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _struggle;
  late final AnimationController _tensionTween;
  late final AnimationController _headlightPulse;
  late final AnimationController _ropeSnap;
  late final AnimationController _escape;
  late final AnimationController _trainPass;
  late final AnimationController _shake;
  late final AnimationController _gameOverRush;
  late final AnimationController _fling;

  double _fromTension = 0;
  double _toTension = 0;
  bool _wasWrongHighlight = false;
  TrayTrainMoment _lastMoment = TrayTrainMoment.none;
  bool _victoryDone = false;
  bool _gameOverStarted = false;
  bool _impactHappened = false;
  bool _gameOverModalShown = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _struggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _tensionTween = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headlightPulse = AnimationController(
      vsync: this,
      duration: TrayTrainConstants.headlightPulseDuration,
    );
    _ropeSnap = AnimationController(
      vsync: this,
      duration: TrayTrainConstants.ropeSnapDuration,
    );
    _escape = AnimationController(
      vsync: this,
      duration: TrayTrainConstants.escapeDuration,
    );
    _trainPass = AnimationController(
      vsync: this,
      duration: TrayTrainConstants.trainPassDuration,
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _gameOverRush = AnimationController(
      vsync: this,
      duration: TrayTrainConstants.gameOverRushDuration,
    );
    _gameOverRush.addListener(_onRushTick);
    _fling = AnimationController(
      vsync: this,
      duration: TrayTrainConstants.gameOverFlingDuration,
    );
    _fling.addStatusListener(_onFlingStatus);

    final initial =
        ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (initial != null) {
      _toTension = initial.trayWaterLevel.clamp(0.0, 1.0);
      _fromTension = _toTension;
      _victoryDone = initial.levelComplete && !initial.trainVictoryActive;
      if (_victoryDone) {
        _escape.value = 1;
        _trainPass.value = 1;
      }
      if (initial.isTrayGameOver) {
        _startGameOverSequence();
      }
    }
  }

  /// Start the fling the moment the train nose reaches the character.
  void _onRushTick() {
    if (!_gameOverStarted || _impactHappened) return;
    if (_gameOverRush.value < TrayTrainConstants.gameOverImpactFraction) {
      return;
    }
    _impactHappened = true;
    unawaited(_fling.forward(from: 0));
    // Hard impact shake.
    unawaited(_shake.forward(from: 0));
  }

  void _onFlingStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _gameOverModalShown) return;
    Future<void>.delayed(TrayTrainConstants.gameOverModalDelay, () {
      if (!mounted || _gameOverModalShown) return;
      _presentGameOverModal();
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _struggle.dispose();
    _tensionTween.dispose();
    _headlightPulse.dispose();
    _ropeSnap.dispose();
    _escape.dispose();
    _trainPass.dispose();
    _shake.dispose();
    _gameOverRush.removeListener(_onRushTick);
    _gameOverRush.dispose();
    _fling.removeStatusListener(_onFlingStatus);
    _fling.dispose();
    super.dispose();
  }

  void _playGameOverSounds() {
    final traySfx = ref.read(wordBuilderGameWaterSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderTrayTrainAudioProvider(widget.bookKey))
          .onGameOverBrake(enabled: traySfx),
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
    _impactHappened = false;
    _fromTension = 1.0;
    _toTension = 1.0;
    _gameOverRush
      ..stop()
      ..reset();
    _fling
      ..stop()
      ..reset();
    _playGameOverSounds();
    unawaited(_gameOverRush.forward());
  }

  void _resetGameOverSequence() {
    _gameOverStarted = false;
    _impactHappened = false;
    _gameOverModalShown = false;
    _gameOverRush
      ..stop()
      ..reset();
    _fling
      ..stop()
      ..reset();
  }

  Future<void> _presentGameOverModal() async {
    if (_gameOverModalShown || !mounted) return;
    _gameOverModalShown = true;
    await TrayGameOverDialog.show(context, bookKey: widget.bookKey);
    if (mounted) _gameOverModalShown = false;
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
          // Passive drip: glide slowly so the train creeps closer
          // continuously (like the tub filling); jumps stay snappy.
          ..duration = delta < TrayTrainConstants.smallTensionDelta
              ? TrayTrainConstants.tensionTweenCreep
              : TrayTrainConstants.tensionTweenFast;
        unawaited(_tensionTween.forward());
      }
    }

    if (s.pathWrongHighlight && !_wasWrongHighlight && !s.isTrayGameOver) {
      _headlightPulse
        ..stop()
        ..reset();
      unawaited(_headlightPulse.forward());
      _shake
        ..stop()
        ..reset();
      unawaited(_shake.forward());
    }
    _wasWrongHighlight = s.pathWrongHighlight;

    if (s.trainMoment != _lastMoment) {
      switch (s.trainMoment) {
        case TrayTrainMoment.ropeBreak:
          _ropeSnap
            ..stop()
            ..reset();
          unawaited(_ropeSnap.forward());
        case TrayTrainMoment.escape:
          _ropeSnap
            ..stop()
            ..reset();
          unawaited(_ropeSnap.forward());
          _escape
            ..stop()
            ..reset();
          unawaited(_escape.forward());
        case TrayTrainMoment.trainPass:
          if (_escape.value < 1) _escape.value = 1;
          _trainPass
            ..stop()
            ..reset();
          unawaited(_trainPass.forward());
          unawaited(_shake.forward(from: 0));
        case TrayTrainMoment.none:
          break;
      }
      _lastMoment = s.trainMoment;
    }

    final victoryDoneNow = s.levelComplete && !s.trainVictoryActive;
    if (victoryDoneNow && !_victoryDone) {
      _escape.value = 1;
      _trainPass.value = 1;
    }
    if (!s.levelComplete && _victoryDone) {
      _escape.value = 0;
      _trainPass.value = 0;
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

  /// One rope segment per solved word (levels have 3 target words and the
  /// character has 3 ropes); the last one snaps during the escape.
  int _brokenRopes(WordBuilderViewState s) {
    if (s.levelComplete) return TrayTrainConstants.ropeCount;
    return s.solvedCount.clamp(0, TrayTrainConstants.ropeCount);
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
    final escaped = s.levelComplete || s.trainVictoryActive;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _ambient,
          _struggle,
          _tensionTween,
          _headlightPulse,
          _ropeSnap,
          _escape,
          _trainPass,
          _shake,
          _gameOverRush,
          _fling,
        ]),
        builder: (context, _) {
          final tension = _currentTension;
          final pulse = Curves.elasticOut.transform(1 - _headlightPulse.value);

          final shakeT = _shake.value;
          // Strongest shake at the collision impact.
          final shakeStrength = isGameOver
              ? (_impactHappened ? 2.2 : 1.2)
              : (0.5 + tension) *
                  (s.trainMoment == TrayTrainMoment.trainPass ? 1.4 : 1.0);
          final dx = shakeT > 0 && shakeT < 1
              ? math.sin(shakeT * math.pi * 6) * 7 * (1 - shakeT) * shakeStrength
              : 0.0;

          final fear = isGameOver
              ? 1.0
              : escaped
                  ? 0.0
                  : (tension * 0.85 + pulse * 0.15).clamp(0.0, 1.0);

          final flingT = _impactHappened ? _fling.value : 0.0;
          // Dust burst right after impact; character fades near the end
          // of the arc so nothing lingers outside the tray.
          final impactBurst = _impactHappened
              ? (flingT / 0.35).clamp(0.0, 1.0)
              : 0.0;
          final characterOpacity = flingT > 0.75
              ? (1.0 - (flingT - 0.75) / 0.25).clamp(0.0, 1.0)
              : 1.0;

          return Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: widget.size,
                  painter: TrayTrainPainter(
                    size: widget.size,
                    center: widget.center,
                    sceneRadius: widget.sceneRadius,
                    saucerRadius: widget.saucerRadius,
                    tension: isGameOver ? 1.0 : tension,
                    ambientPhase: _ambient.value,
                    headlightPulse: isGameOver ? 0.0 : pulse,
                    trainPassProgress:
                        !isGameOver &&
                                (s.trainMoment == TrayTrainMoment.trainPass ||
                                    (escaped && _trainPass.value > 0))
                            ? _trainPass.value
                            : 0.0,
                    gameOverRushProgress:
                        _gameOverStarted ? _gameOverRush.value : 0.0,
                    impactBurst: impactBurst,
                    isGameOver: isGameOver,
                  ),
                ),
                Opacity(
                  opacity: characterOpacity,
                  child: CustomPaint(
                    size: widget.size,
                    painter: TrayTrainCharacterPainter(
                      center: widget.center,
                      sceneRadius: widget.sceneRadius,
                      characterRadius: widget.characterRadius * 0.72,
                      brokenRopes: _brokenRopes(s),
                      totalRopes: TrayTrainConstants.ropeCount,
                      strugglePhase: _struggle.value,
                      ropeSnapProgress:
                          _ropeSnap.isAnimating ? _ropeSnap.value : 0.0,
                      escapeProgress: escaped ? _escape.value : 0.0,
                      fear: fear,
                      celebrate: escaped && _escape.value >= 1,
                      flingProgress: flingT,
                    ),
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
