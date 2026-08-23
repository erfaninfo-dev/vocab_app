import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/silhouettes/wb_crack_overlay.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/silhouettes/wb_silhouette.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/silhouettes/wb_silhouettes_registry.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/silhouettes/wb_special_silhouettes.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';

void main() {
  tearDown(() {
    clearSilhouetteCache();
    WbGearSilhouette.clearTeethCache();
  });

  test('every archetype has a silhouette registry entry', () {
    expect(kWbSilhouettes.length, WbPropArchetype.values.length);
    for (final id in WbPropArchetype.values) {
      expect(kWbSilhouettes.containsKey(id), isTrue, reason: '$id');
    }
  });

  test('silhouetteFor caches the same Path instance', () {
    final a = silhouetteFor(WbPropArchetype.balloon);
    final b = silhouetteFor(WbPropArchetype.balloon);
    expect(identical(a, b), isTrue);
  });

  test('silhouette paths are non-empty and finite', () {
    for (final id in WbPropArchetype.values) {
      final path = silhouetteFor(id);
      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(0), reason: '$id');
      expect(bounds.height, greaterThan(0), reason: '$id');
      expect(bounds.left, greaterThanOrEqualTo(-0.05), reason: '$id');
      expect(bounds.top, greaterThanOrEqualTo(-0.05), reason: '$id');
      expect(bounds.right, lessThanOrEqualTo(1.05), reason: '$id');
      expect(bounds.bottom, lessThanOrEqualTo(1.05), reason: '$id');
    }
  });

  test('gear pathForTeeth caches per tooth count', () {
    final a = WbGearSilhouette.pathForTeeth(8);
    final b = WbGearSilhouette.pathForTeeth(8);
    final c = WbGearSilhouette.pathForTeeth(5);
    expect(identical(a, b), isTrue);
    expect(identical(a, c), isFalse);
  });

  test('crack overlays produce strokes', () {
    expect(WbCrackOverlay.simpleCrack().getBounds().width, greaterThan(0));
    expect(WbCrackOverlay.dualCrack().getBounds().width, greaterThan(0));
    expect(
      WbCrackOverlay.cascade([const Offset(0.3, 0.3), const Offset(0.6, 0.5)])
          .getBounds()
          .width,
      greaterThan(0),
    );
    expect(WbCrackOverlay.spiderweb().getBounds().width, greaterThan(0));
  });

  test('crack stroke paint enforces min 1.5px width', () {
    final p = WbCrackOverlay.crackStrokePaint(const Color(0xFFFFFFFF),
        strokeWidthPx: 0.5);
    expect(p.strokeWidth, greaterThanOrEqualTo(1.5));
  });

  test('simplifiedBelowRadius defaults to 14 and gates fallback', () {
    final spec = kWbArchetypes[WbPropArchetype.balloon]!;
    expect(spec.simplifiedBelowRadius, 16);
    expect(
      useSimplifiedSilhouette(radiusPx: 10, spec: spec),
      isTrue,
    );
    expect(
      useSimplifiedSilhouette(radiusPx: 20, spec: spec),
      isFalse,
    );
  });

  test('erodeClip keeps even-odd pits', () {
    final body = silhouetteFor(WbPropArchetype.concreteBlock);
    final clipped = WbCrackOverlay.erodeClip(
      body,
      const [Offset(0.4, 0.4), Offset(0.6, 0.55)],
    );
    expect(clipped.fillType, PathFillType.evenOdd);
  });
}
