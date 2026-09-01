import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;

import '../../l10n/app_localizations.dart';

bool isNetworkFailureError(Object error) {
  if (error is SocketException || error is ClientException) {
    return true;
  }
  return _looksLikeNetworkFailure(error.toString());
}

bool _looksLikeNetworkFailure(String text) {
  final t = text.toLowerCase();
  return text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      t.contains('connection refused') ||
      t.contains('connection timed out') ||
      t.contains('network is unreachable') ||
      text.contains('HandshakeException');
}

String userFriendlyErrorMessage(Object error, AppLocalizations l10n) {
  if (error is TimeoutException) {
    return l10n.errNoInternet;
  }

  if (error is SocketException) {
    return l10n.errNoInternet;
  }

  if (error is ClientException) {
    return l10n.errNoInternet;
  }

  if (error is FormatException) {
    return l10n.errBadData;
  }

  final text = error.toString();

  if (text.contains('Server not migrated') ||
      text.contains('vocab_quiz_results_schema')) {
    return l10n.vocabQuizHistoryLoadError;
  }

  if (_looksLikeNetworkFailure(text)) {
    return l10n.errNoInternet;
  }

  if (text.contains('is not a subtype') || text.contains('type cast')) {
    return l10n.errBadData;
  }

  // ApiService uses "HTTP {code}" when the response body is not JSON.
  if (text.contains('HTTP ')) {
    return l10n.errServerReturnedError;
  }

  if (text.startsWith('Exception: ')) {
    final detail = text.substring('Exception: '.length).trim();
    if (detail.isNotEmpty &&
        !detail.contains('HTTP ') &&
        detail != 'Create code failed') {
      return detail;
    }
  }

  if (text.contains('Failed to fetch')) {
    return l10n.errServer;
  }

  final cleaned = text.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
  if (cleaned.isNotEmpty && cleaned.length < 180) {
    return cleaned;
  }

  return l10n.errorGeneric;
}
