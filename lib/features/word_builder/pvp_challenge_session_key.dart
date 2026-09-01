/// Reserved [WordBuilderGameNotifier] session-key range for PvP challenges.
const int kPvpChallengeSessionKeyMin = 1900050000;
const int kPvpChallengeSessionKeyMax = 1900059999;

int encodePvpChallengeSessionKey(int matchId) {
  assert(matchId > 0 && matchId <= kPvpChallengeSessionKeyMax - kPvpChallengeSessionKeyMin);
  return kPvpChallengeSessionKeyMin + matchId;
}

int? decodePvpChallengeSessionKey(int key) {
  if (key < kPvpChallengeSessionKeyMin || key > kPvpChallengeSessionKeyMax) {
    return null;
  }
  return key - kPvpChallengeSessionKeyMin;
}

bool isPvpChallengeSessionKey(int key) =>
    decodePvpChallengeSessionKey(key) != null;

const int kPvpChallengeLevelIdBase = 1900060000;

int pvpChallengeLevelId(int matchId) => kPvpChallengeLevelIdBase + matchId;
