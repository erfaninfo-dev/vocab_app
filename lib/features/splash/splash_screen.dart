import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/onboarding/language_selection_prefs.dart';
import '../../core/onboarding/onboarding_prefs.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      const Duration(milliseconds: 80),
      () => mounted ? setState(() => _visible = true) : null,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_prefetchBooksList());
    });
    unawaited(_goNext());
  }

  /// Warm [apiSearchBooksProvider] so Home often shows data immediately.
  Future<void> _prefetchBooksList() async {
    try {
      await ref.read(apiSearchBooksProvider.future);
    } catch (_) {
      if (!mounted) return;
      ref.invalidate(apiSearchBooksProvider);
    }
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    final langSelected = await isUiLanguageSelected();
    if (!mounted) return;
    if (!langSelected) {
      context.go('/language');
      return;
    }
    final onboardingDone = await isOnboardingCompleted();
    if (!mounted) return;
    context.go(onboardingDone ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withOpacity(0.16),
              scheme.secondary.withOpacity(0.1),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 520),
            opacity: _visible ? 1 : 0.35,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 520),
              offset: _visible ? Offset.zero : const Offset(0, 0.08),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withOpacity(0.9),
                          scheme.tertiary.withOpacity(0.78),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.28),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.splashTagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
