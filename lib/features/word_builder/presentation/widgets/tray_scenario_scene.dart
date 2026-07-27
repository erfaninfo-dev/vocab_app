import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/word_builder_game_notifier.dart';
import '../../domain/tray_scenario_kind.dart';
import 'tray_prison_scene.dart';
import 'tray_train_scene.dart';
import 'tray_water_scene.dart';

/// Facade that picks the tray-center visuals for the current level:
/// water tub, train-escape or prison-escape diorama. The letter ring,
/// layout and gameplay are untouched — only this center layer switches.
class TrayScenarioScene extends ConsumerWidget {
  const TrayScenarioScene({
    super.key,
    required this.bookKey,
    required this.size,
    required this.center,
    required this.innerRadius,
    required this.saucerRadius,
    required this.faceRadius,
  });

  final int bookKey;
  final Size size;
  final Offset center;

  /// Scene circle inside the saucer (≈ 0.72 × [saucerRadius]).
  final double innerRadius;
  final double saucerRadius;
  final double faceRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenario = ref.watch(
      wordBuilderGameProvider(bookKey).select(
        (async) =>
            async.valueOrNull?.trayScenario ?? TrayScenarioKind.water,
      ),
    );

    switch (scenario) {
      case TrayScenarioKind.water:
        return TrayWaterScene(
          bookKey: bookKey,
          size: size,
          center: center,
          tubRadius: innerRadius,
          saucerRadius: saucerRadius,
          faceRadius: faceRadius,
        );
      case TrayScenarioKind.train:
        return TrayTrainScene(
          bookKey: bookKey,
          size: size,
          center: center,
          sceneRadius: innerRadius,
          saucerRadius: saucerRadius,
          characterRadius: faceRadius,
        );
      case TrayScenarioKind.prison:
        return TrayPrisonScene(
          bookKey: bookKey,
          size: size,
          center: center,
          sceneRadius: innerRadius,
          saucerRadius: saucerRadius,
          characterRadius: faceRadius,
        );
    }
  }
}
