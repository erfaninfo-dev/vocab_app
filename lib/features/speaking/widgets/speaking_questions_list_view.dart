import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/speaking_question.dart';
import '../../../l10n/app_localizations.dart';
import '../speaking_constants.dart';
import 'speaking_question_card.dart';

class SpeakingQuestionsListView extends ConsumerStatefulWidget {
  const SpeakingQuestionsListView({
    super.key,
    required this.questions,
    required this.showTopicOnCards,
    this.padding = EdgeInsets.zero,
    this.expandAllNotifier,
  });

  final List<SpeakingQuestion> questions;
  final bool showTopicOnCards;
  final EdgeInsets padding;
  final ValueNotifier<bool>? expandAllNotifier;

  @override
  ConsumerState<SpeakingQuestionsListView> createState() =>
      _SpeakingQuestionsListViewState();
}

class _SpeakingQuestionsListViewState
    extends ConsumerState<SpeakingQuestionsListView> {
  int? _expandedQuestionId;
  bool _expandAll = false;

  @override
  void initState() {
    super.initState();
    widget.expandAllNotifier?.addListener(_onExpandAllChanged);
  }

  @override
  void didUpdateWidget(covariant SpeakingQuestionsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expandAllNotifier != widget.expandAllNotifier) {
      oldWidget.expandAllNotifier?.removeListener(_onExpandAllChanged);
      widget.expandAllNotifier?.addListener(_onExpandAllChanged);
    }
  }

  @override
  void dispose() {
    widget.expandAllNotifier?.removeListener(_onExpandAllChanged);
    super.dispose();
  }

  void _onExpandAllChanged() {
    final next = widget.expandAllNotifier?.value;
    if (next == null) return;
    final lock = next && !_expandAll
        ? lockSpeakingListScrollOffset(context)
        : null;

    setState(() {
      _expandAll = next;
      if (_expandAll) _expandedQuestionId = null;
    });
    lock?.releaseAfterLayout();
  }

  void _toggleExpanded(int questionId) {
    final willExpand = !_expandAll && _expandedQuestionId != questionId;
    final lock = willExpand ? lockSpeakingListScrollOffset(context) : null;

    setState(() {
      if (_expandAll) _expandAll = false;
      _expandedQuestionId =
          _expandedQuestionId == questionId ? null : questionId;
      widget.expandAllNotifier?.value = false;
    });
    lock?.releaseAfterLayout();
  }

  bool _isExpanded(SpeakingQuestion question) {
    if (_expandAll) return true;
    return _expandedQuestionId == question.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < widget.questions.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final question = widget.questions[index];
                final displayIndex = index + 1;
                final isExpanded = _isExpanded(question);

                return SpeakingQuestionCard(
                  l10n: l10n,
                  index: displayIndex,
                  question: question,
                  isExpanded: isExpanded,
                  accentColor: speakingQuestionAccentColor(displayIndex),
                  topicLabel:
                      widget.showTopicOnCards ? question.topicTitle : null,
                  onToggle: () => _toggleExpanded(question.id),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
