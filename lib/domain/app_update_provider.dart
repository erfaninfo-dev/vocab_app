import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_info/package_info_provider.dart';
import 'api_providers.dart';

class AppUpdateCheck {
  const AppUpdateCheck({
    required this.androidEligible,
    required this.windowsEligible,
    required this.localBuildNumber,
    required this.updateAvailable,
    required this.forceUpdate,
    this.remoteVersionCode,
    this.remoteVersionName,
    this.downloadUrl,
    this.checkFailed = false,
  });

  final bool androidEligible;
  final bool windowsEligible;
  final int localBuildNumber;
  final bool updateAvailable;
  final bool forceUpdate;
  final int? remoteVersionCode;
  final String? remoteVersionName;
  final String? downloadUrl;
  final bool checkFailed;

  bool get updateEligible => androidEligible || windowsEligible;
}

final appUpdateCheckProvider = FutureProvider<AppUpdateCheck>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final PackageInfo pkg = await ref.watch(packageInfoProvider.future);
  final local = int.tryParse(pkg.buildNumber) ?? 0;

  final isAndroid =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final isWindows =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  final manifest = await api.fetchAppUpdateManifest(
    installedVersion: local > 0 ? local : null,
    installedVersionName: pkg.version,
    platform: isWindows ? 'windows' : 'android',
  );
  if (manifest == null) {
    return AppUpdateCheck(
      androidEligible: isAndroid,
      windowsEligible: isWindows,
      localBuildNumber: local,
      updateAvailable: false,
      forceUpdate: false,
      checkFailed: true,
    );
  }

  int remoteCode = 0;
  String remoteName = '';
  String downloadUrl = '';
  bool forceUpdate = false;

  if (isAndroid) {
    remoteCode = manifest.androidVersionCode;
    remoteName = manifest.androidVersionName;
    downloadUrl = manifest.apkUrl;
    forceUpdate = manifest.androidForceUpdate;
  } else if (isWindows) {
    remoteCode = manifest.windowsVersionCode;
    remoteName = manifest.windowsVersionName;
    downloadUrl = manifest.windowsUrl;
    forceUpdate = manifest.windowsForceUpdate;
  }

  final available = remoteCode > local && downloadUrl.isNotEmpty;

  return AppUpdateCheck(
    androidEligible: isAndroid,
    windowsEligible: isWindows,
    localBuildNumber: local,
    updateAvailable: available,
    forceUpdate: available && forceUpdate,
    remoteVersionCode: remoteCode > 0 ? remoteCode : null,
    remoteVersionName: remoteName.isNotEmpty ? remoteName : null,
    downloadUrl: downloadUrl.isNotEmpty ? downloadUrl : null,
  );
});
