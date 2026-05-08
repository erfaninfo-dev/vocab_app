import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/update/apk_download_dialog.dart';
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

    // Listen once the widget is mounted; show dialog only when an optional
    // update is available. Forced updates are handled by [ForcedUpdateBarrier].
    _updateSub = ref.listenManual<AsyncValue<AppUpdateCheck>>(
      appUpdateCheckProvider,
      (previous, next) {
        final check = next.valueOrNull;
        if (check == null) return;

        final isAndroid =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
        if (!isAndroid || !check.androidEligible) return;
        if (!check.updateAvailable || check.forceUpdate) return;
        if (check.apkUrl == null || check.apkUrl!.isEmpty) return;

        final alreadyShown = ref.read(_optionalUpdateShownThisSessionProvider);
        if (alreadyShown) return;

        unawaited(_maybeShowOptionalUpdateDialog(check));
      },
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

    // Avoid showing a dialog during build/layout.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final verLabel = (check.remoteVersionName ?? '').trim().isNotEmpty
        ? check.remoteVersionName!.trim()
        : '${check.remoteVersionCode ?? ''}';

    final result = await showDialog<_OptionalUpdateAction>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aboutUpdateAvailableVersion(verLabel)),
        content: Text(l10n.aboutInstallApkHint),
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
        showApkDownloadProgressDialog(context, check.apkUrl!);
        return;
      case _OptionalUpdateAction.later:
        await prefs.setInt(_kDismissedOptionalUpdateVersionCodeKey, remoteCode);
        return;
      case null:
        // User dismissed by tapping outside / back.
        return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _OptionalUpdateAction { download, later }

