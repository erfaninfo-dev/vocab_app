import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/profile/profile_avatar.dart';
import '../../data/models/admin_story.dart';

class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.stories,
    this.size = 64,
    this.initialStoryId,
  });

  final List<StoryItem> stories;
  final double size;
  final int? initialStoryId;

  static const _unseenRingColor = Color(0xFFD62976);
  static const _seenRingColor = Color(0xFFB0B0B0);

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    final first = stories.first;
    final scheme = Theme.of(context).colorScheme;
    final ringStroke = size >= 60 ? 3.0 : 2.5;
    final innerInset = ringStroke + 2.5;

    return Semantics(
      button: true,
      label: 'Stories',
      child: GestureDetector(
        onTap: () {
          final initialStoryId = this.initialStoryId;
          context.push(
            initialStoryId == null
                ? '/stories/viewer'
                : '/stories/viewer?storyId=$initialStoryId',
          );
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _SegmentedStoryRingPainter(
                  seenFlags: [for (final story in stories) story.seen],
                  strokeWidth: ringStroke,
                  gapRadians: stories.length > 1 ? 16 * math.pi / 180 : 0,
                  unseenColor: _unseenRingColor,
                  seenColor: _seenRingColor,
                ),
              ),
              Container(
                width: size - innerInset * 2,
                height: size - innerInset * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                ),
                alignment: Alignment.center,
                child: ProfileAvatar(
                  avatarId: first.adminAvatar,
                  userId: first.adminUserId,
                  size: size - 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedStoryRingPainter extends CustomPainter {
  const _SegmentedStoryRingPainter({
    required this.seenFlags,
    required this.strokeWidth,
    required this.gapRadians,
    required this.unseenColor,
    required this.seenColor,
  });

  final List<bool> seenFlags;
  final double strokeWidth;
  final double gapRadians;
  final Color unseenColor;
  final Color seenColor;

  @override
  void paint(Canvas canvas, Size size) {
    final count = seenFlags.length;
    if (count == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAtTop = -math.pi / 2;

    if (count == 1) {
      _drawSegment(
        canvas: canvas,
        rect: rect,
        startAngle: startAtTop,
        sweepAngle: math.pi * 2,
        seen: seenFlags.first,
      );
      return;
    }

    final totalGap = gapRadians * count;
    final sweepPerSegment = (math.pi * 2 - totalGap) / count;

    for (var i = 0; i < count; i++) {
      final startAngle = startAtTop + i * (sweepPerSegment + gapRadians);
      _drawSegment(
        canvas: canvas,
        rect: rect,
        startAngle: startAngle,
        sweepAngle: sweepPerSegment,
        seen: seenFlags[i],
      );
    }
  }

  void _drawSegment({
    required Canvas canvas,
    required Rect rect,
    required double startAngle,
    required double sweepAngle,
    required bool seen,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = seen ? seenColor : unseenColor;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SegmentedStoryRingPainter oldDelegate) {
    return oldDelegate.seenFlags != seenFlags ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gapRadians != gapRadians ||
        oldDelegate.unseenColor != unseenColor ||
        oldDelegate.seenColor != seenColor;
  }
}
