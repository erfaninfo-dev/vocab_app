import 'package:flutter/material.dart';

class SpeakingTopicIllustration extends StatelessWidget {
  const SpeakingTopicIllustration({
    super.key,
    required this.assetPath,
    this.width = 112,
    this.height = 96,
    this.alignment = Alignment.bottomRight,
  });

  final String? assetPath;
  final double width;
  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null || path.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Align(
          alignment: alignment,
          child: Image.asset(
            path,
            width: width,
            height: height,
            fit: BoxFit.contain,
            alignment: alignment,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
