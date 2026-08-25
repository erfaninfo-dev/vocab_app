import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

const Duration kStoryVideoMaxDuration = Duration(seconds: 60);
const int kStoryVideoMaxUploadBytes = 40 * 1024 * 1024;
const Duration kStoryVideoShareTimeout = Duration(seconds: 120);
const Duration kStoryVideoCompressTimeout = Duration(seconds: 90);

typedef StoryVideoProgressCallback =
    void Function({required String label, double? fraction});

class PreparedStoryVideo {
  const PreparedStoryVideo({
    required this.filePath,
    required this.aspectRatio,
    required this.duration,
    this.trimmedToMax = false,
  });

  final String filePath;
  final double aspectRatio;
  final Duration duration;
  final bool trimmedToMax;
}

bool get storyVideoCompressionSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

bool get storyVideoPreviewSupported => !kIsWeb;

Future<String> materializePickedStoryVideo({
  required String pickPath,
  required Stream<List<int>> pickBytes,
  StoryVideoProgressCallback? onProgress,
}) async {
  onProgress?.call(label: 'Copying video...', fraction: 0.05);
  final trimmed = pickPath.trim();
  if (trimmed.isNotEmpty) {
    final source = File(trimmed);
    if (await source.exists()) {
      final size = await source.length();
      if (size > 1024) {
        onProgress?.call(label: 'Video copied', fraction: 0.12);
        return trimmed;
      }
    }
  }

  final tmpDir = await Directory.systemTemp.createTemp('story_pick_');
  final dest = File(
    '${tmpDir.path}/story_${DateTime.now().microsecondsSinceEpoch}.mp4',
  );
  final sink = dest.openWrite();
  try {
    var copied = 0;
    await for (final chunk in pickBytes) {
      sink.add(chunk);
      copied += chunk.length;
    }
    if (copied <= 0) {
      throw Exception('Could not read the selected video.');
    }
  } finally {
    await sink.close();
  }
  onProgress?.call(label: 'Video copied', fraction: 0.12);
  return dest.path;
}

Future<PreparedStoryVideo> prepareStoryVideo(
  String sourcePath, {
  StoryVideoProgressCallback? onProgress,
}) async {
  final source = File(sourcePath);
  if (!await source.exists()) {
    throw Exception('Could not open the selected video.');
  }

  onProgress?.call(label: 'Checking video...', fraction: 0.2);
  final originalSize = await source.length();
  if (originalSize < 1024) {
    throw Exception('Could not prepare this video.');
  }

  var workingPath = sourcePath;
  var duration = kStoryVideoMaxDuration;
  var aspectRatio = 9 / 16;
  var trimmedToMax = false;

  if (storyVideoCompressionSupported) {
    try {
      final info = await VideoCompress.getMediaInfo(sourcePath).timeout(
        const Duration(seconds: 4),
      );
      final durationMs = info.duration ?? 0;
      if (durationMs >= 400) {
        duration = Duration(milliseconds: durationMs.round());
        if (duration > kStoryVideoMaxDuration) {
          duration = kStoryVideoMaxDuration;
          trimmedToMax = true;
        }
      }
      final width = info.width ?? 0;
      final height = info.height ?? 0;
      if (width > 0 && height > 0) {
        aspectRatio = width / height;
        final orientation = info.orientation ?? 0;
        if (orientation == 90 || orientation == 270) {
          aspectRatio = height / width;
        }
      }
    } catch (_) {}
  }

  final needsCompress =
      originalSize > kStoryVideoMaxUploadBytes || trimmedToMax;

  if (needsCompress && storyVideoCompressionSupported) {
    onProgress?.call(label: 'Compressing video...', fraction: 0.25);
    final compressed = await _compressStoryVideo(
      sourcePath,
      trimTo: trimmedToMax ? kStoryVideoMaxDuration : null,
      onProgress: onProgress,
    );
    if (compressed != null && await compressed.exists()) {
      workingPath = compressed.path;
    } else if (originalSize > kStoryVideoMaxUploadBytes) {
      throw Exception(
        'Could not compress this video. Please pick a shorter clip.',
      );
    }
  } else if (originalSize > kStoryVideoMaxUploadBytes) {
    throw Exception(
      'This video is too large. Please pick a shorter clip (up to 60 seconds).',
    );
  }

  final size = await File(workingPath).length();
  if (size < 1024) {
    throw Exception('Could not prepare this video.');
  }
  if (size > kStoryVideoMaxUploadBytes) {
    throw Exception(
      'This video is too large. Please pick a shorter clip (up to 60 seconds).',
    );
  }
  if (aspectRatio <= 0) aspectRatio = 9 / 16;

  onProgress?.call(label: 'Ready', fraction: 1);
  return PreparedStoryVideo(
    filePath: workingPath,
    aspectRatio: aspectRatio,
    duration: duration,
    trimmedToMax: trimmedToMax,
  );
}

Future<File?> _compressStoryVideo(
  String path, {
  Duration? trimTo,
  StoryVideoProgressCallback? onProgress,
}) async {
  Subscription? progressSub;
  if (onProgress != null) {
    progressSub = VideoCompress.compressProgress$.subscribe((raw) {
      final p = (raw.clamp(0.0, 100.0) / 100.0).clamp(0.0, 1.0);
      onProgress(
        label: 'Compressing ${(p * 100).round()}%',
        fraction: 0.25 + (p * 0.7),
      );
    });
  }

  try {
    onProgress?.call(label: 'Compressing video...', fraction: 0.25);
    final info = await VideoCompress.compressVideo(
      path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
      duration: trimTo?.inSeconds,
    ).timeout(
      kStoryVideoCompressTimeout,
      onTimeout: () {
        throw TimeoutException('Video compression timed out.');
      },
    );
    final outPath = info?.path;
    if (outPath == null || outPath.isEmpty) return null;
    final file = File(outPath);
    if (!await file.exists()) return null;
    final size = await file.length();
    if (size <= 0) return null;
    if (size <= kStoryVideoMaxUploadBytes) {
      onProgress?.call(label: 'Compression done', fraction: 0.95);
      return file;
    }
  } on TimeoutException {
    await VideoCompress.cancelCompression();
    rethrow;
  } catch (_) {
    return null;
  } finally {
    progressSub?.unsubscribe();
  }
  return null;
}

Future<String> cacheRemoteStoryVideo(String url) async {
  final uri = Uri.parse(url);
  final lower = uri.path.toLowerCase();
  final ext = lower.endsWith('.mov')
      ? 'mov'
      : lower.endsWith('.webm')
      ? 'webm'
      : lower.endsWith('.3gp') || lower.endsWith('.3gpp')
      ? '3gp'
      : lower.endsWith('.m4v')
      ? 'm4v'
      : 'mp4';
  final tmp = await Directory.systemTemp.createTemp('story_net_');
  final dest = File('${tmp.path}/clip.$ext');
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
    request.followRedirects = true;
    final response = await request.close().timeout(const Duration(seconds: 90));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Could not download story video.');
    }
    final sink = dest.openWrite();
    try {
      await response.pipe(sink);
    } catch (_) {
      await sink.close();
      rethrow;
    }
  } finally {
    client.close(force: true);
  }
  if (!await dest.exists() || await dest.length() < 1024) {
    throw Exception('Could not download story video.');
  }
  return dest.path;
}

Future<VideoPlayerController> createStoryVideoController(String url) async {
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    final local = await cacheRemoteStoryVideo(url);
    return VideoPlayerController.file(File(local));
  }
  return VideoPlayerController.networkUrl(
    Uri.parse(url),
    httpHeaders: const {'Accept': '*/*'},
  );
}

Future<void> disposeStoryVideoCache() async {
  if (!storyVideoCompressionSupported) return;
  try {
    await VideoCompress.cancelCompression();
  } catch (_) {}
  try {
    await VideoCompress.deleteAllCache();
  } catch (_) {}
}
