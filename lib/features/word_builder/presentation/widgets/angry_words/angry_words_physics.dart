import 'dart:math' as math;
import 'dart:ui';

import '../../../domain/word_builder_models.dart';
import 'angry_words_loadout.dart';

/// Cage breach → free slingshot letter hunt.
enum AngryWordsPhase {
  /// Letters locked on top; gun melts the barrier.
  cage,

  /// Barrier gone; letters unlock with a short stagger.
  freeing,

  /// Classic Angry Words slingshot + drifting letters.
  free,
}

/// Rapid-fire blaster projectile (Phase A only).
class AngryWordsBullet {
  AngryWordsBullet({
    required this.pos,
    required this.vel,
    required this.damage,
    required this.pierceLeft,
    required this.radius,
    required this.element,
    this.splashRadius = 0,
    this.homing = false,
  });

  Offset pos;
  Offset vel;
  final int damage;
  int pierceLeft;
  final double radius;
  final AngryWordsBulletElement element;
  final double splashRadius;
  final bool homing;
  bool dead = false;
}

/// Floating letter that wanders continuously (never sits still).
class AngryWordsLetterTarget {
  AngryWordsLetterTarget({
    required this.letter,
    required this.pos,
    required this.vel,
    required this.radius,
    required this.homeRadius,
    required this.phase,
    required this.baseSpeed,
    required this.wanderFreq,
    required this.tintIndex,
    this.revealT = 1,
  });

  final LetterInstance letter;
  Offset pos;
  Offset vel;
  double radius;

  /// Full free-phase size (grow back to this after filler orbs are cleared).
  double homeRadius;
  final double phase;
  final double baseSpeed;
  final double wanderFreq;

  /// Index into the distinct letter-orb palette (unique per stage letter).
  final int tintIndex;

  /// 0..1 pop-in when freed from a wall orb.
  double revealT;
  bool removed = false;

  Rect get bounds => Rect.fromCircle(center: pos, radius: radius);
}

/// Wall ball — may hide a stage letter until popped.
class AngryWordsPropBubble {
  AngryWordsPropBubble({
    required this.id,
    required this.pos,
    required this.vel,
    required this.radius,
    required this.phase,
    required this.baseSpeed,
    required this.wanderFreq,
    required this.palette,
    required this.material,
    required this.maxHp,
    this.cargo,
    this.cargoTintIndex,
    this.spawnT = 1,
    this.skinEmoji,
  }) : hp = maxHp;

  final int id;
  Offset pos;
  Offset vel;
  double radius;
  final double phase;
  final double baseSpeed;
  final double wanderFreq;

  /// 0..5 — color family for candy/plastic painter accents.
  final int palette;
  AngryWordsPropMaterial material;
  int maxHp;
  int hp;
  double hitFlash = 0;

  /// Ice-gun freeze / slime stick; decays in the barrier stepper.
  double freezeT = 0;

  /// Brief rubber stretch juice before a lethal pop (0..1).
  double stretchT = 0;
  bool pendingStretchPop = false;
  LetterInstance? cargo;

  /// Distinct tint reserved for [cargo] (unique among stage letters).
  int? cargoTintIndex;

  /// Stage 35/36: draw this emoji instead of a material circle (physics unchanged).
  String? skinEmoji;

  /// 0..1 pop-in when wall orbs refill after a solved word.
  double spawnT;
  bool removed = false;

  bool get holdsLetter => cargo != null;
  bool get isSpawnVisible => spawnT > 0.02;
}

/// One prop popped by the projectile this frame (board plays juice).
class AngryWordsPropPop {
  const AngryWordsPropPop({
    required this.at,
    required this.palette,
    required this.radius,
    required this.material,
    this.revealedChar,
    this.steamy = false,
  });

  final Offset at;
  final int palette;
  final double radius;
  final AngryWordsPropMaterial material;
  final String? revealedChar;

  /// Short steam puff (e.g. ice/water vs magma).
  final bool steamy;
}

/// Spilled yolk from a cracked egg (stage 9) — falls, merges, slides on floor.
class AngryWordsYolkBlob {
  AngryWordsYolkBlob({
    required this.pos,
    required this.vel,
    required this.radius,
  });

  Offset pos;
  Offset vel;
  double radius;
  bool removed = false;
  bool onFloor = false;
}

/// Live aim preview while the player pulls the slingshot.
class AngryWordsAimPreview {
  const AngryWordsAimPreview({
    required this.path,
    required this.hitsLetter,
    this.predictedLetterId,
    this.impact,
  });

  final List<Offset> path;
  final bool hitsLetter;
  final int? predictedLetterId;
  final Offset? impact;
}

class _LetterSim {
  _LetterSim(
    this.pos,
    this.vel,
    this.radius,
    this.phase,
    this.baseSpeed,
    this.wanderFreq,
    this.id,
  );

  Offset pos;
  Offset vel;
  final double radius;
  final double phase;
  final double baseSpeed;
  final double wanderFreq;
  final int id;
}

/// Pure physics for Angry Words (slingshot + gravity + drifting letters).
class AngryWordsPhysicsWorld {
  AngryWordsPhysicsWorld({required this.width, required this.height});

  double width;
  double height;

  static const ballRadius = 11.0;
  static const gravity = 1280.0;
  static const substeps = 6;
  /// Shorter full-draw so MID/MAX arrive with less finger travel.
  static const maxPull = 98.0;
  static const minPull = 12.0;
  static const minLaunchSpeed = 780.0;
  /// Full draw: very fast, heavy hit.
  static const maxLaunchSpeed = 2680.0;
  static const restitution = 0.92;

  /// Maps linear pull 0..1 → power/speed 0..1 (ease-out: mid/max sooner).
  static double pullPowerCurve(double t) {
    final x = t.clamp(0.0, 1.0);
    return 1.0 - math.pow(1.0 - x, 1.7).toDouble();
  }

  /// Pull distance → 0..1 after [pullPowerCurve].
  static double powerNormFromPullDistance(double dist) {
    final linear =
        ((dist.clamp(minPull, maxPull) - minPull) / (maxPull - minPull))
            .clamp(0.0, 1.0);
    return pullPowerCurve(linear);
  }

  /// Space under the muzzle so the sling tip stays inside the board while aiming.
  static const groundYPad = 96.0;
  static const letterBounce = 0.94;

  /// Extra gap between ball *surfaces* (drawn radius unchanged) so they
  /// don't visually glue together while drifting.
  static const letterSeparationPad = 4.0;

  /// Soft push starts this many px before hard contact.
  static const letterSoftRepelReach = 12.0;

  /// Keep the rubber-band tip (and ball) fully visible inside the clipped frame.
  static const slingTipInset = 12.0;

  /// Ambient breeze always drifts letters (noticeable left/right roam).
  static const ambientWindPx = 68.0;

  /// Extra push while the wind button is held, or while the sling aims at it.
  static const boostWindPx = 140.0;

  /// Fallback if loadout not set yet.
  static const bulletRadius = 5.2;
  static const bulletSpeed = 1080.0;

  AngryWordsLoadout loadout = AngryWordsLoadout.forProgress(0);

  double get gunFireInterval => loadout.fireInterval;

  /// Set by [tryFireGun] each frame; board plays shot SFX then clears it.
  int shotsFiredThisFrame = 0;

  final List<AngryWordsLetterTarget> letters = [];
  final List<AngryWordsPropBubble> props = [];
  final List<AngryWordsPropPop> _pendingPropPops = [];
  final List<AngryWordsBullet> bullets = [];
  final List<AngryWordsYolkBlob> yolks = [];
  double simTime = 0;

  /// Floor line where spilled yolk puddles rest and slide.
  double get yolkFloorY => height - 38.0;

  AngryWordsPhase phase = AngryWordsPhase.cage;

  /// Unit aim direction for the cage-phase blaster (default straight up).
  Offset gunAim = const Offset(0, -1);
  bool gunTriggerHeld = false;
  double fireCooldown = 0;
  double muzzleFlash = 0;
  double gunRecoil = 0;

  /// 0..1 — board can punch/shake the camera.
  double screenPunch = 0;
  int cageCombo = 0;
  double _freeUnlockTimer = 0;

  /// Staggered wall refill after a solved word.
  bool propSpawnActive = false;
  int _propSpawnNext = 0;
  double _propSpawnTimer = 0;

  /// 0..1 — rises while wind button is held, falls when released.
  double windBoost = 0;
  bool windHeld = false;

  /// After a wrong hit, letters may fly much faster for a short time.
  double chaosTimer = 0;

  /// Slow-changing breeze direction (radians).
  double breezeAngle = 0.4;

  /// Finger-dragged letter (knock other balls around).
  int? draggedLetterId;
  Offset? _lastDragPos;
  Offset _dragVel = Offset.zero;
  Offset? _letterPressStart;
  bool _letterPressMoved = false;

  /// Hard focus (tap a letter) — like RDR2 mark / sticky target.
  int? focusedLetterId;

  /// Soft lock while aiming the slingshot (aim-cone AI + stickiness).
  int? softLockLetterId;

  /// 0..1 — reticle pulse / assist feel while a soft lock is active.
  double softLockPulse = 0;

  Offset ball = Offset.zero;
  Offset ballVel = Offset.zero;
  bool inFlight = false;
  bool aiming = false;

  /// 0..1 — while aiming the slingshot, letters ease upward / away from muzzle.
  double aimCrowdLift = 0;

  /// Board sets true while the sling/gun aim ray hits the wind button.
  bool windAimActive = false;

  /// Finger pull (unaffected by aim assist).
  Offset? _rawPullPoint;

  /// Assisted pull used for preview / launch (soft lock may nudge direction).
  Offset? pullPoint;

  LetterInstance? hitLetter;
  Offset? sparkAt;
  bool spentShot = false;

  /// Velocity of the shot at the moment it last struck a letter (for wrong-hit cascade).
  Offset lastShotImpactVel = Offset.zero;

  /// 0..1 shot power at last letter impact (from launch speed).
  double lastShotPowerNorm = 0.5;

  /// Brief red shake on a wrong-hit letter (id → remaining 0..1).
  final Map<int, double> letterShake = {};

  Offset get muzzle => Offset(width * 0.5, height - groundYPad);

  /// How many side-by-side gun bodies share [gunAim] / fire (1 or 2).
  int get gunMountCount => loadout.gunMounts.clamp(1, 2);

  /// World tip origin for mount [mountIndex] (0-based). Aim stays shared.
  Offset muzzleForMount(int mountIndex) {
    final n = gunMountCount;
    if (n <= 1) return muzzle;
    final gap = math.min(40.0, width * 0.085);
    final mid = (n - 1) * 0.5;
    return muzzle + Offset((mountIndex - mid) * gap * 2, 0);
  }

  /// Letter roam zone: upper ~⅔ of the board, with clearance above the slingshot.
  Rect get playBounds {
    final top = height * 0.04;
    final upperTwoThirds = height * (2 / 3);
    final aboveLauncher = muzzle.dy - 56;
    final bottom = math.min(upperTwoThirds, aboveLauncher);
    final left = width * 0.02;
    final right = width * 0.98;
    return Rect.fromLTRB(left, top, right, math.max(top + 80, bottom));
  }

  /// Roam zone while aiming: lifted off the launcher, with air under the ceiling.
  Rect get letterRoamBounds {
    final b = playBounds;
    final lift = aimCrowdLift.clamp(0.0, 1.0);
    if (lift < 0.01) return b;
    final t = lift * lift * (3 - 2 * lift);
    final top = b.top + height * 0.075 * t;
    final bottom = math.min(
      b.bottom - height * 0.13 * t,
      muzzle.dy - (56 + 54 * t),
    );
    return Rect.fromLTRB(b.left, top, b.right, math.max(top + 96, bottom));
  }

  bool get isDraggingLetter => draggedLetterId != null;

  bool get isCagePhase => phase == AngryWordsPhase.cage;
  bool get isFreePhase => phase == AngryWordsPhase.free;
  bool get usesGun => phase == AngryWordsPhase.cage;
  bool get usesSlingshot => phase == AngryWordsPhase.free;

  /// Active aim target: while pulling, purely the letter under the aim angle.
  int? get lockedLetterId => aiming ? softLockLetterId : focusedLetterId;

  AngryWordsLetterTarget? letterById(int? id) {
    if (id == null) return null;
    for (final L in letters) {
      if (!L.removed && L.letter.id == id) return L;
    }
    return null;
  }

  int get alivePropCount {
    var n = 0;
    for (final P in props) {
      if (!P.removed && P.spawnT > 0.5) n++;
    }
    return n;
  }

  int get remainingCargoCount {
    var n = 0;
    for (final P in props) {
      if (!P.removed && P.holdsLetter) n++;
    }
    return n;
  }

  /// Wall orbs that are not hiding a letter (decorative fillers).
  int get aliveFillerCount {
    var n = 0;
    for (final P in props) {
      if (!P.removed && !P.holdsLetter) n++;
    }
    return n;
  }

  int get revealedLetterCount => letters.length;

  /// Classic free-phase letter size (pre–cargo-orb scale).
  double homeLetterRadiusForCount(int letterCount) {
    if (width <= 0 || height <= 0) return 22;
    final count = math.max(1, letterCount);
    final cols = math.max(3, math.sqrt(count * 1.35).ceil());
    final rows = math.max(1, (count / cols).ceil());
    final cellW = (width * 0.92) / cols;
    final cellH = (height * (2 / 3) * 0.9) / rows;
    return math.min(math.min(cellW, cellH) * 0.32, 26.0).clamp(18.0, 26.0);
  }

  double get pullDistance {
    final p = pullPoint;
    if (p == null) return 0;
    return (p - muzzle).distance.clamp(0.0, maxPull);
  }

  double get powerNorm => powerNormFromPullDistance(pullDistance);

  double get windIntensity => (0.28 + windBoost * 0.72).clamp(0.0, 1.0);

  Offset get windVector {
    final strength =
        ambientWindPx + boostWindPx * windBoost + 6 * math.sin(simTime * 0.55);
    return Offset(math.cos(breezeAngle), math.sin(breezeAngle)) * strength;
  }

  void setWindHeld(bool held) {
    windHeld = held;
  }

  /// True when the launch aim (opposite of pull) points at [target].
  /// Uses finger aim ([_rawPullPoint]), not letter-tracked [pullPoint].
  bool isAimingToward(Offset target, {double hitRadius = 64}) {
    if (usesGun && gunTriggerHeld) {
      final dir = gunAim;
      final to = target - muzzle;
      final along = to.dx * dir.dx + to.dy * dir.dy;
      if (along < 18) return false;
      final closest = muzzle + dir * along;
      return (closest - target).distance <= hitRadius;
    }
    if (!aiming) return false;
    final pull = _rawPullPoint ?? pullPoint;
    if (pull == null) return false;
    final launch = muzzle - pull;
    if (launch.distance < minPull * 0.65) return false;
    final dir = launch / launch.distance;
    final to = target - muzzle;
    final along = to.dx * dir.dx + to.dy * dir.dy;
    if (along < 18) return false;
    final closest = muzzle + dir * along;
    return (closest - target).distance <= hitRadius;
  }

  /// Drop letter lock so the sling visually follows the finger (e.g. wind aim).
  void preferFingerAim() {
    if (!aiming) return;
    softLockLetterId = null;
    softLockPulse = 0;
    pullPoint = _rawPullPoint;
  }

  void setWindAimActive(bool active) {
    windAimActive = active;
    if (active) preferFingerAim();
  }

  Offset? launchVelocityFromPull(Offset pull) {
    final delta = pull - muzzle;
    final dist = delta.distance;
    if (dist < minPull) return null;
    final clamped = dist.clamp(minPull, maxPull);
    final dir = delta / dist;
    final t = powerNormFromPullDistance(clamped);
    final speed =
        minLaunchSpeed + (maxLaunchSpeed - minLaunchSpeed) * t;
    return -dir * speed;
  }

  void resize(double w, double h) {
    final sx = width <= 0 ? 1.0 : w / width;
    final sy = height <= 0 ? 1.0 : h / height;
    width = w;
    height = h;
    for (final L in letters) {
      L.pos = Offset(L.pos.dx * sx, L.pos.dy * sy);
      L.vel = Offset(L.vel.dx * sx, L.vel.dy * sy);
      final scale = math.min(sx, sy);
      L.homeRadius = (L.homeRadius * scale).clamp(14.0, 28.0);
      L.radius = (L.radius * scale).clamp(12.0, L.homeRadius);
    }
    for (final P in props) {
      P.pos = Offset(P.pos.dx * sx, P.pos.dy * sy);
      P.vel = Offset(P.vel.dx * sx, P.vel.dy * sy);
      P.radius = (P.radius * math.min(sx, sy)).clamp(5.5, 22.0);
    }
    _clampAllLettersInside();
    _clampAllPropsInside();
    if (!inFlight) resetToCannon();
  }

  void layoutLetters(
    List<LetterInstance> source, {
    int? seed,
    AngryWordsLoadout? loadout,
    bool gradualProps = false,
  }) {
    if (loadout != null) this.loadout = loadout;
    phase = AngryWordsPhase.cage;
    gunTriggerHeld = false;
    fireCooldown = 0;
    muzzleFlash = 0;
    gunRecoil = 0;
    screenPunch = 0;
    cageCombo = 0;
    gunAim = const Offset(0, -1);
    _freeUnlockTimer = 0;
    bullets.clear();
    letters.clear();
    yolks.clear();
    final layoutSeed = (seed ?? 0) ^ 0xA11CE;
    props
      ..clear()
      ..addAll(
        _layoutBarrierProps(
          width,
          height,
          letterCount: source.length,
          seed: layoutSeed,
          loadout: this.loadout,
        ),
      );
    // Hide before cargo assign / next paint when refilling gradually.
    if (gradualProps) {
      for (final P in props) {
        P.spawnT = 0;
      }
    }
    _assignLetterCargos(props, source, math.Random(layoutSeed ^ 0xC4A60));
    _pendingPropPops.clear();
    clearLetterFocus();
    resetToCannon();
    if (gradualProps) {
      beginGradualPropSpawn();
    } else {
      propSpawnActive = false;
      _propSpawnNext = 0;
      _propSpawnTimer = 0;
      for (final P in props) {
        P.spawnT = 1;
      }
    }
  }

  /// Wave refill: props start invisible and pop in from bottom-center.
  void beginGradualPropSpawn() {
    if (props.isEmpty) {
      propSpawnActive = false;
      return;
    }
    final center = Offset(width * 0.5, height * 0.45);
    props.sort((a, b) {
      final da = (a.pos - center).distanceSquared + a.pos.dy * 40;
      final db = (b.pos - center).distanceSquared + b.pos.dy * 40;
      return db.compareTo(da);
    });
    for (final P in props) {
      P.spawnT = 0;
    }
    propSpawnActive = true;
    _propSpawnNext = 0;
    _propSpawnTimer = 0;
  }

  void _tickPropSpawn(double dt) {
    if (!propSpawnActive) return;
    _propSpawnTimer += dt;
    const gap = 0.042;
    while (_propSpawnNext < props.length && _propSpawnTimer >= gap) {
      _propSpawnTimer -= gap;
      final P = props[_propSpawnNext];
      if (P.spawnT <= 0) P.spawnT = 0.02;
      _propSpawnNext++;
    }
    var allDone = _propSpawnNext >= props.length;
    for (final P in props) {
      if (P.removed) continue;
      if (P.spawnT > 0 && P.spawnT < 1) {
        P.spawnT = (P.spawnT + dt * 3.6).clamp(0.0, 1.0);
      }
      if (P.spawnT < 1) allDone = false;
    }
    if (allDone) propSpawnActive = false;
  }

  /// Drain prop pops produced since last call (board plays VFX/SFX).
  List<AngryWordsPropPop> takePropPops() {
    if (_pendingPropPops.isEmpty) return const [];
    final out = List<AngryWordsPropPop>.of(_pendingPropPops);
    _pendingPropPops.clear();
    return out;
  }

  /// Hide each stage letter in a random wall orb.
  static void _assignLetterCargos(
    List<AngryWordsPropBubble> props,
    List<LetterInstance> source,
    math.Random rng,
  ) {
    if (props.isEmpty || source.isEmpty) return;
    final ranked = List<AngryWordsPropBubble>.of(props)
      ..sort((a, b) => b.radius.compareTo(a.radius));
    final pool =
        ranked.take(math.max(source.length, ranked.length ~/ 2)).toList()
          ..shuffle(rng);
    final letters = List<LetterInstance>.of(source)..shuffle(rng);
    final n = math.min(letters.length, pool.length);
    // Unique tint per letter — shuffle palette slots so neighbors differ.
    const tintCount = 24;
    final tintSlots = List<int>.generate(tintCount, (i) => i)..shuffle(rng);
    for (var i = 0; i < n; i++) {
      final P = pool[i];
      P.cargo = letters[i];
      P.cargoTintIndex = tintSlots[i % tintCount];
      // Letters always live in eggs — cream shell + yolk spill on crack.
      P.material = AngryWordsPropMaterial.egg;
      P.maxHp = 1;
      P.hp = 1;
      P.skinEmoji = null;
      P.radius = math.max(P.radius, 15.5);
    }
  }

  /// Dense material wall — mix/density from [loadout].
  static List<AngryWordsPropBubble> _layoutBarrierProps(
    double w,
    double h, {
    required int letterCount,
    required AngryWordsLoadout loadout,
    int? seed,
  }) {
    if (w <= 0 || h <= 0) return [];
    final rng = math.Random(seed ?? letterCount * 97 + 13);
    final top = h * 0.06;
    final bottom = h * 0.58;
    final left = w * 0.04;
    final right = w * 0.96;
    final cols = loadout.effectiveCols;
    final rows = loadout.effectiveRows;
    final cellW = (right - left) / cols;
    final cellH = (bottom - top) / rows;
    final out = <AngryWordsPropBubble>[];
    var id = 9000;

    double rollRadius(AngryWordsPropMaterial material) {
      // Early stages: only medium/large (no tiny clutter). Later: small OK.
      final progress = (loadout.profileIndex / 49.0).clamp(0.0, 1.0);
      final allowSmall = loadout.allowsSmallProps;
      final smallShare = allowSmall ? 0.10 + progress * 0.36 : 0.0;
      final largeShare = allowSmall
          ? 0.34 - progress * 0.18
          : 0.42 + (1 - progress) * 0.08;
      final mediumCeil = 1.0 - largeShare;
      final roll = rng.nextDouble();
      final base = !allowSmall
          ? (roll < 0.55
                ? 10.2 + rng.nextDouble() * 3.2
                : 13.5 + rng.nextDouble() * 4.5)
          : roll < smallShare
          ? 5.8 + rng.nextDouble() * 2.4
          : roll < mediumCeil
          ? 9.2 + rng.nextDouble() * 3.4
          : 13.8 + rng.nextDouble() * 4.8;
      final scaled = switch (material) {
        AngryWordsPropMaterial.metal ||
        AngryWordsPropMaterial.gold => base * 1.12,
        AngryWordsPropMaterial.stone ||
        AngryWordsPropMaterial.magma => base * 1.08,
        AngryWordsPropMaterial.crystal => base * 1.04,
        AngryWordsPropMaterial.water ||
        AngryWordsPropMaterial.foam => allowSmall ? base * 0.92 : base * 0.98,
        AngryWordsPropMaterial.glass ||
        AngryWordsPropMaterial.porcelain ||
        AngryWordsPropMaterial.egg => allowSmall ? base * 0.95 : base * 1.0,
        AngryWordsPropMaterial.sand => allowSmall ? base * 0.97 : base * 1.0,
        AngryWordsPropMaterial.slime => base * 1.05,
        _ => base,
      };
      // Hard floor so early walls never read as "tiny dots".
      final minR = allowSmall ? 5.5 : 9.8;
      return scaled.clamp(minR, 22.0);
    }

    void addAt(Offset pos) {
      final material = loadout.rollMaterial(rng);
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 4.0 + rng.nextDouble() * 12.0;
      final hp = loadout.rollHpFor(material, rng);
      final r =
          rollRadius(material) *
          (hp >= 3
              ? 1.15
              : hp == 2
              ? 1.06
              : 1.0);
      String? skinEmoji;
      final emojiPool = loadout.emojiPropPool;
      if (emojiPool != null && emojiPool.isNotEmpty) {
        skinEmoji = emojiPool[rng.nextInt(emojiPool.length)];
      }
      out.add(
        AngryWordsPropBubble(
          id: id++,
          pos: pos,
          vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          radius: r,
          phase: rng.nextDouble() * math.pi * 2,
          baseSpeed: speed,
          wanderFreq: 0.45 + rng.nextDouble() * 0.9,
          palette: rng.nextInt(12),
          material: material,
          maxHp: hp,
          skinEmoji: skinEmoji,
        ),
      );
    }

    final skipChance = loadout.earlySparseSkipChance;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (skipChance > 0 && rng.nextDouble() < skipChance) continue;
        final xOff = (r.isOdd ? 0.5 : 0.0) * cellW * 0.5;
        final jitter = Offset(
          (rng.nextDouble() - 0.5) * cellW * 0.28,
          (rng.nextDouble() - 0.5) * cellH * 0.28,
        );
        addAt(
          Offset(left + (c + 0.5) * cellW + xOff, top + (r + 0.5) * cellH) +
              jitter,
        );
      }
    }

    final fillers = loadout.profileIndex <= 7
        ? math.min(loadout.effectiveFillers, 4 + loadout.profileIndex)
        : loadout.effectiveFillers;
    for (var i = 0; i < fillers; i++) {
      addAt(
        Offset(
          left + rng.nextDouble() * (right - left),
          top + rng.nextDouble() * (bottom - top),
        ),
      );
    }
    return out;
  }

  AngryWordsLetterTarget? letterAt(Offset local, {double pad = 10}) {
    AngryWordsLetterTarget? best;
    var bestD2 = double.infinity;
    for (final L in letters) {
      if (L.removed) continue;
      final d2 = (L.pos - local).distanceSquared;
      final hitR = L.radius + pad;
      if (d2 <= hitR * hitR && d2 < bestD2) {
        best = L;
        bestD2 = d2;
      }
    }
    return best;
  }

  bool beginLetterDrag(Offset local) {
    if (!isFreePhase || inFlight || aiming) return false;
    final L = letterAt(local);
    if (L == null) return false;
    draggedLetterId = L.letter.id;
    _lastDragPos = local;
    _dragVel = Offset.zero;
    _letterPressStart = local;
    _letterPressMoved = false;
    L.vel = Offset.zero;
    return true;
  }

  void updateLetterDrag(Offset local) {
    final id = draggedLetterId;
    if (id == null) return;
    AngryWordsLetterTarget? L;
    for (final e in letters) {
      if (e.letter.id == id) {
        L = e;
        break;
      }
    }
    if (L == null || L.removed) {
      endLetterDrag();
      return;
    }
    final press = _letterPressStart;
    if (!_letterPressMoved && press != null && (local - press).distance > 12) {
      _letterPressMoved = true;
    }
    // Tap-to-focus: don't move the letter until the finger clearly drags.
    if (!_letterPressMoved) return;

    final prev = _lastDragPos ?? L.pos;
    final delta = local - prev;
    _lastDragPos = local;
    // Smooth velocity estimate for flick + collisions.
    _dragVel = Offset(
      _dragVel.dx * 0.35 + delta.dx * 55,
      _dragVel.dy * 0.35 + delta.dy * 55,
    );
    L.pos = _clampPoint(local, L.radius);
    L.vel = _dragVel;
    _resolveLetterCollisions(dragged: L);
  }

  /// Returns `true` when the gesture was a tap that toggled hard focus.
  bool endLetterDrag() {
    final id = draggedLetterId;
    var wasTapFocus = false;
    if (id != null) {
      if (!_letterPressMoved) {
        focusedLetterId = focusedLetterId == id ? null : id;
        wasTapFocus = true;
        for (final L in letters) {
          if (L.letter.id == id) {
            L.vel = Offset(
              (math.Random(L.letter.id ^ simTime.hashCode).nextDouble() - 0.5) *
                  40,
              (math.Random(L.letter.id * 17 ^ simTime.hashCode).nextDouble() -
                      0.5) *
                  40,
            );
            break;
          }
        }
      } else {
        for (final L in letters) {
          if (L.letter.id != id) continue;
          final spd = _dragVel.distance;
          final maxFlick = 220.0 + windBoost * 80;
          L.vel = spd > maxFlick ? _dragVel * (maxFlick / spd) : _dragVel;
          break;
        }
      }
    }
    draggedLetterId = null;
    _lastDragPos = null;
    _dragVel = Offset.zero;
    _letterPressStart = null;
    _letterPressMoved = false;
    return wasTapFocus;
  }

  void clearLetterFocus() {
    focusedLetterId = null;
    softLockLetterId = null;
    softLockPulse = 0;
  }

  void _pruneDeadFocus() {
    if (focusedLetterId != null && letterById(focusedLetterId) == null) {
      focusedLetterId = null;
    }
    if (softLockLetterId != null && letterById(softLockLetterId) == null) {
      softLockLetterId = null;
    }
  }

  Offset _clampPoint(Offset p, double radius) {
    final b = playBounds;
    return Offset(
      p.dx.clamp(b.left + radius, b.right - radius),
      p.dy.clamp(b.top + radius, b.bottom - radius),
    );
  }

  void beginAim(Offset local) {
    if (!isFreePhase || inFlight) return;
    aiming = true;
    _rawPullPoint = _clampPull(local);
    _refreshTargetLock();
  }

  void updateAim(Offset local) {
    if (!aiming || inFlight) return;
    _rawPullPoint = _clampPull(local);
    _refreshTargetLock();
  }

  /// Aim lock from finger direction; launcher fully tracks the locked letter.
  /// While unlocked, aim stays free (empty space OK) until a letter is
  /// deliberately under the crosshair. Re-lock steal only via closer-in-front.
  void _refreshTargetLock() {
    final raw = _rawPullPoint;
    if (!isFreePhase || !aiming || raw == null) {
      softLockLetterId = null;
      pullPoint = raw;
      return;
    }
    // Aiming at wind button — follow finger, don't track a letter.
    if (windAimActive) {
      softLockLetterId = null;
      softLockPulse = 0;
      pullPoint = raw;
      return;
    }
    final vel = launchVelocityFromPull(raw);
    if (vel == null || vel.distance < 1) {
      softLockLetterId = null;
      pullPoint = raw;
      return;
    }
    final launchDir = vel / vel.distance;

    if (softLockLetterId != null) {
      final locked = letterById(softLockLetterId);
      if (locked == null || !_canKeepTracking(locked)) {
        softLockLetterId = null;
      } else if (_shouldBreakSoftLock(launchDir, locked)) {
        // Light steer off the letter — release into free aim.
        softLockLetterId = null;
      } else {
        // Only steal lock if another letter is clearly closer on the same ray.
        final blocker = _closerLetterInFrontOf(softLockLetterId!);
        if (blocker != null) {
          softLockLetterId = blocker;
        }
      }
    }

    // Free aim: do not magnet to nearby letters; only lock when crosshair
    // is actually on a ball.
    softLockLetterId ??= _selectLetterForLockAcquire(launchDir);

    if (softLockLetterId == null) {
      pullPoint = raw;
      return;
    }
    final locked = letterById(softLockLetterId);
    if (locked == null) {
      softLockLetterId = null;
      pullPoint = raw;
      return;
    }
    // Soft assist: mostly face the letter, but let the finger turn the
    // launcher without a heavy sticky snap.
    final tracked = _pullTowardLetter(raw, softLockLetterId!);
    if (tracked == null) {
      pullPoint = raw;
      return;
    }
    final fingerWeight = _softLockFingerBlend(launchDir, locked);
    pullPoint = Offset.lerp(tracked, raw, fingerWeight) ?? raw;
  }

  bool _canKeepTracking(AngryWordsLetterTarget L) {
    if (L.removed || L.revealT < 0.45) return false;
    final to = L.pos - muzzle;
    // Still roughly above / in front of the slingshot.
    return to.dy < -12 && to.distance > 28 && to.distance < height * 1.25;
  }

  double _aimDotToLetter(Offset launchDir, AngryWordsLetterTarget L) {
    final to = L.pos - muzzle;
    final len = to.distance;
    if (len < 1) return -1;
    final letterDir = to / len;
    return (launchDir.dx * letterDir.dx + launchDir.dy * letterDir.dy).clamp(
      -1.0,
      1.0,
    );
  }

  /// 0 = full letter assist, 1 = full finger aim (light lock feel).
  double _softLockFingerBlend(Offset launchDir, AngryWordsLetterTarget L) {
    final dot = _aimDotToLetter(launchDir, L);
    if (dot >= 0.995) return 0.18;
    if (dot >= 0.985) return 0.42;
    if (dot >= 0.97) return 0.72;
    return 1.0;
  }

  /// Small steer away from the locked letter releases — not a stiff magnet.
  bool _shouldBreakSoftLock(Offset launchDir, AngryWordsLetterTarget L) {
    // ~10° off the letter direction frees the launcher.
    return _aimDotToLetter(launchDir, L) < 0.985;
  }

  /// Nearest letter between the muzzle and [lockedId] on the lock ray.
  int? _closerLetterInFrontOf(int lockedId) {
    final locked = letterById(lockedId);
    if (locked == null) return null;
    final toLocked = locked.pos - muzzle;
    final lockedDist = toLocked.distance;
    if (lockedDist < 1) return null;
    final dir = toLocked / lockedDist;

    int? bestId;
    var bestAlong = lockedDist;
    for (final L in letters) {
      if (L.removed || L.revealT < 0.45) continue;
      if (L.letter.id == lockedId) continue;
      final to = L.pos - muzzle;
      final along = to.dx * dir.dx + to.dy * dir.dy;
      // Must sit clearly closer than the locked letter (in front on the path).
      if (along < 28) continue;
      if (along >= lockedDist - math.max(10.0, locked.radius * 0.65)) {
        continue;
      }
      final closest = muzzle + dir * along;
      final miss = (closest - L.pos).distance;
      if (miss > L.radius + 10) continue;
      if (along < bestAlong) {
        bestAlong = along;
        bestId = L.letter.id;
      }
    }
    return bestId;
  }

  /// Same pull distance as [raw], but launch direction faces [letterId].
  Offset? _pullTowardLetter(Offset raw, int letterId) {
    final L = letterById(letterId);
    if (L == null) return null;
    final power = (raw - muzzle).distance.clamp(minPull, maxPull);
    final t = powerNormFromPullDistance(power);
    final speed =
        minLaunchSpeed + (maxLaunchSpeed - minLaunchSpeed) * t;
    var aim = L.pos;
    for (var i = 0; i < 4; i++) {
      final dist = (aim - muzzle).distance;
      if (dist < 8) return null;
      final flight = dist / speed.clamp(minLaunchSpeed * 0.5, maxLaunchSpeed);
      final drop = 0.5 * gravity * flight * flight;
      aim = L.pos + L.vel * flight - Offset(0, drop);
    }
    final to = aim - muzzle;
    final len = to.distance;
    if (len < 8) return null;
    final launchDir = to / len;
    return _clampPull(muzzle - launchDir * power);
  }

  /// Acquire lock only when the aim ray hits the letter disc (free aim otherwise).
  int? _selectLetterForLockAcquire(Offset launchDir) {
    int? bestId;
    var bestScore = double.infinity;
    for (final L in letters) {
      if (L.removed || L.revealT < 0.45) continue;
      final to = L.pos - muzzle;
      final along = to.dx * launchDir.dx + to.dy * launchDir.dy;
      if (along < 28) continue;
      if (along > height * 1.2) continue;
      final closest = muzzle + launchDir * along;
      final miss = (closest - L.pos).distance;
      // Must point at the ball itself — wide magnet cone removed for freedom.
      final hitR = L.radius + 4;
      if (miss > hitR) continue;
      // Prefer the letter the crosshair is most centered on; nearer on ties.
      final score = miss + along * 0.01;
      if (score < bestScore) {
        bestScore = score;
        bestId = L.letter.id;
      }
    }
    return bestId;
  }

  /// Ballistic launch velocity (keeps [speed]) aimed to hit [letterId].
  /// If another letter lies on that path, live physics hits the blocker first.
  Offset? _guidedVelocityToLetter(int letterId, double speed) {
    final L = letterById(letterId);
    if (L == null || speed < minLaunchSpeed * 0.5) return null;
    final spd = speed.clamp(minLaunchSpeed, maxLaunchSpeed);
    var aim = L.pos;
    for (var i = 0; i < 7; i++) {
      final to = aim - muzzle;
      final dist = to.distance;
      if (dist < 8) return null;
      final flight = dist / spd;
      // Aim above the moving letter to cancel gravity drop (y grows downward).
      final drop = 0.5 * gravity * flight * flight;
      aim = L.pos + L.vel * flight - Offset(0, drop);
    }
    final delta = aim - muzzle;
    final len = delta.distance;
    if (len < 8) return null;
    return delta / len * spd;
  }

  void setGunAim(Offset local) {
    if (!usesGun) return;
    var delta = local - muzzle;
    if (delta.distance < 8) {
      gunAim = const Offset(0, -1);
      return;
    }
    delta = delta / delta.distance;
    // Prefer upward sprays so the gun stays aimed at the wall.
    if (delta.dy > -0.15) {
      delta = Offset(delta.dx.clamp(-0.95, 0.95), -0.55);
      final len = delta.distance;
      if (len > 0.001) delta = delta / len;
    }
    gunAim = delta;
  }

  void setGunTrigger(bool held) {
    if (!usesGun) {
      gunTriggerHeld = false;
      return;
    }
    gunTriggerHeld = held;
  }

  /// Returns true when a round was actually fired (for juice).
  bool tryFireGun() {
    if (!usesGun || fireCooldown > 0) return false;
    fireCooldown = loadout.fireInterval;
    final pellets = loadout.pelletCount.clamp(1, 8);
    final mounts = gunMountCount;
    var any = false;
    for (var mount = 0; mount < mounts; mount++) {
      for (var i = 0; i < pellets; i++) {
        // Multi-barrel uses a fixed fan in _spawnGunBullet; keep jitter mild.
        final scale = pellets == 1
            ? 1.0
            : pellets <= 3
            ? 0.45
            : 0.55 + (i / pellets) * 1.6;
        if (_spawnGunBullet(
          spreadScale: scale,
          pelletIndex: i,
          pelletTotal: pellets,
          mountIndex: mount,
          countTowardJuice: false,
        )) {
          any = true;
        }
      }
    }
    if (!any) return false;
    shotsFiredThisFrame++;
    if (loadout.burstChance > 0 &&
        math.Random((simTime * 1000).round()).nextDouble() <
            loadout.burstChance) {
      for (var mount = 0; mount < mounts; mount++) {
        _spawnGunBullet(
          spreadScale: 1.6,
          pelletIndex: 0,
          pelletTotal: 1,
          mountIndex: mount,
          countTowardJuice: false,
        );
      }
    }
    muzzleFlash = 1;
    gunRecoil = loadout.recoilKick.clamp(0.35, 2.2);
    final punch =
        0.22 * loadout.recoilKick +
        (loadout.splashRadius > 0 ? 0.12 : 0) +
        (loadout.splashRadius >= 55 ? 0.1 : 0) +
        (loadout.homing ? 0.08 : 0) +
        (loadout.pierce >= 2 ? 0.08 : 0) +
        (loadout.element == AngryWordsBulletElement.ice ? 0.04 : 0) +
        (loadout.element == AngryWordsBulletElement.laser && loadout.pierce >= 4
            ? 0.05
            : 0) +
        (loadout.gun == AngryWordsGunKind.railgun ||
                loadout.gun == AngryWordsGunKind.antiMateriel ||
                loadout.gun == AngryWordsGunKind.siege
            ? 0.1
            : 0) +
        (loadout.gun == AngryWordsGunKind.doomsdayMg ? 0.045 : 0);
    screenPunch = (screenPunch + punch).clamp(0.0, 1.0);
    return true;
  }

  bool _spawnGunBullet({
    double spreadScale = 1,
    int pelletIndex = 0,
    int pelletTotal = 1,
    int mountIndex = 0,
    bool countTowardJuice = true,
  }) {
    final rng = math.Random((simTime * 1000 + bullets.length).round());
    var spread = (rng.nextDouble() - 0.5) * loadout.spread * spreadScale;
    // Dual / triple barrels: open fan so pellets don't stick together.
    if (pelletTotal > 1) {
      final mid = (pelletTotal - 1) * 0.5;
      final fanStep = switch (pelletTotal) {
        2 => 0.11,
        3 => 0.12,
        5 => 0.07,
        _ => 0.08,
      };
      spread += (pelletIndex - mid) * fanStep;
    }
    final ca = math.cos(spread);
    final sa = math.sin(spread);
    final dir = Offset(
      gunAim.dx * ca - gunAim.dy * sa,
      gunAim.dx * sa + gunAim.dy * ca,
    );
    final mountMuzzle = muzzleForMount(mountIndex);
    var tip = mountMuzzle + dir * (26 - gunRecoil * 8);
    if (pelletTotal > 1) {
      final side = Offset(-dir.dy, dir.dx);
      final mid = (pelletTotal - 1) * 0.5;
      final gap = switch (pelletTotal) {
        2 => loadout.gun == AngryWordsGunKind.tankCannon ? 18.0 : 16.0,
        3 => 14.0,
        5 => 9.0,
        _ => 11.0,
      };
      tip += side * ((pelletIndex - mid) * gap);
    }

    // Stage 47 Hybrid Tank: barrel 0 = strong laser, barrel 1 = explosive cannon.
    var damage = loadout.bulletDamage;
    var pierceLeft = loadout.pierce;
    var radius = loadout.bulletRadius;
    var speed = loadout.bulletSpeed;
    var element = loadout.element;
    var splashRadius = loadout.splashRadius;
    if (loadout.gun == AngryWordsGunKind.tankCannon &&
        pelletTotal == 2 &&
        pelletIndex == 0) {
      damage = 3;
      pierceLeft = 5;
      radius = 3.4;
      speed = 1900;
      element = AngryWordsBulletElement.laser;
      splashRadius = 0;
    }

    bullets.add(
      AngryWordsBullet(
        pos: tip,
        vel: dir * speed,
        damage: damage,
        pierceLeft: pierceLeft,
        radius: radius,
        element: element,
        splashRadius: splashRadius,
        homing: loadout.homing,
      ),
    );
    if (countTowardJuice) {
      muzzleFlash = 1;
      gunRecoil = loadout.recoilKick.clamp(0.35, 2.2);
      screenPunch = (screenPunch + 0.28 * loadout.recoilKick).clamp(0.0, 1.0);
    }
    return true;
  }

  Offset _clampPull(Offset local) {
    final delta = local - muzzle;
    final dist = delta.distance;
    if (dist <= 0.001) {
      return _keepSlingTipVisible(muzzle + const Offset(0, 28));
    }
    final capped = math.min(dist, maxPull);
    return _keepSlingTipVisible(muzzle + (delta / dist) * capped);
  }

  /// Pull tip = bottom of the slingshot V; must stay inside the board clip.
  Offset _keepSlingTipVisible(Offset tip) {
    final r = ballRadius + slingTipInset;
    return Offset(
      tip.dx.clamp(r, math.max(r, width - r)),
      tip.dy.clamp(r, math.max(r, height - r)),
    );
  }

  bool releaseAim() {
    if (!isFreePhase || !aiming || inFlight) {
      aiming = false;
      _rawPullPoint = null;
      pullPoint = null;
      softLockLetterId = null;
      softLockPulse = 0;
      return false;
    }
    _refreshTargetLock();
    final pull = pullPoint;
    final lockId = softLockLetterId;
    aiming = false;
    windAimActive = false;
    _rawPullPoint = null;
    pullPoint = null;
    softLockPulse = 0;
    softLockLetterId = null;
    if (pull == null) return false;
    var vel = launchVelocityFromPull(pull);
    if (vel == null) return false;
    // Locked shot: steer exactly at the aimed letter (power from pull).
    // A letter in front still wins via normal flight collision.
    if (lockId != null) {
      final guided = _guidedVelocityToLetter(lockId, vel.distance);
      if (guided != null) vel = guided;
    }
    inFlight = true;
    spentShot = false;
    ball = muzzle;
    ballVel = vel;
    return true;
  }

  void cancelAim() {
    aiming = false;
    windAimActive = false;
    _rawPullPoint = null;
    pullPoint = null;
    softLockLetterId = null;
    softLockPulse = 0;
  }

  void resetToCannon() {
    inFlight = false;
    aiming = false;
    windAimActive = false;
    aimCrowdLift = 0;
    _rawPullPoint = null;
    pullPoint = null;
    softLockLetterId = null;
    softLockPulse = 0;
    endLetterDrag();
    ball = muzzle;
    ballVel = Offset.zero;
    hitLetter = null;
    sparkAt = null;
    spentShot = false;
  }

  AngryWordsAimPreview? aimPreview() {
    if (!isFreePhase || !aiming || pullPoint == null || width <= 0) {
      return null;
    }
    final vel0 = launchVelocityFromPull(pullPoint!);
    if (vel0 == null) return null;
    return _simulateTrajectory(
      start: muzzle,
      vel: vel0,
      maxSteps: 420,
      sampleEvery: 2,
    );
  }

  AngryWordsAimPreview _simulateTrajectory({
    required Offset start,
    required Offset vel,
    required int maxSteps,
    required int sampleEvery,
  }) {
    var x = start.dx;
    var y = start.dy;
    var vx = vel.dx;
    var vy = vel.dy;
    final path = <Offset>[Offset(x, y)];
    final dt = 1 / 60 / substeps;

    // Snapshot drifting letters so preview matches live motion.
    final sims = <_LetterSim>[
      for (final L in letters)
        if (!L.removed)
          _LetterSim(
            L.pos,
            L.vel,
            L.radius,
            L.phase,
            L.baseSpeed,
            L.wanderFreq,
            L.letter.id,
          ),
    ];
    var t = simTime;
    var angle = breezeAngle;
    var boost = windBoost;

    for (var step = 0; step < maxSteps; step++) {
      for (var s = 0; s < substeps; s++) {
        t += dt;
        angle += dt * (0.32 + boost * 0.55);
        boost = windHeld
            ? (boost + dt * 2.4).clamp(0.0, 1.0)
            : (boost - dt * 1.6).clamp(0.0, 1.0);
        _stepLetterSims(
          sims,
          dt,
          t: t,
          breezeAngle: angle,
          windBoost: boost,
          bounds: playBounds,
        );

        vy += gravity * dt;
        x += vx * dt;
        y += vy * dt;

        if (x < ballRadius) {
          x = ballRadius;
          vx = vx.abs() * restitution;
        } else if (x > width - ballRadius) {
          x = width - ballRadius;
          vx = -vx.abs() * restitution;
        }
        if (y < ballRadius) {
          y = ballRadius;
          vy = vy.abs() * restitution;
        }

        for (final L in sims) {
          final dx = x - L.pos.dx;
          final dy = y - L.pos.dy;
          final minDist = ballRadius + L.radius;
          if (dx * dx + dy * dy <= minDist * minDist) {
            final impact = Offset(x, y);
            path.add(impact);
            return AngryWordsAimPreview(
              path: path,
              hitsLetter: true,
              predictedLetterId: L.id,
              impact: impact,
            );
          }
        }

        if (y > height - groundYPad + ballRadius) {
          path.add(Offset(x, height - groundYPad + ballRadius));
          return AngryWordsAimPreview(
            path: path,
            hitsLetter: false,
            impact: Offset(x, height - groundYPad + ballRadius),
          );
        }
      }
      if (step % sampleEvery == 0) path.add(Offset(x, y));
    }
    path.add(Offset(x, y));
    return AngryWordsAimPreview(path: path, hitsLetter: false);
  }

  void update(double dt, {required Set<int> selectedIds}) {
    hitLetter = null;
    sparkAt = null;
    simTime += dt;

    muzzleFlash = (muzzleFlash - dt * 9).clamp(0.0, 1.0);
    gunRecoil = (gunRecoil - dt * 7).clamp(0.0, 1.0);
    screenPunch = (screenPunch - dt * 11).clamp(0.0, 1.0);
    if (fireCooldown > 0) {
      fireCooldown = (fireCooldown - dt).clamp(0.0, 2.0);
    }

    // Smooth wind boost while holding the wind button / aiming at it.
    windBoost = windHeld
        ? (windBoost + dt * 3.2).clamp(0.0, 1.0)
        : (windBoost - dt * 1.7).clamp(0.0, 1.0);

    // Ambient breeze slowly turns (faster while boosting).
    breezeAngle += dt * (0.42 + windBoost * 0.85);

    if (chaosTimer > 0) {
      chaosTimer = (chaosTimer - dt).clamp(0.0, 3.0);
    }

    tickLetterShake(dt);
    _stepYolks(dt);

    if (phase == AngryWordsPhase.cage) {
      shotsFiredThisFrame = 0;
      _tickPropSpawn(dt);
      _stepRevealedLetters(dt);
      _stepBarrierProps(dt);
      _growLettersTowardHome(dt);
      if (gunTriggerHeld) {
        tryFireGun();
      }
      _updateBullets(dt);
      if (!propSpawnActive && alivePropCount == 0) {
        _beginFreeing();
      }
      ball = muzzle;
      return;
    }

    if (phase == AngryWordsPhase.freeing) {
      _updateBullets(dt);
      _stepBarrierProps(dt);
      _stepFreeing(dt);
      _growLettersTowardHome(dt);
      ball = muzzle;
      return;
    }

    // Free phase — slingshot letter hunt.
    final wantLift = aiming ? 1.0 : 0.0;
    aimCrowdLift +=
        (wantLift - aimCrowdLift) * math.min(1.0, dt * (aiming ? 3.4 : 2.6));
    if (aimCrowdLift < 0.002) aimCrowdLift = 0;
    _stepLiveLetters(dt);
    for (final L in letters) {
      if (!L.removed && L.revealT < 1) {
        L.revealT = (L.revealT + dt * 2.8).clamp(0.0, 1.0);
      }
    }
    _stepLiveProps(dt);
    _growLettersTowardHome(dt);
    _pruneDeadFocus();
    if (aiming) {
      _refreshTargetLock();
      softLockPulse = softLockLetterId == null
          ? (softLockPulse - dt * 3).clamp(0.0, 1.0)
          : (0.55 + 0.45 * math.sin(simTime * 7));
    } else {
      softLockPulse = focusedLetterId == null
          ? 0
          : (0.4 + 0.25 * math.sin(simTime * 4));
    }

    if (!inFlight) {
      ball = muzzle;
      return;
    }

    final step = dt / substeps;
    for (var i = 0; i < substeps; i++) {
      _integrate(step, selectedIds: selectedIds);
      if (!inFlight || hitLetter != null) break;
    }
  }

  void _stepRevealedLetters(double dt) {
    final bounds = playBounds;
    final wind = windVector * 0.45;
    for (final L in letters) {
      if (L.removed) continue;
      if (L.revealT < 1) {
        L.revealT = (L.revealT + dt * 2.8).clamp(0.0, 1.0);
      }
      _integrateLetter(
        pos: L.pos,
        vel: L.vel,
        radius: L.radius,
        phase: L.phase,
        baseSpeed: L.baseSpeed * 0.75,
        wanderFreq: L.wanderFreq,
        dt: dt,
        t: simTime,
        wind: wind,
        windBoost: windBoost * 0.4,
        bounds: bounds,
        onUpdate: (p, v) {
          L.pos = p;
          L.vel = v * 0.96;
        },
      );
    }
    _resolveLetterCollisions();
    _clampAllLettersInside();
  }

  void _stepBarrierProps(double dt) {
    final bounds = playBounds;
    final wind = windVector * 0.25;
    for (final P in props) {
      if (P.removed || P.spawnT < 0.02) continue;
      if (P.hitFlash > 0) {
        P.hitFlash = (P.hitFlash - dt * 4.5).clamp(0.0, 1.0);
      }
      if (P.freezeT > 0) {
        P.freezeT = (P.freezeT - dt).clamp(0.0, 3.0);
      }
      if (P.stretchT > 0) {
        P.stretchT = (P.stretchT - dt * 7.5).clamp(0.0, 1.0);
        if (P.stretchT <= 0 && P.pendingStretchPop) {
          P.pendingStretchPop = false;
          _popProp(P);
          continue;
        }
      }
      final sticky =
          P.freezeT > 0 ||
          (P.material == AngryWordsPropMaterial.slime && P.hitFlash > 0.2);
      final speedScale = sticky
          ? (P.material == AngryWordsPropMaterial.slime ? 0.35 : 0.22)
          : 1.0;
      _integrateLetter(
        pos: P.pos,
        vel: P.vel,
        radius: P.radius,
        phase: P.phase,
        baseSpeed: P.baseSpeed * speedScale,
        wanderFreq: P.wanderFreq,
        dt: dt,
        t: simTime,
        wind: wind * speedScale,
        windBoost: windBoost * 0.35 * speedScale,
        bounds: bounds,
        onUpdate: (p, v) {
          P.pos = p;
          P.vel = v * (P.freezeT > 0 ? 0.78 : 0.92);
        },
      );
    }
    _resolvePropCollisions();
    _clampAllPropsInside();
    final minY = height * 0.05;
    for (final P in props) {
      if (P.removed) continue;
      if (P.pos.dy < minY + P.radius) {
        P.pos = Offset(P.pos.dx, minY + P.radius);
        if (P.vel.dy < 0) P.vel = Offset(P.vel.dx, -P.vel.dy * 0.4);
      }
    }
  }

  void _beginFreeing() {
    if (phase != AngryWordsPhase.cage) return;
    phase = AngryWordsPhase.freeing;
    gunTriggerHeld = false;
    bullets.clear();
    _freeUnlockTimer = 0;
    cageCombo = 0;
    for (final L in letters) {
      if (L.removed) continue;
      if (L.vel.distance < 8) {
        final angle = L.phase;
        L.vel = Offset(
          math.cos(angle) * L.baseSpeed,
          math.sin(angle) * L.baseSpeed * 0.55 - 30,
        );
      }
      L.revealT = math.max(L.revealT, 0.55);
      // Ensure free-phase target size is the classic home radius.
      L.homeRadius = math.max(
        L.homeRadius,
        homeLetterRadiusForCount(letters.length),
      );
    }
    screenPunch = (screenPunch + 0.35).clamp(0.0, 1.0);
  }

  void _stepFreeing(double dt) {
    _freeUnlockTimer += dt;
    _stepRevealedLetters(dt);
    if (_freeUnlockTimer >= 0.55) {
      phase = AngryWordsPhase.free;
      resetToCannon();
    }
  }

  void _updateBullets(double dt) {
    if (bullets.isEmpty) return;
    final step = dt / substeps;
    for (var s = 0; s < substeps; s++) {
      for (final b in bullets) {
        if (b.dead) continue;
        if (b.homing) _steerBullet(b, step);
        b.pos += b.vel * step;
        if (b.pos.dx < -20 ||
            b.pos.dx > width + 20 ||
            b.pos.dy < -20 ||
            b.pos.dy > height + 20) {
          b.dead = true;
          continue;
        }
        if (yolks.isNotEmpty) _nudgeYolksWithBullet(b);
        _collideBulletWithProps(b);
      }
    }
    bullets.removeWhere((b) => b.dead);
  }

  void _steerBullet(AngryWordsBullet b, double step) {
    AngryWordsPropBubble? best;
    var bestD2 = double.infinity;
    for (final P in props) {
      if (P.removed || P.spawnT < 0.85) continue;
      final d2 = (P.pos - b.pos).distanceSquared;
      if (d2 < bestD2) {
        bestD2 = d2;
        best = P;
      }
    }
    if (best == null) return;
    final to = best.pos - b.pos;
    final len = to.distance;
    if (len < 0.001) return;
    final desired = to / len * b.vel.distance.clamp(400.0, 2000.0);
    b.vel += (desired - b.vel) * (6.2 * step).clamp(0.0, 1.0);
  }

  void _collideBulletWithProps(AngryWordsBullet b) {
    for (final P in props) {
      if (P.removed || P.spawnT < 0.85) continue;
      final delta = b.pos - P.pos;
      final minDist = b.radius + P.radius;
      if (delta.distanceSquared > minDist * minDist) continue;

      sparkAt = P.pos;
      // Stage 50 stone: one impact cracks, next impact shatters — ignore
      // same-volley pellet pile-on while hitFlash is hot.
      final stage50Stone =
          loadout.profileIndex == 49 &&
          P.material == AngryWordsPropMaterial.stone;
      if (stage50Stone && P.hp > 0 && P.hitFlash > 0.4) {
        final d = delta.distance;
        final n = d < 0.001
            ? const Offset(0, -1)
            : Offset(delta.dx / d, delta.dy / d);
        P.vel += n * (_knockbackFor(P.material) * 0.55);
        if (b.pierceLeft > 0) {
          b.pierceLeft--;
          b.pos = P.pos + n * (minDist + 2);
          continue;
        }
        b.dead = true;
        break;
      }
      var dmg = _effectiveBulletDamage(b, P);
      if (stage50Stone) dmg = 1;
      P.hp -= dmg;
      if (b.element == AngryWordsBulletElement.ice) {
        final freezeSec = loadout.gun == AngryWordsGunKind.freezeRay
            ? 1.9
            : 1.25;
        P.freezeT = math.max(P.freezeT, freezeSec);
      }
      final splash = b.splashRadius > 0
          ? b.splashRadius
          : (b.element == AngryWordsBulletElement.fire ? 28.0 : 0.0);
      if (splash > 0) {
        _splashAt(
          P.pos,
          originId: P.id,
          damage: b.element == AngryWordsBulletElement.explosive ? 2 : 1,
          radius: splash,
          freeze: b.element == AngryWordsBulletElement.ice,
          burnBonus:
              b.element == AngryWordsBulletElement.fire ||
              b.element == AngryWordsBulletElement.explosive,
        );
      }

      final steamyHit =
          P.material == AngryWordsPropMaterial.magma &&
          b.element == AngryWordsBulletElement.ice;

      if (P.hp > 0) {
        P.hitFlash = 1;
        if (P.material == AngryWordsPropMaterial.slime) {
          P.freezeT = math.max(P.freezeT, 0.85);
        }
        final d = delta.distance;
        final n = d < 0.001
            ? const Offset(0, -1)
            : Offset(delta.dx / d, delta.dy / d);
        final kb = _knockbackFor(P.material);
        P.vel += n * kb + b.vel * 0.04;
        final canPierceAlive =
            b.element == AngryWordsBulletElement.laser && b.pierceLeft > 0;
        if (!canPierceAlive) {
          b.dead = true;
        } else {
          b.pierceLeft--;
          b.pos = P.pos + n * (minDist + 2);
        }
        screenPunch = (screenPunch + 0.12).clamp(0.0, 1.0);
        break;
      }

      if (P.material == AngryWordsPropMaterial.rubber &&
          !P.pendingStretchPop &&
          P.stretchT <= 0) {
        P.hp = 1;
        P.stretchT = 1;
        P.pendingStretchPop = true;
        P.hitFlash = 1;
        final d = delta.distance;
        final n = d < 0.001
            ? const Offset(0, -1)
            : Offset(delta.dx / d, delta.dy / d);
        P.vel += n * (_knockbackFor(P.material) * 1.35) + b.vel * 0.05;
        b.dead = true;
        screenPunch = (screenPunch + 0.18).clamp(0.0, 1.0);
        break;
      }

      _popProp(P, steamy: steamyHit);
      if (b.pierceLeft > 0 && b.element != AngryWordsBulletElement.explosive) {
        b.pierceLeft--;
        final d = delta.distance;
        final n = d < 0.001
            ? const Offset(0, -1)
            : Offset(delta.dx / d, delta.dy / d);
        b.pos = P.pos + n * (minDist + 2);
        continue;
      }
      b.dead = true;
      break;
    }
  }

  int _effectiveBulletDamage(AngryWordsBullet b, AngryWordsPropBubble P) {
    var d = b.damage;
    if (b.element == AngryWordsBulletElement.ice) {
      if (P.material == AngryWordsPropMaterial.ice) d += 1;
      if (P.material == AngryWordsPropMaterial.magma) d += 2;
      if (P.material == AngryWordsPropMaterial.slime) d += 1;
    }
    if (b.element == AngryWordsBulletElement.fire ||
        b.element == AngryWordsBulletElement.explosive) {
      if (P.material == AngryWordsPropMaterial.ice) d += 2;
      if (P.material == AngryWordsPropMaterial.wood) d += 1;
      if (P.material == AngryWordsPropMaterial.foam) d += 1;
      if (P.material == AngryWordsPropMaterial.magma) d += 1;
    }
    if (P.material == AngryWordsPropMaterial.glass ||
        P.material == AngryWordsPropMaterial.porcelain ||
        P.material == AngryWordsPropMaterial.egg) {
      d = math.max(d, 1);
    }
    if (P.material == AngryWordsPropMaterial.crystal && d < 2) {
      d = math.max(d, 1);
    }
    if ((P.material == AngryWordsPropMaterial.metal ||
            P.material == AngryWordsPropMaterial.gold) &&
        b.element == AngryWordsBulletElement.normal &&
        d < 2) {
      d = 1;
    }
    if (P.material == AngryWordsPropMaterial.metal &&
        (b.element == AngryWordsBulletElement.explosive || b.damage >= 3)) {
      d += 1;
    }
    if (P.material == AngryWordsPropMaterial.metal &&
        loadout.gun == AngryWordsGunKind.antiMateriel) {
      d += 1;
    }
    if (P.material == AngryWordsPropMaterial.metal &&
        loadout.gun == AngryWordsGunKind.rpg) {
      d += 1;
    }
    if (P.material == AngryWordsPropMaterial.foam ||
        P.material == AngryWordsPropMaterial.sand) {
      d = math.max(d, 1);
    }
    return d;
  }

  double _knockbackFor(AngryWordsPropMaterial material) {
    return switch (material) {
      AngryWordsPropMaterial.rubber => 175,
      AngryWordsPropMaterial.water => 150,
      AngryWordsPropMaterial.foam => 130,
      AngryWordsPropMaterial.slime => 95,
      AngryWordsPropMaterial.sand => 100,
      AngryWordsPropMaterial.candy || AngryWordsPropMaterial.plastic => 90,
      AngryWordsPropMaterial.wood => 80,
      AngryWordsPropMaterial.ice => 70,
      AngryWordsPropMaterial.porcelain || AngryWordsPropMaterial.glass => 52,
      AngryWordsPropMaterial.egg => 58,
      AngryWordsPropMaterial.crystal => 48,
      AngryWordsPropMaterial.stone || AngryWordsPropMaterial.magma => 40,
      AngryWordsPropMaterial.gold => 34,
      AngryWordsPropMaterial.metal => 26,
    };
  }

  void _splashAt(
    Offset at, {
    required int originId,
    required int damage,
    required double radius,
    bool freeze = false,
    bool burnBonus = false,
  }) {
    for (final P in props) {
      if (P.removed || P.id == originId) continue;
      if ((P.pos - at).distanceSquared > radius * radius) continue;
      var d = damage;
      if (burnBonus) {
        if (P.material == AngryWordsPropMaterial.ice) d += 1;
        if (P.material == AngryWordsPropMaterial.wood) d += 1;
        if (P.material == AngryWordsPropMaterial.foam) d += 1;
        if (P.material == AngryWordsPropMaterial.magma) d += 1;
      }
      if (freeze) {
        P.freezeT = math.max(P.freezeT, 1.0);
        if (P.material == AngryWordsPropMaterial.magma) d += 1;
      }
      P.hp -= d;
      P.hitFlash = 1;
      if (P.material == AngryWordsPropMaterial.slime && P.hp > 0) {
        P.freezeT = math.max(P.freezeT, 0.7);
      }
      if (P.hp <= 0) {
        _popProp(
          P,
          steamy: freeze && P.material == AngryWordsPropMaterial.magma,
        );
      }
    }
  }

  void _popProp(AngryWordsPropBubble P, {bool steamy = false}) {
    if (P.removed) return;
    P.removed = true;
    P.pendingStretchPop = false;
    final cargo = P.cargo;
    P.cargo = null;
    if (phase == AngryWordsPhase.cage) {
      cageCombo += 1;
      screenPunch = (screenPunch + (cargo != null ? 0.42 : 0.28)).clamp(
        0.0,
        1.0,
      );
    } else {
      screenPunch = (screenPunch + 0.16).clamp(0.0, 1.0);
    }
    if (cargo != null && phase == AngryWordsPhase.cage) {
      _revealLetterFromProp(cargo, P);
    }
    var steam = steamy;
    if (P.material == AngryWordsPropMaterial.water) {
      steam = _douseNearbyMagma(P.pos) || steam;
    }
    if (P.material == AngryWordsPropMaterial.egg) {
      _spawnYolkFromEgg(P);
    }
    _pendingPropPops.add(
      AngryWordsPropPop(
        at: P.pos,
        palette: P.palette,
        radius: P.radius,
        material: P.material,
        revealedChar: cargo?.char,
        steamy: steam || P.material == AngryWordsPropMaterial.magma && steamy,
      ),
    );
  }

  void _spawnYolkFromEgg(AngryWordsPropBubble P) {
    spillYolkAt(P.pos, fromRadius: P.radius, seed: P.id);
  }

  /// Spill a yolk puddle (cracked letter-egg or wall egg).
  void spillYolkAt(Offset at, {double fromRadius = 12, int seed = 0}) {
    final rng = math.Random(seed ^ (simTime * 1000).round() ^ at.dx.round());
    final r = (fromRadius * 0.55).clamp(7.0, 14.0);
    yolks.add(
      AngryWordsYolkBlob(
        pos: at,
        vel: Offset((rng.nextDouble() - 0.5) * 140, 40 + rng.nextDouble() * 80),
        radius: r,
      ),
    );
  }

  void _stepYolks(double dt) {
    if (yolks.isEmpty) return;
    final floor = yolkFloorY;
    final g = gravity * 0.92;
    for (final Y in yolks) {
      if (Y.removed) continue;
      if (!Y.onFloor) {
        Y.vel = Offset(Y.vel.dx * math.exp(-dt * 0.35), Y.vel.dy + g * dt);
        Y.pos += Y.vel * dt;
        final land = floor - Y.radius * 0.35;
        if (Y.pos.dy >= land) {
          Y.pos = Offset(Y.pos.dx, land);
          Y.vel = Offset(Y.vel.dx * 0.72, 0);
          Y.onFloor = true;
        }
      } else {
        // Slide on the floor — soft friction; bullets / wind nudge the pool.
        final windX = windVector.dx * 0.12;
        Y.vel = Offset((Y.vel.dx + windX * dt) * math.exp(-dt * 1.35), 0);
        Y.pos = Offset(Y.pos.dx + Y.vel.dx * dt, floor - Y.radius * 0.35);
      }
      final minX = Y.radius + 4;
      final maxX = width - Y.radius - 4;
      if (Y.pos.dx < minX) {
        Y.pos = Offset(minX, Y.pos.dy);
        Y.vel = Offset(Y.vel.dx.abs() * 0.55, Y.vel.dy);
      } else if (Y.pos.dx > maxX) {
        Y.pos = Offset(maxX, Y.pos.dy);
        Y.vel = Offset(-Y.vel.dx.abs() * 0.55, Y.vel.dy);
      }
    }
    _mergeYolks();
    yolks.removeWhere((Y) => Y.removed);
  }

  void _mergeYolks() {
    for (var i = 0; i < yolks.length; i++) {
      final a = yolks[i];
      if (a.removed) continue;
      for (var j = i + 1; j < yolks.length; j++) {
        final b = yolks[j];
        if (b.removed) continue;
        final dist = (a.pos - b.pos).distance;
        final mergeR = (a.radius + b.radius) * 0.78;
        if (dist > mergeR) continue;
        final areaA = a.radius * a.radius;
        final areaB = b.radius * b.radius;
        final total = areaA + areaB;
        final wA = areaA / total;
        a.pos = Offset(
          a.pos.dx * wA + b.pos.dx * (1 - wA),
          a.pos.dy * wA + b.pos.dy * (1 - wA),
        );
        a.vel = Offset(
          a.vel.dx * wA + b.vel.dx * (1 - wA),
          a.vel.dy * wA + b.vel.dy * (1 - wA),
        );
        a.radius = math.sqrt(total).clamp(7.0, 36.0);
        a.onFloor = a.onFloor || b.onFloor;
        if (a.onFloor) {
          a.pos = Offset(a.pos.dx, yolkFloorY - a.radius * 0.35);
          a.vel = Offset(a.vel.dx, 0);
        }
        b.removed = true;
      }
    }
  }

  void _nudgeYolksWithBullet(AngryWordsBullet b) {
    if (yolks.isEmpty) return;
    for (final Y in yolks) {
      if (Y.removed) continue;
      final d = (Y.pos - b.pos).distance;
      if (d > Y.radius + b.radius + 4) continue;
      final n = d < 0.1 ? const Offset(1, 0) : (Y.pos - b.pos) / d;
      Y.vel += Offset(n.dx * 220, Y.onFloor ? 0 : n.dy * 80);
      if (Y.onFloor) {
        Y.vel = Offset(Y.vel.dx.clamp(-420.0, 420.0), 0);
      }
    }
  }

  /// Water pop cools nearby magma — extra damage + steam juice.
  bool _douseNearbyMagma(Offset at) {
    var any = false;
    const r = 52.0;
    for (final P in props) {
      if (P.removed || P.material != AngryWordsPropMaterial.magma) continue;
      if ((P.pos - at).distanceSquared > r * r) continue;
      P.hp -= 1;
      P.hitFlash = 1;
      P.freezeT = math.max(P.freezeT, 0.45);
      any = true;
      if (P.hp <= 0) _popProp(P, steamy: true);
    }
    return any;
  }

  void _revealLetterFromProp(LetterInstance cargo, AngryWordsPropBubble P) {
    for (final L in letters) {
      if (L.letter.id == cargo.id) return;
    }
    final rng = math.Random(cargo.id ^ (simTime * 1000).round());
    final angle = -math.pi * 0.5 + (rng.nextDouble() - 0.5) * 1.2;
    final speed = 90.0 + rng.nextDouble() * 70.0;
    final stageCount = math.max(1, remainingCargoCount + letters.length + 1);
    final home = homeLetterRadiusForCount(stageCount);
    // Smaller while filler orbs remain; grows back to [home] when cleared.
    final cageR = math.min(home * 0.72, math.max(14.0, P.radius * 0.88));
    final tintIndex = P.cargoTintIndex ?? _nextUniqueLetterTintIndex();
    letters.add(
      AngryWordsLetterTarget(
        letter: cargo,
        pos: P.pos,
        vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed - 40),
        radius: cageR,
        homeRadius: home,
        phase: rng.nextDouble() * math.pi * 2,
        baseSpeed: 72 + rng.nextDouble() * 48,
        wanderFreq: 0.9 + rng.nextDouble() * 0.8,
        tintIndex: tintIndex,
        revealT: 0,
      ),
    );
  }

  int _nextUniqueLetterTintIndex() {
    const tintCount = 24;
    final used = <int>{
      for (final L in letters)
        if (!L.removed) L.tintIndex % tintCount,
      for (final P in props)
        if (!P.removed && P.cargoTintIndex != null)
          P.cargoTintIndex! % tintCount,
    };
    for (var i = 0; i < tintCount; i++) {
      if (!used.contains(i)) return i;
    }
    return letters.length % tintCount;
  }

  /// After filler orbs are gone (or free phase), restore classic letter size.
  void _growLettersTowardHome(double dt) {
    final fillersGone = aliveFillerCount == 0 || !isCagePhase;
    if (!fillersGone) return;
    for (final L in letters) {
      if (L.removed) continue;
      if (L.radius >= L.homeRadius - 0.05) {
        L.radius = L.homeRadius;
        continue;
      }
      final t = (dt * 5.2).clamp(0.0, 1.0);
      L.radius += (L.homeRadius - L.radius) * t;
    }
  }

  void _stepLiveLetters(double dt) {
    final bounds = letterRoamBounds;
    final wind = windVector;
    final dragId = draggedLetterId;
    final inChaos = chaosTimer > 0;
    final chaosLeft = chaosTimer;
    final lift = aimCrowdLift;
    for (final L in letters) {
      if (L.removed) continue;
      // Dragged letter is moved by the finger — skip wander.
      if (dragId != null && L.letter.id == dragId) continue;
      if (inChaos) {
        // Blast → gradual coast; damping rises as chaosTimer runs out.
        _integrateChaosLetter(
          letter: L,
          dt: dt,
          bounds: bounds,
          chaosLeft: chaosLeft,
        );
      } else {
        _integrateLetter(
          pos: L.pos,
          vel: L.vel,
          radius: L.radius,
          phase: L.phase,
          baseSpeed: L.baseSpeed,
          wanderFreq: L.wanderFreq,
          dt: dt,
          t: simTime,
          wind: wind,
          windBoost: windBoost,
          bounds: bounds,
          crowdLift: lift,
          onUpdate: (p, v) {
            L.pos = p;
            L.vel = v;
          },
        );
      }
    }
    _resolveLetterCollisions();
    _resolveLetterCollisions();
  }

  void _stepLiveProps(double dt) {
    final bounds = playBounds;
    final wind = windVector;
    for (final P in props) {
      if (P.removed) continue;
      _integrateLetter(
        pos: P.pos,
        vel: P.vel,
        radius: P.radius,
        phase: P.phase,
        baseSpeed: P.baseSpeed,
        wanderFreq: P.wanderFreq,
        dt: dt,
        t: simTime,
        wind: wind,
        windBoost: windBoost,
        bounds: bounds,
        onUpdate: (p, v) {
          P.pos = p;
          P.vel = v;
        },
      );
    }
    _resolvePropCollisions();
    _clampAllPropsInside();
  }

  void _integrateChaosLetter({
    required AngryWordsLetterTarget letter,
    required double dt,
    required Rect bounds,
    required double chaosLeft,
  }) {
    var nextPos = letter.pos + letter.vel * dt;
    var nextVel = letter.vel;

    // 1 at the start of chaos, 0 when timer ends — ease into a soft stop.
    final wild = (chaosLeft / 2.6).clamp(0.0, 1.0);
    final settle = 1.0 - wild;
    // Early: almost no friction; late: strong coast-down (not an instant halt).
    final dampPerSec = 0.12 + settle * settle * 3.4;
    nextVel *= math.exp(-dampPerSec * dt);

    // Blend toward normal roam speed near the end so the handoff isn't a snap.
    if (settle > 0.25) {
      final wanderAngle = letter.phase + simTime * letter.wanderFreq;
      final wander = Offset(
        math.cos(wanderAngle) * 1.35,
        math.sin(wanderAngle * 0.72) * 0.75,
      );
      final cruise = wander * letter.baseSpeed;
      final blend = ((settle - 0.25) / 0.75).clamp(0.0, 1.0);
      final lerpT = math.min(1.0, dt * (1.2 + blend * 2.8));
      nextVel = Offset(
        nextVel.dx + (cruise.dx - nextVel.dx) * lerpT * blend,
        nextVel.dy + (cruise.dy - nextVel.dy) * lerpT * blend,
      );
    }

    final radius = letter.radius;
    final minX = bounds.left + radius;
    final maxX = bounds.right - radius;
    final minY = bounds.top + radius;
    final maxY = bounds.bottom - radius;

    // Wall kick fades as we settle so they don't re-accelerate at the end.
    final wallKick = 8.0 + wild * 32.0;
    final wallRest = 0.88 + wild * 0.07;
    if (nextPos.dx < minX) {
      nextPos = Offset(minX, nextPos.dy);
      nextVel = Offset(nextVel.dx.abs() * wallRest + wallKick, nextVel.dy);
    } else if (nextPos.dx > maxX) {
      nextPos = Offset(maxX, nextPos.dy);
      nextVel = Offset(-nextVel.dx.abs() * wallRest - wallKick, nextVel.dy);
    }
    if (nextPos.dy < minY) {
      nextPos = Offset(nextPos.dx, minY);
      nextVel = Offset(nextVel.dx, nextVel.dy.abs() * wallRest + wallKick);
    } else if (nextPos.dy > maxY) {
      nextPos = Offset(nextPos.dx, maxY);
      nextVel = Offset(nextVel.dx, -nextVel.dy.abs() * wallRest - wallKick);
    }

    final maxSpd = 180.0 + wild * 340.0;
    final spd = nextVel.distance;
    if (spd > maxSpd) {
      nextVel = nextVel * (maxSpd / spd);
    }

    letter.pos = nextPos;
    letter.vel = nextVel;
  }

  void _stepLetterSims(
    List<_LetterSim> sims,
    double dt, {
    required double t,
    required double breezeAngle,
    required double windBoost,
    required Rect bounds,
  }) {
    final strength =
        ambientWindPx + boostWindPx * windBoost + 6 * math.sin(t * 0.55);
    final wind =
        Offset(math.cos(breezeAngle), math.sin(breezeAngle)) * strength;
    for (final L in sims) {
      _integrateLetter(
        pos: L.pos,
        vel: L.vel,
        radius: L.radius,
        phase: L.phase,
        baseSpeed: L.baseSpeed,
        wanderFreq: L.wanderFreq,
        dt: dt,
        t: t,
        wind: wind,
        windBoost: windBoost,
        bounds: bounds,
        onUpdate: (p, v) {
          L.pos = p;
          L.vel = v;
        },
      );
    }
  }

  void _integrateLetter({
    required Offset pos,
    required Offset vel,
    required double radius,
    required double phase,
    required double baseSpeed,
    required double wanderFreq,
    required double dt,
    required double t,
    required Offset wind,
    required double windBoost,
    required Rect bounds,
    required void Function(Offset pos, Offset vel) onUpdate,
    double crowdLift = 0,
  }) {
    // Continuous wander: strong left/right roam across the board.
    final wanderAngle = phase + t * wanderFreq;
    // Prefer horizontal motion so balls cross the full width.
    final wander = Offset(
      math.cos(wanderAngle) * (1.55 + crowdLift * 0.25),
      math.sin(wanderAngle * 0.72) * (0.95 + crowdLift * 0.2),
    );
    final targetSpeed = baseSpeed * (1.38 + windBoost * 2.15);
    var desired = wander * targetSpeed + wind * (0.85 + windBoost * 0.7);

    // While aiming: lean upward, circulate mid-band, stay clear of slingshot.
    if (crowdLift > 0.01) {
      final midY = (bounds.top + bounds.bottom) * 0.5;
      final belowMid = ((pos.dy - midY) / math.max(28.0, bounds.height * 0.45))
          .clamp(0.0, 1.0);
      desired += Offset(0, -baseSpeed * (0.22 + 0.38 * belowMid) * crowdLift);
      final ceilBand = bounds.top + radius + bounds.height * 0.2;
      if (pos.dy < ceilBand) {
        desired += Offset(0, baseSpeed * 0.65 * crowdLift);
      }
      final floorBand = bounds.bottom - radius - bounds.height * 0.14;
      if (pos.dy > floorBand) {
        desired += Offset(0, -baseSpeed * 0.9 * crowdLift);
      }
      // Extra clearance from the muzzle itself.
      final toMuzzle = pos - muzzle;
      final muzzleClear = 118.0 + crowdLift * 36;
      if (toMuzzle.distance < muzzleClear && toMuzzle.distance > 1) {
        final n = toMuzzle / toMuzzle.distance;
        desired += n * baseSpeed * 0.85 * crowdLift;
        desired += const Offset(0, -1) * baseSpeed * 0.35 * crowdLift;
      }
    }

    // Gentle steering toward desired velocity.
    // If still fast after a wrong-hit blast, ease in slowly (no sudden stop).
    final spdNow = vel.distance;
    final cruise = baseSpeed * (1.38 + windBoost * 2.15);
    final steerRate = spdNow > cruise * 1.8 ? 1.35 : 3.8;
    var nextVel = Offset(
      vel.dx + (desired.dx - vel.dx) * math.min(1.0, dt * steerRate),
      vel.dy + (desired.dy - vel.dy) * math.min(1.0, dt * steerRate),
    );

    // Soft bob so motion never looks linear-only.
    nextVel += Offset(
      math.sin(t * 1.55 + phase) * (16 + windBoost * 28) * dt * 24,
      math.cos(t * 1.2 + phase * 1.4) * (12 + windBoost * 22) * dt * 24,
    );

    var nextPos = pos + nextVel * dt;

    final minX = bounds.left + radius;
    final maxX = bounds.right - radius;
    final minY = bounds.top + radius;
    final maxY = bounds.bottom - radius;

    if (nextPos.dx < minX) {
      nextPos = Offset(minX, nextPos.dy);
      nextVel = Offset(nextVel.dx.abs() * 0.92 + 18, nextVel.dy);
    } else if (nextPos.dx > maxX) {
      nextPos = Offset(maxX, nextPos.dy);
      nextVel = Offset(-nextVel.dx.abs() * 0.92 - 18, nextVel.dy);
    }
    if (nextPos.dy < minY) {
      nextPos = Offset(nextPos.dx, minY);
      // Soft peel off the ceiling — keep circulating, don't stick.
      nextVel = Offset(
        nextVel.dx + math.sin(t * 2.1 + phase) * 18,
        nextVel.dy.abs() * 0.78 + 18 + crowdLift * 22,
      );
    } else if (nextPos.dy > maxY) {
      nextPos = Offset(nextPos.dx, maxY);
      nextVel = Offset(
        nextVel.dx,
        -nextVel.dy.abs() * 0.92 - 14 - crowdLift * 20,
      );
    }

    // Higher normal speed + room for wind / flick / wrong-hit chaos.
    final maxSpd = chaosTimer > 0 ? 380.0 : (105 + windBoost * 145);
    final spd = nextVel.distance;
    if (spd > maxSpd) {
      nextVel = nextVel * (maxSpd / spd);
    }

    onUpdate(nextPos, nextVel);
  }

  /// Circle collisions + soft repulsion so balls push apart and don't stick.
  /// Drawn [AngryWordsLetterTarget.radius] is unchanged — only contact gap grows.
  void _resolveLetterCollisions({AngryWordsLetterTarget? dragged}) {
    for (var i = 0; i < letters.length; i++) {
      final a = letters[i];
      if (a.removed) continue;
      for (var j = i + 1; j < letters.length; j++) {
        final b = letters[j];
        if (b.removed) continue;
        final delta = b.pos - a.pos;
        final hardMin = a.radius + b.radius + letterSeparationPad;
        final softMin = hardMin + letterSoftRepelReach;
        final d2 = delta.distanceSquared;
        if (d2 >= softMin * softMin) continue;

        final d = d2 < 0.0001 ? 0.001 : math.sqrt(d2);
        var n = d2 < 0.0001
            ? Offset(
                (a.letter.id - b.letter.id).isEven ? 1.0 : -1.0,
                (a.letter.id + b.letter.id) % 3 == 0 ? 1.0 : -1.0,
              )
            : Offset(delta.dx / d, delta.dy / d);
        final nLen = n.distance;
        if (nLen > 0.001) {
          n = Offset(n.dx / nLen, n.dy / nLen);
        }

        final aIsDrag = dragged != null && a.letter.id == dragged.letter.id;
        final bIsDrag = dragged != null && b.letter.id == dragged.letter.id;

        if (d < hardMin) {
          final overlap = hardMin - d;
          if (aIsDrag && !bIsDrag) {
            b.pos += n * overlap;
          } else if (bIsDrag && !aIsDrag) {
            a.pos -= n * overlap;
          } else {
            a.pos -= n * (overlap * 0.5);
            b.pos += n * (overlap * 0.5);
          }

          final rv = Offset(b.vel.dx - a.vel.dx, b.vel.dy - a.vel.dy);
          final velAlong = rv.dx * n.dx + rv.dy * n.dy;

          if (aIsDrag || bIsDrag) {
            final knock = (_dragVel.distance.clamp(40.0, 260.0)) * 0.85;
            final knockVel = n * knock;
            if (aIsDrag) {
              b.vel += knockVel;
              b.vel += _dragVel * 0.55;
            } else {
              a.vel -= knockVel;
              a.vel += _dragVel * 0.55;
            }
            continue;
          }

          if (velAlong < 12) {
            final impulse =
                -(1 + letterBounce) * math.min(velAlong, 0) / 2 +
                (12 - velAlong) * 0.35;
            final impulseVec = n * impulse;
            a.vel -= impulseVec;
            b.vel += impulseVec;
          }
        } else {
          final t = (1.0 - (d - hardMin) / letterSoftRepelReach).clamp(
            0.0,
            1.0,
          );
          final push = 22.0 * t * t;
          if (aIsDrag && !bIsDrag) {
            b.vel += n * push;
          } else if (bIsDrag && !aIsDrag) {
            a.vel -= n * push;
          } else if (!aIsDrag && !bIsDrag) {
            a.vel -= n * push;
            b.vel += n * push;
          }
        }
      }
    }
    _clampAllLettersInside();
  }

  void _clampAllLettersInside() {
    final bounds = letterRoamBounds;
    for (final L in letters) {
      if (L.removed) continue;
      L.pos = Offset(
        L.pos.dx.clamp(bounds.left + L.radius, bounds.right - L.radius),
        L.pos.dy.clamp(bounds.top + L.radius, bounds.bottom - L.radius),
      );
    }
  }

  void _clampAllPropsInside() {
    final bounds = playBounds;
    for (final P in props) {
      if (P.removed) continue;
      P.pos = Offset(
        P.pos.dx.clamp(bounds.left + P.radius, bounds.right - P.radius),
        P.pos.dy.clamp(bounds.top + P.radius, bounds.bottom - P.radius),
      );
    }
  }

  /// Soft separation between props, and between props and letter balls.
  void _resolvePropCollisions() {
    for (var i = 0; i < props.length; i++) {
      final a = props[i];
      if (a.removed) continue;
      for (var j = i + 1; j < props.length; j++) {
        final b = props[j];
        if (b.removed) continue;
        _separateCircles(
          getPosA: () => a.pos,
          setPosA: (p) => a.pos = p,
          getVelA: () => a.vel,
          setVelA: (v) => a.vel = v,
          getPosB: () => b.pos,
          setPosB: (p) => b.pos = p,
          getVelB: () => b.vel,
          setVelB: (v) => b.vel = v,
          radiusA: a.radius,
          radiusB: b.radius,
          seed: a.id - b.id,
        );
      }
      for (final L in letters) {
        if (L.removed) continue;
        _separateCircles(
          getPosA: () => a.pos,
          setPosA: (p) => a.pos = p,
          getVelA: () => a.vel,
          setVelA: (v) => a.vel = v,
          getPosB: () => L.pos,
          setPosB: (p) => L.pos = p,
          getVelB: () => L.vel,
          setVelB: (v) => L.vel = v,
          radiusA: a.radius,
          radiusB: L.radius,
          seed: a.id - L.letter.id,
        );
      }
    }
  }

  void _separateCircles({
    required Offset Function() getPosA,
    required void Function(Offset) setPosA,
    required Offset Function() getVelA,
    required void Function(Offset) setVelA,
    required Offset Function() getPosB,
    required void Function(Offset) setPosB,
    required Offset Function() getVelB,
    required void Function(Offset) setVelB,
    required double radiusA,
    required double radiusB,
    required int seed,
  }) {
    final aPos = getPosA();
    final bPos = getPosB();
    final delta = bPos - aPos;
    final hardMin = radiusA + radiusB + letterSeparationPad * 0.65;
    final d2 = delta.distanceSquared;
    if (d2 >= hardMin * hardMin) return;
    final n = d2 < 0.0001
        ? Offset(seed.isEven ? 1.0 : -1.0, seed % 3 == 0 ? 1.0 : -1.0)
        : Offset(delta.dx / math.sqrt(d2), delta.dy / math.sqrt(d2));
    final d = d2 < 0.0001 ? 0.001 : math.sqrt(d2);
    final overlap = hardMin - d;
    setPosA(aPos - n * (overlap * 0.5));
    setPosB(bPos + n * (overlap * 0.5));
    final aVel = getVelA();
    final bVel = getVelB();
    final rv = Offset(bVel.dx - aVel.dx, bVel.dy - aVel.dy);
    final velAlong = rv.dx * n.dx + rv.dy * n.dy;
    if (velAlong < 0) {
      final impulse = n * (-(1 + letterBounce) * velAlong * 0.45);
      setVelA(aVel - impulse);
      setVelB(bVel + impulse);
    }
  }

  void _integrate(double dt, {required Set<int> selectedIds}) {
    ballVel = Offset(ballVel.dx, ballVel.dy + gravity * dt);
    ball += ballVel * dt;

    if (ball.dx - ballRadius < 0) {
      ball = Offset(ballRadius, ball.dy);
      ballVel = Offset(ballVel.dx.abs() * restitution, ballVel.dy);
    } else if (ball.dx + ballRadius > width) {
      ball = Offset(width - ballRadius, ball.dy);
      ballVel = Offset(-ballVel.dx.abs() * restitution, ballVel.dy);
    }
    if (ball.dy - ballRadius < 0) {
      ball = Offset(ball.dx, ballRadius);
      ballVel = Offset(ballVel.dx, ballVel.dy.abs() * restitution);
    }

    if (ball.dy > height - groundYPad + ballRadius * 0.5) {
      resetToCannon();
      return;
    }

    if (ball.dx < -40 || ball.dx > width + 40 || ball.dy < -80) {
      resetToCannon();
      return;
    }

    // Candy pops first — shot keeps flying so chains feel great.
    _collideProps();
    _collideLetters(selectedIds);
  }

  void _collideProps() {
    for (final P in props) {
      if (P.removed) continue;
      final delta = ball - P.pos;
      final minDist = ballRadius + P.radius;
      if (delta.distanceSquared > minDist * minDist) continue;

      sparkAt = P.pos;
      _popProp(P);

      // Soft bounce + keep most speed so one shot can smash several.
      final d = delta.distance;
      final n = d < 0.001
          ? const Offset(0, -1)
          : Offset(delta.dx / d, delta.dy / d);
      final along = ballVel.dx * n.dx + ballVel.dy * n.dy;
      if (along < 0) {
        ballVel -= n * (along * 1.35);
      }
      ballVel = ballVel * 0.9 + n * 90;
      ball = P.pos + n * (minDist + 2);
    }
  }

  void _collideLetters(Set<int> selectedIds) {
    if (spentShot) return;
    for (final L in letters) {
      if (L.removed) continue;
      final c = L.pos;
      final delta = ball - c;
      final minDist = ballRadius + L.radius;
      if (delta.distanceSquared > minDist * minDist) continue;

      sparkAt = c;
      spentShot = true;
      lastShotImpactVel = ballVel;
      lastShotPowerNorm = _powerNormFromSpeed(ballVel.distance);
      final already = selectedIds.contains(L.letter.id);
      if (!already) {
        hitLetter = L.letter;
        // Do not remove yet — board explodes only if letter matches
        // the active slot order; wrong hits keep the bubble.
      }
      ballVel = Offset.zero;
      inFlight = false;
      ball = c;
      break;
    }
  }

  /// Correct letter for active house — pop the bubble.
  void explodeLetter(int letterId) {
    for (final L in letters) {
      if (L.letter.id == letterId) {
        L.removed = true;
        sparkAt = L.pos;
        break;
      }
    }
    letterShake.remove(letterId);
  }

  /// Pop every remaining letter (level-complete celebration).
  List<AngryWordsLetterTarget> explodeAllRemaining() {
    final remaining = <AngryWordsLetterTarget>[
      for (final L in letters)
        if (!L.removed) L,
    ];
    for (final L in remaining) {
      L.removed = true;
      letterShake.remove(L.letter.id);
    }
    return remaining;
  }

  /// Pop leftover candy balloons (called with letter celebration).
  List<AngryWordsPropBubble> explodeAllRemainingProps() {
    final remaining = <AngryWordsPropBubble>[
      for (final P in props)
        if (!P.removed) P,
    ];
    for (final P in remaining) {
      P.removed = true;
    }
    return remaining;
  }

  /// Maps projectile speed → 0..1 relative to sling min/max launch speeds.
  double _powerNormFromSpeed(double speed) {
    final span = (maxLaunchSpeed - minLaunchSpeed).clamp(1.0, 5000.0);
    return ((speed - minLaunchSpeed) / span).clamp(0.0, 1.0);
  }

  /// Wrong letter — knock scales with the shot's real speed/power so a soft
  /// tap nudges lightly and a full pull blasts the pack.
  void scatterFromWrongHit(int letterId) {
    AngryWordsLetterTarget? source;
    for (final L in letters) {
      if (L.letter.id == letterId) {
        source = L;
        break;
      }
    }
    if (source == null) return;

    source.removed = false;

    // Prefer live impact velocity; fall back to aim-from-muzzle.
    var impact = lastShotImpactVel;
    if (impact.distance < 40) {
      final fromMuzzle = source.pos - muzzle;
      impact = fromMuzzle.distance < 1
          ? Offset(0, -minLaunchSpeed)
          : (fromMuzzle / fromMuzzle.distance) * minLaunchSpeed;
    }

    final impactSpeed = impact.distance.clamp(
      minLaunchSpeed * 0.55,
      maxLaunchSpeed,
    );
    final power =
        (lastShotPowerNorm > 0.02
                ? lastShotPowerNorm
                : _powerNormFromSpeed(impactSpeed))
            .clamp(0.08, 1.0);
    final impactDir = impact / impact.distance;

    // Shake & chaos duration track shot power (weak = brief nudge).
    letterShake[letterId] = 0.28 + power * 0.72;
    chaosTimer = 0.85 + power * 2.0;

    final bounds = playBounds;
    final rng = math.Random(
      letterId ^ (simTime * 1000).round() ^ (impactSpeed * 10).round(),
    );

    final alive = <AngryWordsLetterTarget>[
      for (final L in letters)
        if (!L.removed) L,
    ];
    if (alive.isEmpty) return;

    // Hit ball inherits most of the projectile momentum.
    final carry = 0.48 + power * 0.5;
    final jitter = 35.0 + power * 150.0;
    source.vel =
        impactDir * (impactSpeed * carry) +
        Offset(
          (rng.nextDouble() - 0.5) * jitter,
          (rng.nextDouble() - 0.5) * jitter,
        );
    source.pos = Offset(
      source.pos.dx + impactDir.dx * (6 + power * 12),
      source.pos.dy + impactDir.dy * (6 + power * 12),
    );

    // Neighbors: impulse falls with distance and scales with power.
    final epicenter = source.pos;
    final splashReach = 55.0 + power * 90.0;
    for (final L in alive) {
      if (identical(L, source)) continue;
      final delta = L.pos - epicenter;
      final dist = delta.distance;
      final contactReach = source.radius + L.radius + 12;
      if (dist < 1) {
        final a = rng.nextDouble() * math.pi * 2;
        final burst =
            (90 + power * 380) + rng.nextDouble() * (40 + power * 160);
        L.vel += Offset(math.cos(a), math.sin(a)) * burst;
        letterShake[L.letter.id] = math.max(
          letterShake[L.letter.id] ?? 0,
          0.2 + power * 0.45,
        );
        continue;
      }
      if (dist > contactReach + splashReach) continue;
      final n = Offset(delta.dx / dist, delta.dy / dist);
      final near = dist <= contactReach;
      final falloff = near
          ? 1.0
          : (1.0 - ((dist - contactReach) / splashReach)).clamp(0.0, 1.0);
      final radial = (near ? 120.0 : 48.0) + power * (near ? 280.0 : 130.0);
      final forward = (near ? 90.0 : 28.0) + power * (near ? 240.0 : 90.0);
      L.vel += n * (radial * falloff) + impactDir * (forward * falloff);
      L.vel +=
          Offset(-n.dy, n.dx) *
          ((rng.nextDouble() - 0.5) * (50 + power * 180) * falloff);
      if (falloff > 0.2) {
        letterShake[L.letter.id] = math.max(
          letterShake[L.letter.id] ?? 0,
          (0.12 + power * 0.4) * falloff,
        );
      }
    }

    // More cascade steps for harder shots so momentum reaches farther.
    final passes = 6 + (power * 18).round();
    final microDt = 1 / 60;
    final spdCap = 280.0 + power * 820.0;
    for (var pass = 0; pass < passes; pass++) {
      for (final L in alive) {
        L.pos = Offset(
          (L.pos.dx + L.vel.dx * microDt).clamp(
            bounds.left + L.radius,
            bounds.right - L.radius,
          ),
          (L.pos.dy + L.vel.dy * microDt).clamp(
            bounds.top + L.radius,
            bounds.bottom - L.radius,
          ),
        );
        if (L.pos.dx <= bounds.left + L.radius + 0.01 ||
            L.pos.dx >= bounds.right - L.radius - 0.01) {
          L.vel = Offset(-L.vel.dx * letterBounce, L.vel.dy);
        }
        if (L.pos.dy <= bounds.top + L.radius + 0.01 ||
            L.pos.dy >= bounds.bottom - L.radius - 0.01) {
          L.vel = Offset(L.vel.dx, -L.vel.dy * letterBounce);
        }
      }
      _resolveLetterCollisions();
    }

    for (final L in alive) {
      final sp = L.vel.distance;
      if (sp > spdCap) {
        L.vel = (L.vel / sp) * spdCap;
      }
    }
  }

  void markLetterRemoved(int letterId) {
    explodeLetter(letterId);
  }

  /// Path membership must NOT hide balls. Only [explodeLetter] sets removed.
  /// After a wrong path clears, call this so exploded prefix letters return.
  void revealAllLetters() {
    for (final L in letters) {
      L.removed = false;
    }
  }

  void tickLetterShake(double dt) {
    if (letterShake.isEmpty) return;
    final keys = letterShake.keys.toList();
    for (final id in keys) {
      final next = (letterShake[id]! - dt * 2.8).clamp(0.0, 1.0);
      if (next <= 0) {
        letterShake.remove(id);
      } else {
        letterShake[id] = next;
      }
    }
  }
}
