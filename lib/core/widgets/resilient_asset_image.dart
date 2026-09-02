import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:io' show Platform;

/// Desktop builds prefer PNG (broader decoder support); mobile keeps WebP.
String resolveBundledIllustrationPath(String assetPath) {
  if (kIsWeb) return assetPath;

  final onDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  if (!onDesktop) return assetPath;

  if (assetPath.endsWith('.webp')) {
    return '${assetPath.substring(0, assetPath.length - 5)}.png';
  }
  return assetPath;
}

/// Loads a bundled image, trying the alternate `.webp` / `.png` path on failure.
///
/// Idioms/Speaking art may ship as WebP locally while CI/APK builds still
/// bundle legacy PNG until assets are migrated in git.
class ResilientAssetImage extends StatefulWidget {
  const ResilientAssetImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.filterQuality = FilterQuality.medium,
    this.fallback,
  });

  final String assetPath;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final FilterQuality filterQuality;
  final Widget? fallback;

  @override
  State<ResilientAssetImage> createState() => _ResilientAssetImageState();
}

class _ResilientAssetImageState extends State<ResilientAssetImage> {
  late String _path = resolveBundledIllustrationPath(widget.assetPath);
  final Set<String> _triedPaths = {};

  @override
  void didUpdateWidget(covariant ResilientAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _path = resolveBundledIllustrationPath(widget.assetPath);
      _triedPaths
        ..clear()
        ..add(_path);
    }
  }

  @override
  void initState() {
    super.initState();
    _triedPaths.add(_path);
  }

  String? _alternateAssetPath(String path) {
    if (path.endsWith('.webp')) {
      return '${path.substring(0, path.length - 5)}.png';
    }
    if (path.endsWith('.png')) {
      return '${path.substring(0, path.length - 4)}.webp';
    }
    return null;
  }

  void _scheduleFallback() {
    final alternate = _alternateAssetPath(_path);
    if (alternate == null || _triedPaths.contains(alternate)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _path = alternate;
        _triedPaths.add(alternate);
      });
    });
  }

  bool get _canRetry => _alternateAssetPath(_path) != null &&
      !_triedPaths.contains(_alternateAssetPath(_path));

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _path,
      fit: widget.fit,
      alignment: widget.alignment,
      width: widget.width,
      height: widget.height,
      filterQuality: widget.filterQuality,
      errorBuilder: (_, __, ___) {
        if (_canRetry) {
          _scheduleFallback();
          return widget.fallback ?? const SizedBox.shrink();
        }
        return widget.fallback ?? const SizedBox.shrink();
      },
    );
  }
}
