import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:universal_io/io.dart' show Platform;

class Tts {
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<bool> speaking = ValueNotifier(false);

  final bool isWindowsDesktop = Platform.isWindows && !kIsWeb;

  Future<void> init({
    String lang = 'en-US',
    void Function(bool)? onStateChanged,
  }) async {
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
      speaking.value = true;
    });
    _tts.setCompletionHandler(() {
      speaking.value = false;
    });
    _tts.setCancelHandler(() {
      speaking.value = false;
    });
    _tts.setErrorHandler((msg) {
      speaking.value = false;
    });
  }

  Future<void> speak(String text) async {
    if(speaking.value) {
      await _tts.stop();
    }
    speaking.value = true;
    try {
      await _tts.speak(text);
    } catch(e) {
      speaking.value = false;
    } finally {
      speaking.value = false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    speaking.value = false;
  }

  Future<void> dispose() async {
    _tts.stop();
    speaking.value = false;
  }

  Future<void> changeLanguage(String language) async {
    if (isWindowsDesktop) {
      List voices = await _tts.getVoices;
      late String selectedVoice;
      for (var voice in voices) {
        if (voice['locale'] == language) {
          selectedVoice = voice['name'];
          break;
        }
      }
      await _tts.setVoice({
        'name': selectedVoice,
        'locale': language,
      });
    }
    return await _tts.setLanguage(language);
  }

  Future<bool> isLanguageAvailable(String language) async {
    if (isWindowsDesktop) {
      final raw = await _tts.getVoices;

      if (raw.isEmpty) {
        return Future.value(false);
      }

      for (var voice in raw) {
        if (voice['locale'] == language) {
          return Future.value(true);
        }
      }

      return Future.value(false);
    }

    return _tts.isLanguageAvailable(language).then((v) => v == true);
  }
}
