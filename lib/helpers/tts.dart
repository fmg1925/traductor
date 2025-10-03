import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Tts {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;

  void Function(bool)? onStateChanged;

  Future<void> init({String lang = 'es-ES', void Function(bool)? onStateChanged}) async {
    await _tts.setLanguage(lang);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    if (kIsWeb) {
      await _tts.setSpeechRate(1); // 1 es normal en web
    } else {
      await _tts.setSpeechRate(0.50); // En todas las demás lo normal es 0.5
    }

    _tts.setStartHandler(() {
      isSpeaking = true;
      onStateChanged?.call(true);
    });
    _tts.setCompletionHandler(() {
      isSpeaking = false;
      onStateChanged?.call(false);
    });
    _tts.setCancelHandler(() {
      isSpeaking = false;
      onStateChanged?.call(false);
    });
    _tts.setErrorHandler((msg) {
      isSpeaking = false;
      onStateChanged?.call(false);
    });
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }
  
  Future<void> stop() => _tts.stop();
  Future<void> dispose() => _tts.stop();
  Future<void> changeLanguage(String language) => _tts.setLanguage(language);
  bool getState() => isSpeaking; // Conseguir si está hablando o no
  Future isLanguageAvailable(String language) => _tts.isLanguageAvailable(language);
}
