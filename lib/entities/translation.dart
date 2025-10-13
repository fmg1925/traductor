class Translation {
  final String originalText;
  final String translatedText;
  final String detectedLanguage;
  final String target;
  final List<String>? originalRomanization;
  final List<String>? translatedRomanization;
  final List<String> originalIpa;
  final List<String> translatedIpa;

  Translation({
    required this.originalText,
    required this.translatedText,
    required this.detectedLanguage,
    required this.target,
    this.originalRomanization,
    this.translatedRomanization,
    required this.originalIpa,
    required this.translatedIpa,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      originalText: (json['originalText'] ?? '') as String,
      translatedText: (json['translatedText'] ?? '') as String,
      detectedLanguage: ((json['detectedLanguage'] ?? '') as String).substring(0, 2), // Cortar idioma detectado a 2 caracteres (inconsistencias en zh)
      target: (json['target'] ?? '') as String,
      originalRomanization: List<String>.from(json['originalRomanization'] ?? []),
      translatedRomanization: List<String>.from(json['translatedRomanization'] ?? []),
      originalIpa: List<String>.from(json['originalIpa'] ?? []),
      translatedIpa: List<String>.from(json['translatedIpa'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'originalText': originalText,
    'translatedText': translatedText,
    'detectedLanguage': detectedLanguage.substring(0, 2),
    'target': target,
    'originalRomanization': originalRomanization,
    'translatedRomanization': translatedRomanization,
    'originalIpa': originalIpa,
    'translatedIpa': translatedIpa,
  };
}