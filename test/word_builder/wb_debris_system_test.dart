import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/debris/wb_debris_atlas.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/debris/wb_debris_budget.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/debris/wb_debris_pool.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/debris/wb_debris_spawner.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/debris/wb_fluid_pool.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/debris/wb_secondary_body.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/debris/wb_shard_paths.dart';

WbShatterRecipe _recipe({int shards = 18}) => WbShatterRecipe(
      shardCount: shards,
      shapes: const [WbShardShape.shard, WbShardShape.crumb],
      sizeRange: (0.2, 0.5),
      speedRange: (100, 200),
      spreadCone: 6.28,
      gravityScale: 1,
      drag: 0.4,
      lifetime: (0.5, 1.0),
      spinRange: (2, 8),
      dustAmount: 0.2,
      secondaryCount: 0,
      screenShake: 0.2,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WbDebrisPool never exceeds capacity and acquire returns null when full',
      () {
    final pool = WbDebrisPool(capacity: 8);
    for (var i = 0; i < 8; i++) {
      expect(pool.acquire(), isNotNull);
    }
    expect(pool.acquire(), isNull);
    expect(pool.aliveCount, 8);
    expect(pool.poolPressure, closeTo(0.3, 0.001));
  });

  test('budget prefers near-hit pops over far ones', () {
    final pool = WbDebrisPool(capacity: 40);
    // Fill most of the pool so pressure is low.
    for (var i = 0; i < 30; i++) {
      pool.acquire();
    }
    const hit = Offset(100, 100);
    final near = WbDebrisBudget.effectiveShardCount(
      recipe: _recipe(shards: 18),
      pool: pool,
      spawnAt: const Offset(110, 105),
      lastHit: hit,
    );
    final far = WbDebrisBudget.effectiveShardCount(
      recipe: _recipe(shards: 18),
      pool: pool,
      spawnAt: const Offset(800, 100),
      lastHit: hit,
    );
    expect(near, greaterThan(far));
    expect(near, greaterThan(0));
  });

  test('spawner respects budget and is deterministic for same seed', () {
    final a = WbDebrisPool(capacity: 200);
    final b = WbDebrisPool(capacity: 200);
    final n1 = WbDebrisSpawner.spawnShards(
      pool: a,
      recipe: _recipe(shards: 12),
      at: Offset.zero,
      propRadius: 14,
      seed: 42,
    );
    final n2 = WbDebrisSpawner.spawnShards(
      pool: b,
      recipe: _recipe(shards: 12),
      at: Offset.zero,
      propRadius: 14,
      seed: 42,
    );
    expect(n1, n2);
    expect(n1, 12);
    final posA = a.aliveItems.map((d) => (d.posX, d.posY, d.velX)).toList();
    final posB = b.aliveItems.map((d) => (d.posX, d.posY, d.velX)).toList();
    expect(posA, posB);
  });

  test('yolk secondary merges like legacy', () {
    final pool = WbSecondaryPool(capacity: 20);
    final world = WbSecondaryWorld(pool: pool, width: 400, height: 600);
    world.spillYolkAt(const Offset(200, 100), fromRadius: 12, seed: 1);
    world.spillYolkAt(const Offset(205, 100), fromRadius: 12, seed: 2);
    for (var i = 0; i < 90; i++) {
      world.step(1 / 60);
    }
    final yolks =
        world.pool.aliveItems.where((b) => b.kind == WbSecondaryKind.yolk);
    expect(yolks.length, lessThanOrEqualTo(2));
    expect(yolks.every((y) => y.onFloor), isTrue);
  });

  test('secondary pool caps at 120', () {
    final pool = WbSecondaryPool();
    expect(pool.capacity, 120);
    for (var i = 0; i < 120; i++) {
      expect(pool.acquire(), isNotNull);
    }
    expect(pool.acquire(), isNull);
  });

  test('fluid system merges and caps at 20', () {
    final fluids = WbFluidPoolSystem();
    expect(fluids.capacity, 20);
    for (var i = 0; i < 25; i++) {
      fluids.spawn(
        kind: WbFluidKind.oil,
        at: Offset(i * 100.0, 400),
        radius: 12,
        life: 1,
        color: const Color(0xFF5D4037),
      );
    }
    expect(fluids.aliveCount, lessThanOrEqualTo(20));

    fluids.releaseAll();
    fluids.spawn(
      kind: WbFluidKind.acid,
      at: const Offset(10, 10),
      radius: 10,
      life: 1,
      color: const Color(0xFF76FF03),
    );
    fluids.spawn(
      kind: WbFluidKind.acid,
      at: const Offset(20, 12),
      radius: 10,
      life: 1,
      color: const Color(0xFF76FF03),
    );
    expect(fluids.aliveCount, 1);
  });

  test('all 18 shard paths are cached unit paths', () {
    expect(WbShardShape.values.length, 18);
    for (final s in WbShardShape.values) {
      final a = WbShardPaths.forShape(s);
      final b = WbShardPaths.forShape(s);
      expect(identical(a, b), isTrue);
      expect(a.getBounds().width, greaterThan(0));
    }
  });

  test('debris atlas builds 18×4 slots', () async {
    final atlas = await WbDebrisAtlas.build();
    addTearDown(atlas.dispose);
    expect(atlas.rects.length, 18 * 4);
    expect(atlas.rectFor(WbShardShape.glint, 3), isNotNull);
  });

  test('reduced motion scales shards down', () {
    final pool = WbDebrisPool(capacity: 900);
    final full = WbDebrisBudget.effectiveShardCount(
      recipe: _recipe(shards: 20),
      pool: pool,
      spawnAt: Offset.zero,
      motionScale: 1,
    );
    final reduced = WbDebrisBudget.effectiveShardCount(
      recipe: _recipe(shards: 20),
      pool: pool,
      spawnAt: Offset.zero,
      motionScale: 0.25,
    );
    expect(reduced, lessThan(full));
    expect(reduced, greaterThanOrEqualTo(0));
  });
}
