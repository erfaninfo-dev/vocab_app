import 'package:flutter/material.dart';

/// Full-resolution logo for in-app UI.
///
/// Do not use [assets/app_icon.png] for on-screen display — it is a tiny
/// launcher icon and looks blurry when scaled up.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = 56,
    this.borderRadius = 18,
    this.boxShadow,
  });

  final double size;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  static const _logoPath = 'assets/branding/logo.png';
  static const _fallbackPath = 'assets/app_icon.png';

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (size * dpr).round().clamp(64, 512);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          _logoPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          cacheWidth: cachePx,
          cacheHeight: cachePx,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              _fallbackPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            );
          },
        ),
      ),
    );
  }
}
