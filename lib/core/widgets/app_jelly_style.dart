import 'package:flutter/material.dart';

/// App-wide jelly card look (soft gradient, glow, rounded glass edge).
const double kAppJellyRadius = 24;

List<BoxShadow> appJellyCardShadows(
  BuildContext context, {
  ColorScheme? scheme,
  Color? glowColor,
}) {
  final colors = scheme ?? Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final glow = glowColor ?? colors.primary;

  return [
    BoxShadow(
      color: glow.withValues(alpha: isDark ? 0.18 : 0.12),
      blurRadius: 28,
      offset: const Offset(0, 12),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: (glowColor ?? colors.tertiary).withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Fill + border only (no shadow). Use inside clipped Material / Ink.
BoxDecoration appJellyCardSurfaceDecoration(
  BuildContext context, {
  ColorScheme? scheme,
}) {
  final colors = scheme ?? Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(kAppJellyRadius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Color.lerp(colors.primaryContainer, colors.surface, 0.35)!,
              Color.lerp(colors.tertiaryContainer, colors.surface, 0.45)!,
            ]
          : [
              Color.lerp(colors.primaryContainer, Colors.white, 0.42)!,
              Color.lerp(colors.secondaryContainer, Colors.white, 0.55)!,
              Color.lerp(colors.tertiaryContainer, Colors.white, 0.48)!,
            ],
    ),
    border: Border.all(
      color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.72),
      width: 1.4,
    ),
  );
}

/// Convenience decoration for plain [Container] (shadow outside the fill).
BoxDecoration appJellyCardDecoration(
  BuildContext context, {
  ColorScheme? scheme,
}) {
  return appJellyCardSurfaceDecoration(context, scheme: scheme).copyWith(
    boxShadow: appJellyCardShadows(context, scheme: scheme),
  );
}

/// Accent-tinted jelly fill (no shadow).
BoxDecoration appJellyAccentCardSurfaceDecoration(
  BuildContext context, {
  required Color accent,
  Color? accentEnd,
  bool selected = false,
  double intensity = 0.22,
  ColorScheme? scheme,
}) {
  final colors = scheme ?? Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final end = accentEnd ?? accent;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(kAppJellyRadius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Color.lerp(accent, colors.surface, 1 - intensity * 1.4)!,
              Color.lerp(end, colors.surface, 1 - intensity * 0.9)!,
              colors.surface,
            ]
          : [
              Color.lerp(accent, Colors.white, 1 - intensity)!,
              Color.lerp(end, Colors.white, 1 - intensity * 0.55)!,
              Color.lerp(colors.surface, accent, 0.06)!,
            ],
    ),
    border: Border.all(
      color: selected
          ? colors.primary
          : Colors.white.withValues(alpha: isDark ? 0.14 : 0.75),
      width: selected ? 2.5 : 1.4,
    ),
  );
}

BoxDecoration appJellyAccentCardDecoration(
  BuildContext context, {
  required Color accent,
  Color? accentEnd,
  bool selected = false,
  double intensity = 0.22,
  ColorScheme? scheme,
}) {
  final end = accentEnd ?? accent;
  return appJellyAccentCardSurfaceDecoration(
    context,
    accent: accent,
    accentEnd: end,
    selected: selected,
    intensity: intensity,
    scheme: scheme,
  ).copyWith(
    boxShadow: appJellyCardShadows(context, glowColor: accent),
  );
}

BoxDecoration appJellyInsetDecoration(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: isDark ? 0.06 : 0.55),
        scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.55),
      ],
    ),
    border: Border.all(
      color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
      width: 1.2,
    ),
  );
}

class AppJellyIconBubble extends StatelessWidget {
  const AppJellyIconBubble({
    super.key,
    required this.color,
    required this.child,
    this.size = 44,
  });

  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, isDark ? 0.18 : 0.28)!,
            color,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class AppJellyCountBadge extends StatelessWidget {
  const AppJellyCountBadge({
    super.key,
    required this.label,
    this.tone = AppJellyBadgeTone.error,
  });

  final String label;
  final AppJellyBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color base;
    final Color onBase;
    switch (tone) {
      case AppJellyBadgeTone.error:
        base = scheme.error;
        onBase = scheme.onError;
      case AppJellyBadgeTone.primary:
        base = scheme.primary;
        onBase = scheme.onPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, isDark ? 0.12 : 0.18)!,
            base,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onBase,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum AppJellyBadgeTone { error, primary }

/// Rounded jelly shell: soft shadow outside, clipped fill inside (no sharp corners).
class AppJellyShell extends StatelessWidget {
  const AppJellyShell({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.width,
    this.decoration,
    this.shadows,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final BoxDecoration? decoration;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(kAppJellyRadius);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final raw = decoration ?? appJellyCardSurfaceDecoration(context);
    final surface = BoxDecoration(
      borderRadius: radius,
      gradient: raw.gradient,
      color: raw.color,
      border: raw.border,
      image: raw.image,
      backgroundBlendMode: raw.backgroundBlendMode,
    );
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);

    final shell = Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows ?? appJellyCardShadows(context),
      ),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: clipBehavior,
        child: onTap == null && onLongPress == null
            ? Ink(
                decoration: surface,
                child: content,
              )
            : InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                customBorder: shape,
                hoverColor: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.04,
                ),
                splashColor: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                highlightColor: Colors.transparent,
                child: Ink(
                  decoration: surface,
                  child: content,
                ),
              ),
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: shell);
    }
    return shell;
  }
}

/// Jelly surface with optional tap — use for list/nav cards across the app.
class AppJellyCard extends StatelessWidget {
  const AppJellyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
    this.width,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AppJellyShell(
      onTap: onTap,
      padding: padding,
      margin: margin,
      width: width,
      clipBehavior: clipBehavior == Clip.none ? Clip.antiAlias : clipBehavior,
      child: child,
    );
  }
}
