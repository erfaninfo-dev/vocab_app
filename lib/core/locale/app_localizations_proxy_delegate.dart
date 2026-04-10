import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Loads [AppLocalizations] for [appLocale] even when [MaterialApp.locale] is a
/// fallback (e.g. `fa` for framework when the user picked Sorani `ckb`).
class AppLocalizationsProxyDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  AppLocalizationsProxyDelegate(this.appLocale);

  final Locale appLocale;

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(appLocale);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(lookupAppLocalizations(appLocale));
  }

  @override
  bool shouldReload(covariant AppLocalizationsProxyDelegate old) =>
      old.appLocale != appLocale;
}
