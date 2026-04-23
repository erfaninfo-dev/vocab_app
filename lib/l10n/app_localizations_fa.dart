// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Erfan Academy';

  @override
  String get tabHome => 'خانه';

  @override
  String get tabGrammar => 'گرامر';

  @override
  String get tabReview => 'مرور';

  @override
  String get tabProgress => 'پیشرفت';

  @override
  String get tabYou => 'شما';

  @override
  String get tabSettings => 'تنظیمات';

  @override
  String get youPageTitle => 'شما';

  @override
  String get youSectionProgress => 'پیشرفت';

  @override
  String get youSectionProgressSubtitle => 'استریک، آمار و نتایج آزمون';

  @override
  String get youSectionMessages => 'مدرس شما';

  @override
  String get youSectionMessagesHub => 'پیام‌ها';

  @override
  String get youSectionMessagesSubtitle => 'گفت‌وگو با مدرس کلاس';

  @override
  String get youSectionMessagesSubtitleHub => 'گفت‌وگو با مدرس و پشتیبان';

  @override
  String get youMessagesPickTitle => 'گفت‌وگوها';

  @override
  String get youTeacherPanelSubtitle => 'دانش‌آموزان و فعالیت کلاس';

  @override
  String get chatSenderYou => 'شما';

  @override
  String get teacherStudentChat => 'گفت‌وگو';

  @override
  String get teacherInboxTitle => 'پیام‌ها';

  @override
  String get teacherInboxOpenPanel => 'همهٔ دانش‌آموزان';

  @override
  String get chatListYesterday => 'دیروز';

  @override
  String get chatPreviewYouPrefix => 'شما: ';

  @override
  String get teacherChatHint => 'پیام…';

  @override
  String get teacherMessagesEmpty => 'هنوز پیامی نیست.';

  @override
  String get chatMessageEdit => 'ویرایش';

  @override
  String get chatMessageEditTitle => 'ویرایش پیام';

  @override
  String get chatMessageEditHint => 'پیام خود را به‌روزرسانی کنید…';

  @override
  String get chatMessageEdited => 'ویرایش‌شده';

  @override
  String get chatMessageEditFailedRead =>
      'این پیام خوانده شده و دیگر قابل ویرایش نیست.';

  @override
  String get chatMessageEditSave => 'ذخیره';

  @override
  String get chatMessageReadStateSent => 'ارسال شد';

  @override
  String get chatMessageReadStateRead => 'دیده شد';

  @override
  String get teacherMessagesNoTeacher =>
      'با کد دانش‌آموزی، مدرس به شما وصل می‌شود.';

  @override
  String newMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پیام جدید',
      one: '۱ پیام جدید',
      zero: 'پیام جدیدی نیست',
    );
    return '$_temp0';
  }

  @override
  String get tabStudents => 'دانش‌آموز';

  @override
  String get studentBooksTitle => 'کتاب‌های کلاس شما';

  @override
  String get registerAsStudent => 'دانش‌آموز شما';

  @override
  String get studentCodeLabel => 'کد دانش‌آموزی';

  @override
  String get studentCodeRequired => 'کدی که مدرس به شما داده را وارد کنید';

  @override
  String get redeemStudentCode => 'وارد کردن کد دانش‌آموزی';

  @override
  String get redeemStudentCodeSubtitle =>
      'با کد شخصی‌تان تب دانش‌آموز را باز کنید.';

  @override
  String get invalidStudentCode => 'کد نامعتبر یا منقضی است.';

  @override
  String get studentAccessGranted => 'دسترسی دانش‌آموزی فعال شد.';

  @override
  String get studentTabSignIn => 'برای دیدن کتاب‌های کلاس، وارد حساب شوید.';

  @override
  String get back => 'بازگشت';

  @override
  String get next => 'بعدی';

  @override
  String get skip => 'رد کردن';

  @override
  String get cancel => 'لغو';

  @override
  String get continueLabel => 'ادامه';

  @override
  String get close => 'بستن';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get loading => 'در حال بارگذاری…';

  @override
  String get search => 'جستجو';

  @override
  String get errorGeneric => 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.';

  @override
  String get errServerReturnedError =>
      'سرور خطا برگرداند. بعداً دوباره تلاش کنید.';

  @override
  String get splashTagline => 'تمرین آرام و متمرکز واژگان';

  @override
  String get languageSelectionTitle => 'زبان برنامه را انتخاب کنید';

  @override
  String get languageSelectionSubtitle =>
      'هر زمان از تنظیمات می‌توانید تغییر دهید.';

  @override
  String get langEnglish => 'English';

  @override
  String get langPersian => 'فارسی';

  @override
  String get langKurdishSorani => 'کوردی (سورانی)';

  @override
  String get chooseYourBook => 'کتاب خود را انتخاب کنید';

  @override
  String booksAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کتاب موجود',
      one: '۱ کتاب موجود',
      zero: 'کتابی موجود نیست',
    );
    return '$_temp0';
  }

  @override
  String get searchBooksHint => 'جستجوی کتاب…';

  @override
  String get homeReceivingBooks => 'در حال دریافت…';

  @override
  String get couldNotLoadBooks => 'بارگذاری کتاب‌ها انجام نشد.';

  @override
  String couldNotLoadBooksWithError(String error) {
    return 'بارگذاری کتاب‌ها انجام نشد.\n$error';
  }

  @override
  String get noBooksFound => 'کتابی یافت نشد';

  @override
  String get homeTrackIelts => 'آیلتس';

  @override
  String get homeTrackGeneral => 'عمومی';

  @override
  String get homeBooksSeriesOther => 'سایر کتاب‌ها';

  @override
  String get homeSeriesCambridgeTests => 'آزمون‌های کمبریج آیلتس';

  @override
  String homeSeriesVolumesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کتاب در این سری',
      one: '۱ کتاب در این سری',
    );
    return '$_temp0';
  }

  @override
  String seriesBooksGridHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کتاب · برای باز کردن روی کارت بزنید',
      one: '۱ کتاب · برای باز کردن روی کارت بزنید',
    );
    return '$_temp0';
  }

  @override
  String get bookSingular => 'کتاب';

  @override
  String get bookPlural => 'کتاب';

  @override
  String get unitSingular => 'یونیت';

  @override
  String get unitPlural => 'یونیت';

  @override
  String get loadingEllipsis => 'در حال بارگذاری…';

  @override
  String get tapToOpen => 'برای باز کردن بزنید';

  @override
  String get grammarPracticeTitle => 'تمرین گرامر';

  @override
  String get grammarPracticeSubtitle =>
      'سؤالات چندگزینه‌ای بر اساس موضوع گرامر';

  @override
  String reviewWordsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغت برای مرور!',
      one: '۱ لغت برای مرور!',
    );
    return '$_temp0';
  }

  @override
  String get reviewTapStart => 'برای شروع جلسهٔ مرور روزانه بزنید';

  @override
  String get obSlide1Title => 'کتاب‌ها و لغات';

  @override
  String get obSlide1Body =>
      'از خانه شروع کنید: کتاب را انتخاب کنید، یونیت‌ها را باز کنید و لغات را ببینید. با فلش‌کارت و کوییز در هر یونیت همان‌طور که دوست دارید یاد بگیرید.';

  @override
  String get obSlide2Title => 'تمرین گرامر';

  @override
  String get obSlide2Body =>
      'زیر تب گرامر را باز کنید. یک یا چند موضوع انتخاب و جلسه را شروع کنید — هر بار ۲۰ سؤال تصادفی با توضیح.';

  @override
  String get obSlide3Title => 'مرور روزانه';

  @override
  String get obSlide3Body =>
      'مرور با تکرار با فاصله برای لغاتی که تمرین کرده‌اید کار می‌کند. وقتی کارت موعد دارند، نشان روی تب را ببینید.';

  @override
  String get obSlide4Title => 'پیشرفت شما';

  @override
  String get obSlide4Body =>
      'پیشرفت، استریک و فعالیت را نشان می‌دهد. با ریتم ثابت عادت بسازید.';

  @override
  String get obSlide5Title => 'شخصی‌سازی';

  @override
  String get obSlide5Body =>
      'در تنظیمات: تم، زبان ترجمهٔ لغات (فارسی / کوردی سورانی)، یادآور و بیشتر.';

  @override
  String get getStarted => 'شروع';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get sectionAccount => 'حساب کاربری';

  @override
  String get signIn => 'ورود';

  @override
  String get signInSubtitle => 'اختیاری — با ایمیل و رمز عبور';

  @override
  String get createAccount => 'ساخت حساب';

  @override
  String get profile => 'پروفایل';

  @override
  String get signOut => 'خروج';

  @override
  String get signOutTitle => 'خروج از حساب؟';

  @override
  String get signOutBody => 'آیا مطمئن هستید که می‌خواهید خارج شوید؟';

  @override
  String get signedOut => 'خارج شدید';

  @override
  String get loadingAccount => 'در حال بارگذاری حساب…';

  @override
  String get sectionTranslationLanguage => 'زبان ترجمهٔ لغات';

  @override
  String get translationLangPersian => 'فارسی';

  @override
  String get translationLangKurdishSorani => 'کوردی (سورانی)';

  @override
  String get sectionAppearance => 'ظاهر';

  @override
  String get systemTheme => 'تم سیستم';

  @override
  String get lightMode => 'حالت روشن';

  @override
  String get darkMode => 'حالت تیره';

  @override
  String get sectionDailyReminder => 'یادآور روزانه';

  @override
  String get dailyStudyReminder => 'یادآور مطالعهٔ روزانه';

  @override
  String reminderSetAt(String time) {
    return 'یادآور روی $time';
  }

  @override
  String get tapToEnableReminder => 'برای فعال‌سازی بزنید';

  @override
  String get reminderTime => 'زمان یادآور';

  @override
  String get sectionAbout => 'درباره';

  @override
  String get sectionAppLanguage => 'زبان برنامه';

  @override
  String get appLanguageSubtitle =>
      'زبان رابط (انگلیسی، فارسی یا کوردی سورانی)';

  @override
  String get linkCopied => 'لینک در کلیپ‌بورد کپی شد';

  @override
  String get appNameShort => 'Erfan Academy';

  @override
  String get byAuthor => 'اثر عرفان عبدی';

  @override
  String get errNoInternet => 'اتصال اینترنت برقرار نیست. شبکه را بررسی کنید.';

  @override
  String get errBadData => 'خواندن داده ممکن نشد. دوباره تلاش کنید.';

  @override
  String get errServer => 'ارتباط با سرور برقرار نشد. دوباره تلاش کنید.';

  @override
  String get reviewToday => 'مرور امروز';

  @override
  String dueCount(int count) {
    return '$count موعد';
  }

  @override
  String get fetchErrorRetry => 'بارگذاری داده انجام نشد. دوباره تلاش کنید.';

  @override
  String get tapCardToReveal => 'روی کارت بزنید تا پاسخ نمایش داده شود';

  @override
  String get translateThisWord => 'این لغت را ترجمه کنید';

  @override
  String get answer => 'پاسخ';

  @override
  String get tapToSeeAnswer => 'برای دیدن پاسخ بزنید';

  @override
  String get howWellKnew => 'چقدر بلد بودید؟';

  @override
  String get pronounce => 'تلفظ';

  @override
  String get speaking => 'در حال پخش…';

  @override
  String get noWordsDueTitle => 'امروز لغتی برای مرور نیست!';

  @override
  String get noWordsDueBodyFlashcards =>
      'با فلش‌کارت تمرین کنید تا صف مرور پر شود.';

  @override
  String noWordsDueBodyGreat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغت',
      one: '۱ لغت',
    );
    return 'عالی! فردا دوباره سر بزنید.\n$_temp0 در صف شما.';
  }

  @override
  String get sessionComplete => 'جلسه تمام شد!';

  @override
  String youReviewedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغت',
      one: '۱ لغت',
    );
    return 'امروز $_temp0 مرور کردید.';
  }

  @override
  String wordsProgress(int current, int total) {
    return '$current / $total لغت';
  }

  @override
  String get quizTitle => 'کوییز';

  @override
  String get couldNotLoadWords => 'بارگذاری داده انجام نشد. دوباره تلاش کنید.';

  @override
  String get couldNotLoadMistakes => 'بارگذاری لیست اشتباهات ممکن نشد';

  @override
  String get quizNotEnoughImportant =>
      'در این محدوده لغت مهمی نیست. همهٔ لغات را انتخاب کنید، محدوده را عوض کنید یا یونیت‌های بیشتری بگیرید.';

  @override
  String get quizNotEnoughWrongs =>
      'در این انتخاب لغتی از اشتباهات شما نیست. یونیت‌ها را عوض کنید یا «فقط اشتباهات قبلی» را خاموش کنید.';

  @override
  String get quizNeedFourWords => 'حداقل ۴ لغت برای شروع این کوییز لازم است.';

  @override
  String get quizNeedOneWord => 'حداقل ۱ لغت برای شروع این کوییز لازم است.';

  @override
  String get quizScopeTitle => 'محدودهٔ کوییز';

  @override
  String get quizScopeImportantDescription =>
      'این لیست لغات مهم دارد. انتخاب کنید کوییز همهٔ لغات را بپوشد یا فقط مهم‌ها را.';

  @override
  String allWordsCount(int count) {
    return 'همهٔ لغات ($count)';
  }

  @override
  String importantWordsOnlyCount(int count) {
    return 'فقط لغات مهم ($count)';
  }

  @override
  String get importantOnlyNeedsFour =>
      'فقط لغاتی را که روی سرور مهم علامت خورده‌اند کوییز بگیرید.';

  @override
  String get quizSetupTitle => 'تنظیم کوییز';

  @override
  String quizPoolSummary(int pool, int min, int max) {
    return '$pool لغت در مجموعه · حداقل $min سؤال · حداکثر $max';
  }

  @override
  String get onlyPastMistakes => 'فقط اشتباهات قبلی';

  @override
  String get noMistakesYet => 'هنوز اشتباهی برای این محدوده ثبت نشده.';

  @override
  String mistakesOnServer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اشتباه',
      one: '۱ اشتباه',
    );
    return '$_temp0 روی سرور';
  }

  @override
  String get signInForMistakes =>
      'برای همگام‌سازی اشتباهات و حالت «اشتباهات قبلی» وارد شوید.';

  @override
  String get numberOfQuestions => 'تعداد سؤال';

  @override
  String get questionModes => 'حالت‌های سؤال';

  @override
  String get startQuiz => 'شروع کوییز';

  @override
  String get quizMcqWordToMeaning => 'لغت → معنی';

  @override
  String get quizMcqMeaningToWord => 'معنی → لغت';

  @override
  String get quizWrittenMeaningToWord => 'جای خالی';

  @override
  String get quizSpellingListenAndType => 'شنیداری و املا';

  @override
  String get quizSpellingListenPrompt => 'گوش کن و لغت انگلیسی را بنویس:';

  @override
  String get quizReplayAudio => 'پخش مجدد';

  @override
  String get quizSpellingTypeEnglish => 'لغت انگلیسی را بنویسید';

  @override
  String get whatIsMeaningOf => 'معنی این چیست:';

  @override
  String get whichWordMeans => 'کدام لغت این معنی را می‌دهد:';

  @override
  String get typeTheWord => 'لغت را بنویسید';

  @override
  String get typeYourAnswer => 'پاسخ خود را بنویسید…';

  @override
  String get submit => 'ارسال';

  @override
  String get seeResults => 'مشاهدهٔ نتایج';

  @override
  String get nextQuestion => 'سؤال بعدی';

  @override
  String get updating => 'در حال به‌روزرسانی…';

  @override
  String get learnedRemoveMistakes => 'یاد گرفتم — حذف از اشتباهات';

  @override
  String questionProgress(int current, int total) {
    return 'سؤال $current از $total';
  }

  @override
  String scoreCorrect(int score) {
    return '$score درست';
  }

  @override
  String get perfectScore => 'نمرهٔ کامل!';

  @override
  String get excellentWork => 'عالی!';

  @override
  String get goodJob => 'آفرین!';

  @override
  String get keepPracticing => 'به تمرین ادامه دهید!';

  @override
  String get dontGiveUp => 'ناامید نشوید!';

  @override
  String get tryAgain => 'دوباره';

  @override
  String get backToQuiz => 'بازگشت به کوییز';

  @override
  String get backToWords => 'بازگشت به لغات';

  @override
  String correctLine(String answer) {
    return 'درست: $answer';
  }

  @override
  String wrongBlankLine(String correct) {
    return 'غلط (خالی). پاسخ درست: $correct';
  }

  @override
  String wrongAnswerLine(String given, String correct) {
    return 'غلط: $given · پاسخ درست: $correct';
  }

  @override
  String get quizFeedbackWrongPrefix => 'غلط:';

  @override
  String get quizFeedbackCorrectLabel => 'پاسخ درست:';

  @override
  String get quizWrongBlankIntro => 'غلط (خالی).';

  @override
  String get quizWrittenFirstLetterMismatch =>
      'حرف اول نادرست است؛ پاسخ با این حرف شروع نمی‌شود.';

  @override
  String get removedFromMistakes => 'از لیست اشتباهات شما حذف شد';

  @override
  String get couldNotUpdateServer => 'به‌روزرسانی سرور ممکن نشد';

  @override
  String get unitsTitle => 'یونیت‌ها';

  @override
  String get backToBooks => 'بازگشت به کتاب‌ها';

  @override
  String get bookQuiz => 'کوییز کتاب';

  @override
  String get favorites => 'مورد علاقه';

  @override
  String get failedLoadSections =>
      'بارگذاری بخش‌ها انجام نشد. دوباره تلاش کنید.';

  @override
  String wordsUnitSection(int unit, int section) {
    return 'یونیت $unit • بخش $section';
  }

  @override
  String wordsUnitOnly(int unit) {
    return 'یونیت $unit';
  }

  @override
  String get tooltipQuiz => 'کوییز';

  @override
  String get tooltipFlashcards => 'فلش‌کارت';

  @override
  String get searchWordWholeBook => 'جستجوی لغت (کل کتاب)…';

  @override
  String get noMatchingWords => 'لغت مطابقی یافت نشد.';

  @override
  String sectionInUnit(int section, int unit) {
    return 'بخش $section در یونیت $unit';
  }

  @override
  String unitLabel(int unit) {
    return 'یونیت $unit';
  }

  @override
  String matchesWholeBook(int filtered, int total) {
    return '$filtered از $total مورد (کل کتاب)';
  }

  @override
  String wordsVisible(int filtered, int total) {
    return '$filtered از $total لغت نمایش داده می‌شود';
  }

  @override
  String get vocabularyQuizTitle => 'کوییز واژگان';

  @override
  String get vocabQuizHistoryTitle => 'تاریخچهٔ کوییز لغات';

  @override
  String get vocabQuizHistorySubtitle =>
      'جلسات روی حساب کاربری‌تان ذخیره می‌شود و می‌توانید مرور کنید.';

  @override
  String get vocabQuizHistoryEmpty => 'هنوز جلسه‌ای ثبت نشده است.';

  @override
  String get vocabQuizHistorySignIn =>
      'برای ذخیرهٔ نتایج روی سرور و دیدن تاریخچه، وارد شوید.';

  @override
  String get vocabQuizHistoryLoadError =>
      'بارگذاری تاریخچه ممکن نشد. معمولاً جدول نتایج روی دیتابیس نیست؛ فایل api/vocab_quiz_results_schema.sql را روی MySQL اجرا کنید یا بعداً دوباره امتحان کنید.';

  @override
  String get vocabQuizResultDetailTitle => 'جزئیات جلسه';

  @override
  String vocabQuizResultScoreLine(int score, int total) {
    return '$score از $total درست';
  }

  @override
  String get vocabQuizResultYourAnswer => 'پاسخ شما';

  @override
  String get vocabQuizResultCorrect => 'درست';

  @override
  String get vocabQuizResultIncorrect => 'غلط';

  @override
  String get vocabQuizResultQuestion => 'سؤال';

  @override
  String vocabQuizHistoryUnitsLine(String units) {
    return 'یونیت‌ها: $units';
  }

  @override
  String vocabQuizCorrectWrongLine(int correct, int wrong) {
    return '$correct درست · $wrong غلط';
  }

  @override
  String get vocabQuizViewMistakes => 'مشاهدهٔ غلط‌ها';

  @override
  String get vocabQuizMistakesTitle => 'پاسخ‌های غلط';

  @override
  String get vocabQuizMistakesEmpty => 'در این جلسه پاسخ غلطی ثبت نشده است.';

  @override
  String get teacherPanelTitle => 'پنل استاد';

  @override
  String get teacherPanelSubtitle =>
      'مشاهدهٔ تمرین لغات و گرامر شاگردان و ثبت جلسات کلاس.';

  @override
  String get teacherOpenPanel => 'پنل استاد';

  @override
  String get teacherStudentsEmpty =>
      'هنوز شاگردی متصل نیست. روی سرور، کدهای دانش‌آموزی را به حساب استاد خودتان وصل کنید؛ با همان کد ثبت‌نام کنند تا اینجا بیایند.';

  @override
  String get teacherPanelTabStudents => 'شاگردان';

  @override
  String get teacherPanelTabMessages => 'پیام‌ها';

  @override
  String get teacherStudentDetailTitle => 'شاگرد';

  @override
  String get teacherTabVocabQuiz => 'لغات';

  @override
  String get teacherTabGrammar => 'گرامر';

  @override
  String get teacherTabClassSessions => 'جلسات کلاس';

  @override
  String get teacherClassSessionsTabSubtitle =>
      'جلسه را با یک ضربه اضافه کنید، در صورت نیاز تاریخ و ساعت را اصلاح کنید یا یک مورد را حذف کنید. شاگرد این فهرست را فقط به‌صورت مشاهده می‌بیند.';

  @override
  String teacherClassSessionHeading(int number) {
    return 'جلسه $number';
  }

  @override
  String get teacherClassSessionEdit => 'ویرایش';

  @override
  String get teacherClassSessionDelete => 'حذف';

  @override
  String get teacherClassSessionDeleteConfirmTitle => 'این جلسه حذف شود؟';

  @override
  String get teacherClassSessionDeleteConfirmBody => 'این کار برگشت‌پذیر نیست.';

  @override
  String get teacherClassSessionDeleted => 'جلسه حذف شد';

  @override
  String get teacherClassSessionEditTitle => 'تاریخ و ساعت';

  @override
  String get teacherClassSessionAdded => 'جلسه اضافه شد';

  @override
  String get teacherClassSessions => 'جلسات کلاس';

  @override
  String get teacherClassSessionAddTooltip => 'افزودن جلسهٔ کلاس';

  @override
  String get teacherClassSessionsAddButton => 'افزودن جلسه';

  @override
  String get teacherClassSessionDateFieldLabel => 'تاریخ';

  @override
  String get teacherClassSessionTimeFieldLabel => 'ساعت';

  @override
  String get youClassSessionsTitle => 'جلسات کلاس';

  @override
  String get youClassSessionsSubtitle =>
      'جلسه‌هایی که استاد در پروندهٔ شما ثبت می‌کند';

  @override
  String get youClassSessionsEmpty => 'هنوز جلسه‌ای ثبت نشده است.';

  @override
  String get studentPanelTitle => 'پنل کلاس';

  @override
  String get studentPanelFabTooltip => 'باز کردن پنل کلاس';

  @override
  String get studentPanelHeadline => 'استاد، جلسات و پیام‌ها در یک نگاه.';

  @override
  String get studentPanelStatUnread => 'خوانده‌نشده';

  @override
  String get teacherClassSessionsHintEmpty =>
      'با زدن + هر جلسهٔ کلاس را ثبت کنید؛ زمان به‌صورت خودکار ذخیره می‌شود.';

  @override
  String get teacherSessionCountLabel => 'تعداد جلسات ثبت‌شده';

  @override
  String get teacherSessionSave => 'ذخیره';

  @override
  String get teacherSessionSaveNote => 'ذخیرهٔ یادداشت';

  @override
  String get teacherSessionUpdated => 'ذخیره شد';

  @override
  String get teacherSessionInvalid => 'یک عدد معتبر (۰ یا بیشتر) وارد کنید.';

  @override
  String get teacherAccessDenied => 'فقط حساب استاد به این بخش دسترسی دارد.';

  @override
  String get teacherNoResults => 'هنوز نتیجه‌ای ثبت نشده';

  @override
  String get teacherNoteLabel => 'یادداشت استاد';

  @override
  String get teacherNotePlaceholder =>
      'یادداشت خصوصی دربارهٔ این شاگرد (فقط شما می‌بینید)';

  @override
  String get bookQuizSetupIntro =>
      'یونیت‌ها، تعداد سؤال و حالت تمرین روی اشتباهات قبلی را انتخاب کنید.';

  @override
  String get bookQuizWordPoolTitle => 'محدودهٔ لغات';

  @override
  String get unitsSectionTitle => 'یونیت‌ها';

  @override
  String get couldNotLoadMistakesShort => 'بارگذاری اشتباهات ممکن نشد';

  @override
  String get registerTitle => 'ساخت حساب';

  @override
  String get newAccount => 'حساب جدید';

  @override
  String get registerSubtitle =>
      'ایمیل و رمز (حداقل ۸ کاراکتر) انتخاب کنید. بدون کد ایمیل یا پیامک — بلافاصله می‌توانید وارد شوید.';

  @override
  String get displayNameOptional => 'نام نمایشی (اختیاری)';

  @override
  String get email => 'ایمیل';

  @override
  String get password => 'رمز عبور';

  @override
  String get confirmPassword => 'تکرار رمز';

  @override
  String get register => 'ثبت‌نام';

  @override
  String get alreadyHaveAccount => 'حساب دارید؟ وارد شوید';

  @override
  String get loginTitle => 'ورود';

  @override
  String get welcomeBack => 'خوش برگشتید';

  @override
  String get loginSubtitle =>
      'ایمیل و رمز خود را وارد کنید. بدون تأیید اضافی — حساب بلافاصله فعال است.';

  @override
  String get enterEmail => 'ایمیل را وارد کنید';

  @override
  String get enterValidEmail => 'ایمیل معتبر وارد کنید';

  @override
  String get enterPassword => 'رمز را وارد کنید';

  @override
  String get passwordMinLength => 'حداقل ۸ کاراکتر';

  @override
  String get confirmYourPassword => 'رمز را تکرار کنید';

  @override
  String get passwordsNoMatch => 'رمزها یکسان نیستند';

  @override
  String get signInButton => 'ورود';

  @override
  String get forgotPassword => 'رمز را فراموش کرده‌اید؟';

  @override
  String get createAnAccount => 'ساخت حساب';

  @override
  String get goToAuth => 'ورود / ثبت‌نام';

  @override
  String get accountTitle => 'حساب';

  @override
  String get tabSignIn => 'ورود';

  @override
  String get tabRegister => 'ثبت‌نام';

  @override
  String get statsMyProgress => 'پیشرفت من';

  @override
  String get statsTabVocab => 'واژگان';

  @override
  String get statsTabGrammar => 'گرامر';

  @override
  String get statsTabProgress => 'پیشرفت';

  @override
  String get wordMastery => 'تسلط بر لغات';

  @override
  String get last7Days => '۷ روز اخیر';

  @override
  String get quizInsights => 'تحلیل کوییز';

  @override
  String get allTime => 'همهٔ زمان‌ها';

  @override
  String get vocabAndGrammar => 'واژگان و گرامر';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز',
      one: '۱ روز',
    );
    return 'استریک $_temp0';
  }

  @override
  String get longest => 'طولانی‌ترین';

  @override
  String get totalDays => 'روزهای مطالعه';

  @override
  String get mastered => 'تسلط  ';

  @override
  String get learning => 'در حال یادگیری  ';

  @override
  String get seenOnce => 'یک‌بار دیده  ';

  @override
  String get wordsReviewedPerDay => 'لغات مرورشده در روز';

  @override
  String get totalReviews => 'جمع مرورها';

  @override
  String get studyDays => 'روزهای مطالعه';

  @override
  String get insightsTitle => 'تحلیل کوییز';

  @override
  String get tabOverview => 'نمای کلی';

  @override
  String get tabVocabulary => 'واژگان';

  @override
  String get tabGrammarStats => 'گرامر';

  @override
  String get insightsLast14 =>
      '۱۴ روز اخیر: واژگان (این دستگاه) در برابر گرامر (ذخیره‌شده در حساب).';

  @override
  String get insightsSignInGrammar =>
      'برای بارگذاری نمرات گرامر وارد شوید. میله‌های واژگان همچنان از دادهٔ محلی استفاده می‌کنند.';

  @override
  String get insightsGrammarLoadError =>
      'بارگذاری دادهٔ گرامر برای نمودار ممکن نشد.';

  @override
  String get vocabDailyAccuracy =>
      'دقت روزانه از کوییز واژگان (ذخیره روی این دستگاه).';

  @override
  String get allTimeDevice => 'همهٔ زمان (دستگاه)';

  @override
  String get grammarPracticeAppBar => 'تمرین گرامر';

  @override
  String get grammarTooltipResults => 'نتایج';

  @override
  String get grammarTooltipUnselectAll => 'لغو همهٔ انتخاب‌ها';

  @override
  String get grammarSelectTopicsCta => 'انتخاب موضوعات';

  @override
  String grammarContinueTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ادامه ($count موضوع)',
      one: 'ادامه (۱ موضوع)',
    );
    return '$_temp0';
  }

  @override
  String get grammarCouldNotLoadTopics =>
      'بارگذاری موضوعات گرامر ممکن نشد. دوباره تلاش کنید.';

  @override
  String get grammarNoTopicsEmpty =>
      'هنوز موضوع گرامی نیست.\nبه جدول سؤالات ردیف اضافه کنید (ستون content = نام موضوع).';

  @override
  String grammarNotEnoughInBank(int minRequired) {
    return 'سؤال کافی در بانک برای این انتخاب نیست (حداقل $minRequired لازم است).';
  }

  @override
  String get grammarNoQuestions => 'برای موضوعات انتخاب‌شده سؤالی یافت نشد.';

  @override
  String get grammarTopicsPick => 'موضوعات و طول جلسه را انتخاب کنید';

  @override
  String get exitExerciseTitle => 'خروج از تمرین؟';

  @override
  String get exitExerciseBody =>
      'اگر الان برگردید، پیشرفت این جلسه ذخیره نمی‌شود.';

  @override
  String get stay => 'ماندن';

  @override
  String get exit => 'خروج';

  @override
  String get grammarAppBar => 'گرامر';

  @override
  String get noTopicSelected => 'موضوعی انتخاب نشده.';

  @override
  String get reportSubmitted => 'گزارش ارسال شد';

  @override
  String get reportFailed => 'ارسال گزارش ممکن نشد. دوباره تلاش کنید.';

  @override
  String get submitReport => 'ارسال گزارش';

  @override
  String get couldNotSaveResult => 'ذخیرهٔ نتیجه ممکن نشد. دوباره تلاش کنید.';

  @override
  String get keepPrivate => 'خصوصی (فقط برای من)';

  @override
  String get showCommunity => 'نمایش در نتایج جامعه';

  @override
  String get practiseAgain => 'تمرین دوباره';

  @override
  String get backToTopics => 'بازگشت به موضوعات';

  @override
  String get reviewSessionTitle => 'بازبینی جلسه';

  @override
  String get couldNotLoadResult => 'بارگذاری این نتیجه ممکن نشد.';

  @override
  String get myResults => 'نتایج من';

  @override
  String get users => 'کاربران';

  @override
  String get tryAgainResults => 'دوباره';

  @override
  String get wordExample => 'مثال';

  @override
  String get favorite => 'مورد علاقه';

  @override
  String get important => 'مهم';

  @override
  String get pronounceWord => 'تلفظ لغت';

  @override
  String get pronounceExample => 'تلفظ مثال';

  @override
  String get couldNotUpdateImportant => 'به‌روزرسانی پرچم مهم ممکن نشد';

  @override
  String get markedImportant => 'به‌عنوان مهم علامت خورد';

  @override
  String get removedImportant => 'از مهم‌ها حذف شد';

  @override
  String get savedLocally =>
      'به‌صورت محلی ذخیره شد. با تازه‌سازی همگام می‌شود.';

  @override
  String get registerEmailTaken => 'این ایمیل قبلاً ثبت شده است';

  @override
  String get registerFailed => 'ثبت‌نام انجام نشد. دوباره تلاش کنید.';

  @override
  String get loginInvalid => 'ایمیل یا رمز عبور اشتباه است';

  @override
  String get loginFailed => 'ورود انجام نشد. دوباره تلاش کنید.';

  @override
  String get passwordResetTitle => 'بازنشانی رمز';

  @override
  String get passwordResetBody =>
      'به‌دلیل محدودیت اینترنت، بازنشانی با ایمیل ممکن نیست. برای کمک در بله یا روبیکا به erfaninfox پیام دهید.';

  @override
  String get passwordResetSendCode => 'ارسال کد';

  @override
  String get passwordResetCodeSent => 'کد به ایمیل ارسال شد';

  @override
  String get passwordResetSendFailed => 'ارسال کد ناموفق بود';

  @override
  String get passwordResetHelper =>
      'اگر ایمیل شما در سیستم باشد، کد برایتان ارسال می‌شود.';

  @override
  String get passwordResetCodeLabel => 'کد ۶ رقمی';

  @override
  String get passwordResetNewPassword => 'رمز جدید';

  @override
  String get passwordResetConfirmPassword => 'تکرار رمز جدید';

  @override
  String get passwordResetChangeButton => 'تغییر رمز';

  @override
  String get passwordResetInvalidCode => 'کد نامعتبر یا منقضی است';

  @override
  String get passwordResetPasswordsMismatch => 'تکرار رمز یکسان نیست';

  @override
  String get passwordResetSuccess => 'رمز با موفقیت تغییر کرد';

  @override
  String get passwordResetChangeFailed =>
      'تغییر رمز ناموفق بود. دوباره تلاش کنید.';

  @override
  String get copySupportLink => 'کپی لینک پشتیبانی';

  @override
  String get supportLinkCopied =>
      'لینک پشتیبانی کپی شد — در مرورگر یا روبیکا باز کنید';

  @override
  String get copyRequestText => 'کپی متن درخواست';

  @override
  String get requestTextCopied =>
      'متن درخواست کپی شد — در بله یا روبیکا بفرستید';

  @override
  String get statsSignInGrammarTrend =>
      'برای روند نمرهٔ گرامر از کوییزهای ذخیره‌شده وارد شوید.';

  @override
  String get statsCouldNotLoadGrammar => 'بارگذاری آمار گرامر ممکن نشد.';

  @override
  String get statsNoGrammarYet =>
      'هنوز نتیجهٔ گرامری نیست. یک کوییز گرامر انجام و نمره را ذخیره کنید.';

  @override
  String get grammarOverview => 'نمای کلی گرامر';

  @override
  String averageLastAttempts(int count) {
    return 'میانگین (آخرین $count ذخیره‌شده): ';
  }

  @override
  String get attempts => 'تلاش';

  @override
  String get lastLabel => 'آخرین';

  @override
  String get bestLabel => 'بهترین';

  @override
  String get worstLabel => 'بدترین';

  @override
  String get trendLabel => 'روند';

  @override
  String get scoreTrendTitle => 'روند نمره (قدیمی‌ترین → جدیدترین)';

  @override
  String get saveTwoQuizzesChart =>
      'حداقل دو کوییز گرامر ذخیره کنید تا نمودار خطی ببینید.';

  @override
  String get attemptsDistribution => 'توزیع تلاش‌ها';

  @override
  String get vocabDailyChartHint =>
      'به سؤالات کوییز واژگان پاسخ دهید تا دقت روزانه اینجا نمایش داده شود.';

  @override
  String get noQuizDataRange => 'هنوز دادهٔ کوییز در این بازه نیست.';

  @override
  String get legendVocabulary => 'واژگان';

  @override
  String get legendGrammar => 'گرامر';

  @override
  String get insightsVocabVsGrammar => 'واژگان';

  @override
  String get bookQuizChooseUnits => 'انتخاب یونیت‌ها';

  @override
  String nextDaysShort(int n) {
    return '$n روز';
  }

  @override
  String get vocabQuizExitTitle => 'خروج از کوییز؟';

  @override
  String get vocabQuizExitBody =>
      'اگر الان خارج شوید، پیشرفت این کوییز ذخیره نمی‌شود.';

  @override
  String get importantWordsSection => 'لغات مهم';

  @override
  String get importantWordsServerHint =>
      'این انتخاب شامل لغاتی است که خودتان مهم کرده‌اید (با ورود به حساب همگام می‌شود).';

  @override
  String get allWordsChip => 'همهٔ لغات';

  @override
  String get importantOnlyChip => 'فقط مهم‌ها';

  @override
  String bookQuizQuestionsSlider(int max) {
    return 'تعداد سؤال (حداکثر $max)';
  }

  @override
  String get bookQuizPoolTooSmall =>
      'حداقل ۴ لغت در مجموعه لازم است (یونیت‌ها / اشتباه‌ها را بررسی کنید).';

  @override
  String get bookQuizPoolTooSmallImportant =>
      'در این انتخاب لغت مهمی نیست. «همهٔ لغات» را بزنید یا یونیت‌ها را عوض کنید.';

  @override
  String get statsStudiedToday => '✅ امروز مطالعه کردید!';

  @override
  String get statsStudyToKeepStreak => '📖 امروز بخوانید تا استریک بماند';

  @override
  String get statsInsightsCardSubtitle => 'نمودار ۱۴ روز، روند و تفکیک نوع';

  @override
  String statsVocabDeviceAccuracy(String pct, int correct, int answered) {
    return 'واژگان (دستگاه): $pct٪ ($correct / $answered)';
  }

  @override
  String statsWordsStudiedTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغت در مجموع مطالعه شده',
      one: '۱ لغت در مجموع مطالعه شده',
    );
    return '$_temp0';
  }

  @override
  String get srsRatingAgain => '❌ دوباره';

  @override
  String get srsRatingHard => '😐 سخت';

  @override
  String get srsRatingGood => '✅ خوب';

  @override
  String get srsRatingEasy => '🔥 آسان';

  @override
  String get profileScreenTitle => 'پروفایل';

  @override
  String get profileSignInPrompt => 'برای ویرایش پروفایل وارد شوید.';

  @override
  String get profilePhotoUpdated => 'عکس به‌روز شد';

  @override
  String get profileUploadFailed =>
      'بارگذاری ناموفق. دوباره تلاش کنید یا عکس کوچک‌تر انتخاب کنید.';

  @override
  String get profileSaved => 'پروفایل ذخیره شد';

  @override
  String get profileSaveFailed => 'ذخیره نشد. دوباره تلاش کنید.';

  @override
  String get unsavedChangesTitle => 'تغییرات ذخیره نشده';

  @override
  String get unsavedChangesBody => 'تغییرات ذخیره نشده است. خارج می‌شوید؟';

  @override
  String get discardStay => 'ادامهٔ ویرایش';

  @override
  String get discardLeave => 'خروج';

  @override
  String get profileCropPhoto => 'برش عکس';

  @override
  String get profileGallery => 'گالری';

  @override
  String get profileCamera => 'دوربین';

  @override
  String get profileDisplayName => 'نام نمایشی';

  @override
  String get profileDisplayNameHint => 'نامی که نمایش داده می‌شود';

  @override
  String get profilePresetAvatars => 'یا آواتار از پیش‌تعریف انتخاب کنید';

  @override
  String get profileBoyAvatars => 'آواتار پسر';

  @override
  String get profileGirlAvatars => 'آواتار دختر';

  @override
  String get save => 'ذخیره';

  @override
  String get grammarResultsScreenTitle => 'نتایج گرامر';

  @override
  String get grammarExplanationTabFa => 'فارسی';

  @override
  String get grammarExplanationTabCkb => 'کردی';

  @override
  String get grammarExplanationTabEn => 'انگلیسی';

  @override
  String get grammarReportProblemTitle => 'گزارش مشکل';

  @override
  String get grammarReportWhatWrong => 'مشکل چیست؟';

  @override
  String get grammarReportDetailsOptional => 'جزئیات (اختیاری)';

  @override
  String get grammarReportKindWrongAnswer => 'پاسخ درست اعلام‌شده نادرست است';

  @override
  String get grammarReportKindTypoQuestion => 'غلط املایی در متن سؤال';

  @override
  String get grammarReportKindTypoOptions => 'چند گزینه درست به نظر می‌رسند';

  @override
  String get grammarReportKindBadExplanation => 'توضیح نادرست یا ناقص است';

  @override
  String get grammarReportKindUnclear => 'متن سؤال مبهم است';

  @override
  String get grammarReportKindOther => 'سایر';

  @override
  String get grammarReportQuestionTooltip => 'گزارش سؤال';

  @override
  String grammarTopicsCountAppBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موضوع',
      one: '۱ موضوع',
    );
    return '$_temp0';
  }

  @override
  String get grammarSortNewest => 'جدیدترین';

  @override
  String get grammarSortMostPractice => 'بیشترین تمرین';

  @override
  String get grammarSortLabel => 'مرتب‌سازی';

  @override
  String get grammarSignInRequiredTitle => 'ورود لازم است';

  @override
  String get grammarSignInRequiredBody =>
      'برای تاریخچه و برچسب خصوصی/عمومی وارد شوید.';

  @override
  String get grammarGoToSignIn => 'برو به تنظیمات و ورود';

  @override
  String get grammarLoadingYourResults => 'در حال بارگذاری نتایج شما…';

  @override
  String get grammarLoadingCommunityResults => 'در حال بارگذاری نتایج جامعه…';

  @override
  String get grammarNoPersonalResultsTitle => 'هنوز نتیجه‌ای نیست';

  @override
  String get grammarNoPersonalResultsBody =>
      'بعد از اتمام جلسهٔ گرامر، نمره اینجا نمایش داده می‌شود.';

  @override
  String get grammarCommunityEmptyTitle => 'هنوز چیزی نیست';

  @override
  String get grammarCommunityEmptyBody =>
      'اگر در پایان کوییز «نمایش در نتایج جامعه» را بزنید، اینجا دیده می‌شود.';

  @override
  String get guestUser => 'مهمان';

  @override
  String get resultVisibilityPublic => 'عمومی';

  @override
  String get resultVisibilityPrivate => 'خصوصی';

  @override
  String get errorConnectionTryAgain =>
      'اتصال را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get grammarSheetSessionTitle => 'تعداد سؤال این جلسه';

  @override
  String get grammarSheetHintSingleTopic =>
      'سؤالات فقط از همین موضوع به‌صورت تصادفی انتخاب می‌شوند.';

  @override
  String get grammarSheetHintMultiTopic =>
      'سؤالات از همهٔ موضوعات انتخاب‌شده مخلوط می‌شوند.';

  @override
  String grammarSheetUpToInBank(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'حداکثر $max سؤال در بانک موجود است.',
      one: 'حداکثر ۱ سؤال در بانک موجود است.',
    );
    return '$_temp0';
  }

  @override
  String grammarSheetMinSession(int min, int base) {
    return 'حداقل این جلسه: $min (حداقل $base، یا یکی به ازای هر موضوع اگر چندتا انتخاب کنید).';
  }

  @override
  String get grammarSheetQuickPick => 'انتخاب سریع';

  @override
  String grammarQuestionNoun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سؤال',
      one: 'سؤال',
    );
    return '$_temp0';
  }

  @override
  String get grammarCouldNotLoadQuestions =>
      'بارگذاری سؤالات ممکن نشد. دوباره تلاش کنید.';

  @override
  String get grammarNoQuestionsForTopics =>
      'برای موضوع(های) انتخاب‌شده سؤالی نیست.';

  @override
  String get grammarExplanationHeading => 'توضیح';

  @override
  String get grammarSessionCompleteTitle => 'جلسه تمام شد';

  @override
  String grammarScoreOutOf(int score, int total) {
    return 'از $total سؤال، $score درست بود.';
  }

  @override
  String get grammarHowSaveResult => 'نتیجه چطور ذخیره شود؟';

  @override
  String get grammarSaveResultFootnote =>
      'نتایج خصوصی فقط در «نتایج من»؛ نتایج عمومی در تب «کاربران».';

  @override
  String get grammarResultSavedShort => 'نتیجه ذخیره شد';

  @override
  String statsDaysOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز',
      one: '۱ روز',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersTitle => 'مدیریت کاربران';

  @override
  String get adminUserManagement => 'مدیریت کاربران';

  @override
  String get adminSearchUsersHint => 'جستجو با ایمیل، نام یا معلم…';

  @override
  String get adminStudentAccess => 'حساب دانش‌آموز';

  @override
  String get adminAssignedTeacher => 'معلم کلاس';

  @override
  String get adminNoTeacher => 'بدون معلم';

  @override
  String get adminSave => 'ذخیره';

  @override
  String get adminUpdated => 'ذخیره شد';

  @override
  String get adminAccessDenied => 'دسترسی ادمین ندارید.';

  @override
  String get adminTeacherInvalid => 'یک حساب معلم معتبر انتخاب کنید.';

  @override
  String get adminNoUsers => 'کاربری از سرور برنگشت.';

  @override
  String get adminNoSearchResults => 'کاربری با این جستجو پیدا نشد.';

  @override
  String get adminRoleTeacher => 'معلم';

  @override
  String get adminRoleAdmin => 'ادمین';

  @override
  String get youSectionAdmin => 'مدیریت';

  @override
  String get youAdminPanelSubtitle => 'دسترسی دانش‌آموز، معلم و حساب‌ها';

  @override
  String get adminScreenSubtitle => 'جستجو کنید و برای ویرایش روی کاربر بزنید';

  @override
  String get adminEditUserSheetTitle => 'ویرایش دسترسی';
}
