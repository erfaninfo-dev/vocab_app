// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get appTitle => 'وشەکانی پێویستی ئایێڵتس';

  @override
  String get tabHome => 'سەرەکی';

  @override
  String get tabGrammar => 'ڕێزمان';

  @override
  String get tabReview => 'پێداچوونەوە';

  @override
  String get tabProgress => 'پێشکەوتن';

  @override
  String get tabSettings => 'ڕێکخستنەکان';

  @override
  String get back => 'گەڕانەوە';

  @override
  String get next => 'دواتر';

  @override
  String get skip => 'فەوتی کردن';

  @override
  String get cancel => 'هەڵوەشاندنەوە';

  @override
  String get continueLabel => 'بەردەوامبوون';

  @override
  String get close => 'داخستن';

  @override
  String get retry => 'دووبارە هەوڵ بدە';

  @override
  String get loading => 'بارکردن…';

  @override
  String get search => 'گەڕان';

  @override
  String get errorGeneric => 'کێشەیەک ڕوویدا. تکایە دووبارە هەوڵ بدە.';

  @override
  String get splashTagline => 'ڕاهێنانی وشە بە ئارامی و تەرکیز';

  @override
  String get languageSelectionTitle => 'زمانی بەرنامە هەڵبژێرە';

  @override
  String get languageSelectionSubtitle =>
      'هەر کات لە ڕێکخستنەکان دەتوانیت بیگۆڕیت.';

  @override
  String get langEnglish => 'English';

  @override
  String get langPersian => 'فارسی';

  @override
  String get langKurdishSorani => 'کوردی (سورانی)';

  @override
  String get chooseYourBook => 'کتێبەکەت هەڵبژێرە';

  @override
  String booksAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کتێب بەردەستە',
      one: '١ کتێب بەردەستە',
      zero: 'هیچ کتێبێک نییە',
    );
    return '$_temp0';
  }

  @override
  String get searchBooksHint => 'گەڕان لە کتێبەکان…';

  @override
  String get couldNotLoadBooks => 'بارکردنی کتێبەکان سەرکەوتوو نەبوو.';

  @override
  String couldNotLoadBooksWithError(String error) {
    return 'بارکردنی کتێبەکان سەرکەوتوو نەبوو.\n$error';
  }

  @override
  String get noBooksFound => 'هیچ کتێبێک نەدۆزرایەوە';

  @override
  String get bookSingular => 'کتێب';

  @override
  String get bookPlural => 'کتێب';

  @override
  String get unitSingular => 'یەکە';

  @override
  String get unitPlural => 'یەکەکان';

  @override
  String get loadingEllipsis => 'بارکردن…';

  @override
  String get tapToOpen => 'بگرە بۆ کردنەوە';

  @override
  String get grammarPracticeTitle => 'ڕاهێنانی ڕێزمان';

  @override
  String get grammarPracticeSubtitle =>
      'پرسیارە هەڵبژاردەییەکان بەپێی بابەتی ڕێزمان';

  @override
  String reviewWordsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وشە بۆ پێداچوونەوە!',
      one: '١ وشە بۆ پێداچوونەوە!',
    );
    return '$_temp0';
  }

  @override
  String get reviewTapStart =>
      'بگرە بۆ دەستپێکردنی دانیشتنی پێداچوونەوەی ڕۆژانە';

  @override
  String get obSlide1Title => 'کتێب و وشەکان';

  @override
  String get obSlide1Body =>
      'لە ماڵەوە دەست پێبکە: کتێب هەڵبژێرە، یەکەکان بکەرەوە، پاشان وشەکان ببینە. بە کارت و کویز لە هەر یەکەدا وەک ئەوەی حەز دەکەیت فێربە.';

  @override
  String get obSlide2Title => 'ڕاهێنانی ڕێزمان';

  @override
  String get obSlide2Body =>
      'تابی ڕێزمان بکەرەوە. یەک یان چەند بابەت هەڵبژێرە و دانیشتن دەست پێبکە — هەر جارێ ٢٠ پرسیاری هەڕەمەکی لەگەڵ ڕوونکردنەوە.';

  @override
  String get obSlide3Title => 'پێداچوونەوەی ڕۆژانە';

  @override
  String get obSlide3Body =>
      'پێداچوونەوە دووبارەکردنەوەی لەگەڵ مەودا بەکاردێت بۆ وشەکانی ڕاهێنانت کردووە. کارتەکان کاتیان هات، نیشانەی سەر تاب ببینە.';

  @override
  String get obSlide4Title => 'پێشکەوتنت';

  @override
  String get obSlide4Body =>
      'پێشکەوتن، زنجیرە و چالاکی پیشان دەدات. بە ڕیتمی جێگیر عادەت دروست بکە.';

  @override
  String get obSlide5Title => 'شیختای بکە';

  @override
  String get obSlide5Body =>
      'لە ڕێکخستنەکان: ڕووکار، زمانی وەرگێڕانی وشەکان (فارسی / کوردی سورانی)، بیرخەرەوە و زیاتر.';

  @override
  String get getStarted => 'دەستپێکردن';

  @override
  String get settingsTitle => 'ڕێکخستنەکان';

  @override
  String get sectionAccount => 'هەژمار';

  @override
  String get signIn => 'چوونەژوورەوە';

  @override
  String get signInSubtitle => 'ئارەزوومەندانە — بە ئیمەیڵ و وشەی نهێنی';

  @override
  String get createAccount => 'دروستکردنی هەژمار';

  @override
  String get profile => 'پڕۆفایل';

  @override
  String get signOut => 'دەرچوون';

  @override
  String get signOutTitle => 'دەرچوون لە هەژمار؟';

  @override
  String get signOutBody => 'دڵنیای دەتەوێت بچیتە دەرەوە؟';

  @override
  String get signedOut => 'دەرچوویت';

  @override
  String get loadingAccount => 'بارکردنی هەژمار…';

  @override
  String get sectionTranslationLanguage => 'زمانی وەرگێڕانی وشەکان';

  @override
  String get translationLangPersian => 'فارسی';

  @override
  String get translationLangKurdishSorani => 'کوردی (سورانی)';

  @override
  String get sectionAppearance => 'ڕووکار';

  @override
  String get systemTheme => 'ڕووکاری سیستەم';

  @override
  String get lightMode => 'دۆخی ڕووناک';

  @override
  String get darkMode => 'دۆخی تاریک';

  @override
  String get sectionDailyReminder => 'بیرخەرەوەی ڕۆژانە';

  @override
  String get dailyStudyReminder => 'بیرخەرەوەی خوێندنەوەی ڕۆژانە';

  @override
  String reminderSetAt(String time) {
    return 'بیرخەرەوە لە $time';
  }

  @override
  String get tapToEnableReminder => 'بگرە بۆ چالاککردن';

  @override
  String get reminderTime => 'کاتی بیرخەرەوە';

  @override
  String get sectionAbout => 'دەربارە';

  @override
  String get sectionAppLanguage => 'زمانی بەرنامە';

  @override
  String get appLanguageSubtitle =>
      'زمانی ڕووکار (ئینگلیزی، فارسی یان کوردی سورانی)';

  @override
  String get linkCopied => 'بەستەر لە کلیپبۆرد کۆپی کرا';

  @override
  String get appNameShort => 'وشەکانی ئایێڵتس';

  @override
  String get byAuthor => 'لەلایەن عیرفان عەبدی';

  @override
  String get errNoInternet => 'پەیوەندی ئینتەرنێت نییە. تۆڕ بپشکنە.';

  @override
  String get errBadData => 'خوێندنەوەی داتا سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get errServer =>
      'پەیوەندی بە سێرڤەرەوە سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get reviewToday => 'پێداچوونەوەی ئەمڕۆ';

  @override
  String dueCount(int count) {
    return '$count ماوە';
  }

  @override
  String get fetchErrorRetry =>
      'بارکردنی داتا سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get tapCardToReveal => 'بگرە لەسەر کارت بۆ پیشاندانی وەڵام';

  @override
  String get translateThisWord => 'ئەم وشەیە وەرگێڕە';

  @override
  String get answer => 'وەڵام';

  @override
  String get tapToSeeAnswer => 'بگرە بۆ بینینی وەڵام';

  @override
  String get howWellKnew => 'چەند باش دەیناسی؟';

  @override
  String get pronounce => 'خوێندنەوە';

  @override
  String get speaking => 'پەخشکردن…';

  @override
  String get noWordsDueTitle => 'ئەمڕۆ وشەیەک نییە بۆ پێداچوونەوە!';

  @override
  String get noWordsDueBodyFlashcards =>
      'بە کارت ڕاهێنان بکە بۆ پڕکردنەوەی ڕیزەکە.';

  @override
  String noWordsDueBodyGreat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وشە',
      one: '١ وشە',
    );
    return 'زۆر باشە! سبەینێ بگەڕێوە.\n$_temp0 لە ڕیزەکەت.';
  }

  @override
  String get sessionComplete => 'دانیشتن تەواو بوو!';

  @override
  String youReviewedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وشەت',
      one: '١ وشەت',
    );
    return 'ئەمڕۆ $_temp0 پێداچوونەوە کرد.';
  }

  @override
  String wordsProgress(int current, int total) {
    return '$current / $total وشە';
  }

  @override
  String get quizTitle => 'کویز';

  @override
  String get couldNotLoadWords =>
      'بارکردنی داتا سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get couldNotLoadMistakes => 'بارکردنی لیستی هەڵەکان سەرکەوتوو نەبوو';

  @override
  String get quizNotEnoughImportant =>
      'لەم مەودایەدا وشەی گرنگ نییە. هەموو وشەکان هەڵبژێرە، مەودا بگۆڕە یان یەکەی زیاتر.';

  @override
  String get quizNotEnoughWrongs =>
      'لەم هەڵبژاردنەدا هیچ وشەیەک لە هەڵەکانت نییە. یەکەکان بگۆڕە یان «تەنها هەڵەکانی پێشوو» کوژێوە بکە.';

  @override
  String get quizNeedFourWords =>
      'کەمترین ٤ وشە پێویستە بۆ دەستپێکردنی ئەم کویزە.';

  @override
  String get quizNeedOneWord =>
      'کەمترین ١ وشە پێویستە بۆ دەستپێکردنی ئەم کویزە.';

  @override
  String get quizScopeTitle => 'مەودای کویز';

  @override
  String get quizScopeImportantDescription =>
      'ئەم لیستە وشەی گرنگی تێدایە. هەڵبژێرە کویز هەموو وشەکان بگرێتەوە یان تەنها گرنگەکان.';

  @override
  String allWordsCount(int count) {
    return 'هەموو وشەکان ($count)';
  }

  @override
  String importantWordsOnlyCount(int count) {
    return 'تەنها وشەی گرنگ ($count)';
  }

  @override
  String get importantOnlyNeedsFour =>
      'تەنها ئەو وشانەی کە لەسەر سێرڤەر وەک گرنگ نیشانکراون بکۆزەوە.';

  @override
  String get quizSetupTitle => 'ڕێکخستنی کویز';

  @override
  String quizPoolSummary(int pool, int min, int max) {
    return '$pool وشە لە کۆمەڵە · کەمترین $min پرسیار · زۆرترین $max';
  }

  @override
  String get onlyPastMistakes => 'تەنها هەڵەکانی پێشوو';

  @override
  String get noMistakesYet => 'هێشتا هەڵەیەک بۆ ئەم مەودایە تۆمار نەکراوە.';

  @override
  String mistakesOnServer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count هەڵە',
      one: '١ هەڵە',
    );
    return '$_temp0 لەسەر سێرڤەر';
  }

  @override
  String get signInForMistakes =>
      'بچۆرە ژوورەوە بۆ هاوکاتکردنی هەڵەکان و دۆخی «هەڵەکانی پێشوو».';

  @override
  String get numberOfQuestions => 'ژمارەی پرسیارەکان';

  @override
  String get questionModes => 'دۆخەکانی پرسیار';

  @override
  String get startQuiz => 'دەستپێکردنی کویز';

  @override
  String get quizMcqWordToMeaning => 'وشە → واتا';

  @override
  String get quizMcqMeaningToWord => 'واتا → وشە';

  @override
  String get quizWrittenMeaningToWord => 'پڕکردنەوەی بەشێک';

  @override
  String get whatIsMeaningOf => 'واتای ئەمە چییە:';

  @override
  String get whichWordMeans => 'کام وشە ئەم واتایە دەدات:';

  @override
  String get typeTheWord => 'وشەکە بنووسە';

  @override
  String get typeYourAnswer => 'وەڵامەکەت بنووسە…';

  @override
  String get submit => 'ناردن';

  @override
  String get seeResults => 'بینینی ئەنجامەکان';

  @override
  String get nextQuestion => 'پرسیاری دواتر';

  @override
  String get updating => 'نوێکردنەوە…';

  @override
  String get learnedRemoveMistakes => 'فێربووم — لابردن لە هەڵەکان';

  @override
  String questionProgress(int current, int total) {
    return 'پرسیار $current لە $total';
  }

  @override
  String scoreCorrect(int score) {
    return '$score دروست';
  }

  @override
  String get perfectScore => 'نمرەی تەواو!';

  @override
  String get excellentWork => 'نایابە!';

  @override
  String get goodJob => 'باشە!';

  @override
  String get keepPracticing => 'بەردەوام بە لە ڕاهێنان!';

  @override
  String get dontGiveUp => 'بێهیوا مەبە!';

  @override
  String get tryAgain => 'دووبارە';

  @override
  String get changeMode => 'گۆڕینی دۆخ';

  @override
  String get backToWords => 'گەڕانەوە بۆ وشەکان';

  @override
  String correctLine(String answer) {
    return 'دروست: $answer';
  }

  @override
  String wrongBlankLine(String correct) {
    return 'هەڵە ( بەتاڵ ). وەڵامی دروست: $correct';
  }

  @override
  String wrongAnswerLine(String given, String correct) {
    return 'هەڵە: $given · وەڵامی دروست: $correct';
  }

  @override
  String get removedFromMistakes => 'لە لیستی هەڵەکانت لابرا';

  @override
  String get couldNotUpdateServer => 'نوێکردنەوەی سێرڤەر سەرکەوتوو نەبوو';

  @override
  String get unitsTitle => 'یەکەکان';

  @override
  String get backToBooks => 'گەڕانەوە بۆ کتێبەکان';

  @override
  String get bookQuiz => 'کویزی کتێب';

  @override
  String get favorites => 'دڵخواز';

  @override
  String get failedLoadSections =>
      'بارکردنی بەشەکان سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String wordsUnitSection(int unit, int section) {
    return 'یەکە $unit • بەش $section';
  }

  @override
  String wordsUnitOnly(int unit) {
    return 'یەکە $unit';
  }

  @override
  String get tooltipQuiz => 'کویز';

  @override
  String get tooltipFlashcards => 'کارت';

  @override
  String get searchWordWholeBook => 'گەڕان بۆ وشە (هەموو کتێب)…';

  @override
  String get noMatchingWords => 'هیچ وشەیەکی هاوتا نەدۆزرایەوە.';

  @override
  String sectionInUnit(int section, int unit) {
    return 'بەش $section لە یەکە $unit';
  }

  @override
  String unitLabel(int unit) {
    return 'یەکە $unit';
  }

  @override
  String matchesWholeBook(int filtered, int total) {
    return '$filtered لە $total هاوتاکەر (هەموو کتێب)';
  }

  @override
  String wordsVisible(int filtered, int total) {
    return '$filtered لە $total وشە دەردەکەوێت';
  }

  @override
  String get vocabularyQuizTitle => 'کویزی وشە';

  @override
  String get bookQuizSetupIntro =>
      'یەکەکان، ژمارەی پرسیار و ڕاهێنان لەسەر هەڵەکانی پێشوو هەڵبژێرە.';

  @override
  String get unitsSectionTitle => 'یەکەکان';

  @override
  String get couldNotLoadMistakesShort => 'بارکردنی هەڵەکان سەرکەوتوو نەبوو';

  @override
  String get registerTitle => 'دروستکردنی هەژمار';

  @override
  String get newAccount => 'هەژماری نوێ';

  @override
  String get registerSubtitle =>
      'ئیمەیڵ و وشەی نهێنی (کەمترین ٨ پیت) هەڵبژێرە. بێ کۆدی ئیمەیڵ یان SMS — دەتوانیت دەست بکەیت بە چوونەژوورەوە.';

  @override
  String get displayNameOptional => 'ناوی پیشاندان (ئارەزوومەندانە)';

  @override
  String get email => 'ئیمەیڵ';

  @override
  String get password => 'وشەی نهێنی';

  @override
  String get confirmPassword => 'دووبارەکردنەوەی وشەی نهێنی';

  @override
  String get register => 'تۆمارکردن';

  @override
  String get alreadyHaveAccount => 'هەژمارت هەیە؟ بچۆرە ژوورەوە';

  @override
  String get loginTitle => 'چوونەژوورەوە';

  @override
  String get welcomeBack => 'بەخێربێیتەوە';

  @override
  String get loginSubtitle =>
      'ئیمەیڵ و وشەی نهێنی بنووسە. بێ پشتڕاستکردنەوەی زیاتر — هەژمار دەستبەجێ چالاکە.';

  @override
  String get enterEmail => 'ئیمەیڵ بنووسە';

  @override
  String get enterValidEmail => 'ئیمەیڵێکی دروست بنووسە';

  @override
  String get enterPassword => 'وشەی نهێنی بنووسە';

  @override
  String get passwordMinLength => 'کەمترین ٨ پیت';

  @override
  String get confirmYourPassword => 'وشەی نهێنی دووبارە بکەرەوە';

  @override
  String get passwordsNoMatch => 'وشەکانی نهێنی یەک نین';

  @override
  String get signInButton => 'چوونەژوورەوە';

  @override
  String get forgotPassword => 'وشەی نهێنیت لەبیرچووە؟';

  @override
  String get createAnAccount => 'دروستکردنی هەژمار';

  @override
  String get accountTitle => 'هەژمار';

  @override
  String get tabSignIn => 'چوونەژوورەوە';

  @override
  String get tabRegister => 'تۆمارکردن';

  @override
  String get statsMyProgress => 'پێشکەوتنم';

  @override
  String get wordMastery => 'تەواوکردنی وشە';

  @override
  String get last7Days => '٧ ڕۆژی دوایین';

  @override
  String get quizInsights => 'شیکاری کویز';

  @override
  String get allTime => 'هەموو کاتەکان';

  @override
  String get vocabAndGrammar => 'وشە و ڕێزمان';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ڕۆژ',
      one: '١ ڕۆژ',
    );
    return 'زنجیرە $_temp0';
  }

  @override
  String get longest => 'درێژترین';

  @override
  String get totalDays => 'ڕۆژەکانی خوێندنەوە';

  @override
  String get mastered => 'تەواو  ';

  @override
  String get learning => 'فێربوون  ';

  @override
  String get seenOnce => 'جارێک بینراو  ';

  @override
  String get wordsReviewedPerDay => 'وشەکانی پێداچوونەوە لە ڕۆژێکدا';

  @override
  String get totalReviews => 'کۆی پێداچوونەوەکان';

  @override
  String get studyDays => 'ڕۆژەکانی خوێندنەوە';

  @override
  String get insightsTitle => 'شیکاری کویز';

  @override
  String get tabOverview => 'پێشبینین';

  @override
  String get tabVocabulary => 'وشە';

  @override
  String get tabGrammarStats => 'ڕێزمان';

  @override
  String get insightsLast14 =>
      '١٤ ڕۆژی دوایین: وشە (ئەم ئامێرە) بەرامبەر ڕێزمان (پاشەکەوتکراو لە هەژمار).';

  @override
  String get insightsSignInGrammar =>
      'بچۆرە ژوورەوە بۆ بارکردنی نمرەکانی ڕێزمان. میلەکانی وشە هێشتا داتای ناوخۆ بەکاردەهێنن.';

  @override
  String get insightsGrammarLoadError =>
      'بارکردنی داتای ڕێزمان بۆ نەخشە سەرکەوتوو نەبوو.';

  @override
  String get vocabDailyAccuracy =>
      'وردی ڕۆژانە لە کویزی وشە (پاشەکەوتکراو لەسەر ئەم ئامێرە).';

  @override
  String get allTimeDevice => 'هەموو کات (ئامێر)';

  @override
  String get grammarPracticeAppBar => 'ڕاهێنانی ڕێزمان';

  @override
  String get grammarTooltipResults => 'ئەنجامەکان';

  @override
  String get grammarTooltipUnselectAll => 'هەڵوەشاندنەوەی هەموو هەڵبژاردنەکان';

  @override
  String get grammarSelectTopicsCta => 'بابەت هەڵبژێرە';

  @override
  String grammarContinueTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بەردەوام ($count بابەت)',
      one: 'بەردەوام (١ بابەت)',
    );
    return '$_temp0';
  }

  @override
  String get grammarCouldNotLoadTopics =>
      'بارکردنی بابەتەکانی ڕێزمان سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get grammarNoTopicsEmpty =>
      'هێشتا بابەتی ڕێزمان نییە.\nڕیزەکان بۆ خشتەی پرسیارەکان زیاد بکە (ستوونی ناوەڕۆک = ناوی بابەت).';

  @override
  String grammarNotEnoughInBank(int minRequired) {
    return 'پرسیاری پێویست لە بانکدا نییە بۆ ئەم هەڵبژاردنە (کەمترین $minRequired پێویستە).';
  }

  @override
  String get grammarNoQuestions =>
      'بۆ بابەتە هەڵبژێردراوەکان پرسیار نەدۆزرایەوە.';

  @override
  String get grammarTopicsPick => 'بابەت و درێژی دانیشتن هەڵبژێرە';

  @override
  String get exitExerciseTitle => 'دەرچوون لە ڕاهێنان؟';

  @override
  String get exitExerciseBody =>
      'ئێستا بگەڕێیتەوە، پێشکەوتنی ئەم دانیشتنە پاشەکەوت ناکرێت.';

  @override
  String get stay => 'مانەوە';

  @override
  String get exit => 'دەرچوون';

  @override
  String get grammarAppBar => 'ڕێزمان';

  @override
  String get noTopicSelected => 'هیچ بابەتێک هەڵنەبژێردراوە.';

  @override
  String get reportSubmitted => 'ڕاپۆرت نێردرا';

  @override
  String get reportFailed => 'ناردنی ڕاپۆرت سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get submitReport => 'ناردنی ڕاپۆرت';

  @override
  String get couldNotSaveResult =>
      'پاشەکەوتکردنی ئەنجام سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get keepPrivate => 'تایبەت (تەنها بۆ من)';

  @override
  String get showCommunity => 'نیشاندان لە ئەنجامەکانی کۆمەڵگا';

  @override
  String get practiseAgain => 'دووبارە ڕاهێنان';

  @override
  String get backToTopics => 'گەڕانەوە بۆ بابەتەکان';

  @override
  String get reviewSessionTitle => 'پێداچوونەوەی دانیشتن';

  @override
  String get couldNotLoadResult => 'بارکردنی ئەم ئەنجامە سەرکەوتوو نەبوو.';

  @override
  String get myResults => 'ئەنجامەکانم';

  @override
  String get users => 'بەکارهێنەران';

  @override
  String get tryAgainResults => 'دووبارە';

  @override
  String get wordExample => 'نموونە';

  @override
  String get favorite => 'دڵخواز';

  @override
  String get important => 'گرنگ';

  @override
  String get pronounceWord => 'خوێندنەوەی وشە';

  @override
  String get pronounceExample => 'خوێندنەوەی نموونە';

  @override
  String get couldNotUpdateImportant =>
      'نوێکردنەوەی نیشانەی گرنگ سەرکەوتوو نەبوو';

  @override
  String get markedImportant => 'وەک گرنگ نیشان کرا';

  @override
  String get removedImportant => 'لە گرنگەکان لابرا';

  @override
  String get savedLocally =>
      'لە ناوخۆ پاشەکەوت کرا. لەگەڵ نوێکردنەوە هاوکات دەبێت.';

  @override
  String get registerEmailTaken => 'ئەم ئیمەیڵە پێشتر تۆمارکراوە';

  @override
  String get registerFailed => 'تۆمارکردن سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get loginInvalid => 'ئیمەیڵ یان وشەی نهێنی هەڵەیە';

  @override
  String get loginFailed => 'چوونەژوورەوە سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get passwordResetTitle => 'دووبارەکردنەوەی وشەی نهێنی';

  @override
  String get passwordResetBody =>
      'بەهۆی سنووردارکردنی ئینتەرنێتەوە، دووبارەکردنەوە بە ئیمەیڵ ڕەنگە کار نەکات. بۆ یارمەتی پەیام بۆ erfaninfox لە بەلە یان ڕوبیکا بنێرە.';

  @override
  String get copySupportLink => 'کۆپی بەستەری پاڵپشتی';

  @override
  String get supportLinkCopied =>
      'بەستەری پاڵپشتی کۆپی کرا — لە وێبگەڕ یان ڕوبیکا بیکەرەوە';

  @override
  String get copyRequestText => 'کۆپی دەقی داواکاری';

  @override
  String get requestTextCopied =>
      'دەقی داواکاری کۆپی کرا — لە بەلە یان ڕوبیکا بنێرە';

  @override
  String get statsSignInGrammarTrend =>
      'بچۆرە ژوورەوە بۆ بینینی ڕەوتی نمرەی ڕێزمان لە کویزە پاشەکەوتکراوەکان.';

  @override
  String get statsCouldNotLoadGrammar =>
      'بارکردنی ئاماری ڕێزمان سەرکەوتوو نەبوو.';

  @override
  String get statsNoGrammarYet =>
      'هێشتا ئەنجامی ڕێزمان نییە. کویزێکی ڕێزمان تەواو بکە و نمرە پاشەکەوت بکە.';

  @override
  String get grammarOverview => 'پێشبینینی ڕێزمان';

  @override
  String averageLastAttempts(int count) {
    return 'تێکڕا (دوایین $count پاشەکەوتکراو): ';
  }

  @override
  String get attempts => 'هەوڵ';

  @override
  String get lastLabel => 'دوایین';

  @override
  String get bestLabel => 'باشترین';

  @override
  String get worstLabel => 'خراپترین';

  @override
  String get trendLabel => 'ڕەو';

  @override
  String get scoreTrendTitle => 'ڕەوتی نمرە (کۆنترین → نوێترین)';

  @override
  String get saveTwoQuizzesChart =>
      'کەمترین دوو کویزی ڕێزمان پاشەکەوت بکە بۆ بینینی نەخشەی هێڵ.';

  @override
  String get attemptsDistribution => 'دابەشکردنی هەوڵەکان';

  @override
  String get vocabDailyChartHint =>
      'وەڵامی پرسیارەکانی کویزی وشە بدە بۆ بینینی وردی ڕۆژانە لێرە.';

  @override
  String get noQuizDataRange => 'هێشتا داتای کویز لەم مەودایەدا نییە.';

  @override
  String get legendVocabulary => 'وشە';

  @override
  String get legendGrammar => 'ڕێزمان';

  @override
  String get insightsVocabVsGrammar => 'وشە';

  @override
  String get bookQuizChooseUnits => 'هەڵبژاردنی یەکەکان';

  @override
  String nextDaysShort(int n) {
    return '$n ڕۆژ';
  }

  @override
  String get vocabQuizExitTitle => 'دەرچوون لە کویز؟';

  @override
  String get vocabQuizExitBody =>
      'ئێستا بڕۆیتەوە، پێشکەوتنی ئەم کویزە لەدەست دەچێت.';

  @override
  String get importantWordsSection => 'وشە گرنگەکان';

  @override
  String get importantWordsServerHint =>
      'ئەم هەڵبژاردنە وشەی وەک گرنگ نیشانکراو لە سێرڤەر لەخۆ دەگرێت.';

  @override
  String get allWordsChip => 'هەموو وشەکان';

  @override
  String get importantOnlyChip => 'تەنها گرنگەکان';

  @override
  String bookQuizQuestionsSlider(int max) {
    return 'ژمارەی پرسیار (زۆرترین $max)';
  }

  @override
  String get bookQuizPoolTooSmall =>
      'کەمترین ٤ وشە پێویستە (یەکەکان/هەڵەکان بپشکنە).';

  @override
  String get bookQuizPoolTooSmallImportant =>
      'لەم هەڵبژاردنەدا وشەی گرنگ نییە. «هەموو وشەکان» هەڵبژێرە یان یەکەکان بگۆڕە.';

  @override
  String get statsStudiedToday => '✅ ئەمڕۆ خوێندنت کرد!';

  @override
  String get statsStudyToKeepStreak => '📖 ئەمڕۆ بخوێنە بۆ مایەپوچی زنجیرە';

  @override
  String get statsInsightsCardSubtitle => 'نەخشەی ١٤ ڕۆژ، ڕەو و دابەشکردن';

  @override
  String statsVocabDeviceAccuracy(String pct, int correct, int answered) {
    return 'وشە (ئامێر): $pct% ($correct / $answered)';
  }

  @override
  String statsWordsStudiedTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وشە کۆی گشتی خوێندراوەتەوە',
      one: '١ وشە کۆی گشتی خوێندراوەتەوە',
    );
    return '$_temp0';
  }

  @override
  String get srsRatingAgain => '❌ دووبارە';

  @override
  String get srsRatingHard => '😐 قورس';

  @override
  String get srsRatingGood => '✅ باش';

  @override
  String get srsRatingEasy => '🔥 ئاسان';

  @override
  String get profileScreenTitle => 'پڕۆفایل';

  @override
  String get profileSignInPrompt => 'بچۆرە ژوورەوە بۆ دەستکاری پڕۆفایل.';

  @override
  String get profilePhotoUpdated => 'وێنە نوێکرایەوە';

  @override
  String get profileUploadFailed =>
      'بارکردن سەرکەوتوو نەبوو. دووبارە هەوڵ بدە یان وێنەی بچووکتر هەڵبژێرە.';

  @override
  String get profileSaved => 'پڕۆفایل پاشەکەوت کرا';

  @override
  String get profileSaveFailed => 'پاشەکەوتکردن سەرکەوتوو نەبوو.';

  @override
  String get unsavedChangesTitle => 'گۆڕانکاری پاشەکەوت نەکراوە';

  @override
  String get unsavedChangesBody => 'گۆڕانکارییەکانت پاشەکەوت نەکراون. دەرچیت؟';

  @override
  String get discardStay => 'بەردەوام بە دەستکاری';

  @override
  String get discardLeave => 'دەرچوون';

  @override
  String get profileCropPhoto => 'بڕینی وێنە';

  @override
  String get profileGallery => 'پێشانگا';

  @override
  String get profileCamera => 'کامێرا';

  @override
  String get profileDisplayName => 'ناوی پیشاندان';

  @override
  String get profileDisplayNameHint => 'ناوەکەت چۆن دەردەکەوێت';

  @override
  String get profilePresetAvatars => 'یان وێنۆچکەی ئامادە هەڵبژێرە';

  @override
  String get profileBoyAvatars => 'وێنۆچکەی کوڕ';

  @override
  String get profileGirlAvatars => 'وێنۆچکەی کچ';

  @override
  String get save => 'پاشەکەوت';

  @override
  String get grammarResultsScreenTitle => 'ئەنجامەکانی ڕێزمان';

  @override
  String get grammarExplanationTabFa => 'فارسی';

  @override
  String get grammarExplanationTabCkb => 'کوردی';

  @override
  String get grammarReportProblemTitle => 'ڕاپۆرتکردنی کێشە';

  @override
  String get grammarReportWhatWrong => 'کێشەکە چییە؟';

  @override
  String get grammarReportDetailsOptional => 'وردەکاری (ئارەزوومەندانە)';

  @override
  String get grammarReportKindWrongAnswer => 'وەڵامی دروست نیشانکراو هەڵەیە';

  @override
  String get grammarReportKindTypoQuestion => 'هەڵەی ڕێنووس لە دەقی پرسیار';

  @override
  String get grammarReportKindTypoOptions => 'چەند هەڵبژاردن دروست دەردەکەون';

  @override
  String get grammarReportKindBadExplanation => 'ڕوونکردنەوە هەڵە یان ناتەواوە';

  @override
  String get grammarReportKindUnclear => 'دەقی پرسیار ڕوون نییە';

  @override
  String get grammarReportKindOther => 'هیتر';

  @override
  String get grammarReportQuestionTooltip => 'ڕاپۆرتکردنی پرسیار';

  @override
  String grammarTopicsCountAppBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بابەت',
      one: '١ بابەت',
    );
    return '$_temp0';
  }

  @override
  String get grammarSortNewestFirst => 'نوێترین یەکەم';

  @override
  String get grammarSortHighestScore => 'بەرزترین لەسەدی نمرە';

  @override
  String get grammarSortLabel => 'ڕیزکردن';

  @override
  String get grammarSignInRequiredTitle => 'چوونەژوورەوە پێویستە';

  @override
  String get grammarSignInRequiredBody =>
      'بچۆرە ژوورەوە بۆ مێژوو و نیشانەی تایبەت/گشتی.';

  @override
  String get grammarGoToSignIn => 'بڕۆ بۆ ڕێکخستن و چوونەژوورەوە';

  @override
  String get grammarLoadingYourResults => 'بارکردنی ئەنجامەکانت…';

  @override
  String get grammarLoadingCommunityResults => 'بارکردنی ئەنجامەکانی کۆمەڵگا…';

  @override
  String get grammarNoPersonalResultsTitle => 'هێشتا ئەنجام نییە';

  @override
  String get grammarNoPersonalResultsBody =>
      'دوای تەواوکردنی دانیشتنی ڕێزمان، نمرەکەت لێرە دەردەکەوێت.';

  @override
  String get grammarCommunityEmptyTitle => 'هێشتا هیچ نییە';

  @override
  String get grammarCommunityEmptyBody =>
      'کاتێک لە کۆتایی کویزدا «نیشاندان لە ئەنجامەکانی کۆمەڵگا» هەڵدەبژێریت، لێرە دەردەکەوێت.';

  @override
  String get guestUser => 'میوان';

  @override
  String get resultVisibilityPublic => 'گشتی';

  @override
  String get resultVisibilityPrivate => 'تایبەت';

  @override
  String get errorConnectionTryAgain => 'پەیوەندی بپشکنە و دووبارە هەوڵ بدە.';

  @override
  String get grammarSheetSessionTitle => 'ژمارەی پرسیارەکانی ئەم دانیشتنە';

  @override
  String get grammarSheetHintSingleTopic =>
      'پرسیارەکان تەنها لەم بابەتەوە هەڵدەبژێردرێن.';

  @override
  String get grammarSheetHintMultiTopic =>
      'پرسیارەکان لە هەموو بابەتە هەڵبژێردراوەکان تێکەڵ دەکرێن.';

  @override
  String grammarSheetUpToInBank(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'تا $max پرسیار لە بانکدا بەردەستە.',
      one: 'تا ١ پرسیار لە بانکدا بەردەستە.',
    );
    return '$_temp0';
  }

  @override
  String grammarSheetMinSession(int min, int base) {
    return 'کەمترین ئەم دانیشتنە: $min (کەمترین $base، یان یەک بۆ هەر بابەتێک ئەگەر چەندت هەڵبژێریت).';
  }

  @override
  String get grammarSheetQuickPick => 'هەڵبژاردنی خێرا';

  @override
  String grammarQuestionNoun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'پرسیار',
      one: 'پرسیار',
    );
    return '$_temp0';
  }

  @override
  String get grammarCouldNotLoadQuestions =>
      'بارکردنی پرسیارەکان سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

  @override
  String get grammarNoQuestionsForTopics =>
      'بۆ بابەت(ەکان)ی هەڵبژێردراو پرسیار نییە.';

  @override
  String get grammarExplanationHeading => 'ڕوونکردنەوە';

  @override
  String get grammarSessionCompleteTitle => 'دانیشتن تەواو بوو';

  @override
  String grammarScoreOutOf(int score, int total) {
    return 'لە $total پرسیار، $score دروست بوو.';
  }

  @override
  String get grammarHowSaveResult => 'ئەنجام چۆن پاشەکەوت بکرێت؟';

  @override
  String get grammarSaveResultFootnote =>
      'ئەنجامی تایبەت تەنها لە «ئەنجامەکانم»؛ گشتی لە تابی «بەکارهێنەران».';

  @override
  String get grammarResultSavedShort => 'ئەنجام پاشەکەوت کرا';

  @override
  String statsDaysOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ڕۆژ',
      one: '١ ڕۆژ',
    );
    return '$_temp0';
  }
}
