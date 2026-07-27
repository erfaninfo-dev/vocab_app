import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/arkanoid_ball_speed_controller.dart';
import '../../../application/word_builder_game_notifier.dart';
import '../../../domain/word_builder_models.dart';
import 'arkanoid_painter.dart';
import 'arkanoid_physics.dart';

/// Breakout-style letter picker for Word Builder Arkanoid play mode.
///
/// Runs PREFIX_CHECK after every letter (stage targets only).
class ArkanoidLetterBoard extends ConsumerStatefulWidget {
  const ArkanoidLetterBoard({
    super.key,
    required this.bookKey,
    required this.letters,
  });

  final int bookKey;
  final List<LetterInstance> letters;

  @override
  ConsumerState<ArkanoidLetterBoard> createState() =>
      _ArkanoidLetterBoardState();
}

class _ArkanoidLetterBoardState extends ConsumerState<ArkanoidLetterBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _world = ArkanoidPhysicsWorld(width: 1, height: 1);
  Duration _lastElapsed = Duration.zero;
  final List<Offset> _trail = [];
  double _sparkLife = 0;
  double _wrongFlash = 0;
  double _successFlash = 0;
  double _prefixFlash = 0;
  bool _wasWrong = false;
  bool _autoEvalBusy = false;
  bool _attemptClean = true;
  int _wrongStreak = 0;
  int? _layoutSig;
  int? _lastHitLetterId;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(wordBuilderGameProvider(widget.bookKey).notifier)
            .prepareArkanoidMode(),
      );
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ArkanoidLetterBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameLetterIds(oldWidget.letters, widget.letters)) {
      _layoutSig = null;
    }
  }

  bool _sameLetterIds(List<LetterInstance> a, List<LetterInstance> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].char != b[i].char) return false;
    }
    return true;
  }

  void _ensureLayout(Size size) {
    final sig = Object.hash(
      size.width.round(),
      size.height.round(),
      widget.letters.map((e) => e.id).join(','),
    );
    if (_layoutSig == sig) return;
    _layoutSig = sig;
    if ((_world.width - size.width).abs() > 0.5 ||
        (_world.height - size.height).abs() > 0.5) {
      if (_world.width <= 1) {
        _world.width = size.width;
        _world.height = size.height;
        _world.paddleCenterX = size.width / 2;
      } else {
        _world.resize(size.width, size.height);
      }
    } else {
      _world.width = size.width;
      _world.height = size.height;
    }
    _world.layoutBricks(widget.letters);
    if (_world.serving) _world.resetServe();
  }

  void _onTick(Duration elapsed) {
    final dtMs = _lastElapsed == Duration.zero
        ? 16
        : (elapsed - _lastElapsed).inMilliseconds;
    _lastElapsed = elapsed;
    final dt = (dtMs.clamp(1, 32)) / 1000.0;

    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (s == null) return;

    final speed = ref.read(arkanoidBallSpeedProvider);
    _world.setBallSpeedLevel(speed);
    _world.setForgiveness(active: _wrongStreak >= 2);

    final selectedIds = s.path.map((e) => e.id).toSet();

    if (s.pathWrongHighlight && !_wasWrong) {
      _wrongFlash = 1;
      _attemptClean = false;
      _wrongStreak += 1;
      _world.shrinkPaddle();
      // Keep ball in play — only feedback (flash / haptic / sound), no re-serve.
      HapticFeedback.mediumImpact();
      unawaited(_clearWrongAfterFlash());
    }
    _wasWrong = s.pathWrongHighlight;
    if (_wrongFlash > 0) {
      _wrongFlash = (_wrongFlash - dt * 2.2).clamp(0.0, 1.0);
    }
    if (_successFlash > 0) {
      _successFlash = (_successFlash - dt * 1.4).clamp(0.0, 1.0);
    }
    if (_prefixFlash > 0) {
      _prefixFlash = (_prefixFlash - dt * 3.2).clamp(0.0, 1.0);
    }
    if (_sparkLife > 0) {
      _sparkLife = (_sparkLife - dt * 3.5).clamp(0.0, 1.0);
    }

    // During reject flash, ball may bounce but letters are not appended.
    if (!s.trayVictorySequenceActive && !_autoEvalBusy) {
      _world.update(
        dt,
        selectedIds: selectedIds,
        acceptNewLetters: !s.pathWrongHighlight,
      );
      final hit = _world.hitLetter;
      if (hit != null && !s.pathWrongHighlight) {
        _sparkLife = 1;
        _lastHitLetterId = hit.id;
        unawaited(_onLetterHit(hit));
      }
    }

    if (!_world.serving) {
      _trail.add(_world.ball);
      if (_trail.length > 8) _trail.removeAt(0);
    } else {
      _trail.clear();
    }

    if (mounted) setState(() {});
  }

  Future<void> _onLetterHit(LetterInstance hit) async {
    final n = ref.read(wordBuilderGameProvider(widget.bookKey).notifier);
    await n.appendLetterFromDrag(hit);
    if (!mounted) return;

    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (s == null || s.pathWrongHighlight || _autoEvalBusy) return;

    _autoEvalBusy = true;
    try {
      await n.evaluateArkanoidAfterLetter(pathClean: _attemptClean);
      if (!mounted) return;
      final after = ref
          .read(wordBuilderGameProvider(widget.bookKey))
          .valueOrNull;
      if (after?.feedbackMessage == '__arkanoid_prefix') {
        _prefixFlash = 1;
      }
    } finally {
      _autoEvalBusy = false;
    }
  }

  Future<void> _clearWrongAfterFlash() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    await ref
        .read(wordBuilderGameProvider(widget.bookKey).notifier)
        .clearWrongSelectionAfterFade();
  }

  Future<void> _onCorrectWord({required bool perfect}) async {
    _successFlash = 1;
    _prefixFlash = 0;
    _wrongStreak = 0;
    _attemptClean = true;
    _world.setForgiveness(active: false);
    _world.growPaddle();
    _world.resetServe();
    if (!mounted) return;
    _layoutSig = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    final selectedIds = s?.path.map((e) => e.id).toSet() ?? {};
    final blocked =
        (s?.pathWrongHighlight ?? false) ||
        (s?.trayVictorySequenceActive ?? false);
    final hardBlocked = s?.trayVictorySequenceActive ?? false;

    ref.listen(wordBuilderGameProvider(widget.bookKey), (prev, next) {
      final a = prev?.valueOrNull?.circleLetters;
      final b = next.valueOrNull?.circleLetters;
      if (a != null && b != null && !_sameLetterIds(a, b)) {
        _layoutSig = null;
        _world.resetServe();
      }

      final p = prev?.valueOrNull;
      final n = next.valueOrNull;
      if (p == null || n == null) return;

      final feedback = n.feedbackMessage;
      final accepted =
          feedback == '__correct' || feedback == '__correct_perfect';
      if (p.path.isNotEmpty && n.path.isEmpty && accepted) {
        unawaited(_onCorrectWord(perfect: feedback == '__correct_perfect'));
        return;
      }

      if (p.path.isNotEmpty &&
          n.path.isEmpty &&
          !n.pathWrongHighlight &&
          !accepted) {
        // Path cleared after wrong fade (or similar) — keep ball in play.
        _attemptClean = true;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureLayout(size);

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: blocked || _autoEvalBusy
                  ? null
                  : () {
                      if (_world.serving) {
                        _world.launch();
                      }
                    },
              onPanUpdate: hardBlocked
                  ? null
                  : (d) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(d.globalPosition);
                      _world.setPaddleFromNorm(local.dx / size.width);
                    },
              onPanStart: hardBlocked
                  ? null
                  : (d) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(d.globalPosition);
                      _world.setPaddleFromNorm(local.dx / size.width);
                    },
              child: CustomPaint(
                size: size,
                painter: ArkanoidBoardPainter(
                  world: _world,
                  selectedIds: selectedIds,
                  wrongFlash: _wrongFlash,
                  successFlash: _successFlash,
                  prefixFlash: _prefixFlash,
                  lastHitLetterId: _lastHitLetterId,
                  trail: List.of(_trail),
                  sparkLife: _sparkLife,
                  isDark: isDark,
                  scheme: scheme,
                ),
              ),
            ),
            if (_world.serving && !blocked)
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                child: IgnorePointer(
                  child: Text(
                    l10n.wordBuilderArkanoidServeHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
