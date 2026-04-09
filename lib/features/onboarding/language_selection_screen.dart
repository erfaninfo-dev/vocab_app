import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/ui_locale_provider.dart';
import '../../core/onboarding/language_selection_prefs.dart';
import '../../core/onboarding/onboarding_prefs.dart';
import '../../l10n/app_localizations.dart';

/// First-launch UI language: English, Persian, or Kurdish (Sorani).
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _code = 'en';

  Future<void> _continue() async {
    await ref.read(uiLocaleProvider.notifier).setLocaleCode(_code);
    await setUiLanguageSelected();
    if (!mounted) return;
    final onboardingDone = await isOnboardingCompleted();
    if (!mounted) return;
    context.go(onboardingDone ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.secondary.withValues(alpha: 0.08),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.languageSelectionTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.languageSelectionSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'en',
                        groupValue: _code,
                        onChanged: (v) {
                          if (v != null) setState(() => _code = v);
                        },
                        title: Text(l10n.langEnglish),
                        secondary: const Text('EN', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const Divider(height: 0),
                      RadioListTile<String>(
                        value: 'fa',
                        groupValue: _code,
                        onChanged: (v) {
                          if (v != null) setState(() => _code = v);
                        },
                        title: Text(l10n.langPersian),
                        secondary: const Text('فا', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const Divider(height: 0),
                      RadioListTile<String>(
                        value: 'ckb',
                        groupValue: _code,
                        onChanged: (v) {
                          if (v != null) setState(() => _code = v);
                        },
                        title: Text(l10n.langKurdishSorani),
                        secondary: const Text('کو', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.continueLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
