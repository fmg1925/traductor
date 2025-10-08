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
  String get error_ocr => 'Error al procesar OCR';

  @override
  String error_translation(Object log) {
    return 'Ocurrió un error al traducir, registro del error: $log';
  }

  @override
  String get main_hint => 'Escribe algo o pulsa \"Generar\"...';

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

  @override
  String get generate => 'Generar';

  @override
  String get detected_words => 'Palabras detectadas:';

  @override
  String get tap_to_stop => 'Toca para detener';

  @override
  String get repeat_this_phrase => 'Repite esta frase:';

  @override
  String error_function(Object fn, Object msg) {
    return 'Error en la función $fn. Informa a los desarrolladores: $msg';
  }

  @override
  String get listening => 'Escuchando';

  @override
  String error_stt(Object msg) {
    return 'Error al procesar Voz a Texto: $msg';
  }

  @override
  String get accuracy => 'Precisión';

  @override
  String get feature_not_available => 'Función no disponible';

  @override
  String get feature_not_available_windows =>
      'Esta función no está disponible en Windows';

  @override
  String missing_language(Object lang) {
    return 'Falta el paquete de voz del idioma: $lang';
  }

  @override
  String language_not_installed(Object lang) {
    return 'No tienes instalado el paquete de voz del idioma $lang';
  }

  @override
  String get search => 'Buscar…';

  @override
  String get delete => 'Eliminar';

  @override
  String get no_mic_input => 'No se detectó entrada de micrófono';

  @override
  String no_match(String lang) {
    return 'No hay palabras que coincidan en el idioma $lang';
  }

  @override
  String get not_allowed => 'Sin permiso de micrófono';

  @override
  String get unsupported_browser => 'Navegador no soportado';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get generate_for_practice =>
      'Genera una frase para empezar a practicar';
}
