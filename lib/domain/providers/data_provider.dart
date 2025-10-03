import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:http/http.dart' as http;
import '../../entities/translation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
 
class DataProvider {
  final Uri uri = kIsWeb
    ? Uri.parse('http://localhost:3000')
    : Platform.isAndroid
    ? Uri.parse('http://10.0.2.2:3000') // Para emulador de Android
    : Uri.parse('http://localhost:3000');
}

Future<Translation> fetchTranslation( // Pedir frase y traducción
  DataProvider provider,
  String originalLanguage,
  String target,
) async {
    final response = await http.post(
      provider.uri,
      headers: {'Accept': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'originalLanguage': originalLanguage,
        'target': target,
      }),
    );
    final bodyText = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200 || response.statusCode == 207) {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) {
        return Translation.fromJson(decoded);
      } else if (decoded is List && decoded.isNotEmpty) {
        return Translation.fromJson(decoded.first as Map<String, dynamic>);
      } else {
        throw FormatException('JSON inesperado del servidor');
      }
    } else {
      throw Exception('Error en fetchTranslation HTTP ${response.statusCode}: $bodyText');
    }
} 

Future<Translation> fetchTranslationFor(DataProvider provider, String text, String source, String target) async { // Pedir traducción de frase específica
  final response = await http.post(
    Uri.parse('${provider.uri}/translate'),
    headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
    body: jsonEncode(<String, dynamic>{
      'q': text,
      'source': source,
      'target': target,
      'format': 'text',
    }),
  );
  final bodyText = utf8.decode(response.bodyBytes);

  if (response.statusCode == 200 || response.statusCode == 207) {
    final decoded = jsonDecode(bodyText);
    final translated = decoded['translatedText'] as String? ?? '';
    final dl = decoded['detectedLanguage'];
    String detectedLanguage = dl is Map
    ? (dl['language'] as String? ?? '')
    : (dl as String? ?? '');
    detectedLanguage = detectedLanguage.substring(0, 2);
    final originalIpa = (decoded['originalIpa'] as List<dynamic>? ?? [])
    .map((e) => e.toString())
    .toList();
    final translatedIpa = (decoded['translatedIpa'] as List<dynamic>? ?? [])
    .map((e) => e.toString())
    .toList();
    return Translation(
      originalText: text,
      translatedText: translated,
      detectedLanguage: detectedLanguage,
      target: target,
      originalIpa: originalIpa,
      translatedIpa: translatedIpa,
    );
  } else {
    throw Exception('Error en fetchTranslationFor $provider $text $source $target ${response.statusCode}: $bodyText');
  }
}

Future<String> translateWord({ // Traducir palabra
  required DataProvider provider,
  required String word,
  required String target,
  required String source,
}) async {
  final res = await http.post(
    Uri.parse('${provider.uri}/translate'),
    headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
    body: jsonEncode({'q': word, 'source': source, 'target': target, 'format': 'text'}),
  );
  if (res.statusCode != 200) {
    throw Exception('Error en translateWord $provider $word $target HTTP ${res.statusCode}: ${res.body}');
  }
  final m = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  return (m['translatedText'] as String?) ?? '';
}

Future<String> ocr({ // Reconocimiento de texto
  required DataProvider provider,
  required File imageFile,
  required String target,
}) async {
  final uri = Uri.parse('${provider.uri}/ocr');
  final req = http.MultipartRequest('POST', uri)..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  final res = await http.Response.fromStream(await req.send());

  if (res.statusCode != 200) {
    throw Exception('Error en ocr $provider $imageFile $target HTTP ${res.statusCode}: ${res.body}');
  }
  final m = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  return (m['translatedText'] as String?) ?? '';
}