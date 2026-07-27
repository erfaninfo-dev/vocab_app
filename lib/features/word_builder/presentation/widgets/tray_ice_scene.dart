import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/word_builder_sound_service.dart';
import '../../application/word_builder_game_notifier.dart';
import '../../application/word_builder_session_audio.dart';
import '../../application/word_builder_tray_ice_audio.dart';
import '../../domain/tray_ice_constants.dart';
import '../../domain/tray_ice_moment.dart';
import 'tray_game_over_dialog.dart';
import 'tray_ice_figures_layer.dart';
import 'tray_ice_painter.dart';

/// Center tray for Ice Rescue: man trapped in glowing ice, toy scope rifle,
/// one crack per correct word, final shatter + free celebrate, and a
/// family-friendly frost lock on game over.
class TrayIceScene extends ConsumerStatefulWidget {
  const TrayIceScene({
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
  ConsumerState<TrayIceScene> createState() => _TrayIceSceneState();
}

class _TrayIceSceneState extends ConsumerState<TrayIceScene>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _idle;
  late final AnimationController _tensionTween;
  late final AnimationController _shot;
  late final AnimationController _wrongPulse;
  late final AnimationController _rescue;
  late final AnimationController _shake;
  late final AnimationController _gameOver;

  double _fromTension = 0;
  double _toTension = 0;
  bool _wasWrongHighlight = false;
  TrayIceMoment _lastMoment = TrayIceMoment.none;
  bool _victoryDone = false;
  bool _gameOverStarted = false;
  bool _gameOverModalShown = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _tensionTween = AnimationController(
      vsync: this,
      duration: TrayIceConstants.tensionTweenFast,
    );
    _shot = AnimationController(
      vsync: this,
      duration: TrayIceConstants.shotDuration,
    );
    _wrongPulse = AnimationController(
      vsync: this,
      duration: TrayIceConstants.wrongPulseDuration,
    );
    _rescue = AnimationController(
      vsync: this,
      duration: TrayIceConstants.rescueDuration,
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _gameOver = AnimationController(
      vsync: this,
      duration: TrayIceConstants.gameOverFreezeDuration,
    );
    _gameOver.addStatusListener(_onGameOverStatus);

    final initial =
        ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (initial != null) {
      _toTension = initial.trayWaterLevel.clamp(0.0, 1.0);
      _fromTension = _toTension;
      _victoryDone = initial.levelComplete && !initial.iceVictoryActive;
      if (_victoryDone) _rescue.value = 1;
      if (initial.isTrayGameOver) _startGameOverSequence();
    }
  }

  void _onGameOverStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _gameOverModalShown) return;
    Future<void>.delayed(TrayIceConstants.gameOverModalDelay, () {
      if (!mounted || _gameOverModalShown) return;
      _presentGameOverModal();
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _idle.dispose();
    _tensionTween.dispose();
    _shot.dispose();
    _wrongPulse.dispose();
    _rescue.dispose();
    _shake.dispose();
    _gameOver.removeStatusListener(_onGameOverStatus);
    _gameOver.dispose();
    super.dispose();
  }

  void _playGameOverSounds() {
    final traySfx = ref.read(wordBuilderGameWaterSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderTrayIceAudioProvider(widget.bookKey))
          .onGameOverFreeze(enabled: traySfx),
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
    _fromTension = 1;
    _toTension = 1;
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

  Future<void> _runRescueAnimation() async {
    _rescue
      ..stop()
      ..reset();
    final traySfx = ref.read(wordBuilderGameWaterSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderTrayIceAudioProvider(widget.bookKey))
          .onShot(enabled: traySfx),
    );
    await _rescue.forward();
    if (!mounted) return;
    unawaited(
      ref
          .read(wordBuilderTrayIceAudioProvider(widget.bookKey))
          .onShatter(enabled: traySfx),
    );
  }

  void _applyGameState(WordBuilderViewState s) {
    if (!s.isTrayGameOver && _gameOverStarted) _resetGameOverSequence();
    if (s.isTrayGameOver && !_gameOverStarted) _startGameOverSequence();

    if (!s.isTrayGameOver) {
      final target = s.trayWaterLevel.clamp(0.0, 1.0);
      final delta = (target - _toTension).abs();
      if (delta > 0.001) {
        _fromTension = _currentTension;
        _toTension = target;
        _tensionTween
          ..stop()
          ..reset()
          ..duration = delta < TrayIceConstants.smallTensionDelta
              ? TrayIceConstants.tensionTweenCreep
              : TrayIceConstants.tensionTweenFast;
        unawaited(_tensionTween.forward());
      }
    }

    if (s.pathWrongHighlight && !_wasWrongHighlight && !s.isTrayGameOver) {
      _wrongPulse
        ..stop()
        ..reset();
      unawaited(_wrongPulse.forward());
      _shake
        ..stop()
        ..reset();
      unawaited(_shake.forward());
    }
    _wasWrongHighlight = s.pathWrongHighlight;

    if (s.iceMoment != _lastMoment) {
      if (s.iceMoment == TrayIceMoment.shot) {
        _shot
          ..stop()
          ..reset();
        unawaited(_shot.forward());
        final traySfx = ref.read(wordBuilderGameWaterSfxEnabledProvider);
        unawaited(
          ref
              .read(wordBuilderTrayIceAudioProvider(widget.bookKey))
              .onShot(enabled: traySfx),
        );
      } else if (s.iceMoment == TrayIceMoment.rescue) {
        unawaited(_runRescueAnimation());
      }
      _lastMoment = s.iceMoment;
    }

    final victoryDoneNow = s.levelComplete && !s.iceVictoryActive;
    if (victoryDoneNow && !_victoryDone) _rescue.value = 1;
    if (!s.levelComplete && _victoryDone) _rescue.value = 0;
    _victoryDone = victoryDoneNow;
  }

  double get _currentTension {
    if (_gameOverStarted) return 1;
    if (_tensionTween.value >= 1 || !_tensionTween.isAnimating) {
      return _toTension;
    }
    final t = Curves.easeInOut.transform(_tensionTween.value);
    return _fromTension + (_toTension - _fromTension) * t;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(wordBuilderGameProvider(widget.bookKey), (prev, next) {
      final s = next.valueOrNull;
      if (s != null) _applyGameState(s);
    });

    final async = ref.watch(wordBuilderGameProvider(widget.bookKey));
    final s = async.valueOrNull;
    if (s == null) return const SizedBox.shrink();

    final isGameOver = s.isTrayGameOver;
    final escaping = s.iceVictoryActive ||
        (s.levelComplete && _rescue.value > 0);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _ambient,
          _idle,
          _tensionTween,
          _shot,
          _wrongPulse,
          _rescue,
          _shake,
          _gameOver,
        ]),
        builder: (context, _) {
          final tension = _currentTension;
          final pulse = _wrongPulse.isAnimating || _wrongPulse.value > 0
              ? Curves.elasticOut.transform(1 - _wrongPulse.value)
              : 0.0;

          final shakeT = _shake.value;
          final dx = shakeT > 0 && shakeT < 1
              ? math.sin(shakeT * math.pi * 7) *
                  5 *
                  (1 - shakeT) *
                  (isGameOver ? 1.4 : 0.7 + tension)
              : 0.0;

          final targets = s.level.targetCount;
          final crack = targets <= 0
              ? 0.0
              : (escaping
                    ? 1.0
                    : (s.solvedCount / targets).clamp(0.0, 1.0));

          final celebrate =
              escaping && _rescue.value >= TrayIceConstants.victoryFreeEnd;

          final layout = TrayIceLayout(
            center: widget.center,
            sceneRadius: widget.sceneRadius,
          );

          return Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: widget.size,
                  painter: TrayIcePainter(
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
                  painter: TrayIceFiguresLayer(
                    layout: layout,
                    crackProgress: crack,
                    tension: isGameOver ? 1.0 : tension,
                    ambientPhase: _ambient.value,
                    idlePhase: _idle.value,
                    shotProgress: escaping &&
                            _rescue.value < TrayIceConstants.victoryShotEnd
                        ? (_rescue.value / TrayIceConstants.victoryShotEnd)
                            .clamp(0.0, 1.0)
                        : (_shot.isAnimating || _shot.value > 0
                            ? _shot.value
                            : 0.0),
                    wrongPulse: isGameOver ? 0.0 : pulse,
                    rescueProgress: escaping ? _rescue.value : 0.0,
                    gameOverProgress:
                        _gameOverStarted ? _gameOver.value : 0.0,
                    celebrate: celebrate,
                    isGameOver: isGameOver,
                    scopeShake: pulse,
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
