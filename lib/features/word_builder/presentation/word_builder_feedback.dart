import '../../../l10n/app_localizations.dart';
import '../word_builder_constants.dart';

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
    case '__all_levels_done':
      return l10n.wordBuilderAllLevelsDone;
  }
  if (code.startsWith(kWordBuilderMeaningPrefix)) {
    return l10n.wordBuilderHintMeaningLine(
      code.substring(kWordBuilderMeaningPrefix.length),
    );
  }
  return null;
}
