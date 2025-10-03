import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../domain/providers/data_provider.dart';
import '../entities/translation.dart';

Future<Translation> ocrFromBytes({
  required DataProvider provider,
  required Uint8List bytes,
  required String target,
}) async {
  final uri = Uri.parse('${provider.uri}/ocr');

  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    body: jsonEncode({'image_b64': base64Encode(bytes), 'target': target}),
  );

  if (res.statusCode != 200) {
    throw Exception('OCR HTTP ${res.statusCode}: ${res.body}');
  }
  final bodyText = utf8.decode(res.bodyBytes);

  if (res.statusCode == 200 || res.statusCode == 207) {
    final decoded = jsonDecode(bodyText);
    final originalText = decoded['originalText'] as String? ?? '';
    final translated = decoded['translatedText'] as String? ?? '';
    final dl = decoded['detectedLanguage'];
    String detectedLanguage = dl is Map
        ? (dl['language'] as String? ?? '')
        : (dl as String? ?? '');
    detectedLanguage = detectedLanguage.substring(0, 2); // Recortar idioma a 2 caracteres
    final originalIpa = (decoded['originalIpa'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final translatedIpa = (decoded['translatedIpa'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return Translation(
      originalText: originalText,
      translatedText: translated,
      detectedLanguage: detectedLanguage,
      target: target,
      originalIpa: originalIpa,
      translatedIpa: translatedIpa,
    );
  } else {
    throw Exception('Error en ocrFromBytes $provider $bytes $target ${res.statusCode}: $bodyText');
  }
}