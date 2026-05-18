import 'app_release_notes.dart';

class AppUpdateManifest {
  const AppUpdateManifest({
    required this.androidVersionCode,
    required this.androidVersionName,
    required this.apkUrl,
    required this.forceUpdate,
    this.releaseNotes = AppReleaseNotes.empty,
  });

  final int androidVersionCode;
  final String androidVersionName;
  final String apkUrl;
  final bool forceUpdate;
  final AppReleaseNotes releaseNotes;

  factory AppUpdateManifest.fromJson(Map<String, dynamic> json) {
    return AppUpdateManifest(
      androidVersionCode: (json['android_version_code'] as num?)?.toInt() ?? 0,
      androidVersionName: (json['android_version_name'] ?? '').toString(),
      apkUrl: (json['apk_url'] ?? '').toString(),
      forceUpdate: ((json['force_update'] as num?)?.toInt() ?? 0) == 1,
      releaseNotes: AppReleaseNotes.fromJson(json['release_notes']),
    );
  }
}
