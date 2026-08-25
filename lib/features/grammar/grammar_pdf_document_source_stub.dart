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
