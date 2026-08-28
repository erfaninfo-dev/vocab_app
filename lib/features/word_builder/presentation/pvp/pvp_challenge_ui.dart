import 'package:flutter/material.dart';

IconData pvpCategoryIcon(String iconName) {
  return switch (iconName) {
    'pets_rounded' => Icons.pets_rounded,
    'restaurant_rounded' => Icons.restaurant_rounded,
    'park_rounded' => Icons.park_rounded,
    'place_rounded' => Icons.place_rounded,
    'sports_soccer_rounded' => Icons.sports_soccer_rounded,
    'work_rounded' => Icons.work_rounded,
    'category_rounded' => Icons.category_rounded,
    'memory_rounded' => Icons.memory_rounded,
    'directions_bus_rounded' => Icons.directions_bus_rounded,
    'accessibility_new_rounded' => Icons.accessibility_new_rounded,
    'checkroom_rounded' => Icons.checkroom_rounded,
    'family_restroom_rounded' => Icons.family_restroom_rounded,
    'school_rounded' => Icons.school_rounded,
    'flight_rounded' => Icons.flight_rounded,
    'wb_cloudy_rounded' => Icons.wb_cloudy_rounded,
    'rocket_launch_rounded' => Icons.rocket_launch_rounded,
    'waves_rounded' => Icons.waves_rounded,
    'auto_fix_high_rounded' => Icons.auto_fix_high_rounded,
    'sailing_rounded' => Icons.sailing_rounded,
    _ => Icons.extension_rounded,
  };
}

const Color kPvpGold = Color(0xFFFFB300);
const Color kPvpCrimson = Color(0xFFE53935);

LinearGradient pvpChallengeGradient(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const LinearGradient(
      colors: [Color(0xFF24152B), Color(0xFF4A2341), Color(0xFF2D2640)],
    );
  }
  return const LinearGradient(
    colors: [Color(0xFFFFF8E1), Color(0xFFFFDDE8), Color(0xFFFFECB3)],
  );
}
