import 'app_release_notes.dart';

class AppUpdateManifest {
  const AppUpdateManifest({
    required this.androidVersionCode,
    required this.androidVersionName,
    required this.apkUrl,
    required this.androidForceUpdate,
    required this.windowsVersionCode,
    required this.windowsVersionName,
    required this.windowsUrl,
    required this.windowsForceUpdate,
    required this.forceUpdate,
    this.releaseNotes = AppReleaseNotes.empty,
  });

  final int androidVersionCode;
  final String androidVersionName;
  final String apkUrl;
  final bool androidForceUpdate;
  final int windowsVersionCode;
  final String windowsVersionName;
  final String windowsUrl;
  final bool windowsForceUpdate;
  /// Legacy Android-only flag from older API responses.
  final bool forceUpdate;
  final AppReleaseNotes releaseNotes;

  factory AppUpdateManifest.fromJson(Map<String, dynamic> json) {
    final androidForce =
        ((json['android_force_update'] as num?)?.toInt() ??
            (json['force_update'] as num?)?.toInt() ??
            0) ==
        1;
    return AppUpdateManifest(
      androidVersionCode: (json['android_version_code'] as num?)?.toInt() ?? 0,
      androidVersionName: (json['android_version_name'] ?? '').toString(),
      apkUrl: (json['apk_url'] ?? '').toString(),
      androidForceUpdate: androidForce,
      windowsVersionCode: (json['windows_version_code'] as num?)?.toInt() ?? 0,
      windowsVersionName: (json['windows_version_name'] ?? '').toString(),
      windowsUrl: (json['windows_url'] ?? '').toString(),
      windowsForceUpdate:
          ((json['windows_force_update'] as num?)?.toInt() ?? 0) == 1,
      forceUpdate: androidForce,
      releaseNotes: AppReleaseNotes.fromJson(json['release_notes']),
    );
  }
}
