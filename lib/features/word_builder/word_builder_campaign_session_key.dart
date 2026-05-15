import 'domain/word_builder_models.dart';
import 'word_builder_campaign_constants.dart';

const int kWordBuilderCampaignSessionKeyLegacyMin = 1900000000;
const int kWordBuilderCampaignSessionKeyLegacyMax = 1900000999;

const int kWordBuilderCampaignSessionKeyMin = 1900010000;
const int kWordBuilderCampaignSessionKeyMax = 1900010999;

const int _kCampaignSessionSlot = 64;

int encodeWordBuilderCampaignSessionKey(
  WordBuilderDifficulty difficulty,
  int stage1Based,
) {
  assert(stage1Based >= 1 && stage1Based <= kWordBuilderStagesPerTier);
  assert(difficulty.index >= 0 &&
      difficulty.index < WordBuilderDifficulty.values.length);
  return kWordBuilderCampaignSessionKeyMin +
      difficulty.index * _kCampaignSessionSlot +
      stage1Based;
}

({WordBuilderDifficulty difficulty, int stage1Based})?
    decodeWordBuilderCampaignSessionKey(int key) {
  if (key >= kWordBuilderCampaignSessionKeyMin &&
      key <= kWordBuilderCampaignSessionKeyMax) {
    final rel = key - kWordBuilderCampaignSessionKeyMin;
    final dIdx = rel ~/ _kCampaignSessionSlot;
    final stage = rel % _kCampaignSessionSlot;
    if (dIdx < 0 ||
        dIdx >= WordBuilderDifficulty.values.length ||
        stage < 1 ||
        stage > kWordBuilderStagesPerTier) {
      return null;
    }
    return (
      difficulty: WordBuilderDifficulty.values[dIdx],
      stage1Based: stage,
    );
  }
  if (key >= kWordBuilderCampaignSessionKeyLegacyMin &&
      key <= kWordBuilderCampaignSessionKeyLegacyMax) {
    final rel = key - kWordBuilderCampaignSessionKeyLegacyMin;
    final dIdx = rel ~/ 20;
    final stage = rel % 20;
    if (dIdx < 0 ||
        dIdx >= WordBuilderDifficulty.values.length ||
        stage < 1 ||
        stage > 10) {
      return null;
    }
    return (
      difficulty: WordBuilderDifficulty.values[dIdx],
      stage1Based: stage,
    );
  }
  return null;
}

bool isWordBuilderCampaignSessionKey(int key) =>
    decodeWordBuilderCampaignSessionKey(key) != null;
