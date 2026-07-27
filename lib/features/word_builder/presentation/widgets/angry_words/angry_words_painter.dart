import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'angry_words_loadout.dart';
import 'angry_words_physics.dart';

enum AngryWordsBitShape { round, shard, chip, drop, spark, dust, glitter }

class AngryWordsLetterExplosion {
  AngryWordsLetterExplosion({
    required this.at,
    required this.char,
    required this.life,
    required this.bits,
    this.juicy = false,
    this.steamy = false,
    this.ringA = const Color(0xFFFFD54F),
    this.ringB = const Color(0xFFFF7043),
    this.material,
  });

  final Offset at;
  final String char;
  double life;
  final List<AngryWordsExplosionBit> bits;
  final bool juicy;
  final bool steamy;
  final Color ringA;
  final Color ringB;
  final AngryWordsPropMaterial? material;
}

/// Palette tints for candy / plastic accents.
const kAngryWordsPropPalettes = <List<Color>>[
  [Color(0xFFFF80AB), Color(0xFFE91E63)],
  [Color(0xFF80D8FF), Color(0xFF0288D1)],
  [Color(0xFFB9F6CA), Color(0xFF00C853)],
  [Color(0xFFFFE57F), Color(0xFFFFAB00)],
  [Color(0xFFEA80FC), Color(0xFFAA00FF)],
  [Color(0xFFFFAB91), Color(0xFFFF5722)],
  [Color(0xFFFF8A80), Color(0xFFD50000)],
  [Color(0xFFA7FFEB), Color(0xFF00BFA5)],
  [Color(0xFFFFD180), Color(0xFFFF6D00)],
  [Color(0xFFCCFF90), Color(0xFF64DD17)],
  [Color(0xFFB388FF), Color(0xFF6200EA)],
  [Color(0xFFFF80AB), Color(0xFFC51162)],
];

/// Distinct letter-orb colors — one unique hue per letter in a stage.
const kAngryWordsLetterTints = <Color>[
  Color(0xFFFF7043), // deep orange
  Color(0xFF42A5F5), // blue
  Color(0xFF66BB6A), // green
  Color(0xFFAB47BC), // purple
  Color(0xFFFFCA28), // amber
  Color(0xFF26C6DA), // cyan
  Color(0xFFEF5350), // red
  Color(0xFF8D6E63), // brown
  Color(0xFFEC407A), // pink
  Color(0xFF7E57C2), // violet
  Color(0xFF9CCC65), // light green
  Color(0xFFFFA726), // orange
  Color(0xFF29B6F6), // light blue
  Color(0xFFD4E157), // lime
  Color(0xFF5C6BC0), // indigo
  Color(0xFFFF8A65), // coral
  Color(0xFF26A69A), // teal
  Color(0xFFFFEE58), // yellow
  Color(0xFF78909C), // blue grey
  Color(0xFFEF9A9A), // soft red
  Color(0xFF81C784), // soft green
  Color(0xFFBA68C8), // soft purple
  Color(0xFFFFB74D), // soft amber
  Color(0xFF4DD0E1), // soft cyan
];

Color angryWordsLetterTint(int tintIndex) =>
    kAngryWordsLetterTints[tintIndex % kAngryWordsLetterTints.length];

List<Color> _angryWordsPaletteTint(
  int palette,
  Color light,
  Color dark, {
  double amount = 0.62,
}) {
  final p = kAngryWordsPropPalettes[palette % kAngryWordsPropPalettes.length];
  return [
    Color.lerp(light, p[0], amount)!,
    Color.lerp(dark, p[1], amount)!,
  ];
}

List<Color> angryWordsColorsForMaterial(
  AngryWordsPropMaterial material,
  int palette,
) {
  final candy =
      kAngryWordsPropPalettes[palette % kAngryWordsPropPalettes.length];
  return switch (material) {
    AngryWordsPropMaterial.candy || AngryWordsPropMaterial.plastic => candy,
    // Keep material identity, but dye with the candy palette so late walls
    // stay as colorful as early toy stages.
    AngryWordsPropMaterial.wood => _angryWordsPaletteTint(
      palette,
      const Color(0xFFD7CCC8),
      const Color(0xFF6D4C41),
      amount: 0.48,
    ),
    AngryWordsPropMaterial.glass => _angryWordsPaletteTint(
      palette,
      const Color(0xFFE0F7FA),
      const Color(0xFF4DD0E1),
      amount: 0.55,
    ),
    AngryWordsPropMaterial.water => _angryWordsPaletteTint(
      palette,
      const Color(0xFFB3E5FC),
      const Color(0xFF0288D1),
      amount: 0.5,
    ),
    AngryWordsPropMaterial.rubber => _angryWordsPaletteTint(
      palette,
      const Color(0xFFFFAB91),
      const Color(0xFFE64A19),
      amount: 0.45,
    ),
    AngryWordsPropMaterial.stone => _angryWordsPaletteTint(
      palette,
      const Color(0xFFB0BEC5),
      const Color(0xFF546E7A),
      amount: 0.72,
    ),
    AngryWordsPropMaterial.metal => _angryWordsPaletteTint(
      palette,
      const Color(0xFFCFD8DC),
      const Color(0xFF455A64),
      amount: 0.7,
    ),
    AngryWordsPropMaterial.ice => _angryWordsPaletteTint(
      palette,
      const Color(0xFFE1F5FE),
      const Color(0xFF81D4FA),
      amount: 0.65,
    ),
    AngryWordsPropMaterial.crystal => _angryWordsPaletteTint(
      palette,
      const Color(0xFFE1BEE7),
      const Color(0xFF8E24AA),
      amount: 0.4,
    ),
    AngryWordsPropMaterial.porcelain => _angryWordsPaletteTint(
      palette,
      const Color(0xFFFAFAFA),
      const Color(0xFFBDBDBD),
      amount: 0.68,
    ),
    AngryWordsPropMaterial.sand => _angryWordsPaletteTint(
      palette,
      const Color(0xFFFFE0B2),
      const Color(0xFFBF360C),
      amount: 0.4,
    ),
    AngryWordsPropMaterial.foam => _angryWordsPaletteTint(
      palette,
      const Color(0xFFFFFFFF),
      const Color(0xFFECEFF1),
      amount: 0.75,
    ),
    AngryWordsPropMaterial.magma => _angryWordsPaletteTint(
      palette,
      const Color(0xFFFF6D00),
      const Color(0xFFBF360C),
      amount: 0.35,
    ),
    AngryWordsPropMaterial.gold => _angryWordsPaletteTint(
      palette,
      const Color(0xFFFFF59D),
      const Color(0xFFFF8F00),
      amount: 0.35,
    ),
    AngryWordsPropMaterial.slime => _angryWordsPaletteTint(
      palette,
      const Color(0xFFB2FF59),
      const Color(0xFF64DD17),
      amount: 0.4,
    ),
    // Eggs keep natural cream shell — no candy palette dye (pop is shell+yolk).
    AngryWordsPropMaterial.egg => const [
      Color(0xFFFFF8E1),
      Color(0xFFE8D5B5),
    ],
  };
}

class AngryWordsExplosionBit {
  const AngryWordsExplosionBit({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    this.shape = AngryWordsBitShape.round,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final AngryWordsBitShape shape;
}

/// Premium warm board painter for Angry Words.
class AngryWordsBoardPainter extends CustomPainter {
  AngryWordsBoardPainter({
    required this.world,
    required this.selectedIds,
    required this.wrongFlash,
    required this.successFlash,
    required this.prefixFlash,
    required this.combo,
    required this.trail,
    required this.sparkLife,
    required this.explosions,
    required this.isDark,
    required this.scheme,
  });

  final AngryWordsPhysicsWorld world;
  final Set<int> selectedIds;
  final double wrongFlash;
  final double successFlash;
  final double prefixFlash;
  final int combo;
  final List<Offset> trail;
  final double sparkLife;
  final List<AngryWordsLetterExplosion> explosions;
  final bool isDark;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    _paintSky(canvas, size);
    _paintHills(canvas, size);
    _paintWindStreaks(canvas, size);

    if (wrongFlash > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(
            0xFFFF5252,
          ).withValues(alpha: 0.22 * wrongFlash),
      );
    }
    if (successFlash > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(
            0xFF69F0AE,
          ).withValues(alpha: 0.24 * successFlash),
      );
    }
    if (prefixFlash > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(
            0xFFFFD54F,
          ).withValues(alpha: 0.14 * prefixFlash),
      );
    }

    _paintProps(canvas);
    _paintYolks(canvas);
    _paintLetters(canvas);
    if (world.usesSlingshot) {
      _paintTargetLock(canvas);
    }
    _paintExplosions(canvas);
    if (world.usesSlingshot) {
      _paintAimPreview(canvas);
    }
    _paintCannon(canvas);
    if (world.usesGun) {
      _paintBullets(canvas);
      _paintMuzzleFlash(canvas);
    } else {
      _paintTrail(canvas);
      if (world.inFlight || world.aiming) {
        _paintBall(canvas);
      }
    }
    if (sparkLife > 0 && world.sparkAt != null) {
      _paintSpark(canvas, world.sparkAt!, sparkLife);
    }
    if (combo >= 2) {
      _paintCombo(canvas, size);
    }
    if (successFlash > 0.2) {
      _paintPerfectBurst(canvas, size);
    }

    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(
          0xFFFF8A65,
        ).withValues(alpha: isDark ? 0.55 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  void _paintSky(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF2A1B3D), Color(0xFF1A1228), Color(0xFF0E0A16)]
              : const [Color(0xFFFFE0B2), Color(0xFFFFCC80), Color(0xFFFFAB91)],
        ).createShader(Offset.zero & size),
    );

    // Soft sun / moon glow.
    final sun = Offset(size.width * 0.82, size.height * 0.14);
    canvas.drawCircle(
      sun,
      size.width * 0.14,
      Paint()
        ..color = (isDark ? const Color(0xFFFFECB3) : const Color(0xFFFFF59D))
            .withValues(alpha: isDark ? 0.18 : 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
  }

  void _paintHills(Canvas canvas, Size size) {
    final groundY = size.height - AngryWordsPhysicsWorld.groundYPad;
    final path = Path()
      ..moveTo(0, groundY + 8)
      ..quadraticBezierTo(
        size.width * 0.25,
        groundY - 18,
        size.width * 0.5,
        groundY + 2,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        groundY + 22,
        size.width,
        groundY - 6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF3E2723), Color(0xFF1B120E)]
              : const [Color(0xFF81C784), Color(0xFF558B2F)],
        ).createShader(Rect.fromLTWH(0, groundY - 30, size.width, size.height)),
    );
  }

  void _paintWindStreaks(Canvas canvas, Size size) {
    final intensity = world.windIntensity;
    if (intensity < 0.08) return;
    final dir = world.windVector;
    final len = dir.distance;
    if (len < 0.1) return;
    final n = dir / len;
    final count = 6 + (intensity * 8).round();
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12 + intensity * 0.28)
      ..strokeWidth = 1.4 + intensity * 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final seed = i * 17.3 + world.simTime * (18 + intensity * 42);
      final y =
          size.height * (0.1 + (math.sin(seed * 0.07 + i) * 0.5 + 0.5) * 0.48);
      final xBase = (seed * 37) % (size.width + 80) - 40;
      final streak = 18 + intensity * 36;
      final a = Offset(xBase, y);
      final b = a + n * streak;
      canvas.drawLine(a, b, paint);
    }
  }

  void _paintBullets(Canvas canvas) {
    final gun = world.loadout.gun;
    for (final b in world.bullets) {
      if (b.dead) continue;
      final c = b.pos;
      final r = b.radius;
      final v = b.vel;
      final len = v.distance;
      final n = len > 1 ? v / len : const Offset(0, -1);

      if (gun == AngryWordsGunKind.laserTank ||
          b.element == AngryWordsBulletElement.laser) {
        final isTank = gun == AngryWordsGunKind.laserTank;
        final tail = isTank ? 34.0 : (len > 1900 ? 36.0 : 22.0);
        final w = isTank ? math.max(2.0, r * 0.7) : math.max(1.6, r * 0.85);
        canvas.drawLine(
          c - n * tail,
          c + n * 10,
          Paint()
            ..color =
                (isTank ? const Color(0xFFFF5252) : const Color(0xFFFF8A80))
                    .withValues(alpha: 0.9)
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          c,
          isTank ? 3.2 : r * 0.7,
          Paint()..color = const Color(0xFFFFEBEE),
        );
        continue;
      }

      if (gun == AngryWordsGunKind.grenadeLauncher) {
        canvas.drawCircle(
          c + const Offset(1, 1.5),
          r,
          Paint()..color = Colors.black.withValues(alpha: 0.22),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = ui.Gradient.radial(
              c + Offset(-r * 0.3, -r * 0.3),
              r,
              const [Color(0xFFFFE082), Color(0xFFFF8F00), Color(0xFFE65100)],
              const [0.0, 0.45, 1.0],
            ),
        );
        canvas.drawCircle(
          c + Offset(0, -r * 0.15),
          r * 0.28,
          Paint()..color = const Color(0xFF5D4037),
        );
        continue;
      }

      if (gun == AngryWordsGunKind.rpg ||
          gun == AngryWordsGunKind.homingRocket) {
        final homing = gun == AngryWordsGunKind.homingRocket || b.homing;
        final body = Rect.fromCenter(
          center: c,
          width: r * (homing ? 2.4 : 2.8),
          height: r * 1.35,
        );
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(math.atan2(n.dy, n.dx));
        canvas.translate(-c.dx, -c.dy);
        canvas.drawOval(
          body.shift(const Offset(1.2, 1.2)),
          Paint()..color = Colors.black.withValues(alpha: 0.22),
        );
        canvas.drawOval(
          body,
          Paint()
            ..shader = ui.Gradient.linear(
              body.centerLeft,
              body.centerRight,
              homing
                  ? const [
                      Color(0xFFE1BEE7),
                      Color(0xFF7B1FA2),
                      Color(0xFF006064),
                    ]
                  : const [
                      Color(0xFFFFE082),
                      Color(0xFFFF6F00),
                      Color(0xFFBF360C),
                    ],
            ),
        );
        canvas.drawCircle(
          Offset(body.right - r * 0.15, c.dy),
          r * (homing ? 0.55 : 0.45),
          Paint()
            ..color = homing
                ? const Color(0xFF18FFFF)
                : const Color(0xFFFF3D00),
        );
        if (homing) {
          final blink = 0.55 + 0.45 * math.sin(world.simTime * 10 + b.radius);
          canvas.drawCircle(
            Offset(body.right - r * 0.15, c.dy),
            r * 0.28,
            Paint()..color = const Color(0xFFE040FB).withValues(alpha: blink),
          );
        }
        canvas.restore();
        canvas.drawLine(
          c - n * (homing ? r * 2.8 : r * 3.4),
          c - n * r * 0.4,
          Paint()
            ..color =
                (homing ? const Color(0xFF80DEEA) : const Color(0xFFFFAB40))
                    .withValues(alpha: 0.55)
            ..strokeWidth = r * 0.45
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      if (gun == AngryWordsGunKind.doomsdayMg) {
        canvas.drawCircle(
          c,
          r * 1.35,
          Paint()
            ..color = const Color(0xFFFF3D00).withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawCircle(
          c,
          r * 1.15,
          Paint()
            ..shader = ui.Gradient.radial(
              c,
              r,
              const [Color(0xFFFFF8E1), Color(0xFFFF6D00), Color(0xFFBF360C)],
              const [0.0, 0.45, 1.0],
            ),
        );
        canvas.drawLine(
          c - n * 22,
          c,
          Paint()
            ..color = const Color(0xFFFF5722).withValues(alpha: 0.8)
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          c - n * 14,
          c,
          Paint()
            ..color = const Color(0xFFFFECB3).withValues(alpha: 0.75)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      if (gun == AngryWordsGunKind.minigun ||
          gun == AngryWordsGunKind.gatling) {
        final heavy = gun == AngryWordsGunKind.gatling;
        canvas.drawCircle(
          c,
          r * (heavy ? 1.08 : 0.95),
          Paint()
            ..shader = ui.Gradient.radial(
              c,
              r,
              heavy
                  ? const [
                      Color(0xFFFFF8E1),
                      Color(0xFFFFB300),
                      Color(0xFFE65100),
                    ]
                  : const [
                      Color(0xFFFFFDE7),
                      Color(0xFFFFCA28),
                      Color(0xFFFF8F00),
                    ],
              const [0.0, 0.5, 1.0],
            ),
        );
        canvas.drawLine(
          c - n * (heavy ? 16.0 : 11.0),
          c,
          Paint()
            ..color = const Color(0xFFFFECB3).withValues(alpha: 0.7)
            ..strokeWidth = heavy ? 2.6 : 1.8
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      if (gun == AngryWordsGunKind.tankCannon ||
          gun == AngryWordsGunKind.twinTank ||
          gun == AngryWordsGunKind.siege) {
        final siege = gun == AngryWordsGunKind.siege;
        final halo = siege ? r * 1.35 : r * 1.15;
        canvas.drawCircle(
          c,
          halo,
          Paint()
            ..color = const Color(0xFFFF8F00).withValues(alpha: 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        canvas.drawCircle(
          c + const Offset(1.5, 1.5),
          r,
          Paint()..color = Colors.black.withValues(alpha: 0.25),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = ui.Gradient.radial(
              c + Offset(-r * 0.3, -r * 0.3),
              r,
              siege
                  ? const [
                      Color(0xFFFFE0B2),
                      Color(0xFFFF6D00),
                      Color(0xFF3E2723),
                    ]
                  : const [
                      Color(0xFFFFF3E0),
                      Color(0xFFFF8F00),
                      Color(0xFFBF360C),
                    ],
              const [0.0, 0.45, 1.0],
            ),
        );
        canvas.drawLine(
          c - n * (siege ? r * 1.8 : r * 1.3),
          c,
          Paint()
            ..color = const Color(0xFFFFAB40).withValues(alpha: 0.5)
            ..strokeWidth = r * 0.35
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      final core = switch (b.element) {
        AngryWordsBulletElement.ice => const [
          Color(0xFFE1F5FE),
          Color(0xFF4FC3F7),
          Color(0xFF0277BD),
        ],
        AngryWordsBulletElement.fire => const [
          Color(0xFFFFF8E1),
          Color(0xFFFF6D00),
          Color(0xFFD50000),
        ],
        AngryWordsBulletElement.plasma => const [
          Color(0xFFE1F5FE),
          Color(0xFF40C4FF),
          Color(0xFFD500F9),
        ],
        AngryWordsBulletElement.laser => const [
          Color(0xFFFFFFFF),
          Color(0xFFFF5252),
          Color(0xFFD50000),
        ],
        AngryWordsBulletElement.explosive => const [
          Color(0xFFFFF8E1),
          Color(0xFFFF8F00),
          Color(0xFFBF360C),
        ],
        AngryWordsBulletElement.normal => const [
          Color(0xFFFFFDE7),
          Color(0xFFFFCA28),
          Color(0xFFFF6F00),
        ],
      };
      final streak = switch (b.element) {
        AngryWordsBulletElement.ice => const Color(0xFF81D4FA),
        AngryWordsBulletElement.fire => const Color(0xFFFFAB40),
        AngryWordsBulletElement.plasma => const Color(0xFF80D8FF),
        AngryWordsBulletElement.laser => const Color(0xFFFF8A80),
        AngryWordsBulletElement.explosive => const Color(0xFFFFAB40),
        AngryWordsBulletElement.normal => const Color(0xFFFFECB3),
      };
      if (b.homing) {
        canvas.drawCircle(
          c - n * (r + 6),
          r * 0.55,
          Paint()..color = streak.withValues(alpha: 0.35),
        );
      }
      canvas.drawCircle(
        c + const Offset(1, 1.5),
        r,
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            c + Offset(-r * 0.35, -r * 0.35),
            r,
            core,
            const [0.0, 0.45, 1.0],
          ),
      );
      if (len > 1) {
        final streakLen =
            10 +
            r +
            (len > 1400 ? 16.0 : 0.0) +
            (b.pierceLeft >= 2 ? 10.0 : 0.0);
        canvas.drawLine(
          c - n * streakLen,
          c,
          Paint()
            ..color = streak.withValues(alpha: len > 1400 ? 0.75 : 0.55)
            ..strokeWidth = 1.6 + r * 0.22 + (b.pierceLeft >= 2 ? 0.8 : 0)
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _paintMuzzleFlash(Canvas canvas) {
    final flash = world.muzzleFlash;
    if (flash <= 0.01) return;
    final gun = world.loadout.gun;
    final aimA = math.atan2(world.gunAim.dy, world.gunAim.dx);
    final element = world.loadout.element;

    final style = switch (gun) {
      AngryWordsGunKind.grenadeLauncher => (
        glow: const Color(0xFFFFB74D),
        core: const Color(0xFFFFF3E0),
        scale: 0.95,
        sparks: 6,
        barrels: 1,
      ),
      AngryWordsGunKind.rpg => (
        glow: const Color(0xFFFF6D00),
        core: const Color(0xFFFFE0B2),
        scale: 1.25,
        sparks: 12,
        barrels: 1,
      ),
      AngryWordsGunKind.homingRocket => (
        glow: const Color(0xFF26C6DA),
        core: const Color(0xFFE1BEE7),
        scale: 1.05,
        sparks: 8,
        barrels: 1,
      ),
      AngryWordsGunKind.minigun => (
        glow: const Color(0xFFFFF59D),
        core: const Color(0xFFFFFDE7),
        scale: 0.85,
        sparks: 10,
        barrels: 1,
      ),
      AngryWordsGunKind.gatling => (
        glow: const Color(0xFFFFCA28),
        core: const Color(0xFFFFECB3),
        scale: 1.15,
        sparks: 14,
        barrels: 1,
      ),
      AngryWordsGunKind.laserTank => (
        glow: const Color(0xFFFF1744),
        core: const Color(0xFFFFEBEE),
        scale: 0.55,
        sparks: 3,
        barrels: 1,
      ),
      AngryWordsGunKind.tankCannon => (
        glow: const Color(0xFFFF8F00),
        core: const Color(0xFFFFF3E0),
        scale: 1.35,
        sparks: 11,
        barrels: 2,
      ),
      AngryWordsGunKind.twinTank => (
        glow: const Color(0xFFFFA726),
        core: const Color(0xFFFFF8E1),
        scale: 1.2,
        sparks: 10,
        barrels: 2,
      ),
      AngryWordsGunKind.siege => (
        glow: const Color(0xFFFF8A65),
        core: const Color(0xFFFFF3E0),
        scale: 1.25,
        sparks: 12,
        barrels: 3,
      ),
      AngryWordsGunKind.doomsdayMg => (
        glow: const Color(0xFFFF6D00),
        core: const Color(0xFFFFF176),
        scale: 1.6,
        sparks: 18,
        barrels: 5,
      ),
      _ => (
        glow: switch (element) {
          AngryWordsBulletElement.ice => const Color(0xFF81D4FA),
          AngryWordsBulletElement.fire => const Color(0xFFFF6E40),
          AngryWordsBulletElement.plasma => const Color(0xFFE040FB),
          AngryWordsBulletElement.laser => const Color(0xFFFF5252),
          AngryWordsBulletElement.explosive => const Color(0xFFFFAB40),
          AngryWordsBulletElement.normal => const Color(0xFFFFF59D),
        },
        core: switch (element) {
          AngryWordsBulletElement.ice => const Color(0xFFE1F5FE),
          AngryWordsBulletElement.fire => const Color(0xFFFFF8E1),
          AngryWordsBulletElement.plasma => const Color(0xFFF3E5F5),
          AngryWordsBulletElement.laser => const Color(0xFFFFEBEE),
          AngryWordsBulletElement.explosive => const Color(0xFFFFF3E0),
          AngryWordsBulletElement.normal => const Color(0xFFFFF8E1),
        },
        scale: 1.0,
        sparks: world.loadout.splashRadius > 0 ? 8 : 5,
        barrels: 1,
      ),
    };
    final glow = style.glow;
    final core = style.core;
    final scale = (1.0 + world.loadout.recoilKick * 0.12) * style.scale;
    final sparks = style.sparks;
    final barrelFlashes = style.barrels;

    void flashAt(Offset at, double s) {
      canvas.drawCircle(
        at,
        (10 + flash * 16) * s,
        Paint()
          ..color = glow.withValues(alpha: 0.55 * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        at,
        (4 + flash * 7) * s,
        Paint()..color = core.withValues(alpha: 0.9 * flash),
      );
      for (var i = 0; i < sparks; i++) {
        final a = aimA + (i - sparks * 0.5) * 0.18;
        final d = 12 + flash * 18 + i * 2.0;
        canvas.drawCircle(
          at + Offset(math.cos(a) * d, math.sin(a) * d),
          1.8 + flash,
          Paint()..color = glow.withValues(alpha: 0.75 * flash),
        );
      }
    }

    for (var mount = 0; mount < world.gunMountCount; mount++) {
      final tip = world.muzzleForMount(mount) +
          world.gunAim * (28 - world.gunRecoil * 10);
      if (barrelFlashes >= 5) {
        final side = Offset(-world.gunAim.dy, world.gunAim.dx);
        final s = scale * 0.55;
        for (final o in [-2.0, -1.0, 0.0, 1.0, 2.0]) {
          flashAt(tip + side * (8 * o), s * (o == 0 ? 1.15 : 0.9));
        }
      } else if (barrelFlashes >= 2) {
        final side = Offset(-world.gunAim.dy, world.gunAim.dx);
        final gap = barrelFlashes == 3 ? 14.0 : 16.0;
        final s = scale * (barrelFlashes == 3 ? 0.72 : 0.85);
        if (barrelFlashes == 3) {
          flashAt(tip + side * gap, s);
          flashAt(tip, s);
          flashAt(tip - side * gap, s);
        } else {
          flashAt(tip + side * gap, s);
          flashAt(tip - side * gap, s);
        }
      } else {
        flashAt(tip, scale);
      }
      if (gun == AngryWordsGunKind.doomsdayMg) {
        canvas.drawCircle(
          tip,
          28 + flash * 34,
          Paint()
            ..color = const Color(0xFFFF3D00).withValues(alpha: 0.28 * flash)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );
        canvas.drawCircle(
          tip,
          14 + flash * 18,
          Paint()
            ..color = const Color(0xFFFFAB40).withValues(alpha: 0.4 * flash)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
    }
  }

  void _paintProps(Canvas canvas) {
    for (final P in world.props) {
      if (P.removed || !P.isSpawnVisible) continue;
      final spawn = Curves.easeOutBack.transform(P.spawnT.clamp(0.0, 1.0));
      final magmaPulse = P.material == AngryWordsPropMaterial.magma
          ? 0.08 * (0.5 + 0.5 * math.sin(world.simTime * 6.5 + P.phase))
          : 0.0;
      final stretch =
          P.material == AngryWordsPropMaterial.rubber && P.stretchT > 0
          ? 1.0 + P.stretchT * 0.42
          : 1.0;
      final isEgg = P.material == AngryWordsPropMaterial.egg;
      final ovalW = isEgg ? 0.86 : 1.0 / stretch;
      final ovalH = isEgg ? 1.28 : stretch;
      final pulse =
          1.0 + 0.06 * math.sin(world.simTime * 4.2 + P.phase) + magmaPulse;
      final r = P.radius * pulse * (0.2 + 0.8 * spawn);
      final c = P.pos;
      final flash = P.hitFlash;
      final spawnAlpha = spawn.clamp(0.0, 1.0);

      if (P.skinEmoji != null) {
        _paintEmojiProp(canvas, P, c, r, spawnAlpha, flash);
        continue;
      }

      final colors = angryWordsColorsForMaterial(P.material, P.palette);
      final glassLike =
          P.material == AngryWordsPropMaterial.glass ||
          P.material == AngryWordsPropMaterial.ice ||
          P.material == AngryWordsPropMaterial.water ||
          P.material == AngryWordsPropMaterial.crystal ||
          P.material == AngryWordsPropMaterial.foam ||
          isEgg;

      canvas.saveLayer(
        Rect.fromCircle(center: c, radius: r * math.max(ovalW, ovalH) + 14),
        Paint()..color = Colors.white.withValues(alpha: spawnAlpha),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: c + const Offset(0, 3.5),
          width: r * 2 * ovalW,
          height: r * 2 * ovalH,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.16),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2 * ovalW, height: r * 2 * ovalH),
        Paint()
          ..shader = ui.Gradient.radial(
            c + Offset(-r * 0.32, -r * 0.34),
            r * 1.2,
            [
              Colors.white.withValues(alpha: glassLike ? 0.82 : 0.98),
              Color.lerp(colors[0], Colors.white, flash * 0.55)!,
              Color.lerp(colors[1], Colors.white, flash * 0.35)!,
            ],
            const [0.0, 0.45, 1.0],
          ),
      );

      _paintPropMaterialDetail(canvas, P, c, r, colors);

      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(-r * 0.28, -r * 0.32),
          width: r * (glassLike ? 0.72 : 0.55),
          height: r * (glassLike ? 0.48 : 0.38),
        ),
        Paint()
          ..color = Colors.white.withValues(
            alpha: glassLike
                ? 0.88
                : P.material == AngryWordsPropMaterial.slime
                ? 0.55
                : 0.72,
          ),
      );

      if (P.material == AngryWordsPropMaterial.candy ||
          P.material == AngryWordsPropMaterial.plastic ||
          P.material == AngryWordsPropMaterial.gold) {
        final spark = Paint()
          ..color = Colors.white.withValues(alpha: 0.92)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        final s = r * (P.material == AngryWordsPropMaterial.gold ? 0.28 : 0.22);
        final o = Offset(r * 0.22, -r * 0.08);
        canvas.drawLine(c + o + Offset(-s, 0), c + o + Offset(s, 0), spark);
        canvas.drawLine(c + o + Offset(0, -s), c + o + Offset(0, s), spark);
      }

      final rim = switch (P.material) {
        AngryWordsPropMaterial.metal ||
        AngryWordsPropMaterial.gold => const Color(0xFFFFF8E1),
        AngryWordsPropMaterial.magma => const Color(0xFFFFAB40),
        AngryWordsPropMaterial.crystal => const Color(0xFFF3E5F5),
        AngryWordsPropMaterial.porcelain => const Color(0xFFEEEEEE),
        AngryWordsPropMaterial.egg => const Color(0xFFFFFDE7),
        _ => Colors.white,
      };
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2 * ovalW, height: r * 2 * ovalH),
        Paint()
          ..color = rim.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              P.material == AngryWordsPropMaterial.metal ||
                  P.material == AngryWordsPropMaterial.gold
              ? 2.1
              : 1.5,
      );

      if (P.maxHp >= 2 ||
          P.material == AngryWordsPropMaterial.stone ||
          P.material == AngryWordsPropMaterial.metal ||
          P.material == AngryWordsPropMaterial.gold ||
          P.material == AngryWordsPropMaterial.crystal) {
        final armorColor = switch (P.material) {
          AngryWordsPropMaterial.metal => const Color(0xFF90A4AE),
          AngryWordsPropMaterial.gold => const Color(0xFFFFD54F),
          AngryWordsPropMaterial.crystal => const Color(0xFFCE93D8),
          _ => P.hp >= 3 ? const Color(0xFFFFD54F) : const Color(0xFFFFAB40),
        };
        final crack = 1.0 - (P.hp / P.maxHp).clamp(0.0, 1.0);
        canvas.drawCircle(
          c,
          r + 2.2,
          Paint()
            ..color = armorColor.withValues(alpha: 0.5 + flash * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = P.hp >= 3 ? 2.8 : 2.0,
        );
        if (crack > 0.15) {
          final stoneCrack = P.material == AngryWordsPropMaterial.stone;
          final crackPaint = Paint()
            ..color = Colors.black.withValues(
              alpha: 0.22 + crack * (stoneCrack ? 0.4 : 0.25),
            )
            ..strokeWidth = stoneCrack ? 1.55 : 1.1
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            c + Offset(-r * 0.35, -r * 0.1),
            c + Offset(r * 0.1, r * 0.35 * crack),
            crackPaint,
          );
          if (crack > 0.4) {
            canvas.drawLine(
              c + Offset(r * 0.05, -r * 0.3),
              c + Offset(r * 0.35, r * 0.15),
              crackPaint,
            );
            if (stoneCrack) {
              canvas.drawLine(
                c + Offset(-r * 0.2, r * 0.25),
                c + Offset(r * 0.3, -r * 0.05),
                crackPaint..strokeWidth = 1.2,
              );
            }
          }
        }
      }
      if (P.freezeT > 0.05) {
        final status = P.material == AngryWordsPropMaterial.slime
            ? const Color(0xFF76FF03)
            : const Color(0xFF81D4FA);
        canvas.drawCircle(
          c,
          r + 1.5,
          Paint()
            ..color = status.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        if (P.material == AngryWordsPropMaterial.slime) {
          canvas.drawCircle(
            c + Offset(r * 0.2, r * 0.35),
            r * 0.12,
            Paint()..color = status.withValues(alpha: 0.55),
          );
        }
      }
      if (flash > 0.05) {
        canvas.drawCircle(
          c,
          r * (1.05 + flash * 0.12),
          Paint()..color = Colors.white.withValues(alpha: 0.35 * flash),
        );
      }

      final cargo = P.cargo;
      if (cargo != null) {
        final cargoTint = angryWordsLetterTint(P.cargoTintIndex ?? P.palette);
        final pulseRing = 0.35 + 0.2 * math.sin(world.simTime * 5 + P.phase);
        canvas.drawCircle(
          c,
          r * 0.92,
          Paint()..color = cargoTint.withValues(alpha: 0.28),
        );
        canvas.drawCircle(
          c,
          r + 3.5,
          Paint()
            ..color = cargoTint.withValues(alpha: pulseRing + 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: cargo.char.toUpperCase(),
            style: TextStyle(
              color: const Color(0xFF4E342E).withValues(alpha: 0.5),
              fontSize: math.min(r * 0.9, 20),
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      }
      canvas.restore();
    }
  }

  void _paintYolks(Canvas canvas) {
    if (world.yolks.isEmpty) return;
    for (final Y in world.yolks) {
      if (Y.removed) continue;
      final c = Y.pos;
      final rw = Y.radius * (Y.onFloor ? 1.55 : 1.05);
      final rh = Y.radius * (Y.onFloor ? 0.72 : 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: c + const Offset(0, 2.2),
          width: rw * 2,
          height: rh * 2,
        ),
        Paint()..color = const Color(0xFFFF8F00).withValues(alpha: 0.22),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rw * 2, height: rh * 2),
        Paint()
          ..shader = ui.Gradient.radial(
            c + Offset(-rw * 0.25, -rh * 0.35),
            rw * 1.15,
            const [
              Color(0xFFFFF59D),
              Color(0xFFFFD54F),
              Color(0xFFFFA000),
            ],
            const [0.0, 0.45, 1.0],
          ),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(-rw * 0.22, -rh * 0.28),
          width: rw * 0.55,
          height: rh * 0.35,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rw * 2, height: rh * 2),
        Paint()
          ..color = const Color(0xFFFF6F00).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  /// Stages 35–36: material physics stays; visual is a varied emoji instead of a disc.
  void _paintEmojiProp(
    Canvas canvas,
    AngryWordsPropBubble P,
    Offset c,
    double r,
    double spawnAlpha,
    double flash,
  ) {
    final emoji = P.skinEmoji;
    if (emoji == null) return;

    canvas.saveLayer(
      Rect.fromCircle(center: c, radius: r * 1.55 + 12),
      Paint()..color = Colors.white.withValues(alpha: spawnAlpha),
    );

    canvas.drawCircle(
      c + const Offset(0, 2.8),
      r * 0.72,
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: r * 1.9,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));

    if (P.maxHp >= 2 ||
        P.material == AngryWordsPropMaterial.stone ||
        P.material == AngryWordsPropMaterial.metal ||
        P.material == AngryWordsPropMaterial.gold ||
        P.material == AngryWordsPropMaterial.crystal) {
      final armorColor = switch (P.material) {
        AngryWordsPropMaterial.metal => const Color(0xFF90A4AE),
        AngryWordsPropMaterial.gold => const Color(0xFFFFD54F),
        AngryWordsPropMaterial.crystal => const Color(0xFFCE93D8),
        _ => P.hp >= 3 ? const Color(0xFFFFD54F) : const Color(0xFFFFAB40),
      };
      final crack = 1.0 - (P.hp / P.maxHp).clamp(0.0, 1.0);
      canvas.drawCircle(
        c,
        r + 2.2,
        Paint()
          ..color = armorColor.withValues(alpha: 0.5 + flash * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = P.hp >= 3 ? 2.8 : 2.0,
      );
      if (crack > 0.15) {
        final crackPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.28 + crack * 0.3)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          c + Offset(-r * 0.35, -r * 0.1),
          c + Offset(r * 0.1, r * 0.35 * crack),
          crackPaint,
        );
        if (crack > 0.4) {
          canvas.drawLine(
            c + Offset(r * 0.05, -r * 0.3),
            c + Offset(r * 0.35, r * 0.15),
            crackPaint,
          );
        }
      }
    }

    if (P.freezeT > 0.05) {
      final status = P.material == AngryWordsPropMaterial.slime
          ? const Color(0xFF76FF03)
          : const Color(0xFF81D4FA);
      canvas.drawCircle(
        c,
        r + 1.5,
        Paint()
          ..color = status.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
    if (flash > 0.05) {
      canvas.drawCircle(
        c,
        r * (1.05 + flash * 0.12),
        Paint()..color = Colors.white.withValues(alpha: 0.35 * flash),
      );
    }

    final cargo = P.cargo;
    if (cargo != null) {
      final cargoTint = angryWordsLetterTint(P.cargoTintIndex ?? P.palette);
      final pulseRing = 0.35 + 0.2 * math.sin(world.simTime * 5 + P.phase);
      canvas.drawCircle(
        c,
        r * 0.92,
        Paint()..color = cargoTint.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        c,
        r + 3.5,
        Paint()
          ..color = cargoTint.withValues(alpha: pulseRing + 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      final letterTp = TextPainter(
        text: TextSpan(
          text: cargo.char.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFF4E342E).withValues(alpha: 0.55),
            fontSize: math.min(r * 0.75, 18),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      letterTp.paint(
        canvas,
        c - Offset(letterTp.width / 2, letterTp.height / 2),
      );
    }

    canvas.restore();
  }

  void _paintPropMaterialDetail(
    Canvas canvas,
    AngryWordsPropBubble P,
    Offset c,
    double r,
    List<Color> colors,
  ) {
    switch (P.material) {
      case AngryWordsPropMaterial.wood:
        final grain = Paint()
          ..color = const Color(0xFF5D4037).withValues(alpha: 0.38)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          c + Offset(-r * 0.45, -r * 0.1),
          c + Offset(r * 0.4, -r * 0.18),
          grain,
        );
        canvas.drawLine(
          c + Offset(-r * 0.4, r * 0.15),
          c + Offset(r * 0.35, r * 0.08),
          grain,
        );
        canvas.drawLine(
          c + Offset(-r * 0.3, r * 0.32),
          c + Offset(r * 0.25, r * 0.28),
          grain..strokeWidth = 0.9,
        );
      case AngryWordsPropMaterial.stone:
      case AngryWordsPropMaterial.metal:
        canvas.drawCircle(
          c + Offset(-r * 0.15, r * 0.1),
          r * 0.18,
          Paint()..color = Colors.black.withValues(alpha: 0.14),
        );
        canvas.drawCircle(
          c + Offset(r * 0.22, -r * 0.08),
          r * 0.12,
          Paint()..color = Colors.black.withValues(alpha: 0.1),
        );
        if (P.material == AngryWordsPropMaterial.metal) {
          canvas.drawLine(
            c + Offset(-r * 0.35, -r * 0.2),
            c + Offset(r * 0.1, -r * 0.4),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.55)
              ..strokeWidth = 1.8
              ..strokeCap = StrokeCap.round,
          );
        }
      case AngryWordsPropMaterial.water:
        canvas.drawCircle(
          c + Offset(r * 0.1, r * 0.15),
          r * 0.24,
          Paint()..color = Colors.white.withValues(alpha: 0.3),
        );
        canvas.drawCircle(
          c + Offset(-r * 0.2, r * 0.05),
          r * 0.1,
          Paint()..color = Colors.white.withValues(alpha: 0.22),
        );
      case AngryWordsPropMaterial.ice:
        for (var i = 0; i < 3; i++) {
          final a = P.phase + i * 2.1;
          canvas.drawLine(
            c,
            c + Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.45)
              ..strokeWidth = 1.3
              ..strokeCap = StrokeCap.round,
          );
        }
      case AngryWordsPropMaterial.crystal:
        final facet = Path()
          ..moveTo(c.dx, c.dy - r * 0.7)
          ..lineTo(c.dx + r * 0.55, c.dy)
          ..lineTo(c.dx, c.dy + r * 0.55)
          ..lineTo(c.dx - r * 0.55, c.dy)
          ..close();
        canvas.drawPath(
          facet,
          Paint()
            ..color = const Color(0xFFF3E5F5).withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      case AngryWordsPropMaterial.porcelain:
        final crack = Paint()
          ..color = const Color(0xFF9E9E9E).withValues(alpha: 0.45)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          c + Offset(-r * 0.25, -r * 0.35),
          c + Offset(r * 0.05, r * 0.1),
          crack,
        );
        canvas.drawLine(
          c + Offset(r * 0.05, r * 0.1),
          c + Offset(r * 0.35, -r * 0.05),
          crack,
        );
      case AngryWordsPropMaterial.egg:
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(r * 0.12, r * 0.22),
            width: r * 0.55,
            height: r * 0.7,
          ),
          Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.22),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(-r * 0.18, -r * 0.28),
            width: r * 0.42,
            height: r * 0.28,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.78),
        );
        if (P.hitFlash > 0.35) {
          final crack = Paint()
            ..color = const Color(
              0xFF8D6E63,
            ).withValues(alpha: 0.55 * P.hitFlash)
            ..strokeWidth = 1.15
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            c + Offset(-r * 0.15, -r * 0.45),
            c + Offset(r * 0.05, r * 0.15),
            crack,
          );
          canvas.drawLine(
            c + Offset(r * 0.05, r * 0.15),
            c + Offset(r * 0.28, -r * 0.2),
            crack,
          );
        }
      case AngryWordsPropMaterial.sand:
        final grit = Paint()..color = colors[1].withValues(alpha: 0.35);
        for (var i = 0; i < 5; i++) {
          final a = P.phase + i * 1.3;
          canvas.drawCircle(
            c + Offset(math.cos(a) * r * 0.4, math.sin(a) * r * 0.35),
            1.2 + (i % 2),
            grit,
          );
        }
      case AngryWordsPropMaterial.foam:
        canvas.drawCircle(
          c + Offset(-r * 0.15, -r * 0.1),
          r * 0.55,
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
        canvas.drawCircle(
          c + Offset(r * 0.25, r * 0.1),
          r * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.28),
        );
      case AngryWordsPropMaterial.magma:
        canvas.drawCircle(
          c,
          r * 0.55,
          Paint()
            ..color = const Color(0xFFFFEA00).withValues(
              alpha: 0.35 + 0.25 * math.sin(world.simTime * 7 + P.phase),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          c + Offset(r * 0.15, -r * 0.1),
          r * 0.18,
          Paint()..color = const Color(0xFFFFAB40).withValues(alpha: 0.7),
        );
      case AngryWordsPropMaterial.gold:
        for (var i = 0; i < 4; i++) {
          final a = world.simTime * 2.2 + i * math.pi / 2 + P.phase;
          canvas.drawCircle(
            c + Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55),
            1.6,
            Paint()..color = Colors.white.withValues(alpha: 0.85),
          );
        }
      case AngryWordsPropMaterial.slime:
        canvas.drawCircle(
          c + Offset(r * 0.18, r * 0.28),
          r * 0.16,
          Paint()..color = const Color(0xFFCCFF90).withValues(alpha: 0.65),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(-r * 0.1, r * 0.45),
            width: r * 0.22,
            height: r * 0.35,
          ),
          Paint()..color = colors[1].withValues(alpha: 0.55),
        );
      case AngryWordsPropMaterial.rubber:
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.62),
          0.4,
          2.2,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      case AngryWordsPropMaterial.glass:
        canvas.drawLine(
          c + Offset(-r * 0.2, -r * 0.35),
          c + Offset(r * 0.35, -r * 0.05),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      case AngryWordsPropMaterial.candy:
      case AngryWordsPropMaterial.plastic:
        break;
    }
  }

  void _paintLetters(Canvas canvas) {
    for (final L in world.letters) {
      if (L.removed) continue;
      final shake = world.letterShake[L.letter.id] ?? 0;
      final shakeOff = shake > 0
          ? Offset(
              math.sin(shake * 42) * (3.5 + 9 * shake),
              math.cos(shake * 31) * (1.2 + 3.5 * shake),
            )
          : Offset.zero;
      final c = L.pos + shakeOff;
      final dragged = world.draggedLetterId == L.letter.id;
      final reveal = Curves.easeOutBack.transform(L.revealT.clamp(0.0, 1.0));
      final r = L.radius * (dragged ? 1.08 : 1.0) * (0.35 + 0.65 * reveal);
      final alpha = (0.25 + 0.75 * L.revealT).clamp(0.0, 1.0);
      // Letters are eggs: tall oval shell with the char on top.
      final ovalW = 0.86;
      final ovalH = 1.28;
      final rw = r * ovalW;
      final rh = r * ovalH;

      canvas.saveLayer(
        Rect.fromCenter(center: c, width: rw * 2 + 16, height: rh * 2 + 16),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: c + const Offset(0, 3),
          width: rw * 2,
          height: rh * 2,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.16),
      );

      final baseTint = angryWordsLetterTint(L.tintIndex);
      final tint = shake > 0 ? const Color(0xFFFF5252) : baseTint;
      final shellLight = Color.lerp(
        const Color(0xFFFFF8E1),
        baseTint,
        0.18,
      )!;
      final shellDark = Color.lerp(
        const Color(0xFFE8D5B5),
        tint,
        shake > 0 ? 0.45 : 0.22,
      )!;

      canvas.drawOval(
        Rect.fromCenter(center: c, width: rw * 2, height: rh * 2),
        Paint()
          ..shader = ui.Gradient.radial(
            c + Offset(-rw * 0.28, -rh * 0.32),
            r * 1.2,
            [
              Colors.white.withValues(alpha: 0.96),
              shellLight,
              shellDark,
            ],
            const [0.0, 0.45, 1.0],
          ),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(rw * 0.12, rh * 0.22),
          width: rw * 0.55,
          height: rh * 0.7,
        ),
        Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.2),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(-rw * 0.18, -rh * 0.28),
          width: rw * 0.42,
          height: rh * 0.28,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.72),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rw * 2, height: rh * 2),
        Paint()
          ..color = const Color(0xFFFFFDE7).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: L.letter.char.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFF4E342E),
            fontSize: math.min(r * 0.9, 22),
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(color: tint.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
      if (L.revealT < 0.95) {
        canvas.drawOval(
          Rect.fromCenter(
            center: c,
            width: rw * 2 * (1.35 - L.revealT * 0.35),
            height: rh * 2 * (1.35 - L.revealT * 0.35),
          ),
          Paint()
            ..color = const Color(
              0xFFFFD54F,
            ).withValues(alpha: 0.45 * (1 - L.revealT))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      canvas.restore();
    }
  }

  /// RDR2-style focus reticle on the locked / soft-locked letter.
  void _paintTargetLock(Canvas canvas) {
    final id = world.lockedLetterId;
    if (id == null) return;
    final L = world.letterById(id);
    if (L == null) return;
    final pulse = world.softLockPulse.clamp(0.0, 1.0);
    final aiming = world.aiming;
    final c = L.pos;
    final r = L.radius + 6 + pulse * 4;
    final accent = aiming ? const Color(0xFFFF5252) : const Color(0xFFFFD54F);
    final spin = world.simTime * (aiming ? 2.4 : 1.1);

    canvas.drawCircle(
      c,
      r + 10,
      Paint()
        ..color = accent.withValues(alpha: 0.12 + 0.16 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = accent.withValues(alpha: 0.55 + 0.35 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = aiming ? 2.6 : 2.0,
    );
    canvas.drawCircle(
      c,
      r * 0.72,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 + 0.25 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Rotating diamond brackets (Dead Eye–like mark).
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin);
    final bracket = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final outer = r + 3;
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      canvas.drawLine(Offset(0, -outer), Offset(5, -outer + 5), bracket);
      canvas.drawLine(Offset(0, -outer), Offset(-5, -outer + 5), bracket);
      canvas.restore();
    }
    canvas.restore();

    if (aiming) {
      final pathPaint = Paint()
        ..color = accent.withValues(alpha: 0.28 + 0.2 * pulse)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(world.muzzle.dx, world.muzzle.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, pathPaint..strokeCap = StrokeCap.round);
    }
  }

  void _paintExplosions(Canvas canvas) {
    for (final e in explosions) {
      final t = 1 - e.life;
      final ringScale = e.juicy ? 1.45 : 1.0;
      final soft =
          e.material == AngryWordsPropMaterial.foam ||
          e.material == AngryWordsPropMaterial.water ||
          e.material == AngryWordsPropMaterial.slime;
      canvas.drawCircle(
        e.at,
        (12 + t * (soft ? 50 : 42)) * ringScale,
        Paint()
          ..color = e.ringA.withValues(alpha: 0.55 * e.life)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (3.5 + (e.juicy ? 1.6 : 0)) * e.life,
      );
      canvas.drawCircle(
        e.at,
        (8 + t * 28) * ringScale,
        Paint()
          ..color = e.ringB.withValues(alpha: 0.4 * e.life)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, soft ? 14 : 10),
      );
      if (e.juicy) {
        canvas.drawCircle(
          e.at,
          6 + t * 54,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.32 * e.life)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
        );
      }
      if (e.steamy) {
        canvas.drawCircle(
          e.at + Offset(0, -t * 28),
          10 + t * 36,
          Paint()
            ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.35 * e.life)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );
      }
      for (final bit in e.bits) {
        final dist = bit.speed * t * (e.juicy ? 1.25 : 1.0);
        final lift = soft ? t * 22 : t * 36;
        final p = Offset(
          e.at.dx + math.cos(bit.angle) * dist,
          e.at.dy + math.sin(bit.angle) * dist - lift,
        );
        _paintExplosionBit(canvas, bit, p, e.life, e.juicy);
      }
      if (e.char.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: e.char,
          style: TextStyle(
            color: const Color(0xFF2E7D32).withValues(alpha: e.life),
            fontSize: 22 + t * 10,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: const Color(0xFF69F0AE).withValues(alpha: e.life),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(e.at.dx - tp.width / 2, e.at.dy - tp.height / 2 - t * 70),
      );
    }
  }

  void _paintExplosionBit(
    Canvas canvas,
    AngryWordsExplosionBit bit,
    Offset p,
    double life,
    bool juicy,
  ) {
    final s = bit.size * life * (juicy ? 1.15 : 1.0);
    final paint = Paint()..color = bit.color.withValues(alpha: 0.92 * life);
    switch (bit.shape) {
      case AngryWordsBitShape.round:
        canvas.drawCircle(p, s, paint);
      case AngryWordsBitShape.dust:
        canvas.drawCircle(
          p,
          s * 1.35,
          Paint()
            ..color = bit.color.withValues(alpha: 0.45 * life)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      case AngryWordsBitShape.drop:
        canvas.drawOval(
          Rect.fromCenter(center: p, width: s * 0.85, height: s * 1.55),
          paint,
        );
      case AngryWordsBitShape.chip:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(bit.angle);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 2.2,
              height: s * 0.7,
            ),
            const Radius.circular(1.2),
          ),
          paint,
        );
        canvas.restore();
      case AngryWordsBitShape.shard:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(bit.angle);
        final path = Path()
          ..moveTo(0, -s * 1.6)
          ..lineTo(s * 0.55, s * 0.9)
          ..lineTo(-s * 0.45, s * 0.7)
          ..close();
        canvas.drawPath(path, paint);
        canvas.restore();
      case AngryWordsBitShape.spark:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(bit.angle);
        canvas.drawLine(
          Offset(-s * 1.4, 0),
          Offset(s * 1.4, 0),
          Paint()
            ..color = bit.color.withValues(alpha: 0.92 * life)
            ..strokeWidth = math.max(1.2, s * 0.45)
            ..strokeCap = StrokeCap.round,
        );
        canvas.restore();
      case AngryWordsBitShape.glitter:
        final g = Paint()
          ..color = bit.color.withValues(alpha: 0.95 * life)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p + Offset(-s, 0), p + Offset(s, 0), g);
        canvas.drawLine(p + Offset(0, -s), p + Offset(0, s), g);
        canvas.drawCircle(p, s * 0.35, paint);
    }
  }

  void _paintAimPreview(Canvas canvas) {
    // Locked on a letter → reticle only (no dashed trajectory).
    // Empty aim → show ballistic prediction dashes.
    final lockedOnLetter = world.aiming && world.lockedLetterId != null;
    if (!lockedOnLetter) {
      final preview = world.aimPreview();
      if (preview != null && preview.path.length >= 2) {
        final power = world.powerNorm;
        final color = preview.hitsLetter
            ? Color.lerp(
                const Color(0xFF69F0AE),
                const Color(0xFF00E676),
                power,
              )!
            : Color.lerp(
                const Color(0xFFFFF176),
                const Color(0xFFFF6D00),
                power,
              )!;
        // Stronger pull → thicker, denser dashes (reads as more speed).
        _drawDottedPath(
          canvas,
          preview.path,
          Paint()
            ..color = color.withValues(alpha: 0.75 + power * 0.2)
            ..strokeWidth = 1.8 + power * 2.4
            ..strokeCap = StrokeCap.round,
        );
        final impact = preview.impact;
        if (impact != null) {
          canvas.drawCircle(
            impact,
            4.5 + power * 3.5,
            Paint()..color = color.withValues(alpha: 0.95),
          );
          canvas.drawCircle(
            impact,
            4.5 + power * 3.5,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
        }
      }
    }

    if (world.aiming && world.pullPoint != null) {
      _paintPullPowerMeter(canvas);
    }
  }

  /// Clear pull → power / speed readout while stretching the sling.
  void _paintPullPowerMeter(Canvas canvas) {
    final power = world.powerNorm;
    final m = world.muzzle;
    final pull = world.pullPoint!;
    final pullDelta = pull - m;
    final pullLen = pullDelta.distance;
    if (pullLen < 4) return;

    final pullDir = pullDelta / pullLen;
    final side = Offset(-pullDir.dy, pullDir.dx);
    final meterOrigin = m + side * 34 - pullDir * 6;

    // Track (empty) + fill (power).
    const trackH = 52.0;
    const trackW = 10.0;
    canvas.save();
    canvas.translate(meterOrigin.dx, meterOrigin.dy);
    final ang = math.atan2(pullDir.dy, pullDir.dx) + math.pi / 2;
    canvas.rotate(ang);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: trackW, height: trackH),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: trackW, height: trackH),
        const Radius.circular(5),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final fillH = (trackH - 4) * power;
    if (fillH > 0.5) {
      final fillColor = Color.lerp(
        const Color(0xFFFFF176),
        Color.lerp(const Color(0xFFFF8A65), const Color(0xFFFF1744), power)!,
        power,
      )!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            -trackW / 2 + 2,
            trackH / 2 - 2 - fillH,
            trackW / 2 - 2,
            trackH / 2 - 2,
          ),
          const Radius.circular(3.5),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, trackH / 2),
            Offset(0, -trackH / 2),
            [
              const Color(0xFFFFF59D),
              fillColor,
              const Color(0xFFFF1744),
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
    }
    // Tick marks at 25/50/75%.
    for (final t in [0.25, 0.5, 0.75]) {
      final y = trackH / 2 - 2 - (trackH - 4) * t;
      canvas.drawLine(
        Offset(-trackW / 2 - 2, y),
        Offset(-trackW / 2 + 2.5, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 1.1,
      );
    }
    canvas.restore();

    // Label: weak → max (thresholds match ease-out pull curve).
    final label = power < 0.22
        ? 'WEAK'
        : power < 0.52
            ? 'MID'
            : power < 0.82
                ? 'STRONG'
                : 'MAX';
    final labelColor = Color.lerp(
      const Color(0xFFFFF176),
      const Color(0xFFFF1744),
      power,
    )!;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 11 + power * 3,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelAt = meterOrigin - pullDir * (trackH * 0.85) + side * 2;
    tp.paint(canvas, labelAt - Offset(tp.width / 2, tp.height / 2));

    // Speed chevrons in launch direction (opposite of pull).
    final launchDir = -pullDir;
    final chevronCount = 1 + (power * 3).round().clamp(0, 3);
    for (var i = 0; i < chevronCount; i++) {
      final along = 28.0 + i * (10 + power * 6);
      final tip = m + launchDir * along;
      final wing = 5.0 + power * 3.5;
      final a = tip - launchDir * 7 + side * wing;
      final b = tip;
      final c = tip - launchDir * 7 - side * wing;
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = labelColor.withValues(alpha: 0.35 + 0.2 * power)
          ..strokeWidth = 2 + power
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        c,
        b,
        Paint()
          ..color = labelColor.withValues(alpha: 0.35 + 0.2 * power)
          ..strokeWidth = 2 + power
          ..strokeCap = StrokeCap.round,
      );
    }

    // Soft glow at muzzle scales with charge.
    canvas.drawCircle(
      m,
      12 + power * 22,
      Paint()
        ..color = labelColor.withValues(alpha: 0.08 + power * 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawDottedPath(Canvas canvas, List<Offset> pts, Paint paint) {
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final total = (b - a).distance;
      if (total < 0.5) continue;
      final dir = (b - a) / total;
      const dash = 5.0;
      const gap = 5.0;
      var d = 0.0;
      // Alternate dashes along the whole polyline for a continuous feel.
      final startGap = (i * 7) % (dash + gap);
      d = -startGap;
      while (d < total) {
        final d0 = math.max(0.0, d);
        final d1 = math.min(d + dash, total);
        if (d1 > d0) {
          canvas.drawLine(a + dir * d0, a + dir * d1, paint);
        }
        d += dash + gap;
      }
    }
  }

  void _paintCannon(Canvas canvas) {
    if (world.usesGun || world.phase == AngryWordsPhase.freeing) {
      _paintBlaster(canvas);
      return;
    }
    _paintSlingshot(canvas);
  }

  void _paintBlaster(Canvas canvas) {
    final mounts = world.gunMountCount;
    for (var i = 0; i < mounts; i++) {
      _paintBlasterAt(canvas, world.muzzleForMount(i));
    }
  }

  void _paintBlasterAt(Canvas canvas, Offset m) {
    final angle = math.atan2(world.gunAim.dy, world.gunAim.dx);
    final kick = world.gunRecoil * 6;
    final gun = world.loadout.gun;
    final visual = gun.visual;
    final stageBoost = (world.loadout.profileIndex / 49.0).clamp(0.0, 1.0);
    // Unique per-stage accent so neighboring guns never feel identical.
    final stageAccent = HSVColor.fromAHSV(
      1,
      (world.loadout.profileIndex * 27.0) % 360.0,
      0.55 + stageBoost * 0.25,
      0.92,
    ).toColor();

    var bodyColors = switch (visual) {
      AngryWordsGunVisual.tinyPistol => const [
        Color(0xFFA1887F),
        Color(0xFF5D4037),
      ],
      AngryWordsGunVisual.pistol ||
      AngryWordsGunVisual.dual => const [Color(0xFF8D6E63), Color(0xFF4E342E)],
      AngryWordsGunVisual.revolver => const [
        Color(0xFFA1887F),
        Color(0xFF3E2723),
      ],
      AngryWordsGunVisual.smg => const [Color(0xFF607D8B), Color(0xFF263238)],
      AngryWordsGunVisual.shotgun => const [
        Color(0xFF8D6E63),
        Color(0xFF5D4037),
      ],
      AngryWordsGunVisual.rifle => const [Color(0xFF78909C), Color(0xFF37474F)],
      AngryWordsGunVisual.sniper => const [
        Color(0xFF546E7A),
        Color(0xFF263238),
      ],
      AngryWordsGunVisual.ice => const [Color(0xFF90CAF9), Color(0xFF1565C0)],
      AngryWordsGunVisual.flame => const [Color(0xFFFF8A65), Color(0xFFBF360C)],
      AngryWordsGunVisual.bow => const [Color(0xFF8D6E63), Color(0xFF3E2723)],
      AngryWordsGunVisual.laser => const [Color(0xFFEF5350), Color(0xFFB71C1C)],
      AngryWordsGunVisual.plasma => const [
        Color(0xFF455A64),
        Color(0xFF1A237E),
      ],
      AngryWordsGunVisual.rocket => const [
        Color(0xFF795548),
        Color(0xFF3E2723),
      ],
      AngryWordsGunVisual.minigun => const [
        Color(0xFF78909C),
        Color(0xFF212121),
      ],
      AngryWordsGunVisual.tank => const [Color(0xFF558B2F), Color(0xFF33691E)],
      AngryWordsGunVisual.artillery => const [
        Color(0xFF6D4C41),
        Color(0xFF212121),
      ],
    };
    bodyColors = switch (gun) {
      AngryWordsGunKind.tripleBurstSmg => const [
        Color(0xFF546E7A),
        Color(0xFF0D47A1),
      ],
      AngryWordsGunKind.ak47 => const [Color(0xFF8D6E63), Color(0xFF3E2723)],
      AngryWordsGunKind.burstRifle => const [
        Color(0xFF607D8B),
        Color(0xFF1B5E20),
      ],
      AngryWordsGunKind.battleRifle => const [
        Color(0xFF546E7A),
        Color(0xFF212121),
      ],
      AngryWordsGunKind.quadBarrel => const [
        Color(0xFF6D4C41),
        Color(0xFF212121),
      ],
      AngryWordsGunKind.lmg => const [Color(0xFF78909C), Color(0xFF263238)],
      AngryWordsGunKind.heavySmg => const [
        Color(0xFF546E7A),
        Color(0xFF212121),
      ],
      AngryWordsGunKind.icePistol => const [
        Color(0xFF81D4FA),
        Color(0xFF01579B),
      ],
      AngryWordsGunKind.freezeRay => const [
        Color(0xFFB3E5FC),
        Color(0xFF0277BD),
      ],
      AngryWordsGunKind.flamethrower => const [
        Color(0xFFFF8A65),
        Color(0xFFBF360C),
      ],
      AngryWordsGunKind.inferno => const [Color(0xFFFF7043), Color(0xFFB71C1C)],
      AngryWordsGunKind.crossbow => const [
        Color(0xFF8D6E63),
        Color(0xFF3E2723),
      ],
      AngryWordsGunKind.repeatingCrossbow => const [
        Color(0xFFA1887F),
        Color(0xFF4E342E),
      ],
      AngryWordsGunKind.huntingRifle => const [
        Color(0xFF795548),
        Color(0xFF37474F),
      ],
      AngryWordsGunKind.sniper => const [Color(0xFF455A64), Color(0xFF102027)],
      AngryWordsGunKind.antiMateriel => const [
        Color(0xFF546E7A),
        Color(0xFF212121),
      ],
      AngryWordsGunKind.gauss => const [Color(0xFF80CBC4), Color(0xFF004D40)],
      AngryWordsGunKind.laserPointer => const [
        Color(0xFFFF8A80),
        Color(0xFFC62828),
      ],
      AngryWordsGunKind.pulseLaser => const [
        Color(0xFFFF5252),
        Color(0xFFB71C1C),
      ],
      AngryWordsGunKind.beamLaser => const [
        Color(0xFFFF1744),
        Color(0xFF880E4F),
      ],
      AngryWordsGunKind.plasmaPistol => const [
        Color(0xFFCE93D8),
        Color(0xFF4A148C),
      ],
      AngryWordsGunKind.plasmaRifle => const [
        Color(0xFFBA68C8),
        Color(0xFF311B92),
      ],
      AngryWordsGunKind.plasmaCannon => const [
        Color(0xFFE040FB),
        Color(0xFF1A237E),
      ],
      AngryWordsGunKind.railgun => const [Color(0xFF90A4AE), Color(0xFF0D47A1)],
      AngryWordsGunKind.coilgun => const [Color(0xFF4DD0E1), Color(0xFF006064)],
      AngryWordsGunKind.grenadeLauncher => const [
        Color(0xFFA1887F),
        Color(0xFF5D4037),
      ],
      AngryWordsGunKind.rpg => const [Color(0xFF558B2F), Color(0xFF1B5E20)],
      AngryWordsGunKind.homingRocket => const [
        Color(0xFF455A64),
        Color(0xFF006064),
      ],
      AngryWordsGunKind.minigun => const [Color(0xFF90A4AE), Color(0xFF37474F)],
      AngryWordsGunKind.gatling => const [Color(0xFF546E7A), Color(0xFF102027)],
      AngryWordsGunKind.laserTank => const [
        Color(0xFF7CB342),
        Color(0xFFB71C1C),
      ],
      AngryWordsGunKind.tankCannon => const [
        Color(0xFF8BC34A),
        Color(0xFF33691E),
      ],
      AngryWordsGunKind.twinTank => const [
        Color(0xFF9CCC65),
        Color(0xFF1B5E20),
      ],
      AngryWordsGunKind.siege => const [Color(0xFF8D6E63), Color(0xFF3E2723)],
      AngryWordsGunKind.doomsdayMg => const [
        Color(0xFF546E7A),
        Color(0xFF212121),
      ],
      _ => bodyColors,
    };
    final barrelColors = switch (visual) {
      AngryWordsGunVisual.tinyPistol ||
      AngryWordsGunVisual.pistol ||
      AngryWordsGunVisual.dual => const [
        Color(0xFFBCAAA4),
        Color(0xFF6D4C41),
        Color(0xFF3E2723),
      ],
      AngryWordsGunVisual.revolver => const [
        Color(0xFFD7CCC8),
        Color(0xFF795548),
        Color(0xFF3E2723),
      ],
      AngryWordsGunVisual.smg || AngryWordsGunVisual.minigun => const [
        Color(0xFFB0BEC5),
        Color(0xFF455A64),
        Color(0xFF212121),
      ],
      AngryWordsGunVisual.shotgun || AngryWordsGunVisual.bow => const [
        Color(0xFFBCAAA4),
        Color(0xFF6D4C41),
        Color(0xFF212121),
      ],
      AngryWordsGunVisual.rifle || AngryWordsGunVisual.sniper => const [
        Color(0xFFCFD8DC),
        Color(0xFF546E7A),
        Color(0xFF263238),
      ],
      AngryWordsGunVisual.ice => const [
        Color(0xFFE1F5FE),
        Color(0xFF4FC3F7),
        Color(0xFF01579B),
      ],
      AngryWordsGunVisual.flame => const [
        Color(0xFFFFCC80),
        Color(0xFFFF6D00),
        Color(0xFFBF360C),
      ],
      AngryWordsGunVisual.laser => const [
        Color(0xFFFFCDD2),
        Color(0xFFEF5350),
        Color(0xFFB71C1C),
      ],
      AngryWordsGunVisual.plasma => const [
        Color(0xFF90A4AE),
        Color(0xFF37474F),
        Color(0xFF102027),
      ],
      AngryWordsGunVisual.rocket || AngryWordsGunVisual.artillery => const [
        Color(0xFFFFCC80),
        Color(0xFF8D6E63),
        Color(0xFF3E2723),
      ],
      AngryWordsGunVisual.tank => const [
        Color(0xFFAED581),
        Color(0xFF558B2F),
        Color(0xFF33691E),
      ],
    };
    final trim = Color.lerp(
      switch (gun) {
        AngryWordsGunKind.doomsdayMg => const Color(0xFFFF3D00),
        _ => switch (visual) {
          AngryWordsGunVisual.ice => const Color(0xFF81D4FA),
          AngryWordsGunVisual.flame => const Color(0xFFFF6E40),
          AngryWordsGunVisual.laser => const Color(0xFFFF5252),
          AngryWordsGunVisual.plasma => const Color(0xFF80D8FF),
          AngryWordsGunVisual.rocket ||
          AngryWordsGunVisual.artillery => const Color(0xFFFFAB40),
          AngryWordsGunVisual.tank => const Color(0xFFCDDC39),
          _ => const Color(0xFFFFB74D),
        },
      },
      stageAccent,
      0.55,
    )!;
    final coreColors = gun == AngryWordsGunKind.doomsdayMg
        ? const [Color(0xFFFF8A65), Color(0xFFBF360C)]
        : switch (visual) {
            AngryWordsGunVisual.ice => const [
              Color(0xFFE1F5FE),
              Color(0xFF0288D1),
            ],
            AngryWordsGunVisual.flame => const [
              Color(0xFFFFF59D),
              Color(0xFFDD2C00),
            ],
            AngryWordsGunVisual.laser => const [
              Color(0xFFFF8A80),
              Color(0xFFD50000),
            ],
            AngryWordsGunVisual.plasma => const [
              Color(0xFF80D8FF),
              Color(0xFFD500F9),
            ],
            AngryWordsGunVisual.rocket || AngryWordsGunVisual.artillery =>
              const [Color(0xFFFFE082), Color(0xFFE65100)],
            _ => const [Color(0xFFFFCC80), Color(0xFFFF6F00)],
          };
    var barrelLen = switch (visual) {
      AngryWordsGunVisual.tinyPistol => 38.0,
      AngryWordsGunVisual.pistol || AngryWordsGunVisual.dual => 46.0,
      AngryWordsGunVisual.revolver => 50.0,
      AngryWordsGunVisual.smg => 54.0,
      AngryWordsGunVisual.shotgun => 58.0,
      AngryWordsGunVisual.rifle => 66.0,
      AngryWordsGunVisual.sniper => 78.0,
      AngryWordsGunVisual.ice => 56.0,
      AngryWordsGunVisual.flame => 50.0,
      AngryWordsGunVisual.bow => 52.0,
      AngryWordsGunVisual.laser => 70.0,
      AngryWordsGunVisual.plasma => 62.0,
      AngryWordsGunVisual.rocket => 60.0,
      AngryWordsGunVisual.minigun => 64.0,
      AngryWordsGunVisual.tank => 72.0,
      AngryWordsGunVisual.artillery => 80.0,
    };
    var barrelH = switch (visual) {
      AngryWordsGunVisual.tinyPistol => 16.0,
      AngryWordsGunVisual.laser => 14.0,
      AngryWordsGunVisual.sniper => 16.0,
      AngryWordsGunVisual.smg => 18.0,
      AngryWordsGunVisual.shotgun || AngryWordsGunVisual.flame => 24.0,
      AngryWordsGunVisual.minigun || AngryWordsGunVisual.tank => 26.0,
      AngryWordsGunVisual.artillery || AngryWordsGunVisual.rocket => 28.0,
      _ => 20.0,
    };
    final silhouette = switch (gun) {
      AngryWordsGunKind.tripleBurstSmg => (56.0, 17.0),
      AngryWordsGunKind.compactShotgun => (48.0, 26.0),
      AngryWordsGunKind.pumpShotgun => (64.0, 24.0),
      AngryWordsGunKind.autoShotgun => (56.0, 25.0),
      AngryWordsGunKind.quadBarrel => (52.0, 28.0),
      AngryWordsGunKind.carbine => (58.0, 18.0),
      AngryWordsGunKind.assault => (64.0, 19.0),
      AngryWordsGunKind.ak47 => (62.0, 20.0),
      AngryWordsGunKind.battleRifle => (72.0, 20.0),
      AngryWordsGunKind.burstRifle => (66.0, 18.0),
      AngryWordsGunKind.lmg => (74.0, 20.0),
      AngryWordsGunKind.heavySmg => (54.0, 22.0),
      AngryWordsGunKind.icePistol => (46.0, 16.0),
      AngryWordsGunKind.freezeRay => (68.0, 15.0),
      AngryWordsGunKind.flamethrower => (46.0, 26.0),
      AngryWordsGunKind.inferno => (50.0, 28.0),
      AngryWordsGunKind.crossbow => (50.0, 18.0),
      AngryWordsGunKind.repeatingCrossbow => (48.0, 17.0),
      AngryWordsGunKind.huntingRifle => (72.0, 17.0),
      AngryWordsGunKind.sniper => (84.0, 15.0),
      AngryWordsGunKind.antiMateriel => (92.0, 16.0),
      AngryWordsGunKind.gauss => (70.0, 18.0),
      AngryWordsGunKind.laserPointer => (58.0, 11.0),
      AngryWordsGunKind.pulseLaser => (66.0, 13.0),
      AngryWordsGunKind.beamLaser => (78.0, 12.0),
      AngryWordsGunKind.plasmaPistol => (48.0, 20.0),
      AngryWordsGunKind.plasmaRifle => (64.0, 20.0),
      AngryWordsGunKind.plasmaCannon => (58.0, 26.0),
      AngryWordsGunKind.railgun => (96.0, 14.0),
      AngryWordsGunKind.coilgun => (56.0, 19.0),
      AngryWordsGunKind.grenadeLauncher => (48.0, 28.0),
      AngryWordsGunKind.rpg => (78.0, 22.0),
      AngryWordsGunKind.homingRocket => (72.0, 20.0),
      AngryWordsGunKind.minigun => (60.0, 22.0),
      AngryWordsGunKind.gatling => (74.0, 30.0),
      AngryWordsGunKind.laserTank => (80.0, 12.0),
      AngryWordsGunKind.tankCannon => (72.0, 28.0),
      AngryWordsGunKind.twinTank => (68.0, 22.0),
      AngryWordsGunKind.siege => (78.0, 22.0),
      AngryWordsGunKind.doomsdayMg => (94.0, 36.0),
      _ => null,
    };
    if (silhouette != null) {
      barrelLen = silhouette.$1;
      barrelH = silhouette.$2;
    }

    var baseW = switch (visual) {
      AngryWordsGunVisual.tinyPistol ||
      AngryWordsGunVisual.pistol ||
      AngryWordsGunVisual.revolver => 42.0,
      AngryWordsGunVisual.tank || AngryWordsGunVisual.artillery => 64.0,
      AngryWordsGunVisual.minigun => 58.0,
      _ => 52.0,
    };
    baseW = switch (gun) {
      AngryWordsGunKind.grenadeLauncher => 50.0,
      AngryWordsGunKind.rpg => 56.0,
      AngryWordsGunKind.homingRocket => 54.0,
      AngryWordsGunKind.minigun => 56.0,
      AngryWordsGunKind.gatling => 66.0,
      AngryWordsGunKind.laserTank => 60.0,
      AngryWordsGunKind.tankCannon => 68.0,
      AngryWordsGunKind.twinTank => 72.0,
      AngryWordsGunKind.siege => 64.0,
      AngryWordsGunKind.doomsdayMg => 86.0,
      _ => baseW,
    };
    final base = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(m.dx, m.dy + 16),
        width: baseW,
        height: gun == AngryWordsGunKind.doomsdayMg
            ? 34
            : visual == AngryWordsGunVisual.tank ||
                  visual == AngryWordsGunVisual.artillery
            ? 30
            : 26,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      base.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      base,
      Paint()
        ..shader = LinearGradient(
          colors: bodyColors,
        ).createShader(base.outerRect),
    );

    canvas.save();
    canvas.translate(m.dx, m.dy);
    canvas.rotate(angle);
    canvas.translate(-kick, 0);

    final pellets = world.loadout.pelletCount.clamp(1, 8);
    final hybridTank = gun == AngryWordsGunKind.tankCannon && pellets >= 2;
    final energyMulti =
        pellets >= 2 &&
        (visual == AngryWordsGunVisual.plasma ||
            gun == AngryWordsGunKind.railgun ||
            gun == AngryWordsGunKind.coilgun ||
            gun == AngryWordsGunKind.plasmaPistol ||
            gun == AngryWordsGunKind.plasmaRifle ||
            gun == AngryWordsGunKind.plasmaCannon);
    if (visual == AngryWordsGunVisual.dual ||
        gun == AngryWordsGunKind.twinTank ||
        gun == AngryWordsGunKind.siege ||
        hybridTank ||
        energyMulti) {
      final multi = gun == AngryWordsGunKind.siege || pellets >= 3;
      final tubeH = multi
          ? 9.0
          : hybridTank
          ? 13.0
          : gun == AngryWordsGunKind.twinTank
          ? 12.0
          : energyMulti
          ? 11.0
          : 14.0;
      final gap = multi
          ? 11.0
          : hybridTank
          ? 13.0
          : gun == AngryWordsGunKind.twinTank
          ? 12.0
          : energyMulti
          ? 9.0
          : 8.0;
      final yOffs = multi ? const [-11.0, 0.0, 11.0] : [-gap, gap];
      for (var bi = 0; bi < yOffs.length; bi++) {
        final yOff = yOffs[bi];
        final isLaserTube = hybridTank && bi == 0;
        final tubeColors = gun == AngryWordsGunKind.siege
            ? const [Color(0xFFFFCC80), Color(0xFF8D6E63), Color(0xFF3E2723)]
            : isLaserTube
            ? const [Color(0xFFFF8A80), Color(0xFFD50000)]
            : barrelColors;
        final barrel = RRect.fromRectAndRadius(
          Rect.fromLTWH(-6, yOff - tubeH / 2, barrelLen * 0.92, tubeH),
          const Radius.circular(5),
        );
        canvas.drawRRect(
          barrel,
          Paint()
            ..shader = LinearGradient(
              colors: tubeColors,
            ).createShader(barrel.outerRect),
        );
        canvas.drawRRect(
          barrel,
          Paint()
            ..color = (isLaserTube ? const Color(0xFFFF5252) : trim).withValues(
              alpha: 0.55,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
        if (isLaserTube) {
          canvas.drawCircle(
            Offset(barrelLen * 0.88, yOff),
            3.8,
            Paint()..color = const Color(0xFFFF1744),
          );
          canvas.drawCircle(
            Offset(barrelLen * 0.88, yOff),
            1.8,
            Paint()..color = const Color(0xFFFFEBEE),
          );
        }
      }
    } else {
      final barrel = RRect.fromRectAndRadius(
        Rect.fromLTWH(-8, -barrelH / 2, barrelLen, barrelH),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        barrel,
        Paint()
          ..shader = LinearGradient(
            colors: barrelColors,
          ).createShader(barrel.outerRect),
      );
      canvas.drawRRect(
        barrel,
        Paint()
          ..color = trim.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    if (gun != AngryWordsGunKind.doomsdayMg &&
        (visual == AngryWordsGunVisual.smg ||
            visual == AngryWordsGunVisual.minigun ||
            gun == AngryWordsGunKind.tripleBurstSmg ||
            gun == AngryWordsGunKind.heavySmg ||
            gun == AngryWordsGunKind.lmg)) {
      final magW = gun == AngryWordsGunKind.lmg
          ? 16.0
          : gun == AngryWordsGunKind.heavySmg
          ? 15.0
          : gun == AngryWordsGunKind.tripleBurstSmg
          ? 14.0
          : 12.0;
      final magH = gun == AngryWordsGunKind.lmg
          ? 20.0
          : gun == AngryWordsGunKind.heavySmg
          ? 18.0
          : gun == AngryWordsGunKind.tripleBurstSmg
          ? 16.0
          : 14.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(6, 6, magW, magH),
          const Radius.circular(3),
        ),
        Paint()
          ..color = gun == AngryWordsGunKind.tripleBurstSmg
              ? const Color(0xFF1565C0)
              : gun == AngryWordsGunKind.heavySmg
              ? const Color(0xFF263238)
              : const Color(0xFF37474F),
      );
      if (gun == AngryWordsGunKind.lmg) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barrelLen * 0.45, barrelH / 2 + 1, 18, 5),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF455A64),
        );
      }
    }
    if (visual == AngryWordsGunVisual.revolver ||
        gun == AngryWordsGunKind.magnum) {
      canvas.drawCircle(
        Offset(gun == AngryWordsGunKind.magnum ? 12 : 10, 10),
        gun == AngryWordsGunKind.magnum ? 9.0 : 7.0,
        Paint()..color = const Color(0xFF5D4037),
      );
    }
    if (gun != AngryWordsGunKind.lmg &&
        (visual == AngryWordsGunVisual.rifle ||
            visual == AngryWordsGunVisual.sniper ||
            gun == AngryWordsGunKind.assault ||
            gun == AngryWordsGunKind.burstRifle ||
            gun == AngryWordsGunKind.battleRifle ||
            gun == AngryWordsGunKind.huntingRifle)) {
      final scopeW = switch (gun) {
        AngryWordsGunKind.antiMateriel => 30.0,
        AngryWordsGunKind.railgun => 22.0,
        AngryWordsGunKind.sniper => 26.0,
        AngryWordsGunKind.huntingRifle => 20.0,
        _ => 18.0,
      };
      final scopeH = gun == AngryWordsGunKind.antiMateriel
          ? 10.0
          : gun == AngryWordsGunKind.sniper || gun == AngryWordsGunKind.railgun
          ? 9.0
          : 7.0;
      final scopeX =
          barrelLen *
          (gun == AngryWordsGunKind.antiMateriel ||
                  gun == AngryWordsGunKind.railgun ||
                  gun == AngryWordsGunKind.sniper
              ? 0.34
              : 0.28);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(scopeX, -barrelH / 2 - scopeH, scopeW, scopeH),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF263238),
      );
      if (gun == AngryWordsGunKind.sniper ||
          gun == AngryWordsGunKind.antiMateriel) {
        canvas.drawCircle(
          Offset(scopeX + scopeW * 0.55, -barrelH / 2 - scopeH * 0.45),
          gun == AngryWordsGunKind.antiMateriel ? 4.0 : 3.2,
          Paint()..color = const Color(0xFF90A4AE),
        );
      }
    }
    if (gun == AngryWordsGunKind.gauss) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(12, -barrelH / 2 - 4, barrelLen * 0.55, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF64FFDA).withValues(alpha: 0.75),
      );
    }
    if (visual == AngryWordsGunVisual.laser) {
      canvas.drawCircle(
        Offset(barrelLen - 5, 0),
        gun == AngryWordsGunKind.beamLaser
            ? 5.5
            : gun == AngryWordsGunKind.pulseLaser
            ? 4.5
            : 3.5,
        Paint()
          ..color = gun == AngryWordsGunKind.beamLaser
              ? const Color(0xFFFF5252)
              : const Color(0xFFFF8A80),
      );
    }
    if (visual == AngryWordsGunVisual.plasma) {
      canvas.drawCircle(
        Offset(barrelLen * 0.45, 0),
        gun == AngryWordsGunKind.plasmaCannon
            ? 9.0
            : gun == AngryWordsGunKind.plasmaRifle
            ? 6.5
            : 5.5,
        Paint()
          ..color = const Color(0xFFE040FB).withValues(
            alpha: gun == AngryWordsGunKind.plasmaCannon ? 0.7 : 0.55,
          ),
      );
    }
    if (gun == AngryWordsGunKind.railgun) {
      canvas.drawLine(
        Offset(8, -barrelH / 2 - 2),
        Offset(barrelLen - 8, -barrelH / 2 - 2),
        Paint()
          ..color = const Color(0xFF40C4FF)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(8, barrelH / 2 + 2),
        Offset(barrelLen - 8, barrelH / 2 + 2),
        Paint()
          ..color = const Color(0xFF40C4FF)
          ..strokeWidth = 2,
      );
    }
    if (gun == AngryWordsGunKind.coilgun) {
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(14.0 + i * 10, 0),
          5.5,
          Paint()
            ..color = const Color(0xFF18FFFF).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    if (gun == AngryWordsGunKind.icePistol) {
      canvas.drawCircle(
        Offset(barrelLen - 10, 0),
        5.5,
        Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.85),
      );
    }
    if (gun == AngryWordsGunKind.freezeRay) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, -3, barrelLen * 0.7, 6),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFE1F5FE).withValues(alpha: 0.75),
      );
    }
    if (gun == AngryWordsGunKind.inferno) {
      for (final yOff in [-7.0, 7.0]) {
        canvas.drawCircle(
          Offset(barrelLen - 5, yOff),
          4.5,
          Paint()..color = const Color(0xFFFF6E40),
        );
      }
    }
    if (gun == AngryWordsGunKind.ak47) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, 8, 22, 10),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF5D4037),
      );
    }
    if (visual == AngryWordsGunVisual.shotgun) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            gun == AngryWordsGunKind.compactShotgun
                ? barrelLen - 14
                : barrelLen - 20,
            -barrelH / 2 - 2,
            gun == AngryWordsGunKind.compactShotgun ? 12 : 16,
            barrelH + 4,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF4E342E).withValues(alpha: 0.7),
      );
      if (gun == AngryWordsGunKind.pumpShotgun) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barrelLen * 0.35, -barrelH / 2 - 5, 16, 6),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF3E2723),
        );
      }
      if (gun == AngryWordsGunKind.autoShotgun) {
        canvas.drawCircle(
          Offset(barrelLen * 0.4, barrelH / 2 + 6),
          7,
          Paint()..color = const Color(0xFF37474F),
        );
      }
    }
    if (visual == AngryWordsGunVisual.bow) {
      final bowH = gun == AngryWordsGunKind.repeatingCrossbow ? 28.0 : 36.0;
      final bowW = gun == AngryWordsGunKind.repeatingCrossbow ? 24.0 : 30.0;
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(8, 0), width: bowW, height: bowH),
        -1.2,
        2.4,
        false,
        Paint()
          ..color = gun == AngryWordsGunKind.repeatingCrossbow
              ? const Color(0xFF6D4C41)
              : const Color(0xFF5D4037)
          ..style = PaintingStyle.stroke
          ..strokeWidth = gun == AngryWordsGunKind.repeatingCrossbow
              ? 2.4
              : 3.2,
      );
      if (gun == AngryWordsGunKind.repeatingCrossbow) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 7, 12, 12),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF37474F),
        );
      }
    }
    if (gun == AngryWordsGunKind.grenadeLauncher) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barrelLen - 16, -barrelH / 2 - 3, 14, barrelH + 6),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFFFF8F00).withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        Offset(barrelLen - 6, 0),
        9,
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawCircle(
        Offset(18, barrelH / 2 + 4),
        6,
        Paint()..color = const Color(0xFFFF6F00),
      );
    }
    if (gun == AngryWordsGunKind.rpg) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-10, -barrelH / 2 - 6, 18, barrelH + 12),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF33691E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barrelLen - 22, -8, 20, 16),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFFF3D00),
      );
      canvas.drawCircle(
        Offset(barrelLen - 4, 0),
        5,
        Paint()..color = const Color(0xFFFFAB40),
      );
    }
    if (gun == AngryWordsGunKind.homingRocket) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, -barrelH / 2 - 5, barrelLen * 0.45, 4),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF26C6DA),
      );
      canvas.drawCircle(
        Offset(barrelLen - 6, -barrelH / 2 - 6),
        3.2,
        Paint()..color = const Color(0xFF18FFFF),
      );
      final eyePulse = 0.55 + 0.45 * math.sin(world.simTime * 6);
      canvas.drawCircle(
        Offset(barrelLen - 7, 0),
        6.5,
        Paint()..color = const Color(0xFF80DEEA).withValues(alpha: eyePulse),
      );
      canvas.drawCircle(
        Offset(barrelLen - 7, 0),
        2.8,
        Paint()..color = const Color(0xFFE040FB),
      );
    }
    if (gun == AngryWordsGunKind.siege) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, 7, 38, 12),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF4E342E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barrelLen * 0.28, -18, 16, 36),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFF8A65).withValues(alpha: 0.45),
      );
      for (final y in const [-11.0, 0.0, 11.0]) {
        canvas.drawCircle(
          Offset(barrelLen * 0.55, y),
          2.2,
          Paint()..color = const Color(0xFFFFD54F),
        );
      }
    }
    if (gun == AngryWordsGunKind.doomsdayMg) {
      final heat = world.muzzleFlash;
      final pulse = 0.55 + 0.45 * math.sin(world.simTime * 7);
      final beltSway = math.sin(world.simTime * 11 + heat) * 2.2;
      // Cooling fins.
      for (var i = 0; i < 5; i++) {
        final x = 10.0 + i * 9.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, -barrelH / 2 - 5, 5, barrelH + 10),
            const Radius.circular(1),
          ),
          Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.85),
        );
      }
      // Hazard stripe.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barrelLen * 0.22, -barrelH / 2 - 1, 22, barrelH + 2),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFF9A825),
      );
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(barrelLen * 0.22 + i * 5.5, -barrelH / 2 - 1),
          Offset(barrelLen * 0.22 + i * 5.5 + 4, barrelH / 2 + 1),
          Paint()
            ..color = const Color(0xFF212121)
            ..strokeWidth = 2.2,
        );
      }
      // Apocalypse core pulse (red/orange, not purple).
      canvas.drawCircle(
        Offset(barrelLen * 0.18, 0),
        10,
        Paint()
          ..color = const Color(
            0xFFFF3D00,
          ).withValues(alpha: 0.28 + 0.35 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(barrelLen * 0.18, 0),
        5.5,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFBF360C),
            const Color(0xFFFFAB40),
            pulse,
          )!,
      );
      // Giant mag + hanging ammo belt.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 12, 28, 22),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF263238),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 15, 20, 8),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFF6D00).withValues(alpha: 0.55),
      );
      final belt = Path()
        ..moveTo(28, 22)
        ..quadraticBezierTo(40 + beltSway, 34, 48 + beltSway, 28)
        ..quadraticBezierTo(56 + beltSway, 22, 62 + beltSway, 30);
      canvas.drawPath(
        belt,
        Paint()
          ..color = const Color(0xFF5D4037)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
      for (var i = 0; i < 5; i++) {
        final t = i / 4;
        final bx = 30 + t * 30 + beltSway * t;
        final by = 24 + math.sin(t * math.pi + world.simTime * 3) * 6;
        canvas.drawCircle(
          Offset(bx, by),
          2.4,
          Paint()..color = const Color(0xFFFFB300),
        );
      }
      // 5-barrel spinning cylinder — largest in the game.
      final spin = world.simTime * (16 + heat * 10);
      const ringR = 10.0;
      const barrelN = 5;
      canvas.drawCircle(
        Offset(barrelLen - 10, 0),
        ringR + 4,
        Paint()
          ..color = const Color(0xFF102027)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.2,
      );
      for (var i = 0; i < barrelN; i++) {
        final a = spin + (i / barrelN) * math.pi * 2;
        final tipGlow = Color.lerp(
          const Color(0xFF78909C),
          const Color(0xFFFF6D00),
          heat.clamp(0.0, 1.0),
        )!;
        canvas.drawCircle(
          Offset(barrelLen - 10 + math.cos(a) * ringR, math.sin(a) * ringR),
          3.8,
          Paint()..color = tipGlow,
        );
        if (heat > 0.15) {
          canvas.drawCircle(
            Offset(barrelLen - 10 + math.cos(a) * ringR, math.sin(a) * ringR),
            1.7,
            Paint()..color = const Color(0xFFFFECB3).withValues(alpha: heat),
          );
        }
      }
      // Stock / rear grip.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-18, -8, 16, 16),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF3E2723),
      );
    }
    if (visual == AngryWordsGunVisual.tank ||
        gun == AngryWordsGunKind.laserTank) {
      final hullW = gun == AngryWordsGunKind.twinTank
          ? 46.0
          : gun == AngryWordsGunKind.laserTank
          ? 40.0
          : 38.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-hullW * 0.45, 8, hullW, 13),
          const Radius.circular(4),
        ),
        Paint()
          ..color = gun == AngryWordsGunKind.laserTank
              ? const Color(0xFF558B2F)
              : const Color(0xFF33691E),
      );
      for (final x in [-hullW * 0.28, 0.0, hullW * 0.28]) {
        canvas.drawCircle(
          Offset(x, 18),
          3.2,
          Paint()..color = const Color(0xFF212121),
        );
      }
      if (gun == AngryWordsGunKind.laserTank) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barrelLen * 0.2, -barrelH / 2 - 5, 14, 5),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFFF5252),
        );
        canvas.drawCircle(
          Offset(barrelLen - 3, 0),
          3.5,
          Paint()..color = const Color(0xFFFF1744),
        );
      }
      if (gun == AngryWordsGunKind.tankCannon) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barrelLen - 14, -barrelH / 2 - 2, 12, barrelH + 4),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF455A64),
        );
      }
    }
    if (gun == AngryWordsGunKind.minigun || gun == AngryWordsGunKind.gatling) {
      final heavy = gun == AngryWordsGunKind.gatling;
      final n = heavy ? 6 : 4;
      final spin = world.simTime * (heavy ? 14 : 18);
      final ringR = heavy ? 7.5 : 5.5;
      canvas.drawCircle(
        Offset(barrelLen - 8, 0),
        ringR + 2,
        Paint()
          ..color = const Color(0xFF263238)
          ..style = PaintingStyle.stroke
          ..strokeWidth = heavy ? 3.2 : 2.2,
      );
      for (var i = 0; i < n; i++) {
        final a = spin + (i / n) * math.pi * 2;
        canvas.drawCircle(
          Offset(barrelLen - 8 + math.cos(a) * ringR, math.sin(a) * ringR),
          heavy ? 3.0 : 2.2,
          Paint()..color = const Color(0xFF90A4AE),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, heavy ? 10 : 8, heavy ? 20 : 14, heavy ? 16 : 12),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF37474F),
      );
    }

    final coreW = barrelLen * 0.42;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, -5, coreW, 10),
        const Radius.circular(4),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: coreColors,
        ).createShader(Rect.fromLTWH(8, -5, coreW, 10)),
    );
    final tipR = switch (gun) {
      AngryWordsGunKind.grenadeLauncher => 10.5,
      AngryWordsGunKind.rpg => 8.0,
      AngryWordsGunKind.homingRocket => 7.0,
      AngryWordsGunKind.laserTank => 3.5,
      AngryWordsGunKind.tankCannon => 11.0,
      AngryWordsGunKind.siege => 5.5,
      AngryWordsGunKind.doomsdayMg => 8.5,
      AngryWordsGunKind.minigun => 5.0,
      AngryWordsGunKind.gatling => 6.5,
      _ => switch (visual) {
        AngryWordsGunVisual.plasma => 7.2,
        AngryWordsGunVisual.flame => 8.0,
        AngryWordsGunVisual.laser => 4.5,
        AngryWordsGunVisual.shotgun => 7.5,
        AngryWordsGunVisual.rocket || AngryWordsGunVisual.artillery => 9.0,
        AngryWordsGunVisual.tank => 8.5,
        AngryWordsGunVisual.tinyPistol => 4.5,
        _ => 6.0,
      },
    };
    if (gun == AngryWordsGunKind.quadBarrel) {
      for (final o in const [
        Offset(-5, -5),
        Offset(5, -5),
        Offset(-5, 5),
        Offset(5, 5),
      ]) {
        canvas.drawCircle(
          Offset(barrelLen - 4, 0) + o,
          4.2,
          Paint()..color = trim,
        );
      }
    } else if (gun == AngryWordsGunKind.twinTank) {
      for (final yOff in const [-12.0, 12.0]) {
        canvas.drawCircle(
          Offset(barrelLen - 4, yOff),
          7.2,
          Paint()..color = const Color(0xFFFF8F00),
        );
      }
    } else if (gun == AngryWordsGunKind.siege) {
      for (final yOff in const [-11.0, 0.0, 11.0]) {
        canvas.drawCircle(
          Offset(barrelLen - 3, yOff),
          tipR,
          Paint()..color = const Color(0xFFFF8A65),
        );
        canvas.drawCircle(
          Offset(barrelLen - 3, yOff),
          tipR * 0.45,
          Paint()..color = Colors.white.withValues(alpha: 0.75),
        );
      }
    } else if (gun == AngryWordsGunKind.doomsdayMg) {
      final heat = world.muzzleFlash.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(barrelLen - 4, 0),
        tipR,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF455A64),
            const Color(0xFFFF6D00),
            0.35 + heat * 0.65,
          )!,
      );
      canvas.drawCircle(
        Offset(barrelLen - 4, 0),
        tipR * 0.4,
        Paint()
          ..color = const Color(
            0xFFFFECB3,
          ).withValues(alpha: 0.55 + heat * 0.4),
      );
    } else if (gun != AngryWordsGunKind.inferno &&
        gun != AngryWordsGunKind.homingRocket) {
      canvas.drawCircle(Offset(barrelLen - 6, 0), tipR, Paint()..color = trim);
    }
    if (gun == AngryWordsGunKind.tripleBurstSmg ||
        gun == AngryWordsGunKind.burstRifle) {
      final y = -barrelH / 2 - 3;
      final x0 = barrelLen * 0.48;
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(x0 + i * 6.5, y),
          2.6,
          Paint()
            ..color = gun == AngryWordsGunKind.burstRifle
                ? const Color(0xFF69F0AE)
                : const Color(0xFFFFD54F),
        );
      }
    }
    canvas.restore();
  }

  void _paintSlingshot(Canvas canvas) {
    final m = world.muzzle;
    final pull = world.pullPoint;
    var angle = -math.pi / 2;
    if (pull != null) {
      final delta = m - pull;
      if (delta.distance > 1) {
        angle = math.atan2(delta.dy, delta.dx);
      }
    }

    final base = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(m.dx, m.dy + 18), width: 64, height: 28),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      base.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      base,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
        ).createShader(base.outerRect),
    );

    canvas.save();
    canvas.translate(m.dx, m.dy);
    canvas.rotate(angle);
    final barrel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-10, -14, 54, 28),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      barrel,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFCC80), Color(0xFFFF7043), Color(0xFFE64A19)],
        ).createShader(barrel.outerRect),
    );
    canvas.drawRRect(
      barrel,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();

    if (world.aiming && pull != null) {
      final power = world.powerNorm;
      final bandColor = Color.lerp(
        const Color(0xFF546E7A),
        Color.lerp(const Color(0xFFFF8A65), const Color(0xFFFF1744), power)!,
        0.25 + power * 0.75,
      )!;
      final left = Offset(m.dx - 22, m.dy + 4);
      final right = Offset(m.dx + 22, m.dy + 4);
      final band = Paint()
        ..color = bandColor.withValues(alpha: 0.88)
        ..strokeWidth = 2.6 + power * 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(left, pull, band);
      canvas.drawLine(right, pull, band);
      // Stretch sparks along bands when charging hard.
      if (power > 0.45) {
        final sparkN = 2 + (power * 4).round();
        for (var i = 1; i <= sparkN; i++) {
          final t = i / (sparkN + 1);
          final onLeft = Offset.lerp(left, pull, t)!;
          final onRight = Offset.lerp(right, pull, t)!;
          final spark = Paint()
            ..color = bandColor.withValues(alpha: 0.35 + power * 0.35)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            onLeft,
            onLeft + Offset(0, -3 - power * 4),
            spark,
          );
          canvas.drawLine(
            onRight,
            onRight + Offset(0, -3 - power * 4),
            spark,
          );
        }
      }
      final tipR = AngryWordsPhysicsWorld.ballRadius * (1.0 + power * 0.28);
      canvas.drawCircle(
        pull,
        tipR + 4 + power * 6,
        Paint()
          ..color = bandColor.withValues(alpha: 0.12 + power * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        pull,
        3.2,
        Paint()..color = const Color(0xFF263238).withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        pull,
        tipR,
        Paint()
          ..shader = ui.Gradient.radial(
            pull + const Offset(-3, -3),
            tipR,
            [
              const Color(0xFFFFF8E1),
              Color.lerp(const Color(0xFFFF7043), const Color(0xFFFF1744), power)!,
              Color.lerp(const Color(0xFFD84315), const Color(0xFFB71C1C), power)!,
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
      canvas.drawCircle(
        pull,
        tipR,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    } else if (!world.inFlight) {
      canvas.drawCircle(
        m,
        AngryWordsPhysicsWorld.ballRadius,
        Paint()
          ..shader = ui.Gradient.radial(
            m + const Offset(-3, -3),
            AngryWordsPhysicsWorld.ballRadius,
            const [Color(0xFFFFF8E1), Color(0xFFFF7043), Color(0xFFD84315)],
            const [0.0, 0.55, 1.0],
          ),
      );
    }
  }

  void _paintTrail(Canvas canvas) {
    for (var i = 0; i < trail.length; i++) {
      final t = (i + 1) / (trail.length + 1);
      canvas.drawCircle(
        trail[i],
        AngryWordsPhysicsWorld.ballRadius * (0.3 + t * 0.4),
        Paint()..color = const Color(0xFFFFAB91).withValues(alpha: 0.28 * t),
      );
    }
  }

  void _paintBall(Canvas canvas) {
    if (world.aiming) return;
    final c = world.ball;
    canvas.drawCircle(
      c + const Offset(1.5, 2),
      AngryWordsPhysicsWorld.ballRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      c,
      AngryWordsPhysicsWorld.ballRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          c + const Offset(-3, -3),
          AngryWordsPhysicsWorld.ballRadius,
          const [Color(0xFFFFF8E1), Color(0xFFFF7043), Color(0xFFD84315)],
          const [0.0, 0.55, 1.0],
        ),
    );
  }

  void _paintSpark(Canvas canvas, Offset at, double life) {
    final paint = Paint()
      ..color = const Color(0xFFFFECB3).withValues(alpha: life)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi * 2 / 8;
      final len = 8 + (1 - life) * 14;
      canvas.drawLine(
        at,
        Offset(at.dx + math.cos(a) * len, at.dy + math.sin(a) * len),
        paint,
      );
    }
    canvas.drawCircle(
      at,
      10 * life,
      Paint()
        ..color = const Color(0xFFFF7043).withValues(alpha: 0.35 * life)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _paintCombo(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'Combo x$combo',
        style: TextStyle(
          color: const Color(0xFFFF6F00).withValues(alpha: 0.95),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Color(0x66FFECB3), blurRadius: 10)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, 12));
  }

  void _paintPerfectBurst(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: '✓',
        style: TextStyle(
          color: const Color(0xFF00C853).withValues(alpha: successFlash),
          fontSize: 46 + (1 - successFlash) * 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width / 2 - tp.width / 2, size.height * 0.36 - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant AngryWordsBoardPainter oldDelegate) => true;
}
