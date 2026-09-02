import 'package:flutter/material.dart';

import '../../core/files/study_pdf_opener.dart';
import '../../data/models/book_pdf.dart';
import 'book_pdf_picker_sheet.dart';

Future<void> openBookPdf(
  BuildContext context, {
  required BookPdf pdf,
}) {
  return openStudyPdf(
    context: context,
    pdfUrl: pdf.pdfUrl,
    cacheVersion: pdf.cacheVersion,
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
    await openBookPdf(context, pdf: pdfs.first);
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
