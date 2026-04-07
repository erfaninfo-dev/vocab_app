import 'package:flutter/material.dart';

import 'profile_presets.dart';

/// Circular preset avatar (no network image).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarId,
    this.size = 44,
    this.showBorder = false,
  });

  final String avatarId;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final p = profilePresetForId(avatarId);
    return Container(
      width: size,
      height: size,
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            )
          : null,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: p.background,
        child: Icon(
          p.icon,
          color: p.foreground,
          size: size * 0.52,
        ),
      ),
    );
  }
}
