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
  String get error_translation => 'An error occurred while translating';

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
}
