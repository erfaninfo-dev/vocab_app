import 'dart:ui';

import '../wb_prop_archetype.dart';
import 'wb_balloon_silhouette.dart';
import 'wb_basic_silhouettes.dart';
import 'wb_candy_silhouette.dart';
import 'wb_silhouette.dart';
import 'wb_special_silhouettes.dart';
import 'wb_vessel_silhouettes.dart';

final Map<WbPropArchetype, Path> _silhouetteCache = {};

/// Cached unit path — never rebuild inside `paint()`.
Path silhouetteFor(WbPropArchetype a) =>
    _silhouetteCache.putIfAbsent(a, () => kWbSilhouettes[a]!.build());

void clearSilhouetteCache() => _silhouetteCache.clear();

const _ellipse = WbEllipseSilhouette();
const _ellipseTall = WbEllipseSilhouette(rx: 0.36, ry: 0.44);
const _ellipseWide = WbEllipseSilhouette(rx: 0.44, ry: 0.36);
const _box = WbBoxSilhouette();
const _barrel = WbBarrelSilhouette();
const _can = WbCanSilhouette();
const _crystal = WbCrystalSilhouette();
const _tire = WbTireSilhouette();

/// One silhouette builder per archetype (shared instances for like shapes).
const Map<WbPropArchetype, WbSilhouette> kWbSilhouettes = {
  // Toy Box
  WbPropArchetype.balloon: WbBalloonSilhouette(),
  WbPropArchetype.candyBall: WbCandySilhouette(),
  WbPropArchetype.plushBear: WbBearSilhouette(),
  WbPropArchetype.giftBox: _box,
  WbPropArchetype.woodCrate: _box,
  WbPropArchetype.paperLantern: _ellipseTall,
  WbPropArchetype.piggyBank: WbEllipseSilhouette(rx: 0.40, ry: 0.36),
  // Street Spray
  WbPropArchetype.sodaCan: _can,
  WbPropArchetype.egg: _ellipseTall,
  WbPropArchetype.sprayCan: _can,
  // Pellet Party
  WbPropArchetype.pinata: _ellipseTall,
  WbPropArchetype.watermelon: _ellipseWide,
  WbPropArchetype.soapBubble: _ellipse,
  WbPropArchetype.discoBall: _ellipse,
  WbPropArchetype.confettiBall: _ellipse,
  // War Band
  WbPropArchetype.woodBarrel: _barrel,
  WbPropArchetype.brick: _box,
  WbPropArchetype.tinCan: _can,
  WbPropArchetype.oilDrum: _barrel,
  WbPropArchetype.sandstone: _box,
  WbPropArchetype.woodTarget: _ellipse,
  WbPropArchetype.ceramicJug: WbJugSilhouette(),
  // Ice & Fire
  WbPropArchetype.glassBottle: WbBottleSilhouette(),
  WbPropArchetype.iceBlock: _box,
  WbPropArchetype.waxBall: _ellipse,
  WbPropArchetype.magmaOrb: _ellipse,
  // Piercers
  WbPropArchetype.coconut: _ellipse,
  WbPropArchetype.pumpkin: _ellipseWide,
  WbPropArchetype.glassPane: WbPaneSilhouette(),
  WbPropArchetype.lightBulb: WbBulbSilhouette(),
  WbPropArchetype.steelPlate: WbPaneSilhouette(),
  WbPropArchetype.magnetSphere: _ellipse,
  // Energy Age
  WbPropArchetype.crystal: _crystal,
  WbPropArchetype.oldTv: WbTvSilhouette(),
  WbPropArchetype.emojiVariety: _ellipse,
  WbPropArchetype.emojiAnimal: _ellipse,
  WbPropArchetype.neonOrb: _ellipse,
  WbPropArchetype.neonTube: WbTubeSilhouette(),
  WbPropArchetype.metalGear: WbGearSilhouette(teeth: 8),
  WbPropArchetype.batteryCell: _can,
  // Boom Brigade
  WbPropArchetype.fireworkShell: _ellipseTall,
  WbPropArchetype.powderKeg: _barrel,
  WbPropArchetype.oilLamp: WbBottleSilhouette(),
  WbPropArchetype.concreteBlock: _box,
  WbPropArchetype.rubberTire: _tire,
  // Endgame
  WbPropArchetype.goldTrophy: WbTrophySilhouette(),
  WbPropArchetype.stoneStatue: WbStatueSilhouette(),
  WbPropArchetype.bronzeBell: WbBellSilhouette(),
  WbPropArchetype.obsidianGem: _crystal,
  WbPropArchetype.graniteBlock: _box,
};
