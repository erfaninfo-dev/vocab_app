import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/profile/profile_avatar.dart';
import '../../data/models/admin_story.dart';

class StoryRing extends StatefulWidget {
  const StoryRing({
    super.key,
    required this.stories,
    this.size = 64,
    this.initialStoryId,
  });

  final List<StoryItem> stories;
  final double size;
  final int? initialStoryId;

  @override
  State<StoryRing> createState() => _StoryRingState();
}

class _StoryRingState extends State<StoryRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.stories.first;
    final hasUnseen = widget.stories.any((s) => !s.seen);
    final scheme = Theme.of(context).colorScheme;
    final borderGradient = hasUnseen
        ? const LinearGradient(
            colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          )
        : LinearGradient(
            colors: [
              scheme.outlineVariant,
              scheme.outline.withValues(alpha: 0.65),
            ],
          );

    return Semantics(
      button: true,
      label: 'Stories',
      child: GestureDetector(
        onTap: () {
          final initialStoryId = widget.initialStoryId;
          context.push(
            initialStoryId == null
                ? '/stories/viewer'
                : '/stories/viewer?storyId=$initialStoryId',
          );
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final spread = hasUnseen ? 3.0 + (_pulse.value * 5) : 0.0;
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (hasUnseen)
                    BoxShadow(
                      color: const Color(0xFFD62976).withValues(alpha: 0.22),
                      blurRadius: 10 + spread,
                      spreadRadius: spread * 0.18,
                    ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: borderGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
              child: ProfileAvatar(
                avatarId: first.adminAvatar,
                userId: first.adminUserId,
                size: widget.size - 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
