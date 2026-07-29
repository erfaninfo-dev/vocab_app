import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_sound_prefs.dart';

DateTime? _lastLightImpactAt;

/// Haptics gated by [appHapticsEnabledProvider] (`sound_haptics_enabled_v1`).
void appHaptic(WidgetRef ref, void Function() feedback) {
  if (!ref.read(appHapticsEnabledProvider)) return;
  feedback();
}

void appHapticSelection(WidgetRef ref) =>
    appHaptic(ref, HapticFeedback.selectionClick);

void appHapticLight(WidgetRef ref) =>
    appHaptic(ref, HapticFeedback.lightImpact);

/// Gun fire: lightImpact, at most once per [minInterval].
void appHapticLightThrottled(
  WidgetRef ref, {
  Duration minInterval = const Duration(milliseconds: 80),
}) {
  if (!ref.read(appHapticsEnabledProvider)) return;
  final now = DateTime.now();
  final last = _lastLightImpactAt;
  if (last != null && now.difference(last) < minInterval) return;
  _lastLightImpactAt = now;
  HapticFeedback.lightImpact();
}

void appHapticMedium(WidgetRef ref) =>
    appHaptic(ref, HapticFeedback.mediumImpact);

void appHapticHeavy(WidgetRef ref) =>
    appHaptic(ref, HapticFeedback.heavyImpact);

/// Word complete: two medium impacts ~90ms apart.
Future<void> appHapticWordComplete(WidgetRef ref) async {
  if (!ref.read(appHapticsEnabledProvider)) return;
  HapticFeedback.mediumImpact();
  await Future<void>.delayed(const Duration(milliseconds: 90));
  if (!ref.read(appHapticsEnabledProvider)) return;
  HapticFeedback.mediumImpact();
}
