import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/update/platform_update_download_dialog.dart';
import '../../domain/app_update_provider.dart';
import '../../l10n/app_localizations.dart';

const _kDismissedOptionalUpdateVersionCodeKey =
    'dismissed_optional_update_version_code_v1';

final _optionalUpdateShownThisSessionProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class OptionalUpdatePrompt extends ConsumerStatefulWidget {
  const OptionalUpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OptionalUpdatePrompt> createState() => _OptionalUpdatePromptState();
}

class _OptionalUpdatePromptState extends ConsumerState<OptionalUpdatePrompt> {
  ProviderSubscription<AsyncValue<AppUpdateCheck>>? _updateSub;

  @override
  void initState() {
    super.initState();

    _updateSub = ref.listenManual<AsyncValue<AppUpdateCheck>>(
      appUpdateCheckProvider,
      (previous, next) {
        final check = next.valueOrNull;
        if (check == null) return;

        if (!check.updateEligible) return;
        if (!check.updateAvailable || check.forceUpdate) return;
        if (check.downloadUrl == null || check.downloadUrl!.isEmpty) return;

        final alreadyShown = ref.read(_optionalUpdateShownThisSessionProvider);
        if (alreadyShown) return;

        unawaited(_maybeShowOptionalUpdateDialog(check));
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _updateSub?.close();
    _updateSub = null;
    super.dispose();
  }

  Future<void> _maybeShowOptionalUpdateDialog(AppUpdateCheck check) async {
    final remoteCode = check.remoteVersionCode ?? 0;
    if (remoteCode <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissedCode =
        prefs.getInt(_kDismissedOptionalUpdateVersionCodeKey) ?? 0;
    if (dismissedCode >= remoteCode) return;

    if (!mounted) return;
    ref.read(_optionalUpdateShownThisSessionProvider.notifier).state = true;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final verLabel = (check.remoteVersionName ?? '').trim().isNotEmpty
        ? check.remoteVersionName!.trim()
        : '${check.remoteVersionCode ?? ''}';
    final hint = check.windowsEligible
        ? l10n.aboutInstallWindowsHint
        : l10n.aboutInstallApkHint;

    final result = await showDialog<_OptionalUpdateAction>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aboutUpdateAvailableVersion(verLabel)),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_OptionalUpdateAction.later),
            child: Text(l10n.aboutLater),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(ctx).pop(_OptionalUpdateAction.download),
            icon: const Icon(Icons.download_rounded),
            label: Text(l10n.aboutDownloadApkUpdate),
          ),
        ],
      ),
    );

    if (!mounted) return;
    switch (result) {
      case _OptionalUpdateAction.download:
        showPlatformUpdateDownloadDialog(
          context,
          check.downloadUrl!,
          androidEligible: check.androidEligible,
          windowsEligible: check.windowsEligible,
        );
        return;
      case _OptionalUpdateAction.later:
        await prefs.setInt(_kDismissedOptionalUpdateVersionCodeKey, remoteCode);
        return;
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _OptionalUpdateAction { download, later }
