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
  /// **'Erfan Academy'**
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

  /// No description provided for @tabPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tabPlay;

  /// No description provided for @youSectionReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get youSectionReview;

  /// No description provided for @youSectionReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spaced repetition for words you\'ve practiced.'**
  String get youSectionReviewSubtitle;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get tabYou;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @youPageTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youPageTitle;

  /// No description provided for @youSectionProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get youSectionProgress;

  /// No description provided for @youSectionProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Streaks, stats, and quiz insights'**
  String get youSectionProgressSubtitle;

  /// No description provided for @youSectionMessages.
  ///
  /// In en, this message translates to:
  /// **'Your teacher'**
  String get youSectionMessages;

  /// No description provided for @youSectionMessagesHub.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get youSectionMessagesHub;

  /// No description provided for @youSectionMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with your class teacher'**
  String get youSectionMessagesSubtitle;

  /// No description provided for @youSectionMessagesSubtitleHub.
  ///
  /// In en, this message translates to:
  /// **'Chats with your teacher and staff'**
  String get youSectionMessagesSubtitleHub;

  /// No description provided for @youMessagesPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Your chats'**
  String get youMessagesPickTitle;

  /// No description provided for @youTeacherPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students and class activity'**
  String get youTeacherPanelSubtitle;

  /// No description provided for @chatSenderYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatSenderYou;

  /// No description provided for @teacherStudentChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get teacherStudentChat;

  /// No description provided for @teacherInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get teacherInboxTitle;

  /// No description provided for @teacherInboxOpenPanel.
  ///
  /// In en, this message translates to:
  /// **'Full student list'**
  String get teacherInboxOpenPanel;

  /// No description provided for @chatListYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatListYesterday;

  /// No description provided for @chatPreviewYouPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: '**
  String get chatPreviewYouPrefix;

  /// No description provided for @teacherChatHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get teacherChatHint;

  /// No description provided for @teacherMessagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get teacherMessagesEmpty;

  /// No description provided for @chatMessageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatMessageEdit;

  /// No description provided for @chatMessageEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chatMessageEditTitle;

  /// No description provided for @chatMessageEditHint.
  ///
  /// In en, this message translates to:
  /// **'Update your message…'**
  String get chatMessageEditHint;

  /// No description provided for @chatMessageEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get chatMessageEdited;

  /// No description provided for @chatMessageEditFailedRead.
  ///
  /// In en, this message translates to:
  /// **'This message has already been read and can\'t be edited.'**
  String get chatMessageEditFailedRead;

  /// No description provided for @chatMessageEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get chatMessageEditSave;

  /// No description provided for @chatMessageReadStateSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatMessageReadStateSent;

  /// No description provided for @chatMessageReadStateRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatMessageReadStateRead;

  /// No description provided for @teacherMessagesNoTeacher.
  ///
  /// In en, this message translates to:
  /// **'Use your student code so a teacher can be assigned to you.'**
  String get teacherMessagesNoTeacher;

  /// No description provided for @newMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new} other{{count} new}}'**
  String newMessagesCount(int count);

  /// No description provided for @tabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// No description provided for @studentBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Your class books'**
  String get studentBooksTitle;

  /// No description provided for @registerAsStudent.
  ///
  /// In en, this message translates to:
  /// **'Your student'**
  String get registerAsStudent;

  /// No description provided for @studentCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Student code'**
  String get studentCodeLabel;

  /// No description provided for @studentCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the code your teacher gave you'**
  String get studentCodeRequired;

  /// No description provided for @redeemStudentCode.
  ///
  /// In en, this message translates to:
  /// **'Enter student code'**
  String get redeemStudentCode;

  /// No description provided for @redeemStudentCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 5-digit code from your teacher.'**
  String get redeemStudentCodeSubtitle;

  /// No description provided for @createStudentCode.
  ///
  /// In en, this message translates to:
  /// **'Create student code'**
  String get createStudentCode;

  /// No description provided for @createStudentCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register a one-time 5-digit code for one student.'**
  String get createStudentCodeSubtitle;

  /// No description provided for @studentCodeFiveDigitsHint.
  ///
  /// In en, this message translates to:
  /// **'12345'**
  String get studentCodeFiveDigitsHint;

  /// No description provided for @studentCodeFiveDigitsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 5 digits'**
  String get studentCodeFiveDigitsInvalid;

  /// No description provided for @teacherStudentCodeRegistered.
  ///
  /// In en, this message translates to:
  /// **'Code {code} is ready for one student.'**
  String teacherStudentCodeRegistered(String code);

  /// No description provided for @teacherStudentCodeRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not register this code.'**
  String get teacherStudentCodeRegisterFailed;

  /// No description provided for @teacherUnusedCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unused codes'**
  String get teacherUnusedCodesTitle;

  /// No description provided for @invalidStudentCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code.'**
  String get invalidStudentCode;

  /// No description provided for @studentAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Student access enabled.'**
  String get studentAccessGranted;

  /// No description provided for @studentTabSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your teacher\'s books.'**
  String get studentTabSignIn;

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

  /// No description provided for @unitSamplesOpen.
  ///
  /// In en, this message translates to:
  /// **'Sample texts'**
  String get unitSamplesOpen;

  /// No description provided for @unitSamplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} — Sample texts'**
  String unitSamplesTitle(int unit);

  /// No description provided for @unitSamplesTitleSection.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} — Section {section} — Sample texts'**
  String unitSamplesTitleSection(int unit, int section);

  /// No description provided for @unitSamplesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sample texts for this unit yet.'**
  String get unitSamplesEmpty;

  /// No description provided for @unitSamplesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load sample texts.'**
  String get unitSamplesLoadFailed;

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

  /// No description provided for @errServerReturnedError.
  ///
  /// In en, this message translates to:
  /// **'The server returned an error. Please try again later.'**
  String get errServerReturnedError;

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

  /// No description provided for @homeReceivingBooks.
  ///
  /// In en, this message translates to:
  /// **'Receiving…'**
  String get homeReceivingBooks;

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

  /// No description provided for @homeTrackIelts.
  ///
  /// In en, this message translates to:
  /// **'IELTS'**
  String get homeTrackIelts;

  /// No description provided for @homeTrackGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get homeTrackGeneral;

  /// No description provided for @homeBooksSeriesOther.
  ///
  /// In en, this message translates to:
  /// **'Other books'**
  String get homeBooksSeriesOther;

  /// No description provided for @homeSeriesCambridgeTests.
  ///
  /// In en, this message translates to:
  /// **'Cambridge IELTS Tests'**
  String get homeSeriesCambridgeTests;

  /// No description provided for @homeSeriesVolumesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book in series} other{{count} books in series}}'**
  String homeSeriesVolumesCount(int count);

  /// No description provided for @seriesBooksGridHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book · tap a card to open} other{{count} books · tap a card to open}}'**
  String seriesBooksGridHint(int count);

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

  /// No description provided for @sectionSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sectionSound;

  /// No description provided for @splashSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Startup chime'**
  String get splashSoundTitle;

  /// No description provided for @splashSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a calming sound when the app opens'**
  String get splashSoundSubtitle;

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
  /// **'Erfan Academy'**
  String get appNameShort;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By Erfan Abdi'**
  String get byAuthor;

  /// No description provided for @aboutAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String aboutAppVersion(String version, String buildNumber);

  /// No description provided for @aboutUpdateFromPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Get the latest version'**
  String get aboutUpdateFromPlayStore;

  /// No description provided for @aboutAppUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version installed.'**
  String get aboutAppUpToDate;

  /// No description provided for @aboutUpdateAvailableVersion.
  ///
  /// In en, this message translates to:
  /// **'New version available: {version}'**
  String aboutUpdateAvailableVersion(String version);

  /// No description provided for @aboutDownloadApkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get aboutDownloadApkUpdate;

  /// No description provided for @aboutDownloadingApk.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get aboutDownloadingApk;

  /// No description provided for @aboutDownloadApkFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check your connection and try again.'**
  String get aboutDownloadApkFailed;

  /// No description provided for @aboutInstallApkHint.
  ///
  /// In en, this message translates to:
  /// **'If prompted, allow installing updates from this app in system settings.'**
  String get aboutInstallApkHint;

  /// No description provided for @aboutDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get aboutDownloadComplete;

  /// No description provided for @aboutInstallReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'The update has been downloaded. Tap Install to update Erfan Academy. Your account and data will be preserved.'**
  String get aboutInstallReadyMessage;

  /// No description provided for @aboutInstallNow.
  ///
  /// In en, this message translates to:
  /// **'Install now'**
  String get aboutInstallNow;

  /// No description provided for @aboutInstallPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Android needs permission to install updates from this app. Allow it in Settings → Apps → Erfan Academy → Install unknown apps, then tap Install again.'**
  String get aboutInstallPermissionRequired;

  /// No description provided for @aboutInstallLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the installer. Please try again.'**
  String get aboutInstallLaunchFailed;

  /// No description provided for @aboutForcedUpdateNote.
  ///
  /// In en, this message translates to:
  /// **'This update is required. Please download and install the latest version.'**
  String get aboutForcedUpdateNote;

  /// No description provided for @aboutUpdateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates.'**
  String get aboutUpdateCheckFailed;

  /// No description provided for @aboutRetryUpdateCheck.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get aboutRetryUpdateCheck;

  /// No description provided for @homeNewUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'New updates'**
  String get homeNewUpdatesTitle;

  /// No description provided for @homeNewUpdatesLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get homeNewUpdatesLetsGo;

  /// No description provided for @aboutLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get aboutLater;

  /// No description provided for @aboutCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get aboutCouldNotOpenLink;

  /// No description provided for @aboutPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get aboutPhoneLabel;

  /// No description provided for @aboutPhoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied to clipboard'**
  String get aboutPhoneCopied;

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

  /// No description provided for @couldNotLoadLeague.
  ///
  /// In en, this message translates to:
  /// **'Could not load the league'**
  String get couldNotLoadLeague;

  /// No description provided for @leagueErrorPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh.'**
  String get leagueErrorPullToRefresh;

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

  /// No description provided for @quizSpellingListenAndType.
  ///
  /// In en, this message translates to:
  /// **'Listen & spell'**
  String get quizSpellingListenAndType;

  /// No description provided for @quizSpellingListenPrompt.
  ///
  /// In en, this message translates to:
  /// **'Listen and type the English word:'**
  String get quizSpellingListenPrompt;

  /// No description provided for @quizReplayAudio.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get quizReplayAudio;

  /// No description provided for @quizSpellingTypeEnglish.
  ///
  /// In en, this message translates to:
  /// **'Type the English word'**
  String get quizSpellingTypeEnglish;

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

  /// No description provided for @backToQuiz.
  ///
  /// In en, this message translates to:
  /// **'Back to quiz'**
  String get backToQuiz;

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

  /// No description provided for @quizFeedbackWrongPrefix.
  ///
  /// In en, this message translates to:
  /// **'Wrong:'**
  String get quizFeedbackWrongPrefix;

  /// No description provided for @quizFeedbackCorrectLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct answer:'**
  String get quizFeedbackCorrectLabel;

  /// No description provided for @quizWrongBlankIntro.
  ///
  /// In en, this message translates to:
  /// **'Wrong (blank).'**
  String get quizWrongBlankIntro;

  /// No description provided for @quizWrittenFirstLetterMismatch.
  ///
  /// In en, this message translates to:
  /// **'Wrong first letter — the answer doesn’t start with that.'**
  String get quizWrittenFirstLetterMismatch;

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

  /// No description provided for @vocabQuizHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary quiz history'**
  String get vocabQuizHistoryTitle;

  /// No description provided for @vocabQuizHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions are saved on your account so you can review them on any device.'**
  String get vocabQuizHistorySubtitle;

  /// No description provided for @vocabQuizHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vocabulary quiz sessions yet.'**
  String get vocabQuizHistoryEmpty;

  /// No description provided for @vocabQuizHistorySignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save quiz results to the server and view them here.'**
  String get vocabQuizHistorySignIn;

  /// No description provided for @vocabQuizHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Quiz history could not be loaded. The server may be missing the results table—run api/vocab_quiz_results_schema.sql on MySQL, or try again later.'**
  String get vocabQuizHistoryLoadError;

  /// No description provided for @vocabQuizResultDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get vocabQuizResultDetailTitle;

  /// No description provided for @vocabQuizResultScoreLine.
  ///
  /// In en, this message translates to:
  /// **'{score} / {total} correct'**
  String vocabQuizResultScoreLine(int score, int total);

  /// No description provided for @vocabQuizResultYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get vocabQuizResultYourAnswer;

  /// No description provided for @vocabQuizResultCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get vocabQuizResultCorrect;

  /// No description provided for @vocabQuizResultIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get vocabQuizResultIncorrect;

  /// No description provided for @vocabQuizResultQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get vocabQuizResultQuestion;

  /// No description provided for @vocabQuizHistoryUnitsLine.
  ///
  /// In en, this message translates to:
  /// **'Units: {units}'**
  String vocabQuizHistoryUnitsLine(String units);

  /// No description provided for @vocabQuizCorrectWrongLine.
  ///
  /// In en, this message translates to:
  /// **'{correct} correct · {wrong} wrong'**
  String vocabQuizCorrectWrongLine(int correct, int wrong);

  /// No description provided for @vocabQuizViewMistakes.
  ///
  /// In en, this message translates to:
  /// **'View mistakes'**
  String get vocabQuizViewMistakes;

  /// No description provided for @vocabQuizMistakesTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong answers'**
  String get vocabQuizMistakesTitle;

  /// No description provided for @vocabQuizMistakesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No wrong answers in this session.'**
  String get vocabQuizMistakesEmpty;

  /// No description provided for @teacherPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher panel'**
  String get teacherPanelTitle;

  /// No description provided for @teacherPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your students\' vocabulary & grammar practice and class sessions.'**
  String get teacherPanelSubtitle;

  /// No description provided for @teacherOpenPanel.
  ///
  /// In en, this message translates to:
  /// **'Teacher panel'**
  String get teacherOpenPanel;

  /// No description provided for @teacherStudentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No students linked yet. On the server, create student codes tied to your teacher account — learners who register with those codes appear here.'**
  String get teacherStudentsEmpty;

  /// No description provided for @teacherPanelTabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get teacherPanelTabStudents;

  /// No description provided for @teacherPanelTabSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get teacherPanelTabSchedule;

  /// No description provided for @teacherPanelTabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get teacherPanelTabMessages;

  /// No description provided for @teacherScheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the next 7 days. Add weekly class times under each student (Weekly schedule tab), or every upcoming slot was already logged under Class sessions.'**
  String get teacherScheduleEmpty;

  /// No description provided for @teacherScheduleTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days from each student\'s Weekly schedule. When you log the matching session under Class sessions, it disappears here.'**
  String get teacherScheduleTabSubtitle;

  /// No description provided for @sessionDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sessionDayToday;

  /// No description provided for @sessionDayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get sessionDayTomorrow;

  /// No description provided for @teacherStudentDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get teacherStudentDetailTitle;

  /// No description provided for @teacherTabVocabQuiz.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get teacherTabVocabQuiz;

  /// No description provided for @teacherTabGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get teacherTabGrammar;

  /// No description provided for @teacherTabClassSessions.
  ///
  /// In en, this message translates to:
  /// **'Class sessions'**
  String get teacherTabClassSessions;

  /// No description provided for @teacherTabWeeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get teacherTabWeeklySchedule;

  /// No description provided for @teacherClassScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set which weekdays and times this student has class. Learners see this list as read-only.'**
  String get teacherClassScheduleSubtitle;

  /// No description provided for @teacherClassScheduleAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add time slot'**
  String get teacherClassScheduleAddButton;

  /// No description provided for @teacherClassScheduleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit time slot'**
  String get teacherClassScheduleEditTitle;

  /// No description provided for @classScheduleWeekdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get classScheduleWeekdayLabel;

  /// No description provided for @classScheduleStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get classScheduleStartLabel;

  /// No description provided for @classScheduleEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get classScheduleEndLabel;

  /// No description provided for @classScheduleIncludeEnd.
  ///
  /// In en, this message translates to:
  /// **'Include end time'**
  String get classScheduleIncludeEnd;

  /// No description provided for @classScheduleHasEndSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — leave off for a single start time.'**
  String get classScheduleHasEndSubtitle;

  /// No description provided for @classScheduleLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get classScheduleLabelHint;

  /// No description provided for @classScheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weekly times set yet.'**
  String get classScheduleEmpty;

  /// No description provided for @classScheduleSlotAdded.
  ///
  /// In en, this message translates to:
  /// **'Time slot added'**
  String get classScheduleSlotAdded;

  /// No description provided for @classScheduleSlotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Time slot updated'**
  String get classScheduleSlotUpdated;

  /// No description provided for @classScheduleSlotDeleted.
  ///
  /// In en, this message translates to:
  /// **'Time slot removed'**
  String get classScheduleSlotDeleted;

  /// No description provided for @classScheduleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get classScheduleRemove;

  /// No description provided for @classScheduleDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this time slot?'**
  String get classScheduleDeleteConfirmTitle;

  /// No description provided for @classScheduleDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get classScheduleDeleteConfirmBody;

  /// No description provided for @classScheduleInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get classScheduleInvalidRange;

  /// No description provided for @teacherTemporaryClassAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add temporary class'**
  String get teacherTemporaryClassAddButton;

  /// No description provided for @teacherTemporaryClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary class'**
  String get teacherTemporaryClassTitle;

  /// No description provided for @teacherTemporaryClassStudentLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get teacherTemporaryClassStudentLabel;

  /// No description provided for @teacherTemporaryClassSaved.
  ///
  /// In en, this message translates to:
  /// **'Temporary class added'**
  String get teacherTemporaryClassSaved;

  /// No description provided for @teacherTemporaryClassUpdated.
  ///
  /// In en, this message translates to:
  /// **'Temporary class updated'**
  String get teacherTemporaryClassUpdated;

  /// No description provided for @teacherTemporaryClassDeleted.
  ///
  /// In en, this message translates to:
  /// **'Temporary class removed'**
  String get teacherTemporaryClassDeleted;

  /// No description provided for @teacherTemporaryClassBadge.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get teacherTemporaryClassBadge;

  /// No description provided for @teacherTemporaryClassDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this temporary class?'**
  String get teacherTemporaryClassDeleteConfirmTitle;

  /// No description provided for @teacherTemporaryClassDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This one-off schedule item will be removed.'**
  String get teacherTemporaryClassDeleteConfirmBody;

  /// No description provided for @teacherTemporaryClassNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students available.'**
  String get teacherTemporaryClassNoStudents;

  /// No description provided for @teacherTemporaryClassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a student, date, and time for a one-hour class.'**
  String get teacherTemporaryClassSubtitle;

  /// No description provided for @teacherScheduleModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get teacherScheduleModeAuto;

  /// No description provided for @teacherScheduleModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get teacherScheduleModeManual;

  /// No description provided for @teacherScheduleDidClassHappen.
  ///
  /// In en, this message translates to:
  /// **'Was this class held?'**
  String get teacherScheduleDidClassHappen;

  /// No description provided for @teacherScheduleYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get teacherScheduleYes;

  /// No description provided for @teacherScheduleNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get teacherScheduleNo;

  /// No description provided for @teacherScheduleClassSkipped.
  ///
  /// In en, this message translates to:
  /// **'Class skipped'**
  String get teacherScheduleClassSkipped;

  /// No description provided for @youClassScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring class days and times from your teacher'**
  String get youClassScheduleSubtitle;

  /// No description provided for @teacherClassSessionsTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add sessions with one tap, adjust date and time when needed, or remove an entry. Students see this list in read-only form.'**
  String get teacherClassSessionsTabSubtitle;

  /// No description provided for @teacherClassSessionHeading.
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String teacherClassSessionHeading(int number);

  /// No description provided for @teacherClassSessionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get teacherClassSessionEdit;

  /// No description provided for @teacherClassSessionDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teacherClassSessionDelete;

  /// No description provided for @teacherClassSessionDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this session?'**
  String get teacherClassSessionDeleteConfirmTitle;

  /// No description provided for @teacherClassSessionDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get teacherClassSessionDeleteConfirmBody;

  /// No description provided for @teacherClassSessionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Session removed'**
  String get teacherClassSessionDeleted;

  /// No description provided for @teacherClassSessionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get teacherClassSessionEditTitle;

  /// No description provided for @teacherClassSessionAdded.
  ///
  /// In en, this message translates to:
  /// **'Session added'**
  String get teacherClassSessionAdded;

  /// No description provided for @teacherClassSessions.
  ///
  /// In en, this message translates to:
  /// **'Class sessions'**
  String get teacherClassSessions;

  /// No description provided for @teacherClassSessionAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a class session'**
  String get teacherClassSessionAddTooltip;

  /// No description provided for @teacherClassSessionsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add session'**
  String get teacherClassSessionsAddButton;

  /// No description provided for @teacherClassSessionDateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get teacherClassSessionDateFieldLabel;

  /// No description provided for @teacherClassSessionTimeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get teacherClassSessionTimeFieldLabel;

  /// No description provided for @youClassSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Class sessions'**
  String get youClassSessionsTitle;

  /// No description provided for @youClassSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions your teacher records in your profile'**
  String get youClassSessionsSubtitle;

  /// No description provided for @youClassSessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions recorded yet.'**
  String get youClassSessionsEmpty;

  /// No description provided for @studentPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Your class'**
  String get studentPanelTitle;

  /// No description provided for @studentPanelFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open class panel'**
  String get studentPanelFabTooltip;

  /// No description provided for @myPanelFab.
  ///
  /// In en, this message translates to:
  /// **'My pannel'**
  String get myPanelFab;

  /// No description provided for @studentPanelHeadline.
  ///
  /// In en, this message translates to:
  /// **'Teacher, sessions, and messages in one place.'**
  String get studentPanelHeadline;

  /// No description provided for @studentPanelStatUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get studentPanelStatUnread;

  /// No description provided for @teacherClassSessionsHintEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap + to record each class session. The time is saved automatically.'**
  String get teacherClassSessionsHintEmpty;

  /// No description provided for @teacherClassSessionsTabSubtitleTerms.
  ///
  /// In en, this message translates to:
  /// **'Create terms and set how many sessions each term allows. Log sessions under the matching term; students see the same grouping.'**
  String get teacherClassSessionsTabSubtitleTerms;

  /// No description provided for @teacherClassTermsSection.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get teacherClassTermsSection;

  /// No description provided for @teacherClassTermTitle.
  ///
  /// In en, this message translates to:
  /// **'Term {number}'**
  String teacherClassTermTitle(int number);

  /// No description provided for @teacherClassTermSessionsProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} sessions'**
  String teacherClassTermSessionsProgress(int current, int max);

  /// No description provided for @teacherClassTermsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add term'**
  String get teacherClassTermsAddButton;

  /// No description provided for @teacherClassTermsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a term first, set its session limit, then log class sessions under that term.'**
  String get teacherClassTermsEmptyHint;

  /// No description provided for @teacherClassTermEditCapTitle.
  ///
  /// In en, this message translates to:
  /// **'Session limit'**
  String get teacherClassTermEditCapTitle;

  /// No description provided for @teacherClassTermCapFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Max sessions in this term'**
  String get teacherClassTermCapFieldLabel;

  /// No description provided for @teacherClassTermDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this term?'**
  String get teacherClassTermDeleteConfirmTitle;

  /// No description provided for @teacherClassTermDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every class session recorded in this term will be removed. This cannot be undone.'**
  String get teacherClassTermDeleteConfirmBody;

  /// No description provided for @teacherClassTermAdded.
  ///
  /// In en, this message translates to:
  /// **'Term added'**
  String get teacherClassTermAdded;

  /// No description provided for @teacherClassTermUpdated.
  ///
  /// In en, this message translates to:
  /// **'Term updated'**
  String get teacherClassTermUpdated;

  /// No description provided for @teacherClassTermDeleted.
  ///
  /// In en, this message translates to:
  /// **'Term removed'**
  String get teacherClassTermDeleted;

  /// No description provided for @teacherClassTermAddSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Log session'**
  String get teacherClassTermAddSessionButton;

  /// No description provided for @classTermPaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get classTermPaymentPaid;

  /// No description provided for @classTermPaymentUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get classTermPaymentUnpaid;

  /// No description provided for @classTermPaymentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment status updated'**
  String get classTermPaymentUpdated;

  /// No description provided for @teacherPanelTabFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get teacherPanelTabFinance;

  /// No description provided for @teacherSessionPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Default term fee'**
  String get teacherSessionPriceTitle;

  /// No description provided for @teacherSessionPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get teacherSessionPriceHint;

  /// No description provided for @teacherSessionPriceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit default'**
  String get teacherSessionPriceEdit;

  /// No description provided for @teacherSessionPriceFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee for this term'**
  String get teacherSessionPriceFieldLabel;

  /// No description provided for @teacherSessionPriceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Term fee updated'**
  String get teacherSessionPriceUpdated;

  /// No description provided for @teacherTermFeeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit term fee'**
  String get teacherTermFeeEdit;

  /// No description provided for @teacherTermFeeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Term fee saved'**
  String get teacherTermFeeUpdated;

  /// No description provided for @teacherTotalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total received'**
  String get teacherTotalReceived;

  /// No description provided for @teacherTotalUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Total unpaid'**
  String get teacherTotalUnpaid;

  /// No description provided for @teacherFinancePeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get teacherFinancePeriodToday;

  /// No description provided for @teacherFinancePeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get teacherFinancePeriodWeek;

  /// No description provided for @teacherFinancePeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get teacherFinancePeriodMonth;

  /// No description provided for @teacherFinancePeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get teacherFinancePeriodAll;

  /// No description provided for @teacherFinancePeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get teacherFinancePeriodCustom;

  /// No description provided for @teacherFinanceFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teacherFinanceFilterAll;

  /// No description provided for @teacherFinanceFilterPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get teacherFinanceFilterPaid;

  /// No description provided for @teacherFinanceFilterUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get teacherFinanceFilterUnpaid;

  /// No description provided for @teacherFinanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No financial activity in this period'**
  String get teacherFinanceEmpty;

  /// No description provided for @teacherFinanceBreakdownStudents.
  ///
  /// In en, this message translates to:
  /// **'By student'**
  String get teacherFinanceBreakdownStudents;

  /// No description provided for @teacherTermAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Term amount'**
  String get teacherTermAmountLabel;

  /// No description provided for @teacherTermSessionsAndAmount.
  ///
  /// In en, this message translates to:
  /// **'{sessions} · {amount}'**
  String teacherTermSessionsAndAmount(String sessions, String amount);

  /// No description provided for @teacherFinanceStudentUnpaidBadge.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get teacherFinanceStudentUnpaidBadge;

  /// No description provided for @teacherFinancePriceNotSet.
  ///
  /// In en, this message translates to:
  /// **'Price not set'**
  String get teacherFinancePriceNotSet;

  /// No description provided for @teacherFinanceTermMarkedUnpaid.
  ///
  /// In en, this message translates to:
  /// **'A session was added — this term is now unpaid'**
  String get teacherFinanceTermMarkedUnpaid;

  /// No description provided for @financialCurrencyIrr.
  ///
  /// In en, this message translates to:
  /// **'Toman'**
  String get financialCurrencyIrr;

  /// No description provided for @financialCurrencyUsd.
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get financialCurrencyUsd;

  /// No description provided for @teacherFinanceSelectDates.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get teacherFinanceSelectDates;

  /// No description provided for @teacherFinanceFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get teacherFinanceFromDate;

  /// No description provided for @teacherFinanceToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get teacherFinanceToDate;

  /// No description provided for @teacherFinanceApplyRange.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get teacherFinanceApplyRange;

  /// No description provided for @teacherFinancePricingSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set session price here'**
  String get teacherFinancePricingSetupTitle;

  /// No description provided for @teacherFinancePricingSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Edit price and enter the cost per class session. Term totals = sessions × price. If Edit fails, run teacher_student_pricing_migration.sql on the server.'**
  String get teacherFinancePricingSetupBody;

  /// No description provided for @teacherFinancePricingSetupShort.
  ///
  /// In en, this message translates to:
  /// **'Set a default fee below, then set each term\'s fee'**
  String get teacherFinancePricingSetupShort;

  /// No description provided for @teacherFinanceServerSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial tracking not active on server'**
  String get teacherFinanceServerSetupTitle;

  /// No description provided for @teacherFinanceServerSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your admin to run teacher_student_pricing_migration.sql and deploy the latest API files. Until then, session prices cannot be saved.'**
  String get teacherFinanceServerSetupBody;

  /// No description provided for @teacherSessionPriceSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Set a price per session to calculate term totals and finance reports.'**
  String get teacherSessionPriceSetupHint;

  /// No description provided for @teacherFinanceAllZeroHint.
  ///
  /// In en, this message translates to:
  /// **'All amounts are 0 because no session price is set yet. Open a student → Class sessions → Edit price.'**
  String get teacherFinanceAllZeroHint;

  /// No description provided for @teacherSessionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Recorded class sessions'**
  String get teacherSessionCountLabel;

  /// No description provided for @teacherSessionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get teacherSessionSave;

  /// No description provided for @teacherSessionSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get teacherSessionSaveNote;

  /// No description provided for @teacherSessionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get teacherSessionUpdated;

  /// No description provided for @teacherSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number (0 or more).'**
  String get teacherSessionInvalid;

  /// No description provided for @teacherAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Only teacher accounts can open this panel.'**
  String get teacherAccessDenied;

  /// No description provided for @teacherNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get teacherNoResults;

  /// No description provided for @teacherNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher note'**
  String get teacherNoteLabel;

  /// No description provided for @teacherNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Private notes about this student (only you can see this)'**
  String get teacherNotePlaceholder;

  /// No description provided for @bookQuizSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose units, how many questions, and whether to drill past mistakes.'**
  String get bookQuizSetupIntro;

  /// No description provided for @bookQuizWordPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Word pool'**
  String get bookQuizWordPoolTitle;

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

  /// No description provided for @goToAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Create account'**
  String get goToAuth;

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

  /// No description provided for @statsTabVocab.
  ///
  /// In en, this message translates to:
  /// **'Vocab'**
  String get statsTabVocab;

  /// No description provided for @statsTabGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get statsTabGrammar;

  /// No description provided for @statsTabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get statsTabProgress;

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

  /// No description provided for @grammarStudyPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Study material (PDF)'**
  String get grammarStudyPdfTooltip;

  /// No description provided for @grammarStudyPdfOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the study PDF.'**
  String get grammarStudyPdfOpenError;

  /// No description provided for @grammarStudyPdfOpenExternally.
  ///
  /// In en, this message translates to:
  /// **'Open externally'**
  String get grammarStudyPdfOpenExternally;

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

  /// No description provided for @passwordResetSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get passwordResetSendCode;

  /// No description provided for @passwordResetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your email'**
  String get passwordResetCodeSent;

  /// No description provided for @passwordResetSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code'**
  String get passwordResetSendFailed;

  /// No description provided for @passwordResetHelper.
  ///
  /// In en, this message translates to:
  /// **'If your email exists in our system, a code will be sent.'**
  String get passwordResetHelper;

  /// No description provided for @passwordResetCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get passwordResetCodeLabel;

  /// No description provided for @passwordResetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordResetNewPassword;

  /// No description provided for @passwordResetConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get passwordResetConfirmPassword;

  /// No description provided for @passwordResetChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordResetChangeButton;

  /// No description provided for @passwordResetInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get passwordResetInvalidCode;

  /// No description provided for @passwordResetPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordResetPasswordsMismatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change password. Please try again.'**
  String get passwordResetChangeFailed;

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
  /// **'This selection includes words you marked as important (synced when signed in).'**
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

  /// No description provided for @bookQuizSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get bookQuizSectionsTitle;

  /// No description provided for @bookQuizSectionsHint.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more sections per unit for the quiz.'**
  String get bookQuizSectionsHint;

  /// No description provided for @bookQuizSectionsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get bookQuizSectionsSelectAll;

  /// No description provided for @bookQuizSectionsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get bookQuizSectionsClear;

  /// No description provided for @bookQuizPickAtLeastOneSection.
  ///
  /// In en, this message translates to:
  /// **'Select at least one section in each chosen unit.'**
  String get bookQuizPickAtLeastOneSection;

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

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBio;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Write a short note about yourself'**
  String get profileBioHint;

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

  /// No description provided for @profilePasswordSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get profilePasswordSectionTitle;

  /// No description provided for @profilePasswordSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'For security, your password is stored as a hash on the server and cannot be shown. Use the fields below to type your current password and set a new one. You can tap the eye icon to show or hide what you type.'**
  String get profilePasswordSecurityNote;

  /// No description provided for @profileCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileCurrentPasswordLabel;

  /// No description provided for @profilePasswordTooLong.
  ///
  /// In en, this message translates to:
  /// **'Password must be at most 72 characters'**
  String get profilePasswordTooLong;

  /// No description provided for @profilePasswordSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'Choose a password that is different from your current one.'**
  String get profilePasswordSameAsCurrent;

  /// No description provided for @profileWrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get profileWrongCurrentPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

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
  /// **'Kurdi'**
  String get grammarExplanationTabCkb;

  /// No description provided for @translationLangKurdiTab.
  ///
  /// In en, this message translates to:
  /// **'Kurdi'**
  String get translationLangKurdiTab;

  /// No description provided for @grammarExplanationTabEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get grammarExplanationTabEn;

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

  /// No description provided for @grammarSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get grammarSortNewest;

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

  /// No description provided for @grammarCommunityQuizTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 grammar quiz completed} other{{count} grammar quizzes completed}}'**
  String grammarCommunityQuizTotal(int count);

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestUser;

  /// No description provided for @profileBioEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bio yet.'**
  String get profileBioEmpty;

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

  /// No description provided for @adminUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get adminUsersTitle;

  /// No description provided for @adminUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get adminUserManagement;

  /// No description provided for @adminSearchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email, name, or teacher…'**
  String get adminSearchUsersHint;

  /// No description provided for @adminStudentAccess.
  ///
  /// In en, this message translates to:
  /// **'Student account'**
  String get adminStudentAccess;

  /// No description provided for @adminTeacherAccess.
  ///
  /// In en, this message translates to:
  /// **'Teacher account'**
  String get adminTeacherAccess;

  /// No description provided for @adminAssignedTeacher.
  ///
  /// In en, this message translates to:
  /// **'Class teacher'**
  String get adminAssignedTeacher;

  /// No description provided for @adminNoTeacher.
  ///
  /// In en, this message translates to:
  /// **'No teacher'**
  String get adminNoTeacher;

  /// No description provided for @adminSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminSave;

  /// No description provided for @adminUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get adminUpdated;

  /// No description provided for @adminAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have admin access.'**
  String get adminAccessDenied;

  /// No description provided for @adminTeacherInvalid.
  ///
  /// In en, this message translates to:
  /// **'Pick a valid teacher account.'**
  String get adminTeacherInvalid;

  /// No description provided for @adminUserAppInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed: {version}'**
  String adminUserAppInstalled(String version);

  /// No description provided for @adminUserAppActive.
  ///
  /// In en, this message translates to:
  /// **'Latest release: {version}'**
  String adminUserAppActive(String version);

  /// No description provided for @adminUserAppVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not reported yet'**
  String get adminUserAppVersionUnknown;

  /// No description provided for @adminNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users returned from the server.'**
  String get adminNoUsers;

  /// No description provided for @adminNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No users match this search.'**
  String get adminNoSearchResults;

  /// No description provided for @adminRoleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get adminRoleTeacher;

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleAdmin;

  /// No description provided for @youSectionAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get youSectionAdmin;

  /// No description provided for @youAdminPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Student access, teachers, and accounts'**
  String get youAdminPanelSubtitle;

  /// No description provided for @adminScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search and tap a user to edit'**
  String get adminScreenSubtitle;

  /// No description provided for @wordBuilderClearPath.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wordBuilderClearPath;

  /// No description provided for @wordBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Builder'**
  String get wordBuilderTitle;

  /// No description provided for @wordBuilderShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle letters'**
  String get wordBuilderShuffle;

  /// No description provided for @wordBuilderPickSource.
  ///
  /// In en, this message translates to:
  /// **'Choose vocabulary'**
  String get wordBuilderPickSource;

  /// No description provided for @wordBuilderStartPlay.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get wordBuilderStartPlay;

  /// No description provided for @wordBuilderCatalogAll.
  ///
  /// In en, this message translates to:
  /// **'All books'**
  String get wordBuilderCatalogAll;

  /// No description provided for @wordBuilderNoWordsBody.
  ///
  /// In en, this message translates to:
  /// **'No suitable English words were found for this source. Pick another book or refresh.'**
  String get wordBuilderNoWordsBody;

  /// No description provided for @wordBuilderHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build English words from shuffled letters.'**
  String get wordBuilderHomeSubtitle;

  /// No description provided for @wordBuilderLevelOf.
  ///
  /// In en, this message translates to:
  /// **'Level {current} of {total}'**
  String wordBuilderLevelOf(int current, int total);

  /// No description provided for @wordBuilderCategory.
  ///
  /// In en, this message translates to:
  /// **'Topic: {name}'**
  String wordBuilderCategory(String name);

  /// No description provided for @wordBuilderDifficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get wordBuilderDifficultyBeginner;

  /// No description provided for @wordBuilderDifficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get wordBuilderDifficultyIntermediate;

  /// No description provided for @wordBuilderDifficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get wordBuilderDifficultyAdvanced;

  /// No description provided for @wordBuilderTierLockedIntermediateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Locked • finish Beginner first'**
  String get wordBuilderTierLockedIntermediateSubtitle;

  /// No description provided for @wordBuilderTierLockedAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Locked • finish Intermediate first'**
  String get wordBuilderTierLockedAdvancedSubtitle;

  /// No description provided for @wordBuilderTierLockedIntermediateMessage.
  ///
  /// In en, this message translates to:
  /// **'Finish all Beginner stages to unlock Intermediate.'**
  String get wordBuilderTierLockedIntermediateMessage;

  /// No description provided for @wordBuilderTierLockedAdvancedMessage.
  ///
  /// In en, this message translates to:
  /// **'Finish all Intermediate stages to unlock Advanced.'**
  String get wordBuilderTierLockedAdvancedMessage;

  /// No description provided for @wordBuilderYourWord.
  ///
  /// In en, this message translates to:
  /// **'Your word'**
  String get wordBuilderYourWord;

  /// No description provided for @wordBuilderLetters.
  ///
  /// In en, this message translates to:
  /// **'Letter pool'**
  String get wordBuilderLetters;

  /// No description provided for @wordBuilderSubmit.
  ///
  /// In en, this message translates to:
  /// **'Check word'**
  String get wordBuilderSubmit;

  /// No description provided for @wordBuilderReset.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wordBuilderReset;

  /// No description provided for @wordBuilderNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get wordBuilderNextLevel;

  /// No description provided for @wordBuilderHints.
  ///
  /// In en, this message translates to:
  /// **'Hints'**
  String get wordBuilderHints;

  /// No description provided for @wordBuilderHintReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal a letter'**
  String get wordBuilderHintReveal;

  /// No description provided for @wordBuilderHintRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove an extra letter'**
  String get wordBuilderHintRemove;

  /// No description provided for @wordBuilderHintMeaning.
  ///
  /// In en, this message translates to:
  /// **'Show a meaning'**
  String get wordBuilderHintMeaning;

  /// No description provided for @wordBuilderTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get wordBuilderTranslation;

  /// No description provided for @wordBuilderTooShort.
  ///
  /// In en, this message translates to:
  /// **'Pick more letters first.'**
  String get wordBuilderTooShort;

  /// No description provided for @wordBuilderAlreadyFound.
  ///
  /// In en, this message translates to:
  /// **'You already found that word.'**
  String get wordBuilderAlreadyFound;

  /// No description provided for @wordBuilderTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Not in this level — keep trying.'**
  String get wordBuilderTryAgain;

  /// No description provided for @wordBuilderCorrectNice.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get wordBuilderCorrectNice;

  /// No description provided for @wordBuilderTrainGameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'The train arrived!'**
  String get wordBuilderTrainGameOverTitle;

  /// No description provided for @wordBuilderTrainGameOverBody.
  ///
  /// In en, this message translates to:
  /// **'Time ran out before the last rope snapped. Try again and set them free!'**
  String get wordBuilderTrainGameOverBody;

  /// No description provided for @wordBuilderPrisonGameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Caught!'**
  String get wordBuilderPrisonGameOverTitle;

  /// No description provided for @wordBuilderPrisonGameOverBody.
  ///
  /// In en, this message translates to:
  /// **'The guard woke up and took the key back. Try again — carefully this time!'**
  String get wordBuilderPrisonGameOverBody;

  /// No description provided for @wordBuilderReplayLevel.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get wordBuilderReplayLevel;

  /// No description provided for @wordBuilderLevelCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Level complete!'**
  String get wordBuilderLevelCompleteTitle;

  /// No description provided for @wordBuilderLevelCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Great job. You found all the words in this stage.'**
  String get wordBuilderLevelCompleteBody;

  /// No description provided for @wordBuilderBeginnerCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Beginner complete!'**
  String get wordBuilderBeginnerCompleteTitle;

  /// No description provided for @wordBuilderBeginnerCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Amazing! Intermediate is unlocked. Ready for the next challenge?'**
  String get wordBuilderBeginnerCompleteBody;

  /// No description provided for @wordBuilderStartIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Start Intermediate'**
  String get wordBuilderStartIntermediate;

  /// No description provided for @wordBuilderIntermediateCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Intermediate complete!'**
  String get wordBuilderIntermediateCompleteTitle;

  /// No description provided for @wordBuilderIntermediateCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Fantastic work! Advanced is unlocked. Let’s raise the level.'**
  String get wordBuilderIntermediateCompleteBody;

  /// No description provided for @wordBuilderStartAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Start Advanced'**
  String get wordBuilderStartAdvanced;

  /// No description provided for @wordBuilderAdvancedCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'All sections complete!'**
  String get wordBuilderAdvancedCompleteTitle;

  /// No description provided for @wordBuilderAdvancedCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You finished the full Word Builder campaign. Brilliant work!'**
  String get wordBuilderAdvancedCompleteBody;

  /// No description provided for @wordBuilderHintLetter.
  ///
  /// In en, this message translates to:
  /// **'A letter was revealed in one of the words.'**
  String get wordBuilderHintLetter;

  /// No description provided for @wordBuilderHintRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed an extra letter from your word.'**
  String get wordBuilderHintRemoved;

  /// No description provided for @wordBuilderHintRemoveNone.
  ///
  /// In en, this message translates to:
  /// **'No extra letters to remove right now.'**
  String get wordBuilderHintRemoveNone;

  /// No description provided for @wordBuilderNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins. Solve words to earn more.'**
  String get wordBuilderNotEnoughCoins;

  /// No description provided for @wordBuilderCoinsCost.
  ///
  /// In en, this message translates to:
  /// **'Costs {coins} coins'**
  String wordBuilderCoinsCost(int coins);

  /// No description provided for @wordBuilderCoinsBalance.
  ///
  /// In en, this message translates to:
  /// **'{coins}'**
  String wordBuilderCoinsBalance(int coins);

  /// No description provided for @wordBuilderSessionSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get wordBuilderSessionSoundTitle;

  /// No description provided for @wordBuilderSessionBgmSwitch.
  ///
  /// In en, this message translates to:
  /// **'Background music'**
  String get wordBuilderSessionBgmSwitch;

  /// No description provided for @wordBuilderSessionBgmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plays while you solve words in this game.'**
  String get wordBuilderSessionBgmSubtitle;

  /// No description provided for @wordBuilderSessionSfxSwitch.
  ///
  /// In en, this message translates to:
  /// **'Game sounds'**
  String get wordBuilderSessionSfxSwitch;

  /// No description provided for @wordBuilderSessionSfxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Correct answers, mistakes, and level complete.'**
  String get wordBuilderSessionSfxSubtitle;

  /// No description provided for @wordBuilderSessionWaterSfxSwitch.
  ///
  /// In en, this message translates to:
  /// **'Water sounds'**
  String get wordBuilderSessionWaterSfxSwitch;

  /// No description provided for @wordBuilderSessionWaterSfxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pouring water, drowning tension, and tray effects when you make mistakes.'**
  String get wordBuilderSessionWaterSfxSubtitle;

  /// No description provided for @wordBuilderPlayModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Play mode'**
  String get wordBuilderPlayModeTitle;

  /// No description provided for @wordBuilderPlayModeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic Tray'**
  String get wordBuilderPlayModeClassic;

  /// No description provided for @wordBuilderPlayModeClassicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Circular letters with water, train, and prison scenes.'**
  String get wordBuilderPlayModeClassicSubtitle;

  /// No description provided for @wordBuilderPlayModeArkanoid.
  ///
  /// In en, this message translates to:
  /// **'Arkanoid'**
  String get wordBuilderPlayModeArkanoid;

  /// No description provided for @wordBuilderPlayModeArkanoidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bounce the ball to hit letter bricks and build words.'**
  String get wordBuilderPlayModeArkanoidSubtitle;

  /// No description provided for @wordBuilderPlayModeAngryWords.
  ///
  /// In en, this message translates to:
  /// **'Angry Words'**
  String get wordBuilderPlayModeAngryWords;

  /// No description provided for @wordBuilderPlayModeAngryWordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aim the slingshot, follow the trajectory, and hit letters in order.'**
  String get wordBuilderPlayModeAngryWordsSubtitle;

  /// No description provided for @wordBuilderPlayModePuzzle.
  ///
  /// In en, this message translates to:
  /// **'Letter Puzzle'**
  String get wordBuilderPlayModePuzzle;

  /// No description provided for @wordBuilderPlayModePuzzleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Slide letter tiles on a checkerboard grid to build words.'**
  String get wordBuilderPlayModePuzzleSubtitle;

  /// No description provided for @wordBuilderPuzzleSlideHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a letter next to the empty cell to slide it into your word.'**
  String get wordBuilderPuzzleSlideHint;

  /// No description provided for @wordBuilderAngryWordsAimHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a letter to focus · drag to bump · pull empty space to shoot'**
  String get wordBuilderAngryWordsAimHint;

  /// No description provided for @wordBuilderAngryWordsWindHint.
  ///
  /// In en, this message translates to:
  /// **'Hold the wind button, or aim the slingshot at it — letters drift faster'**
  String get wordBuilderAngryWordsWindHint;

  /// No description provided for @wordBuilderArkanoidCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get wordBuilderArkanoidCheck;

  /// No description provided for @wordBuilderArkanoidServeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag paddle · tap to serve'**
  String get wordBuilderArkanoidServeHint;

  /// No description provided for @wordBuilderArkanoidBallSpeed.
  ///
  /// In en, this message translates to:
  /// **'Ball speed'**
  String get wordBuilderArkanoidBallSpeed;

  /// No description provided for @wordBuilderArkanoidBallSpeedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get wordBuilderArkanoidBallSpeedSlow;

  /// No description provided for @wordBuilderArkanoidBallSpeedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get wordBuilderArkanoidBallSpeedNormal;

  /// No description provided for @wordBuilderArkanoidBallSpeedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get wordBuilderArkanoidBallSpeedFast;

  /// No description provided for @wordBuilderPlayModeSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how you pick letters. Classic keeps tray stories; Puzzle uses a sliding tile grid.'**
  String get wordBuilderPlayModeSwitchHint;

  /// No description provided for @wordBuilderHintMeaningLine.
  ///
  /// In en, this message translates to:
  /// **'Hint: {meaning}'**
  String wordBuilderHintMeaningLine(String meaning);

  /// No description provided for @wordBuilderAllLevelsDone.
  ///
  /// In en, this message translates to:
  /// **'You finished all levels in this session.'**
  String get wordBuilderAllLevelsDone;

  /// No description provided for @wordBuilderTotalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP: {xp}'**
  String wordBuilderTotalXp(int xp);

  /// No description provided for @wordBuilderAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {pct}%'**
  String wordBuilderAccuracy(int pct);

  /// No description provided for @wordBuilderPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get wordBuilderPronunciation;

  /// No description provided for @wordBuilderMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get wordBuilderMeaning;

  /// No description provided for @wordBuilderExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get wordBuilderExample;

  /// No description provided for @wordBuilderSpeakWord.
  ///
  /// In en, this message translates to:
  /// **'Speak word'**
  String get wordBuilderSpeakWord;

  /// No description provided for @wordBuilderSpeakExample.
  ///
  /// In en, this message translates to:
  /// **'Speak example'**
  String get wordBuilderSpeakExample;

  /// No description provided for @wordBuilderTargetsHeading.
  ///
  /// In en, this message translates to:
  /// **'Words to find'**
  String get wordBuilderTargetsHeading;

  /// No description provided for @wordBuilderCampaignHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **''**
  String get wordBuilderCampaignHubSubtitle;

  /// No description provided for @wordBuilderCampaignStagesHint.
  ///
  /// In en, this message translates to:
  /// **''**
  String get wordBuilderCampaignStagesHint;

  /// No description provided for @wordBuilderCampaignStageLockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Finish the previous stage first.'**
  String get wordBuilderCampaignStageLockedSnackbar;

  /// No description provided for @wordBuilderCampaignTierLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Complete all 50 stages in the previous difficulty to unlock this track.'**
  String get wordBuilderCampaignTierLockedBody;

  /// No description provided for @wordBuilderCampaignPlanError.
  ///
  /// In en, this message translates to:
  /// **'Not enough vocabulary to build this stage. Try refreshing books later.'**
  String get wordBuilderCampaignPlanError;

  /// No description provided for @wordBuilderCampaignReset.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get wordBuilderCampaignReset;

  /// No description provided for @wordBuilderCampaignResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all Word Builder stage progress? This cannot be undone.'**
  String get wordBuilderCampaignResetConfirm;

  /// No description provided for @wordBuilderCampaignResetDone.
  ///
  /// In en, this message translates to:
  /// **'Campaign progress cleared.'**
  String get wordBuilderCampaignResetDone;

  /// No description provided for @wordBuilderCampaignStageOf.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} of {total}'**
  String wordBuilderCampaignStageOf(int stage, int total);

  /// No description provided for @wordBuilderCampaignStageN.
  ///
  /// In en, this message translates to:
  /// **'Stage {n}'**
  String wordBuilderCampaignStageN(int n);

  /// No description provided for @wordBuilderCampaignStageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get wordBuilderCampaignStageCompleted;

  /// No description provided for @wordBuilderCampaignStageReplayHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to replay this stage'**
  String get wordBuilderCampaignStageReplayHint;

  /// No description provided for @wordBuilderCategoryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a topic'**
  String get wordBuilderCategoryPickerTitle;

  /// No description provided for @wordBuilderCategoryPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play by theme, or start the regular campaign.'**
  String get wordBuilderCategoryPickerSubtitle;

  /// No description provided for @wordBuilderCategorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search topics'**
  String get wordBuilderCategorySearchHint;

  /// No description provided for @wordBuilderNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get wordBuilderNormalTitle;

  /// No description provided for @wordBuilderNormalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'IELTS campaign with all difficulty levels'**
  String get wordBuilderNormalSubtitle;

  /// No description provided for @wordBuilderCategorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get wordBuilderCategorySectionTitle;

  /// No description provided for @wordBuilderCategoryEmptyResults.
  ///
  /// In en, this message translates to:
  /// **'No topics match your search.'**
  String get wordBuilderCategoryEmptyResults;

  /// No description provided for @wordBuilderCategoryNoWordsYet.
  ///
  /// In en, this message translates to:
  /// **'No words in this topic yet.'**
  String get wordBuilderCategoryNoWordsYet;

  /// No description provided for @wordBuilderCategoryTopicsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Topics could not be loaded. Pull down to refresh.'**
  String get wordBuilderCategoryTopicsLoadFailed;

  /// No description provided for @adminEditUserSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit access'**
  String get adminEditUserSheetTitle;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @noWordsForSection.
  ///
  /// In en, this message translates to:
  /// **'No words for this section.'**
  String get noWordsForSection;

  /// No description provided for @noFavoriteWordsYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite words yet.'**
  String get noFavoriteWordsYet;

  /// No description provided for @tapCardToRevealAndRate.
  ///
  /// In en, this message translates to:
  /// **'Tap card to reveal answer & rate'**
  String get tapCardToRevealAndRate;

  /// No description provided for @tapToFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap to flip'**
  String get tapToFlip;

  /// No description provided for @flashcardCardProgress.
  ///
  /// In en, this message translates to:
  /// **'Card {current} of {total}'**
  String flashcardCardProgress(int current, int total);

  /// No description provided for @flashcardMeaningLabel.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get flashcardMeaningLabel;

  /// No description provided for @flashcardWordLabel.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get flashcardWordLabel;

  /// No description provided for @allCardsReviewed.
  ///
  /// In en, this message translates to:
  /// **'All cards reviewed!'**
  String get allCardsReviewed;

  /// No description provided for @flashcardBadgeImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get flashcardBadgeImportant;

  /// No description provided for @flashcardBadgeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get flashcardBadgeFavorite;

  /// No description provided for @flashcardResumedHint.
  ///
  /// In en, this message translates to:
  /// **'Resumed session'**
  String get flashcardResumedHint;

  /// No description provided for @flashcardRatingAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get flashcardRatingAgain;

  /// No description provided for @flashcardRatingHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get flashcardRatingHard;

  /// No description provided for @flashcardRatingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get flashcardRatingGood;

  /// No description provided for @flashcardRatingEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get flashcardRatingEasy;

  /// No description provided for @flashcardSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get flashcardSetupTitle;

  /// No description provided for @flashcardSetupDeck.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get flashcardSetupDeck;

  /// No description provided for @flashcardSetupPoolAll.
  ///
  /// In en, this message translates to:
  /// **'All words'**
  String get flashcardSetupPoolAll;

  /// No description provided for @flashcardSetupPoolImportant.
  ///
  /// In en, this message translates to:
  /// **'Important only'**
  String get flashcardSetupPoolImportant;

  /// No description provided for @flashcardSetupPoolFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get flashcardSetupPoolFavorites;

  /// No description provided for @flashcardSetupOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get flashcardSetupOrder;

  /// No description provided for @flashcardSetupShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle cards'**
  String get flashcardSetupShuffle;

  /// No description provided for @flashcardSetupDirection.
  ///
  /// In en, this message translates to:
  /// **'Card direction'**
  String get flashcardSetupDirection;

  /// No description provided for @flashcardSetupDirectionWordToMeaning.
  ///
  /// In en, this message translates to:
  /// **'Word → Meaning'**
  String get flashcardSetupDirectionWordToMeaning;

  /// No description provided for @flashcardSetupDirectionMeaningToWord.
  ///
  /// In en, this message translates to:
  /// **'Meaning → Word'**
  String get flashcardSetupDirectionMeaningToWord;

  /// No description provided for @flashcardSetupOptions.
  ///
  /// In en, this message translates to:
  /// **'Study options'**
  String get flashcardSetupOptions;

  /// No description provided for @flashcardSetupSrs.
  ///
  /// In en, this message translates to:
  /// **'Ratings feed your daily review queue.'**
  String get flashcardSetupSrs;

  /// No description provided for @flashcardSetupSrsToggle.
  ///
  /// In en, this message translates to:
  /// **'Ratings affect daily review'**
  String get flashcardSetupSrsToggle;

  /// No description provided for @flashcardSetupSwipeRatings.
  ///
  /// In en, this message translates to:
  /// **'Swipe to rate'**
  String get flashcardSetupSwipeRatings;

  /// No description provided for @flashcardSetupStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get flashcardSetupStart;

  /// No description provided for @flashcardSetupUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit}'**
  String flashcardSetupUnitTitle(int unit);

  /// No description provided for @flashcardSetupUnitSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · Section {section}'**
  String flashcardSetupUnitSectionTitle(int unit, int section);

  /// No description provided for @flashcardSetupResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume session'**
  String get flashcardSetupResumeTitle;

  /// No description provided for @flashcardSetupResumeBody.
  ///
  /// In en, this message translates to:
  /// **'You were on card {current} of {total}. Continue where you left off, or start fresh.'**
  String flashcardSetupResumeBody(int current, int total);

  /// No description provided for @flashcardSetupResumeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get flashcardSetupResumeContinue;

  /// No description provided for @flashcardSetupResumeFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get flashcardSetupResumeFresh;

  /// No description provided for @flashcardImportantEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No important words yet'**
  String get flashcardImportantEmptyTitle;

  /// No description provided for @flashcardImportantEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Mark words as important on word cards to study them here.'**
  String get flashcardImportantEmptyBody;

  /// No description provided for @flashcardImportantEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Go to words'**
  String get flashcardImportantEmptyAction;

  /// No description provided for @flashcardFavoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorite words yet'**
  String get flashcardFavoritesEmptyTitle;

  /// No description provided for @flashcardFavoritesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Mark words as favorite on word cards to study them here.'**
  String get flashcardFavoritesEmptyBody;

  /// No description provided for @flashcardFavoritesEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Go to words'**
  String get flashcardFavoritesEmptyAction;

  /// No description provided for @flashcardNoWordsTitle.
  ///
  /// In en, this message translates to:
  /// **'No words to study'**
  String get flashcardNoWordsTitle;

  /// No description provided for @flashcardNoWordsBody.
  ///
  /// In en, this message translates to:
  /// **'There are no words for this unit or section.'**
  String get flashcardNoWordsBody;

  /// No description provided for @flashcardSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get flashcardSessionComplete;

  /// No description provided for @flashcardSessionCardsReviewed.
  ///
  /// In en, this message translates to:
  /// **'{count} cards reviewed'**
  String flashcardSessionCardsReviewed(int count);

  /// No description provided for @flashcardSessionDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String flashcardSessionDuration(int minutes, int seconds);

  /// No description provided for @flashcardSessionReviewAgain.
  ///
  /// In en, this message translates to:
  /// **'Review again ({count})'**
  String flashcardSessionReviewAgain(int count);

  /// No description provided for @flashcardSessionRestart.
  ///
  /// In en, this message translates to:
  /// **'Study again'**
  String get flashcardSessionRestart;

  /// No description provided for @flashcardSessionBackToWords.
  ///
  /// In en, this message translates to:
  /// **'Back to words'**
  String get flashcardSessionBackToWords;

  /// No description provided for @flashcardSummaryReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get flashcardSummaryReviewed;

  /// No description provided for @flashcardSummaryMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get flashcardSummaryMastered;

  /// No description provided for @flashcardSummaryToReview.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get flashcardSummaryToReview;

  /// No description provided for @couldNotLoadSectionsWithError.
  ///
  /// In en, this message translates to:
  /// **'Could not load sections.\n{error}'**
  String couldNotLoadSectionsWithError(String error);

  /// No description provided for @couldNotLoadUnitsWithError.
  ///
  /// In en, this message translates to:
  /// **'Could not load units.\n{error}'**
  String couldNotLoadUnitsWithError(String error);

  /// No description provided for @noUnitsFound.
  ///
  /// In en, this message translates to:
  /// **'No units found in this dataset.'**
  String get noUnitsFound;

  /// No description provided for @unitsGridHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit · tap a card to open} other{{count} units · tap a card to open}}'**
  String unitsGridHint(int count);

  /// No description provided for @checkingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingEllipsis;

  /// No description provided for @backToUnits.
  ///
  /// In en, this message translates to:
  /// **'Back to units'**
  String get backToUnits;

  /// No description provided for @englishMeaning.
  ///
  /// In en, this message translates to:
  /// **'English meaning'**
  String get englishMeaning;

  /// No description provided for @wordsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get wordsTabLabel;

  /// No description provided for @samplesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get samplesTabLabel;

  /// No description provided for @unitSectionLine.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · Section {section}'**
  String unitSectionLine(int unit, int section);

  /// No description provided for @sectionNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Section {section}'**
  String sectionNumberLabel(int section);

  /// No description provided for @grammarReviewQuestionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get grammarReviewQuestionsHeading;

  /// No description provided for @grammarNoPerQuestionData.
  ///
  /// In en, this message translates to:
  /// **'No per-question data was stored for this attempt (older results or server not migrated).'**
  String get grammarNoPerQuestionData;

  /// No description provided for @grammarReviewQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Q{index} · {topic}'**
  String grammarReviewQuestionTitle(int index, String topic);

  /// No description provided for @answerCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get answerCorrect;

  /// No description provided for @answerIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get answerIncorrect;

  /// No description provided for @statsQuizCorrectFraction.
  ///
  /// In en, this message translates to:
  /// **'{correct} / {answered} correct'**
  String statsQuizCorrectFraction(int correct, int answered);

  /// No description provided for @statsAccuracyPercent.
  ///
  /// In en, this message translates to:
  /// **'{pct}% accuracy'**
  String statsAccuracyPercent(String pct);

  /// No description provided for @unitSamplesLoadingCatalog.
  ///
  /// In en, this message translates to:
  /// **'Loading vocabulary…'**
  String get unitSamplesLoadingCatalog;

  /// No description provided for @unitSamplesTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get unitSamplesTextSize;

  /// No description provided for @profilePresetBoy1.
  ///
  /// In en, this message translates to:
  /// **'Boy 1'**
  String get profilePresetBoy1;

  /// No description provided for @profilePresetBoy2.
  ///
  /// In en, this message translates to:
  /// **'Boy 2'**
  String get profilePresetBoy2;

  /// No description provided for @profilePresetBoy3.
  ///
  /// In en, this message translates to:
  /// **'Boy 3'**
  String get profilePresetBoy3;

  /// No description provided for @profilePresetBoy4.
  ///
  /// In en, this message translates to:
  /// **'Boy 4'**
  String get profilePresetBoy4;

  /// No description provided for @profilePresetGirl1.
  ///
  /// In en, this message translates to:
  /// **'Girl 1'**
  String get profilePresetGirl1;

  /// No description provided for @profilePresetGirl2.
  ///
  /// In en, this message translates to:
  /// **'Girl 2'**
  String get profilePresetGirl2;

  /// No description provided for @profilePresetGirl3.
  ///
  /// In en, this message translates to:
  /// **'Girl 3'**
  String get profilePresetGirl3;

  /// No description provided for @profilePresetGirl4.
  ///
  /// In en, this message translates to:
  /// **'Girl 4'**
  String get profilePresetGirl4;

  /// No description provided for @unitSampleUntitled.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get unitSampleUntitled;

  /// No description provided for @sampleBookMode.
  ///
  /// In en, this message translates to:
  /// **'Book mode'**
  String get sampleBookMode;

  /// No description provided for @sampleBookPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String sampleBookPageOf(int current, int total);

  /// No description provided for @sampleBookTurnHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe or tap the sides to turn pages'**
  String get sampleBookTurnHint;

  /// No description provided for @sampleBookPageSoundOn.
  ///
  /// In en, this message translates to:
  /// **'Page turn sound on'**
  String get sampleBookPageSoundOn;

  /// No description provided for @sampleBookPageSoundOff.
  ///
  /// In en, this message translates to:
  /// **'Page turn sound off'**
  String get sampleBookPageSoundOff;

  /// No description provided for @sampleHighlightPickMainColor.
  ///
  /// In en, this message translates to:
  /// **'Highlight color'**
  String get sampleHighlightPickMainColor;

  /// No description provided for @sampleHighlightTapColor.
  ///
  /// In en, this message translates to:
  /// **'Tap a color to highlight'**
  String get sampleHighlightTapColor;

  /// No description provided for @sampleHighlightRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove highlight'**
  String get sampleHighlightRemove;

  /// No description provided for @sampleHighlightDefaultColor.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get sampleHighlightDefaultColor;

  /// No description provided for @samplePlayFullText.
  ///
  /// In en, this message translates to:
  /// **'Play sample'**
  String get samplePlayFullText;

  /// No description provided for @samplePauseFullText.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get samplePauseFullText;

  /// No description provided for @sampleTtsNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Reading sample text'**
  String get sampleTtsNowPlaying;

  /// No description provided for @sampleTtsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get sampleTtsStop;

  /// No description provided for @sampleTtsRewind5.
  ///
  /// In en, this message translates to:
  /// **'Back 5 seconds'**
  String get sampleTtsRewind5;

  /// No description provided for @sampleTtsForward5.
  ///
  /// In en, this message translates to:
  /// **'Forward 5 seconds'**
  String get sampleTtsForward5;

  /// No description provided for @sampleTtsHighlight.
  ///
  /// In en, this message translates to:
  /// **'Karaoke highlight'**
  String get sampleTtsHighlight;

  /// No description provided for @sampleTtsSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get sampleTtsSpeed;

  /// No description provided for @sampleTtsSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'{speed}×'**
  String sampleTtsSpeedLabel(String speed);

  /// No description provided for @sampleTtsEngine.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get sampleTtsEngine;

  /// No description provided for @sampleTtsEngineSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get sampleTtsEngineSystem;

  /// No description provided for @sampleTtsEngineGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get sampleTtsEngineGoogle;
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
