import 'package:flutter/material.dart';

/// Preset avatar ids stored on the server (see `api/update_profile.php`).
/// m1–m4: boy-style palettes, f1–f4: girl-style palettes (icons + colors, no image assets).
class ProfilePreset {
  const ProfilePreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}

const kDefaultAvatarId = 'm1';

const kProfilePresets = <ProfilePreset>[
  ProfilePreset(
    id: 'm1',
    label: 'Boy 1',
    icon: Icons.face_rounded,
    background: Color(0xFF2563EB),
    foreground: Colors.white,
  ),
  ProfilePreset(
    id: 'm2',
    label: 'Boy 2',
    icon: Icons.sports_esports_rounded,
    background: Color(0xFF4F46E5),
    foreground: Colors.white,
  ),
  ProfilePreset(
    id: 'm3',
    label: 'Boy 3',
    icon: Icons.school_rounded,
    background: Color(0xFF0D9488),
    foreground: Colors.white,
  ),
  ProfilePreset(
    id: 'm4',
    label: 'Boy 4',
    icon: Icons.music_note_rounded,
    background: Color(0xFF0891B2),
    foreground: Colors.white,
  ),
  ProfilePreset(
    id: 'f1',
    label: 'Girl 1',
    icon: Icons.face_3_rounded,
    background: Color(0xFFDB2777),
    foreground: Colors.white,
  ),
  ProfilePreset(
    id: 'f2',
    label: 'Girl 2',
    icon: Icons.favorite_rounded,
    background: Color(0xFFE11D48),
    foreground: Colors.white,
  ),
  ProfilePreset(
    id: 'f3',
    label: 'Girl 3',
    icon: Icons.star_rounded,
    background: Color(0xFF9333EA),
    foreground: Colors.white,
  ),
  ProfilePreset(
    id: 'f4',
    label: 'Girl 4',
    icon: Icons.auto_awesome_rounded,
    background: Color(0xFFC026D3),
    foreground: Colors.white,
  ),
];

ProfilePreset profilePresetForId(String? id) {
  final key = (id == null || id.isEmpty) ? kDefaultAvatarId : id;
  for (final p in kProfilePresets) {
    if (p.id == key) {
      return p;
    }
  }
  return kProfilePresets.first;
}
