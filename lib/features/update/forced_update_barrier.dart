import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/update/platform_update_download_dialog.dart';
import '../../core/widgets/app_jelly_style.dart';
import '../../domain/app_update_provider.dart';
import '../../l10n/app_localizations.dart';

/// Blocks the entire app when the server requires an update (Android / Windows sideload).
class ForcedUpdateBarrier extends ConsumerWidget {
  const ForcedUpdateBarrier({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCheck = ref.watch(appUpdateCheckProvider);
    final check = asyncCheck.valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final block = check != null &&
        check.updateEligible &&
        check.forceUpdate &&
        check.updateAvailable &&
        (check.downloadUrl != null && check.downloadUrl!.isNotEmpty);

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
                                  (check.remoteVersionName ?? '')
                                      .trim()
                                      .isNotEmpty
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
                                  final url = check.downloadUrl;
                                  if (url == null || url.isEmpty) return;
                                  showPlatformUpdateDownloadDialog(
                                    context,
                                    url,
                                    androidEligible: check.androidEligible,
                                    windowsEligible: check.windowsEligible,
                                  );
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
