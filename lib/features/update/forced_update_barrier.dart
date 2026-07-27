import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/update/apk_download_dialog.dart';
import '../../core/widgets/app_jelly_style.dart';
import '../../domain/app_update_provider.dart';
import '../../l10n/app_localizations.dart';

/// Blocks the entire app when the server requires an update (Android sideload flow).
///
/// The server row must have `force_update = 1`, a non-empty `apk_url`, and
/// `version_code` greater than the installed Android `versionCode` (pubspec +build).
class ForcedUpdateBarrier extends ConsumerWidget {
  const ForcedUpdateBarrier({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCheck = ref.watch(appUpdateCheckProvider);
    final check = asyncCheck.valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final block = check != null &&
        isAndroid &&
        check.forceUpdate &&
        check.updateAvailable &&
        (check.apkUrl != null && check.apkUrl!.isNotEmpty);

    return PopScope(
      canPop: !block,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AbsorbPointer(absorbing: block, child: child),
          if (block)
            Material(
              color: Colors.black54,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: AppJellyCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.system_update_alt_rounded,
                                size: 48,
                                color: scheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.aboutUpdateAvailableVersion(
                                  (check.remoteVersionName ?? '').trim().isNotEmpty
                                      ? check.remoteVersionName!.trim()
                                      : '${check.remoteVersionCode ?? ''}',
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.aboutForcedUpdateNote,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () {
                                  final url = check.apkUrl;
                                  if (url == null || url.isEmpty) return;
                                  showApkDownloadProgressDialog(context, url);
                                },
                                icon: const Icon(Icons.download_rounded),
                                label: Text(l10n.aboutDownloadApkUpdate),
                              ),
                            ],
                          ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
