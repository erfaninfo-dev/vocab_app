/// Eight break SFX families remapping onto existing APK assets.
enum WbPropSoundFamily {
  popSoft,
  shatterGlass,
  breakCeramic,
  thudWood,
  clangMetal,
  crumbleStone,
  splashFluid,
  sparkEnergy,
}

extension WbPropSoundFamilyX on WbPropSoundFamily {
  /// Preferred asset; missing file → [fallbackAssetPath].
  String get assetPath => switch (this) {
        WbPropSoundFamily.popSoft ||
        WbPropSoundFamily.thudWood ||
        WbPropSoundFamily.crumbleStone ||
        WbPropSoundFamily.splashFluid =>
          'assets/audio/pop.WAV',
        WbPropSoundFamily.shatterGlass ||
        WbPropSoundFamily.breakCeramic ||
        WbPropSoundFamily.clangMetal =>
          'assets/audio/pot.mp3',
        WbPropSoundFamily.sparkEnergy => 'assets/audio/shot2.WAV',
      };

  String get fallbackAssetPath => 'assets/audio/pop.WAV';

  /// Inclusive pitch band — archetype [soundPitch] must stay inside.
  (double, double) get pitchRange => switch (this) {
        WbPropSoundFamily.popSoft => (1.1, 1.35),
        WbPropSoundFamily.shatterGlass => (1.0, 1.3),
        WbPropSoundFamily.breakCeramic => (0.85, 1.0),
        WbPropSoundFamily.thudWood => (0.7, 0.9),
        WbPropSoundFamily.clangMetal => (0.65, 0.9),
        WbPropSoundFamily.crumbleStone => (0.5, 0.7),
        WbPropSoundFamily.splashFluid => (0.9, 1.1),
        WbPropSoundFamily.sparkEnergy => (1.1, 1.4),
      };

  double get defaultPitch {
    final r = pitchRange;
    return (r.$1 + r.$2) * 0.5;
  }
}

/// Interim material → family map until every prop carries an archetype.
WbPropSoundFamily wbSoundFamilyForMaterial(Object material) {
  final name = material.toString().split('.').last;
  return switch (name) {
    'rubber' || 'foam' || 'plastic' => WbPropSoundFamily.popSoft,
    'glass' || 'ice' || 'crystal' => WbPropSoundFamily.shatterGlass,
    'porcelain' => WbPropSoundFamily.breakCeramic,
    'wood' => WbPropSoundFamily.thudWood,
    'metal' || 'gold' => WbPropSoundFamily.clangMetal,
    'stone' || 'sand' => WbPropSoundFamily.crumbleStone,
    'water' || 'slime' || 'egg' || 'magma' => WbPropSoundFamily.splashFluid,
    'candy' => WbPropSoundFamily.sparkEnergy,
    _ => WbPropSoundFamily.popSoft,
  };
}
