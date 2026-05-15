import 'package:flutter/material.dart';

import '../../domain/word_builder_models.dart';

class LetterTile extends StatelessWidget {
  const LetterTile({
    super.key,
    required this.instance,
    required this.onTap,
    this.compact = false,
  });

  final LetterInstance instance;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final side = compact ? 40.0 : 46.0;
    final label = instance.char.toUpperCase();
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: side,
          height: side,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
