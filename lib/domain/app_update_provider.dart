import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_info/package_info_provider.dart';
import 'api_providers.dart';

class AppUpdateCheck {
  const AppUpdateCheck({
    required this.androidEligible,
    required this.localBuildNumber,
    required this.updateAvailable,
    required this.forceUpdate,
    this.remoteVersionCode,
    this.remoteVersionName,
    this.apkUrl,
    this.checkFailed = false,
  });

  final bool androidEligible;
  final int localBuildNumber;
  final bool updateAvailable;
  final bool forceUpdate;
  final int? remoteVersionCode;
  final String? remoteVersionName;
  final String? apkUrl;
  final bool checkFailed;
}

final appUpdateCheckProvider = FutureProvider<AppUpdateCheck>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final PackageInfo pkg = await ref.watch(packageInfoProvider.future);
  final local = int.tryParse(pkg.buildNumber) ?? 0;

  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final manifest = await api.fetchAppUpdateManifest(
    installedVersion: local > 0 ? local : null,
    installedVersionName: pkg.version,
  );
  if (manifest == null) {
    return AppUpdateCheck(
      androidEligible: isAndroid,
      localBuildNumber: local,
      updateAvailable: false,
      forceUpdate: false,
      checkFailed: true,
    );
  }

  final remote = manifest.androidVersionCode;
  // `force_update` in MySQL is ignored unless the server build is newer than
  // the installed `versionCode` (pubspec +N / Android build number).
  final available =
      remote > local && manifest.apkUrl.isNotEmpty;

  return AppUpdateCheck(
    androidEligible: isAndroid,
    localBuildNumber: local,
    updateAvailable: available,
    forceUpdate: available && manifest.forceUpdate,
    remoteVersionCode: remote,
    remoteVersionName: manifest.androidVersionName,
    apkUrl: manifest.apkUrl,
  );
});
