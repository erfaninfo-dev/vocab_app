import '../../core/language/language_provider.dart';
import 'speaking_question.dart';

extension SpeakingQuestionLang on SpeakingQuestion {
  /// Localized sample answer for [lang]; falls back to the other local language.
  String answerTranslationFor(TranslationLang lang) {
    final fa = faAnswer.trim();
    final kur = kurAnswer.trim();
    if (lang == TranslationLang.kur) {
      if (kur.isNotEmpty) return kur;
      return fa;
    }
    if (fa.isNotEmpty) return fa;
    return kur;
  }
}
