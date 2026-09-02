import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cache/grammar_topic_pdf_cache.dart';
import '../../l10n/app_localizations.dart';

/// Downloads the study PDF (cached after first fetch) and opens it with the
/// system app picker so the user can view it outside Erfan Academy.
Future<bool> openStudyPdf({
  required BuildContext context,
  required String pdfUrl,
  String? cacheVersion,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.grammarStudyPdfDownloading)),
          ],
        ),
      ),
    ),
  );

  try {
    final localPath = await GrammarTopicPdfCache.instance.ensureCached(
      pdfUrl: pdfUrl,
      contentVersion: cacheVersion,
    );
    if (localPath == null || localPath.isEmpty) {
      throw StateError('PDF cache unavailable');
    }

    if (context.mounted) {
      navigator.pop();
    }

    final result = await OpenFilex.open(localPath, type: 'application/pdf');
    if (result.type == ResultType.done) {
      return true;
    }

    final uri = Uri.tryParse(pdfUrl.trim());
    if (uri != null) {
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      } catch (_) {}
    }

    if (context.mounted) {
      _showError(context, l10n.grammarStudyPdfOpenError);
    }
    return false;
  } catch (_) {
    if (context.mounted && navigator.canPop()) {
      navigator.pop();
    }
    if (context.mounted) {
      _showError(context, l10n.grammarStudyPdfOpenError);
    }
    return false;
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
