// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get error => 'Error';

  @override
  String get error_tts => 'Error initializing TTS';

  @override
  String get error_ocr => 'Error processing OCR';

  @override
  String error_translation(Object log) {
    return 'An error occurred while translating, error log: $log';
  }

  @override
  String get main_hint => 'Write something or press \"Generate\"...';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get listen => 'Listen';

  @override
  String get generate_translation => 'Generate Translation';

  @override
  String get translate => 'Translate';

  @override
  String get translation => 'Translation';

  @override
  String get original => 'Original';

  @override
  String get practice => 'Practice';

  @override
  String get dictionary => 'Dictionary';

  @override
  String get no_words => 'No words stored in dictionary';

  @override
  String get auto => 'Auto detect';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get en => 'English';

  @override
  String get es => 'Spanish';

  @override
  String get zh => 'Chinese';

  @override
  String get ja => 'Japanese';

  @override
  String get ko => 'Korean';

  @override
  String get generate => 'Generate';

  @override
  String get detected_words => 'Detected words:';

  @override
  String get tap_to_stop => 'Tap to stop';

  @override
  String get repeat_this_phrase => 'Repeat this phrase:';

  @override
  String error_function(Object fn, Object msg) {
    return 'Error in function $fn please report this to the developers: $msg';
  }

  @override
  String get listening => 'Listening';

  @override
  String error_stt(Object msg) {
    return 'Error processing Speech To Text: $msg';
  }

  @override
  String get accuracy => 'Accuracy';

  @override
  String get feature_not_available => 'Feature not available';

  @override
  String get feature_not_available_windows =>
      'This feature is not available on Windows';

  @override
  String missing_language(Object lang) {
    return 'Missing language voice pack: $lang';
  }

  @override
  String language_not_installed(Object lang) {
    return 'You do not have the $lang language voice pack installed';
  }

  @override
  String get search => 'Search…';

  @override
  String get delete => 'Delete';

  @override
  String get no_mic_input => 'No microphone input detected';

  @override
  String no_match(String lang) {
    return 'No words match in $lang language';
  }

  @override
  String get not_allowed => 'Microphone permission denied';

  @override
  String get unsupported_browser => 'Unsupported browser';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get generate_for_practice => 'Generate a phrase to start practicing';

  @override
  String get frase => 'Phrase';

  @override
  String get sujeto => 'Subject';

  @override
  String get verbo => 'Verb';

  @override
  String get color => 'Color';

  @override
  String get familia => 'Family';

  @override
  String get adjetivo => 'Adjective';

  @override
  String get direccion => 'Directions';

  @override
  String get retraducir => 'Retranslate';
}
