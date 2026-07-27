import 'package:flutter/material.dart';

import 'app_jelly_style.dart';

/// Label for a class term: jelly surface card, high-contrast label text.
class TermTitleCard extends StatelessWidget {
  const TermTitleCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: appJellyInsetDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
