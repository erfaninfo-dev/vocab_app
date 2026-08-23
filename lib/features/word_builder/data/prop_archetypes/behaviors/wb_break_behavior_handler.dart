import 'dart:math' as math;
import 'dart:ui';

import '../wb_prop_archetype.dart';
import '../wb_prop_runtime.dart';
import '../wb_prop_sound_family.dart';

/// Hit payload for [WbBreakHandler.onHit] — damage before HP is applied.
class WbHitInfo {
  const WbHitInfo({
    required this.damage,
    required this.point,
    this.direction = Offset.zero,
  });

  final int damage;
  final Offset point;
  final Offset direction;
}

/// World side-effects available to break handlers.
///
/// Handlers must not touch Riverpod notifiers or word-accept logic — only
/// debris, splash damage, audio keys, and juice. Cargo release stays on the
/// existing pop path outside this layer.
abstract class WbWorldOps {
  void spawnShards(WbShatterRecipe r, Offset at, double radius, int seed);

  void spawnSecondary(WbShardShape shape, int count, Offset at, int seed);

  void spawnDust(double amount, Offset at, double radius);

  void damageInRadius(
    Offset at,
    double radius,
    int damage, {
    Offset? exclude,
  });

  void applyFireDot(Offset at, double radius, double duration);

  void requestScreenShake(double strength);

  void playSound(
    WbPropSoundFamily family,
    double pitch, {
    bool applyJitter = true,
    double priority = 0,
  });

  void spawnFluidPool(Offset at, Color color, double size, double life);

  /// Deterministic float in `[0, 1)` from [seed] (no global Random).
  double random(int seed);

  /// Enter a chain-explosion generation. Returns `false` if [propKey] is
  /// already exploding or depth would exceed [maxDepth].
  bool tryEnterChainExplosion(Object propKey, {int maxDepth = 4});

  void exitChainExplosion(Object propKey);
}

/// Strategy for one [WbBreakBehavior]. Const / stateless — mutable stage
/// lives on [WbPropRuntime].
sealed class WbBreakHandler {
  const WbBreakHandler();

  /// Before HP is reduced. Return effective damage (e.g. tire absorbs).
  int onHit(WbPropRuntime prop, WbHitInfo hit, WbWorldOps ops) => hit.damage;

  /// HP lowered but prop still alive.
  void onDamageStage(WbPropRuntime prop, int newStage, WbWorldOps ops) {}

  /// Destruction juice — shards, AoE, sound.
  void onDestroy(WbPropRuntime prop, WbWorldOps ops);

  /// Per-frame for fuse / burn / melt.
  void tick(WbPropRuntime prop, double dt, WbWorldOps ops) {}

  /// Shared recipe → debris / dust / shake / sound.
  void spawnRecipeJuice(WbPropRuntime prop, WbWorldOps ops) {
    final r = prop.recipe;
    final count = math.max(0, r.playableShardCount);
    if (count > 0 && r.shapes.isNotEmpty) {
      ops.spawnShards(r, prop.position, prop.radius, prop.seed);
    }
    final secondary = r.secondaryShape;
    final secCount = r.playableSecondaryCount;
    if (secCount > 0 && secondary != null) {
      ops.spawnSecondary(
        secondary,
        secCount,
        prop.position,
        prop.seed ^ 0xA5A5,
      );
    }
    if (r.dustAmount > 0) {
      ops.spawnDust(r.dustAmount, prop.position, prop.radius);
    }
    if (r.screenShake > 0) {
      ops.requestScreenShake(r.screenShake);
    }
    ops.playSound(prop.soundFamily, prop.soundPitch);
  }
}

/// Runs several handlers in order (e.g. neon tube = split + lightDeath).
class WbCompositeHandler extends WbBreakHandler {
  const WbCompositeHandler(this.handlers);

  final List<WbBreakHandler> handlers;

  @override
  int onHit(WbPropRuntime prop, WbHitInfo hit, WbWorldOps ops) {
    var damage = hit.damage;
    for (final h in handlers) {
      damage = h.onHit(
        prop,
        WbHitInfo(damage: damage, point: hit.point, direction: hit.direction),
        ops,
      );
    }
    return damage;
  }

  @override
  void onDamageStage(WbPropRuntime prop, int newStage, WbWorldOps ops) {
    for (final h in handlers) {
      h.onDamageStage(prop, newStage, ops);
    }
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) {
    for (final h in handlers) {
      h.onDestroy(prop, ops);
    }
  }

  @override
  void tick(WbPropRuntime prop, double dt, WbWorldOps ops) {
    for (final h in handlers) {
      h.tick(prop, dt, ops);
    }
  }
}

// ── Individual strategies ───────────────────────────────────────────────────

class WbPopHandler extends WbBreakHandler {
  const WbPopHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbShatterHandler extends WbBreakHandler {
  const WbShatterHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbCrumbleHandler extends WbBreakHandler {
  const WbCrumbleHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbSplitInHalfHandler extends WbBreakHandler {
  const WbSplitInHalfHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbCaveInHandler extends WbBreakHandler {
  const WbCaveInHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbMeltHandler extends WbBreakHandler {
  const WbMeltHandler();

  @override
  void tick(WbPropRuntime prop, double dt, WbWorldOps ops) {
    if (prop.meltProgress >= 1) return;
    prop.meltProgress = math.min(1, prop.meltProgress + dt / 0.45);
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) {
    ops.spawnFluidPool(
      prop.position,
      prop.accentColor,
      prop.radius * 1.2,
      0.9,
    );
    spawnRecipeJuice(prop, ops);
  }
}

class WbBurstFluidHandler extends WbBreakHandler {
  const WbBurstFluidHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) {
    ops.spawnFluidPool(
      prop.position,
      prop.accentColor,
      prop.radius,
      0.7,
    );
    spawnRecipeJuice(prop, ops);
  }
}

class WbSpillContentsHandler extends WbBreakHandler {
  const WbSpillContentsHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbDentThenRuptureHandler extends WbBreakHandler {
  const WbDentThenRuptureHandler();

  @override
  void onDamageStage(WbPropRuntime prop, int newStage, WbWorldOps ops) {
    final dents = prop.dentPoints ??= <Offset>[];
    dents.add(Offset(
      ops.random(prop.seed ^ newStage ^ 0x11) * 2 - 1,
      ops.random(prop.seed ^ newStage ^ 0x22) * 2 - 1,
    ));
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbErodeHandler extends WbBreakHandler {
  const WbErodeHandler();

  @override
  void onDamageStage(WbPropRuntime prop, int newStage, WbWorldOps ops) {
    prop.teethRemaining = math.max(0, prop.hp);
    final dents = prop.dentPoints ??= <Offset>[];
    dents.add(Offset(
      ops.random(prop.seed ^ newStage ^ 0x33) * 2 - 1,
      ops.random(prop.seed ^ newStage ^ 0x44) * 2 - 1,
    ));
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbCrackCascadeHandler extends WbBreakHandler {
  const WbCrackCascadeHandler();

  @override
  void onDamageStage(WbPropRuntime prop, int newStage, WbWorldOps ops) {
    final branches = prop.crackBranches ??= <Path>[];
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(
        ops.random(prop.seed ^ newStage) * 2 - 1,
        ops.random(prop.seed ^ newStage ^ 7) * 2 - 1,
      );
    branches.add(path);
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbSpiderwebHandler extends WbBreakHandler {
  const WbSpiderwebHandler();

  @override
  void onDamageStage(WbPropRuntime prop, int newStage, WbWorldOps ops) {
    final branches = prop.crackBranches ??= <Path>[];
    final web = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      web.moveTo(0, 0);
      web.lineTo(math.cos(a), math.sin(a));
    }
    branches.add(web);
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

/// Fuse then AoE — depth-limited so powder kegs cannot stack-overflow.
class WbChainExplodeHandler extends WbBreakHandler {
  const WbChainExplodeHandler({
    this.fuseSeconds = 0.15,
    this.radiusMul = 1.8,
    this.splashDamage = 1,
  });

  final double fuseSeconds;
  final double radiusMul;
  final int splashDamage;

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) {
    // Arm fuse on first destroy signal; world should keep prop until fuse ends.
    prop.fuseTimer ??= fuseSeconds;
    if (prop.fuseTimer! > 0) return;
    _detonate(prop, ops);
  }

  @override
  void tick(WbPropRuntime prop, double dt, WbWorldOps ops) {
    final fuse = prop.fuseTimer;
    if (fuse == null) return;
    if (fuse <= 0) {
      _detonate(prop, ops);
      return;
    }
    final next = fuse - dt;
    prop.fuseTimer = next <= 0 ? 0 : next;
    if (prop.fuseTimer == 0) {
      _detonate(prop, ops);
    }
  }

  void _detonate(WbPropRuntime prop, WbWorldOps ops) {
    if (!ops.tryEnterChainExplosion(prop.key)) return;
    try {
      spawnRecipeJuice(prop, ops);
      ops.damageInRadius(
        prop.position,
        prop.radius * radiusMul,
        splashDamage,
        exclude: prop.position,
      );
      prop.fuseTimer = null;
    } finally {
      ops.exitChainExplosion(prop.key);
    }
  }
}

class WbRingDecayHandler extends WbBreakHandler {
  const WbRingDecayHandler();

  @override
  void onDamageStage(WbPropRuntime prop, int newStage, WbWorldOps ops) {
    // HP 3→1.2, 2→1.0, 1→0.8 — ear-readable HP.
    final pitch = switch (prop.hp) {
      >= 3 => 1.2,
      2 => 1.0,
      _ => 0.8,
    };
    ops.playSound(prop.soundFamily, pitch, applyJitter: false);
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbToppleHandler extends WbBreakHandler {
  const WbToppleHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbLightDeathHandler extends WbBreakHandler {
  const WbLightDeathHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) {
    ops.playSound(prop.soundFamily, prop.soundPitch);
    ops.requestScreenShake(prop.recipe.screenShake * 0.5);
    // Glow dies without duplicating full shard burst when composed after split.
    if (prop.behaviors.length == 1) {
      spawnRecipeJuice(prop, ops);
    }
  }
}

class WbMagnetizeHandler extends WbBreakHandler {
  const WbMagnetizeHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbRefractHandler extends WbBreakHandler {
  const WbRefractHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

class WbFluidFireHandler extends WbBreakHandler {
  const WbFluidFireHandler();

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) {
    ops.spawnFluidPool(
      prop.position,
      prop.accentColor,
      prop.radius * 0.9,
      1.0,
    );
    ops.applyFireDot(prop.position, prop.radius * 1.4, 0.9);
    spawnRecipeJuice(prop, ops);
  }

  @override
  void tick(WbPropRuntime prop, double dt, WbWorldOps ops) {
    final burn = prop.burnRemaining;
    if (burn == null) return;
    final next = burn - dt;
    prop.burnRemaining = next <= 0 ? null : next;
  }
}

class WbAbsorbBounceHandler extends WbBreakHandler {
  const WbAbsorbBounceHandler();

  @override
  int onHit(WbPropRuntime prop, WbHitInfo hit, WbWorldOps ops) {
    prop.squashAmount = 0.4;
    prop.squashAxis = hit.direction == Offset.zero
        ? 0
        : math.atan2(hit.direction.dy, hit.direction.dx);
    // Soft tire: at least 1, but strictly less than full hit when damage > 1.
    if (hit.damage <= 1) return 1;
    return math.max(1, hit.damage - 1);
  }

  @override
  void tick(WbPropRuntime prop, double dt, WbWorldOps ops) {
    if (prop.squashAmount <= 0) return;
    prop.squashAmount = math.max(0, prop.squashAmount - dt / 0.12);
  }

  @override
  void onDestroy(WbPropRuntime prop, WbWorldOps ops) =>
      spawnRecipeJuice(prop, ops);
}

/// Registry — one const instance per behavior.
const Map<WbBreakBehavior, WbBreakHandler> kWbBreakHandlers = {
  WbBreakBehavior.pop: WbPopHandler(),
  WbBreakBehavior.shatter: WbShatterHandler(),
  WbBreakBehavior.crumble: WbCrumbleHandler(),
  WbBreakBehavior.splitInHalf: WbSplitInHalfHandler(),
  WbBreakBehavior.caveIn: WbCaveInHandler(),
  WbBreakBehavior.melt: WbMeltHandler(),
  WbBreakBehavior.burstFluid: WbBurstFluidHandler(),
  WbBreakBehavior.spillContents: WbSpillContentsHandler(),
  WbBreakBehavior.dentThenRupture: WbDentThenRuptureHandler(),
  WbBreakBehavior.erode: WbErodeHandler(),
  WbBreakBehavior.crackCascade: WbCrackCascadeHandler(),
  WbBreakBehavior.spiderweb: WbSpiderwebHandler(),
  WbBreakBehavior.chainExplode: WbChainExplodeHandler(),
  WbBreakBehavior.ringDecay: WbRingDecayHandler(),
  WbBreakBehavior.topple: WbToppleHandler(),
  WbBreakBehavior.lightDeath: WbLightDeathHandler(),
  WbBreakBehavior.magnetize: WbMagnetizeHandler(),
  WbBreakBehavior.refract: WbRefractHandler(),
  WbBreakBehavior.fluidFire: WbFluidFireHandler(),
  WbBreakBehavior.absorbBounce: WbAbsorbBounceHandler(),
};

/// Resolve a single handler or a [WbCompositeHandler] for multi-behavior specs.
WbBreakHandler wbBreakHandlerFor(List<WbBreakBehavior> behaviors) {
  assert(behaviors.isNotEmpty, 'behaviors must not be empty');
  if (behaviors.length == 1) {
    return kWbBreakHandlers[behaviors.single]!;
  }
  return WbCompositeHandler([
    for (final b in behaviors) kWbBreakHandlers[b]!,
  ]);
}
