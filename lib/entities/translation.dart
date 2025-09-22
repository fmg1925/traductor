class Translation {
  final String originalText;
  final String translatedText;
  final String detectedLanguage;

  Translation({
    required this.originalText,
    required this.translatedText,
    required this.detectedLanguage,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      originalText: (json['originalText'] ?? '') as String,
      translatedText: (json['translatedText'] ?? '') as String,
      detectedLanguage: (json['detectedLanguage'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'originalText': originalText,
    'translatedText': translatedText,
    'detectedLanguage': detectedLanguage,
  };
}