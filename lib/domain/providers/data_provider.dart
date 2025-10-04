import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:http/http.dart' as http;
import '../../entities/translation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../helpers/cache.dart';
 
class DataProvider {
  DataProvider({http.Client? client})
      : _client = client ?? http.Client(),
        limiter = RequestLimiter();

  final http.Client _client;
  final RequestLimiter limiter;

  Uri get uri => kIsWeb
      ? Uri.parse('http://localhost:3000')
      : (Platform.isAndroid
          ? Uri.parse('http://10.0.2.2:3000')
          : Uri.parse('http://localhost:3000'));

  void dispose() => _client.close();

  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return _client
        .post(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 15));
  }
}


Future<Translation> fetchTranslation(
  DataProvider provider,
  String originalLanguage,
  String target,
) async {
  final key = 'fetchTranslation|$originalLanguage|$target';

  return provider.limiter.run<Translation>(key, () async {
    final res = await provider.post(
      provider.uri,
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'originalLanguage': originalLanguage, 'target': target}),
    );
    final bodyText = utf8.decode(res.bodyBytes);

    if (res.statusCode == 200 || res.statusCode == 207) {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) {
        return Translation.fromJson(decoded);
      } else if (decoded is List && decoded.isNotEmpty) {
        return Translation.fromJson(decoded.first as Map<String, dynamic>);
      }
      throw const FormatException('Unexpected JSON from server');
    }
    throw Exception('HTTP ${res.statusCode}: $bodyText');
  }, cache: true);
}

Future<Translation> fetchTranslationFor(
  DataProvider provider,
  String text,
  String source,
  String target,
) async {
  final norm = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final key = 'translate|$source|$target|${norm.hashCode}';

  return provider.limiter.run<Translation>(key, () async {
    final res = await provider.post(
      Uri.parse('${provider.uri}/translate'),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'q': norm, 'source': source, 'target': target, 'format': 'text'}),
    );
    final bodyText = utf8.decode(res.bodyBytes);

    if (res.statusCode == 200 || res.statusCode == 207) {
      final decoded = jsonDecode(bodyText) as Map<String, dynamic>;
      final translated = decoded['translatedText'] as String? ?? '';
      final dl = decoded['detectedLanguage'];
      String detectedLanguage = dl is Map ? (dl['language'] as String? ?? '') : (dl as String? ?? '');
      detectedLanguage = detectedLanguage.substring(0, detectedLanguage.isEmpty ? 0 : 2);

      final originalIpa = (decoded['originalIpa'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final translatedIpa = (decoded['translatedIpa'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      return Translation(
        originalText: norm,
        translatedText: translated,
        detectedLanguage: detectedLanguage,
        target: target,
        originalIpa: originalIpa,
        translatedIpa: translatedIpa,
      );
    }
    throw Exception('HTTP ${res.statusCode}: $bodyText');
  }, cache: true);
}

Future<String> translateWord({
  required DataProvider provider,
  required String word,
  required String target,
  required String source,
}) async {
  final norm = word.trim().toLowerCase();
  final key = 'word|$source|$target|$norm';

  return provider.limiter.run<String>(key, () async {
    final res = await provider.post(
      Uri.parse('${provider.uri}/translate'),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'q': norm, 'source': source, 'target': target, 'format': 'text'}),
    );
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final m = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (m['translatedText'] as String?) ?? '';
  }, cache: true);
}

Future<String> ocr({
  required DataProvider provider,
  required File imageFile,
  required String target,
}) async {
  final key = 'ocr|$target|${imageFile.path.hashCode}';

  return provider.limiter.run<String>(key, () async {
    final uri = Uri.parse('${provider.uri}/ocr');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final m = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (m['translatedText'] as String?) ?? '';
  }, cache: false);
}
