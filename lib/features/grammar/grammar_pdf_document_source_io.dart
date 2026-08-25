import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

Widget buildGrammarPdfDocument({
  required String? localPath,
  required String pdfUrl,
  required PdfViewerController controller,
  required double maxZoomLevel,
  required PdfZoomLevelChangedCallback? onZoomLevelChanged,
  required PdfDocumentLoadFailedCallback? onDocumentLoadFailed,
  required PdfDocumentLoadedCallback? onDocumentLoaded,
}) {
  if (localPath != null && localPath.isNotEmpty) {
    return SfPdfViewer.file(
      File(localPath),
      controller: controller,
      canShowPaginationDialog: true,
      maxZoomLevel: maxZoomLevel,
      onZoomLevelChanged: onZoomLevelChanged,
      onDocumentLoadFailed: onDocumentLoadFailed,
      onDocumentLoaded: onDocumentLoaded,
    );
  }

  return SfPdfViewer.network(
    pdfUrl,
    controller: controller,
    canShowPaginationDialog: true,
    maxZoomLevel: maxZoomLevel,
    onZoomLevelChanged: onZoomLevelChanged,
    onDocumentLoadFailed: onDocumentLoadFailed,
    onDocumentLoaded: onDocumentLoaded,
  );
}
