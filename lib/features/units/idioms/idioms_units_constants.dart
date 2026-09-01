import 'package:flutter/material.dart';

/// Server book id for «Idioms for Speaking».
const int kIdiomsSpeakingBookId = 37;

/// Reference width for a typical phone (~2-column idioms grid).
const double kIdiomsCardReferenceWidth = 175;

/// Reference screen width (e.g. iPhone 14).
const double kIdiomsScreenReferenceWidth = 390;

/// Target max card width — wider viewports add columns instead of stretching cards.
const double kIdiomsUnitCardMaxWidth = 200;

/// Card width / height in the idioms units grid.
const double kIdiomsUnitCardAspectRatio = 0.88;

/// Scales card typography, padding, and illustration insets from grid cell width.
/// Linear on small phones; capped so cards do not blow up on tablet/desktop.
double idiomsCardScale(double cardWidth) =>
    (cardWidth / kIdiomsCardReferenceWidth).clamp(0.52, 1.05);

/// Scales page chrome (search row, hint, grid gaps) from screen width.
double idiomsScreenScale(double screenWidth) =>
    (screenWidth / kIdiomsScreenReferenceWidth).clamp(0.75, 1.0);

/// Column count for the idioms grid — keeps cards near [kIdiomsUnitCardMaxWidth].
int idiomsUnitsGridCrossAxisCount({
  required double viewportWidth,
  required double horizontalPadding,
  required double spacing,
}) {
  final inner = (viewportWidth - horizontalPadding).clamp(0, double.infinity);
  final count =
      ((inner + spacing) / (kIdiomsUnitCardMaxWidth + spacing)).floor();
  return count.clamp(2, 6);
}

/// Pool used when [unit_details] does not match a known category slug.
const kIdiomsUnitArtPool = <String>[
  'assets/idioms_units/age_pic.png',
  'assets/idioms_units/city_pic.png',
  'assets/idioms_units/communication_pic.png',
  'assets/idioms_units/education_pic.png',
  'assets/idioms_units/entertainment_pic.png',
  'assets/idioms_units/environment_pic.png',
  'assets/idioms_units/experience_pic.png',
  'assets/idioms_units/food_pic.png',
  'assets/idioms_units/friendship_pic.png',
  'assets/idioms_units/futureplans_pic.png',
  'assets/idioms_units/health_pic.png',
  'assets/idioms_units/home_pic.png',
  'assets/idioms_units/love_pic.png',
  'assets/idioms_units/money_pic.png',
  'assets/idioms_units/nature_pic.png',
  'assets/idioms_units/negativefeeling_pic.png',
  'assets/idioms_units/shopping_pic.png',
  'assets/idioms_units/problems_pic.png',
  'assets/idioms_units/achievement_pic.png',
  'assets/idioms_units/positivefeeling_pic.png',
  'assets/idioms_units/technology_pic.png',
  'assets/idioms_units/time_pic.png',
  'assets/idioms_units/transport_pic.png',
  'assets/idioms_units/travel_pic.png',
  'assets/idioms_units/weather_pic.png',
  'assets/idioms_units/work_pic.png',
];

/// Normalized slug from [unit_details] (`Shopping 🛍️` → `shopping`).
String idiomsUnitSlug(String? unitDetails) {
  final title = idiomsUnitDisplayTitle(unitDetails).toLowerCase();
  if (title.isEmpty) return '';
  return title.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Art keyed by slug — **not** by unit number (DB order may differ).
const _kIdiomsAssetBySlug = <String, String>{
  'age': 'assets/idioms_units/age_pic.png',
  'citiesplaces': 'assets/idioms_units/city_pic.png',
  'communication': 'assets/idioms_units/communication_pic.png',
  'education': 'assets/idioms_units/education_pic.png',
  'entertainmentfreetime': 'assets/idioms_units/entertainment_pic.png',
  'environment': 'assets/idioms_units/environment_pic.png',
  'experiencesmemories': 'assets/idioms_units/experience_pic.png',
  'food': 'assets/idioms_units/food_pic.png',
  'friendshiphelpingothers': 'assets/idioms_units/friendship_pic.png',
  'futureplans': 'assets/idioms_units/futureplans_pic.png',
  'healthlifestyle': 'assets/idioms_units/health_pic.png',
  'homefamily': 'assets/idioms_units/home_pic.png',
  'loverelationships': 'assets/idioms_units/love_pic.png',
  'money': 'assets/idioms_units/money_pic.png',
  'negativefeelings': 'assets/idioms_units/negativefeeling_pic.png',
  'nature': 'assets/idioms_units/nature_pic.png',
  'opinionsdecisions': 'assets/idioms_units/opinion_pic.png',
  'peoplepersonality': 'assets/idioms_units/people_pic.png',
  'shopping': 'assets/idioms_units/shopping_pic.png',
  'stressproblems': 'assets/idioms_units/problems_pic.png',
  'successachievement': 'assets/idioms_units/achievement_pic.png',
  'positivefeelings': 'assets/idioms_units/positivefeeling_pic.png',
  'technology': 'assets/idioms_units/technology_pic.png',
  'time': 'assets/idioms_units/time_pic.png',
  'transport': 'assets/idioms_units/transport_pic.png',
  'travel': 'assets/idioms_units/travel_pic.png',
  'weather': 'assets/idioms_units/weather_pic.png',
  'workcareer': 'assets/idioms_units/work_pic.png',
};

/// Local illustration path — prefers [unitDetails] slug, then stable pool by [unit].
String? idiomsUnitAssetPath(int unit, {String? unitDetails}) {
  final slug = idiomsUnitSlug(unitDetails);
  if (slug.isNotEmpty) {
    final direct = _kIdiomsAssetBySlug[slug];
    if (direct != null) return direct;
  }

  if (unit <= 0) return kIdiomsUnitArtPool.first;

  final index = (unit * 7 + 1) % kIdiomsUnitArtPool.length;
  return kIdiomsUnitArtPool[index];
}

/// Shared illustration box size (same for every card).
const double kIdiomsImageSlotWidthFactor = 0.72;
const double kIdiomsImageSlotHeightFactor = 0.52;

/// Optional tweak inside the fixed illustration slot (default 1.0).
const kIdiomsImageSlotScaleByAsset = <String, double>{
  'assets/idioms_units/age_pic.png': 1.06,
};

double idiomsImageSlotScale(String? assetPath) =>
    kIdiomsImageSlotScaleByAsset[assetPath ?? ''] ?? 1.0;

/// Card title without trailing emoji (server may store `Travel ✈️`).
String idiomsUnitDisplayTitle(String? unitDetails) {
  if (unitDetails == null || unitDetails.trim().isEmpty) return '';
  return unitDetails
      .replaceAll(
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
        '',
      )
      .trim();
}

class IdiomsUnitCardTheme {
  const IdiomsUnitCardTheme({required this.background, required this.accent});

  final Color background;
  final Color accent;
}

const _kIdiomsUnitThemes = <IdiomsUnitCardTheme>[
  IdiomsUnitCardTheme(background: Color(0xFFF3EDFF), accent: Color(0xFF8B5CF6)),
  IdiomsUnitCardTheme(background: Color(0xFFE9F9F0), accent: Color(0xFF22C55E)),
  IdiomsUnitCardTheme(background: Color(0xFFFFF6E8), accent: Color(0xFFF59E0B)),
  IdiomsUnitCardTheme(background: Color(0xFFEAF2FF), accent: Color(0xFF3B82F6)),
  IdiomsUnitCardTheme(background: Color(0xFFFFEDF6), accent: Color(0xFFEC4899)),
  IdiomsUnitCardTheme(background: Color(0xFFE8FAF8), accent: Color(0xFF14B8A6)),
];

IdiomsUnitCardTheme idiomsThemeForUnit(int unit) {
  if (unit <= 0) return _kIdiomsUnitThemes.first;
  return _kIdiomsUnitThemes[(unit - 1) % _kIdiomsUnitThemes.length];
}

/// Unit grid card fill — tinted dark surfaces in night mode.
Color idiomsUnitCardSurface(BuildContext context, IdiomsUnitCardTheme theme) {
  if (Theme.of(context).brightness == Brightness.light) {
    return theme.background;
  }
  final scheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    theme.accent.withValues(alpha: 0.16),
    scheme.surfaceContainerHigh,
  );
}

BoxDecoration idiomsWordCardDecoration(IdiomsUnitCardTheme theme) {
  return BoxDecoration(color: theme.background);
}

List<BoxShadow> idiomsWordCardShadows(IdiomsUnitCardTheme theme) {
  return [
    BoxShadow(
      color: theme.accent.withValues(alpha: 0.12),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
