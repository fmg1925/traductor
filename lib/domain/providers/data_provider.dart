import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../../entities/translation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../helpers/cache.dart';
import 'package:crypto/crypto.dart';
 
class DataProvider {
  DataProvider({http.Client? client})
      : _client = client ?? http.Client(),
        limiter = RequestLimiter();

  final http.Client _client;
  final RequestLimiter limiter;

  Uri get uri => kIsWeb
      ? Uri.parse('https://herpetologic-nonmelodiously-maudie.ngrok-free.dev')
      : (Platform.isAndroid
          ? Uri.parse('https://herpetologic-nonmelodiously-maudie.ngrok-free.dev')
          : Uri.parse('https://herpetologic-nonmelodiously-maudie.ngrok-free.dev'));

  void dispose() => _client.close();

  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return _client
        .post(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 1));
  }
}

Future<Translation> fetchTranslation(
  DataProvider provider,
  String originalLanguage,
  String target,
  String tipo,
) async {
  final key = 'fetchTranslation|$originalLanguage|$target';

  return provider.limiter.run<Translation>(key, () async {
    final res = await provider.post(
      provider.uri,
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'originalLanguage': originalLanguage, 'target': target, 'tipo': tipo}),
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
  final digest = md5.convert(utf8.encode(norm)).toString();
  final key = 'translate|$source|$target|$digest';

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
      final originalRomanization = (decoded['originalRomanization'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final translatedRomanization = (decoded['translatedRomanization'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      return Translation(
        originalText: norm,
        translatedText: translated,
        detectedLanguage: detectedLanguage,
        target: target,
        originalIpa: originalIpa,
        translatedIpa: translatedIpa,
        originalRomanization: originalRomanization,
        translatedRomanization: translatedRomanization
      );
    }
    throw Exception('HTTP ${res.statusCode}: $bodyText');
  }, cache: true);
}

Future<Translation> retranslate(
  DataProvider provider,
  String text,
  String source,
  String target,
) async {
  final norm = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final digest = md5.convert(utf8.encode(norm)).toString();
  final key = 'translate|$source|$target|$digest';

  return provider.limiter.run<Translation>(
    key,
    () async {
      final res = await provider.post(
        Uri.parse('${provider.uri}/retranslate'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
        body: jsonEncode({
          'sentence': norm,
          'sourceLang': source,
          'targetLang': target,
        }),
      );

      final bodyText = utf8.decode(res.bodyBytes);
      if (res.statusCode != 200 && res.statusCode != 207) {
        throw Exception('HTTP ${res.statusCode}: $bodyText');
      }

      final decoded = jsonDecode(bodyText) as Map<String, dynamic>;
      final translated = decoded['translatedText'] as String? ?? '';
      final dl = decoded['detectedLanguage'];
      String detectedLanguage = dl is Map ? (dl['language'] as String? ?? '') : (dl as String? ?? '');
      detectedLanguage = detectedLanguage.substring(0, detectedLanguage.isEmpty ? 0 : 2);

      final originalIpa = (decoded['originalIpa'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final translatedIpa = (decoded['translatedIpa'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final originalRomanization = (decoded['originalRomanization'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final translatedRomanization = (decoded['translatedRomanization'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      final tx = Translation(
        originalText: norm,
        translatedText: translated,
        detectedLanguage: detectedLanguage,
        target: target,
        originalIpa: originalIpa,
        translatedIpa: translatedIpa,
        originalRomanization: originalRomanization,
        translatedRomanization: translatedRomanization,
      );
      return tx;
    },
    cache: false,
  );
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
