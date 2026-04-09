import 'dart:io';

import '../../l10n/app_localizations.dart';

String userFriendlyErrorMessage(Object error, AppLocalizations l10n) {
  if (error is SocketException) {
    return l10n.errNoInternet;
  }

  if (error is FormatException) {
    return l10n.errBadData;
  }

  final text = error.toString();

  if (text.contains('HTTP ') || text.contains('Failed to fetch')) {
    return l10n.errServer;
  }

  return l10n.errorGeneric;
}
