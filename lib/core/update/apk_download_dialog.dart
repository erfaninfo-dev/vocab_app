import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../network/resolve_update_url.dart';
import 'android_apk_installer.dart';

class _ApkDownloadProgress {
  const _ApkDownloadProgress({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final double progress;
  final int receivedBytes;
  final int totalBytes;
}

/// Downloads the APK with a non-dismissible progress dialog, then opens the installer.
Future<void> showApkDownloadProgressDialog(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context)!;
  if (!context.mounted) return;
  final resolved = resolveUpdateDownloadUrl(url);
  if (resolved == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
    return;
  }

  final progressN = ValueNotifier<_ApkDownloadProgress>(
    const _ApkDownloadProgress(
      progress: -1,
      receivedBytes: 0,
      totalBytes: -1,
    ),
  );

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ValueListenableBuilder<_ApkDownloadProgress>(
      valueListenable: progressN,
      builder: (context, p, _) {
        final percent =
            p.progress >= 0 ? (p.progress * 100).clamp(0, 100) : null;
        final receivedMb = p.receivedBytes / 1024 / 1024;
        final totalMb = p.totalBytes > 0 ? p.totalBytes / 1024 / 1024 : null;
        return AlertDialog(
          title: Text(l10n.aboutDownloadingApk),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: p.progress >= 0 ? p.progress : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (percent != null)
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    )
                  else
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      totalMb != null
                          ? '${receivedMb.toStringAsFixed(1)} / ${totalMb.toStringAsFixed(1)} MB'
                          : '${receivedMb.toStringAsFixed(1)} MB',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
  try {
    await downloadAndOpenAndroidApk(
      resolved.toString(),
      onProgress: (p, r, t) {
        progressN.value = _ApkDownloadProgress(
          progress: p,
          receivedBytes: r,
          totalBytes: t,
        );
      },
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutDownloadApkFailed)),
      );
    }
  } finally {
    progressN.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
