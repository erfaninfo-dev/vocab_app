import '../../../l10n/app_localizations.dart';
import '../word_builder_constants.dart';

String? wordBuilderMeaningFromFeedback(String? code) {
  if (code == null || !code.startsWith(kWordBuilderMeaningPrefix)) {
    return null;
  }
  final text = code.substring(kWordBuilderMeaningPrefix.length).trim();
  return text.isEmpty ? null : text;
}

bool wordBuilderFeedbackIsMeaning(String? code) =>
    wordBuilderMeaningFromFeedback(code) != null;

String? localizeWordBuilderFeedback(AppLocalizations l10n, String? code) {
  if (code == null) return null;
  switch (code) {
    case '__correct':
      return null;
    case '__too_short':
      return l10n.wordBuilderTooShort;
    case '__already_found':
      return l10n.wordBuilderAlreadyFound;
    case '__try_again':
      return null;
    case '__hint_letter':
      return l10n.wordBuilderHintLetter;
    case '__hint_removed':
      return l10n.wordBuilderHintRemoved;
    case '__hint_remove_none':
      return l10n.wordBuilderHintRemoveNone;
    case '__not_enough_coins':
      return l10n.wordBuilderNotEnoughCoins;
    case '__all_levels_done':
      return l10n.wordBuilderAllLevelsDone;
  }
  if (wordBuilderFeedbackIsMeaning(code)) {
    return null;
  }
  return null;
}
