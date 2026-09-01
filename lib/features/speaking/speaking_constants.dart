import 'package:flutter/material.dart';

import '../units/idioms/idioms_units_constants.dart';

const int kSpeakingPart1 = 1;

enum SpeakingPart1BrowseMode { topics, modelQuestions }

const double kSpeakingCardReferenceWidth = 175;
const double kSpeakingScreenReferenceWidth = 390;
const double kSpeakingTopicCardMaxWidth = 200;
const double kSpeakingTopicCardAspectRatio = 0.9;

double speakingCardScale(double cardWidth) =>
    (cardWidth / kSpeakingCardReferenceWidth).clamp(0.52, 1.05);

double speakingScreenScale(double screenWidth) =>
    (screenWidth / kSpeakingScreenReferenceWidth).clamp(0.75, 1.0);

int speakingTopicsGridCrossAxisCount({
  required double viewportWidth,
  required double horizontalPadding,
  required double spacing,
}) {
  final inner = (viewportWidth - horizontalPadding).clamp(0, double.infinity);
  final count =
      ((inner + spacing) / (kSpeakingTopicCardMaxWidth + spacing)).floor();
  return count.clamp(2, 6);
}

const double kSpeakingImageSlotWidthFactor = 0.68;
const double kSpeakingImageSlotHeightFactor = 0.5;

String _speakingTopicSlug(String title) {
  return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Speaking Part 1 topic title → best-matching illustration from idioms pool.
const _kSpeakingAssetBySlug = <String, String>{
  // Current Part 1 topics
  'praiseencouragement': 'assets/idioms_units/achievement_pic.png',
  'holidays': 'assets/idioms_units/travel_pic.png',
  'holiday': 'assets/idioms_units/travel_pic.png',
  'library': 'assets/idioms_units/education_pic.png',
  'libraries': 'assets/idioms_units/education_pic.png',
  'smallbusiness': 'assets/idioms_units/work_pic.png',
  'business': 'assets/idioms_units/work_pic.png',
  'chocolates': 'assets/idioms_units/food_pic.png',
  'chocolate': 'assets/idioms_units/food_pic.png',
  // Common IELTS Part 1 topics
  'work': 'assets/idioms_units/work_pic.png',
  'workcareer': 'assets/idioms_units/work_pic.png',
  'job': 'assets/idioms_units/work_pic.png',
  'hometown': 'assets/idioms_units/city_pic.png',
  'hometowncity': 'assets/idioms_units/city_pic.png',
  'city': 'assets/idioms_units/city_pic.png',
  'cities': 'assets/idioms_units/city_pic.png',
  'home': 'assets/idioms_units/home_pic.png',
  'family': 'assets/idioms_units/home_pic.png',
  'food': 'assets/idioms_units/food_pic.png',
  'music': 'assets/idioms_units/entertainment_pic.png',
  'weather': 'assets/idioms_units/weather_pic.png',
  'travel': 'assets/idioms_units/travel_pic.png',
  'transport': 'assets/idioms_units/transport_pic.png',
  'shopping': 'assets/idioms_units/shopping_pic.png',
  'health': 'assets/idioms_units/health_pic.png',
  'sport': 'assets/idioms_units/health_pic.png',
  'sports': 'assets/idioms_units/health_pic.png',
  'technology': 'assets/idioms_units/technology_pic.png',
  'friends': 'assets/idioms_units/friendship_pic.png',
  'friendship': 'assets/idioms_units/friendship_pic.png',
  'money': 'assets/idioms_units/money_pic.png',
  'education': 'assets/idioms_units/education_pic.png',
  'study': 'assets/idioms_units/education_pic.png',
  'studying': 'assets/idioms_units/education_pic.png',
  'nature': 'assets/idioms_units/nature_pic.png',
  'environment': 'assets/idioms_units/environment_pic.png',
  'communication': 'assets/idioms_units/communication_pic.png',
  'people': 'assets/idioms_units/people_pic.png',
  'personality': 'assets/idioms_units/people_pic.png',
  'time': 'assets/idioms_units/time_pic.png',
  'age': 'assets/idioms_units/age_pic.png',
  'future': 'assets/idioms_units/futureplans_pic.png',
  'futureplans': 'assets/idioms_units/futureplans_pic.png',
  'experience': 'assets/idioms_units/experience_pic.png',
  'memories': 'assets/idioms_units/experience_pic.png',
  'opinion': 'assets/idioms_units/opinion_pic.png',
  'opinions': 'assets/idioms_units/opinion_pic.png',
  'love': 'assets/idioms_units/love_pic.png',
  'relationships': 'assets/idioms_units/love_pic.png',
  'feelings': 'assets/idioms_units/positivefeeling_pic.png',
  'positivefeelings': 'assets/idioms_units/positivefeeling_pic.png',
  'negativefeelings': 'assets/idioms_units/negativefeeling_pic.png',
  'stress': 'assets/idioms_units/problems_pic.png',
  'problems': 'assets/idioms_units/problems_pic.png',
  'achievement': 'assets/idioms_units/achievement_pic.png',
  'success': 'assets/idioms_units/achievement_pic.png',
  'entertainment': 'assets/idioms_units/entertainment_pic.png',
  'freetime': 'assets/idioms_units/entertainment_pic.png',
};

/// Keyword fallbacks when slug is not an exact map key (checked in order).
const _kSpeakingAssetKeywordRules = <(String keyword, String asset)>[
  ('chocolate', 'assets/idioms_units/food_pic.png'),
  ('library', 'assets/idioms_units/education_pic.png'),
  ('holiday', 'assets/idioms_units/travel_pic.png'),
  ('praise', 'assets/idioms_units/achievement_pic.png'),
  ('encourag', 'assets/idioms_units/achievement_pic.png'),
  ('business', 'assets/idioms_units/work_pic.png'),
  ('hometown', 'assets/idioms_units/city_pic.png'),
  ('weather', 'assets/idioms_units/weather_pic.png'),
  ('transport', 'assets/idioms_units/transport_pic.png'),
  ('friend', 'assets/idioms_units/friendship_pic.png'),
  ('family', 'assets/idioms_units/home_pic.png'),
  ('food', 'assets/idioms_units/food_pic.png'),
  ('music', 'assets/idioms_units/entertainment_pic.png'),
  ('health', 'assets/idioms_units/health_pic.png'),
  ('sport', 'assets/idioms_units/health_pic.png'),
  ('study', 'assets/idioms_units/education_pic.png'),
  ('work', 'assets/idioms_units/work_pic.png'),
  ('travel', 'assets/idioms_units/travel_pic.png'),
  ('shop', 'assets/idioms_units/shopping_pic.png'),
  ('money', 'assets/idioms_units/money_pic.png'),
  ('tech', 'assets/idioms_units/technology_pic.png'),
  ('nature', 'assets/idioms_units/nature_pic.png'),
  ('city', 'assets/idioms_units/city_pic.png'),
];

/// Maps topic title to the closest idioms illustration asset.
String? speakingTopicAssetPath(int topicId, {required String title}) {
  final slug = _speakingTopicSlug(title);
  if (slug.isNotEmpty) {
    final direct = _kSpeakingAssetBySlug[slug];
    if (direct != null) return direct;

    for (final rule in _kSpeakingAssetKeywordRules) {
      if (slug.contains(rule.$1)) return rule.$2;
    }
  }

  if (topicId <= 0) return kIdiomsUnitArtPool.first;

  final index = (topicId * 7 + 1) % kIdiomsUnitArtPool.length;
  return kIdiomsUnitArtPool[index];
}

class SpeakingTopicCardTheme {
  const SpeakingTopicCardTheme({
    required this.background,
    required this.accent,
    required this.glow,
  });

  final Color background;
  final Color accent;
  final Color glow;
}

const _kSpeakingTopicThemes = <SpeakingTopicCardTheme>[
  SpeakingTopicCardTheme(
    background: Color(0xFFE6FAF8),
    accent: Color(0xFF0D9488),
    glow: Color(0xFF5EEAD4),
  ),
  SpeakingTopicCardTheme(
    background: Color(0xFFEAF4FF),
    accent: Color(0xFF0284C7),
    glow: Color(0xFF7DD3FC),
  ),
  SpeakingTopicCardTheme(
    background: Color(0xFFF3EEFF),
    accent: Color(0xFF7C3AED),
    glow: Color(0xFFC4B5FD),
  ),
  SpeakingTopicCardTheme(
    background: Color(0xFFFFF4E8),
    accent: Color(0xFFEA580C),
    glow: Color(0xFFFDBA74),
  ),
  SpeakingTopicCardTheme(
    background: Color(0xFFEEFDF3),
    accent: Color(0xFF16A34A),
    glow: Color(0xFF86EFAC),
  ),
  SpeakingTopicCardTheme(
    background: Color(0xFFFFEEF5),
    accent: Color(0xFFDB2777),
    glow: Color(0xFFF9A8D4),
  ),
];

SpeakingTopicCardTheme speakingThemeForTopic(int topicId) {
  if (topicId <= 0) return _kSpeakingTopicThemes.first;
  return _kSpeakingTopicThemes[(topicId - 1) % _kSpeakingTopicThemes.length];
}

Color speakingTopicCardSurface(
  BuildContext context,
  SpeakingTopicCardTheme theme,
) {
  if (Theme.of(context).brightness == Brightness.light) {
    return theme.background;
  }
  final scheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    theme.accent.withValues(alpha: 0.18),
    scheme.surfaceContainerHigh,
  );
}

const Color kSpeakingBrandTeal = Color(0xFF0D9488);
const Color kSpeakingBrandCyan = Color(0xFF06B6D4);
