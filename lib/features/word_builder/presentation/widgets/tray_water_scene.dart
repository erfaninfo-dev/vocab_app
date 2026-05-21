import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audio/word_builder_sound_service.dart';
import '../../application/word_builder_game_notifier.dart';
import '../../application/word_builder_session_audio.dart';
import '../../application/word_builder_tray_water_audio.dart';
import '../../domain/tray_water_constants.dart';
import 'tray_center_face_painter.dart';
import 'tray_game_over_dialog.dart';
import 'tray_water_painter.dart';

/// Center tray: glass tub, pipes, water, face reactions, game-over sequence.
class TrayWaterScene extends ConsumerStatefulWidget {
  const TrayWaterScene({
    super.key,
    required this.bookKey,
    required this.size,
    required this.center,
    required this.tubRadius,
    required this.saucerRadius,
    required this.faceRadius,
  });

  final int bookKey;
  final Size size;
  final Offset center;
  final double tubRadius;
  final double saucerRadius;
  final double faceRadius;

  @override
  ConsumerState<TrayWaterScene> createState() => _TrayWaterSceneState();
}

class _TrayWaterSceneState extends ConsumerState<TrayWaterScene>
    with TickerProviderStateMixin {
  late final AnimationController _waves;
  late final AnimationController _inletValve;
  late final AnimationController _outletValve;
  late final AnimationController _waterTween;
  late final AnimationController _reactionPulse;
  late final AnimationController _gameOverFill;
  late final AnimationController _gameOverFlip;
  late final AnimationController _passiveDrip;
  late final AnimationController _inletPipeFlow;

  double _fromWater = 0;
  double _toWater = 0;
  TrayFaceMood? _lastMood;
  bool _gameOverStarted = false;
  bool _gameOverModalShown = false;

  @override
  void initState() {
    super.initState();
    _waves = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _inletValve = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _outletValve = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _waterTween = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _reactionPulse = AnimationController(
      vsync: this,
      duration: TrayWaterConstants.reactionPulseDuration,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _gameOverFill = AnimationController(
      vsync: this,
      duration: TrayWaterConstants.gameOverFillDuration,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _gameOverFlip = AnimationController(
      vsync: this,
      duration: TrayWaterConstants.gameOverFlipDuration,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _gameOverFlip.addStatusListener(_onFlipStatus);
    _passiveDrip = AnimationController(
      vsync: this,
      duration: TrayWaterConstants.passiveDripCycleDuration,
    )..repeat();
    _inletPipeFlow = AnimationController(
      vsync: this,
      duration: TrayWaterConstants.inletPipeFlowCycleDuration,
    )..repeat();

    final initial =
        ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (initial != null) {
      _toWater = initial.trayWaterLevel.clamp(0.0, 1.0);
      _fromWater = _toWater;
      if (initial.isTrayGameOver) {
        _startGameOverSequence(fromLevel: _toWater);
      }
    }
  }

  void _onFlipStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _gameOverModalShown) return;
    Future<void>.delayed(TrayWaterConstants.gameOverModalDelay, () {
      if (!mounted || _gameOverModalShown) return;
      _presentGameOverModal();
    });
  }

  @override
  void dispose() {
    _waves.dispose();
    _inletValve.dispose();
    _outletValve.dispose();
    _waterTween.dispose();
    _reactionPulse.dispose();
    _gameOverFill.dispose();
    _gameOverFlip.removeStatusListener(_onFlipStatus);
    _gameOverFlip.dispose();
    _passiveDrip.dispose();
    _inletPipeFlow.dispose();
    super.dispose();
  }

  void _triggerReaction(TrayFaceMood mood) {
    if (mood == TrayFaceMood.neutral || mood == TrayFaceMood.dead) return;
    _reactionPulse
      ..stop()
      ..reset();
    unawaited(_reactionPulse.forward());
  }

  void _playGameOverFailureSound() {
    unawaited(
      ref.read(wordBuilderTrayWaterAudioProvider(widget.bookKey)).stopAll(),
    );
    final enabled = ref.read(wordBuilderGameSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderSoundServiceProvider)
          .play(WordBuilderSound.gameOver, enabled: enabled),
    );
  }

  void _startGameOverSequence({required double fromLevel}) {
    if (_gameOverStarted) return;
    _gameOverStarted = true;
    _fromWater = fromLevel.clamp(0.0, 1.0);
    _toWater = 1.0;
    _gameOverFill
      ..stop()
      ..reset();
    _gameOverFlip
      ..stop()
      ..reset();
    _playGameOverFailureSound();
    unawaited(_gameOverFill.forward());
    unawaited(_gameOverFlip.forward());
  }

  void _resetGameOverSequence() {
    _gameOverStarted = false;
    _gameOverModalShown = false;
    _gameOverFill
      ..stop()
      ..reset();
    _gameOverFlip
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
      _startGameOverSequence(fromLevel: _currentWater);
    }

    if (_lastMood != s.faceMood) {
      _triggerReaction(s.faceMood);
      _lastMood = s.faceMood;
    }
    if (!s.isTrayGameOver) {
      final target = s.trayWaterLevel.clamp(0.0, 1.0);
      if ((target - _toWater).abs() > 0.001) {
        _fromWater = _currentWater;
        _toWater = target;
        _waterTween
          ..stop()
          ..reset();
        unawaited(_waterTween.forward());
      }
    }
    if (s.isInletValveOpen) {
      unawaited(_inletValve.forward());
    } else {
      unawaited(_inletValve.reverse());
    }
    if (s.isOutletValveOpen) {
      unawaited(_outletValve.forward());
    } else {
      unawaited(_outletValve.reverse());
    }
  }

  double get _currentWater {
    if (_gameOverStarted) {
      final t = Curves.easeInOut.transform(_gameOverFill.value);
      return _fromWater + (1.0 - _fromWater) * t;
    }
    if (_waterTween.value >= 1 || !_waterTween.isAnimating) {
      return _toWater;
    }
    final t = Curves.easeInOut.transform(_waterTween.value);
    return _fromWater + (_toWater - _fromWater) * t;
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

    final scheme = Theme.of(context).colorScheme;
    final water = _currentWater;
    final isGameOver = s.isTrayGameOver;
    final liveInletDrip = !isGameOver &&
        !s.isOutletValveOpen &&
        !s.levelComplete &&
        !s.pathWrongHighlight;
    final passiveInletVisual =
        liveInletDrip ? TrayWaterConstants.passiveInletVisualOpen : 0.0;
    final inletOpenVisual = isGameOver
        ? 0.0
        : math.max(_inletValve.value, passiveInletVisual);
    final mood = s.faceMood;
    final pulse = Curves.elasticOut.transform(1 - _reactionPulse.value);

    final flipAngle = isGameOver ? _gameOverFlip.value * math.pi : 0.0;

    final faceCenter = isGameOver
        ? widget.center
        : widget.center +
            Offset(
              0,
              -water * widget.faceRadius * 0.28 +
                  (mood == TrayFaceMood.happy
                      ? -pulse * widget.faceRadius * 0.14
                      : mood == TrayFaceMood.stressed
                          ? pulse * widget.faceRadius * 0.06
                          : 0),
            );

    final faceR = isGameOver
        ? widget.faceRadius
        : widget.faceRadius *
            switch (mood) {
              TrayFaceMood.happy => 1.0 + pulse * 0.14,
              TrayFaceMood.stressed => 1.0 - pulse * 0.06,
              TrayFaceMood.panic => 1.0 + pulse * 0.08,
              TrayFaceMood.dead => 1.0,
              _ => 1.0,
            };

    final waterSurfaceY = TrayWaterPainter.waterSurfaceScreenY(
      tubCenter: widget.center,
      tubRadius: widget.tubRadius,
      waterLevel: isGameOver ? 1.0 : water,
    );

    final faceLayer = TrayCenterFaceLayer(
      size: widget.size,
      center: faceCenter,
      radius: faceR,
      mood: mood,
      waterSubmerge: isGameOver ? 1.0 : water,
      waterSurfaceY: waterSurfaceY,
      reactionPulse: isGameOver ? 0 : pulse,
      wrongAnswerCount: s.wrongAnswerCount,
      solvedInLevel: s.solvedCount,
      targetsInLevel: s.level.targetCount,
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _waves,
            _inletValve,
            _outletValve,
            _waterTween,
            _reactionPulse,
            _gameOverFill,
            _gameOverFlip,
            _passiveDrip,
            _inletPipeFlow,
          ]),
          builder: (context, _) {
            return CustomPaint(
              size: widget.size,
              painter: TrayWaterPainter(
                size: widget.size,
                center: widget.center,
                tubRadius: widget.tubRadius,
                saucerRadius: widget.saucerRadius,
                waterLevel: water,
                wavePhase: _waves.value * math.pi * 2,
                inletPipeFlowPhase: _inletPipeFlow.value,
                inletValveOpen: inletOpenVisual,
                outletValveOpen: isGameOver ? 0 : _outletValve.value,
                liveInletDrip: liveInletDrip,
                inletDripPhase: _passiveDrip.value,
                waterAgitation: isGameOver
                    ? 0.15
                    : math.max(
                        inletOpenVisual * (0.85 + pulse * 0.4),
                        _outletValve.value * 0.55,
                      ),
                scheme: scheme,
              ),
            );
          },
        ),
        if (isGameOver)
          Transform.rotate(
            angle: flipAngle,
            origin: widget.center,
            child: faceLayer,
          )
        else
          faceLayer,
      ],
    );
  }
}
