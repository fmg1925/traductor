import 'package:hive_flutter/hive_flutter.dart';
import '../domain/providers/data_provider.dart';

class WordCache {
  static DataProvider provider = DataProvider();
  static Box get _box => Hive.box<String>('word_cache');
  static bool translating = false;

  static String _makeKey(String originalWord, String origin, String target) =>
    '$originalWord::$origin::$target';

  static final Map<String, Future<String>> _inProgress = {};

  static Future<String?> get(String word, String origin, String target) async {
    final key = _makeKey(word, origin, target);

    final cached = _box.get(key);
    if (cached != null) return Future.value(cached as String);

    if (_inProgress.isNotEmpty) {
      return _inProgress[key]!;
    }

    if(origin == target) {
      await _box.put(key, word);
      _inProgress.remove(key);
      return word;
    }

    final resultado = translateWord(provider: provider, word: word, target: target)
    .then((resultado) async {
      await _box.put(key, resultado);
      return resultado;
    }).whenComplete(() {
      _inProgress.remove(key);
    });

    _inProgress[key] = resultado;
    return resultado;
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}