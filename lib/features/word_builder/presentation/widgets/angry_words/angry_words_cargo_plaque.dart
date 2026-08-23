import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../data/prop_archetypes/wb_prop_archetype.dart';

/// Flat readable backing behind cargo letters on busy / narrow silhouettes.
abstract final class AngryWordsCargoPlaque {
  /// Gear, tubes, cans, statues, bottles — letter sits on a flat chip.
  static bool needsPlaque(WbArchetypeSpec? spec) {
    if (spec == null) return false;
    if (!spec.holdsCargoWell) return true;
    if (spec.aspectRatio < 0.75) return true;
    return switch (spec.id) {
      WbPropArchetype.metalGear ||
      WbPropArchetype.neonTube ||
      WbPropArchetype.batteryCell ||
      WbPropArchetype.sprayCan ||
      WbPropArchetype.sodaCan ||
      WbPropArchetype.tinCan ||
      WbPropArchetype.oilDrum ||
      WbPropArchetype.glassBottle ||
      WbPropArchetype.stoneStatue ||
      WbPropArchetype.neonOrb =>
        true,
      _ => false,
    };
  }

  /// Soft tint wash + optional flat plaque + pulse ring (cargo ≠ filler).
  static void paintBacking({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color cargoTint,
    required double pulse,
    required bool usePlaque,
  }) {
    // Soft wash — always present so cargo pops from filler skins.
    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()..color = cargoTint.withValues(alpha: usePlaque ? 0.18 : 0.28),
    );

    if (usePlaque) {
      final w = radius * 1.15;
      final h = radius * 0.95;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: h),
        Radius.circular(radius * 0.22),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            center + Offset(0, -h * 0.4),
            center + Offset(0, h * 0.45),
            [
              const Color(0xFFFFFDE7),
              Color.lerp(const Color(0xFFFFF8E1), cargoTint, 0.12)!,
              const Color(0xFFEFEBE9),
            ],
            const [0.0, 0.45, 1.0],
          ),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFF5D4037).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, radius * 0.08),
      );
    }

    canvas.drawCircle(
      center,
      radius + 3.5,
      Paint()
        ..color = cargoTint.withValues(alpha: 0.35 + 0.25 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  static void paintGlyph({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required String char,
    Color color = const Color(0xFF3E2723),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: char.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: math.min(radius * 0.88, 20),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
