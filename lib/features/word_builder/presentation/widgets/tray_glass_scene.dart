import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/word_builder_sound_service.dart';
import '../../application/word_builder_game_notifier.dart';
import '../../application/word_builder_session_audio.dart';
import '../../application/word_builder_tray_visual_mode_provider.dart';
import '../../domain/glass_crack_path_generator.dart';
import '../../domain/tray_glass_constants.dart';
import 'tray_glass_game_over_dialog.dart';
import 'tray_glass_painter.dart';
import 'tray_glass_shatter_overlay.dart';

class TrayGlassScene extends ConsumerStatefulWidget {
  const TrayGlassScene({
    super.key,
    required this.bookKey,
    required this.size,
    required this.center,
    required this.glassRadius,
  });

  final int bookKey;
  final Size size;
  final Offset center;
  final double glassRadius;

  @override
  ConsumerState<TrayGlassScene> createState() => _TrayGlassSceneState();
}

class _TrayGlassSceneState extends ConsumerState<TrayGlassScene>
    with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _crackGrow;
  late final AnimationController _heal;
  late final AnimationController _impactShake;
  late final AnimationController _shatter;

  int _lastSeedCount = 0;
  int _healingIndex = -1;
  bool _gameOverStarted = false;
  bool _gameOverModalShown = false;
  List<TrayGlassShatterParticle> _particles = const [];

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _crackGrow =
        AnimationController(
          vsync: this,
          duration: TrayGlassConstants.crackGrowDuration,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _heal =
        AnimationController(
          vsync: this,
          duration: TrayGlassConstants.healFadeDuration,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _impactShake =
        AnimationController(
          vsync: this,
          duration: TrayGlassConstants.impactShakeDuration,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _shatter =
        AnimationController(
          vsync: this,
          duration: TrayGlassConstants.shatterDuration,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _shatter.addStatusListener(_onShatterStatus);

    final initial = ref
        .read(wordBuilderGameProvider(widget.bookKey))
        .valueOrNull;
    if (initial != null) {
      _lastSeedCount = initial.glassCrackSeeds.length;
      if (initial.isTrayGameOver) {
        _startShatter(fromSeeds: initial.glassCrackSeeds);
      }
    }
  }

  void _onShatterStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _gameOverModalShown) return;
    Future<void>.delayed(TrayGlassConstants.gameOverModalDelay, () {
      if (!mounted || _gameOverModalShown) return;
      _presentGameOverModal();
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _crackGrow.dispose();
    _heal.dispose();
    _impactShake.dispose();
    _shatter.removeStatusListener(_onShatterStatus);
    _shatter.dispose();
    super.dispose();
  }

  void _playGlassCrackSfx() {
    final enabled = ref.read(wordBuilderGameGlassSfxEnabledProvider);
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
    final sfxOn = ref.read(wordBuilderGameSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderSoundServiceProvider)
          .play(WordBuilderSound.wrong, enabled: sfxOn && enabled),
    );
  }

  void _playShatterSfx() {
    final enabled = ref.read(wordBuilderGameGlassSfxEnabledProvider);
    if (enabled) {
      HapticFeedback.heavyImpact();
    }
    final sfxOn = ref.read(wordBuilderGameSfxEnabledProvider);
    unawaited(
      ref
          .read(wordBuilderSoundServiceProvider)
          .play(WordBuilderSound.gameOver, enabled: sfxOn && enabled),
    );
  }

  void _startShatter({required List<int> fromSeeds}) {
    if (_gameOverStarted) return;
    _gameOverStarted = true;
    final seed = fromSeeds.isEmpty
        ? widget.bookKey
        : fromSeeds.fold(0, (a, b) => a ^ b);
    _particles = buildTrayGlassShatterParticles(
      center: widget.center,
      radius: widget.glassRadius,
      seed: seed,
    );
    _playShatterSfx();
    _shatter
      ..stop()
      ..reset();
    unawaited(_shatter.forward());
  }

  void _resetShatter() {
    _gameOverStarted = false;
    _gameOverModalShown = false;
    _particles = const [];
    _shatter
      ..stop()
      ..reset();
  }

  Future<void> _presentGameOverModal() async {
    if (_gameOverModalShown || !mounted) return;
    _gameOverModalShown = true;
    await TrayGlassGameOverDialog.show(context, bookKey: widget.bookKey);
    if (mounted) _gameOverModalShown = false;
  }

  void _onNewCrack() {
    _healingIndex = -1;
    _heal
      ..stop()
      ..reset();
    _crackGrow
      ..stop()
      ..reset();
    _impactShake
      ..stop()
      ..reset();
    _playGlassCrackSfx();
    unawaited(_crackGrow.forward());
    unawaited(_impactShake.forward());
  }

  void _onHealCrack(int index) {
    _healingIndex = index;
    _heal
      ..stop()
      ..reset();
    unawaited(_heal.forward());
  }

  void _applyGameState(WordBuilderViewState s) {
    if (!s.isTrayGameOver && _gameOverStarted) {
      _resetShatter();
      _lastSeedCount = s.glassCrackSeeds.length;
      return;
    }

    if (s.isTrayGameOver && !_gameOverStarted) {
      _startShatter(fromSeeds: s.glassCrackSeeds);
    }

    final seeds = s.glassCrackSeeds;
    if (seeds.length > _lastSeedCount) {
      _onNewCrack();
    } else if (seeds.length < _lastSeedCount && _lastSeedCount > 0) {
      _onHealCrack(_lastSeedCount - 1);
    }

    _lastSeedCount = seeds.length;
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

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final segments = GlassCrackPathGenerator.segmentsFromSeeds(
      seeds: s.glassCrackSeeds,
      center: widget.center,
      radius: widget.glassRadius,
    );
    final stress =
        (s.wrongAnswerCount / TrayGlassConstants.maxWrongBeforeShatter).clamp(
          0.0,
          1.0,
        );

    final shakeOffset = _impactShake.isAnimating
        ? Offset(
            math.sin(_impactShake.value * math.pi * 6) *
                widget.glassRadius *
                0.035 *
                (1 - _impactShake.value),
            math.cos(_impactShake.value * math.pi * 4) *
                widget.glassRadius *
                0.02 *
                (1 - _impactShake.value),
          )
        : Offset.zero;

    final glassLayer = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_shimmer, _crackGrow, _heal]),
        builder: (context, _) {
          return CustomPaint(
            size: widget.size,
            painter: TrayGlassPainter(
              center: widget.center,
              radius: widget.glassRadius,
              scheme: scheme,
              isDark: isDark,
              crackSegments: segments,
              crackGrowProgress: Curves.easeOutCubic.transform(
                _crackGrow.value,
              ),
              healProgress: Curves.easeInOut.transform(_heal.value),
              healingIndex: _healingIndex,
              shimmerPhase: _shimmer.value,
              stressLevel: stress,
            ),
          );
        },
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Transform.translate(offset: shakeOffset, child: glassLayer),
        if (_gameOverStarted)
          TrayGlassShatterOverlay(
            center: widget.center,
            radius: widget.glassRadius,
            progress: _shatter.value,
            particles: _particles,
            isDark: isDark,
          ),
      ],
    );
  }
}
