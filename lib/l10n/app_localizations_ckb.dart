// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get appTitle => 'Erfan Academy';

  @override
  String get tabHome => 'سەرەکی';

  @override
  String get tabGrammar => 'ڕێزمان';

  @override
  String get tabReview => 'پێداچوونەوە';

  @override
  String get tabPlay => 'یاری';

  @override
  String get youSectionReview => 'پێداچوونەوە';

  @override
  String get youSectionReviewSubtitle =>
      'دووبارەکردنەوەی وشەکان بە مەودا بۆ ئەو ووشانەی تەمرین کردووتە.';

  @override
  String get tabProgress => 'پێشکەوتن';

  @override
  String get tabYou => 'تۆ';

  @override
  String get tabSettings => 'ڕێکخستنەکان';

  @override
  String get youPageTitle => 'تۆ';

  @override
  String get youSectionProgress => 'پێشکەوتن';

  @override
  String get youSectionProgressSubtitle => 'زنجیرە، ئامار و تێڕوانینەکانی تێست';

  @override
  String get youSectionMessages => 'مامۆستاکەت';

  @override
  String get youSectionMessagesHub => 'پەیامەکان';

  @override
  String get youSectionMessagesSubtitle => 'گفتوگۆ لەگەڵ مامۆستای پۆلەکەت';

  @override
  String get youSectionMessagesSubtitleHub => 'گفتوگۆ لەگەڵ مامۆستا و ستاف';

  @override
  String get youMessagesPickTitle => 'گفتوگۆکان';

  @override
  String get youTeacherPanelSubtitle => 'قوتابیان و چالاکی پۆل';

  @override
  String get chatSenderYou => 'تۆ';

  @override
  String get teacherStudentChat => 'گفتوگۆ';

  @override
  String get teacherInboxTitle => 'پەیامەکان';

  @override
  String get teacherInboxOpenPanel => 'هەموو قوتابیان';

  @override
  String get chatListYesterday => 'دوێنێ';

  @override
  String get chatPreviewYouPrefix => 'تۆ: ';

  @override
  String get teacherChatHint => 'پەیام…';

  @override
  String get teacherMessagesEmpty => 'هێشتا پەیام نییە.';

  @override
  String get chatMessageEdit => 'دەستکاری';

  @override
  String get chatMessageEditTitle => 'دەستکاری پەیام';

  @override
  String get chatMessageEditHint => 'پەیامەکەت نوێ بکەوە…';

  @override
  String get chatMessageEdited => 'دەستکاری کراوە';

  @override
  String get chatMessageEditFailedRead =>
      'ئەم پەیامە خوێندراوەتەوە و ناتوانرێت دەستکاری بکرێت.';

  @override
  String get chatMessageEditSave => 'پاشەکەوت';

  @override
  String get chatMessageReadStateSent => 'نێردرا';

  @override
  String get chatMessageReadStateRead => 'بینراوە';

  @override
  String get teacherMessagesNoTeacher =>
      'کۆدی قوتابی بەکاربهێنە بۆ پەیوەندی مامۆستا.';

  @override
  String newMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پەیامی نوێ',
      one: '١ پەیامی نوێ',
      zero: 'پەیامی نوێ نییە',
    );
    return '$_temp0';
  }

  @override
  String get tabStudents => 'قوتابی';

  @override
  String get studentBooksTitle => 'کتێبەکانی پۆلەکەت';

  @override
  String get registerAsStudent => 'قوتابی تۆ';

  @override
  String get studentCodeLabel => 'کۆدی قوتابی';

  @override
  String get studentCodeRequired => 'کۆدەکە بنووسە کە مامۆستا پێتداویە';

  @override
  String get redeemStudentCode => 'تۆمارکردنی کۆدی قوتابی';

  @override
  String get redeemStudentCodeSubtitle => 'کۆدی ٥ ژمارەیی مامۆستاکەت بنووسە.';

  @override
  String get createStudentCode => 'دروستکردنی کۆدی قوتابی';

  @override
  String get createStudentCodeSubtitle =>
      'کۆدێکی ٥ ژمارەیی یەک‌جار بۆ قوتابیەک تۆمار بکە.';

  @override
  String get studentCodeFiveDigitsHint => '١٢٣٤٥';

  @override
  String get studentCodeFiveDigitsInvalid => 'تەواو ٥ ژمارە بنووسە';

  @override
  String teacherStudentCodeRegistered(String code) {
    return 'کۆدی $code بۆ قوتابیەک ئامادەیە.';
  }

  @override
  String get teacherStudentCodeRegisterFailed =>
      'نەتوانرا ئەم کۆدە تۆمار بکرێت.';

  @override
  String get teacherUnusedCodesTitle => 'کۆدە بەکارنەهاتووەکان';

  @override
  String get invalidStudentCode => 'کۆدەکە نادروستە یان بەسەرچووە.';

  @override
  String get studentAccessGranted => 'دەستپێگەیشتنی قوتابی چالاککرا.';

  @override
  String get studentTabSignIn =>
      'بچۆرە ژوورەوە بۆ بینینی کتێبەکانی مامۆستاکەت.';

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
  String get unitSamplesOpen => 'دەقی نموونە';

  @override
  String unitSamplesTitle(int unit) {
    return 'یونیت $unit — دەقی نموونە';
  }

  @override
  String unitSamplesTitleSection(int unit, int section) {
    return 'یونیت $unit — بەش $section — دەقی نموونە';
  }

  @override
  String get unitSamplesEmpty => 'هێشتا بۆ ئەم یونیتە دەقی نموونە نییە.';

  @override
  String get unitSamplesLoadFailed => 'بارکردنی دەقی نموونە سەرکەوتوو نەبوو.';

  @override
  String get search => 'گەڕان';

  @override
  String get errorGeneric => 'کێشەیەک ڕوویدا. تکایە دووبارە هەوڵ بدە.';

  @override
  String get errServerReturnedError =>
      'سێرڤەر هەڵەیەکی گەڕاندەوە. دواتر دووبارە هەوڵ بدە.';

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
  String get homeReceivingBooks => 'لە وەرگرتندایە…';

  @override
  String get couldNotLoadBooks => 'بارکردنی کتێبەکان سەرکەوتوو نەبوو.';

  @override
  String couldNotLoadBooksWithError(String error) {
    return 'بارکردنی کتێبەکان سەرکەوتوو نەبوو.\n$error';
  }

  @override
  String get noBooksFound => 'هیچ کتێبێک نەدۆزرایەوە';

  @override
  String get homeTrackIelts => 'ئایێڵتس';

  @override
  String get homeTrackGeneral => 'گشتی';

  @override
  String get homeBooksSeriesOther => 'کتێبەکانی تر';

  @override
  String get homeSeriesCambridgeTests => 'تێستەکانی Cambridge IELTS';

  @override
  String homeSeriesVolumesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کتێب لەم زنجیرەیە',
      one: '١ کتێب لەم زنجیرەیە',
    );
    return '$_temp0';
  }

  @override
  String seriesBooksGridHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کتێب · بۆ کردنەوە لەسەر کارت دابگرە',
      one: '١ کتێب · بۆ کردنەوە لەسەر کارت دابگرە',
    );
    return '$_temp0';
  }

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
  String get sectionSound => 'دەنگ';

  @override
  String get splashSoundTitle => 'دەنگی دەستپێکردن';

  @override
  String get splashSoundSubtitle => 'کاتێک ئەپ دەکرێتەوە دەنگێکی هێمن لێ بدە';

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
  String get appNameShort => 'Erfan Academy';

  @override
  String get byAuthor => 'لەلایەن عیرفان عەبدی';

  @override
  String aboutAppVersion(String version, String buildNumber) {
    return 'وەشان $version ($buildNumber)';
  }

  @override
  String get aboutUpdateFromPlayStore => 'وەشانی نوێ دابگرە';

  @override
  String get aboutAppUpToDate => 'دوایین وەشان دامەزراوە.';

  @override
  String aboutUpdateAvailableVersion(String version) {
    return 'وەشانێکی نوێ بەردەستە: $version';
  }

  @override
  String get aboutDownloadApkUpdate => 'داگرتنی نوێکردنەوە';

  @override
  String get aboutDownloadingApk => 'داگرتن…';

  @override
  String get aboutDownloadApkFailed =>
      'داگرتن سەرکەوتوو نەبوو. پەیوەندی بپشکنە و دووبارە هەوڵ بدە.';

  @override
  String get aboutInstallApkHint =>
      'ئەگەر داواکرا، لە ڕێکخستنەکاندا ڕێگە بدە بە دامەزراندن لەم ئەپەوە.';

  @override
  String get aboutDownloadComplete => 'داگرتن تەواو بوو';

  @override
  String get aboutInstallReadyMessage =>
      'نوێکردنەوەکە داگیراوە. بۆ نوێکردنەوەی Erfan Academy کلیک لەسەر «دامەزراندن» بکە. هەژمار و داتاکەت پاراستراو دەبێت.';

  @override
  String get aboutInstallNow => 'دامەزراندن';

  @override
  String get aboutInstallPermissionRequired =>
      'ئەندرۆید پێویستی بە مۆڵەتە بۆ دامەزراندنی نوێکردنەوە لەم ئەپەوە. لە «ڕێکخستنەکان ← ئەپەکان ← Erfan Academy ← دامەزراندنی ئەپی نەناسراو» مۆڵەت بدە و دیسان «دامەزراندن» داگرە.';

  @override
  String get aboutInstallLaunchFailed =>
      'نەتوانرا دامەزرێنەرەکە بکرێتەوە. تکایە دیسان هەوڵ بدە.';

  @override
  String get aboutForcedUpdateNote =>
      'ئەم نوێکردنەوەیە پێویستە. تکایە دوایین وەشان دابگرە و دامەزرێنە.';

  @override
  String get aboutUpdateCheckFailed => 'پشکنینی نوێکردنەوە سەرکەوتوو نەبوو.';

  @override
  String get aboutRetryUpdateCheck => 'دووبارە هەوڵ بدە';

  @override
  String get homeNewUpdatesTitle => 'نوێکارییەکان';

  @override
  String get homeNewUpdatesLetsGo => 'تێگەیشتم';

  @override
  String get aboutLater => 'دواتر';

  @override
  String get aboutCouldNotOpenLink => 'بۆکردنەوەی بەستەر سەرکەوتوو نەبوو.';

  @override
  String get aboutPhoneLabel => 'تەلەفۆن';

  @override
  String get aboutPhoneCopied => 'ژمارەکە لە کلیپبۆرد کۆپی کرا';

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
  String get quizSpellingListenAndType => 'گوێگرتن و ڕێنووس';

  @override
  String get quizSpellingListenPrompt => 'گوێ بگرە و وشەی ئینگلیزی بنووسە:';

  @override
  String get quizReplayAudio => 'دووبارە پێکردنەوە';

  @override
  String get quizSpellingTypeEnglish => 'وشەی ئینگلیزی بنووسە';

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
  String get backToQuiz => 'گەڕانەوە بۆ تاقیکردنەوە';

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
  String get quizFeedbackWrongPrefix => 'هەڵە:';

  @override
  String get quizFeedbackCorrectLabel => 'وەڵامی دروست:';

  @override
  String get quizWrongBlankIntro => 'هەڵە ( بەتاڵ ).';

  @override
  String get quizWrittenFirstLetterMismatch =>
      'پیتەی یەکەم هەڵەیە؛ وەڵام بەم پیتەیە دەست پێناکات.';

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
  String get vocabQuizHistoryTitle => 'مێژووی تاقیکردنەوەی وشەکان';

  @override
  String get vocabQuizHistorySubtitle =>
      'دانیشتنەکان لە هەژمارەکەتدا هەڵدەگیرێن.';

  @override
  String get vocabQuizHistoryEmpty => 'هێشتا دانیشتنێک تۆمار نەکراوە.';

  @override
  String get vocabQuizHistorySignIn =>
      'بچۆرە ژوورەوە بۆ تۆمارکردنی ئەنجامەکان لەسەر سێرڤەر.';

  @override
  String get vocabQuizHistoryLoadError =>
      'بارکردنی مێژوو سەرکەوتوو نەبوو. زۆرجار خشتەی ئەنجام لە داتابەیس دروست نەکراوە؛ فایلی api/vocab_quiz_results_schema.sql لەسەر MySQL جێبەجێ بکە یان دواتر دووبارە هەوڵ بدە.';

  @override
  String get vocabQuizResultDetailTitle => 'وردەکاری دانیشتن';

  @override
  String vocabQuizResultScoreLine(int score, int total) {
    return '$score لە $total دروست';
  }

  @override
  String get vocabQuizResultYourAnswer => 'وەڵامەکەت';

  @override
  String get vocabQuizResultCorrect => 'دروست';

  @override
  String get vocabQuizResultIncorrect => 'هەڵە';

  @override
  String get vocabQuizResultQuestion => 'پرسیار';

  @override
  String vocabQuizHistoryUnitsLine(String units) {
    return 'یەکەکان: $units';
  }

  @override
  String vocabQuizCorrectWrongLine(int correct, int wrong) {
    return '$correct دروست · $wrong هەڵە';
  }

  @override
  String get vocabQuizViewMistakes => 'بینینی هەڵەکان';

  @override
  String get vocabQuizMistakesTitle => 'وەڵامە هەڵەکان';

  @override
  String get vocabQuizMistakesEmpty =>
      'لەم دانیشتنەدا وەڵامی هەڵە تۆمار نەکراوە.';

  @override
  String get teacherPanelTitle => 'پانێلی مامۆستا';

  @override
  String get teacherPanelSubtitle =>
      'بینینی وشە و ڕێزمانی قوتابیان و تۆمارکردنی وانەکان.';

  @override
  String get teacherOpenPanel => 'پانێلی مامۆستا';

  @override
  String get teacherStudentsEmpty =>
      'هێشتا قوتابی بەستراو نییە. لەسەر سێرڤەر کۆدی قوتابی بە هەژماری مامۆستاکەت بەستە؛ قوتابیەکان بە هەمان کۆد تۆمار دەبن.';

  @override
  String get teacherPanelTabStudents => 'قوتابیان';

  @override
  String get teacherPanelTabSchedule => 'خشتەی وانە';

  @override
  String get teacherPanelTabMessages => 'نامەکان';

  @override
  String get teacherScheduleEmpty =>
      'لە ٧ ڕۆژی داهاتوودا هیچ نییە. کاتەکانی هەفتانە لە هەر قوتابییەک زیاد بکە، یان هەموو کاتە نزیکەکان پێشتر تۆمارکراون.';

  @override
  String get teacherScheduleTabSubtitle =>
      '٧ ڕۆژی داهاتوو لە خشتەی هەفتانەی هەر قوتابییەک. دوای تۆمارکردنی هەمان وانە لە دانیشتنەکان، لێرە دەردەچێت.';

  @override
  String get sessionDayToday => 'ئەمڕۆ';

  @override
  String get sessionDayTomorrow => 'سبەی';

  @override
  String get teacherStudentDetailTitle => 'قوتابی';

  @override
  String get teacherTabVocabQuiz => 'وشەکان';

  @override
  String get teacherTabGrammar => 'ڕێزمان';

  @override
  String get teacherTabClassSessions => 'دانیشتنەکان';

  @override
  String get teacherTabWeeklySchedule => 'خشتەی هەفتانە';

  @override
  String get teacherClassScheduleSubtitle =>
      'ڕۆژەکانی هەفتە و کاتەکانی وانە دیاری بکە — قوتابی تەنها دەبینێت.';

  @override
  String get teacherClassScheduleAddButton => 'زیادکردنی کات';

  @override
  String get teacherClassScheduleEditTitle => 'دەستکاریکردنی کات';

  @override
  String get classScheduleWeekdayLabel => 'ڕۆژی هەفتە';

  @override
  String get classScheduleStartLabel => 'کاتی دەستپێک';

  @override
  String get classScheduleEndLabel => 'کاتی کۆتایی';

  @override
  String get classScheduleIncludeEnd => 'کاتی کۆتاییش بنووسە';

  @override
  String get classScheduleHasEndSubtitle =>
      'ئارەزوومەندانە — ئەگەر نەبێت تەنها دەستپێک دەردەکەوێت.';

  @override
  String get classScheduleLabelHint => 'تێبینی (ئارەزوومەندانە)';

  @override
  String get classScheduleEmpty => 'هێشتا کاتێک تۆمار نەکراوە.';

  @override
  String get classScheduleSlotAdded => 'کات زیادکرا';

  @override
  String get classScheduleSlotUpdated => 'کات نوێکرایەوە';

  @override
  String get classScheduleSlotDeleted => 'کات سڕایەوە';

  @override
  String get classScheduleRemove => 'سڕینەوە';

  @override
  String get classScheduleDeleteConfirmTitle => 'ئەم کاتە بسڕدرێتەوە؟';

  @override
  String get classScheduleDeleteConfirmBody => 'گەڕانەوە نییە.';

  @override
  String get classScheduleInvalidRange => 'کاتی کۆتایی دەبێت دوای دەستپێک بێت.';

  @override
  String get teacherTemporaryClassAddButton => 'زیادکردنی وانەی کاتی';

  @override
  String get teacherTemporaryClassTitle => 'وانەی کاتی';

  @override
  String get teacherTemporaryClassStudentLabel => 'قوتابی';

  @override
  String get teacherTemporaryClassSaved => 'وانەی کاتی زیادکرا';

  @override
  String get teacherTemporaryClassUpdated => 'وانەی کاتی دەستکاری کرا';

  @override
  String get teacherTemporaryClassDeleted => 'وانەی کاتی سڕایەوە';

  @override
  String get teacherTemporaryClassBadge => 'کاتی';

  @override
  String get teacherTemporaryClassDeleteConfirmTitle =>
      'ئەم وانەیەی کاتی بسڕدرێتەوە؟';

  @override
  String get teacherTemporaryClassDeleteConfirmBody =>
      'ئەم بڕگەیەی جارێک لە خشتەکە دەسڕدرێتەوە.';

  @override
  String get teacherTemporaryClassNoStudents => 'قوتابی بۆ هەڵبژاردن نییە.';

  @override
  String get teacherTemporaryClassSubtitle =>
      'قوتابی، بەروار و کاتی وانەیەکی یەک کاتژمێری هەڵبژێرە.';

  @override
  String get teacherScheduleModeAuto => 'خۆکار';

  @override
  String get teacherScheduleModeManual => 'دەستی';

  @override
  String get teacherScheduleDidClassHappen => 'ئەم وانەیە بەڕێوەچوو؟';

  @override
  String get teacherScheduleYes => 'بەڵێ';

  @override
  String get teacherScheduleNo => 'نەخێر';

  @override
  String get teacherScheduleClassSkipped => 'وانەکە تێپەڕێنرا';

  @override
  String get youClassScheduleSubtitle =>
      'ڕۆژ و کاتی وانەی دووبارە لە مامۆستاکەت';

  @override
  String get teacherClassSessionsTabSubtitle =>
      'دانیشتن بە یەک داگرتن زیاد بکە، کاتەکە ڕاست بکەوە یان سڕینەوە. قوتابی تەنها دەتوانێت لیستەکە ببینێت.';

  @override
  String teacherClassSessionHeading(int number) {
    return 'دانیشتن $number';
  }

  @override
  String get teacherClassSessionEdit => 'دەستکاری';

  @override
  String get teacherClassSessionDelete => 'سڕینەوە';

  @override
  String get teacherClassSessionDeleteConfirmTitle =>
      'ئەم دانیشتنە بسڕدرێتەوە؟';

  @override
  String get teacherClassSessionDeleteConfirmBody => 'ناتوانرێت بگەڕێندرێتەوە.';

  @override
  String get teacherClassSessionDeleted => 'دانیشتن سڕایەوە';

  @override
  String get teacherClassSessionEditTitle => 'بەروار و کات';

  @override
  String get teacherClassSessionAdded => 'دانیشتن زیادکرا';

  @override
  String get teacherClassSessions => 'وانەکان';

  @override
  String get teacherClassSessionAddTooltip => 'زیادکردنی دانیشتنی پۆل';

  @override
  String get teacherClassSessionsAddButton => 'زیادکردنی دانیشتن';

  @override
  String get teacherClassSessionDateFieldLabel => 'بەروار';

  @override
  String get teacherClassSessionTimeFieldLabel => 'کات';

  @override
  String get youClassSessionsTitle => 'دانیشتنەکانی پۆل';

  @override
  String get youClassSessionsSubtitle =>
      'ئەو دانیشتنانەی مامۆستا لە پرۆفایلەکەتدا تۆمار دەکات';

  @override
  String get youClassSessionsEmpty => 'هێشتا دانیشتن تۆمار نەکراوە.';

  @override
  String get studentPanelTitle => 'پانێلی پۆل';

  @override
  String get studentPanelFabTooltip => 'کردنەوەی پانێلی پۆل';

  @override
  String get myPanelFab => 'پانێلی من';

  @override
  String get studentPanelHeadline =>
      'مامۆستا، دانیشتن و پەیامەکان لە یەک شوێن.';

  @override
  String get studentPanelStatUnread => 'نەخوێندراوە';

  @override
  String get teacherClassSessionsHintEmpty =>
      'بە + هەر دانیشتنێک تۆمار بکە؛ کاتەکە خۆکار پاشەکەوت دەکرێت.';

  @override
  String get teacherClassSessionsTabSubtitleTerms =>
      'خولەکان دروست بکە و بۆ هەر خولێک زۆرترین ژمارەی دانیشتن دیاری بکە؛ دانیشتنەکان لەژێر هەمان خول تۆمار بکە؛ قوتابی هەمان گروپکردن دەبینێت.';

  @override
  String get teacherClassTermsSection => 'خولەکان';

  @override
  String teacherClassTermTitle(int number) {
    return 'خول $number';
  }

  @override
  String teacherClassTermSessionsProgress(int current, int max) {
    return '$current لە $max دانیشتن';
  }

  @override
  String get teacherClassTermsAddButton => 'زیادکردنی خول';

  @override
  String get teacherClassTermsEmptyHint =>
      'سەرەتا خولێک دروست بکە و سنووری دانیشتن دیاری بکە؛ پاشان دانیشتنەکان لەژێر هەمان خول تۆمار بکە.';

  @override
  String get teacherClassTermEditCapTitle => 'سنووری دانیشتن';

  @override
  String get teacherClassTermCapFieldLabel =>
      'زۆرترین ژمارەی دانیشتن لەم خولەدا';

  @override
  String get teacherClassTermDeleteConfirmTitle => 'ئەم خولە بسڕدرێتەوە؟';

  @override
  String get teacherClassTermDeleteConfirmBody =>
      'هەموو دانیشتنە تۆمارکراوەکان لەم خولەدا دەسڕدرێنەوە و ناتوانرێت بگەڕێندرێتەوە.';

  @override
  String get teacherClassTermAdded => 'خول زیادکرا';

  @override
  String get teacherClassTermUpdated => 'خول نوێکرایەوە';

  @override
  String get teacherClassTermDeleted => 'خول سڕایەوە';

  @override
  String get teacherClassTermAddSessionButton => 'تۆمارکردنی دانیشتن';

  @override
  String get classTermPaymentPaid => 'پارەدراوە';

  @override
  String get classTermPaymentUnpaid => 'پارە نەدراوە';

  @override
  String get classTermPaymentUpdated => 'دۆخی پارەدان نوێکرایەوە';

  @override
  String get teacherSessionCountLabel => 'ژمارەی وانە تۆمارکراوەکان';

  @override
  String get teacherSessionSave => 'پاشەکەوت';

  @override
  String get teacherSessionSaveNote => 'پاشەکەوتکردنی تێبینی';

  @override
  String get teacherSessionUpdated => 'پاشەکەوت کرا';

  @override
  String get teacherSessionInvalid => 'ژمارەیەکی دروست بنووسە (٠ یان زیاتر).';

  @override
  String get teacherAccessDenied =>
      'تەنها هەژماری مامۆستا دەتوانێت بچێتە ناو ئەم بەشە.';

  @override
  String get teacherNoResults => 'هێشتا ئەنجام نییە';

  @override
  String get teacherNoteLabel => 'تێبینی مامۆستا';

  @override
  String get teacherNotePlaceholder =>
      'تێبینی تایبەت دەربارەی ئەم قوتابیە (تەنها تۆ دەبینیت)';

  @override
  String get bookQuizSetupIntro =>
      'یەکەکان، ژمارەی پرسیار و ڕاهێنان لەسەر هەڵەکانی پێشوو هەڵبژێرە.';

  @override
  String get bookQuizWordPoolTitle => 'کۆمەڵەی وشەکان';

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
  String get goToAuth => 'چوونەژوورەوە / تۆمارکردن';

  @override
  String get accountTitle => 'هەژمار';

  @override
  String get tabSignIn => 'چوونەژوورەوە';

  @override
  String get tabRegister => 'تۆمارکردن';

  @override
  String get statsMyProgress => 'پێشکەوتنم';

  @override
  String get statsTabVocab => 'وشەکان';

  @override
  String get statsTabGrammar => 'ڕێزمان';

  @override
  String get statsTabProgress => 'پێشکەوتن';

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
  String get passwordResetSendCode => 'ناردنی کۆد';

  @override
  String get passwordResetCodeSent => 'کۆد بۆ ئیمەیڵ نێردرا';

  @override
  String get passwordResetSendFailed => 'ناردنی کۆد سەرکەوتوو نەبوو';

  @override
  String get passwordResetHelper =>
      'ئەگەر ئیمەیڵەکەت لە سیستەم هەبێت، کۆد دەنێردرێت.';

  @override
  String get passwordResetCodeLabel => 'کۆدی ٦ ژمارەیی';

  @override
  String get passwordResetNewPassword => 'وشەی نهێنی نوێ';

  @override
  String get passwordResetConfirmPassword => 'دووبارەکردنەوەی وشەی نهێنی نوێ';

  @override
  String get passwordResetChangeButton => 'گۆڕینی وشەی نهێنی';

  @override
  String get passwordResetInvalidCode => 'کۆدەکە نادروستە یان بەسەرچووە';

  @override
  String get passwordResetPasswordsMismatch => 'وشەکانی نهێنی یەک نین';

  @override
  String get passwordResetSuccess => 'وشەی نهێنی بەسەرکەوتوویی گۆڕدرا';

  @override
  String get passwordResetChangeFailed =>
      'گۆڕینی وشەی نهێنی سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.';

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
      'ئەم هەڵبژاردنە ئەو وشانە لەخۆ دەگرێت کە خۆت وەک گرنگ نیشانت کردووە (کاتێک چوویتە ژوورەوە هاوکات دەبێت).';

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
  String get bookQuizSectionsTitle => 'بەشەکان';

  @override
  String get bookQuizSectionsHint =>
      'بۆ هەر یەکەیەک یەک یان زیاتر بەش بۆ کویز هەڵبژێرە.';

  @override
  String get bookQuizSectionsSelectAll => 'هەمووی هەڵبژێرە';

  @override
  String get bookQuizSectionsClear => 'پاککردنەوە';

  @override
  String get bookQuizPickAtLeastOneSection =>
      'لانیکەم یەک بەش لە هەر یەکەی هەڵبژێردراو پێویستە.';

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
  String get profilePasswordSectionTitle => 'وشەی نهێنی';

  @override
  String get profilePasswordSecurityNote =>
      'بۆ ئاسایش، وشەی نهێنیت لەسەر سێرڤەر وەک هاش هەڵدەگیرێت و ناتوانرێت پیشان بدرێت. بۆ گۆڕین، وشەی نهێنی ئێستا و نوێ لە خانەکان بنووسە؛ بە ئایکۆنی چاو دەتوانیت لە کاتی نووسیندا دەربکەیت یان بشاریتەوە.';

  @override
  String get profileCurrentPasswordLabel => 'وشەی نهێنی ئێستا';

  @override
  String get profilePasswordTooLong => 'وشەی نهێنی دەبێت زۆرترین ٧٢ پیت بێت';

  @override
  String get profilePasswordSameAsCurrent =>
      'وشەیەکی نهێنی هەڵبژێرە جیاواز لە ئێستا.';

  @override
  String get profileWrongCurrentPassword => 'وشەی نهێنی ئێستا هەڵەیە';

  @override
  String get showPassword => 'پیشاندانی وشەی نهێنی';

  @override
  String get hidePassword => 'شاردنەوەی وشەی نهێنی';

  @override
  String get save => 'پاشەکەوت';

  @override
  String get grammarResultsScreenTitle => 'ئەنجامەکانی ڕێزمان';

  @override
  String get grammarExplanationTabFa => 'فارسی';

  @override
  String get grammarExplanationTabCkb => 'کوردی';

  @override
  String get translationLangKurdiTab => 'کوردی';

  @override
  String get grammarExplanationTabEn => 'ئینگلیزی';

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
  String get grammarSortNewest => 'نوێترین';

  @override
  String get grammarSortMostPractice => 'زۆرترین مەشق';

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
  String grammarCommunityQuizTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تاقیکردنەوەی گرامەر تەواوکراو',
      one: '١ تاقیکردنەوەی گرامەر تەواوکراو',
    );
    return '$_temp0';
  }

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

  @override
  String get adminUsersTitle => 'بەڕێوەبردنی بەکارهێنەران';

  @override
  String get adminUserManagement => 'بەڕێوەبردنی بەکارهێنەران';

  @override
  String get adminSearchUsersHint => 'گەڕان بە ئیمەیڵ، ناو یان مامۆستا…';

  @override
  String get adminStudentAccess => 'هەژماری قوتابی';

  @override
  String get adminTeacherAccess => 'هەژماری مامۆستا';

  @override
  String get adminAssignedTeacher => 'مامۆستای پۆل';

  @override
  String get adminNoTeacher => 'بێ مامۆستا';

  @override
  String get adminSave => 'پاشەکەوت';

  @override
  String get adminUpdated => 'پاشەکەوت کرا';

  @override
  String get adminAccessDenied => 'دەستپێگەیشتنی بەڕێوەبەرت نییە.';

  @override
  String get adminTeacherInvalid => 'هەژماری مامۆستایەکی دروست هەڵبژێرە.';

  @override
  String get adminNoUsers => 'هیچ بەکارهێنەرێک لە سێرڤەر نەهاتەوە.';

  @override
  String get adminNoSearchResults => 'بەکارهێنەر بەم گەڕانەوە نییە.';

  @override
  String get adminRoleTeacher => 'مامۆستا';

  @override
  String get adminRoleAdmin => 'بەڕێوەبەر';

  @override
  String get youSectionAdmin => 'بەڕێوەبردن';

  @override
  String get youAdminPanelSubtitle =>
      'دەستپێگەیشتنی قوتابی، مامۆستا و هەژمارەکان';

  @override
  String get adminScreenSubtitle =>
      'بگەڕێ و بۆ دەستکاری کرتە لەسەر بەکارهێنەر بکە';

  @override
  String get wordBuilderClearPath => 'سڕینەوەی هێڵ';

  @override
  String get wordBuilderTitle => 'دروستکەری وشە';

  @override
  String get wordBuilderShuffle => 'تێکەڵکردنی پیتەکان';

  @override
  String get wordBuilderPickSource => 'سەرچاوەی وشە هەڵبژێرە';

  @override
  String get wordBuilderStartPlay => 'دەستپێکردن';

  @override
  String get wordBuilderCatalogAll => 'هەموو کتێبەکان';

  @override
  String get wordBuilderNoWordsBody =>
      'بۆ ئەم سەرچاوەیە وشەی ئینگلیزی گونجاو نەدۆزرایەوە. کتێبێکی تر هەڵبژێرە یان دووبارە هەوڵ بدە.';

  @override
  String get wordBuilderHomeSubtitle =>
      'وشەی ئینگلیزی لە پیتە تێکەڵاوەکان دروست بکە.';

  @override
  String wordBuilderLevelOf(int current, int total) {
    return 'ئاست $current لە $total';
  }

  @override
  String wordBuilderCategory(String name) {
    return 'بابەت: $name';
  }

  @override
  String get wordBuilderDifficultyBeginner => 'سەرەتایی';

  @override
  String get wordBuilderDifficultyIntermediate => 'مامناوەند';

  @override
  String get wordBuilderDifficultyAdvanced => 'پێشکەوتوو';

  @override
  String get wordBuilderYourWord => 'وشەکەت';

  @override
  String get wordBuilderLetters => 'پیتەکان';

  @override
  String get wordBuilderSubmit => 'پشکنین';

  @override
  String get wordBuilderReset => 'سڕینەوە';

  @override
  String get wordBuilderNextLevel => 'ئاستی دواتر';

  @override
  String get wordBuilderHints => 'یارمەتی';

  @override
  String get wordBuilderHintReveal => 'پیتێک دەربکە';

  @override
  String get wordBuilderHintRemove => 'پیتێکی زیادە لاببە';

  @override
  String get wordBuilderHintMeaning => 'واتایەک پیشان بدە';

  @override
  String get wordBuilderTranslation => 'وەرگێڕان';

  @override
  String get wordBuilderTooShort => 'سەرەتا پیت زیاتر هەڵبژێرە.';

  @override
  String get wordBuilderAlreadyFound => 'ئەم وشەتەت دۆزییەوە.';

  @override
  String get wordBuilderTryAgain => 'لەم ئاستەدا نییە — بەردەوام بە.';

  @override
  String get wordBuilderCorrectNice => 'باشە!';

  @override
  String get wordBuilderLevelCompleteTitle => 'ئاستەکە تەواو بوو!';

  @override
  String get wordBuilderLevelCompleteBody =>
      'زۆر باش بوو؛ هەموو وشەکانی ئەم ئاستەت دۆزییەوە.';

  @override
  String get wordBuilderHintLetter => 'پیتێک لە یەکێک لە وشەکان دەردەکەوێت.';

  @override
  String get wordBuilderHintRemoved => 'پیتێکی زیادە لە وشەکەت لابرا.';

  @override
  String get wordBuilderHintRemoveNone => 'ئێستا پیتێکی زیادە نییە.';

  @override
  String get wordBuilderNotEnoughCoins =>
      'سکە بەس نییە. بە دۆزینەوەی وشەکان سکە بەدەست بهێنە.';

  @override
  String wordBuilderCoinsCost(int coins) {
    return '$coins سکە';
  }

  @override
  String wordBuilderCoinsBalance(int coins) {
    return '$coins';
  }

  @override
  String get wordBuilderSessionSoundTitle => 'دەنگ';

  @override
  String get wordBuilderSessionBgmSwitch => 'مۆسیقای پاشبنەما';

  @override
  String get wordBuilderSessionBgmSubtitle =>
      'لەم یارییەدا کاتێک وشەکان دەکۆڵیتەوە دەگوازرێتەوە.';

  @override
  String get wordBuilderSessionSfxSwitch => 'دەنگەکانی یاری';

  @override
  String get wordBuilderSessionSfxSubtitle =>
      'وەڵامی ڕاست، هەڵە و کۆتایی قۆناغ.';

  @override
  String get wordBuilderSessionWaterSfxSwitch => 'دەنگەکانی ئاو';

  @override
  String get wordBuilderSessionWaterSfxSubtitle =>
      'ڕژانی ئاو، فشار و کاریگەری سینی کاتێک هەڵە دەکەیت.';

  @override
  String wordBuilderHintMeaningLine(String meaning) {
    return 'یارمەتی: $meaning';
  }

  @override
  String get wordBuilderAllLevelsDone => 'هەموو ئاستەکانی ئەم دانیشتنە تەواون.';

  @override
  String wordBuilderTotalXp(int xp) {
    return 'کۆی XP: $xp';
  }

  @override
  String wordBuilderAccuracy(int pct) {
    return 'وردی: $pct٪';
  }

  @override
  String get wordBuilderPronunciation => 'دەنگکردن';

  @override
  String get wordBuilderMeaning => 'واتا';

  @override
  String get wordBuilderExample => 'نموونە';

  @override
  String get wordBuilderSpeakWord => 'وتنی وشە';

  @override
  String get wordBuilderSpeakExample => 'وتنی ڕستە';

  @override
  String get wordBuilderTargetsHeading => 'وشە مەبەستەکان';

  @override
  String get wordBuilderCampaignHubSubtitle => '';

  @override
  String get wordBuilderCampaignStagesHint => '';

  @override
  String get wordBuilderCampaignStageLockedSnackbar =>
      'سەرەتا قۆناغی پێشوو تەواو بکە.';

  @override
  String get wordBuilderCampaignTierLockedBody =>
      'بۆ کردنەوەی ئەم ئاستە، هەموو ٥٠ قۆناغی ئاستی پێشوو تەواو بکە.';

  @override
  String get wordBuilderCampaignPlanError =>
      'وشەی پێویست بۆ ئەم قۆناغە نییە. دواتر هەوڵ بدەوە.';

  @override
  String get wordBuilderCampaignReset => 'ڕێکخستنەوەی پێشکەوتن';

  @override
  String get wordBuilderCampaignResetConfirm =>
      'هەموو پێشڕەوی واژەساز بسڕدرێتەوە؟ گەڕانەوە نییە.';

  @override
  String get wordBuilderCampaignResetDone => 'پێشڕەوی قۆناغەکان سڕایەوە.';

  @override
  String wordBuilderCampaignStageOf(int stage, int total) {
    return 'قۆناغ $stage لە $total';
  }

  @override
  String wordBuilderCampaignStageN(int n) {
    return 'قۆناغ $n';
  }

  @override
  String get wordBuilderCampaignStageCompleted => 'تەواو';

  @override
  String get wordBuilderCampaignStageReplayHint => 'کرتە بکە بۆ دووبارەکردنەوە';

  @override
  String get adminEditUserSheetTitle => 'دەستکاری دەستپێگەیشتن';

  @override
  String get previous => 'پێشوو';

  @override
  String get finish => 'کۆتایی';

  @override
  String get noWordsForSection => 'وشە بۆ ئەم بەشە نییە.';

  @override
  String get noFavoriteWordsYet => 'هێشتا وشەی دڵخوازت نییە.';

  @override
  String get tapCardToRevealAndRate =>
      'کارتەکە بکەرەوە بۆ بینینی وەڵام و نمرەدان';

  @override
  String get tapToFlip => 'کرتە بکە بۆ گۆڕین';

  @override
  String flashcardCardProgress(int current, int total) {
    return 'کارت $current لە $total';
  }

  @override
  String get flashcardMeaningLabel => 'واتا';

  @override
  String get flashcardWordLabel => 'وشە';

  @override
  String get allCardsReviewed => 'هەموو کارتەکان پێداچوونەوە کران!';

  @override
  String couldNotLoadSectionsWithError(String error) {
    return 'بارکردنی بەشەکان سەرکەوتوو نەبوو.\n$error';
  }

  @override
  String couldNotLoadUnitsWithError(String error) {
    return 'بارکردنی یەکەکان سەرکەوتوو نەبوو.\n$error';
  }

  @override
  String get noUnitsFound => 'هیچ یەکەیەک لەم داتاسێتەدا نەدۆزرایەوە.';

  @override
  String unitsGridHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count یەکە · کرتە بکە بۆ کردنەوە',
      one: '١ یەکە · کرتە بکە بۆ کردنەوە',
    );
    return '$_temp0';
  }

  @override
  String get checkingEllipsis => 'پشکنین…';

  @override
  String get backToUnits => 'گەڕانەوە بۆ یەکەکان';

  @override
  String get englishMeaning => 'واتای ئینگلیزی';

  @override
  String get wordsTabLabel => 'وشەکان';

  @override
  String get samplesTabLabel => 'دەقی نموونە';

  @override
  String unitSectionLine(int unit, int section) {
    return 'یەکە $unit · بەش $section';
  }

  @override
  String sectionNumberLabel(int section) {
    return 'بەش $section';
  }

  @override
  String get grammarReviewQuestionsHeading => 'پرسیارەکان';

  @override
  String get grammarNoPerQuestionData =>
      'زانیاری هەر پرسیارێک پاشەکەوت نەکراوە (ئەنجامی کۆن یان گواستنەوەی سێرڤەر).';

  @override
  String grammarReviewQuestionTitle(int index, String topic) {
    return 'پ$index · $topic';
  }

  @override
  String get answerCorrect => 'ڕاست';

  @override
  String get answerIncorrect => 'هەڵە';

  @override
  String statsQuizCorrectFraction(int correct, int answered) {
    return '$correct / $answered ڕاست';
  }

  @override
  String statsAccuracyPercent(String pct) {
    return 'وردی $pct٪';
  }

  @override
  String get unitSamplesLoadingCatalog => 'بارکردنی پێرستی وشەکان…';

  @override
  String get unitSamplesTextSize => 'قەبارەی دەق';

  @override
  String get profilePresetBoy1 => 'کوڕ ١';

  @override
  String get profilePresetBoy2 => 'کوڕ ٢';

  @override
  String get profilePresetBoy3 => 'کوڕ ٣';

  @override
  String get profilePresetBoy4 => 'کوڕ ٤';

  @override
  String get profilePresetGirl1 => 'کچ ١';

  @override
  String get profilePresetGirl2 => 'کچ ٢';

  @override
  String get profilePresetGirl3 => 'کچ ٣';

  @override
  String get profilePresetGirl4 => 'کچ ٤';

  @override
  String get unitSampleUntitled => 'نموونە';

  @override
  String get sampleHighlightPickMainColor => 'ڕەنگی دیاریکردن';

  @override
  String get sampleHighlightTapColor => 'ڕەنگێک بگرە بۆ دیاریکردن';

  @override
  String get sampleHighlightRemove => 'سڕینەوەی دیاریکردن';

  @override
  String get sampleHighlightDefaultColor => 'دیاریکردن';
}
