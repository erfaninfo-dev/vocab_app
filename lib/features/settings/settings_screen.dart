import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info/package_info_provider.dart';
import '../../core/audio/splash_sound_controller.dart';
import '../../core/update/android_apk_installer.dart';
import '../../domain/app_update_provider.dart';
import '../../core/locale/ui_locale_provider.dart';
import '../../core/language/language_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../l10n/app_localizations.dart';
import 'theme_mode_controller.dart';

const _kSupportPhoneDisplay = '09107837602';
const _kSupportPhoneUri = 'tel:+989107837602';

final _aboutUpdateDismissedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

class _ApkDownloadProgress {
  const _ApkDownloadProgress({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final double progress; // -1 for indeterminate
  final int receivedBytes;
  final int totalBytes; // -1 when unknown
}

Future<void> _downloadApkUpdate(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context)!;
  if (!context.mounted) return;
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
      url,
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

Future<void> _openLatestDownloadLink(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.parse(url);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  }
}

Future<void> _openSupportPhone(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.parse(_kSupportPhoneUri);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final theme = ref.read(themeModeProvider.notifier);
    final notif = ref.watch(notifProvider);
    final notifN = ref.read(notifProvider.notifier);
    final splashSound = ref.watch(splashSoundProvider);
    final splashSoundN = ref.read(splashSoundProvider.notifier);
    final lang = ref.watch(langProvider);
    final langN = ref.read(langProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final uiLoc = ref.watch(uiLocaleProvider);
    final uiLocN = ref.read(uiLocaleProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withOpacity(0.06), scheme.surface],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _SectionLabel(label: l10n.sectionAppLanguage),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'en',
                    groupValue: uiLoc.languageCode,
                    onChanged: (v) {
                      if (v != null) uiLocN.setLocaleCode(v);
                    },
                    title: Text(l10n.langEnglish),
                  ),
                  RadioListTile<String>(
                    value: 'fa',
                    groupValue: uiLoc.languageCode,
                    onChanged: (v) {
                      if (v != null) uiLocN.setLocaleCode(v);
                    },
                    title: Text(l10n.langPersian),
                  ),
                  RadioListTile<String>(
                    value: 'ckb',
                    groupValue: uiLoc.languageCode,
                    onChanged: (v) {
                      if (v != null) uiLocN.setLocaleCode(v);
                    },
                    title: Text(l10n.langKurdishSorani),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Translation Language ──────────────────────────────────────────
            _SectionLabel(label: l10n.sectionTranslationLanguage),
            Card(
              child: Column(
                children: TranslationLang.values.map((l) {
                  return RadioListTile<TranslationLang>(
                    value: l,
                    groupValue: lang,
                    onChanged: (v) {
                      if (v != null) langN.setLang(v);
                    },
                    secondary: Text(
                      l == TranslationLang.fa ? '🇮🇷' : '🟢',
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      l == TranslationLang.fa
                          ? l10n.translationLangPersian
                          : l10n.translationLangKurdishSorani,
                    ),
                    subtitle: Text(l.englishLabel),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Theme ────────────────────────────────────────────────────────
            _SectionLabel(label: l10n.sectionAppearance),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: mode,
                    onChanged: (v) {
                      if (v != null) theme.setThemeMode(v);
                    },
                    title: Text(l10n.systemTheme),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: mode,
                    onChanged: (v) {
                      if (v != null) theme.setThemeMode(v);
                    },
                    title: Text(l10n.lightMode),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: mode,
                    onChanged: (v) {
                      if (v != null) theme.setThemeMode(v);
                    },
                    title: Text(l10n.darkMode),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Notifications ─────────────────────────────────────────────────
            _SectionLabel(label: l10n.sectionDailyReminder),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: Text(l10n.dailyStudyReminder),
                    subtitle: Text(
                      notif.enabled
                          ? l10n.reminderSetAt(notif.timeLabel)
                          : l10n.tapToEnableReminder,
                    ),
                    value: notif.enabled,
                    onChanged: (v) => notifN.setEnabled(v),
                  ),
                  if (notif.enabled) ...[
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: Text(l10n.reminderTime),
                      trailing: Text(
                        notif.timeLabel,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: notif.hour,
                            minute: notif.minute,
                          ),
                        );
                        if (picked != null) {
                          await notifN.setTime(picked.hour, picked.minute);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Sound ─────────────────────────────────────────────────────────
            _SectionLabel(label: l10n.sectionSound),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.music_note_rounded),
                title: Text(l10n.splashSoundTitle),
                subtitle: Text(l10n.splashSoundSubtitle),
                value: splashSound,
                onChanged: (v) => splashSoundN.setEnabled(v),
              ),
            ),

            const SizedBox(height: 16),

            // ── About ──────────────────────────────────────────────────────────
            _SectionLabel(label: l10n.sectionAbout),
            const _AboutCard(),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends ConsumerWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    final packageAsync = ref.watch(packageInfoProvider);
    final updateAsync = ref.watch(appUpdateCheckProvider);
    final dismissed = ref.watch(_aboutUpdateDismissedProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.secondaryContainer],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            children: [
              // ── App icon ──────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  // No background "frame" behind the logo — only shadow.
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── App name ──────────────────────────────────────────────────
              Text(
                l10nEn.appNameShort,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimaryContainer,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 6),

              // ── Author ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10nEn.byAuthor,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              packageAsync.when(
                data: (info) => Column(
                  children: [
                    Text(
                      l10n.aboutAppVersion(info.version, info.buildNumber),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    updateAsync.when(
                      data: (check) {
                        if (check.androidEligible) {
                          if (check.checkFailed) {
                            return Column(
                              children: [
                                Text(
                                  l10n.aboutUpdateCheckFailed,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSecondaryContainer,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => ref.invalidate(
                                    appUpdateCheckProvider,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text(l10n.aboutRetryUpdateCheck),
                                ),
                              ],
                            );
                          }
                          if (check.updateAvailable &&
                              check.apkUrl != null &&
                              check.apkUrl!.isNotEmpty) {
                            final verLabel =
                                (check.remoteVersionName ?? '').trim().isNotEmpty
                                ? check.remoteVersionName!.trim()
                                : '${check.remoteVersionCode ?? ''}';
                            return Column(
                              children: [
                                Text(
                                  l10n.aboutUpdateAvailableVersion(verLabel),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: scheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                if (!dismissed || check.forceUpdate)
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: () => _downloadApkUpdate(
                                          context,
                                          check.apkUrl!,
                                        ),
                                        icon: const Icon(Icons.download_rounded),
                                        label: Text(l10n.aboutDownloadApkUpdate),
                                      ),
                                      if (!check.forceUpdate)
                                        TextButton(
                                          onPressed: () => ref
                                              .read(
                                                _aboutUpdateDismissedProvider
                                                    .notifier,
                                              )
                                              .state = true,
                                          child: Text(l10n.aboutLater),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  check.forceUpdate
                                      ? l10n.aboutForcedUpdateNote
                                      : l10n.aboutInstallApkHint,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSecondaryContainer,
                                      ),
                                ),
                              ],
                            );
                          }
                          return Text(
                            l10n.aboutAppUpToDate,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          );
                        }
                        if (check.apkUrl == null || check.apkUrl!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return FilledButton.tonalIcon(
                          onPressed: () => _openLatestDownloadLink(
                            context,
                            check.apkUrl!,
                          ),
                          icon: const Icon(Icons.system_update_rounded),
                          label: Text(l10n.aboutUpdateFromPlayStore),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => Column(
                        children: [
                          Text(
                            l10n.aboutUpdateCheckFailed,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSecondaryContainer),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                ref.invalidate(appUpdateCheckProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.aboutRetryUpdateCheck),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 28,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),
              Divider(color: scheme.outline.withOpacity(0.3)),
              const SizedBox(height: 16),

              // ── Website ───────────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'www.erfaninfo.com'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.linkCopied),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: scheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'www.erfaninfo.com',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _openSupportPhone(context),
                onLongPress: () {
                  Clipboard.setData(
                    const ClipboardData(text: _kSupportPhoneDisplay),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.aboutPhoneCopied),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: scheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.aboutPhoneLabel}: ',
                        style: TextStyle(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          _kSupportPhoneDisplay,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
