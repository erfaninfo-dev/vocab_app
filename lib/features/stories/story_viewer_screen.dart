import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/admin_story.dart';
import '../../data/services/api_service.dart';
import '../../domain/api_providers.dart';
import 'story_poll_sticker.dart';
import 'story_providers.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, this.initialStoryId});

  final int? initialStoryId;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  var _index = 0;
  var _markedStoryId = -1;
  var _initialStoryApplied = false;
  int? _votingPollId;
  String? _votingOptionId;

  @override
  void initState() {
    super.initState();
    _progress =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _next();
          });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markCurrentViewed();
      _progress.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  List<StoryItem> get _stories =>
      ref.read(visibleStoriesProvider).valueOrNull ?? const [];

  void _applyInitialStoryIndex(List<StoryItem> stories) {
    if (_initialStoryApplied) return;
    _initialStoryApplied = true;
    final initialStoryId = widget.initialStoryId;
    final requestedIndex = initialStoryId == null
        ? -1
        : stories.indexWhere((story) => story.id == initialStoryId);
    final firstUnseenIndex = stories.indexWhere((story) => !story.seen);
    final targetIndex = requestedIndex >= 0
        ? requestedIndex
        : firstUnseenIndex >= 0
        ? firstUnseenIndex
        : 0;
    _index = targetIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _markedStoryId = -1;
      _markCurrentViewed();
      _progress.forward(from: 0);
    });
  }

  void _markCurrentViewed() {
    final stories = _stories;
    if (!mounted || stories.isEmpty || _index >= stories.length) return;
    final story = stories[_index];
    if (_markedStoryId == story.id) return;
    _markedStoryId = story.id;
    unawaited(ref.read(visibleStoriesProvider.notifier).markViewed(story.id));
  }

  void _next() {
    final stories = _stories;
    if (stories.isEmpty) return;
    if (_index >= stories.length - 1) {
      context.pop();
      return;
    }
    setState(() => _index++);
    _markCurrentViewed();
    _progress.forward(from: 0);
  }

  void _previous() {
    if (_index <= 0) {
      _progress.forward(from: 0);
      return;
    }
    setState(() => _index--);
    _markCurrentViewed();
    _progress.forward(from: 0);
  }

  Future<void> _toggleLike(StoryItem story) async {
    await ref
        .read(visibleStoriesProvider.notifier)
        .setLiked(story, !story.liked);
  }

  Future<void> _votePoll(
    StoryItem story,
    StoryPoll poll,
    String optionId,
  ) async {
    if (poll.hasVoted || _votingPollId != null) return;
    _pauseProgress();
    setState(() {
      _votingPollId = poll.id;
      _votingOptionId = optionId;
    });
    try {
      await ref
          .read(visibleStoriesProvider.notifier)
          .votePoll(story: story, poll: poll, optionId: optionId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _votingPollId = null;
          _votingOptionId = null;
        });
        _resumeProgress();
      }
    }
  }

  void _pauseProgress() {
    if (_progress.isAnimating) _progress.stop();
  }

  void _resumeProgress() {
    if (!_progress.isCompleted && !_progress.isAnimating) {
      _progress.forward();
    }
  }

  void _showAudience(StoryItem story) {
    _pauseProgress();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StoryAudienceSheet(story: story),
    ).whenComplete(() {
      if (mounted) _resumeProgress();
    });
  }

  Future<void> _requestDeleteStory(StoryItem story) async {
    _pauseProgress();
    final confirmed = await _confirmDeleteStory();
    if (!mounted) return;
    if (confirmed) {
      await _deleteStory(story);
      return;
    }
    _resumeProgress();
  }

  Future<bool> _confirmDeleteStory() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Delete story?',
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w900),
          ),
          content: const Text('Do you want to delete this story?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _deleteStory(StoryItem story) async {
    try {
      await ref.read(apiServiceProvider).deleteAdminStory(story.id);
      ref.invalidate(adminStoriesProvider);
      await ref.read(visibleStoriesProvider.notifier).refresh();
      if (!mounted) return;
      final stories = _stories;
      if (stories.isEmpty) {
        context.pop();
        return;
      }
      if (_index >= stories.length) {
        setState(() => _index = stories.length - 1);
      }
      _markedStoryId = -1;
      _markCurrentViewed();
      _progress.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete story: $e')));
      _resumeProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(visibleStoriesProvider);
    final session = ref.watch(authProvider).valueOrNull;
    return Scaffold(
      backgroundColor: Colors.black,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _StoryError(onClose: () => context.pop()),
        data: (stories) {
          if (stories.isEmpty) return _StoryError(onClose: () => context.pop());
          _applyInitialStoryIndex(stories);
          if (_index >= stories.length) _index = stories.length - 1;
          final story = stories[_index];
          final isOwnAdminStory =
              session?.user.isAdmin == true &&
              session?.user.id == story.adminUserId;
          return GestureDetector(
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 260) {
                context.pop();
              } else if (velocity < -260 && isOwnAdminStory) {
                _showAudience(story);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _StoryBody(story: story),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) => _pauseProgress(),
                        onTapUp: (_) => _resumeProgress(),
                        onTapCancel: _resumeProgress,
                        onTap: _previous,
                        onLongPressStart: (_) => _pauseProgress(),
                        onLongPressEnd: (_) => _resumeProgress(),
                        onLongPressCancel: _resumeProgress,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) => _pauseProgress(),
                        onTapUp: (_) => _resumeProgress(),
                        onTapCancel: _resumeProgress,
                        onTap: _next,
                        onLongPressStart: (_) => _pauseProgress(),
                        onLongPressEnd: (_) => _resumeProgress(),
                        onLongPressCancel: _resumeProgress,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
                if (story.textStyle.poll != null)
                  _ViewerPollOverlay(
                    story: story,
                    poll: story.textStyle.poll!,
                    isOwnAdminStory: isOwnAdminStory,
                    votingPollId: _votingPollId,
                    votingOptionId: _votingOptionId,
                    onVote: (optionId) =>
                        _votePoll(story, story.textStyle.poll!, optionId),
                  ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                        child: _ProgressBars(
                          count: stories.length,
                          index: _index,
                          progress: _progress,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
                        child: _StoryHeader(
                          story: story,
                          onClose: () => context.pop(),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        child: Row(
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: story.liked
                                    ? const Color(0xFFFF2D55)
                                    : Colors.white,
                              ),
                              onPressed: () => _toggleLike(story),
                              icon: Icon(
                                story.liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                              ),
                            ),
                            if (isOwnAdminStory)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _showAudience(story),
                                  icon: const Icon(Icons.visibility_rounded),
                                ),
                              ),
                            const Spacer(),
                            if (isOwnAdminStory)
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: const Color(0xFFFF453A),
                                ),
                                onPressed: () => _requestDeleteStory(story),
                                icon: const Icon(Icons.delete_rounded),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.story});

  final StoryItem story;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layers = story.textStyle.layers;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (story.isImage && (story.imagePath ?? '').isNotEmpty)
              _StoryImage(
                imagePath: story.imagePath!,
                transform: story.textStyle.imageTransform,
              )
            else
              _StoryTextBackground(style: story.textStyle),
            if (layers.isNotEmpty)
              for (final layer in layers)
                _StoryLayerView(layer: layer, canvasSize: size)
            else if ((story.textContent ?? '').trim().isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _LegacyStoryText(story: story),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ViewerPollOverlay extends StatelessWidget {
  const _ViewerPollOverlay({
    required this.story,
    required this.poll,
    required this.isOwnAdminStory,
    required this.votingPollId,
    required this.votingOptionId,
    required this.onVote,
  });

  final StoryItem story;
  final StoryPoll poll;
  final bool isOwnAdminStory;
  final int? votingPollId;
  final String? votingOptionId;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = poll.usesCompactTwoOptionLayout ? 340.0 : 300.0;
          final height = poll.usesCompactTwoOptionLayout ? 180.0 : 260.0;
          final showResults =
              poll.hasVoted || isOwnAdminStory || poll.totalVotes > 0;
          return Stack(
            children: [
              Positioned(
                left: (poll.x * constraints.maxWidth) - width / 2,
                top: (poll.y * constraints.maxHeight) - height / 2,
                width: width,
                height: height,
                child: Center(
                  child: Transform.scale(
                    scale: poll.scale,
                    child: StoryPollSticker(
                      poll: poll,
                      showResults: showResults,
                      votingOptionId: votingPollId == poll.id
                          ? votingOptionId
                          : null,
                      onVote: showResults ? null : onVote,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.imagePath, required this.transform});

  final String imagePath;
  final StoryImageTransform transform;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform.translate(
          offset: Offset(
            transform.x * constraints.maxWidth,
            transform.y * constraints.maxHeight,
          ),
          child: Transform.scale(
            scale: transform.scale,
            child: Image.network(
              apiAbsoluteMediaUrl(imagePath),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF111111),
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoryTextBackground extends StatelessWidget {
  const _StoryTextBackground({required this.style});

  final StoryTextStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(style.backgroundStart), Color(style.backgroundEnd)],
        ),
      ),
    );
  }
}

class _StoryLayerView extends StatelessWidget {
  const _StoryLayerView({required this.layer, required this.canvasSize});

  final StoryTextLayer layer;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    final width = canvasSize.width * 0.82;
    const height = 180.0;
    return Positioned(
      left: layer.x * canvasSize.width - width / 2,
      top: layer.y * canvasSize.height - height / 2,
      width: width,
      height: height,
      child: Center(child: _LayerText(layer: layer)),
    );
  }
}

class _LayerText extends StatelessWidget {
  const _LayerText({required this.layer});

  final StoryTextLayer layer;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: layer.rotation,
      child: Transform.scale(
        scale: layer.scale,
        child: Text(
          layer.text,
          textAlign: _textAlign(layer.alignment),
          style: TextStyle(
            color: Color(layer.textColor),
            fontSize: layer.fontSize,
            fontFamily: layer.fontFamily == 'Default' ? null : layer.fontFamily,
            height: 1.12,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyStoryText extends StatelessWidget {
  const _LegacyStoryText({required this.story});

  final StoryItem story;

  @override
  Widget build(BuildContext context) {
    final style = story.textStyle;
    return Text(
      (story.textContent ?? '').trim(),
      textAlign: _textAlign(style.alignment),
      style: TextStyle(
        color: Color(style.textColor),
        fontSize: style.fontSize,
        fontFamily: style.fontFamily == 'Default' ? null : style.fontFamily,
        height: 1.18,
        fontWeight: FontWeight.w800,
        shadows: const [
          Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

TextAlign _textAlign(String alignment) {
  return switch (alignment) {
    'left' => TextAlign.left,
    'right' => TextAlign.right,
    _ => TextAlign.center,
  };
}

class _StoryAudienceSheet extends ConsumerWidget {
  const _StoryAudienceSheet({required this.story});

  final StoryItem story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(storyAudienceProvider(story.id));
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.38,
      maxChildSize: 0.84,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Could not load audience')),
            data: (summary) {
              final likedUserIds = summary.likers.map((u) => u.id).toSet();
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${summary.viewCount} views',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF2D55),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${summary.likeCount}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (summary.poll != null)
                    _AudiencePollSummary(poll: summary.poll!),
                  Expanded(
                    child: summary.viewers.isEmpty
                        ? const Center(child: Text('No views yet'))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                            itemCount: summary.viewers.length,
                            itemBuilder: (context, i) {
                              final user = summary.viewers[i];
                              return ListTile(
                                dense: true,
                                leading: _AudienceAvatar(
                                  user: user,
                                  liked: likedUserIds.contains(user.id),
                                ),
                                title: Text(
                                  user.displayLabel,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(fontSize: 14),
                                ),
                                subtitle: user.pollOptionText == null
                                    ? null
                                    : Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: _VotedOptionChip(
                                          label: user.pollOptionText!,
                                        ),
                                      ),
                                trailing: Text(
                                  _formatWhen(user.happenedAt),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AudiencePollSummary extends StatelessWidget {
  const _AudiencePollSummary({required this.poll});

  final StoryPoll poll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < poll.options.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${poll.options[i].voteCount}',
                    style: TextStyle(
                      color: i == 0
                          ? const Color(0xFF00B8C8)
                          : const Color(0xFFFF4E67),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'votes for ${poll.options[i].text}',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            if (i != poll.options.length - 1)
              SizedBox(
                height: 34,
                child: VerticalDivider(color: scheme.outlineVariant),
              ),
          ],
        ],
      ),
    );
  }
}

class _VotedOptionChip extends StatelessWidget {
  const _VotedOptionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'voted $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF3F51B5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AudienceAvatar extends StatelessWidget {
  const _AudienceAvatar({required this.user, required this.liked});

  final StoryAudienceUser user;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfileAvatar(avatarId: user.avatar, userId: user.id, size: 44),
        if (liked)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFFF2D55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 3,
                color: Colors.white30,
                child: i == index
                    ? AnimatedBuilder(
                        animation: progress,
                        builder: (_, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.value,
                          child: const ColoredBox(color: Colors.white),
                        ),
                      )
                    : FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: i < index ? 1 : 0,
                        child: const ColoredBox(color: Colors.white),
                      ),
              ),
            ),
          ),
          if (i != count - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({required this.story, required this.onClose});

  final StoryItem story;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(
          avatarId: story.adminAvatar,
          userId: story.adminUserId,
          size: 38,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.adminName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _relativeStoryTime(story.createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _StoryError extends StatelessWidget {
  const _StoryError({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_outlined, color: Colors.white54),
            const SizedBox(height: 12),
            const Text('No stories', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

String _relativeStoryTime(String raw) {
  final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized)?.toLocal();
  if (dt == null) return raw;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

String _formatWhen(String raw) {
  final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized)?.toLocal();
  if (dt == null) return raw;
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.month}/${dt.day} ${dt.hour}:$m';
}
