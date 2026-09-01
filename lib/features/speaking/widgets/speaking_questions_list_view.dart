import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tts/tts_service.dart';
import '../../../data/models/speaking_question.dart';
import '../../../l10n/app_localizations.dart';
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
    setState(() {
      _expandAll = next;
      if (_expandAll) _expandedQuestionId = null;
    });
  }

  void _toggleExpanded(int questionId) {
    setState(() {
      if (_expandAll) _expandAll = false;
      _expandedQuestionId =
          _expandedQuestionId == questionId ? null : questionId;
      widget.expandAllNotifier?.value = false;
    });
  }

  bool _isExpanded(SpeakingQuestion question) {
    if (_expandAll) return true;
    return _expandedQuestionId == question.id;
  }

  Future<void> _speakQuestion(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await ref.read(ttsProvider.notifier).speak(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = ref.watch(ttsProvider);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: widget.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = widget.questions[index];
        final displayIndex = index + 1;
        final isExpanded = _isExpanded(question);
        final isSpeaking = tts.isSpeakingText(question.questionText);

        return SpeakingQuestionCard(
          l10n: l10n,
          index: displayIndex,
          question: question,
          isExpanded: isExpanded,
          isSpeaking: isSpeaking,
          topicLabel: widget.showTopicOnCards ? question.topicTitle : null,
          onToggle: () => _toggleExpanded(question.id),
          onSpeak: () => unawaited(_speakQuestion(question.questionText)),
        );
      },
    );
  }
}
