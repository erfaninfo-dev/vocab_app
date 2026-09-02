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
  // Server topics (Part 1)
  'internet': 'assets/idioms_units/technology_pic.webp',
  'praiseencouragement': 'assets/idioms_units/achievement_pic.webp',
  'holidays': 'assets/idioms_units/travel_pic.webp',
  'holiday': 'assets/idioms_units/travel_pic.webp',
  'library': 'assets/idioms_units/education_pic.webp',
  'libraries': 'assets/idioms_units/education_pic.webp',
  'smallbusiness': 'assets/idioms_units/work_pic.webp',
  'chocolates': 'assets/idioms_units/food_pic.webp',
  'chocolate': 'assets/idioms_units/food_pic.webp',
  'singing': 'assets/idioms_units/entertainment_pic.webp',
  'outerspaceandstars': 'assets/idioms_units/technology_pic.webp',
  'list': 'assets/idioms_units/education_pic.webp',
  'houseworkandcooking': 'assets/idioms_units/home_pic.webp',
  'textmessages': 'assets/idioms_units/communication_pic.webp',
  'beingbusy': 'assets/idioms_units/time_pic.webp',
  'puzzles': 'assets/idioms_units/problems_pic.webp',
  'sayingthankyou': 'assets/idioms_units/communication_pic.webp',
  'publictransportation': 'assets/idioms_units/transport_pic.webp',
  'names': 'assets/idioms_units/people_pic.webp',
  'jewelry': 'assets/idioms_units/shopping_pic.webp',
  'geography': 'assets/idioms_units/city_pic.webp',
  'flowers': 'assets/idioms_units/nature_pic.webp',
  'birthday': 'assets/idioms_units/positivefeeling_pic.webp',
  'planschedule': 'assets/idioms_units/futureplans_pic.webp',
  'sparetime': 'assets/idioms_units/entertainment_pic.webp',
  'spendingtimebyyourself': 'assets/idioms_units/home_pic.webp',
  'writing': 'assets/idioms_units/education_pic.webp',
  'weather': 'assets/idioms_units/weather_pic.webp',
  'snacks': 'assets/idioms_units/food_pic.webp',
  'patience': 'assets/idioms_units/opinion_pic.webp',
  'machine': 'assets/idioms_units/technology_pic.webp',
  'memory': 'assets/idioms_units/experience_pic.webp',
  'hatscaps': 'assets/idioms_units/shopping_pic.webp',
  'borrowinglending': 'assets/idioms_units/friendship_pic.webp',
  'colors': 'assets/idioms_units/entertainment_pic.webp',
  'hobby': 'assets/idioms_units/entertainment_pic.webp',
  'advertisement': 'assets/idioms_units/communication_pic.webp',
  'feelingbored': 'assets/idioms_units/negativefeeling_pic.webp',
  'friends': 'assets/idioms_units/friendship_pic.webp',
  'booksandreadinghabits': 'assets/idioms_units/education_pic.webp',
  'eveningtime': 'assets/idioms_units/time_pic.webp',
  'sittingdown': 'assets/idioms_units/home_pic.webp',
  'computers': 'assets/idioms_units/technology_pic.webp',
  'oldbuildings': 'assets/idioms_units/city_pic.webp',
  'collectingthings': 'assets/idioms_units/shopping_pic.webp',
  'artdrawing': 'assets/idioms_units/entertainment_pic.webp',
  'talents': 'assets/idioms_units/achievement_pic.webp',
  'watch': 'assets/idioms_units/time_pic.webp',
  'takingphotos': 'assets/idioms_units/technology_pic.webp',
  'cars': 'assets/idioms_units/transport_pic.webp',
  'lostandfound': 'assets/idioms_units/problems_pic.webp',
  'websites': 'assets/idioms_units/technology_pic.webp',
  'streetmarket': 'assets/idioms_units/shopping_pic.webp',
  'mobilephone': 'assets/idioms_units/technology_pic.webp',
  'timemanagement': 'assets/idioms_units/time_pic.webp',
  'sportsprograms': 'assets/idioms_units/health_pic.webp',
  'makingfriends': 'assets/idioms_units/friendship_pic.webp',
  'goodview': 'assets/idioms_units/nature_pic.webp',
  'laughing': 'assets/idioms_units/positivefeeling_pic.webp',
  'teamwork': 'assets/idioms_units/achievement_pic.webp',
  'fishing': 'assets/idioms_units/nature_pic.webp',
  'perfume': 'assets/idioms_units/shopping_pic.webp',
  'roadsandstreets': 'assets/idioms_units/transport_pic.webp',
  'coins': 'assets/idioms_units/money_pic.webp',
  'teachers': 'assets/idioms_units/education_pic.webp',
  'bikes': 'assets/idioms_units/transport_pic.webp',
  'transport': 'assets/idioms_units/transport_pic.webp',
  'challenges': 'assets/idioms_units/achievement_pic.webp',
  'askingforhelp': 'assets/idioms_units/friendship_pic.webp',
  'childhoodmemory': 'assets/idioms_units/experience_pic.webp',
  'plants': 'assets/idioms_units/nature_pic.webp',
  'excitingactivities': 'assets/idioms_units/entertainment_pic.webp',
  'stayingathome': 'assets/idioms_units/home_pic.webp',
  'sharing': 'assets/idioms_units/friendship_pic.webp',
  'morningroutine': 'assets/idioms_units/time_pic.webp',
  'art': 'assets/idioms_units/entertainment_pic.webp',
  'keys': 'assets/idioms_units/home_pic.webp',
  'numbers': 'assets/idioms_units/education_pic.webp',
  'science': 'assets/idioms_units/education_pic.webp',
  'news': 'assets/idioms_units/communication_pic.webp',
  'ebooksandpaperbooks': 'assets/idioms_units/education_pic.webp',
  'stayingup': 'assets/idioms_units/time_pic.webp',
  'language': 'assets/idioms_units/communication_pic.webp',
  'happythings': 'assets/idioms_units/positivefeeling_pic.webp',
  'penorpencil': 'assets/idioms_units/education_pic.webp',
  'stagesoflife': 'assets/idioms_units/age_pic.webp',
  'tshirts': 'assets/idioms_units/shopping_pic.webp',
  'weekends': 'assets/idioms_units/entertainment_pic.webp',
  'breakfast': 'assets/idioms_units/food_pic.webp',
  'videogames': 'assets/idioms_units/technology_pic.webp',
  'sunglasses': 'assets/idioms_units/shopping_pic.webp',
  'socialmedia': 'assets/idioms_units/technology_pic.webp',
  'cake': 'assets/idioms_units/food_pic.webp',
  'losingthings': 'assets/idioms_units/problems_pic.webp',
  'music': 'assets/idioms_units/entertainment_pic.webp',
  'crowdedplace': 'assets/idioms_units/city_pic.webp',
  'celebrity': 'assets/idioms_units/people_pic.webp',
  'running': 'assets/idioms_units/health_pic.webp',
  'chatting': 'assets/idioms_units/communication_pic.webp',
  'helpingothers': 'assets/idioms_units/friendship_pic.webp',
  'maps': 'assets/idioms_units/travel_pic.webp',
  'clothing': 'assets/idioms_units/shopping_pic.webp',
  'musicalinstruments': 'assets/idioms_units/entertainment_pic.webp',
  'noise': 'assets/idioms_units/problems_pic.webp',
  'teaandcoffee': 'assets/idioms_units/food_pic.webp',
  'robots': 'assets/idioms_units/technology_pic.webp',
  'gifts': 'assets/idioms_units/love_pic.webp',
  'films': 'assets/idioms_units/entertainment_pic.webp',
  'icecream': 'assets/idioms_units/food_pic.webp',
  'concentrate': 'assets/idioms_units/opinion_pic.webp',
  'fixingthings': 'assets/idioms_units/problems_pic.webp',
  'health': 'assets/idioms_units/health_pic.webp',
  'dream': 'assets/idioms_units/experience_pic.webp',
  'favouriteday': 'assets/idioms_units/positivefeeling_pic.webp',
  'rain': 'assets/idioms_units/weather_pic.webp',
  'dayoff': 'assets/idioms_units/entertainment_pic.webp',
  'bags': 'assets/idioms_units/shopping_pic.webp',
  'wildanimals': 'assets/idioms_units/nature_pic.webp',
  'school': 'assets/idioms_units/education_pic.webp',
  'highschool': 'assets/idioms_units/education_pic.webp',
  'technology': 'assets/idioms_units/technology_pic.webp',
  'emails': 'assets/idioms_units/communication_pic.webp',
  'rainydays': 'assets/idioms_units/weather_pic.webp',
  // Common IELTS Part 1 topics (legacy / extras)
  'work': 'assets/idioms_units/work_pic.webp',
  'workcareer': 'assets/idioms_units/work_pic.webp',
  'job': 'assets/idioms_units/work_pic.webp',
  'business': 'assets/idioms_units/work_pic.webp',
  'hometown': 'assets/idioms_units/city_pic.webp',
  'hometowncity': 'assets/idioms_units/city_pic.webp',
  'city': 'assets/idioms_units/city_pic.webp',
  'cities': 'assets/idioms_units/city_pic.webp',
  'home': 'assets/idioms_units/home_pic.webp',
  'family': 'assets/idioms_units/home_pic.webp',
  'food': 'assets/idioms_units/food_pic.webp',
  'sport': 'assets/idioms_units/health_pic.webp',
  'sports': 'assets/idioms_units/health_pic.webp',
  'travel': 'assets/idioms_units/travel_pic.webp',
  'shopping': 'assets/idioms_units/shopping_pic.webp',
  'online': 'assets/idioms_units/technology_pic.webp',
  'friendship': 'assets/idioms_units/friendship_pic.webp',
  'money': 'assets/idioms_units/money_pic.webp',
  'education': 'assets/idioms_units/education_pic.webp',
  'study': 'assets/idioms_units/education_pic.webp',
  'studying': 'assets/idioms_units/education_pic.webp',
  'nature': 'assets/idioms_units/nature_pic.webp',
  'environment': 'assets/idioms_units/environment_pic.webp',
  'communication': 'assets/idioms_units/communication_pic.webp',
  'people': 'assets/idioms_units/people_pic.webp',
  'personality': 'assets/idioms_units/people_pic.webp',
  'time': 'assets/idioms_units/time_pic.webp',
  'age': 'assets/idioms_units/age_pic.webp',
  'future': 'assets/idioms_units/futureplans_pic.webp',
  'futureplans': 'assets/idioms_units/futureplans_pic.webp',
  'experience': 'assets/idioms_units/experience_pic.webp',
  'memories': 'assets/idioms_units/experience_pic.webp',
  'opinion': 'assets/idioms_units/opinion_pic.webp',
  'opinions': 'assets/idioms_units/opinion_pic.webp',
  'love': 'assets/idioms_units/love_pic.webp',
  'relationships': 'assets/idioms_units/love_pic.webp',
  'feelings': 'assets/idioms_units/positivefeeling_pic.webp',
  'positivefeelings': 'assets/idioms_units/positivefeeling_pic.webp',
  'negativefeelings': 'assets/idioms_units/negativefeeling_pic.webp',
  'stress': 'assets/idioms_units/problems_pic.webp',
  'problems': 'assets/idioms_units/problems_pic.webp',
  'achievement': 'assets/idioms_units/achievement_pic.webp',
  'success': 'assets/idioms_units/achievement_pic.webp',
  'entertainment': 'assets/idioms_units/entertainment_pic.webp',
  'freetime': 'assets/idioms_units/entertainment_pic.webp',
};

/// Keyword fallbacks when slug is not an exact map key (checked in order).
const _kSpeakingAssetKeywordRules = <(String keyword, String asset)>[
  // Multi-word / partial titles
  ('childhood', 'assets/idioms_units/experience_pic.webp'),
  ('transportation', 'assets/idioms_units/transport_pic.webp'),
  ('socialmedia', 'assets/idioms_units/technology_pic.webp'),
  ('videogame', 'assets/idioms_units/technology_pic.webp'),
  ('ebook', 'assets/idioms_units/education_pic.webp'),
  ('paperbook', 'assets/idioms_units/education_pic.webp'),
  ('reading', 'assets/idioms_units/education_pic.webp'),
  ('housework', 'assets/idioms_units/home_pic.webp'),
  ('cooking', 'assets/idioms_units/food_pic.webp'),
  ('outerspace', 'assets/idioms_units/technology_pic.webp'),
  ('space', 'assets/idioms_units/technology_pic.webp'),
  ('celebrity', 'assets/idioms_units/people_pic.webp'),
  ('musical', 'assets/idioms_units/entertainment_pic.webp'),
  ('instrument', 'assets/idioms_units/entertainment_pic.webp'),
  ('photograph', 'assets/idioms_units/technology_pic.webp'),
  ('mobile', 'assets/idioms_units/technology_pic.webp'),
  ('computer', 'assets/idioms_units/technology_pic.webp'),
  ('website', 'assets/idioms_units/technology_pic.webp'),
  ('robot', 'assets/idioms_units/technology_pic.webp'),
  ('email', 'assets/idioms_units/communication_pic.webp'),
  ('message', 'assets/idioms_units/communication_pic.webp'),
  ('chat', 'assets/idioms_units/communication_pic.webp'),
  ('thank', 'assets/idioms_units/communication_pic.webp'),
  ('advert', 'assets/idioms_units/communication_pic.webp'),
  ('language', 'assets/idioms_units/communication_pic.webp'),
  ('news', 'assets/idioms_units/communication_pic.webp'),
  ('chocolate', 'assets/idioms_units/food_pic.webp'),
  ('snack', 'assets/idioms_units/food_pic.webp'),
  ('breakfast', 'assets/idioms_units/food_pic.webp'),
  ('coffee', 'assets/idioms_units/food_pic.webp'),
  ('icecream', 'assets/idioms_units/food_pic.webp'),
  ('cake', 'assets/idioms_units/food_pic.webp'),
  ('fishing', 'assets/idioms_units/nature_pic.webp'),
  ('flower', 'assets/idioms_units/nature_pic.webp'),
  ('plant', 'assets/idioms_units/nature_pic.webp'),
  ('animal', 'assets/idioms_units/nature_pic.webp'),
  ('rain', 'assets/idioms_units/weather_pic.webp'),
  ('library', 'assets/idioms_units/education_pic.webp'),
  ('school', 'assets/idioms_units/education_pic.webp'),
  ('teacher', 'assets/idioms_units/education_pic.webp'),
  ('science', 'assets/idioms_units/education_pic.webp'),
  ('writing', 'assets/idioms_units/education_pic.webp'),
  ('holiday', 'assets/idioms_units/travel_pic.webp'),
  ('praise', 'assets/idioms_units/achievement_pic.webp'),
  ('encourag', 'assets/idioms_units/achievement_pic.webp'),
  ('talent', 'assets/idioms_units/achievement_pic.webp'),
  ('teamwork', 'assets/idioms_units/achievement_pic.webp'),
  ('challenge', 'assets/idioms_units/achievement_pic.webp'),
  ('business', 'assets/idioms_units/work_pic.webp'),
  ('market', 'assets/idioms_units/shopping_pic.webp'),
  ('cloth', 'assets/idioms_units/shopping_pic.webp'),
  ('jewel', 'assets/idioms_units/shopping_pic.webp'),
  ('perfume', 'assets/idioms_units/shopping_pic.webp'),
  ('sunglass', 'assets/idioms_units/shopping_pic.webp'),
  ('collect', 'assets/idioms_units/shopping_pic.webp'),
  ('shirt', 'assets/idioms_units/shopping_pic.webp'),
  ('bag', 'assets/idioms_units/shopping_pic.webp'),
  ('coin', 'assets/idioms_units/money_pic.webp'),
  ('bored', 'assets/idioms_units/negativefeeling_pic.webp'),
  ('happy', 'assets/idioms_units/positivefeeling_pic.webp'),
  ('laugh', 'assets/idioms_units/positivefeeling_pic.webp'),
  ('dream', 'assets/idioms_units/experience_pic.webp'),
  ('memory', 'assets/idioms_units/experience_pic.webp'),
  ('borrow', 'assets/idioms_units/friendship_pic.webp'),
  ('lend', 'assets/idioms_units/friendship_pic.webp'),
  ('help', 'assets/idioms_units/friendship_pic.webp'),
  ('share', 'assets/idioms_units/friendship_pic.webp'),
  ('friend', 'assets/idioms_units/friendship_pic.webp'),
  ('gift', 'assets/idioms_units/love_pic.webp'),
  ('hometown', 'assets/idioms_units/city_pic.webp'),
  ('geograph', 'assets/idioms_units/city_pic.webp'),
  ('crowded', 'assets/idioms_units/city_pic.webp'),
  ('building', 'assets/idioms_units/city_pic.webp'),
  ('street', 'assets/idioms_units/transport_pic.webp'),
  ('road', 'assets/idioms_units/transport_pic.webp'),
  ('bike', 'assets/idioms_units/transport_pic.webp'),
  ('car', 'assets/idioms_units/transport_pic.webp'),
  ('weather', 'assets/idioms_units/weather_pic.webp'),
  ('transport', 'assets/idioms_units/transport_pic.webp'),
  ('running', 'assets/idioms_units/health_pic.webp'),
  ('sport', 'assets/idioms_units/health_pic.webp'),
  ('health', 'assets/idioms_units/health_pic.webp'),
  ('routine', 'assets/idioms_units/time_pic.webp'),
  ('schedule', 'assets/idioms_units/futureplans_pic.webp'),
  ('weekend', 'assets/idioms_units/entertainment_pic.webp'),
  ('evening', 'assets/idioms_units/time_pic.webp'),
  ('morning', 'assets/idioms_units/time_pic.webp'),
  ('busy', 'assets/idioms_units/time_pic.webp'),
  ('family', 'assets/idioms_units/home_pic.webp'),
  ('home', 'assets/idioms_units/home_pic.webp'),
  ('singing', 'assets/idioms_units/entertainment_pic.webp'),
  ('music', 'assets/idioms_units/entertainment_pic.webp'),
  ('film', 'assets/idioms_units/entertainment_pic.webp'),
  ('hobby', 'assets/idioms_units/entertainment_pic.webp'),
  ('art', 'assets/idioms_units/entertainment_pic.webp'),
  ('puzzle', 'assets/idioms_units/problems_pic.webp'),
  ('noise', 'assets/idioms_units/problems_pic.webp'),
  ('lost', 'assets/idioms_units/problems_pic.webp'),
  ('fix', 'assets/idioms_units/problems_pic.webp'),
  ('concentr', 'assets/idioms_units/opinion_pic.webp'),
  ('patience', 'assets/idioms_units/opinion_pic.webp'),
  ('stage', 'assets/idioms_units/age_pic.webp'),
  ('food', 'assets/idioms_units/food_pic.webp'),
  ('study', 'assets/idioms_units/education_pic.webp'),
  ('work', 'assets/idioms_units/work_pic.webp'),
  ('travel', 'assets/idioms_units/travel_pic.webp'),
  ('map', 'assets/idioms_units/travel_pic.webp'),
  ('shop', 'assets/idioms_units/shopping_pic.webp'),
  ('money', 'assets/idioms_units/money_pic.webp'),
  ('tech', 'assets/idioms_units/technology_pic.webp'),
  ('internet', 'assets/idioms_units/technology_pic.webp'),
  ('online', 'assets/idioms_units/technology_pic.webp'),
  ('nature', 'assets/idioms_units/nature_pic.webp'),
  ('city', 'assets/idioms_units/city_pic.webp'),
  ('name', 'assets/idioms_units/people_pic.webp'),
  ('people', 'assets/idioms_units/people_pic.webp'),
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

/// Card/topic titles — aligned with idioms unit cards (not full-strength onSurface).
Color speakingCardTitleColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88);

/// Secondary titles under accent labels (model chip, previews).
Color speakingCardSubtitleColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.76);

const _kSpeakingQuestionAccentColors = <Color>[
  Color(0xFF3B82F6),
  Color(0xFF22C55E),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
];

Color speakingQuestionAccentColor(int index) {
  if (index <= 0) return _kSpeakingQuestionAccentColors.first;
  return _kSpeakingQuestionAccentColors[
    (index - 1) % _kSpeakingQuestionAccentColors.length
  ];
}

Color speakingQuestionsTitleColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  return brightness == Brightness.light
      ? const Color(0xFF1E3A5F)
      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92);
}

/// Finds the outer vertical scroll view (skips nested non-scrollable lists).
ScrollPosition? speakingParentScrollPosition(BuildContext context) {
  ScrollPosition? result;

  context.visitAncestorElements((element) {
    if (element is! StatefulElement) return true;
    final state = element.state;
    if (state is! ScrollableState) return true;

    final position = state.position;
    if (position.axis != Axis.vertical) return true;
    if (position.physics is NeverScrollableScrollPhysics) return true;

    result = position;
    return false;
  });

  return result;
}

/// Keeps the list offset fixed while a card grows downward.
SpeakingListScrollLock? lockSpeakingListScrollOffset(BuildContext context) {
  final position = speakingParentScrollPosition(context);
  if (position == null || !position.hasPixels) return null;

  return SpeakingListScrollLock._(position, position.pixels);
}

/// Prevents list jump when a speaking question card grows — keeps the card top
/// anchored and lets expansion continue downward only.
void preserveSpeakingListScrollOffset(BuildContext context) {
  lockSpeakingListScrollOffset(context)?.releaseAfterLayout();
}

/// Holds scroll offset across one or more layout passes after expand/collapse.
class SpeakingListScrollLock {
  SpeakingListScrollLock._(this._position, this._lockedOffset)
    : _hold = _position.hold(() {});

  final ScrollPosition _position;
  final double _lockedOffset;
  final ScrollHoldController _hold;
  var _released = false;

  void releaseAfterLayout({int frameCount = 3}) {
    void restoreFrame(int remaining) {
      if (_released || !(_position.hasPixels)) return;

      final target = _lockedOffset.clamp(
        _position.minScrollExtent,
        _position.maxScrollExtent,
      );
      if ((_position.pixels - target).abs() > 0.5) {
        _position.jumpTo(target);
      }

      if (remaining <= 1) {
        _released = true;
        _hold.cancel();
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => restoreFrame(remaining - 1),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => restoreFrame(frameCount));
  }
}
