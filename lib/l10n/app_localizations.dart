import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @error_tts.
  ///
  /// In en, this message translates to:
  /// **'Error initializing TTS'**
  String get error_tts;

  /// No description provided for @error_ocr.
  ///
  /// In en, this message translates to:
  /// **'Error processing OCR'**
  String get error_ocr;

  /// No description provided for @error_translation.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while translating, error log: {log}'**
  String error_translation(Object log);

  /// No description provided for @main_hint.
  ///
  /// In en, this message translates to:
  /// **'Write something or press \"Generate\"...'**
  String get main_hint;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @generate_translation.
  ///
  /// In en, this message translates to:
  /// **'Generate Translation'**
  String get generate_translation;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @dictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictionary;

  /// No description provided for @no_words.
  ///
  /// In en, this message translates to:
  /// **'No words stored in dictionary'**
  String get no_words;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto detect'**
  String get auto;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get en;

  /// No description provided for @es.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get es;

  /// No description provided for @zh.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get zh;

  /// No description provided for @ja.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get ja;

  /// No description provided for @ko.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get ko;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @detected_words.
  ///
  /// In en, this message translates to:
  /// **'Detected words:'**
  String get detected_words;

  /// No description provided for @tap_to_stop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get tap_to_stop;

  /// No description provided for @repeat_this_phrase.
  ///
  /// In en, this message translates to:
  /// **'Repeat this phrase:'**
  String get repeat_this_phrase;

  /// No description provided for @error_function.
  ///
  /// In en, this message translates to:
  /// **'Error in function {fn} please report this to the developers: {msg}'**
  String error_function(Object fn, Object msg);

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listening;

  /// No description provided for @error_stt.
  ///
  /// In en, this message translates to:
  /// **'Error processing Speech To Text: {msg}'**
  String error_stt(Object msg);

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @feature_not_available.
  ///
  /// In en, this message translates to:
  /// **'Feature not available'**
  String get feature_not_available;

  /// No description provided for @feature_not_available_windows.
  ///
  /// In en, this message translates to:
  /// **'This feature is not available on Windows'**
  String get feature_not_available_windows;

  /// No description provided for @missing_language.
  ///
  /// In en, this message translates to:
  /// **'Missing language voice pack: {lang}'**
  String missing_language(Object lang);

  /// No description provided for @language_not_installed.
  ///
  /// In en, this message translates to:
  /// **'You do not have the {lang} language voice pack installed'**
  String language_not_installed(Object lang);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get search;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @no_mic_input.
  ///
  /// In en, this message translates to:
  /// **'No microphone input detected'**
  String get no_mic_input;

  /// No description provided for @no_match.
  ///
  /// In en, this message translates to:
  /// **'No words match in {lang} language'**
  String no_match(String lang);

  /// No description provided for @not_allowed.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get not_allowed;

  /// No description provided for @unsupported_browser.
  ///
  /// In en, this message translates to:
  /// **'Unsupported browser'**
  String get unsupported_browser;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @generate_for_practice.
  ///
  /// In en, this message translates to:
  /// **'Generate a phrase to start practicing'**
  String get generate_for_practice;

  /// No description provided for @frase.
  ///
  /// In en, this message translates to:
  /// **'Phrase'**
  String get frase;

  /// No description provided for @sujeto.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get sujeto;

  /// No description provided for @verbo.
  ///
  /// In en, this message translates to:
  /// **'Verb'**
  String get verbo;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @familia.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familia;

  /// No description provided for @adjetivo.
  ///
  /// In en, this message translates to:
  /// **'Adjective'**
  String get adjetivo;

  /// No description provided for @direccion.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get direccion;

  /// No description provided for @retraducir.
  ///
  /// In en, this message translates to:
  /// **'Retranslate'**
  String get retraducir;

  /// No description provided for @speechNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'You do not have the {lang} language voice pack installed'**
  String speechNotInstalled(Object lang);

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @ipaPName.
  ///
  /// In en, this message translates to:
  /// **'voiceless bilabial plosive'**
  String get ipaPName;

  /// No description provided for @ipaBName.
  ///
  /// In en, this message translates to:
  /// **'voiced bilabial plosive'**
  String get ipaBName;

  /// No description provided for @ipaTName.
  ///
  /// In en, this message translates to:
  /// **'voiceless alveolar plosive'**
  String get ipaTName;

  /// No description provided for @ipaDName.
  ///
  /// In en, this message translates to:
  /// **'voiced alveolar plosive'**
  String get ipaDName;

  /// No description provided for @ipaKName.
  ///
  /// In en, this message translates to:
  /// **'voiceless velar plosive'**
  String get ipaKName;

  /// No description provided for @ipaGName.
  ///
  /// In en, this message translates to:
  /// **'voiced velar plosive'**
  String get ipaGName;

  /// No description provided for @ipaTeshName.
  ///
  /// In en, this message translates to:
  /// **'voiceless postalveolar affricate'**
  String get ipaTeshName;

  /// No description provided for @ipaDezhName.
  ///
  /// In en, this message translates to:
  /// **'voiced postalveolar affricate'**
  String get ipaDezhName;

  /// No description provided for @ipaFName.
  ///
  /// In en, this message translates to:
  /// **'voiceless labiodental fricative'**
  String get ipaFName;

  /// No description provided for @ipaVName.
  ///
  /// In en, this message translates to:
  /// **'voiced labiodental fricative'**
  String get ipaVName;

  /// No description provided for @ipaThetaName.
  ///
  /// In en, this message translates to:
  /// **'voiceless dental fricative'**
  String get ipaThetaName;

  /// No description provided for @ipaEthName.
  ///
  /// In en, this message translates to:
  /// **'voiced dental fricative'**
  String get ipaEthName;

  /// No description provided for @ipaSName.
  ///
  /// In en, this message translates to:
  /// **'voiceless alveolar fricative'**
  String get ipaSName;

  /// No description provided for @ipaZName.
  ///
  /// In en, this message translates to:
  /// **'voiced alveolar fricative'**
  String get ipaZName;

  /// No description provided for @ipaEshName.
  ///
  /// In en, this message translates to:
  /// **'voiceless postalveolar fricative'**
  String get ipaEshName;

  /// No description provided for @ipaEzhName.
  ///
  /// In en, this message translates to:
  /// **'voiced postalveolar fricative'**
  String get ipaEzhName;

  /// No description provided for @ipaHName.
  ///
  /// In en, this message translates to:
  /// **'voiceless glottal fricative'**
  String get ipaHName;

  /// No description provided for @ipaMName.
  ///
  /// In en, this message translates to:
  /// **'bilabial nasal'**
  String get ipaMName;

  /// No description provided for @ipaNName.
  ///
  /// In en, this message translates to:
  /// **'alveolar nasal'**
  String get ipaNName;

  /// No description provided for @ipaEngName.
  ///
  /// In en, this message translates to:
  /// **'velar nasal'**
  String get ipaEngName;

  /// No description provided for @ipaLName.
  ///
  /// In en, this message translates to:
  /// **'alveolar lateral approximant'**
  String get ipaLName;

  /// No description provided for @ipaTurnRName.
  ///
  /// In en, this message translates to:
  /// **'alveolar approximant'**
  String get ipaTurnRName;

  /// No description provided for @ipaJName.
  ///
  /// In en, this message translates to:
  /// **'palatal approximant'**
  String get ipaJName;

  /// No description provided for @ipaWName.
  ///
  /// In en, this message translates to:
  /// **'labio-velar approximant'**
  String get ipaWName;

  /// No description provided for @ipaIName.
  ///
  /// In en, this message translates to:
  /// **'close front unrounded vowel'**
  String get ipaIName;

  /// No description provided for @ipaSmallCapitalIName.
  ///
  /// In en, this message translates to:
  /// **'near-close near-front unrounded vowel'**
  String get ipaSmallCapitalIName;

  /// No description provided for @ipaEName.
  ///
  /// In en, this message translates to:
  /// **'close-mid front unrounded vowel'**
  String get ipaEName;

  /// No description provided for @ipaEpsilonName.
  ///
  /// In en, this message translates to:
  /// **'open-mid front unrounded vowel'**
  String get ipaEpsilonName;

  /// No description provided for @ipaAshName.
  ///
  /// In en, this message translates to:
  /// **'near-open front unrounded vowel'**
  String get ipaAshName;

  /// No description provided for @ipaScriptAName.
  ///
  /// In en, this message translates to:
  /// **'open back unrounded vowel'**
  String get ipaScriptAName;

  /// No description provided for @ipaOpenOName.
  ///
  /// In en, this message translates to:
  /// **'open-mid back rounded vowel'**
  String get ipaOpenOName;

  /// No description provided for @ipaOuDiphthongName.
  ///
  /// In en, this message translates to:
  /// **'diphthong'**
  String get ipaOuDiphthongName;

  /// No description provided for @ipaUName.
  ///
  /// In en, this message translates to:
  /// **'close back rounded vowel'**
  String get ipaUName;

  /// No description provided for @ipaUpsilonName.
  ///
  /// In en, this message translates to:
  /// **'near-close near-back rounded vowel'**
  String get ipaUpsilonName;

  /// No description provided for @ipaTurnedVName.
  ///
  /// In en, this message translates to:
  /// **'open-mid back unrounded vowel'**
  String get ipaTurnedVName;

  /// No description provided for @ipaSchwaName.
  ///
  /// In en, this message translates to:
  /// **'mid central vowel (schwa)'**
  String get ipaSchwaName;

  /// No description provided for @ipaAiDiphthongName.
  ///
  /// In en, this message translates to:
  /// **'diphthong'**
  String get ipaAiDiphthongName;

  /// No description provided for @ipaAuDiphthongName.
  ///
  /// In en, this message translates to:
  /// **'diphthong'**
  String get ipaAuDiphthongName;

  /// No description provided for @ipaOpenOiDiphthongName.
  ///
  /// In en, this message translates to:
  /// **'diphthong'**
  String get ipaOpenOiDiphthongName;
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
      <String>['en', 'es', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
