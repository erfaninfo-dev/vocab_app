import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/theme/word_builder_chapter_theme.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_loadout.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_painter.dart';

/// Mid-sky — soft luminance floor; hue separation carries most readability
/// on cheerful palettes (candy orbs on blue/green/orange).
const kWbOrbMidContrastMin = 1.08;

/// Top/bottom atmosphere — decorative only.
const kWbOrbEdgeContrastMin = 1.0;

double wbContrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final light = math.max(l1, l2);
  final dark = math.min(l1, l2);
  return (light + 0.05) / (dark + 0.05);
}

Color wbMaterialBodyColor(AngryWordsPropMaterial m, {int palette = 0}) {
  final pair = angryWordsColorsForMaterial(m, palette);
  return Color.lerp(pair[0], pair[1], 0.5)!;
}

Color wbArchetypeBodyColor(WbArchetypeSpec spec) {
  if (spec.palette.isEmpty) {
    return wbMaterialBodyColor(spec.material);
  }
  if (spec.palette.length == 1) return spec.palette.first;
  return Color.lerp(spec.palette[0], spec.palette[1], 0.5)!;
}

void main() {
  test('chapter skies keep materials readable (mid strict, edges soft)', () {
    final failures = <String>[];

    for (final chapter in WbChapterTheme.all) {
      for (var si = 0; si < chapter.skyStops.length; si++) {
        final sky = chapter.skyStops[si];
        final minRatio =
            si == 1 ? kWbOrbMidContrastMin : kWbOrbEdgeContrastMin;
        final fillerFloor = si == 1 ? 1.02 : 1.0;

        for (final material in AngryWordsPropMaterial.values) {
          final body = wbMaterialBodyColor(material);
          final cargoRatio = wbContrastRatio(body, sky);
          final filler = chapter.biasFillerTowardBackground(body);
          final fillerRatio = wbContrastRatio(filler, sky);

          if (cargoRatio < minRatio) {
            failures.add(
              '${chapter.name} sky[$si] vs $material cargo '
              'ratio=${cargoRatio.toStringAsFixed(2)} '
              '(need ≥${minRatio.toStringAsFixed(2)}; '
              'sky=${_hex(sky)} body=${_hex(body)})',
            );
          }
          if (fillerRatio < fillerFloor) {
            failures.add(
              '${chapter.name} sky[$si] vs $material filler '
              'ratio=${fillerRatio.toStringAsFixed(2)} '
              '(need ≥${fillerFloor.toStringAsFixed(2)}; '
              'sky=${_hex(sky)} filler=${_hex(filler)})',
            );
          }
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Adjust chapter backgrounds (not material colors).\n'
          '${failures.take(50).join('\n')}'
          '${failures.length > 50 ? '\n… +${failures.length - 50} more' : ''}',
    );
  });

  test('stage archetypes stay readable on their chapter mid-sky', () {
    final failures = <String>[];

    for (final L in kAngryWordsStageArsenal) {
      final stage = L.profileIndex + 1;
      final chapter = WbChapterTheme.forStage(stage);
      final sky = chapter.skyStops.length > 1
          ? chapter.skyStops[1]
          : chapter.skyStops.first;

      void check(WbPropArchetype id, {required bool cargo}) {
        final spec = kWbArchetypes[id];
        if (spec == null) {
          failures.add('stage $stage missing archetype $id');
          return;
        }
        final body = wbArchetypeBodyColor(spec);
        final ratio = wbContrastRatio(
          cargo ? body : chapter.biasFillerTowardBackground(body),
          sky,
        );
        final floor = cargo ? kWbOrbMidContrastMin : 1.02;
        if (ratio < floor) {
          failures.add(
            'stage $stage ${chapter.name} ${cargo ? 'primary' : 'filler'} '
            '${spec.labelEn} (${spec.id.name}) '
            'ratio=${ratio.toStringAsFixed(2)} need ≥${floor.toStringAsFixed(2)} '
            'sky=${_hex(sky)} body=${_hex(body)}',
          );
        }
      }

      check(L.primaryArchetype, cargo: true);
      final filler = L.fillerArchetype;
      if (filler != null) check(filler, cargo: false);
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Tune archetype palettes (or chapter sky) — watch concrete/granite/ice.\n'
          '${failures.take(40).join('\n')}'
          '${failures.length > 40 ? '\n… +${failures.length - 40} more' : ''}',
    );
  });

  test('cargo vs filler primaryRatio keeps majority cargo skin', () {
    for (final L in kAngryWordsStageArsenal) {
      expect(L.primaryRatio, greaterThanOrEqualTo(0.6));
      if (L.fillerArchetype != null) {
        expect(L.primaryArchetype, isNot(equals(L.fillerArchetype)));
      }
    }
  });

  test('narrow / gear archetypes request letter plaques', () {
    expect(
      kWbArchetypes[WbPropArchetype.metalGear]!.needsLetterPlaque,
      isTrue,
    );
    expect(
      kWbArchetypes[WbPropArchetype.neonTube]!.needsLetterPlaque,
      isTrue,
    );
    expect(
      kWbArchetypes[WbPropArchetype.glassBottle]!.needsLetterPlaque,
      isTrue,
    );
    expect(
      kWbArchetypes[WbPropArchetype.balloon]!.needsLetterPlaque,
      isFalse,
    );
  });
}

String _hex(Color c) {
  final v = c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#${v.substring(2)}';
}
