import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../network/resolve_update_url.dart';
import 'apk_download_dialog.dart' show showApkDownloadProgressDialog;
import 'windows_update_installer.dart';

/// Shows the platform-appropriate in-app update download flow.
Future<void> showPlatformUpdateDownloadDialog(
  BuildContext context,
  String url, {
  required bool androidEligible,
  required bool windowsEligible,
}) async {
  if (androidEligible) {
    await showApkDownloadProgressDialog(context, url);
    return;
  }
  if (windowsEligible) {
    await showWindowsDownloadProgressDialog(context, url);
  }
}

class _DownloadProgress {
  const _DownloadProgress({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final double progress;
  final int receivedBytes;
  final int totalBytes;
}

Future<void> showWindowsDownloadProgressDialog(
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

  final progressN = ValueNotifier<_DownloadProgress>(
    const _DownloadProgress(
      progress: -1,
      receivedBytes: 0,
      totalBytes: -1,
    ),
  );

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ValueListenableBuilder<_DownloadProgress>(
      valueListenable: progressN,
      builder: (context, p, _) {
        final percent =
            p.progress >= 0 ? (p.progress * 100).clamp(0, 100) : null;
        final receivedMb = p.receivedBytes / 1024 / 1024;
        final totalMb = p.totalBytes > 0 ? p.totalBytes / 1024 / 1024 : null;
        return AlertDialog(
          title: Text(l10n.aboutDownloadingWindowsUpdate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: p.progress >= 0 ? p.progress : null,
              ),
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

  String? packagePath;
  Object? downloadError;
  try {
    packagePath = await downloadWindowsUpdate(
      resolved.toString(),
      onProgress: (p, r, t) {
        progressN.value = _DownloadProgress(
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

  if (packagePath == null || !context.mounted) return;
  await _showWindowsInstallReadyDialog(context, packagePath);
}

Future<void> _showWindowsInstallReadyDialog(
  BuildContext context,
  String packagePath,
) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _WindowsInstallReadyDialog(
      packagePath: packagePath,
      l10n: l10n,
    ),
  );
}

class _WindowsInstallReadyDialog extends StatefulWidget {
  const _WindowsInstallReadyDialog({
    required this.packagePath,
    required this.l10n,
  });

  final String packagePath;
  final AppLocalizations l10n;

  @override
  State<_WindowsInstallReadyDialog> createState() =>
      _WindowsInstallReadyDialogState();
}

class _WindowsInstallReadyDialogState extends State<_WindowsInstallReadyDialog> {
  bool _launching = false;
  bool _failed = false;

  Future<void> _install() async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _failed = false;
    });
    final status = await launchWindowsUpdate(widget.packagePath);
    if (!mounted) return;
    if (status == WindowsUpdateLaunchStatus.launched) {
      Navigator.of(context, rootNavigator: true).pop();
      // Give PowerShell time to enter Wait-Process before we exit.
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      exit(0);
    }
    setState(() {
      _launching = false;
      _failed = true;
    });
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
          Text(l10n.aboutInstallWindowsReadyMessage),
          if (_failed) ...[
            const SizedBox(height: 12),
            Text(
              l10n.aboutInstallLaunchFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              l10n.aboutInstallWindowsHint,
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
              : const Icon(Icons.install_desktop_rounded),
          label: Text(l10n.aboutInstallNow),
        ),
      ],
    );
  }
}
