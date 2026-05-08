import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/cache/api_disk_cache.dart';
import 'core/auth/auth_provider.dart';
import 'data/models/auth_user.dart';
import 'core/locale/app_localizations_proxy_delegate.dart';
import 'core/locale/ui_locale_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/tts/tts_player_overlay.dart';
import 'features/update/forced_update_barrier.dart';
import 'features/update/optional_update_prompt.dart';
import 'domain/api_providers.dart';
import 'features/settings/theme_mode_controller.dart';
import 'features/words/important_words_controller.dart';
import 'features/words/word_preferences_controller.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiDiskCache.instance.init();
  await initNotifications();
  runApp(const ProviderScope(child: IeltsVocabApp()));
}

class IeltsVocabApp extends ConsumerWidget {
  const IeltsVocabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthSession?>>(authProvider, (previous, next) {
      final session = next.valueOrNull;
      if (session == null) return;
      if (previous?.valueOrNull?.token == session.token) return;
      final api = ref.read(apiServiceProvider);
      unawaited(() async {
        await api.bustUserVocabMarksCache();
        await ref.read(wordPreferencesProvider.notifier).pullFromServer(api);
        await ref.read(importantWordsProvider.notifier).pullFromServer(api);
      }());
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final uiLocale = ref.watch(uiLocaleProvider);
    final rtl =
        uiLocale.languageCode == 'fa' || uiLocale.languageCode == 'ckb';

    // `GlobalMaterialLocalizations` has no Sorani (`ckb`). Use Persian for
    // framework strings; [AppLocalizationsProxyDelegate] still loads app ARB for `ckb`.
    final materialLocale = uiLocale.languageCode == 'ckb'
        ? const Locale('fa')
        : uiLocale;

    return MaterialApp.router(
      title: 'Erfan Academy',
      debugShowCheckedModeBanner: false,
      locale: materialLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizationsProxyDelegate(uiLocale),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        final isDark =
            Theme.of(context).brightness == Brightness.dark;

        final overlay = SystemUiOverlayStyle(
          statusBarColor: scheme.surface,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: ForcedUpdateBarrier(
              child: OptionalUpdatePrompt(
                child: TtsPlayerOverlay(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
        );
      },
    );
  }
}
