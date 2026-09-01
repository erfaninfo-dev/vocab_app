import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_gradient_scaffold.dart';
import '../../data/models/speaking_question.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/speaking_question_card.dart';

class SpeakingTopicQuestionsScreen extends ConsumerStatefulWidget {
  const SpeakingTopicQuestionsScreen({super.key, required this.topicId});

  final int topicId;

  @override
  ConsumerState<SpeakingTopicQuestionsScreen> createState() =>
      _SpeakingTopicQuestionsScreenState();
}

class _SpeakingTopicQuestionsScreenState
    extends ConsumerState<SpeakingTopicQuestionsScreen> {
  int? _expandedQuestionId;
  bool _expandAll = false;

  Future<void> _onRefresh() async {
    await refreshAllRemoteApiData(ref);
    await ref.read(apiSpeakingTopicQuestionsProvider(widget.topicId).future);
  }

  void _toggleExpanded(int questionId) {
    setState(() {
      if (_expandAll) _expandAll = false;
      _expandedQuestionId =
          _expandedQuestionId == questionId ? null : questionId;
    });
  }

  void _toggleExpandAll(List<SpeakingQuestion> questions) {
    setState(() {
      _expandAll = !_expandAll;
      if (_expandAll) {
        _expandedQuestionId = null;
      }
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
    final scheme = Theme.of(context).colorScheme;
    final dataValue = ref.watch(
      apiSpeakingTopicQuestionsProvider(widget.topicId),
    );
    final tts = ref.watch(ttsProvider);

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.back,
        onPressed: () => context.pop(),
      ),
      title: dataValue.maybeWhen(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.topic.title.trim().isEmpty
                  ? l10n.speakingUntitledTopic
                  : data.topic.title.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              l10n.speakingTopicQuestionsSubtitle(data.questions.length),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        orElse: () => Text(
          l10n.speakingPart1Title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      centerTitle: false,
      actions: [
        dataValue.maybeWhen(
          data: (data) => IconButton(
            tooltip: _expandAll
                ? l10n.speakingCollapseAll
                : l10n.speakingExpandAll,
            onPressed: data.questions.isEmpty
                ? null
                : () => _toggleExpandAll(data.questions),
            icon: Icon(
              _expandAll
                  ? Icons.unfold_less_rounded
                  : Icons.unfold_more_rounded,
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(width: 4),
      ],
    );
    final topInset = appGradientContentTopInset(
      context,
      appBar: appBar,
      extra: 12,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppGradientScaffold(
        appBar: appBar,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: dataValue.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: topInset),
              children: const [
                SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: topInset),
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      l10n.speakingQuestionsLoadError('$error'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ),
              ],
            ),
            data: (data) {
              if (data.questions.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: topInset),
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text(l10n.speakingNoQuestions)),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
                itemCount: data.questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final question = data.questions[index];
                  final displayIndex = index + 1;
                  final isExpanded = _isExpanded(question);
                  final isSpeaking = tts.isSpeakingText(question.questionText);

                  return SpeakingQuestionCard(
                    l10n: l10n,
                    index: displayIndex,
                    question: question,
                    isExpanded: isExpanded,
                    isSpeaking: isSpeaking,
                    onToggle: () => _toggleExpanded(question.id),
                    onSpeak: () => unawaited(_speakQuestion(question.questionText)),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
