import 'package:hive_flutter/hive_flutter.dart';
import '../domain/providers/data_provider.dart';

class WordCache {
  static DataProvider provider = DataProvider();
  static Box get _box => Hive.box('word_cache');
  static bool translating = false;

  static String _makeKey(String word, String target) =>
    '${word.toLowerCase()}::$target';

  static Future<String?> get(String word, String target) async {
    final key = _makeKey(word, target);

    final cached = _box.get(key);
    if (cached != null) return cached as String;

    if(translating) return null;
    translating = true;
    try {
    final result = await translateWord(provider: provider, word: word, target: target);

    await _box.put(key, result);
    return result;
    } finally {
      translating = false;
    }
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}