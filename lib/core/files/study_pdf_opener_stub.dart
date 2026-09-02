import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Web fallback: open the PDF URL in the browser.
Future<bool> openStudyPdf({
  required BuildContext context,
  required String pdfUrl,
  String? cacheVersion,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.tryParse(pdfUrl.trim());
  if (uri == null) {
    _showError(context, l10n.grammarStudyPdfOpenError);
    return false;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showError(context, l10n.grammarStudyPdfOpenError);
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      _showError(context, l10n.grammarStudyPdfOpenError);
    }
    return false;
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
