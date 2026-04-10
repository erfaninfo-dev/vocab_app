import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ckb.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ckb'),
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'IELTS Essential Words'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get tabGrammar;

  /// No description provided for @tabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get tabReview;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Calm, focused vocabulary practice'**
  String get splashTagline;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings.'**
  String get languageSelectionSubtitle;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langPersian.
  ///
  /// In en, this message translates to:
  /// **'Persian (Farsi)'**
  String get langPersian;

  /// No description provided for @langKurdishSorani.
  ///
  /// In en, this message translates to:
  /// **'Kurdish (Sorani)'**
  String get langKurdishSorani;

  /// No description provided for @chooseYourBook.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Book'**
  String get chooseYourBook;

  /// No description provided for @booksAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No books available} =1{1 book available} other{{count} books available}}'**
  String booksAvailable(int count);

  /// No description provided for @searchBooksHint.
  ///
  /// In en, this message translates to:
  /// **'Search books…'**
  String get searchBooksHint;

  /// No description provided for @couldNotLoadBooks.
  ///
  /// In en, this message translates to:
  /// **'Could not load books.'**
  String get couldNotLoadBooks;

  /// No description provided for @couldNotLoadBooksWithError.
  ///
  /// In en, this message translates to:
  /// **'Could not load books.\n{error}'**
  String couldNotLoadBooksWithError(String error);

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// No description provided for @bookSingular.
  ///
  /// In en, this message translates to:
  /// **'book'**
  String get bookSingular;

  /// No description provided for @bookPlural.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get bookPlural;

  /// No description provided for @unitSingular.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get unitSingular;

  /// No description provided for @unitPlural.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitPlural;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingEllipsis;

  /// No description provided for @tapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open'**
  String get tapToOpen;

  /// No description provided for @grammarPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar practice'**
  String get grammarPracticeTitle;

  /// No description provided for @grammarPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple-choice questions by grammar topic'**
  String get grammarPracticeSubtitle;

  /// No description provided for @reviewWordsDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word due for review!} other{{count} words due for review!}}'**
  String reviewWordsDue(int count);

  /// No description provided for @reviewTapStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start your daily review session'**
  String get reviewTapStart;

  /// No description provided for @obSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Books & words'**
  String get obSlide1Title;

  /// No description provided for @obSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Start from Home: pick a book, open units, then browse words. Use flashcards and quizzes inside each unit to study the way you like.'**
  String get obSlide1Body;

  /// No description provided for @obSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Grammar practice'**
  String get obSlide2Title;

  /// No description provided for @obSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Open the Grammar tab below. Select one or more topics and start a session — each run uses 20 random questions with explanations.'**
  String get obSlide2Body;

  /// No description provided for @obSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Daily review'**
  String get obSlide3Title;

  /// No description provided for @obSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Review uses spaced repetition for words you\'ve practiced. Check the badge on the tab when cards are due.'**
  String get obSlide3Body;

  /// No description provided for @obSlide4Title.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get obSlide4Title;

  /// No description provided for @obSlide4Body.
  ///
  /// In en, this message translates to:
  /// **'Progress shows streaks and activity. Keep a steady rhythm to build a habit.'**
  String get obSlide4Body;

  /// No description provided for @obSlide5Title.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get obSlide5Title;

  /// No description provided for @obSlide5Body.
  ///
  /// In en, this message translates to:
  /// **'In Settings: theme, translation language (Persian / Kurdish Sorani), reminders, and more.'**
  String get obSlide5Body;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — use email and password'**
  String get signInSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutBody;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get signedOut;

  /// No description provided for @loadingAccount.
  ///
  /// In en, this message translates to:
  /// **'Loading account…'**
  String get loadingAccount;

  /// No description provided for @sectionTranslationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translation language'**
  String get sectionTranslationLanguage;

  /// No description provided for @translationLangPersian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get translationLangPersian;

  /// No description provided for @translationLangKurdishSorani.
  ///
  /// In en, this message translates to:
  /// **'Kurdish (Sorani)'**
  String get translationLangKurdishSorani;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get systemTheme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @sectionDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get sectionDailyReminder;

  /// No description provided for @dailyStudyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily study reminder'**
  String get dailyStudyReminder;

  /// No description provided for @reminderSetAt.
  ///
  /// In en, this message translates to:
  /// **'Reminder set at {time}'**
  String reminderSetAt(String time);

  /// No description provided for @tapToEnableReminder.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable'**
  String get tapToEnableReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @sectionAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get sectionAppLanguage;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interface language (English, Persian, or Kurdish Sorani)'**
  String get appLanguageSubtitle;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @appNameShort.
  ///
  /// In en, this message translates to:
  /// **'IELTS Words'**
  String get appNameShort;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By Erfan Abdi'**
  String get byAuthor;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errNoInternet;

  /// No description provided for @errBadData.
  ///
  /// In en, this message translates to:
  /// **'Could not read data. Please try again.'**
  String get errBadData;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Please try again.'**
  String get errServer;

  /// No description provided for @reviewToday.
  ///
  /// In en, this message translates to:
  /// **'Review Today'**
  String get reviewToday;

  /// No description provided for @dueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String dueCount(int count);

  /// No description provided for @fetchErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load data. Please try again.'**
  String get fetchErrorRetry;

  /// No description provided for @tapCardToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap card to reveal answer'**
  String get tapCardToReveal;

  /// No description provided for @translateThisWord.
  ///
  /// In en, this message translates to:
  /// **'Translate this word'**
  String get translateThisWord;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @tapToSeeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap to see answer'**
  String get tapToSeeAnswer;

  /// No description provided for @howWellKnew.
  ///
  /// In en, this message translates to:
  /// **'How well did you know this?'**
  String get howWellKnew;

  /// No description provided for @pronounce.
  ///
  /// In en, this message translates to:
  /// **'Pronounce'**
  String get pronounce;

  /// No description provided for @speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking…'**
  String get speaking;

  /// No description provided for @noWordsDueTitle.
  ///
  /// In en, this message translates to:
  /// **'No words due today!'**
  String get noWordsDueTitle;

  /// No description provided for @noWordsDueBodyFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Start studying words using Flashcards to build your review queue.'**
  String get noWordsDueBodyFlashcards;

  /// No description provided for @noWordsDueBodyGreat.
  ///
  /// In en, this message translates to:
  /// **'Great job! Come back tomorrow for more reviews.\n{count, plural, =1{1 word} other{{count} words}} in your queue.'**
  String noWordsDueBodyGreat(int count);

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get sessionComplete;

  /// No description provided for @youReviewedToday.
  ///
  /// In en, this message translates to:
  /// **'You reviewed {count, plural, =1{1 word} other{{count} words}} today.'**
  String youReviewedToday(int count);

  /// No description provided for @wordsProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} words'**
  String wordsProgress(int current, int total);

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @couldNotLoadWords.
  ///
  /// In en, this message translates to:
  /// **'Could not load data. Please try again.'**
  String get couldNotLoadWords;

  /// No description provided for @couldNotLoadMistakes.
  ///
  /// In en, this message translates to:
  /// **'Could not load mistake list'**
  String get couldNotLoadMistakes;

  /// No description provided for @quizNotEnoughImportant.
  ///
  /// In en, this message translates to:
  /// **'No important words in this scope. Choose all words, change scope, or pick more units.'**
  String get quizNotEnoughImportant;

  /// No description provided for @quizNotEnoughWrongs.
  ///
  /// In en, this message translates to:
  /// **'No words from your mistake list in this selection. Adjust units or turn off “only past mistakes”.'**
  String get quizNotEnoughWrongs;

  /// No description provided for @quizNeedFourWords.
  ///
  /// In en, this message translates to:
  /// **'Need at least 4 words to start this quiz.'**
  String get quizNeedFourWords;

  /// No description provided for @quizNeedOneWord.
  ///
  /// In en, this message translates to:
  /// **'Need at least 1 word to start this quiz.'**
  String get quizNeedOneWord;

  /// No description provided for @quizScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz scope'**
  String get quizScopeTitle;

  /// No description provided for @quizScopeImportantDescription.
  ///
  /// In en, this message translates to:
  /// **'This list includes important words. Choose whether the quiz uses every word here or only important ones.'**
  String get quizScopeImportantDescription;

  /// No description provided for @allWordsCount.
  ///
  /// In en, this message translates to:
  /// **'All words ({count})'**
  String allWordsCount(int count);

  /// No description provided for @importantWordsOnlyCount.
  ///
  /// In en, this message translates to:
  /// **'Important words only ({count})'**
  String importantWordsOnlyCount(int count);

  /// No description provided for @importantOnlyNeedsFour.
  ///
  /// In en, this message translates to:
  /// **'Quiz only the words marked important in this list.'**
  String get importantOnlyNeedsFour;

  /// No description provided for @quizSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz setup'**
  String get quizSetupTitle;

  /// No description provided for @quizPoolSummary.
  ///
  /// In en, this message translates to:
  /// **'{pool} words in pool · min {min} question(s) · max {max}'**
  String quizPoolSummary(int pool, int min, int max);

  /// No description provided for @onlyPastMistakes.
  ///
  /// In en, this message translates to:
  /// **'Only past mistakes'**
  String get onlyPastMistakes;

  /// No description provided for @noMistakesYet.
  ///
  /// In en, this message translates to:
  /// **'No mistakes recorded yet for this scope.'**
  String get noMistakesYet;

  /// No description provided for @mistakesOnServer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mistake} other{{count} mistakes}} on server'**
  String mistakesOnServer(int count);

  /// No description provided for @signInForMistakes.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync mistakes and use “past mistakes” mode.'**
  String get signInForMistakes;

  /// No description provided for @numberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get numberOfQuestions;

  /// No description provided for @questionModes.
  ///
  /// In en, this message translates to:
  /// **'Question modes'**
  String get questionModes;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get startQuiz;

  /// No description provided for @quizMcqWordToMeaning.
  ///
  /// In en, this message translates to:
  /// **'Word → Meaning'**
  String get quizMcqWordToMeaning;

  /// No description provided for @quizMcqMeaningToWord.
  ///
  /// In en, this message translates to:
  /// **'Meaning → Word'**
  String get quizMcqMeaningToWord;

  /// No description provided for @quizWrittenMeaningToWord.
  ///
  /// In en, this message translates to:
  /// **'Fill in the blank'**
  String get quizWrittenMeaningToWord;

  /// No description provided for @whatIsMeaningOf.
  ///
  /// In en, this message translates to:
  /// **'What is the meaning of:'**
  String get whatIsMeaningOf;

  /// No description provided for @whichWordMeans.
  ///
  /// In en, this message translates to:
  /// **'Which word means:'**
  String get whichWordMeans;

  /// No description provided for @typeTheWord.
  ///
  /// In en, this message translates to:
  /// **'Type the word'**
  String get typeTheWord;

  /// No description provided for @typeYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type your answer…'**
  String get typeYourAnswer;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @seeResults.
  ///
  /// In en, this message translates to:
  /// **'See Results'**
  String get seeResults;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @learnedRemoveMistakes.
  ///
  /// In en, this message translates to:
  /// **'I learned it — remove from mistakes'**
  String get learnedRemoveMistakes;

  /// No description provided for @questionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} / {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @scoreCorrect.
  ///
  /// In en, this message translates to:
  /// **'{score} correct'**
  String scoreCorrect(int score);

  /// No description provided for @perfectScore.
  ///
  /// In en, this message translates to:
  /// **'Perfect score!'**
  String get perfectScore;

  /// No description provided for @excellentWork.
  ///
  /// In en, this message translates to:
  /// **'Excellent work!'**
  String get excellentWork;

  /// No description provided for @goodJob.
  ///
  /// In en, this message translates to:
  /// **'Good job!'**
  String get goodJob;

  /// No description provided for @keepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing!'**
  String get keepPracticing;

  /// No description provided for @dontGiveUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t give up!'**
  String get dontGiveUp;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @changeMode.
  ///
  /// In en, this message translates to:
  /// **'Change Mode'**
  String get changeMode;

  /// No description provided for @backToWords.
  ///
  /// In en, this message translates to:
  /// **'Back to Words'**
  String get backToWords;

  /// No description provided for @correctLine.
  ///
  /// In en, this message translates to:
  /// **'Correct: {answer}'**
  String correctLine(String answer);

  /// No description provided for @wrongBlankLine.
  ///
  /// In en, this message translates to:
  /// **'Wrong (blank). Correct answer: {correct}'**
  String wrongBlankLine(String correct);

  /// No description provided for @wrongAnswerLine.
  ///
  /// In en, this message translates to:
  /// **'Wrong: {given} · Correct answer: {correct}'**
  String wrongAnswerLine(String given, String correct);

  /// No description provided for @removedFromMistakes.
  ///
  /// In en, this message translates to:
  /// **'Removed from your mistake list'**
  String get removedFromMistakes;

  /// No description provided for @couldNotUpdateServer.
  ///
  /// In en, this message translates to:
  /// **'Could not update server'**
  String get couldNotUpdateServer;

  /// No description provided for @unitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitsTitle;

  /// No description provided for @backToBooks.
  ///
  /// In en, this message translates to:
  /// **'Back to books'**
  String get backToBooks;

  /// No description provided for @bookQuiz.
  ///
  /// In en, this message translates to:
  /// **'Book quiz'**
  String get bookQuiz;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @failedLoadSections.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sections. Please retry.'**
  String get failedLoadSections;

  /// No description provided for @wordsUnitSection.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} • Section {section}'**
  String wordsUnitSection(int unit, int section);

  /// No description provided for @wordsUnitOnly.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit}'**
  String wordsUnitOnly(int unit);

  /// No description provided for @tooltipQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get tooltipQuiz;

  /// No description provided for @tooltipFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get tooltipFlashcards;

  /// No description provided for @searchWordWholeBook.
  ///
  /// In en, this message translates to:
  /// **'Search word (whole book)…'**
  String get searchWordWholeBook;

  /// No description provided for @noMatchingWords.
  ///
  /// In en, this message translates to:
  /// **'No matching words found.'**
  String get noMatchingWords;

  /// No description provided for @sectionInUnit.
  ///
  /// In en, this message translates to:
  /// **'Section {section} in Unit {unit}'**
  String sectionInUnit(int section, int unit);

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit}'**
  String unitLabel(int unit);

  /// No description provided for @matchesWholeBook.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} matches (whole book)'**
  String matchesWholeBook(int filtered, int total);

  /// No description provided for @wordsVisible.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} words visible'**
  String wordsVisible(int filtered, int total);

  /// No description provided for @vocabularyQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary quiz'**
  String get vocabularyQuizTitle;

  /// No description provided for @bookQuizSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose units, how many questions, and whether to drill past mistakes.'**
  String get bookQuizSetupIntro;

  /// No description provided for @unitsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitsSectionTitle;

  /// No description provided for @couldNotLoadMistakesShort.
  ///
  /// In en, this message translates to:
  /// **'Could not load mistakes'**
  String get couldNotLoadMistakesShort;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose email and password (at least 8 characters). No email or SMS code — you can sign in right away.'**
  String get registerSubtitle;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameOptional;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your email and password. No verification step — your account is active immediately.'**
  String get loginSubtitle;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNoMatch;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @tabSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get tabSignIn;

  /// No description provided for @tabRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get tabRegister;

  /// No description provided for @statsMyProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get statsMyProgress;

  /// No description provided for @wordMastery.
  ///
  /// In en, this message translates to:
  /// **'Word Mastery'**
  String get wordMastery;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @quizInsights.
  ///
  /// In en, this message translates to:
  /// **'Quiz insights'**
  String get quizInsights;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @vocabAndGrammar.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary & grammar'**
  String get vocabAndGrammar;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}} streak'**
  String streakDays(int count);

  /// No description provided for @longest.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get longest;

  /// No description provided for @totalDays.
  ///
  /// In en, this message translates to:
  /// **'Total Days'**
  String get totalDays;

  /// No description provided for @mastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered  '**
  String get mastered;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning  '**
  String get learning;

  /// No description provided for @seenOnce.
  ///
  /// In en, this message translates to:
  /// **'Seen once  '**
  String get seenOnce;

  /// No description provided for @wordsReviewedPerDay.
  ///
  /// In en, this message translates to:
  /// **'Words reviewed per day'**
  String get wordsReviewedPerDay;

  /// No description provided for @totalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get totalReviews;

  /// No description provided for @studyDays.
  ///
  /// In en, this message translates to:
  /// **'Study Days'**
  String get studyDays;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz insights'**
  String get insightsTitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get tabVocabulary;

  /// No description provided for @tabGrammarStats.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get tabGrammarStats;

  /// No description provided for @insightsLast14.
  ///
  /// In en, this message translates to:
  /// **'Last 14 days: vocabulary (this device) vs grammar (saved to your account).'**
  String get insightsLast14;

  /// No description provided for @insightsSignInGrammar.
  ///
  /// In en, this message translates to:
  /// **'Sign in to load grammar scores. Vocabulary bars still use local quiz data.'**
  String get insightsSignInGrammar;

  /// No description provided for @insightsGrammarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load grammar data for the chart.'**
  String get insightsGrammarLoadError;

  /// No description provided for @vocabDailyAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Daily accuracy from vocabulary quizzes (stored on this device).'**
  String get vocabDailyAccuracy;

  /// No description provided for @allTimeDevice.
  ///
  /// In en, this message translates to:
  /// **'All-time (device)'**
  String get allTimeDevice;

  /// No description provided for @grammarPracticeAppBar.
  ///
  /// In en, this message translates to:
  /// **'Grammar practice'**
  String get grammarPracticeAppBar;

  /// No description provided for @grammarTooltipResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get grammarTooltipResults;

  /// No description provided for @grammarTooltipUnselectAll.
  ///
  /// In en, this message translates to:
  /// **'Unselect all'**
  String get grammarTooltipUnselectAll;

  /// No description provided for @grammarSelectTopicsCta.
  ///
  /// In en, this message translates to:
  /// **'Select topics'**
  String get grammarSelectTopicsCta;

  /// No description provided for @grammarContinueTopics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Continue (1 topic)} other{Continue ({count} topics)}}'**
  String grammarContinueTopics(int count);

  /// No description provided for @grammarCouldNotLoadTopics.
  ///
  /// In en, this message translates to:
  /// **'Could not load grammar topics. Please try again.'**
  String get grammarCouldNotLoadTopics;

  /// No description provided for @grammarNoTopicsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No grammar topics yet.\nAdd rows to your questions table (column content = topic name).'**
  String get grammarNoTopicsEmpty;

  /// No description provided for @grammarNotEnoughInBank.
  ///
  /// In en, this message translates to:
  /// **'Not enough questions in the bank for this selection (need at least {minRequired}).'**
  String grammarNotEnoughInBank(int minRequired);

  /// No description provided for @grammarNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions found for the selected topics.'**
  String get grammarNoQuestions;

  /// No description provided for @grammarTopicsPick.
  ///
  /// In en, this message translates to:
  /// **'Pick topics and session length'**
  String get grammarTopicsPick;

  /// No description provided for @exitExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit exercise?'**
  String get exitExerciseTitle;

  /// No description provided for @exitExerciseBody.
  ///
  /// In en, this message translates to:
  /// **'If you go back now, your progress for this session will not be saved.'**
  String get exitExerciseBody;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @grammarAppBar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammarAppBar;

  /// No description provided for @noTopicSelected.
  ///
  /// In en, this message translates to:
  /// **'No topic selected.'**
  String get noTopicSelected;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit report. Please try again.'**
  String get reportFailed;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @couldNotSaveResult.
  ///
  /// In en, this message translates to:
  /// **'Could not save your result. Please try again.'**
  String get couldNotSaveResult;

  /// No description provided for @keepPrivate.
  ///
  /// In en, this message translates to:
  /// **'Keep private (only for me)'**
  String get keepPrivate;

  /// No description provided for @showCommunity.
  ///
  /// In en, this message translates to:
  /// **'Show in community results'**
  String get showCommunity;

  /// No description provided for @practiseAgain.
  ///
  /// In en, this message translates to:
  /// **'Practise again'**
  String get practiseAgain;

  /// No description provided for @backToTopics.
  ///
  /// In en, this message translates to:
  /// **'Back to topics'**
  String get backToTopics;

  /// No description provided for @reviewSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Review session'**
  String get reviewSessionTitle;

  /// No description provided for @couldNotLoadResult.
  ///
  /// In en, this message translates to:
  /// **'Could not load this result.'**
  String get couldNotLoadResult;

  /// No description provided for @myResults.
  ///
  /// In en, this message translates to:
  /// **'My results'**
  String get myResults;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @tryAgainResults.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainResults;

  /// No description provided for @wordExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get wordExample;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @pronounceWord.
  ///
  /// In en, this message translates to:
  /// **'Pronounce word'**
  String get pronounceWord;

  /// No description provided for @pronounceExample.
  ///
  /// In en, this message translates to:
  /// **'Pronounce example'**
  String get pronounceExample;

  /// No description provided for @couldNotUpdateImportant.
  ///
  /// In en, this message translates to:
  /// **'Could not update important flag'**
  String get couldNotUpdateImportant;

  /// No description provided for @markedImportant.
  ///
  /// In en, this message translates to:
  /// **'Marked as important'**
  String get markedImportant;

  /// No description provided for @removedImportant.
  ///
  /// In en, this message translates to:
  /// **'Removed from important'**
  String get removedImportant;

  /// No description provided for @savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Will sync on refresh.'**
  String get savedLocally;

  /// No description provided for @registerEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get registerEmailTaken;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerFailed;

  /// No description provided for @loginInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginInvalid;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get passwordResetTitle;

  /// No description provided for @passwordResetBody.
  ///
  /// In en, this message translates to:
  /// **'Due to internet restrictions, email reset may not work. For help, message erfaninfox on Bale or Rubika.'**
  String get passwordResetBody;

  /// No description provided for @copySupportLink.
  ///
  /// In en, this message translates to:
  /// **'Copy support link'**
  String get copySupportLink;

  /// No description provided for @supportLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Support link copied — open in browser or Rubika'**
  String get supportLinkCopied;

  /// No description provided for @copyRequestText.
  ///
  /// In en, this message translates to:
  /// **'Copy request text'**
  String get copyRequestText;

  /// No description provided for @requestTextCopied.
  ///
  /// In en, this message translates to:
  /// **'Request text copied — send it in Bale or Rubika'**
  String get requestTextCopied;

  /// No description provided for @statsSignInGrammarTrend.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see grammar score trends from your saved quizzes.'**
  String get statsSignInGrammarTrend;

  /// No description provided for @statsCouldNotLoadGrammar.
  ///
  /// In en, this message translates to:
  /// **'Could not load grammar stats.'**
  String get statsCouldNotLoadGrammar;

  /// No description provided for @statsNoGrammarYet.
  ///
  /// In en, this message translates to:
  /// **'No grammar results yet. Complete a grammar quiz and save your score.'**
  String get statsNoGrammarYet;

  /// No description provided for @grammarOverview.
  ///
  /// In en, this message translates to:
  /// **'Grammar overview'**
  String get grammarOverview;

  /// No description provided for @averageLastAttempts.
  ///
  /// In en, this message translates to:
  /// **'Average (last {count} saved): '**
  String averageLastAttempts(int count);

  /// No description provided for @attempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get attempts;

  /// No description provided for @lastLabel.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get lastLabel;

  /// No description provided for @bestLabel.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get bestLabel;

  /// No description provided for @worstLabel.
  ///
  /// In en, this message translates to:
  /// **'Worst'**
  String get worstLabel;

  /// No description provided for @trendLabel.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trendLabel;

  /// No description provided for @scoreTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Score trend (oldest → newest)'**
  String get scoreTrendTitle;

  /// No description provided for @saveTwoQuizzesChart.
  ///
  /// In en, this message translates to:
  /// **'Save at least two grammar quizzes to see a line chart.'**
  String get saveTwoQuizzesChart;

  /// No description provided for @attemptsDistribution.
  ///
  /// In en, this message translates to:
  /// **'Attempts distribution'**
  String get attemptsDistribution;

  /// No description provided for @vocabDailyChartHint.
  ///
  /// In en, this message translates to:
  /// **'Answer vocabulary quiz questions to see daily accuracy here.'**
  String get vocabDailyChartHint;

  /// No description provided for @noQuizDataRange.
  ///
  /// In en, this message translates to:
  /// **'No quiz data in this range yet.'**
  String get noQuizDataRange;

  /// No description provided for @legendVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get legendVocabulary;

  /// No description provided for @legendGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get legendGrammar;

  /// No description provided for @insightsVocabVsGrammar.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get insightsVocabVsGrammar;

  /// No description provided for @bookQuizChooseUnits.
  ///
  /// In en, this message translates to:
  /// **'Choose units'**
  String get bookQuizChooseUnits;

  /// No description provided for @nextDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String nextDaysShort(int n);

  /// No description provided for @vocabQuizExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit quiz?'**
  String get vocabQuizExitTitle;

  /// No description provided for @vocabQuizExitBody.
  ///
  /// In en, this message translates to:
  /// **'If you leave now, your progress for this quiz will be lost.'**
  String get vocabQuizExitBody;

  /// No description provided for @importantWordsSection.
  ///
  /// In en, this message translates to:
  /// **'Important words'**
  String get importantWordsSection;

  /// No description provided for @importantWordsServerHint.
  ///
  /// In en, this message translates to:
  /// **'This selection includes words marked important on the server.'**
  String get importantWordsServerHint;

  /// No description provided for @allWordsChip.
  ///
  /// In en, this message translates to:
  /// **'All words'**
  String get allWordsChip;

  /// No description provided for @importantOnlyChip.
  ///
  /// In en, this message translates to:
  /// **'Important only'**
  String get importantOnlyChip;

  /// No description provided for @bookQuizQuestionsSlider.
  ///
  /// In en, this message translates to:
  /// **'Questions (max {max})'**
  String bookQuizQuestionsSlider(int max);

  /// No description provided for @bookQuizPoolTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Need at least 4 words in the pool (check units / mistakes).'**
  String get bookQuizPoolTooSmall;

  /// No description provided for @bookQuizPoolTooSmallImportant.
  ///
  /// In en, this message translates to:
  /// **'No important words in this selection. Choose all words or adjust units / mistakes.'**
  String get bookQuizPoolTooSmallImportant;

  /// No description provided for @statsStudiedToday.
  ///
  /// In en, this message translates to:
  /// **'✅ Studied today!'**
  String get statsStudiedToday;

  /// No description provided for @statsStudyToKeepStreak.
  ///
  /// In en, this message translates to:
  /// **'📖 Study today to keep your streak'**
  String get statsStudyToKeepStreak;

  /// No description provided for @statsInsightsCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'14-day charts, trends, and breakdown by type'**
  String get statsInsightsCardSubtitle;

  /// No description provided for @statsVocabDeviceAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Vocab (device): {pct}% ({correct} / {answered})'**
  String statsVocabDeviceAccuracy(String pct, int correct, int answered);

  /// No description provided for @statsWordsStudiedTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word studied in total} other{{count} words studied in total}}'**
  String statsWordsStudiedTotal(int count);

  /// No description provided for @srsRatingAgain.
  ///
  /// In en, this message translates to:
  /// **'❌ Again'**
  String get srsRatingAgain;

  /// No description provided for @srsRatingHard.
  ///
  /// In en, this message translates to:
  /// **'😐 Hard'**
  String get srsRatingHard;

  /// No description provided for @srsRatingGood.
  ///
  /// In en, this message translates to:
  /// **'✅ Good'**
  String get srsRatingGood;

  /// No description provided for @srsRatingEasy.
  ///
  /// In en, this message translates to:
  /// **'🔥 Easy'**
  String get srsRatingEasy;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileScreenTitle;

  /// No description provided for @profileSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to edit your profile.'**
  String get profileSignInPrompt;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @profileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Try again or pick a smaller image.'**
  String get profileUploadFailed;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave anyway?'**
  String get unsavedChangesBody;

  /// No description provided for @discardStay.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discardStay;

  /// No description provided for @discardLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get discardLeave;

  /// No description provided for @profileCropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get profileCropPhoto;

  /// No description provided for @profileGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get profileGallery;

  /// No description provided for @profileCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get profileCamera;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How your name appears'**
  String get profileDisplayNameHint;

  /// No description provided for @profilePresetAvatars.
  ///
  /// In en, this message translates to:
  /// **'Or pick a preset avatar'**
  String get profilePresetAvatars;

  /// No description provided for @profileBoyAvatars.
  ///
  /// In en, this message translates to:
  /// **'Boy avatars'**
  String get profileBoyAvatars;

  /// No description provided for @profileGirlAvatars.
  ///
  /// In en, this message translates to:
  /// **'Girl avatars'**
  String get profileGirlAvatars;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @grammarResultsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar results'**
  String get grammarResultsScreenTitle;

  /// No description provided for @grammarExplanationTabFa.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get grammarExplanationTabFa;

  /// No description provided for @grammarExplanationTabCkb.
  ///
  /// In en, this message translates to:
  /// **'Kurdish'**
  String get grammarExplanationTabCkb;

  /// No description provided for @grammarReportProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get grammarReportProblemTitle;

  /// No description provided for @grammarReportWhatWrong.
  ///
  /// In en, this message translates to:
  /// **'What is wrong?'**
  String get grammarReportWhatWrong;

  /// No description provided for @grammarReportDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get grammarReportDetailsOptional;

  /// No description provided for @grammarReportKindWrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Marked correct answer is wrong'**
  String get grammarReportKindWrongAnswer;

  /// No description provided for @grammarReportKindTypoQuestion.
  ///
  /// In en, this message translates to:
  /// **'Typo in the question text'**
  String get grammarReportKindTypoQuestion;

  /// No description provided for @grammarReportKindTypoOptions.
  ///
  /// In en, this message translates to:
  /// **'Multiple options look correct'**
  String get grammarReportKindTypoOptions;

  /// No description provided for @grammarReportKindBadExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation is wrong or incomplete'**
  String get grammarReportKindBadExplanation;

  /// No description provided for @grammarReportKindUnclear.
  ///
  /// In en, this message translates to:
  /// **'Question wording is unclear'**
  String get grammarReportKindUnclear;

  /// No description provided for @grammarReportKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get grammarReportKindOther;

  /// No description provided for @grammarReportQuestionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report question'**
  String get grammarReportQuestionTooltip;

  /// No description provided for @grammarTopicsCountAppBar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 topic} other{{count} topics}}'**
  String grammarTopicsCountAppBar(int count);

  /// No description provided for @grammarSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get grammarSortNewestFirst;

  /// No description provided for @grammarSortHighestScore.
  ///
  /// In en, this message translates to:
  /// **'Highest score %'**
  String get grammarSortHighestScore;

  /// No description provided for @grammarSortMostPractice.
  ///
  /// In en, this message translates to:
  /// **'Most practice'**
  String get grammarSortMostPractice;

  /// No description provided for @grammarSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get grammarSortLabel;

  /// No description provided for @grammarSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get grammarSignInRequiredTitle;

  /// No description provided for @grammarSignInRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your personal history and private/public labels.'**
  String get grammarSignInRequiredBody;

  /// No description provided for @grammarGoToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings & sign in'**
  String get grammarGoToSignIn;

  /// No description provided for @grammarLoadingYourResults.
  ///
  /// In en, this message translates to:
  /// **'Loading your results…'**
  String get grammarLoadingYourResults;

  /// No description provided for @grammarLoadingCommunityResults.
  ///
  /// In en, this message translates to:
  /// **'Loading community results…'**
  String get grammarLoadingCommunityResults;

  /// No description provided for @grammarNoPersonalResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get grammarNoPersonalResultsTitle;

  /// No description provided for @grammarNoPersonalResultsBody.
  ///
  /// In en, this message translates to:
  /// **'After you finish a grammar session, your score will appear here.'**
  String get grammarNoPersonalResultsBody;

  /// No description provided for @grammarCommunityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get grammarCommunityEmptyTitle;

  /// No description provided for @grammarCommunityEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you choose “Show in community results” at the end of a quiz, it will appear in this list.'**
  String get grammarCommunityEmptyBody;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestUser;

  /// No description provided for @resultVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get resultVisibilityPublic;

  /// No description provided for @resultVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get resultVisibilityPrivate;

  /// No description provided for @errorConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get errorConnectionTryAgain;

  /// No description provided for @grammarSheetSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions in this session'**
  String get grammarSheetSessionTitle;

  /// No description provided for @grammarSheetHintSingleTopic.
  ///
  /// In en, this message translates to:
  /// **'Questions are drawn at random from this topic only.'**
  String get grammarSheetHintSingleTopic;

  /// No description provided for @grammarSheetHintMultiTopic.
  ///
  /// In en, this message translates to:
  /// **'Questions are mixed at random from all selected topics for varied practice.'**
  String get grammarSheetHintMultiTopic;

  /// No description provided for @grammarSheetUpToInBank.
  ///
  /// In en, this message translates to:
  /// **'{max, plural, =1{Up to 1 question available in the bank.} other{Up to {max} questions available in the bank.}}'**
  String grammarSheetUpToInBank(int max);

  /// No description provided for @grammarSheetMinSession.
  ///
  /// In en, this message translates to:
  /// **'Minimum this session: {min} (at least {base}, or one per topic if you pick several).'**
  String grammarSheetMinSession(int min, int base);

  /// No description provided for @grammarSheetQuickPick.
  ///
  /// In en, this message translates to:
  /// **'Quick pick'**
  String get grammarSheetQuickPick;

  /// No description provided for @grammarQuestionNoun.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{question} other{questions}}'**
  String grammarQuestionNoun(int count);

  /// No description provided for @grammarCouldNotLoadQuestions.
  ///
  /// In en, this message translates to:
  /// **'Could not load questions. Please try again.'**
  String get grammarCouldNotLoadQuestions;

  /// No description provided for @grammarNoQuestionsForTopics.
  ///
  /// In en, this message translates to:
  /// **'No questions for the selected topic(s).'**
  String get grammarNoQuestionsForTopics;

  /// No description provided for @grammarExplanationHeading.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get grammarExplanationHeading;

  /// No description provided for @grammarSessionCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get grammarSessionCompleteTitle;

  /// No description provided for @grammarScoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'You got {score} out of {total} correct.'**
  String grammarScoreOutOf(int score, int total);

  /// No description provided for @grammarHowSaveResult.
  ///
  /// In en, this message translates to:
  /// **'How should we save this result?'**
  String get grammarHowSaveResult;

  /// No description provided for @grammarSaveResultFootnote.
  ///
  /// In en, this message translates to:
  /// **'Private results appear only under My results; public results appear in the Users tab.'**
  String get grammarSaveResultFootnote;

  /// No description provided for @grammarResultSavedShort.
  ///
  /// In en, this message translates to:
  /// **'Result saved'**
  String get grammarResultSavedShort;

  /// No description provided for @statsDaysOnly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String statsDaysOnly(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ckb', 'en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ckb':
      return AppLocalizationsCkb();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
