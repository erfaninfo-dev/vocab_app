import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/admin_story.dart';
import 'story_image_scale.dart';
import 'story_video_prepare.dart';

class StoryLoopingVideoPreview extends StatefulWidget {
  const StoryLoopingVideoPreview({
    super.key,
    required this.path,
    required this.transform,
    required this.style,
  });

  final String path;
  final StoryImageTransform transform;
  final StoryTextStyle style;

  @override
  State<StoryLoopingVideoPreview> createState() =>
      _StoryLoopingVideoPreviewState();
}

class _StoryLoopingVideoPreviewState extends State<StoryLoopingVideoPreview> {
  VideoPlayerController? _controller;
  Timer? _failSafe;
  var _ready = false;
  var _failed = false;
  Uint8List? _thumbnailBytes;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant StoryLoopingVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bind();
    }
  }

  @override
  void dispose() {
    _failSafe?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  void _markFailed() {
    if (!mounted || _ready || _failed) return;
    setState(() => _failed = true);
    unawaited(_loadThumbnailFallback());
  }

  Future<void> _loadThumbnailFallback() async {
    if (!storyVideoCompressionSupported) return;
    try {
      final bytes = await VideoCompress.getByteThumbnail(
        widget.path,
        quality: 72,
        position: 0,
      ).timeout(const Duration(seconds: 4));
      if (!mounted || bytes == null || bytes.isEmpty) return;
      setState(() => _thumbnailBytes = bytes);
    } catch (_) {}
  }

  Future<void> _bind() async {
    _failSafe?.cancel();
    final previous = _controller;
    _controller = null;
    _ready = false;
    _failed = false;
    _thumbnailBytes = null;
    if (previous != null) {
      unawaited(previous.dispose());
    }
    if (!mounted) return;

    if (!storyVideoPreviewSupported) {
      _markFailed();
      return;
    }

    _failSafe = Timer(const Duration(seconds: 8), _markFailed);

    final controller = VideoPlayerController.file(File(widget.path));
    try {
      await controller.initialize().timeout(const Duration(seconds: 8));
      if (!mounted || _failed) {
        unawaited(controller.dispose());
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
    } catch (_) {
      unawaited(controller.dispose());
      _markFailed();
      return;
    }
    if (!mounted || _failed) {
      unawaited(controller.dispose());
      return;
    }
    _failSafe?.cancel();
    setState(() {
      _controller = controller;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      child: _failed
          ? _StoryVideoPreviewFallback(thumbnailBytes: _thumbnailBytes)
          : !_ready || _controller == null
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            )
          : StoryTransformedVideo(
              controller: _controller!,
              transform: widget.transform,
            ),
    );
  }
}

class _StoryVideoPreviewFallback extends StatelessWidget {
  const _StoryVideoPreviewFallback({this.thumbnailBytes});

  final Uint8List? thumbnailBytes;

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailBytes;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thumb != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  thumb,
                  width: 180,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                Icons.videocam_rounded,
                color: Colors.white70,
                size: 52,
              ),
            const SizedBox(height: 12),
            const Text(
              'Video selected',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can still share this story.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryTransformedVideo extends StatelessWidget {
  const StoryTransformedVideo({
    super.key,
    required this.controller,
    required this.transform,
  });

  final VideoPlayerController controller;
  final StoryImageTransform transform;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = controller.value.size;
        final width = size.width <= 0 ? 9.0 : size.width;
        final height = size.height <= 0 ? 16.0 : size.height;
        return ClipRect(
          child: Transform.translate(
            offset: Offset(
              transform.x * constraints.maxWidth,
              transform.y * constraints.maxHeight,
            ),
            child: Transform.scale(
              scale: storyImageEffectiveScale(
                canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                imageScale: transform.scale,
                aspectRatio: transform.aspectRatio > 0
                    ? transform.aspectRatio
                    : width / height,
              ),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: transform.aspectRatio > 0
                      ? BoxFit.contain
                      : storyImageFitForScale(transform.scale),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: IgnorePointer(child: VideoPlayer(controller)),
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
