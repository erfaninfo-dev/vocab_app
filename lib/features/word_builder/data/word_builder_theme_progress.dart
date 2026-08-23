import '../domain/word_builder_models.dart';
import '../word_builder_theme_session_key.dart';

bool isThemeStageCompleted(
  WordBuilderPersistedProgress persisted,
  int levelId,
  int targetWordCount,
) {
  if (targetWordCount <= 0) return false;
  final lp = persisted.perLevel[levelId];
  if (lp == null) return false;
  return lp.solvedWordsLower.length >= targetWordCount;
}

bool isThemeStageUnlocked({
  required WordBuilderPersistedProgress persisted,
  required int categoryIndex,
  required int stage1Based,
  required List<int> targetCountsByStage,
  bool unlockAll = false,
}) {
  if (unlockAll) return true;
  if (stage1Based < 1 || stage1Based > targetCountsByStage.length) {
    return false;
  }
  if (stage1Based == 1) return true;
  final prevLevelId =
      wordBuilderThemeLevelId(categoryIndex, stage1Based - 1);
  final prevTargets = targetCountsByStage[stage1Based - 2];
  return isThemeStageCompleted(persisted, prevLevelId, prevTargets);
}

int clearedThemeStages({
  required WordBuilderPersistedProgress persisted,
  required int categoryIndex,
  required List<int> targetCountsByStage,
}) {
  var cleared = 0;
  for (var i = 0; i < targetCountsByStage.length; i++) {
    final levelId = wordBuilderThemeLevelId(categoryIndex, i + 1);
    if (isThemeStageCompleted(
      persisted,
      levelId,
      targetCountsByStage[i],
    )) {
      cleared++;
    } else {
      break;
    }
  }
  return cleared;
}
