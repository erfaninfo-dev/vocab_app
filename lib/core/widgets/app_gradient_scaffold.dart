import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

List<Color> appGradientBackgroundColors(ColorScheme scheme) => [
      scheme.primary.withValues(alpha: 0.10),
      scheme.secondary.withValues(alpha: 0.06),
      scheme.surface,
    ];

SystemUiOverlayStyle appSystemOverlayStyle(BuildContext context) =>
    AppTheme.systemOverlayStyleFor(context);

PreferredSizeWidget styledAppGradientAppBar({
  required BuildContext context,
  Widget? leading,
  Widget? title,
  bool? centerTitle,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final scheme = Theme.of(context).colorScheme;
  return AppBar(
    leading: leading,
    title: title,
    centerTitle: centerTitle,
    actions: actions,
    bottom: bottom,
    backgroundColor: scheme.surface.withValues(alpha: 0.85),
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: appSystemOverlayStyle(context),
  );
}

double appGradientContentTopInset(
  BuildContext context, {
  PreferredSizeWidget? appBar,
  double extra = 0,
}) {
  final top = MediaQuery.paddingOf(context).top;
  final barHeight = appBar?.preferredSize.height ?? kToolbarHeight;
  return top + barHeight + extra;
}

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overlay = appSystemOverlayStyle(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: appGradientBackgroundColors(scheme),
            ),
          ),
          child: body,
        ),
      ),
    );
  }
}
