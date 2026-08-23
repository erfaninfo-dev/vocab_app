import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/behaviors/wb_break_behavior_handler.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_runtime.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_sound_family.dart';

class _RecordingOps implements WbWorldOps {
  final List<WbShatterRecipe> shardRecipes = [];
  final List<int> shardSeeds = [];
  final List<int> secondaryCounts = [];
  final List<double> dustAmounts = [];
  final List<double> shakes = [];
  final List<(WbPropSoundFamily, double, bool)> sounds = [];
  final List<({Offset at, double radius, int damage})> radiusHits = [];
  final List<({Offset at, double radius, double duration})> fireDots = [];
  final List<Offset> fluidPools = [];

  final Map<Object, WbPropRuntime> props = {};
  final Set<Object> exploding = {};
  int chainDepth = 0;
  int maxChainDepthSeen = 0;
  int destroyInvocations = 0;
  bool chainTimedOut = false;

  @override
  double random(int seed) {
    var x = seed & 0x7fffffff;
    if (x == 0) x = 1;
    x = (1103515245 * x + 12345) & 0x7fffffff;
    return x / 0x80000000;
  }

  @override
  void spawnShards(WbShatterRecipe r, Offset at, double radius, int seed) {
    shardRecipes.add(r);
    shardSeeds.add(seed);
  }

  @override
  void spawnSecondary(WbShardShape shape, int count, Offset at, int seed) {
    secondaryCounts.add(count);
  }

  @override
  void spawnDust(double amount, Offset at, double radius) {
    dustAmounts.add(amount);
  }

  @override
  void requestScreenShake(double strength) => shakes.add(strength);

  @override
  void playSound(
    WbPropSoundFamily family,
    double pitch, {
    bool applyJitter = true,
    double priority = 0,
  }) =>
      sounds.add((family, pitch, applyJitter));

  @override
  void spawnFluidPool(Offset at, Color color, double size, double life) {
    fluidPools.add(at);
  }

  @override
  void applyFireDot(Offset at, double radius, double duration) {
    fireDots.add((at: at, radius: radius, duration: duration));
  }

  @override
  bool tryEnterChainExplosion(Object propKey, {int maxDepth = 4}) {
    if (exploding.contains(propKey)) return false;
    if (chainDepth >= maxDepth) return false;
    exploding.add(propKey);
    chainDepth++;
    if (chainDepth > maxChainDepthSeen) maxChainDepthSeen = chainDepth;
    return true;
  }

  @override
  void exitChainExplosion(Object propKey) {
    exploding.remove(propKey);
    chainDepth = (chainDepth - 1).clamp(0, 1 << 20);
  }

  @override
  void damageInRadius(
    Offset at,
    double radius,
    int damage, {
    Offset? exclude,
  }) {
    radiusHits.add((at: at, radius: radius, damage: damage));
    destroyInvocations++;
    if (destroyInvocations > 200) {
      chainTimedOut = true;
      return;
    }
    for (final prop in props.values.toList()) {
      if (exclude != null && (prop.position - exclude).distanceSquared < 0.0001) {
        continue;
      }
      if ((prop.position - at).distance > radius) continue;
      if (prop.hp <= 0) continue;
      prop.hp -= damage;
      if (prop.hp > 0) continue;
      // Instant fuse for chain stress test.
      prop.fuseTimer = 0;
      wbBreakHandlerFor(prop.behaviors).onDestroy(prop, this);
    }
  }
}

WbShatterRecipe _recipe({int shards = 12}) => WbShatterRecipe(
      shardCount: shards,
      shapes: const [WbShardShape.shard, WbShardShape.crumb],
      sizeRange: (0.2, 0.5),
      speedRange: (80, 180),
      spreadCone: 6.28,
      gravityScale: 1,
      drag: 0.4,
      lifetime: (0.5, 1.0),
      spinRange: (2, 8),
      dustAmount: 0.3,
      secondaryCount: 2,
      secondaryShape: WbShardShape.spark,
      screenShake: 0.2,
    );

WbPropRuntime _prop({
  required WbBreakBehavior behavior,
  int seed = 42,
  int shards = 12,
  Offset position = Offset.zero,
  Object? key,
  int hp = 1,
}) {
  return WbPropRuntime(
    key: key ?? 'p-$seed',
    archetypeId: WbPropArchetype.balloon,
    recipe: _recipe(shards: shards),
    soundFamily: WbPropSoundFamily.popSoft,
    soundPitch: 1,
    behaviors: [behavior],
    position: position,
    radius: 20,
    seed: seed,
    hp: hp,
    palette: const [Color(0xFFFF0000)],
  );
}

void _forceDestroy(WbBreakHandler handler, WbPropRuntime prop, WbWorldOps ops) {
  handler.onDestroy(prop, ops);
  if (prop.fuseTimer != null && prop.fuseTimer! > 0) {
    prop.fuseTimer = 0;
    handler.tick(prop, 0.001, ops);
  } else if (prop.fuseTimer == 0) {
    handler.tick(prop, 0.001, ops);
  }
}

void main() {
  test('kWbBreakHandlers covers every WbBreakBehavior', () {
    expect(kWbBreakHandlers.length, WbBreakBehavior.values.length);
    for (final b in WbBreakBehavior.values) {
      expect(kWbBreakHandlers.containsKey(b), isTrue, reason: '$b');
    }
  });

  for (final behavior in WbBreakBehavior.values) {
    test('$behavior onDestroy yields shard count in recipe range', () {
      final ops = _RecordingOps();
      final prop = _prop(behavior: behavior, shards: 12);
      final handler = kWbBreakHandlers[behavior]!;
      _forceDestroy(handler, prop, ops);

      if (prop.recipe.shardCount <= 0) {
        expect(ops.shardRecipes, isEmpty);
        return;
      }
      // lightDeath alone still juices; chainExplode after fuse juices once.
      expect(ops.shardRecipes, isNotEmpty, reason: '$behavior spawned no shards');
      final spawned = ops.shardRecipes.first.shardCount;
      expect(spawned, inInclusiveRange(1, prop.recipe.shardCount));
      expect(spawned, prop.recipe.shardCount);
    });
  }

  test('chainExplode of 10 packed shells terminates (depth limit)', () {
    final ops = _RecordingOps();
    final handler = kWbBreakHandlers[WbBreakBehavior.chainExplode]!;
    for (var i = 0; i < 10; i++) {
      final p = _prop(
        behavior: WbBreakBehavior.chainExplode,
        seed: 100 + i,
        key: 'fw-$i',
        position: Offset(i * 10.0, 0),
        hp: 1,
      );
      // radius 20 * 1.8 = 36 → neighbors within 10px all overlap.
      ops.props[p.key] = p;
    }

    final first = ops.props['fw-0']!;
    first.fuseTimer = 0;
    handler.onDestroy(first, ops);

    expect(ops.chainTimedOut, isFalse);
    expect(ops.maxChainDepthSeen, lessThanOrEqualTo(4));
    expect(ops.destroyInvocations, lessThan(200));
    // Not every shell must die (depth cap), but explosion must stop.
    expect(ops.radiusHits, isNotEmpty);
  });

  test('absorbBounce onHit returns less damage than hit.damage', () {
    final ops = _RecordingOps();
    final prop = _prop(behavior: WbBreakBehavior.absorbBounce);
    final handler = kWbBreakHandlers[WbBreakBehavior.absorbBounce]!;
    const hit = WbHitInfo(damage: 3, point: Offset.zero, direction: Offset(1, 0));
    final effective = handler.onHit(prop, hit, ops);
    expect(effective, lessThan(hit.damage));
    expect(effective, greaterThanOrEqualTo(1));
    expect(prop.squashAmount, greaterThan(0));
  });

  test('deterministic RNG: same seed yields identical shard seeds', () {
    final handler = kWbBreakHandlers[WbBreakBehavior.shatter]!;

    final opsA = _RecordingOps();
    final propA = _prop(behavior: WbBreakBehavior.shatter, seed: 0xC0FFEE);
    handler.onDestroy(propA, opsA);

    final opsB = _RecordingOps();
    final propB = _prop(behavior: WbBreakBehavior.shatter, seed: 0xC0FFEE);
    handler.onDestroy(propB, opsB);

    expect(opsA.shardSeeds, opsB.shardSeeds);
    expect(opsA.shardRecipes.map((r) => r.shardCount).toList(),
        opsB.shardRecipes.map((r) => r.shardCount).toList());
    expect(opsA.sounds.map((e) => e.$1).toList(), opsB.sounds.map((e) => e.$1).toList());
  });

  test('wbPropSeed is stable for same grid coords', () {
    expect(
      wbPropSeed(stage: 41, gridRow: 2, gridCol: 3),
      wbPropSeed(stage: 41, gridRow: 2, gridCol: 3),
    );
    expect(
      wbPropSeed(stage: 41, gridRow: 2, gridCol: 3),
      isNot(wbPropSeed(stage: 41, gridRow: 2, gridCol: 4)),
    );
  });

  test('composite split+lightDeath runs both without double full juice', () {
    final ops = _RecordingOps();
    final prop = WbPropRuntime(
      key: 'neon',
      archetypeId: WbPropArchetype.neonTube,
      recipe: _recipe(shards: 2),
      soundFamily: WbPropSoundFamily.shatterGlass,
      soundPitch: 1.25,
      behaviors: const [
        WbBreakBehavior.splitInHalf,
        WbBreakBehavior.lightDeath,
      ],
      position: Offset.zero,
      radius: 10,
      seed: 7,
      hp: 1,
    );
    final handler = wbBreakHandlerFor(prop.behaviors);
    expect(handler, isA<WbCompositeHandler>());
    handler.onDestroy(prop, ops);
    // Split juices once; lightDeath skips full juice when composed.
    expect(ops.shardRecipes.length, 1);
    expect(ops.sounds, isNotEmpty);
  });

  test('neonTube archetype uses composite behaviors', () {
    final spec = kWbArchetypes[WbPropArchetype.neonTube]!;
    expect(
      spec.behaviors,
      [
        WbBreakBehavior.splitInHalf,
        WbBreakBehavior.lightDeath,
      ],
    );
  });
}
