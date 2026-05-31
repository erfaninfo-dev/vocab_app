import 'package:flutter/material.dart';

/// Placeholder when [assets/branding/logo.png] is unavailable (e.g. stale build).
class AppBrandLogoFallback extends StatelessWidget {
  const AppBrandLogoFallback({super.key, required this.size, this.borderRadius = 18});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.9),
            scheme.tertiary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.auto_stories_rounded,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}

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
            return AppBrandLogoFallback(size: size, borderRadius: borderRadius);
          },
        ),
      ),
    );
  }
}
