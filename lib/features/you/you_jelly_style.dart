import 'package:flutter/material.dart';

import '../../core/widgets/app_jelly_style.dart';

/// You-screen aliases for the shared app jelly style.
const double kYouJellyRadius = kAppJellyRadius;

BoxDecoration youJellyCardDecoration(
  BuildContext context, {
  ColorScheme? scheme,
}) =>
    appJellyCardDecoration(context, scheme: scheme);

BoxDecoration youJellyCardSurfaceDecoration(
  BuildContext context, {
  ColorScheme? scheme,
}) =>
    appJellyCardSurfaceDecoration(context, scheme: scheme);

BoxDecoration youJellyInsetDecoration(BuildContext context) =>
    appJellyInsetDecoration(context);

List<BoxShadow> youJellyCardShadows(
  BuildContext context, {
  ColorScheme? scheme,
}) =>
    appJellyCardShadows(context, scheme: scheme);

typedef YouJellyIconBubble = AppJellyIconBubble;
typedef YouJellyCountBadge = AppJellyCountBadge;
typedef YouJellyBadgeTone = AppJellyBadgeTone;
typedef YouJellyShell = AppJellyShell;
