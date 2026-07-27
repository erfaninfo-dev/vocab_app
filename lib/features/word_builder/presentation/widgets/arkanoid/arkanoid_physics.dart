import 'dart:math' as math;
import 'dart:ui';

import '../../../domain/arkanoid_ball_speed.dart';
import '../../../domain/word_builder_models.dart';

/// One letter brick on the Arkanoid board.
class ArkanoidBrick {
  ArkanoidBrick({
    required this.letter,
    required this.rect,
  });

  final LetterInstance letter;
  Rect rect;
  bool removed = false;
}

/// Predicted paddle contact + optional rebound ray for aim assist.
class ArkanoidAimPreview {
  const ArkanoidAimPreview({
    required this.approach,
    required this.hit,
    required this.willHitPaddle,
    required this.reboundDir,
  });

  final List<Offset> approach;
  final Offset hit;
  final bool willHitPaddle;
  final Offset? reboundDir;
}

/// Pure physics/sim for the Arkanoid letter board (no Flutter widgets).
class ArkanoidPhysicsWorld {
  ArkanoidPhysicsWorld({
    required this.width,
    required this.height,
    this.ballSpeedLevel = ArkanoidBallSpeedScale.defaultLevel,
  });

  double width;
  double height;
  int ballSpeedLevel;

  static const ballRadius = 9.0;
  static const paddleHeight = 16.0;
  static const basePaddleWidthFactor = 0.26;
  static const substeps = 4;
  static const paddleBounceSpread = 1.05;

  /// Grows on correct words, shrinks on wrong (0.72..1.55).
  double paddleScale = 1.0;

  final List<ArkanoidBrick> bricks = [];
  Offset ball = Offset.zero;
  Offset ballVel = Offset.zero;
  double paddleCenterX = 0;
  bool serving = true;
  bool shake = false;

  LetterInstance? hitLetter;
  Offset? sparkAt;

  /// After repeated misses, slightly widen paddle forgiveness.
  bool forgiveness = false;

  double get minBallSpeed => ArkanoidBallSpeedScale.minSpeed(ballSpeedLevel);
  double get maxBallSpeed => ArkanoidBallSpeedScale.maxSpeed(ballSpeedLevel);

  double get paddleWidth {
    final base =
        (width * basePaddleWidthFactor * paddleScale).clamp(72.0, width * 0.55);
    return forgiveness ? (base * 1.12).clamp(72.0, width * 0.62) : base;
  }

  void setForgiveness({required bool active}) {
    forgiveness = active;
  }

  Rect get paddleRect {
    final left =
        (paddleCenterX - paddleWidth / 2).clamp(0.0, width - paddleWidth);
    return Rect.fromLTWH(
      left,
      height - paddleHeight - 12,
      paddleWidth,
      paddleHeight,
    );
  }

  void growPaddle() {
    paddleScale = (paddleScale + 0.12).clamp(0.72, 1.55);
  }

  void shrinkPaddle() {
    paddleScale = (paddleScale - 0.12).clamp(0.72, 1.55);
  }

  /// Apply a new speed level; rescale in-flight velocity if needed.
  void setBallSpeedLevel(int next) {
    final clamped = ArkanoidBallSpeedScale.clampLevel(next);
    if (ballSpeedLevel == clamped) return;
    final prevLaunch = ArkanoidBallSpeedScale.launchSpeed(ballSpeedLevel);
    ballSpeedLevel = clamped;
    if (!serving && ballVel.distance > 1) {
      final scale =
          ArkanoidBallSpeedScale.launchSpeed(clamped) / prevLaunch;
      ballVel = ballVel * scale;
      _clampSpeed();
    }
  }

  /// Bounce angle unit vector for a paddle hit at [hitX] (same as physics).
  static Offset reboundDirectionForHit({
    required double hitX,
    required Rect paddle,
  }) {
    final hitNorm =
        ((hitX - paddle.center.dx) / (paddle.width / 2)).clamp(-1.0, 1.0);
    final angle = -math.pi / 2 + hitNorm * paddleBounceSpread;
    return Offset(math.cos(angle), math.sin(angle));
  }

  /// Predicted contact on the paddle line + rebound preview while descending.
  ArkanoidAimPreview? aimPreview() {
    if (serving || width <= 0 || height <= 0) return null;
    if (ballVel.dy <= 0) return null;

    final targetY = paddleRect.top - ballRadius;
    if (ball.dy >= targetY - 1) return null;

    var x = ball.dx;
    var y = ball.dy;
    var vx = ballVel.dx;
    var vy = ballVel.dy;
    final path = <Offset>[Offset(x, y)];

    for (var i = 0; i < 320; i++) {
      final dt = 0.006;
      x += vx * dt;
      y += vy * dt;
      if (x < ballRadius) {
        x = ballRadius;
        vx = vx.abs();
      } else if (x > width - ballRadius) {
        x = width - ballRadius;
        vx = -vx.abs();
      }
      if (y < ballRadius) {
        y = ballRadius;
        vy = vy.abs();
      }
      if (i % 3 == 0) path.add(Offset(x, y));
      if (y >= targetY) {
        final hit = Offset(x.clamp(ballRadius, width - ballRadius), targetY);
        path.add(hit);
        final p = paddleRect;
        final willHit = hit.dx >= p.left && hit.dx <= p.right;
        final rebound = willHit
            ? reboundDirectionForHit(hitX: hit.dx, paddle: p)
            : null;
        return ArkanoidAimPreview(
          approach: path,
          hit: hit,
          willHitPaddle: willHit,
          reboundDir: rebound,
        );
      }
    }
    return null;
  }

  void resize(double w, double h) {
    final sx = width <= 0 ? 1.0 : w / width;
    width = w;
    height = h;
    paddleCenterX =
        (paddleCenterX * sx).clamp(paddleWidth / 2, w - paddleWidth / 2);
    if (!serving) {
      ball = Offset(ball.dx * sx, ball.dy * (h / (height <= 0 ? h : height)));
    } else {
      _snapBallToPaddle();
    }
  }

  void setPaddleFromNorm(double normX) {
    paddleCenterX = (normX.clamp(0.0, 1.0) * width)
        .clamp(paddleWidth / 2, width - paddleWidth / 2);
    if (serving) _snapBallToPaddle();
  }

  void _snapBallToPaddle() {
    final p = paddleRect;
    ball = Offset(p.center.dx, p.top - ballRadius - 2);
    ballVel = Offset.zero;
  }

  void layoutBricks(List<LetterInstance> letters) {
    bricks
      ..clear()
      ..addAll(_buildSingleRow(letters, width, height));
  }

  /// All bricks on one centered row — square tiles with gaps wide enough
  /// for the ball to pass between and bounce off the ceiling.
  static List<ArkanoidBrick> _buildSingleRow(
    List<LetterInstance> letters,
    double w,
    double h,
  ) {
    if (letters.isEmpty || w <= 0) return [];
    final count = letters.length;
    final gap = math.max(ballRadius * 2 + 8, 24.0);
    final sidePad = 12.0;
    final usable = w - sidePad * 2;
    final side = math
        .min((usable - gap * (count - 1)) / count, h * 0.11)
        .clamp(24.0, 46.0);
    final rowWidth = count * side + (count - 1) * gap;
    final startX = (w - rowWidth) / 2;
    final top = h * 0.14;
    final out = <ArkanoidBrick>[];
    for (var i = 0; i < count; i++) {
      final rect = Rect.fromLTWH(
        startX + i * (side + gap),
        top,
        side,
        side,
      );
      out.add(ArkanoidBrick(letter: letters[i], rect: rect));
    }
    return out;
  }

  void launch() {
    if (!serving) return;
    serving = false;
    final angle = -math.pi / 2 + (math.Random().nextDouble() - 0.5) * 0.5;
    final speed = ArkanoidBallSpeedScale.launchSpeed(ballSpeedLevel);
    ballVel = Offset(math.cos(angle) * speed, math.sin(angle) * speed);
  }

  void resetServe() {
    serving = true;
    _snapBallToPaddle();
    ballVel = Offset.zero;
    hitLetter = null;
    sparkAt = null;
  }

  void update(
    double dt, {
    required Set<int> selectedIds,
    bool acceptNewLetters = true,
  }) {
    hitLetter = null;
    sparkAt = null;
    shake = false;
    if (serving || width <= 0 || height <= 0) {
      if (serving) _snapBallToPaddle();
      return;
    }

    final step = dt / substeps;
    for (var i = 0; i < substeps; i++) {
      _integrate(
        step,
        selectedIds: selectedIds,
        acceptNewLetters: acceptNewLetters,
      );
      if (serving) break;
    }
    _clampSpeed();
  }

  void _integrate(
    double dt, {
    required Set<int> selectedIds,
    required bool acceptNewLetters,
  }) {
    ball += ballVel * dt;

    if (ball.dx - ballRadius < 0) {
      ball = Offset(ballRadius, ball.dy);
      ballVel = Offset(ballVel.dx.abs(), ballVel.dy);
    } else if (ball.dx + ballRadius > width) {
      ball = Offset(width - ballRadius, ball.dy);
      ballVel = Offset(-ballVel.dx.abs(), ballVel.dy);
    }
    if (ball.dy - ballRadius < 0) {
      ball = Offset(ball.dx, ballRadius);
      ballVel = Offset(ballVel.dx, ballVel.dy.abs());
      final floorDy = minBallSpeed * 0.55;
      if (ballVel.dy < floorDy) {
        ballVel = Offset(ballVel.dx, floorDy);
      }
    }

    if (ball.dy - ballRadius > height + 20) {
      resetServe();
      return;
    }

    _collidePaddle();
    _collideBricks(selectedIds, acceptNewLetters: acceptNewLetters);
  }

  void _collidePaddle() {
    final p = paddleRect;
    final ballRect = Rect.fromCircle(center: ball, radius: ballRadius);
    if (!ballRect.overlaps(p) || ballVel.dy <= 0) return;

    ball = Offset(ball.dx, p.top - ballRadius - 0.5);
    final dir = reboundDirectionForHit(hitX: ball.dx, paddle: p);
    final speed = ballVel.distance.clamp(minBallSpeed, maxBallSpeed);
    ballVel = dir * speed;
  }

  void _collideBricks(
    Set<int> selectedIds, {
    required bool acceptNewLetters,
  }) {
    final ballRect = Rect.fromCircle(center: ball, radius: ballRadius);
    for (final b in bricks) {
      if (b.removed) continue;
      if (!ballRect.overlaps(b.rect)) continue;

      final inter = ballRect.intersect(b.rect);
      if (inter.width < inter.height) {
        ballVel = Offset(-ballVel.dx, ballVel.dy);
        ball = Offset(
          ball.dx < b.rect.center.dx
              ? b.rect.left - ballRadius - 0.5
              : b.rect.right + ballRadius + 0.5,
          ball.dy,
        );
      } else {
        ballVel = Offset(ballVel.dx, -ballVel.dy);
        ball = Offset(
          ball.dx,
          ball.dy < b.rect.center.dy
              ? b.rect.top - ballRadius - 0.5
              : b.rect.bottom + ballRadius + 0.5,
        );
      }

      sparkAt = b.rect.center;
      final alreadySelected = selectedIds.contains(b.letter.id);
      if (acceptNewLetters && !alreadySelected && hitLetter == null) {
        hitLetter = b.letter;
      }
      break;
    }
  }

  void _clampSpeed() {
    final speed = ballVel.distance;
    if (speed < 1) return;
    if (speed < minBallSpeed) {
      ballVel = ballVel * (minBallSpeed / speed);
    } else if (speed > maxBallSpeed) {
      ballVel = ballVel * (maxBallSpeed / speed);
    }
    final minDy = minBallSpeed * 0.45;
    if (ballVel.dy.abs() < minDy) {
      ballVel = Offset(
        ballVel.dx,
        ballVel.dy < 0 ? -minDy : minDy,
      );
      _clampSpeed();
    }
  }
}
