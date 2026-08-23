import 'dart:ui';

import 'wb_prop_archetype.dart';
import 'wb_prop_sound_family.dart';

/// Stable seed for deterministic debris / juice RNG.
///
/// Never use unseeded [Random] in the gameplay loop — derive from this.
int wbPropSeed({
  required int stage,
  required int gridRow,
  required int gridCol,
}) =>
    Object.hash(stage, gridRow, gridCol);

/// Per-prop mutable break state. Handlers stay const/stateless — all stage
/// data lives here so one [WbBreakHandler] instance can serve every prop.
class WbPropRuntime {
  WbPropRuntime({
    required this.key,
    required this.archetypeId,
    required this.recipe,
    required this.soundFamily,
    required this.soundPitch,
    required this.behaviors,
    required this.position,
    required this.radius,
    required this.seed,
    required this.hp,
    this.damageStage = 0,
    this.dentPoints,
    this.crackBranches,
    this.fuseTimer,
    this.burnRemaining,
    this.teethRemaining = 0,
    this.squashAxis = 0,
    this.squashAmount = 0,
    this.meltProgress = 0,
    this.palette = const [],
  });

  /// Opaque id for chain-explode bookkeeping (must be unique in the world).
  final Object key;

  final WbPropArchetype archetypeId;
  final WbShatterRecipe recipe;
  final WbPropSoundFamily soundFamily;
  final double soundPitch;
  final List<WbBreakBehavior> behaviors;

  Offset position;
  double radius;
  final int seed;

  int hp;
  int damageStage;

  List<Offset>? dentPoints;
  List<Path>? crackBranches;

  /// Seconds remaining before [WbBreakBehavior.chainExplode] detonates.
  double? fuseTimer;

  /// Seconds of ground-fire DoT left ([WbBreakBehavior.fluidFire]).
  double? burnRemaining;

  /// Visual HP feedback for gear-like erode (teeth left ≈ hp).
  int teethRemaining;

  double squashAxis;
  double squashAmount;
  double meltProgress;

  final List<Color> palette;

  Color get accentColor =>
      palette.isEmpty ? const Color(0xFFFFFFFF) : palette.first;
}
