import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_gradient_scaffold.dart';
import '../../data/models/speaking_question.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'speaking_constants.dart';
import 'widgets/speaking_question_card.dart';
import 'widgets/speaking_topic_questions_header.dart';

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

  Future<void> _onRefresh() async {
    await refreshAllRemoteApiData(ref);
    await ref.read(apiSpeakingTopicQuestionsProvider(widget.topicId).future);
  }

  void _toggleExpanded(int questionId) {
    final willExpand = _expandedQuestionId != questionId;
    final lock = willExpand ? lockSpeakingListScrollOffset(context) : null;

    setState(() {
      _expandedQuestionId =
          _expandedQuestionId == questionId ? null : questionId;
    });
    lock?.releaseAfterLayout();
  }

  bool _isExpanded(SpeakingQuestion question) =>
      _expandedQuestionId == question.id;

  PreferredSizeWidget _appBar(
    BuildContext context,
    AppLocalizations l10n,
    String title,
  ) {
    return speakingTopicQuestionsAppBar(
      context: context,
      l10n: l10n,
      title: title,
      onBack: () => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataValue = ref.watch(
      apiSpeakingTopicQuestionsProvider(widget.topicId),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: dataValue.when(
        loading: () => AppGradientScaffold(
          extendBodyBehindAppBar: false,
          appBar: _appBar(context, l10n, l10n.speakingPart1Title),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => AppGradientScaffold(
          extendBodyBehindAppBar: false,
          appBar: _appBar(context, l10n, l10n.speakingPart1Title),
          body: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Text(
                  l10n.speakingQuestionsLoadError('$error'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
            ],
          ),
        ),
        data: (data) {
          final title = data.topic.title.trim().isEmpty
              ? l10n.speakingUntitledTopic
              : data.topic.title.trim();
          final appBar = _appBar(context, l10n, title);

          if (data.questions.isEmpty) {
            return AppGradientScaffold(
              extendBodyBehindAppBar: false,
              appBar: appBar,
              body: Center(child: Text(l10n.speakingNoQuestions)),
            );
          }

          return AppGradientScaffold(
            extendBodyBehindAppBar: false,
            appBar: appBar,
            body: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: data.questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final question = data.questions[index];
                  final displayIndex = index + 1;
                  final isExpanded = _isExpanded(question);

                  return SpeakingQuestionCard(
                    l10n: l10n,
                    index: displayIndex,
                    question: question,
                    isExpanded: isExpanded,
                    accentColor: speakingQuestionAccentColor(displayIndex),
                    onToggle: () => _toggleExpanded(question.id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
