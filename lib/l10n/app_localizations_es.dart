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

  @override
  String get frase => 'Frase';

  @override
  String get sujeto => 'Sujeto';

  @override
  String get verbo => 'Verbo';

  @override
  String get color => 'Color';

  @override
  String get familia => 'Familia';

  @override
  String get adjetivo => 'Adjetivo';

  @override
  String get direccion => 'Direcciones';

  @override
  String get retraducir => 'Retraducir';

  @override
  String speechNotInstalled(Object lang) {
    return 'No tienes instalado el reconocimiento de voz de $lang.';
  }

  @override
  String get theme => 'Tema';

  @override
  String get ipaPName => 'oclusiva bilabial sorda';

  @override
  String get ipaBName => 'oclusiva bilabial sonora';

  @override
  String get ipaTName => 'oclusiva alveolar sorda';

  @override
  String get ipaDName => 'oclusiva alveolar sonora';

  @override
  String get ipaKName => 'oclusiva velar sorda';

  @override
  String get ipaGName => 'oclusiva velar sonora';

  @override
  String get ipaTeshName => 'africada postalveolar sorda';

  @override
  String get ipaDezhName => 'africada postalveolar sonora';

  @override
  String get ipaFName => 'fricativa labiodental sorda';

  @override
  String get ipaVName => 'fricativa labiodental sonora';

  @override
  String get ipaThetaName => 'fricativa dental sorda';

  @override
  String get ipaEthName => 'fricativa dental sonora';

  @override
  String get ipaSName => 'fricativa alveolar sorda';

  @override
  String get ipaZName => 'fricativa alveolar sonora';

  @override
  String get ipaEshName => 'fricativa postalveolar sorda';

  @override
  String get ipaEzhName => 'fricativa postalveolar sonora';

  @override
  String get ipaHName => 'fricativa glotal sorda';

  @override
  String get ipaMName => 'nasal bilabial';

  @override
  String get ipaNName => 'nasal alveolar';

  @override
  String get ipaEngName => 'nasal velar';

  @override
  String get ipaLName => 'lateral alveolar';

  @override
  String get ipaTurnRName => 'aproximante alveolar';

  @override
  String get ipaJName => 'aproximante palatal';

  @override
  String get ipaWName => 'aproximante labiovelar';

  @override
  String get ipaIName => 'vocal anterior cerrada no redondeada';

  @override
  String get ipaSmallCapitalIName =>
      'vocal casi cerrada casi anterior no redondeada';

  @override
  String get ipaEName => 'vocal anterior media-cerrada no redondeada';

  @override
  String get ipaEpsilonName => 'vocal anterior media-abierta no redondeada';

  @override
  String get ipaAshName => 'vocal casi abierta anterior no redondeada';

  @override
  String get ipaScriptAName => 'vocal posterior abierta no redondeada';

  @override
  String get ipaOpenOName => 'vocal posterior media-abierta redondeada';

  @override
  String get ipaOuDiphthongName => 'diptongo';

  @override
  String get ipaUName => 'vocal posterior cerrada redondeada';

  @override
  String get ipaUpsilonName => 'vocal casi cerrada casi posterior redondeada';

  @override
  String get ipaTurnedVName => 'vocal posterior media-abierta no redondeada';

  @override
  String get ipaSchwaName => 'vocal central media (schwa)';

  @override
  String get ipaAiDiphthongName => 'diptongo';

  @override
  String get ipaAuDiphthongName => 'diptongo';

  @override
  String get ipaOpenOiDiphthongName => 'diptongo';

  @override
  String get network_error => 'Error de red. Revisa tu conexión.';

  @override
  String get timeout => 'La solicitud excedió el tiempo de espera.';

  @override
  String get ssl_error => 'Falló la conexión segura (SSL).';

  @override
  String get canceled => 'Solicitud cancelada.';

  @override
  String get bad_request => 'Solicitud incorrecta.';

  @override
  String get unauthorized => 'No autorizado. Inicia sesión.';

  @override
  String get forbidden => 'Acceso denegado.';

  @override
  String get not_found => 'Servidor offline / no encontrado.';

  @override
  String get method_not_allowed => 'Método no permitido.';

  @override
  String get conflict => 'Conflicto.';

  @override
  String get unprocessable_entity => 'Entidad no procesable.';

  @override
  String get too_many_requests =>
      'Demasiadas solicitudes. Inténtalo más tarde.';

  @override
  String get server_error => 'Error interno del servidor.';

  @override
  String get bad_gateway => 'Puerta de enlace incorrecta.';

  @override
  String get service_unavailable => 'Servicio no disponible.';

  @override
  String get gateway_timeout => 'Tiempo de espera de la puerta de enlace.';

  @override
  String get unknown_error => 'Error inesperado.';

  @override
  String get no_text_in_ocr => 'No se detectó texto en el OCR.';
}
