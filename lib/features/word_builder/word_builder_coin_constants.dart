import 'word_builder_constants.dart';

const int kWordBuilderCoinsInitialBalance = 36;

int wordBuilderCoinsPerCorrectWord() =>
    kWordBuilderWordsPerLevel * 4;

int wordBuilderCoinsLevelCompleteBonus() =>
    kWordBuilderWordsPerLevel * 3;

int wordBuilderCoinsCostHintLetter() =>
    kWordBuilderWordsPerLevel * 2;

int wordBuilderCoinsCostHintMeaning() =>
    kWordBuilderWordsPerLevel * 4;

int wordBuilderCoinsCostHintRemoveWrong() =>
    kWordBuilderWordsPerLevel * 2;

/// Extra coins for an Arkanoid word solved with no rejects on that attempt.
int wordBuilderCoinsArkanoidPerfectBonus() => kWordBuilderWordsPerLevel;
