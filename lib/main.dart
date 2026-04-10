import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale/app_localizations_proxy_delegate.dart';
import 'core/locale/ui_locale_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/theme_mode_controller.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const ProviderScope(child: IeltsVocabApp()));
}

class IeltsVocabApp extends ConsumerWidget {
  const IeltsVocabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      title: 'IELTS Essential Words',
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
        return Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
