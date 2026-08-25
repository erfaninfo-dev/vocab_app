import 'package:flutter/material.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../data/models/grammar_topic_pdf.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet listing multiple study PDFs for one grammar topic.
class GrammarTopicPdfPickerSheet extends StatelessWidget {
  const GrammarTopicPdfPickerSheet({
    super.key,
    required this.topic,
    required this.pdfs,
    required this.accent,
    required this.onPdfSelected,
  });

  final String topic;
  final List<GrammarTopicPdf> pdfs;
  final Color accent;
  final ValueChanged<GrammarTopicPdf> onPdfSelected;

  static Future<void> show({
    required BuildContext context,
    required String topic,
    required List<GrammarTopicPdf> pdfs,
    required Color accent,
    required ValueChanged<GrammarTopicPdf> onPdfSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => GrammarTopicPdfPickerSheet(
        topic: topic,
        pdfs: pdfs,
        accent: accent,
        onPdfSelected: onPdfSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.grammarStudyPdfPickerTitle(topic),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.grammarStudyPdfPickerSubtitle(pdfs.length),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pdfs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pdf = pdfs[index];
                final order = pdf.sortOrder > 0 ? pdf.sortOrder : index + 1;
                final title = pdf.displayTitle(
                  fallbackPrefix: l10n.grammarStudyPdfPartLabel,
                );
                return _GrammarTopicPdfPickerCard(
                  order: order,
                  title: title,
                  accent: accent,
                  viewLabel: l10n.grammarStudyPdfView,
                  onView: () {
                    Navigator.of(context).pop();
                    onPdfSelected(pdf);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarTopicPdfPickerCard extends StatelessWidget {
  const _GrammarTopicPdfPickerCard({
    required this.order,
    required this.title,
    required this.accent,
    required this.viewLabel,
    required this.onView,
  });

  final int order;
  final String title;
  final Color accent;
  final String viewLabel;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppJellyCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.92),
                  accent.withValues(alpha: 0.62),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$order',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: Text(viewLabel),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: scheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
