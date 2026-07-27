import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../../core/audio/splash_sound_controller.dart';
import '../../core/locale/ui_locale_provider.dart';
import '../../core/language/language_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/widgets/app_jelly_style.dart';
import '../../core/widgets/app_gradient_scaffold.dart';
import '../../l10n/app_localizations.dart';
import 'theme_mode_controller.dart';
import 'widgets/about_card.dart';

Future<void> _showAboutSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.9;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: const AboutCard(),
        ),
      );
    },
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final theme = ref.read(themeModeProvider.notifier);
    final notif = ref.watch(notifProvider);
    final notifN = ref.read(notifProvider.notifier);
    final lang = ref.watch(langProvider);
    final langN = ref.read(langProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final uiLoc = ref.watch(uiLocaleProvider);
    final uiLocN = ref.read(uiLocaleProvider.notifier);

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      title: Text(l10n.settingsTitle),
      actions: [
        IconButton(
          tooltip: l10n.sectionAbout,
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () => _showAboutSheet(context),
        ),
      ],
    );
    final topInset = appGradientContentTopInset(context, appBar: appBar, extra: 12);

    return AppGradientScaffold(
      appBar: appBar,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 16),
        children: [
            _SectionLabel(label: l10n.sectionAppLanguage),
            AppJellyCard(
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

            _SectionLabel(label: l10n.sectionTranslationLanguage),
            AppJellyCard(
              child: Column(
                children: TranslationLang.values.map((l) {
                  return RadioListTile<TranslationLang>(
                    value: l,
                    groupValue: lang,
                    onChanged: (v) {
                      if (v != null) langN.setLang(v);
                    },
                    title: Text(
                      l == TranslationLang.fa
                          ? l10n.translationLangPersian
                          : l10n.translationLangKurdishSorani,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            _SectionLabel(label: l10n.sectionAppearance),
            AppJellyCard(
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

            _SectionLabel(label: l10n.sectionDailyReminder),
            AppJellyCard(
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

            // Startup chime setting hidden for now.
            // _SectionLabel(label: l10n.sectionSound),
            // Card(
            //   child: SwitchListTile(
            //     secondary: const Icon(Icons.music_note_rounded),
            //     title: Text(l10n.splashSoundTitle),
            //     subtitle: Text(l10n.splashSoundSubtitle),
            //     value: splashSound,
            //     onChanged: (v) => splashSoundN.setEnabled(v),
            //   ),
            // ),
            // const SizedBox(height: 16),

            _SectionLabel(label: l10n.sectionAbout),
            const AboutCard(),
          ],
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
