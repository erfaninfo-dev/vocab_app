// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Erfan Academy';

  @override
  String get tabHome => 'Home';

  @override
  String get tabGrammar => 'Grammar';

  @override
  String get tabReview => 'Review';

  @override
  String get tabPlay => 'Play';

  @override
  String get youSectionReview => 'Review';

  @override
  String get youSectionReviewSubtitle =>
      'Spaced repetition for words you\'ve practiced.';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabYou => 'You';

  @override
  String get tabSettings => 'Settings';

  @override
  String get youPageTitle => 'You';

  @override
  String get youSectionProgress => 'Progress';

  @override
  String get youSectionProgressSubtitle => 'Streaks, stats, and quiz insights';

  @override
  String get youSectionMessages => 'Your teacher';

  @override
  String get youSectionMessagesHub => 'Messages';

  @override
  String get youSectionMessagesSubtitle => 'Chat with your class teacher';

  @override
  String get youSectionMessagesSubtitleHub =>
      'Chats with your teacher and staff';

  @override
  String get youMessagesPickTitle => 'Your chats';

  @override
  String get youTeacherPanelSubtitle => 'Students and class activity';

  @override
  String get chatSenderYou => 'You';

  @override
  String get teacherStudentChat => 'Chat';

  @override
  String get teacherInboxTitle => 'Messages';

  @override
  String get teacherInboxOpenPanel => 'Full student list';

  @override
  String get chatListYesterday => 'Yesterday';

  @override
  String get chatPreviewYouPrefix => 'You: ';

  @override
  String get teacherChatHint => 'Message…';

  @override
  String get teacherMessagesEmpty => 'No messages yet.';

  @override
  String get chatMessageEdit => 'Edit';

  @override
  String get chatMessageEditTitle => 'Edit message';

  @override
  String get chatMessageEditHint => 'Update your message…';

  @override
  String get chatMessageEdited => 'edited';

  @override
  String get chatMessageEditFailedRead =>
      'This message has already been read and can\'t be edited.';

  @override
  String get chatMessageEditSave => 'Save';

  @override
  String get chatMessageReadStateSent => 'Sent';

  @override
  String get chatMessageReadStateRead => 'Read';

  @override
  String get teacherMessagesNoTeacher =>
      'Use your student code so a teacher can be assigned to you.';

  @override
  String newMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String get tabStudents => 'Students';

  @override
  String get studentBooksTitle => 'Your class books';

  @override
  String get registerAsStudent => 'Your student';

  @override
  String get studentCodeLabel => 'Student code';

  @override
  String get studentCodeRequired => 'Enter the code your teacher gave you';

  @override
  String get redeemStudentCode => 'Enter student code';

  @override
  String get redeemStudentCodeSubtitle =>
      'Enter the 5-digit code from your teacher.';

  @override
  String get createStudentCode => 'Create student code';

  @override
  String get createStudentCodeSubtitle =>
      'Register a one-time 5-digit code for one student.';

  @override
  String get studentCodeFiveDigitsHint => '12345';

  @override
  String get studentCodeFiveDigitsInvalid => 'Enter exactly 5 digits';

  @override
  String teacherStudentCodeRegistered(String code) {
    return 'Code $code is ready for one student.';
  }

  @override
  String get teacherStudentCodeRegisterFailed =>
      'Could not register this code.';

  @override
  String get teacherUnusedCodesTitle => 'Unused codes';

  @override
  String get invalidStudentCode => 'Invalid or expired code.';

  @override
  String get studentAccessGranted => 'Student access enabled.';

  @override
  String get studentTabSignIn => 'Sign in to access your teacher\'s books.';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get unitSamplesOpen => 'Sample texts';

  @override
  String unitSamplesTitle(int unit) {
    return 'Unit $unit — Sample texts';
  }

  @override
  String unitSamplesTitleSection(int unit, int section) {
    return 'Unit $unit — Section $section — Sample texts';
  }

  @override
  String get unitSamplesEmpty => 'No sample texts for this unit yet.';

  @override
  String get unitSamplesLoadFailed => 'Could not load sample texts.';

  @override
  String get search => 'Search';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errServerReturnedError =>
      'The server returned an error. Please try again later.';

  @override
  String get splashTagline => 'Calm, focused vocabulary practice';

  @override
  String get languageSelectionTitle => 'Choose app language';

  @override
  String get languageSelectionSubtitle =>
      'You can change this anytime in Settings.';

  @override
  String get langEnglish => 'English';

  @override
  String get langPersian => 'Persian (Farsi)';

  @override
  String get langKurdishSorani => 'Kurdish (Sorani)';

  @override
  String get chooseYourBook => 'Choose Your Book';

  @override
  String booksAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books available',
      one: '1 book available',
      zero: 'No books available',
    );
    return '$_temp0';
  }

  @override
  String get searchBooksHint => 'Search books…';

  @override
  String get homeReceivingBooks => 'Receiving…';

  @override
  String get couldNotLoadBooks => 'Could not load books.';

  @override
  String couldNotLoadBooksWithError(String error) {
    return 'Could not load books.\n$error';
  }

  @override
  String get noBooksFound => 'No books found';

  @override
  String get homeTrackIelts => 'IELTS';

  @override
  String get homeTrackGeneral => 'General';

  @override
  String get homeBooksSeriesOther => 'Other books';

  @override
  String get homeSeriesCambridgeTests => 'Cambridge IELTS Tests';

  @override
  String homeSeriesVolumesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books in series',
      one: '1 book in series',
    );
    return '$_temp0';
  }

  @override
  String seriesBooksGridHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books · tap a card to open',
      one: '1 book · tap a card to open',
    );
    return '$_temp0';
  }

  @override
  String get bookSingular => 'book';

  @override
  String get bookPlural => 'books';

  @override
  String get unitSingular => 'unit';

  @override
  String get unitPlural => 'units';

  @override
  String get loadingEllipsis => 'Loading…';

  @override
  String get tapToOpen => 'Tap to open';

  @override
  String get grammarPracticeTitle => 'Grammar practice';

  @override
  String get grammarPracticeSubtitle =>
      'Multiple-choice questions by grammar topic';

  @override
  String reviewWordsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words due for review!',
      one: '1 word due for review!',
    );
    return '$_temp0';
  }

  @override
  String get reviewTapStart => 'Tap to start your daily review session';

  @override
  String get obSlide1Title => 'Books & words';

  @override
  String get obSlide1Body =>
      'Start from Home: pick a book, open units, then browse words. Use flashcards and quizzes inside each unit to study the way you like.';

  @override
  String get obSlide2Title => 'Grammar practice';

  @override
  String get obSlide2Body =>
      'Open the Grammar tab below. Select one or more topics and start a session — each run uses 20 random questions with explanations.';

  @override
  String get obSlide3Title => 'Daily review';

  @override
  String get obSlide3Body =>
      'Review uses spaced repetition for words you\'ve practiced. Check the badge on the tab when cards are due.';

  @override
  String get obSlide4Title => 'Your progress';

  @override
  String get obSlide4Body =>
      'Progress shows streaks and activity. Keep a steady rhythm to build a habit.';

  @override
  String get obSlide5Title => 'Make it yours';

  @override
  String get obSlide5Body =>
      'In Settings: theme, translation language (Persian / Kurdish Sorani), reminders, and more.';

  @override
  String get getStarted => 'Get started';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccount => 'Account';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSubtitle => 'Optional — use email and password';

  @override
  String get createAccount => 'Create account';

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody => 'Are you sure you want to sign out?';

  @override
  String get signedOut => 'Signed out';

  @override
  String get loadingAccount => 'Loading account…';

  @override
  String get sectionTranslationLanguage => 'Translation language';

  @override
  String get translationLangPersian => 'Persian';

  @override
  String get translationLangKurdishSorani => 'Kurdish (Sorani)';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get systemTheme => 'System theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get sectionDailyReminder => 'Daily reminder';

  @override
  String get dailyStudyReminder => 'Daily study reminder';

  @override
  String reminderSetAt(String time) {
    return 'Reminder set at $time';
  }

  @override
  String get tapToEnableReminder => 'Tap to enable';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get sectionSound => 'Sound';

  @override
  String get splashSoundTitle => 'Startup chime';

  @override
  String get splashSoundSubtitle => 'Play a calming sound when the app opens';

  @override
  String get sectionAbout => 'About';

  @override
  String get sectionAppLanguage => 'App language';

  @override
  String get appLanguageSubtitle =>
      'Interface language (English, Persian, or Kurdish Sorani)';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get appNameShort => 'Erfan Academy';

  @override
  String get byAuthor => 'By Erfan Abdi';

  @override
  String aboutAppVersion(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get aboutUpdateFromPlayStore => 'Get the latest version';

  @override
  String get aboutAppUpToDate => 'You have the latest version installed.';

  @override
  String aboutUpdateAvailableVersion(String version) {
    return 'New version available: $version';
  }

  @override
  String get aboutDownloadApkUpdate => 'Download update';

  @override
  String get aboutDownloadingApk => 'Downloading update…';

  @override
  String get aboutDownloadApkFailed =>
      'Download failed. Check your connection and try again.';

  @override
  String get aboutInstallApkHint =>
      'If prompted, allow installing updates from this app in system settings.';

  @override
  String get aboutDownloadComplete => 'Download complete';

  @override
  String get aboutInstallReadyMessage =>
      'The update has been downloaded. Tap Install to update Erfan Academy. Your account and data will be preserved.';

  @override
  String get aboutInstallNow => 'Install now';

  @override
  String get aboutInstallPermissionRequired =>
      'Android needs permission to install updates from this app. Allow it in Settings → Apps → Erfan Academy → Install unknown apps, then tap Install again.';

  @override
  String get aboutInstallLaunchFailed =>
      'Could not open the installer. Please try again.';

  @override
  String get aboutForcedUpdateNote =>
      'This update is required. Please download and install the latest version.';

  @override
  String get aboutUpdateCheckFailed => 'Could not check for updates.';

  @override
  String get aboutRetryUpdateCheck => 'Retry';

  @override
  String get homeNewUpdatesTitle => 'New updates';

  @override
  String get homeNewUpdatesLetsGo => 'Let\'s go!';

  @override
  String get aboutLater => 'Later';

  @override
  String get aboutCouldNotOpenLink => 'Could not open the link.';

  @override
  String get aboutPhoneLabel => 'Phone';

  @override
  String get aboutPhoneCopied => 'Phone number copied to clipboard';

  @override
  String get errNoInternet =>
      'No internet connection. Please check your network.';

  @override
  String get errBadData => 'Could not read data. Please try again.';

  @override
  String get errServer => 'Could not reach the server. Please try again.';

  @override
  String get reviewToday => 'Review Today';

  @override
  String dueCount(int count) {
    return '$count due';
  }

  @override
  String get fetchErrorRetry => 'Could not load data. Please try again.';

  @override
  String get tapCardToReveal => 'Tap card to reveal answer';

  @override
  String get translateThisWord => 'Translate this word';

  @override
  String get answer => 'Answer';

  @override
  String get tapToSeeAnswer => 'Tap to see answer';

  @override
  String get howWellKnew => 'How well did you know this?';

  @override
  String get pronounce => 'Pronounce';

  @override
  String get speaking => 'Speaking…';

  @override
  String get noWordsDueTitle => 'No words due today!';

  @override
  String get noWordsDueBodyFlashcards =>
      'Start studying words using Flashcards to build your review queue.';

  @override
  String noWordsDueBodyGreat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return 'Great job! Come back tomorrow for more reviews.\n$_temp0 in your queue.';
  }

  @override
  String get sessionComplete => 'Session Complete!';

  @override
  String youReviewedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return 'You reviewed $_temp0 today.';
  }

  @override
  String wordsProgress(int current, int total) {
    return '$current / $total words';
  }

  @override
  String get quizTitle => 'Quiz';

  @override
  String get couldNotLoadWords => 'Could not load data. Please try again.';

  @override
  String get couldNotLoadMistakes => 'Could not load mistake list';

  @override
  String get quizNotEnoughImportant =>
      'No important words in this scope. Choose all words, change scope, or pick more units.';

  @override
  String get quizNotEnoughWrongs =>
      'No words from your mistake list in this selection. Adjust units or turn off “only past mistakes”.';

  @override
  String get quizNeedFourWords => 'Need at least 4 words to start this quiz.';

  @override
  String get quizNeedOneWord => 'Need at least 1 word to start this quiz.';

  @override
  String get quizScopeTitle => 'Quiz scope';

  @override
  String get quizScopeImportantDescription =>
      'This list includes important words. Choose whether the quiz uses every word here or only important ones.';

  @override
  String allWordsCount(int count) {
    return 'All words ($count)';
  }

  @override
  String importantWordsOnlyCount(int count) {
    return 'Important words only ($count)';
  }

  @override
  String get importantOnlyNeedsFour =>
      'Quiz only the words marked important in this list.';

  @override
  String get quizSetupTitle => 'Quiz setup';

  @override
  String quizPoolSummary(int pool, int min, int max) {
    return '$pool words in pool · min $min question(s) · max $max';
  }

  @override
  String get onlyPastMistakes => 'Only past mistakes';

  @override
  String get noMistakesYet => 'No mistakes recorded yet for this scope.';

  @override
  String mistakesOnServer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mistakes',
      one: '1 mistake',
    );
    return '$_temp0 on server';
  }

  @override
  String get signInForMistakes =>
      'Sign in to sync mistakes and use “past mistakes” mode.';

  @override
  String get numberOfQuestions => 'Number of questions';

  @override
  String get questionModes => 'Question modes';

  @override
  String get startQuiz => 'Start quiz';

  @override
  String get quizMcqWordToMeaning => 'Word → Meaning';

  @override
  String get quizMcqMeaningToWord => 'Meaning → Word';

  @override
  String get quizWrittenMeaningToWord => 'Fill in the blank';

  @override
  String get quizSpellingListenAndType => 'Listen & spell';

  @override
  String get quizSpellingListenPrompt => 'Listen and type the English word:';

  @override
  String get quizReplayAudio => 'Play again';

  @override
  String get quizSpellingTypeEnglish => 'Type the English word';

  @override
  String get whatIsMeaningOf => 'What is the meaning of:';

  @override
  String get whichWordMeans => 'Which word means:';

  @override
  String get typeTheWord => 'Type the word';

  @override
  String get typeYourAnswer => 'Type your answer…';

  @override
  String get submit => 'Submit';

  @override
  String get seeResults => 'See Results';

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get updating => 'Updating…';

  @override
  String get learnedRemoveMistakes => 'I learned it — remove from mistakes';

  @override
  String questionProgress(int current, int total) {
    return 'Question $current / $total';
  }

  @override
  String scoreCorrect(int score) {
    return '$score correct';
  }

  @override
  String get perfectScore => 'Perfect score!';

  @override
  String get excellentWork => 'Excellent work!';

  @override
  String get goodJob => 'Good job!';

  @override
  String get keepPracticing => 'Keep practicing!';

  @override
  String get dontGiveUp => 'Don\'t give up!';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get backToQuiz => 'Back to quiz';

  @override
  String get backToWords => 'Back to Words';

  @override
  String correctLine(String answer) {
    return 'Correct: $answer';
  }

  @override
  String wrongBlankLine(String correct) {
    return 'Wrong (blank). Correct answer: $correct';
  }

  @override
  String wrongAnswerLine(String given, String correct) {
    return 'Wrong: $given · Correct answer: $correct';
  }

  @override
  String get quizFeedbackWrongPrefix => 'Wrong:';

  @override
  String get quizFeedbackCorrectLabel => 'Correct answer:';

  @override
  String get quizWrongBlankIntro => 'Wrong (blank).';

  @override
  String get quizWrittenFirstLetterMismatch =>
      'Wrong first letter — the answer doesn’t start with that.';

  @override
  String get removedFromMistakes => 'Removed from your mistake list';

  @override
  String get couldNotUpdateServer => 'Could not update server';

  @override
  String get unitsTitle => 'Units';

  @override
  String get backToBooks => 'Back to books';

  @override
  String get bookQuiz => 'Book quiz';

  @override
  String get favorites => 'Favorites';

  @override
  String get failedLoadSections => 'Failed to load sections. Please retry.';

  @override
  String wordsUnitSection(int unit, int section) {
    return 'Unit $unit • Section $section';
  }

  @override
  String wordsUnitOnly(int unit) {
    return 'Unit $unit';
  }

  @override
  String get tooltipQuiz => 'Quiz';

  @override
  String get tooltipFlashcards => 'Flashcards';

  @override
  String get searchWordWholeBook => 'Search word (whole book)…';

  @override
  String get noMatchingWords => 'No matching words found.';

  @override
  String sectionInUnit(int section, int unit) {
    return 'Section $section in Unit $unit';
  }

  @override
  String unitLabel(int unit) {
    return 'Unit $unit';
  }

  @override
  String matchesWholeBook(int filtered, int total) {
    return '$filtered of $total matches (whole book)';
  }

  @override
  String wordsVisible(int filtered, int total) {
    return '$filtered of $total words visible';
  }

  @override
  String get vocabularyQuizTitle => 'Vocabulary quiz';

  @override
  String get vocabQuizHistoryTitle => 'Vocabulary quiz history';

  @override
  String get vocabQuizHistorySubtitle =>
      'Sessions are saved on your account so you can review them on any device.';

  @override
  String get vocabQuizHistoryEmpty => 'No vocabulary quiz sessions yet.';

  @override
  String get vocabQuizHistorySignIn =>
      'Sign in to save quiz results to the server and view them here.';

  @override
  String get vocabQuizHistoryLoadError =>
      'Quiz history could not be loaded. The server may be missing the results table—run api/vocab_quiz_results_schema.sql on MySQL, or try again later.';

  @override
  String get vocabQuizResultDetailTitle => 'Session details';

  @override
  String vocabQuizResultScoreLine(int score, int total) {
    return '$score / $total correct';
  }

  @override
  String get vocabQuizResultYourAnswer => 'Your answer';

  @override
  String get vocabQuizResultCorrect => 'Correct';

  @override
  String get vocabQuizResultIncorrect => 'Wrong';

  @override
  String get vocabQuizResultQuestion => 'Question';

  @override
  String vocabQuizHistoryUnitsLine(String units) {
    return 'Units: $units';
  }

  @override
  String vocabQuizCorrectWrongLine(int correct, int wrong) {
    return '$correct correct · $wrong wrong';
  }

  @override
  String get vocabQuizViewMistakes => 'View mistakes';

  @override
  String get vocabQuizMistakesTitle => 'Wrong answers';

  @override
  String get vocabQuizMistakesEmpty => 'No wrong answers in this session.';

  @override
  String get teacherPanelTitle => 'Teacher panel';

  @override
  String get teacherPanelSubtitle =>
      'View your students\' vocabulary & grammar practice and class sessions.';

  @override
  String get teacherOpenPanel => 'Teacher panel';

  @override
  String get teacherStudentsEmpty =>
      'No students linked yet. On the server, create student codes tied to your teacher account — learners who register with those codes appear here.';

  @override
  String get teacherPanelTabStudents => 'Students';

  @override
  String get teacherPanelTabSchedule => 'Schedule';

  @override
  String get teacherPanelTabMessages => 'Messages';

  @override
  String get teacherScheduleEmpty =>
      'Nothing in the next 7 days. Add weekly class times under each student (Weekly schedule tab), or every upcoming slot was already logged under Class sessions.';

  @override
  String get teacherScheduleTabSubtitle =>
      'Next 7 days from each student\'s Weekly schedule. When you log the matching session under Class sessions, it disappears here.';

  @override
  String get sessionDayToday => 'Today';

  @override
  String get sessionDayTomorrow => 'Tomorrow';

  @override
  String get teacherStudentDetailTitle => 'Student';

  @override
  String get teacherTabVocabQuiz => 'Vocabulary';

  @override
  String get teacherTabGrammar => 'Grammar';

  @override
  String get teacherTabClassSessions => 'Class sessions';

  @override
  String get teacherTabWeeklySchedule => 'Weekly schedule';

  @override
  String get teacherClassScheduleSubtitle =>
      'Set which weekdays and times this student has class. Learners see this list as read-only.';

  @override
  String get teacherClassScheduleAddButton => 'Add time slot';

  @override
  String get teacherClassScheduleEditTitle => 'Edit time slot';

  @override
  String get classScheduleWeekdayLabel => 'Day of week';

  @override
  String get classScheduleStartLabel => 'Start time';

  @override
  String get classScheduleEndLabel => 'End time';

  @override
  String get classScheduleIncludeEnd => 'Include end time';

  @override
  String get classScheduleHasEndSubtitle =>
      'Optional — leave off for a single start time.';

  @override
  String get classScheduleLabelHint => 'Note (optional)';

  @override
  String get classScheduleEmpty => 'No weekly times set yet.';

  @override
  String get classScheduleSlotAdded => 'Time slot added';

  @override
  String get classScheduleSlotUpdated => 'Time slot updated';

  @override
  String get classScheduleSlotDeleted => 'Time slot removed';

  @override
  String get classScheduleRemove => 'Remove';

  @override
  String get classScheduleDeleteConfirmTitle => 'Remove this time slot?';

  @override
  String get classScheduleDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get classScheduleInvalidRange => 'End time must be after start time.';

  @override
  String get youClassScheduleSubtitle =>
      'Recurring class days and times from your teacher';

  @override
  String get teacherClassSessionsTabSubtitle =>
      'Add sessions with one tap, adjust date and time when needed, or remove an entry. Students see this list in read-only form.';

  @override
  String teacherClassSessionHeading(int number) {
    return 'Session $number';
  }

  @override
  String get teacherClassSessionEdit => 'Edit';

  @override
  String get teacherClassSessionDelete => 'Remove';

  @override
  String get teacherClassSessionDeleteConfirmTitle => 'Remove this session?';

  @override
  String get teacherClassSessionDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get teacherClassSessionDeleted => 'Session removed';

  @override
  String get teacherClassSessionEditTitle => 'Date & time';

  @override
  String get teacherClassSessionAdded => 'Session added';

  @override
  String get teacherClassSessions => 'Class sessions';

  @override
  String get teacherClassSessionAddTooltip => 'Add a class session';

  @override
  String get teacherClassSessionsAddButton => 'Add session';

  @override
  String get teacherClassSessionDateFieldLabel => 'Date';

  @override
  String get teacherClassSessionTimeFieldLabel => 'Time';

  @override
  String get youClassSessionsTitle => 'Class sessions';

  @override
  String get youClassSessionsSubtitle =>
      'Sessions your teacher records in your profile';

  @override
  String get youClassSessionsEmpty => 'No sessions recorded yet.';

  @override
  String get studentPanelTitle => 'Your class';

  @override
  String get studentPanelFabTooltip => 'Open class panel';

  @override
  String get myPanelFab => 'My pannel';

  @override
  String get studentPanelHeadline =>
      'Teacher, sessions, and messages in one place.';

  @override
  String get studentPanelStatUnread => 'Unread';

  @override
  String get teacherClassSessionsHintEmpty =>
      'Tap + to record each class session. The time is saved automatically.';

  @override
  String get teacherClassSessionsTabSubtitleTerms =>
      'Create terms and set how many sessions each term allows. Log sessions under the matching term; students see the same grouping.';

  @override
  String get teacherClassTermsSection => 'Terms';

  @override
  String teacherClassTermTitle(int number) {
    return 'Term $number';
  }

  @override
  String teacherClassTermSessionsProgress(int current, int max) {
    return '$current / $max sessions';
  }

  @override
  String get teacherClassTermsAddButton => 'Add term';

  @override
  String get teacherClassTermsEmptyHint =>
      'Add a term first, set its session limit, then log class sessions under that term.';

  @override
  String get teacherClassTermEditCapTitle => 'Session limit';

  @override
  String get teacherClassTermCapFieldLabel => 'Max sessions in this term';

  @override
  String get teacherClassTermDeleteConfirmTitle => 'Delete this term?';

  @override
  String get teacherClassTermDeleteConfirmBody =>
      'Every class session recorded in this term will be removed. This cannot be undone.';

  @override
  String get teacherClassTermAdded => 'Term added';

  @override
  String get teacherClassTermUpdated => 'Term updated';

  @override
  String get teacherClassTermDeleted => 'Term removed';

  @override
  String get teacherClassTermAddSessionButton => 'Log session';

  @override
  String get classTermPaymentPaid => 'Paid';

  @override
  String get classTermPaymentUnpaid => 'Unpaid';

  @override
  String get classTermPaymentUpdated => 'Payment status updated';

  @override
  String get teacherSessionCountLabel => 'Recorded class sessions';

  @override
  String get teacherSessionSave => 'Save';

  @override
  String get teacherSessionSaveNote => 'Save note';

  @override
  String get teacherSessionUpdated => 'Saved';

  @override
  String get teacherSessionInvalid => 'Enter a valid number (0 or more).';

  @override
  String get teacherAccessDenied =>
      'Only teacher accounts can open this panel.';

  @override
  String get teacherNoResults => 'No results yet';

  @override
  String get teacherNoteLabel => 'Teacher note';

  @override
  String get teacherNotePlaceholder =>
      'Private notes about this student (only you can see this)';

  @override
  String get bookQuizSetupIntro =>
      'Choose units, how many questions, and whether to drill past mistakes.';

  @override
  String get bookQuizWordPoolTitle => 'Word pool';

  @override
  String get unitsSectionTitle => 'Units';

  @override
  String get couldNotLoadMistakesShort => 'Could not load mistakes';

  @override
  String get registerTitle => 'Create account';

  @override
  String get newAccount => 'New account';

  @override
  String get registerSubtitle =>
      'Choose email and password (at least 8 characters). No email or SMS code — you can sign in right away.';

  @override
  String get displayNameOptional => 'Display name (optional)';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get register => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle =>
      'Use your email and password. No verification step — your account is active immediately.';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get passwordMinLength => 'At least 8 characters';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get passwordsNoMatch => 'Passwords do not match';

  @override
  String get signInButton => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get goToAuth => 'Sign in / Create account';

  @override
  String get accountTitle => 'Account';

  @override
  String get tabSignIn => 'Sign in';

  @override
  String get tabRegister => 'Register';

  @override
  String get statsMyProgress => 'My Progress';

  @override
  String get statsTabVocab => 'Vocab';

  @override
  String get statsTabGrammar => 'Grammar';

  @override
  String get statsTabProgress => 'Progress';

  @override
  String get wordMastery => 'Word Mastery';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get quizInsights => 'Quiz insights';

  @override
  String get allTime => 'All Time';

  @override
  String get vocabAndGrammar => 'Vocabulary & grammar';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0 streak';
  }

  @override
  String get longest => 'Longest';

  @override
  String get totalDays => 'Total Days';

  @override
  String get mastered => 'Mastered  ';

  @override
  String get learning => 'Learning  ';

  @override
  String get seenOnce => 'Seen once  ';

  @override
  String get wordsReviewedPerDay => 'Words reviewed per day';

  @override
  String get totalReviews => 'Total Reviews';

  @override
  String get studyDays => 'Study Days';

  @override
  String get insightsTitle => 'Quiz insights';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabVocabulary => 'Vocabulary';

  @override
  String get tabGrammarStats => 'Grammar';

  @override
  String get insightsLast14 =>
      'Last 14 days: vocabulary (this device) vs grammar (saved to your account).';

  @override
  String get insightsSignInGrammar =>
      'Sign in to load grammar scores. Vocabulary bars still use local quiz data.';

  @override
  String get insightsGrammarLoadError =>
      'Could not load grammar data for the chart.';

  @override
  String get vocabDailyAccuracy =>
      'Daily accuracy from vocabulary quizzes (stored on this device).';

  @override
  String get allTimeDevice => 'All-time (device)';

  @override
  String get grammarPracticeAppBar => 'Grammar practice';

  @override
  String get grammarTooltipResults => 'Results';

  @override
  String get grammarTooltipUnselectAll => 'Unselect all';

  @override
  String get grammarSelectTopicsCta => 'Select topics';

  @override
  String grammarContinueTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Continue ($count topics)',
      one: 'Continue (1 topic)',
    );
    return '$_temp0';
  }

  @override
  String get grammarCouldNotLoadTopics =>
      'Could not load grammar topics. Please try again.';

  @override
  String get grammarNoTopicsEmpty =>
      'No grammar topics yet.\nAdd rows to your questions table (column content = topic name).';

  @override
  String grammarNotEnoughInBank(int minRequired) {
    return 'Not enough questions in the bank for this selection (need at least $minRequired).';
  }

  @override
  String get grammarNoQuestions =>
      'No questions found for the selected topics.';

  @override
  String get grammarTopicsPick => 'Pick topics and session length';

  @override
  String get exitExerciseTitle => 'Exit exercise?';

  @override
  String get exitExerciseBody =>
      'If you go back now, your progress for this session will not be saved.';

  @override
  String get stay => 'Stay';

  @override
  String get exit => 'Exit';

  @override
  String get grammarAppBar => 'Grammar';

  @override
  String get noTopicSelected => 'No topic selected.';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get reportFailed => 'Could not submit report. Please try again.';

  @override
  String get submitReport => 'Submit report';

  @override
  String get couldNotSaveResult =>
      'Could not save your result. Please try again.';

  @override
  String get keepPrivate => 'Keep private (only for me)';

  @override
  String get showCommunity => 'Show in community results';

  @override
  String get practiseAgain => 'Practise again';

  @override
  String get backToTopics => 'Back to topics';

  @override
  String get reviewSessionTitle => 'Review session';

  @override
  String get couldNotLoadResult => 'Could not load this result.';

  @override
  String get myResults => 'My results';

  @override
  String get users => 'Users';

  @override
  String get tryAgainResults => 'Try again';

  @override
  String get wordExample => 'Example';

  @override
  String get favorite => 'Favorite';

  @override
  String get important => 'Important';

  @override
  String get pronounceWord => 'Pronounce word';

  @override
  String get pronounceExample => 'Pronounce example';

  @override
  String get couldNotUpdateImportant => 'Could not update important flag';

  @override
  String get markedImportant => 'Marked as important';

  @override
  String get removedImportant => 'Removed from important';

  @override
  String get savedLocally => 'Saved locally. Will sync on refresh.';

  @override
  String get registerEmailTaken => 'This email is already registered';

  @override
  String get registerFailed => 'Registration failed. Please try again.';

  @override
  String get loginInvalid => 'Invalid email or password';

  @override
  String get loginFailed => 'Sign-in failed. Please try again.';

  @override
  String get passwordResetTitle => 'Password reset';

  @override
  String get passwordResetBody =>
      'Due to internet restrictions, email reset may not work. For help, message erfaninfox on Bale or Rubika.';

  @override
  String get passwordResetSendCode => 'Send code';

  @override
  String get passwordResetCodeSent => 'Code sent to your email';

  @override
  String get passwordResetSendFailed => 'Could not send the code';

  @override
  String get passwordResetHelper =>
      'If your email exists in our system, a code will be sent.';

  @override
  String get passwordResetCodeLabel => '6-digit code';

  @override
  String get passwordResetNewPassword => 'New password';

  @override
  String get passwordResetConfirmPassword => 'Confirm new password';

  @override
  String get passwordResetChangeButton => 'Change password';

  @override
  String get passwordResetInvalidCode => 'Invalid or expired code';

  @override
  String get passwordResetPasswordsMismatch => 'Passwords do not match';

  @override
  String get passwordResetSuccess => 'Password changed successfully';

  @override
  String get passwordResetChangeFailed =>
      'Could not change password. Please try again.';

  @override
  String get copySupportLink => 'Copy support link';

  @override
  String get supportLinkCopied =>
      'Support link copied — open in browser or Rubika';

  @override
  String get copyRequestText => 'Copy request text';

  @override
  String get requestTextCopied =>
      'Request text copied — send it in Bale or Rubika';

  @override
  String get statsSignInGrammarTrend =>
      'Sign in to see grammar score trends from your saved quizzes.';

  @override
  String get statsCouldNotLoadGrammar => 'Could not load grammar stats.';

  @override
  String get statsNoGrammarYet =>
      'No grammar results yet. Complete a grammar quiz and save your score.';

  @override
  String get grammarOverview => 'Grammar overview';

  @override
  String averageLastAttempts(int count) {
    return 'Average (last $count saved): ';
  }

  @override
  String get attempts => 'Attempts';

  @override
  String get lastLabel => 'Last';

  @override
  String get bestLabel => 'Best';

  @override
  String get worstLabel => 'Worst';

  @override
  String get trendLabel => 'Trend';

  @override
  String get scoreTrendTitle => 'Score trend (oldest → newest)';

  @override
  String get saveTwoQuizzesChart =>
      'Save at least two grammar quizzes to see a line chart.';

  @override
  String get attemptsDistribution => 'Attempts distribution';

  @override
  String get vocabDailyChartHint =>
      'Answer vocabulary quiz questions to see daily accuracy here.';

  @override
  String get noQuizDataRange => 'No quiz data in this range yet.';

  @override
  String get legendVocabulary => 'Vocabulary';

  @override
  String get legendGrammar => 'Grammar';

  @override
  String get insightsVocabVsGrammar => 'Vocabulary';

  @override
  String get bookQuizChooseUnits => 'Choose units';

  @override
  String nextDaysShort(int n) {
    return '${n}d';
  }

  @override
  String get vocabQuizExitTitle => 'Exit quiz?';

  @override
  String get vocabQuizExitBody =>
      'If you leave now, your progress for this quiz will be lost.';

  @override
  String get importantWordsSection => 'Important words';

  @override
  String get importantWordsServerHint =>
      'This selection includes words you marked as important (synced when signed in).';

  @override
  String get allWordsChip => 'All words';

  @override
  String get importantOnlyChip => 'Important only';

  @override
  String bookQuizQuestionsSlider(int max) {
    return 'Questions (max $max)';
  }

  @override
  String get bookQuizPoolTooSmall =>
      'Need at least 4 words in the pool (check units / mistakes).';

  @override
  String get bookQuizPoolTooSmallImportant =>
      'No important words in this selection. Choose all words or adjust units / mistakes.';

  @override
  String get statsStudiedToday => '✅ Studied today!';

  @override
  String get statsStudyToKeepStreak => '📖 Study today to keep your streak';

  @override
  String get statsInsightsCardSubtitle =>
      '14-day charts, trends, and breakdown by type';

  @override
  String statsVocabDeviceAccuracy(String pct, int correct, int answered) {
    return 'Vocab (device): $pct% ($correct / $answered)';
  }

  @override
  String statsWordsStudiedTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words studied in total',
      one: '1 word studied in total',
    );
    return '$_temp0';
  }

  @override
  String get srsRatingAgain => '❌ Again';

  @override
  String get srsRatingHard => '😐 Hard';

  @override
  String get srsRatingGood => '✅ Good';

  @override
  String get srsRatingEasy => '🔥 Easy';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileSignInPrompt => 'Sign in to edit your profile.';

  @override
  String get profilePhotoUpdated => 'Photo updated';

  @override
  String get profileUploadFailed =>
      'Upload failed. Try again or pick a smaller image.';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSaveFailed => 'Could not save profile. Please try again.';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesBody => 'You have unsaved changes. Leave anyway?';

  @override
  String get discardStay => 'Keep editing';

  @override
  String get discardLeave => 'Leave';

  @override
  String get profileCropPhoto => 'Crop photo';

  @override
  String get profileGallery => 'Gallery';

  @override
  String get profileCamera => 'Camera';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profileDisplayNameHint => 'How your name appears';

  @override
  String get profilePresetAvatars => 'Or pick a preset avatar';

  @override
  String get profileBoyAvatars => 'Boy avatars';

  @override
  String get profileGirlAvatars => 'Girl avatars';

  @override
  String get profilePasswordSectionTitle => 'Password';

  @override
  String get profilePasswordSecurityNote =>
      'For security, your password is stored as a hash on the server and cannot be shown. Use the fields below to type your current password and set a new one. You can tap the eye icon to show or hide what you type.';

  @override
  String get profileCurrentPasswordLabel => 'Current password';

  @override
  String get profilePasswordTooLong => 'Password must be at most 72 characters';

  @override
  String get profilePasswordSameAsCurrent =>
      'Choose a password that is different from your current one.';

  @override
  String get profileWrongCurrentPassword => 'Current password is incorrect';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get save => 'Save';

  @override
  String get grammarResultsScreenTitle => 'Grammar results';

  @override
  String get grammarExplanationTabFa => 'Persian';

  @override
  String get grammarExplanationTabCkb => 'Kurdi';

  @override
  String get translationLangKurdiTab => 'Kurdi';

  @override
  String get grammarExplanationTabEn => 'English';

  @override
  String get grammarReportProblemTitle => 'Report a problem';

  @override
  String get grammarReportWhatWrong => 'What is wrong?';

  @override
  String get grammarReportDetailsOptional => 'Details (optional)';

  @override
  String get grammarReportKindWrongAnswer => 'Marked correct answer is wrong';

  @override
  String get grammarReportKindTypoQuestion => 'Typo in the question text';

  @override
  String get grammarReportKindTypoOptions => 'Multiple options look correct';

  @override
  String get grammarReportKindBadExplanation =>
      'Explanation is wrong or incomplete';

  @override
  String get grammarReportKindUnclear => 'Question wording is unclear';

  @override
  String get grammarReportKindOther => 'Other';

  @override
  String get grammarReportQuestionTooltip => 'Report question';

  @override
  String grammarTopicsCountAppBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics',
      one: '1 topic',
    );
    return '$_temp0';
  }

  @override
  String get grammarSortNewest => 'Newest';

  @override
  String get grammarSortMostPractice => 'Most practice';

  @override
  String get grammarSortLabel => 'Sort';

  @override
  String get grammarSignInRequiredTitle => 'Sign in required';

  @override
  String get grammarSignInRequiredBody =>
      'Log in to see your personal history and private/public labels.';

  @override
  String get grammarGoToSignIn => 'Go to Settings & sign in';

  @override
  String get grammarLoadingYourResults => 'Loading your results…';

  @override
  String get grammarLoadingCommunityResults => 'Loading community results…';

  @override
  String get grammarNoPersonalResultsTitle => 'No results yet';

  @override
  String get grammarNoPersonalResultsBody =>
      'After you finish a grammar session, your score will appear here.';

  @override
  String get grammarCommunityEmptyTitle => 'Nothing here yet';

  @override
  String get grammarCommunityEmptyBody =>
      'When you choose “Show in community results” at the end of a quiz, it will appear in this list.';

  @override
  String grammarCommunityQuizTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grammar quizzes completed',
      one: '1 grammar quiz completed',
    );
    return '$_temp0';
  }

  @override
  String get guestUser => 'Guest';

  @override
  String get resultVisibilityPublic => 'Public';

  @override
  String get resultVisibilityPrivate => 'Private';

  @override
  String get errorConnectionTryAgain => 'Check your connection and try again.';

  @override
  String get grammarSheetSessionTitle => 'Questions in this session';

  @override
  String get grammarSheetHintSingleTopic =>
      'Questions are drawn at random from this topic only.';

  @override
  String get grammarSheetHintMultiTopic =>
      'Questions are mixed at random from all selected topics for varied practice.';

  @override
  String grammarSheetUpToInBank(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Up to $max questions available in the bank.',
      one: 'Up to 1 question available in the bank.',
    );
    return '$_temp0';
  }

  @override
  String grammarSheetMinSession(int min, int base) {
    return 'Minimum this session: $min (at least $base, or one per topic if you pick several).';
  }

  @override
  String get grammarSheetQuickPick => 'Quick pick';

  @override
  String grammarQuestionNoun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'questions',
      one: 'question',
    );
    return '$_temp0';
  }

  @override
  String get grammarCouldNotLoadQuestions =>
      'Could not load questions. Please try again.';

  @override
  String get grammarNoQuestionsForTopics =>
      'No questions for the selected topic(s).';

  @override
  String get grammarExplanationHeading => 'Explanation';

  @override
  String get grammarSessionCompleteTitle => 'Session complete';

  @override
  String grammarScoreOutOf(int score, int total) {
    return 'You got $score out of $total correct.';
  }

  @override
  String get grammarHowSaveResult => 'How should we save this result?';

  @override
  String get grammarSaveResultFootnote =>
      'Private results appear only under My results; public results appear in the Users tab.';

  @override
  String get grammarResultSavedShort => 'Result saved';

  @override
  String statsDaysOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersTitle => 'User management';

  @override
  String get adminUserManagement => 'User management';

  @override
  String get adminSearchUsersHint => 'Search by email, name, or teacher…';

  @override
  String get adminStudentAccess => 'Student account';

  @override
  String get adminTeacherAccess => 'Teacher account';

  @override
  String get adminAssignedTeacher => 'Class teacher';

  @override
  String get adminNoTeacher => 'No teacher';

  @override
  String get adminSave => 'Save';

  @override
  String get adminUpdated => 'Saved';

  @override
  String get adminAccessDenied => 'You do not have admin access.';

  @override
  String get adminTeacherInvalid => 'Pick a valid teacher account.';

  @override
  String get adminNoUsers => 'No users returned from the server.';

  @override
  String get adminNoSearchResults => 'No users match this search.';

  @override
  String get adminRoleTeacher => 'Teacher';

  @override
  String get adminRoleAdmin => 'Admin';

  @override
  String get youSectionAdmin => 'Administration';

  @override
  String get youAdminPanelSubtitle => 'Student access, teachers, and accounts';

  @override
  String get adminScreenSubtitle => 'Search and tap a user to edit';

  @override
  String get wordBuilderClearPath => 'Clear';

  @override
  String get wordBuilderTitle => 'Word Builder';

  @override
  String get wordBuilderShuffle => 'Shuffle letters';

  @override
  String get wordBuilderPickSource => 'Choose vocabulary';

  @override
  String get wordBuilderStartPlay => 'Start';

  @override
  String get wordBuilderCatalogAll => 'All books';

  @override
  String get wordBuilderNoWordsBody =>
      'No suitable English words were found for this source. Pick another book or refresh.';

  @override
  String get wordBuilderHomeSubtitle =>
      'Build English words from shuffled letters.';

  @override
  String wordBuilderLevelOf(int current, int total) {
    return 'Level $current of $total';
  }

  @override
  String wordBuilderCategory(String name) {
    return 'Topic: $name';
  }

  @override
  String get wordBuilderDifficultyBeginner => 'Beginner';

  @override
  String get wordBuilderDifficultyIntermediate => 'Intermediate';

  @override
  String get wordBuilderDifficultyAdvanced => 'Advanced';

  @override
  String get wordBuilderYourWord => 'Your word';

  @override
  String get wordBuilderLetters => 'Letter pool';

  @override
  String get wordBuilderSubmit => 'Check word';

  @override
  String get wordBuilderReset => 'Clear';

  @override
  String get wordBuilderNextLevel => 'Next level';

  @override
  String get wordBuilderHints => 'Hints';

  @override
  String get wordBuilderHintReveal => 'Reveal a letter';

  @override
  String get wordBuilderHintRemove => 'Remove an extra letter';

  @override
  String get wordBuilderHintMeaning => 'Show a meaning';

  @override
  String get wordBuilderTranslation => 'Translation';

  @override
  String get wordBuilderTooShort => 'Pick more letters first.';

  @override
  String get wordBuilderAlreadyFound => 'You already found that word.';

  @override
  String get wordBuilderTryAgain => 'Not in this level — keep trying.';

  @override
  String get wordBuilderCorrectNice => 'Nice!';

  @override
  String get wordBuilderHintLetter =>
      'A letter was revealed in one of the words.';

  @override
  String get wordBuilderHintRemoved =>
      'Removed an extra letter from your word.';

  @override
  String get wordBuilderHintRemoveNone =>
      'No extra letters to remove right now.';

  @override
  String get wordBuilderNotEnoughCoins =>
      'Not enough coins. Solve words to earn more.';

  @override
  String wordBuilderCoinsCost(int coins) {
    return 'Costs $coins coins';
  }

  @override
  String wordBuilderCoinsBalance(int coins) {
    return '$coins';
  }

  @override
  String get wordBuilderSessionSoundTitle => 'Sound';

  @override
  String get wordBuilderSessionBgmSwitch => 'Background music';

  @override
  String get wordBuilderSessionBgmSubtitle =>
      'Plays while you solve words in this game.';

  @override
  String get wordBuilderSessionSfxSwitch => 'Game sounds';

  @override
  String get wordBuilderSessionSfxSubtitle =>
      'Correct answers, mistakes, and level complete.';

  @override
  String wordBuilderHintMeaningLine(String meaning) {
    return 'Hint: $meaning';
  }

  @override
  String get wordBuilderAllLevelsDone =>
      'You finished all levels in this session.';

  @override
  String wordBuilderTotalXp(int xp) {
    return 'Total XP: $xp';
  }

  @override
  String wordBuilderAccuracy(int pct) {
    return 'Accuracy: $pct%';
  }

  @override
  String get wordBuilderPronunciation => 'Pronunciation';

  @override
  String get wordBuilderMeaning => 'Meaning';

  @override
  String get wordBuilderExample => 'Example';

  @override
  String get wordBuilderSpeakWord => 'Speak word';

  @override
  String get wordBuilderSpeakExample => 'Speak example';

  @override
  String get wordBuilderTargetsHeading => 'Words to find';

  @override
  String get wordBuilderCampaignHubSubtitle => '';

  @override
  String get wordBuilderCampaignStagesHint => '';

  @override
  String get wordBuilderCampaignStageLockedSnackbar =>
      'Finish the previous stage first.';

  @override
  String get wordBuilderCampaignTierLockedBody =>
      'Complete all 50 stages in the previous difficulty to unlock this track.';

  @override
  String get wordBuilderCampaignPlanError =>
      'Not enough vocabulary to build this stage. Try refreshing books later.';

  @override
  String get wordBuilderCampaignReset => 'Reset progress';

  @override
  String get wordBuilderCampaignResetConfirm =>
      'Clear all Word Builder stage progress? This cannot be undone.';

  @override
  String get wordBuilderCampaignResetDone => 'Campaign progress cleared.';

  @override
  String wordBuilderCampaignStageOf(int stage, int total) {
    return 'Stage $stage of $total';
  }

  @override
  String wordBuilderCampaignStageN(int n) {
    return 'Stage $n';
  }

  @override
  String get wordBuilderCampaignStageCompleted => 'Completed';

  @override
  String get wordBuilderCampaignStageReplayHint => 'Tap to replay this stage';

  @override
  String get adminEditUserSheetTitle => 'Edit access';

  @override
  String get previous => 'Previous';

  @override
  String get finish => 'Finish';

  @override
  String get noWordsForSection => 'No words for this section.';

  @override
  String get noFavoriteWordsYet => 'No favorite words yet.';

  @override
  String get tapCardToRevealAndRate => 'Tap card to reveal answer & rate';

  @override
  String get tapToFlip => 'Tap to flip';

  @override
  String flashcardCardProgress(int current, int total) {
    return 'Card $current of $total';
  }

  @override
  String get flashcardMeaningLabel => 'Meaning';

  @override
  String get flashcardWordLabel => 'Word';

  @override
  String get allCardsReviewed => 'All cards reviewed!';

  @override
  String couldNotLoadSectionsWithError(String error) {
    return 'Could not load sections.\n$error';
  }

  @override
  String couldNotLoadUnitsWithError(String error) {
    return 'Could not load units.\n$error';
  }

  @override
  String get noUnitsFound => 'No units found in this dataset.';

  @override
  String unitsGridHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units · tap a card to open',
      one: '1 unit · tap a card to open',
    );
    return '$_temp0';
  }

  @override
  String get checkingEllipsis => 'Checking…';

  @override
  String get backToUnits => 'Back to units';

  @override
  String get englishMeaning => 'English meaning';

  @override
  String get wordsTabLabel => 'Words';

  @override
  String get samplesTabLabel => 'Sample texts';

  @override
  String unitSectionLine(int unit, int section) {
    return 'Unit $unit · Section $section';
  }

  @override
  String sectionNumberLabel(int section) {
    return 'Section $section';
  }

  @override
  String get grammarReviewQuestionsHeading => 'Questions';

  @override
  String get grammarNoPerQuestionData =>
      'No per-question data was stored for this attempt (older results or server not migrated).';

  @override
  String grammarReviewQuestionTitle(int index, String topic) {
    return 'Q$index · $topic';
  }

  @override
  String get answerCorrect => 'Correct';

  @override
  String get answerIncorrect => 'Incorrect';

  @override
  String statsQuizCorrectFraction(int correct, int answered) {
    return '$correct / $answered correct';
  }

  @override
  String statsAccuracyPercent(String pct) {
    return '$pct% accuracy';
  }

  @override
  String get unitSamplesLoadingCatalog => 'Loading vocabulary…';

  @override
  String get unitSamplesTextSize => 'Text size';

  @override
  String get profilePresetBoy1 => 'Boy 1';

  @override
  String get profilePresetBoy2 => 'Boy 2';

  @override
  String get profilePresetBoy3 => 'Boy 3';

  @override
  String get profilePresetBoy4 => 'Boy 4';

  @override
  String get profilePresetGirl1 => 'Girl 1';

  @override
  String get profilePresetGirl2 => 'Girl 2';

  @override
  String get profilePresetGirl3 => 'Girl 3';

  @override
  String get profilePresetGirl4 => 'Girl 4';

  @override
  String get unitSampleUntitled => 'Sample';
}
