// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get error => 'Error';

  @override
  String get error_tts => 'Error al inicializar TTS';

  @override
  String get error_ocr => 'Error al procesar el OCR';

  @override
  String get error_translation => 'Ocurrió un error al traducir';

  @override
  String get main_hint => 'Escribe algo o presiona \"Generar\"...';

  @override
  String get start => 'Iniciar';

  @override
  String get stop => 'Detener';

  @override
  String get listen => 'Escuchar';

  @override
  String get generate_translation => 'Generar traducción';

  @override
  String get translate => 'Traducir';

  @override
  String get translation => 'Traducción';

  @override
  String get original => 'Original';

  @override
  String get practice => 'Practicar';

  @override
  String get dictionary => 'Diccionario';

  @override
  String get no_words => 'No hay palabras guardadas en el diccionario';

  @override
  String get auto => 'Detección automática';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get en => 'Inglés';

  @override
  String get es => 'Español';

  @override
  String get zh => 'Chino';

  @override
  String get ja => 'Japonés';

  @override
  String get ko => 'Coreano';
}
