import 'package:flutter/material.dart';

import '../../data/models/admin_story.dart';

class StoryPollSticker extends StatelessWidget {
  const StoryPollSticker({
    super.key,
    required this.poll,
    required this.showResults,
    this.votingOptionId,
    this.onVote,
    this.onTap,
    this.compact = false,
  });

  final StoryPoll poll;
  final bool showResults;
  final String? votingOptionId;
  final ValueChanged<String>? onVote;
  final VoidCallback? onTap;
  final bool compact;

  bool get _canVote => onVote != null && !showResults;

  @override
  Widget build(BuildContext context) {
    final child = poll.usesCompactTwoOptionLayout
        ? _TwoOptionPoll(
            poll: poll,
            showResults: showResults,
            votingOptionId: votingOptionId,
            onVote: _canVote ? onVote : null,
            compact: compact,
          )
        : _MultiOptionPoll(
            poll: poll,
            showResults: showResults,
            votingOptionId: votingOptionId,
            onVote: _canVote ? onVote : null,
            compact: compact,
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _TwoOptionPoll extends StatelessWidget {
  const _TwoOptionPoll({
    required this.poll,
    required this.showResults,
    required this.votingOptionId,
    required this.onVote,
    required this.compact,
  });

  final StoryPoll poll;
  final bool showResults;
  final String? votingOptionId;
  final ValueChanged<String>? onVote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 286.0 : 300.0;
    final question = poll.question.trim();
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (question.isNotEmpty) ...[
            Text(
              question,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 36,
                height: 1.12,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: showResults
                  ? _TwoOptionResultBar(poll: poll, compact: compact)
                  : Row(
                      children: [
                        for (var i = 0; i < poll.options.length; i++) ...[
                          Expanded(
                            child: _PollOptionCell(
                              option: poll.options[i],
                              selected:
                                  poll.selectedOptionId == poll.options[i].id,
                              showResults: false,
                              voting: votingOptionId == poll.options[i].id,
                              horizontal: true,
                              optionColor: i == 0
                                  ? const Color(0xFF00B8C8)
                                  : const Color(0xFFFF4E67),
                              onTap: onVote == null
                                  ? null
                                  : () => onVote!(poll.options[i].id),
                            ),
                          ),
                          if (i == 0)
                            Container(
                              width: 1,
                              height: compact ? 78 : 82,
                              color: const Color(0xFFD1D1D8),
                            ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoOptionResultBar extends StatelessWidget {
  const _TwoOptionResultBar({required this.poll, required this.compact});

  final StoryPoll poll;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final first = poll.options[0];
    final second = poll.options[1];
    final firstFlex = first.percent > 0 ? first.percent.round() : 50;
    final secondFlex = second.percent > 0 ? second.percent.round() : 50;
    return SizedBox(
      height: compact ? 78 : 82,
      child: Row(
        children: [
          Expanded(
            flex: firstFlex.clamp(12, 88),
            child: _TwoOptionResultSegment(
              option: first,
              color: const Color(0xFF00B8C8),
              selected: poll.selectedOptionId == first.id,
              alignRight: false,
            ),
          ),
          Container(width: 1, color: const Color(0xFFD1D1D8)),
          Expanded(
            flex: secondFlex.clamp(12, 88),
            child: _TwoOptionResultSegment(
              option: second,
              color: const Color(0xFFFF4E67),
              selected: poll.selectedOptionId == second.id,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoOptionResultSegment extends StatelessWidget {
  const _TwoOptionResultSegment({
    required this.option,
    required this.color,
    required this.selected,
    required this.alignRight,
  });

  final StoryPollOption option;
  final Color color;
  final bool selected;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.16 : 0.09),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: selected ? 0.24 : 0.13),
            blurRadius: selected ? 14 : 8,
            spreadRadius: selected ? 1 : 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: alignRight ? 6 : 10,
          end: alignRight ? 10 : 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              option.text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${option.percent.round()}%',
              maxLines: 1,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.9),
                fontWeight: FontWeight.w900,
                fontSize: 25,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiOptionPoll extends StatelessWidget {
  const _MultiOptionPoll({
    required this.poll,
    required this.showResults,
    required this.votingOptionId,
    required this.onVote,
    required this.compact,
  });

  final StoryPoll poll;
  final bool showResults;
  final String? votingOptionId;
  final ValueChanged<String>? onVote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 246.0 : 296.0;
    final question = poll.question.trim();
    final likelyTwoLineQuestion =
        question.length > 28 || question.contains('\n');
    final dense = compact || poll.options.length >= 4;
    final optionHeight = dense ? 34.0 : 42.0;
    final optionGap = dense ? 4.0 : 6.0;
    final headerHeight = dense
        ? (likelyTwoLineQuestion ? 62.0 : 54.0)
        : (likelyTwoLineQuestion ? 72.0 : 63.0);
    return Container(
      width: width,
      padding: EdgeInsets.only(
        top: question.isEmpty ? (dense ? 6 : 8) : 0,
        bottom: dense ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (question.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: dense ? 6 : 8),
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF111116),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                  bottom: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  question.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11 : 12,
                    height: 1.12,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          for (final option in poll.options)
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, optionGap),
              child: _PollOptionCell(
                option: option,
                selected: poll.selectedOptionId == option.id,
                showResults: showResults,
                voting: votingOptionId == option.id,
                horizontal: false,
                height: optionHeight,
                onTap: onVote == null ? null : () => onVote!(option.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _PollOptionCell extends StatelessWidget {
  const _PollOptionCell({
    required this.option,
    required this.selected,
    required this.showResults,
    required this.voting,
    required this.horizontal,
    this.height,
    this.optionColor,
    required this.onTap,
  });

  final StoryPollOption option;
  final bool selected;
  final bool showResults;
  final bool voting;
  final bool horizontal;
  final double? height;
  final Color? optionColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = option.percent.clamp(0, 100) / 100;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: voting ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: horizontal ? 78 : height ?? 42,
          decoration: BoxDecoration(
            color: horizontal ? Colors.transparent : const Color(0xFFF1F1F5),
            borderRadius: BorderRadius.circular(horizontal ? 0 : 12),
            border: selected
                ? Border.all(color: const Color(0xFF2196F3), width: 1.8)
                : null,
          ),
          child: Stack(
            children: [
              if (showResults)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(horizontal ? 0 : 12),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        widthFactor: percent,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: selected
                                  ? const [Color(0xFF2196F3), Color(0xFF42A5F5)]
                                  : const [
                                      Color(0xFFE7E7EF),
                                      Color(0xFFDADAE6),
                                    ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (showResults && !horizontal) ...[
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        if (selected) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            option.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : optionColor ?? const Color(0xFF30313A),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${option.percent.round()}%',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal ? 8 : 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: horizontal
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          option.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: horizontal
                              ? TextAlign.center
                              : TextAlign.start,
                          style: TextStyle(
                            color: optionColor ?? const Color(0xFF30313A),
                            fontWeight: FontWeight.w900,
                            fontSize: horizontal ? 42 : 12,
                            letterSpacing: horizontal ? 0.5 : 0,
                          ),
                        ),
                      ),
                      if (voting) ...[
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
