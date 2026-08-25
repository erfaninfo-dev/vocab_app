import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Full-screen in-app PDF viewer for a grammar topic's study material.
///
/// Supports pinch-to-zoom (built into [SfPdfViewer] by default) plus an
/// explicit +/- zoom control for users who prefer tapping over pinching.
class GrammarPdfViewerScreen extends StatefulWidget {
  const GrammarPdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  final String title;
  final String pdfUrl;

  @override
  State<GrammarPdfViewerScreen> createState() =>
      _GrammarPdfViewerScreenState();
}

class _GrammarPdfViewerScreenState extends State<GrammarPdfViewerScreen> {
  static const double _minZoom = 1.0;
  static const double _maxZoom = 5.0;
  static const double _zoomStep = 0.25;

  final _pdfController = PdfViewerController();
  bool _loadFailed = false;
  bool _isReady = false;
  double _zoomLevel = _minZoom;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.pdfUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Best-effort fallback action; nothing else to do if this also fails.
    }
  }

  void _setZoom(double next) {
    final clamped = next.clamp(_minZoom, _maxZoom);
    _pdfController.zoomLevel = clamped;
    setState(() => _zoomLevel = clamped);
  }

  void _zoomIn() => _setZoom(_zoomLevel + _zoomStep);

  void _zoomOut() => _setZoom(_zoomLevel - _zoomStep);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: l10n.grammarStudyPdfOpenExternally,
            onPressed: _openExternally,
          ),
        ],
      ),
      body: _loadFailed
          ? _PdfLoadError(
              message: l10n.grammarStudyPdfOpenError,
              retryLabel: l10n.retry,
              openExternallyLabel: l10n.grammarStudyPdfOpenExternally,
              onRetry: () => setState(() => _loadFailed = false),
              onOpenExternally: _openExternally,
            )
          : Stack(
              children: [
                SfPdfViewer.network(
                  widget.pdfUrl,
                  controller: _pdfController,
                  canShowPaginationDialog: true,
                  maxZoomLevel: _maxZoom,
                  onZoomLevelChanged: (details) {
                    if (!mounted) return;
                    setState(() => _zoomLevel = details.newZoomLevel);
                  },
                  onDocumentLoadFailed: (details) {
                    if (!mounted) return;
                    setState(() => _loadFailed = true);
                  },
                  onDocumentLoaded: (details) {
                    if (!mounted) return;
                    setState(() => _isReady = true);
                  },
                ),
                if (!_isReady)
                  const Center(child: CircularProgressIndicator()),
                if (_isReady)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Center(
                      child: _ZoomControlBar(
                        zoomLevel: _zoomLevel,
                        minZoom: _minZoom,
                        maxZoom: _maxZoom,
                        onZoomIn: _zoomIn,
                        onZoomOut: _zoomOut,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ZoomControlBar extends StatelessWidget {
  const _ZoomControlBar({
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canZoomOut = zoomLevel > minZoom + 0.001;
    final canZoomIn = zoomLevel < maxZoom - 0.001;

    return Material(
      color: scheme.surface.withValues(alpha: 0.96),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_rounded),
              onPressed: canZoomOut ? onZoomOut : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(zoomLevel * 100).round()}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: canZoomIn ? onZoomIn : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfLoadError extends StatelessWidget {
  const _PdfLoadError({
    required this.message,
    required this.retryLabel,
    required this.openExternallyLabel,
    required this.onRetry,
    required this.onOpenExternally,
  });

  final String message;
  final String retryLabel;
  final String openExternallyLabel;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
                FilledButton(
                  onPressed: onOpenExternally,
                  child: Text(openExternallyLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
