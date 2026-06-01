import 'dart:math' as math;

import 'package:flutter/material.dart';

const kStoryImagePinchMinScale = 0.15;
const kStoryImagePinchMaxScale = 4.0;

const _kStoryImageShrinkFloorScale = 0.45;
const _kStoryImageMinContainEffectiveScale = 0.22;

BoxFit storyImageFitForScale(double scale) {
  return scale < 0.995 ? BoxFit.contain : BoxFit.cover;
}

double storyImageEffectiveScale({
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

  if (imageScale <= _kStoryImageShrinkFloorScale) {
    final t =
        ((imageScale - kStoryImagePinchMinScale) /
                (_kStoryImageShrinkFloorScale - kStoryImagePinchMinScale))
            .clamp(0.0, 1.0)
            .toDouble();
    return _kStoryImageMinContainEffectiveScale +
        (1 - _kStoryImageMinContainEffectiveScale) * t;
  }

  final t =
      ((imageScale - _kStoryImageShrinkFloorScale) /
              (1 - _kStoryImageShrinkFloorScale))
          .clamp(0.0, 1.0)
          .toDouble();
  return 1 + ((coverScale - 1) * t);
}
