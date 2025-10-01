class Translation {
  final String originalText;
  final String translatedText;
  final String detectedLanguage;
  final String target;
  final List<String> originalIpa;
  final List<String> translatedIpa;

  Translation({
    required this.originalText,
    required this.translatedText,
    required this.detectedLanguage,
    required this.target,
    required this.originalIpa,
    required this.translatedIpa,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      originalText: (json['originalText'] ?? '') as String,
      translatedText: (json['translatedText'] ?? '') as String,
      detectedLanguage: ((json['detectedLanguage'] ?? '') as String).substring(0, 2),
      target: (json['target'] ?? '') as String,
      originalIpa: List<String>.from(json['originalIpa'] ?? []),
      translatedIpa: List<String>.from(json['translatedIpa'] ?? []),

    );
  }

  Map<String, dynamic> toJson() => {
    'originalText': originalText,
    'translatedText': translatedText,
    'detectedLanguage': detectedLanguage.substring(0, 2),
    'target': target,
    'originalIpa': originalIpa,
    'translatedIpa': translatedIpa,
  };
}