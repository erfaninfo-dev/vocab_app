// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IELTS Essential Words';

  @override
  String get tabHome => 'Home';

  @override
  String get tabGrammar => 'Grammar';

  @override
  String get tabReview => 'Review';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabSettings => 'Settings';

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
  String get search => 'Search';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

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
  String get couldNotLoadBooks => 'Could not load books.';

  @override
  String couldNotLoadBooksWithError(String error) {
    return 'Could not load books.\n$error';
  }

  @override
  String get noBooksFound => 'No books found';

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
  String get sectionAbout => 'About';

  @override
  String get sectionAppLanguage => 'App language';

  @override
  String get appLanguageSubtitle =>
      'Interface language (English, Persian, or Kurdish Sorani)';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get appNameShort => 'IELTS Words';

  @override
  String get byAuthor => 'By Erfan Abdi';

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
  String get changeMode => 'Change Mode';

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
  String get bookQuizSetupIntro =>
      'Choose units, how many questions, and whether to drill past mistakes.';

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
  String get accountTitle => 'Account';

  @override
  String get tabSignIn => 'Sign in';

  @override
  String get tabRegister => 'Register';

  @override
  String get statsMyProgress => 'My Progress';

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
      'This selection includes words marked important on the server.';

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
  String get save => 'Save';

  @override
  String get grammarResultsScreenTitle => 'Grammar results';

  @override
  String get grammarExplanationTabFa => 'Persian';

  @override
  String get grammarExplanationTabCkb => 'Kurdish';

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
  String get grammarSortNewestFirst => 'Newest first';

  @override
  String get grammarSortHighestScore => 'Highest score %';

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
}
