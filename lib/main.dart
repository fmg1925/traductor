import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traductor/pages/home.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/web_title.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('word_cache');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setWebTitle("Trilingo");
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Fira Code'),
      home: HomePage()
    );
  }
}

final ipaStyle = GoogleFonts.notoSans(
  fontSize: 13,
  height: 1.15,
  color: const Color(0xFF424242),
);

final wordStyle = const TextStyle(
  fontSize: 16,
  height: 1.15,
  color: Colors.black87,
);

const Map<String, String> languages = {
  'auto': 'Detectar automáticamente',
  'en': 'Inglés',
  'es': 'Español',
  'zh': 'Chino',
  'ja': 'Japonés',
  'ko': 'Coreano',
};

String ttsLocaleFor(String code) {
  switch (code) {
    case 'es':
      return 'es-ES';
    case 'en':
      return 'en-US';
    case 'fr':
      return 'fr-FR';
    case 'pt':
      return 'pt-PT';
    case 'ko':
      return 'ko-KR';
    case 'ja':
      return 'ja-JP';
    case 'zh':
      return 'zh-CN';
    default:
      return 'en-US';
  }
}
