// force_web_speech_lang.dart
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js_util' as jsu;

/// Fuerza el idioma de SpeechRecognition en Web (Chrome/Edge).
/// Llama a esto una sola vez (por ejemplo, en main()).
bool forceWebSpeechLang(String bcp47) {
  final w = html.window;

  // Obtén el constructor (SpeechRecognition o webkitSpeechRecognition).
  // ignore: non_constant_identifier_names
  var SR = jsu.getProperty(w, 'SpeechRecognition');
  SR ??= jsu.getProperty(w, 'webkitSpeechRecognition');
  if (SR == null) return false;

  final proto = jsu.getProperty(SR, 'prototype');
  if (proto == null) return false;

  // Evita parchear más de una vez.
  if (jsu.getProperty(proto, '__langPatched__') == true) {
    jsu.setProperty(w, '__forcedSpeechLang__', bcp47);
    return true;
  }

  // Guarda el start original.
  final originalStart = jsu.getProperty(proto, 'start');
  if (originalStart == null) return false;

  // Variable global para poder cambiar el idioma en caliente.
  jsu.setProperty(w, '__forcedSpeechLang__', bcp47);

  // Parchea start(): antes de arrancar, fija .lang al valor forzado.
  jsu.setProperty(
    proto,
    'start',
    jsu.allowInteropCaptureThis((self) {
      final forced = jsu.getProperty(w, '__forcedSpeechLang__') ?? bcp47;
      jsu.setProperty(self, 'lang', forced); // <- BCP-47 (p.ej., "es-ES")
      // Llama al start original preservando el this.
      jsu.callMethod(originalStart, 'call', [self]);
    }),
  );

  jsu.setProperty(proto, '__langPatched__', true);
  return true;
}