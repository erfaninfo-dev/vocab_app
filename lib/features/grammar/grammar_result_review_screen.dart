import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/grammar_session_item.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

const _optKeys = ['option1', 'option2', 'option3', 'option4'];

/// Persian / Arabic script → RTL; otherwise LTR (English, etc.).
bool _questionTextIsRtl(String? text) {
  if (text == null || text.trim().isEmpty) return false;
  return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({
    required this.quizName,
    required this.score,
    required this.totalQuestions,
    required this.percent,
    required this.scheme,
  });

  final String quizName;
  final int? score;
  final int? totalQuestions;
  final int? percent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.45),
              scheme.secondaryContainer.withValues(alpha: 0.28),
              scheme.surface.withValues(alpha: 0.92),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quizName,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${score ?? '—'} / ${totalQuestions ?? '—'}',
                      style: tt.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _SessionPercentRing(percent: percent, scheme: scheme),
          ],
        ),
      ),
    );
  }
}

class _SessionPercentRing extends StatelessWidget {
  const _SessionPercentRing({
    required this.percent,
    required this.scheme,
  });

  final int? percent;
  final ColorScheme scheme;

  Color _ringColor(int p) {
    if (p >= 75) return const Color(0xFF2E7D32);
    if (p >= 45) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final p = percent;

    if (p == null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
            width: 6,
          ),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '—',
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final v = p.clamp(0, 100);
    final color = _ringColor(v);

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: v / 100.0,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.95),
              color: color,
            ),
          ),
          Text(
            '$v%',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Saved grammar attempt: question-by-question review (requires server session_json).
class GrammarResultReviewScreen extends ConsumerWidget {
  const GrammarResultReviewScreen({super.key, required this.resultId});

  final int resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(grammarResultDetailProvider(resultId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.reviewSessionTitle),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.couldNotLoadResult),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(grammarResultDetailProvider(resultId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          final r = detail.result;
          final items = detail.items;
          final pct = (r.score != null &&
                  r.totalQuestions != null &&
                  r.totalQuestions! > 0)
              ? ((r.score! / r.totalQuestions!) * 100).round()
              : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SessionSummaryCard(
                quizName: r.quizName,
                score: r.score,
                totalQuestions: r.totalQuestions,
                percent: pct,
                scheme: scheme,
              ),
              const SizedBox(height: 16),
              Text(
                'Questions',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No per-question data was stored for this attempt '
                    '(older results or server not migrated).',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                ...List.generate(items.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuestionReviewCard(
                      index: i + 1,
                      item: items[i],
                      scheme: scheme,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

enum _ReviewExplanationTab { fa, kur, eng }

_ReviewExplanationTab _initialExplanationTab(GrammarSessionItem item) {
  if ((item.faExplanation ?? '').trim().isNotEmpty) {
    return _ReviewExplanationTab.fa;
  }
  if ((item.kurExplanation ?? '').trim().isNotEmpty) {
    return _ReviewExplanationTab.kur;
  }
  return _ReviewExplanationTab.eng;
}

String _explanationText(GrammarSessionItem item, _ReviewExplanationTab tab) {
  switch (tab) {
    case _ReviewExplanationTab.fa:
      return (item.faExplanation ?? '').trim();
    case _ReviewExplanationTab.kur:
      return (item.kurExplanation ?? '').trim();
    case _ReviewExplanationTab.eng:
      return (item.engExplanation ?? '').trim();
  }
}

TextDirection _explanationDirection(_ReviewExplanationTab tab) {
  switch (tab) {
    case _ReviewExplanationTab.fa:
    case _ReviewExplanationTab.kur:
      return TextDirection.rtl;
    case _ReviewExplanationTab.eng:
      return TextDirection.ltr;
  }
}

class _QuestionReviewCard extends StatefulWidget {
  const _QuestionReviewCard({
    required this.index,
    required this.item,
    required this.scheme,
  });

  final int index;
  final GrammarSessionItem item;
  final ColorScheme scheme;

  @override
  State<_QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends State<_QuestionReviewCard> {
  late _ReviewExplanationTab _explanationTab;

  @override
  void initState() {
    super.initState();
    _explanationTab = _initialExplanationTab(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final questionText = widget.item.questionText ?? '—';
    final questionRtl = _questionTextIsRtl(questionText);
    final exp = _explanationText(widget.item, _explanationTab);
    final hasAnyExplanation = (widget.item.faExplanation ?? '').trim().isNotEmpty ||
        (widget.item.kurExplanation ?? '').trim().isNotEmpty ||
        (widget.item.engExplanation ?? '').trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: CircleAvatar(
          backgroundColor: widget.item.isCorrect
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
          foregroundColor: widget.item.isCorrect
              ? Colors.green.shade800
              : Colors.red.shade800,
          child: Icon(
            widget.item.isCorrect ? Icons.check_rounded : Icons.close_rounded,
            size: 20,
          ),
        ),
        title: Text(
          'Q${widget.index} · ${widget.item.topic}',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          widget.item.isCorrect ? 'Correct' : 'Incorrect',
          style: tt.labelMedium?.copyWith(
            color: widget.item.isCorrect
                ? Colors.green.shade700
                : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          SizedBox(
            width: double.infinity,
            child: Directionality(
              textDirection:
                  questionRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                questionText,
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._optKeys.map((k) {
            final label = widget.item.optionLabel(k) ?? '';
            if (label.isEmpty) return const SizedBox.shrink();
            final sel = (widget.item.selectedAnswer ?? '').trim().toLowerCase();
            final cor = (widget.item.correctAnswer ?? '').trim().toLowerCase();
            final kk = k.toLowerCase();
            final isCorrectOpt = kk == cor;
            final isChosen = kk == sel;
            Color? bg;
            if (isCorrectOpt) {
              bg = Colors.green.withValues(alpha: 0.15);
            } else if (isChosen && !widget.item.isCorrect) {
              bg = Colors.red.withValues(alpha: 0.12);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bg ??
                      widget.scheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: tt.bodyMedium,
                      ),
                    ),
                    if (isCorrectOpt)
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: Colors.green.shade700),
                    if (isChosen && !isCorrectOpt)
                      Icon(Icons.radio_button_checked_rounded,
                          size: 18, color: widget.scheme.primary),
                  ],
                ),
              ),
            );
          }),
          if (hasAnyExplanation) ...[
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.grammarExplanationHeading,
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<_ReviewExplanationTab>(
              segments: [
                ButtonSegment<_ReviewExplanationTab>(
                  value: _ReviewExplanationTab.fa,
                  label: Text(l10n.grammarExplanationTabFa),
                ),
                ButtonSegment<_ReviewExplanationTab>(
                  value: _ReviewExplanationTab.kur,
                  label: Text(l10n.grammarExplanationTabCkb),
                ),
                ButtonSegment<_ReviewExplanationTab>(
                  value: _ReviewExplanationTab.eng,
                  label: Text(l10n.grammarExplanationTabEn),
                ),
              ],
              selected: {_explanationTab},
              onSelectionChanged: (next) {
                setState(() => _explanationTab = next.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Directionality(
                textDirection: _explanationDirection(_explanationTab),
                child: Text(
                  exp.isEmpty ? '—' : exp,
                  textAlign: TextAlign.start,
                  style: tt.bodyMedium?.copyWith(
                    height: 1.45,
                    color: widget.scheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
