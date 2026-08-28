import 'package:flutter/material.dart';

import '../../data/models/book_pdf.dart';
import '../../l10n/app_localizations.dart';
import '../grammar/grammar_pdf_viewer_screen.dart';
import 'book_pdf_picker_sheet.dart';

void openBookPdf(
  BuildContext context, {
  required BookPdf pdf,
}) {
  final l10n = AppLocalizations.of(context)!;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GrammarPdfViewerScreen(
        title: pdf.displayTitle(
          fallbackPrefix: l10n.bookStudyPdfPartLabel,
        ),
        pdfUrl: pdf.pdfUrl,
        cacheVersion: pdf.cacheVersion,
      ),
    ),
  );
}

Future<void> openBookStudyPdfs({
  required BuildContext context,
  required String bookTitle,
  required List<BookPdf> pdfs,
  required Color accent,
}) async {
  if (pdfs.isEmpty) return;

  if (pdfs.length == 1) {
    openBookPdf(context, pdf: pdfs.first);
    return;
  }

  await BookPdfPickerSheet.show(
    context: context,
    bookTitle: bookTitle,
    pdfs: pdfs,
    accent: accent,
    onPdfSelected: (pdf) => openBookPdf(context, pdf: pdf),
  );
}
