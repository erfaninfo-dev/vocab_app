import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Result of the resume prompt: `true` = continue, `false` = start fresh,
/// `null` = user dismissed the dialog (treat as continue to avoid losing progress).
Future<bool?> showFlashcardResumeDialog({
  required BuildContext context,
  required int current,
  required int total,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        icon: const Icon(Icons.history_rounded),
        title: Text(l10n.flashcardSetupResumeTitle),
        content: Text(l10n.flashcardSetupResumeBody(current, total)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.flashcardSetupResumeFresh),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.flashcardSetupResumeContinue),
          ),
        ],
      );
    },
  );
}
