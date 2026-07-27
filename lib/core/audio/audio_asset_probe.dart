import 'package:flutter/services.dart';

final Map<String, bool> _audioAssetExistsCache = {};

/// Returns whether [assetPath] is present in the Flutter asset bundle.
///
/// Missing optional SFX must be skipped *before* calling `just_audio` —
/// loading a missing asset on Windows corrupts the native player and can
/// silence unrelated sounds until restart.
Future<bool> audioAssetExists(String assetPath) async {
  final cached = _audioAssetExistsCache[assetPath];
  if (cached != null) return cached;
  try {
    await rootBundle.load(assetPath);
    return _audioAssetExistsCache[assetPath] = true;
  } catch (_) {
    return _audioAssetExistsCache[assetPath] = false;
  }
}
