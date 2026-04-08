import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../core/language/language_provider.dart';
import '../../core/notifications/notification_service.dart';
import 'theme_mode_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode    = ref.watch(themeModeProvider);
    final theme   = ref.read(themeModeProvider.notifier);
    final notif   = ref.watch(notifProvider);
    final notifN  = ref.read(notifProvider.notifier);
    final lang    = ref.watch(langProvider);
    final langN   = ref.read(langProvider.notifier);
    final scheme  = Theme.of(context).colorScheme;
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
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
            // ── Account ───────────────────────────────────────────────────────
            _SectionLabel(label: 'Account'),
            authAsync.when(
              data: (session) {
                if (session == null) {
                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.login_rounded,
                            color: scheme.primary,
                          ),
                          title: const Text('Sign in'),
                          subtitle: const Text(
                            'Optional — use email and password',
                          ),
                          onTap: () => context.push('/login'),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: Icon(
                            Icons.person_add_alt_1_rounded,
                            color: scheme.secondary,
                          ),
                          title: const Text('Create account'),
                          onTap: () => context.push('/register'),
                        ),
                      ],
                    ),
                  );
                }
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: ProfileAvatar(
                          avatarId: session.user.avatar,
                          userId: session.user.id,
                          size: 48,
                        ),
                        title: const Text('Profile'),
                        subtitle: Text(
                          session.user.displayName != null &&
                                  session.user.displayName!.trim().isNotEmpty
                              ? '${session.user.displayName!}\n${session.user.email}'
                              : session.user.email,
                        ),
                        isThreeLine:
                            session.user.displayName != null &&
                            session.user.displayName!.trim().isNotEmpty,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        onTap: () => context.push('/profile'),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded),
                        title: const Text('Sign out'),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Sign out?'),
                                content: const Text(
                                  'Are you sure you want to sign out?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Sign out'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (ok != true) {
                            return;
                          }
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Signed out')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
              loading: () => Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                  title: const Text('Loading account…'),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // ── Translation Language ──────────────────────────────────────────
            _SectionLabel(label: 'Translation Language'),
            Card(
              child: Column(
                children: TranslationLang.values.map((l) {
                  return RadioListTile<TranslationLang>(
                    value: l,
                    groupValue: lang,
                    onChanged: (v) { if (v != null) langN.setLang(v); },
                    secondary: Text(
                      l == TranslationLang.fa ? '🇮🇷' : '🟢',
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(l.nativeLabel),
                    subtitle: Text(l.englishLabel),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Theme ────────────────────────────────────────────────────────
            _SectionLabel(label: 'Appearance'),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: mode,
                    onChanged: (v) { if (v != null) theme.setThemeMode(v); },
                    title: const Text('System theme'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: mode,
                    onChanged: (v) { if (v != null) theme.setThemeMode(v); },
                    title: const Text('Light mode'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: mode,
                    onChanged: (v) { if (v != null) theme.setThemeMode(v); },
                    title: const Text('Dark mode'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Notifications ─────────────────────────────────────────────────
            _SectionLabel(label: 'Daily Reminder'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Daily study reminder'),
                    subtitle: Text(
                      notif.enabled
                          ? 'Reminder set at ${notif.timeLabel}'
                          : 'Tap to enable',
                    ),
                    value: notif.enabled,
                    onChanged: (v) => notifN.setEnabled(v),
                  ),
                  if (notif.enabled) ...[
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Reminder time'),
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

            // ── About ──────────────────────────────────────────────────────────
            _SectionLabel(label: 'About'),
            _AboutCard(),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.secondaryContainer,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            children: [
              // ── App icon ──────────────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 38,
                  color: scheme.onPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // ── App name ──────────────────────────────────────────────────
              Text(
                'IELTS Words',
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
                    'By Erfan Abdi',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: scheme.outline.withOpacity(0.3)),
              const SizedBox(height: 16),

              // ── Website ───────────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'www.erfaninfo.com'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Link copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: scheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language_rounded, size: 18, color: scheme.primary),
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
