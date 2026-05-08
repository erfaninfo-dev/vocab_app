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

/// Downloads the APK with a non-dismissible progress dialog, then shows an
/// "Install now" dialog so the user can fire the system installer (and retry
/// if Android needs the "install unknown apps" permission).
Future<void> showApkDownloadProgressDialog(
  BuildContext context,
  String url,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (!context.mounted) return;
  final resolved = resolveUpdateDownloadUrl(url);
  if (resolved == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
    );
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

  String? apkPath;
  Object? downloadError;
  try {
    apkPath = await downloadAndroidApk(
      resolved.toString(),
      onProgress: (p, r, t) {
        progressN.value = _ApkDownloadProgress(
          progress: p,
          receivedBytes: r,
          totalBytes: t,
        );
      },
    );
  } catch (e) {
    downloadError = e;
  } finally {
    progressN.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (downloadError != null) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.aboutDownloadApkFailed)),
      );
    }
    return;
  }

  if (apkPath == null || !context.mounted) return;
  await _showInstallReadyDialog(context, apkPath);
}

Future<void> _showInstallReadyDialog(
  BuildContext context,
  String apkPath,
) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _InstallReadyDialog(apkPath: apkPath, l10n: l10n),
  );
}

class _InstallReadyDialog extends StatefulWidget {
  const _InstallReadyDialog({required this.apkPath, required this.l10n});

  final String apkPath;
  final AppLocalizations l10n;

  @override
  State<_InstallReadyDialog> createState() => _InstallReadyDialogState();
}

class _InstallReadyDialogState extends State<_InstallReadyDialog> {
  bool _launching = false;
  bool _permissionRequired = false;
  bool _failed = false;

  Future<void> _install() async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _permissionRequired = false;
      _failed = false;
    });
    final status = await openDownloadedApk(widget.apkPath);
    if (!mounted) return;
    switch (status) {
      case ApkInstallLaunchStatus.launched:
        Navigator.of(context, rootNavigator: true).pop();
        return;
      case ApkInstallLaunchStatus.permissionRequired:
        setState(() {
          _launching = false;
          _permissionRequired = true;
        });
        return;
      case ApkInstallLaunchStatus.failed:
        setState(() {
          _launching = false;
          _failed = true;
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.aboutDownloadComplete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.aboutInstallReadyMessage),
          if (_permissionRequired) ...[
            const SizedBox(height: 12),
            Text(
              l10n.aboutInstallPermissionRequired,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ] else if (_failed) ...[
            const SizedBox(height: 12),
            Text(
              l10n.aboutInstallLaunchFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              l10n.aboutInstallApkHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _launching
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(l10n.aboutLater),
        ),
        FilledButton.icon(
          onPressed: _launching ? null : _install,
          icon: _launching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.install_mobile_rounded),
          label: Text(l10n.aboutInstallNow),
        ),
      ],
    );
  }
}
