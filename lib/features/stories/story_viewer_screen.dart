import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/admin_story.dart';
import '../../data/services/api_service.dart';
import '../../domain/api_providers.dart';
import 'story_fonts.dart';
import 'story_poll_sticker.dart';
import 'story_providers.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    this.initialStoryId,
    this.grammarOnly = false,
  });

  final int? initialStoryId;
  final bool grammarOnly;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  var _index = 0;
  var _markedStoryId = -1;
  var _initialStoryApplied = false;
  final _loadedImageStoryIds = <int>{};
  final _imageLoadProgressByStoryId = <int, double>{};
  var _sendingReply = false;
  var _replyComposerActive = false;
  int? _votingPollId;
  String? _votingOptionId;
  int? _answeringGrammarGameId;
  String? _answeringGrammarOptionId;

  @override
  void initState() {
    super.initState();
    _progress =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _next();
          });
    _replyFocusNode.addListener(_handleReplyFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markCurrentViewed();
    });
  }

  @override
  void dispose() {
    _replyFocusNode.removeListener(_handleReplyFocusChanged);
    _replyController.dispose();
    _replyFocusNode.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _handleReplyFocusChanged() {
    if (_replyFocusNode.hasFocus) {
      _activateReplyComposer();
    } else {
      _replyComposerActive = false;
      _resumeProgress();
    }
  }

  void _activateReplyComposer() {
    _replyComposerActive = true;
    _pauseProgress();
  }

  bool _dismissReplyComposerIfOpen() {
    if (!_replyComposerActive && !_replyFocusNode.hasFocus) return false;
    _replyComposerActive = false;
    _replyFocusNode.unfocus();
    _resumeProgress();
    return true;
  }

  List<StoryItem> _filterStories(List<StoryItem> stories) {
    return stories.where((story) {
      return widget.grammarOnly ? story.hasGrammarGame : !story.hasGrammarGame;
    }).toList();
  }

  bool get _unseenOnlyPlayback {
    if (widget.grammarOnly || widget.initialStoryId != null) return false;
    final session = ref.read(authProvider).valueOrNull;
    if (session?.user.isAdmin == true) return false;
    return true;
  }

  List<StoryItem> _playbackStoriesFrom(List<StoryItem> stories) {
    final filtered = _filterStories(stories);
    if (!_unseenOnlyPlayback) return filtered;
    return filtered.where((story) => !story.seen).toList(growable: false);
  }

  List<StoryItem> get _stories {
    final stories = ref.read(visibleStoriesProvider).valueOrNull ?? const [];
    return _playbackStoriesFrom(stories);
  }

  void _applyInitialStoryIndex(List<StoryItem> stories) {
    if (_initialStoryApplied) return;
    _initialStoryApplied = true;
    if (stories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return;
    }
    final initialStoryId = widget.initialStoryId;
    final requestedIndex = initialStoryId == null
        ? -1
        : stories.indexWhere((story) => story.id == initialStoryId);
    final firstUnseenIndex = stories.indexWhere((story) => !story.seen);
    final targetIndex = requestedIndex >= 0
        ? requestedIndex
        : _unseenOnlyPlayback
        ? 0
        : firstUnseenIndex >= 0
        ? firstUnseenIndex
        : 0;
    _index = targetIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final playback = _stories;
      if (playback.isEmpty) {
        context.pop();
        return;
      }
      if (_index >= playback.length) _index = playback.length - 1;
      _markedStoryId = -1;
      _markCurrentViewed();
      _startStoryProgress(playback[_index]);
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
    if (_dismissReplyComposerIfOpen()) return;
    final stories = _stories;
    if (stories.isEmpty) return;
    if (_index >= stories.length - 1) {
      context.pop();
      return;
    }
    _replyController.clear();
    _replyComposerActive = false;
    _replyFocusNode.unfocus();
    setState(() => _index++);
    _markCurrentViewed();
    _startStoryProgress(stories[_index]);
  }

  void _previous() {
    if (_dismissReplyComposerIfOpen()) return;
    final stories = _stories;
    if (stories.isEmpty) return;
    if (_index <= 0) {
      final story = _currentStoryOrNull();
      if (story != null) _startStoryProgress(story);
      return;
    }
    _replyController.clear();
    _replyComposerActive = false;
    _replyFocusNode.unfocus();
    setState(() => _index--);
    _markCurrentViewed();
    _startStoryProgress(stories[_index]);
  }

  Future<void> _toggleLike(StoryItem story) async {
    await ref
        .read(visibleStoriesProvider.notifier)
        .setLiked(story, !story.liked);
  }

  Future<void> _sendStoryReply(StoryItem story) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply || story.adminUserId < 1) return;
    final myId = ref.read(authProvider).valueOrNull?.user.id;
    final savedMessages = myId != null && myId == story.adminUserId;
    setState(() => _sendingReply = true);
    _pauseProgress();
    try {
      await ref
          .read(apiServiceProvider)
          .sendTeacherMessage(
            text,
            peerTeacherId: savedMessages ? null : story.adminUserId,
            storyReplyStoryId: story.id,
            savedMessages: savedMessages,
          );
      _replyController.clear();
      _replyFocusNode.unfocus();
      ref.invalidate(teacherMessagesPreviewProvider);
      ref.invalidate(teacherMessagesUnreadFabProvider);
      ref.invalidate(teacherInboxStudentsProvider);
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
        setState(() => _sendingReply = false);
        if (!story.hasGrammarGame) _resumeProgress();
      }
    }
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

  Future<void> _answerGrammarGame(
    StoryItem story,
    StoryGrammarGame game,
    String optionId,
  ) async {
    if (game.hasAnswered || _answeringGrammarGameId != null) return;
    _pauseProgress();
    setState(() {
      _answeringGrammarGameId = game.id;
      _answeringGrammarOptionId = optionId;
    });
    try {
      await ref
          .read(visibleStoriesProvider.notifier)
          .answerGrammarGame(story: story, game: game, optionId: optionId);
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
          _answeringGrammarGameId = null;
          _answeringGrammarOptionId = null;
        });
        _pauseProgress();
      }
    }
  }

  void _syncProgressForStory(StoryItem story, {required bool imageReady}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_shouldKeepProgressPaused(story: story, imageReady: imageReady)) {
        _progress.stop();
      } else if (!_progress.isAnimating && !_progress.isCompleted) {
        _progress.forward();
      }
    });
  }

  bool _storyHasLoadableImage(StoryItem story) {
    return (story.imagePath ?? '').trim().isNotEmpty;
  }

  bool _storyExpectsImage(StoryItem story) {
    return story.isImage || _storyHasLoadableImage(story);
  }

  bool _isStoryImageReady(StoryItem story) {
    if (!_storyExpectsImage(story)) return true;
    if (!_storyHasLoadableImage(story)) return false;
    return _loadedImageStoryIds.contains(story.id);
  }

  void _setStoryImageLoadProgress(StoryItem story, double? progress) {
    if (!_storyHasLoadableImage(story) ||
        _loadedImageStoryIds.contains(story.id)) {
      return;
    }
    final normalized = progress?.clamp(0.0, 1.0).toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedImageStoryIds.contains(story.id)) return;
      final previous = _imageLoadProgressByStoryId[story.id];
      if (previous == normalized) return;
      if (previous != null &&
          normalized != null &&
          (previous - normalized).abs() < 0.01) {
        return;
      }
      setState(() {
        if (normalized == null) {
          _imageLoadProgressByStoryId.remove(story.id);
        } else {
          _imageLoadProgressByStoryId[story.id] = normalized;
        }
      });
    });
  }

  void _completeStoryImageLoad(StoryItem story) {
    if (!_storyHasLoadableImage(story) ||
        _loadedImageStoryIds.contains(story.id)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedImageStoryIds.contains(story.id)) return;
      setState(() {
        _loadedImageStoryIds.add(story.id);
        _imageLoadProgressByStoryId[story.id] = 1;
      });
      _resumeProgress();
    });
  }

  void _startStoryProgress(StoryItem story) {
    _progress.forward(from: 0);
    if (!_isStoryImageReady(story)) _progress.stop();
  }

  void _pauseProgress() {
    if (_progress.isAnimating) _progress.stop();
  }

  void _resumeProgress() {
    if (_shouldKeepProgressPaused()) return;
    if (!_progress.isCompleted && !_progress.isAnimating) {
      _progress.forward();
    }
  }

  bool _shouldKeepProgressPaused({StoryItem? story, bool? imageReady}) {
    if (_replyComposerActive || _replyFocusNode.hasFocus || _sendingReply) {
      return true;
    }
    if (_votingPollId != null || _answeringGrammarGameId != null) return true;
    final currentStory = story ?? _currentStoryOrNull();
    if (currentStory == null) return false;
    if (currentStory.hasGrammarGame) return true;
    return !(imageReady ?? _isStoryImageReady(currentStory));
  }

  StoryItem? _currentStoryOrNull() {
    final stories = _stories;
    if (stories.isEmpty || _index < 0 || _index >= stories.length) return null;
    return stories[_index];
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
      _startStoryProgress(stories[_index]);
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
        data: (allStories) {
          final stories = _playbackStoriesFrom(allStories);
          if (stories.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.pop();
            });
            return const SizedBox.shrink();
          }
          _applyInitialStoryIndex(stories);
          if (_index >= stories.length) _index = stories.length - 1;
          final story = stories[_index];
          final isOwnAdminStory =
              session?.user.isAdmin == true &&
              session?.user.id == story.adminUserId;
          final imageReady = _isStoryImageReady(story);
          final expectsImage = _storyExpectsImage(story);
          final isOwnStory =
              session != null && session.user.id == story.adminUserId;
          final canReply =
              session != null &&
              story.adminUserId > 0 &&
              (!session.user.isTeacher && !session.user.isAdmin || isOwnStory);
          _syncProgressForStory(story, imageReady: imageReady);
          final replyPanelHeight = 70.0 + MediaQuery.paddingOf(context).bottom;
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
                Positioned.fill(
                  bottom: replyPanelHeight,
                  child: _StoryBody(
                    story: story,
                    imageReady: imageReady,
                    imageLoadProgress: _imageLoadProgressByStoryId[story.id],
                    onImageLoadProgress: (progress) =>
                        _setStoryImageLoadProgress(story, progress),
                    onImageLoadComplete: () => _completeStoryImageLoad(story),
                  ),
                ),
                Positioned.fill(
                  bottom: replyPanelHeight,
                  child: Row(
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
                ),
                if (expectsImage && !imageReady)
                  Positioned.fill(
                    bottom: replyPanelHeight,
                    child: _StoryImageBlockingLoadingOverlay(
                      style: story.textStyle,
                      progress: _imageLoadProgressByStoryId[story.id],
                    ),
                  ),
                if (imageReady && story.textStyle.poll != null)
                  Positioned.fill(
                    bottom: replyPanelHeight,
                    child: _ViewerPollOverlay(
                      story: story,
                      poll: story.textStyle.poll!,
                      isOwnAdminStory: isOwnAdminStory,
                      votingPollId: _votingPollId,
                      votingOptionId: _votingOptionId,
                      onVote: (optionId) =>
                          _votePoll(story, story.textStyle.poll!, optionId),
                    ),
                  ),
                if (imageReady && story.textStyle.grammarGame != null)
                  Positioned.fill(
                    bottom: replyPanelHeight,
                    child: _ViewerGrammarGameOverlay(
                      game: story.textStyle.grammarGame!,
                      answeringGameId: _answeringGrammarGameId,
                      answeringOptionId: _answeringGrammarOptionId,
                      onAnswer: (optionId) => _answerGrammarGame(
                        story,
                        story.textStyle.grammarGame!,
                        optionId,
                      ),
                    ),
                  ),
                Positioned.fill(
                  bottom: replyPanelHeight,
                  child: SafeArea(
                    bottom: false,
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
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _StoryReplyPanel(
                    controller: _replyController,
                    focusNode: _replyFocusNode,
                    enabled: canReply && !_sendingReply,
                    sending: _sendingReply,
                    liked: story.liked,
                    isOwnAdminStory: isOwnAdminStory,
                    onComposerActivate: _activateReplyComposer,
                    onSubmitted: (_) => _sendStoryReply(story),
                    onLike: () => _toggleLike(story),
                    onAudience: isOwnAdminStory
                        ? () => _showAudience(story)
                        : null,
                    onDelete: isOwnAdminStory
                        ? () => _requestDeleteStory(story)
                        : null,
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

class _StoryReplyPanel extends StatefulWidget {
  const _StoryReplyPanel({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.sending,
    required this.liked,
    required this.isOwnAdminStory,
    required this.onComposerActivate,
    required this.onSubmitted,
    required this.onLike,
    required this.onAudience,
    required this.onDelete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool sending;
  final bool liked;
  final bool isOwnAdminStory;
  final VoidCallback onComposerActivate;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onLike;
  final VoidCallback? onAudience;
  final VoidCallback? onDelete;

  @override
  State<_StoryReplyPanel> createState() => _StoryReplyPanelState();
}

class _StoryReplyPanelState extends State<_StoryReplyPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleInputChanged);
    widget.focusNode.addListener(_handleInputChanged);
  }

  @override
  void didUpdateWidget(covariant _StoryReplyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleInputChanged);
      widget.controller.addListener(_handleInputChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleInputChanged);
      widget.focusNode.addListener(_handleInputChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleInputChanged);
    widget.focusNode.removeListener(_handleInputChanged);
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) setState(() {});
  }

  void _submit() {
    if (!widget.enabled || widget.sending) return;
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final focused = widget.focusNode.hasFocus;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final showInlineSend = focused && (hasText || widget.sending);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      color: focused
          ? const Color(0xFF070A0F).withValues(alpha: 0.36)
          : const Color(0xFF070A0F),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          focused ? 12 : 9,
          focused ? 8 : 8,
          focused ? 12 : 9,
          (focused ? 10 : 14) + bottom,
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            if (!focused &&
                widget.isOwnAdminStory &&
                widget.onAudience != null) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 38,
                ),
                onPressed: widget.onAudience,
                icon: const Icon(
                  Icons.visibility_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: focused ? 10 : 8),
                child: SizedBox(
                  height: focused ? 44 : 38,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (_) => widget.onComposerActivate(),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      readOnly: !widget.enabled,
                      enableInteractiveSelection: widget.enabled,
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 1,
                      onTap: widget.onComposerActivate,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Send message',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: focused
                            ? Colors.black.withValues(alpha: 0.18)
                            : Colors.transparent,
                        suffixIcon: showInlineSend
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 4,
                                ),
                                child: _InlineReplySendButton(
                                  enabled:
                                      widget.enabled &&
                                      hasText &&
                                      !widget.sending,
                                  sending: widget.sending,
                                  onPressed: _submit,
                                ),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints.tightFor(
                          width: 42,
                          height: 42,
                        ),
                        disabledBorder: _replyInputBorder(alpha: 0.42),
                        enabledBorder: _replyInputBorder(
                          alpha: focused ? 0.42 : 0.48,
                        ),
                        focusedBorder: _replyInputBorder(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!focused) ...[
              const SizedBox(width: 2),
              if (widget.sending)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 38,
                  ),
                  onPressed: widget.onLike,
                  icon: Icon(
                    widget.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: widget.liked
                        ? const Color(0xFFFF2D55)
                        : Colors.white,
                    size: 27,
                  ),
                ),
              if (widget.isOwnAdminStory && widget.onDelete != null) ...[
                const SizedBox(width: 5),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 38,
                  ),
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFFF453A),
                    size: 25,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static OutlineInputBorder _replyInputBorder({required double alpha}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: alpha),
        width: 1.1,
      ),
    );
  }
}

class _InlineReplySendButton extends StatelessWidget {
  const _InlineReplySendButton({
    required this.enabled,
    required this.sending,
    required this.onPressed,
  });

  final bool enabled;
  final bool sending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onPressed : null,
        child: SizedBox.square(
          dimension: 36,
          child: Center(
            child: sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: enabled
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.64),
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}

class _StoryBody extends StatelessWidget {
  const _StoryBody({
    required this.story,
    required this.imageReady,
    required this.imageLoadProgress,
    required this.onImageLoadProgress,
    required this.onImageLoadComplete,
  });

  final StoryItem story;
  final bool imageReady;
  final double? imageLoadProgress;
  final ValueChanged<double?> onImageLoadProgress;
  final VoidCallback onImageLoadComplete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layers = story.textStyle.layers;
        final imagePath = (story.imagePath ?? '').trim();
        return Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath.isNotEmpty)
              _StoryImage(
                imagePath: imagePath,
                transform: story.textStyle.imageTransform,
                style: story.textStyle,
                ready: imageReady,
                progress: imageLoadProgress,
                onProgress: onImageLoadProgress,
                onComplete: onImageLoadComplete,
              )
            else
              _StoryTextBackground(style: story.textStyle),
            if (imageReady && layers.isNotEmpty)
              for (final layer in layers)
                _StoryLayerView(layer: layer, canvasSize: size)
            else if (imageReady && (story.textContent ?? '').trim().isNotEmpty)
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

class _ViewerGrammarGameOverlay extends StatelessWidget {
  const _ViewerGrammarGameOverlay({
    required this.game,
    required this.answeringGameId,
    required this.answeringOptionId,
    required this.onAnswer,
  });

  final StoryGrammarGame game;
  final int? answeringGameId;
  final String? answeringOptionId;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 86, 18, 96),
          child: Center(
            child: _GrammarWaterRescueGame(
              game: game,
              answeringOptionId: answeringGameId == game.id
                  ? answeringOptionId
                  : null,
              onAnswer: onAnswer,
            ),
          ),
        ),
      ),
    );
  }
}

class _GrammarWaterRescueGame extends StatelessWidget {
  const _GrammarWaterRescueGame({
    required this.game,
    required this.answeringOptionId,
    required this.onAnswer,
  });

  final StoryGrammarGame game;
  final String? answeringOptionId;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final answered = game.hasAnswered;
    final correct = game.isCorrect == true;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GrammarGameQuestionCard(text: game.questionText),
          const SizedBox(height: 18),
          _GrammarWaterTank(answered: answered, correct: correct),
          const SizedBox(height: 18),
          for (final option in game.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GrammarGameOptionButton(
                option: option,
                selected: game.selectedOptionId == option.id,
                answered: answered,
                correct: correct,
                loading: answeringOptionId == option.id,
                onTap: answered ? null : () => onAnswer(option.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _GrammarGameQuestionCard extends StatelessWidget {
  const _GrammarGameQuestionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111116),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            height: 1.25,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _GrammarWaterTank extends StatelessWidget {
  const _GrammarWaterTank({required this.answered, required this.correct});

  final bool answered;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final waterLevel = !answered
        ? 0.42
        : correct
        ? 0.12
        : 0.82;
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.82),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      heightFactor: waterLevel,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF81D4FA).withValues(alpha: 0.75),
                              const Color(0xFF0288D1).withValues(alpha: 0.86),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 450),
                    scale: answered && correct ? 1.08 : 1,
                    child: Text(
                      answered && correct
                          ? '😄'
                          : answered && !correct
                          ? '😵'
                          : '😟',
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: answered ? 1 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: correct
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF453A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  child: Text(
                    correct ? 'Saved!' : 'Water is rising!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarGameOptionButton extends StatelessWidget {
  const _GrammarGameOptionButton({
    required this.option,
    required this.selected,
    required this.answered,
    required this.correct,
    required this.loading,
    required this.onTap,
  });

  final StoryGrammarGameOption option;
  final bool selected;
  final bool answered;
  final bool correct;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = correct
        ? const Color(0xFF34C759)
        : const Color(0xFFFF453A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor
                : Colors.white.withValues(alpha: answered ? 0.72 : 0.94),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF24242C),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (selected)
                Icon(
                  correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryImage extends StatefulWidget {
  const _StoryImage({
    required this.imagePath,
    required this.transform,
    required this.style,
    required this.ready,
    required this.progress,
    required this.onProgress,
    required this.onComplete,
  });

  final String imagePath;
  final StoryImageTransform transform;
  final StoryTextStyle style;
  final bool ready;
  final double? progress;
  final ValueChanged<double?> onProgress;
  final VoidCallback onComplete;

  @override
  State<_StoryImage> createState() => _StoryImageState();
}

class _StoryImageState extends State<_StoryImage> {
  var _retryToken = 0;

  void _retry() {
    setState(() => _retryToken++);
    widget.onProgress(null);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = apiAbsoluteMediaUrl(widget.imagePath);
    return LayoutBuilder(
      builder: (context, constraints) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(widget.style.backgroundStart),
                Color(widget.style.backgroundEnd),
              ],
            ),
          ),
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(
                widget.transform.x * constraints.maxWidth,
                widget.transform.y * constraints.maxHeight,
              ),
              child: Transform.scale(
                scale: _storyImageEffectiveScale(
                  canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                  imageScale: widget.transform.scale,
                  aspectRatio: widget.transform.aspectRatio,
                ),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: _StoryImageLoadingFrame(
                    ready: widget.ready,
                    progress: widget.progress,
                    style: widget.style,
                    child: FittedBox(
                      fit: widget.transform.aspectRatio > 0
                          ? BoxFit.contain
                          : _storyImageFitForScale(widget.transform.scale),
                      child: Image.network(
                        imageUrl,
                        key: ValueKey(
                          'story_image_${widget.imagePath}_$_retryToken',
                        ),
                        headers: const {'Connection': 'close'},
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded || frame != null) {
                                widget.onComplete();
                              }
                              return child;
                            },
                        loadingBuilder: (context, child, loadingProgress) {
                          final currentProgress = _imageChunkProgress(
                            loadingProgress,
                          );
                          if (loadingProgress != null) {
                            widget.onProgress(currentProgress);
                          }
                          return child;
                        },
                        errorBuilder: (_, __, ___) {
                          widget.onProgress(null);
                          return _StoryImageErrorFrame(
                            style: widget.style,
                            onRetry: _retry,
                          );
                        },
                      ),
                    ),
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

BoxFit _storyImageFitForScale(double scale) {
  return scale < 0.995 ? BoxFit.contain : BoxFit.cover;
}

double _storyImageEffectiveScale({
  required Size canvasSize,
  required double imageScale,
  required double aspectRatio,
}) {
  if (aspectRatio <= 0 || canvasSize.width <= 0 || canvasSize.height <= 0) {
    return imageScale;
  }
  final canvasAspectRatio = canvasSize.width / canvasSize.height;
  final coverScale = math.max(
    aspectRatio / canvasAspectRatio,
    canvasAspectRatio / aspectRatio,
  );
  if (imageScale >= 1) return coverScale * imageScale;
  const minImageScale = 0.45;
  final t = ((imageScale - minImageScale) / (1 - minImageScale))
      .clamp(0.0, 1.0)
      .toDouble();
  return 1 + ((coverScale - 1) * t);
}

class _StoryImageErrorFrame extends StatelessWidget {
  const _StoryImageErrorFrame({required this.style, required this.onRetry});

  final StoryTextStyle style;
  final VoidCallback onRetry;

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
      child: Center(
        child: Material(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onRetry,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Image did not load. Tap to retry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryImageBlockingLoadingOverlay extends StatelessWidget {
  const _StoryImageBlockingLoadingOverlay({
    required this.style,
    required this.progress,
  });

  final StoryTextStyle style;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final p = progress?.clamp(0.0, 1.0).toDouble() ?? 0.0;
    final blurSigma = math.max(2.0, 22.0 * (1 - p));
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: _StoryImageLoadingBackdrop(style: style),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34 - (0.14 * p)),
            ),
            child: Center(child: _StoryImageCircularLoader(progress: progress)),
          ),
        ],
      ),
    );
  }
}

double? _imageChunkProgress(ImageChunkEvent? progress) {
  if (progress == null || progress.expectedTotalBytes == null) return null;
  return (progress.cumulativeBytesLoaded / progress.expectedTotalBytes!)
      .clamp(0.0, 1.0)
      .toDouble();
}

class _StoryImageLoadingFrame extends StatelessWidget {
  const _StoryImageLoadingFrame({
    required this.ready,
    required this.progress,
    required this.style,
    required this.child,
  });

  final bool ready;
  final double? progress;
  final StoryTextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = ready ? 1.0 : progress;
    final blurSigma = ready
        ? 0.0
        : math.max(3.0, 18.0 * (1 - (effectiveProgress ?? 0)));
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: ready ? 1 : 0,
          child: child,
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: ready ? 0 : 1,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: _StoryImageLoadingBackdrop(style: style),
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: ready ? 0 : 1,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
              ),
              child: Center(
                child: _StoryImageCircularLoader(progress: progress),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryImageLoadingBackdrop extends StatelessWidget {
  const _StoryImageLoadingBackdrop({required this.style});

  final StoryTextStyle style;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.08,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(style.backgroundStart), Color(style.backgroundEnd)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.82,
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.black.withValues(alpha: 0.20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryImageCircularLoader extends StatefulWidget {
  const _StoryImageCircularLoader({required this.progress});

  final double? progress;

  @override
  State<_StoryImageCircularLoader> createState() =>
      _StoryImageCircularLoaderState();
}

class _StoryImageCircularLoaderState extends State<_StoryImageCircularLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseCurve;

  bool get _waitingForProgress => widget.progress == null;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _pulseCurve = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
    if (_waitingForProgress) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StoryImageCircularLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_waitingForProgress && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_waitingForProgress && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress?.clamp(0.0, 1.0).toDouble() ?? 0.0;
    final indicatorOpacity = 0.26 + (0.74 * p);
    return AnimatedBuilder(
      animation: _pulseCurve,
      builder: (context, child) {
        final pulseValue = _waitingForProgress ? _pulseCurve.value : 0.0;
        final scale = 0.95 + (0.08 * pulseValue);
        final offsetY = -1.5 + (3.0 * pulseValue);
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20 + (0.10 * p)),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10 + (0.18 * p)),
          ),
        ),
        child: SizedBox.square(
          dimension: 72,
          child: Center(
            child: SizedBox.square(
              dimension: 50,
              child: CircularProgressIndicator(
                value: p,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                color: Colors.white.withValues(alpha: indicatorOpacity),
              ),
            ),
          ),
        ),
      ),
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
    final height = _storyTextLayerHeight(
      context: context,
      layer: layer,
      width: width,
    );
    return Positioned(
      left: layer.x * canvasSize.width - width / 2,
      top: _storyTextLayerTop(
        centerY: layer.y * canvasSize.height,
        height: height,
        canvasHeight: canvasSize.height,
      ),
      width: width,
      height: height,
      child: Center(child: _LayerText(layer: layer)),
    );
  }
}

class _LayerText extends StatelessWidget {
  const _LayerText({required this.layer});

  final StoryTextLayer layer;

  static TextStyle textStyle(StoryTextLayer layer) {
    return TextStyle(
      color: Color(layer.textColor),
      fontSize: layer.fontSize,
      fontFamily: storyFontFamily(layer.fontFamily),
      height: layer.lineHeight,
      fontWeight: FontWeight.w900,
      shadows: const [
        Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: layer.rotation,
      child: Transform.scale(
        scale: layer.scale,
        child: Text(
          layer.text,
          textAlign: _textAlign(layer.alignment),
          style: textStyle(layer),
        ),
      ),
    );
  }
}

double _storyTextLayerHeight({
  required BuildContext context,
  required StoryTextLayer layer,
  required double width,
}) {
  final text = layer.text.isEmpty ? ' ' : layer.text;
  final painter = TextPainter(
    text: TextSpan(text: text, style: _LayerText.textStyle(layer)),
    textAlign: _textAlign(layer.alignment),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: width);
  final verticalPadding = layer.fontSize * 0.55 + 24;
  final layoutHeight = painter.height + verticalPadding;
  return math.max(72.0, layoutHeight * math.max(1.0, layer.scale));
}

double _storyTextLayerTop({
  required double centerY,
  required double height,
  required double canvasHeight,
}) {
  if (height >= canvasHeight) return 0;
  return (centerY - height / 2).clamp(0, canvasHeight - height).toDouble();
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
        fontFamily: storyFontFamily(style.fontFamily),
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
