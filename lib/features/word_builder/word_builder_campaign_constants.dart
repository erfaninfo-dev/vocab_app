const int kWordBuilderStagesPerTier = 50;

/// SharedPreferences key: XOR'd into the campaign plan RNG so a lobby Reset
/// rebuilds stages with a fresh word set (not the forever-stable catalog seed).
const String kWordBuilderCampaignPlanSeedPrefsKey =
    'word_builder_campaign_plan_seed_v1';

/// Max target words per campaign stage (beginner / intermediate / advanced).
const int kWordBuilderCampaignWordsPerStage = 3;

const int kWordBuilderBeginnerMaxThreeLetterQuestions =
    kWordBuilderCampaignWordsPerStage;
const int kWordBuilderIntermediateWordsPerStage =
    kWordBuilderCampaignWordsPerStage;
const int kWordBuilderAdvancedWordsPerStage =
    kWordBuilderCampaignWordsPerStage;

/// [WordBuilderLevel.levelId] for campaign stages (see [buildCampaignStageLevel]).
const int kWordBuilderCampaignLevelIdMin = 900000001;
const int kWordBuilderCampaignLevelIdMax = 900000100;

bool isWordBuilderCampaignPersistedLevelId(int levelId) =>
    levelId >= kWordBuilderCampaignLevelIdMin &&
    levelId <= kWordBuilderCampaignLevelIdMax;
