import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../network/resolve_update_url.dart';

/// Some hosts block or mis-handle the default Dart [http] user agent; browsers work.
const _kApkDownloadUserAgent =
    'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

const _kApkFileName = 'erfan_academy_update.apk';

/// Outcome of attempting to launch the system APK installer.
enum ApkInstallLaunchStatus {
  /// The installer was launched successfully.
  launched,

  /// Android refused because the app lacks "install unknown apps" permission.
  /// The caller should ask the user to allow it in system settings.
  permissionRequired,

  /// Some other failure (file missing, no installer, etc.).
  failed,
}

/// Downloads the release APK to a temp file and returns its path. Throws on
/// network/disk failure.
Future<String> downloadAndroidApk(
  String url, {
  void Function(double progress, int received, int total)? onProgress,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    throw UnsupportedError('APK download is only supported on Android');
  }

  final uri = resolveUpdateDownloadUrl(url);
  if (uri == null) {
    throw ArgumentError.value(url, 'url', 'invalid update URL');
  }
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$_kApkFileName';
  final file = File(path);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {}
  }

  final client = http.Client();
  try {
    final request = http.Request('GET', uri);
    request.headers['User-Agent'] = _kApkDownloadUserAgent;
    request.headers['Accept'] = '*/*';
    request.headers['Accept-Encoding'] = 'identity';
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? -1;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null && total > 0) {
          onProgress(received / total, received, total);
        } else if (onProgress != null) {
          onProgress(-1, received, total);
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  } finally {
    client.close();
  }

  return path;
}

/// Asks Android to display the package installer for [apkPath]. Returns a
/// status the UI can branch on.
Future<ApkInstallLaunchStatus> openDownloadedApk(String apkPath) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return ApkInstallLaunchStatus.failed;
  }
  final file = File(apkPath);
  if (!await file.exists()) return ApkInstallLaunchStatus.failed;

  final result = await OpenFilex.open(apkPath);
  switch (result.type) {
    case ResultType.done:
      return ApkInstallLaunchStatus.launched;
    case ResultType.permissionDenied:
      return ApkInstallLaunchStatus.permissionRequired;
    case ResultType.fileNotFound:
    case ResultType.noAppToOpen:
    case ResultType.error:
      return ApkInstallLaunchStatus.failed;
  }
}
