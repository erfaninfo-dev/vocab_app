import 'package:flutter/material.dart';

/// Word Builder (lobby, stages, session) stays left-to-right even when the app
/// UI locale is Persian or Kurdish — English letter layout must not mirror.
class WordBuilderLtrScope extends StatelessWidget {
  const WordBuilderLtrScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }
}
