/// Reserved [WordBuilderGameNotifier] session-key range for themed
/// (non-campaign, non-book) categories such as "Animals" or "Food".
///
/// Kept well outside [kWordBuilderCampaignSessionKeyMin]..Max and far above
/// any real server book id (small positive ints) or [kWordBuilderAllBooksKey]
/// (-1).
///
/// The category *list itself* now comes from the server (or a bundled
/// fallback) and can grow without an app release, so this range only bounds
/// the reserved key-space (up to 1000 categories) — it does not know how many
/// categories currently exist. Callers must still bounds-check the decoded
/// index against whatever category list they resolved.
const int kWordBuilderThemeSessionKeyMin = 1900020000;
const int kWordBuilderThemeSessionKeyMax = 1900020999;

int encodeWordBuilderThemeSessionKey(int categoryIndex) {
  assert(
    categoryIndex >= 0 &&
        categoryIndex <=
            kWordBuilderThemeSessionKeyMax - kWordBuilderThemeSessionKeyMin,
  );
  return kWordBuilderThemeSessionKeyMin + categoryIndex;
}

/// Returns the theme category index encoded in [key], or null if [key] isn't
/// a themed-category session key. Does NOT validate the index against the
/// current category list length — callers must do that themselves.
int? decodeWordBuilderThemeSessionKey(int key) {
  if (key < kWordBuilderThemeSessionKeyMin ||
      key > kWordBuilderThemeSessionKeyMax) {
    return null;
  }
  return key - kWordBuilderThemeSessionKeyMin;
}

/// Persisted [WordBuilderLevel.levelId] range for themed categories (Animals, …).
/// Keeps theme progress separate from campaign (`900000xxx`) and book sessions.
const int kWordBuilderThemeLevelIdBase = 1900030000;

int wordBuilderThemeLevelId(int categoryIndex, int stage1Based) {
  assert(categoryIndex >= 0 && categoryIndex <= 999);
  assert(stage1Based >= 1 && stage1Based <= 999);
  return kWordBuilderThemeLevelIdBase + categoryIndex * 1000 + stage1Based;
}

bool isWordBuilderThemePersistedLevelId(int levelId) {
  return levelId >= kWordBuilderThemeLevelIdBase &&
      levelId < kWordBuilderThemeLevelIdBase + 1000 * 1000;
}

/// Per-stage session keys: category × stage (up to 127 stages per topic).
const int kWordBuilderThemeStageSessionKeyMin = 1900040000;
const int _kThemeSessionCategorySlot = 128;
const int kWordBuilderThemeMaxCategories = 128;
const int kWordBuilderThemeStageSessionKeyMax =
    kWordBuilderThemeStageSessionKeyMin +
    kWordBuilderThemeMaxCategories * _kThemeSessionCategorySlot +
    _kThemeSessionCategorySlot -
    1;

int encodeWordBuilderThemeStageSessionKey(
  int categoryIndex,
  int stage1Based,
) {
  assert(categoryIndex >= 0 && categoryIndex < kWordBuilderThemeMaxCategories);
  assert(stage1Based >= 1 && stage1Based < _kThemeSessionCategorySlot);
  return kWordBuilderThemeStageSessionKeyMin +
      categoryIndex * _kThemeSessionCategorySlot +
      stage1Based;
}

({int categoryIndex, int stage1Based})? decodeWordBuilderThemeStageSessionKey(
  int key,
) {
  if (key < kWordBuilderThemeStageSessionKeyMin ||
      key > kWordBuilderThemeStageSessionKeyMax) {
    return null;
  }
  final rel = key - kWordBuilderThemeStageSessionKeyMin;
  final categoryIndex = rel ~/ _kThemeSessionCategorySlot;
  final stage1Based = rel % _kThemeSessionCategorySlot;
  if (stage1Based < 1) return null;
  return (categoryIndex: categoryIndex, stage1Based: stage1Based);
}

bool isWordBuilderThemeStageSessionKey(int key) =>
    decodeWordBuilderThemeStageSessionKey(key) != null;
