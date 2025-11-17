// force_web_speech_lang_web.dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Fuerza el idioma de SpeechRecognition en Web (Chrome/Edge).
/// Llama a esto una sola vez (por ejemplo, en main()), o cada vez
/// que cambies de idioma. Es idempotente.
bool forceWebSpeechLang(String bcp47) {
  // Window de JS (no usamos dart:html).
  final win = web.window;

  // Guardamos el idioma forzado en una global JS. Cambiar este valor
  // es O(1) y no re-parchea nada.
  (win as JSObject)['__forcedSpeechLang__'] = bcp47.toJS;

  // Constructor: SpeechRecognition o webkitSpeechRecognition.
  JSAny? srAny = (win as JSObject)['SpeechRecognition'];
  if (srAny == null || srAny.isUndefinedOrNull) {
    srAny = (win as JSObject)['webkitSpeechRecognition'];
  }
  if (srAny == null || srAny.isUndefinedOrNull) return false;

  final sr = srAny as JSObject;

  final protoAny = sr['prototype'];
  if (protoAny == null || protoAny.isUndefinedOrNull) return false;
  final proto = protoAny as JSObject;

  // Si ya está parcheado, solo actualizamos el idioma global y salimos.
  final alreadyPatched = proto['__langPatched__'];
  if (!(alreadyPatched == null || alreadyPatched.isUndefinedOrNull)) {
    return true;
  }

  // Object.defineProperty(SpeechRecognition.prototype, 'lang', { get, set })
  final objectCtorAny = (win as JSObject)['Object'];
  if (objectCtorAny == null || objectCtorAny.isUndefinedOrNull) return false;
  final objectCtor = objectCtorAny as JSObject;

  final descriptor = <String, Object?>{
    'configurable': true,
    'enumerable': false,

    // Siempre lee el idioma actual desde la global.
    'get': (() => (win as JSObject)['__forcedSpeechLang__']).toJS,

    // Ignora escrituras a .lang para que ningún código JS pueda
    // sobreescribir el idioma forzado. No hace trabajo extra.
    'set': ((JSAny? _) {}).toJS,
  }.jsify() as JSAny;

  objectCtor.callMethodVarArgs(
    'defineProperty'.toJS,
    <JSAny?>[proto, 'lang'.toJS, descriptor],
  );

  proto['__langPatched__'] = true.toJS;
  return true;
}