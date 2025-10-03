import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traductor/pages/home.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/web_title.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Iniciar persistencia
  await Hive.openBox<String>('word_cache'); // Diccionario
  await Hive.openBox<String>('prefs'); // Idioma
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setWebTitle("Trilingo"); // Forzar título en web, default es ip:puerto
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Box prefs = Hive.box<String>('prefs');

  Locale _parseLocaleTag(String tag) { // Convertir idiomas xx-XX a xx
    final parts = tag.split(RegExp(r'[-_]'));
    if (parts.length == 1) return Locale(parts[0]);
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    return Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
      countryCode: parts[2],
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<String>('prefs');
    return ValueListenableBuilder<Box<String>>(
      valueListenable: box.listenable(keys: const ['locale']),
      builder: (_, b, _) {
        final tag = b.get('locale', defaultValue: 'en')!;
        final loc = _parseLocaleTag(tag);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: loc,
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('zh'),
            Locale('ja'),
            Locale('ko'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(fontFamily: 'Fira Code'),
          home: const HomePage(),
        );
      },
    );
  }
}

final ipaStyle = GoogleFonts.notoSans( // Estilo para alfabeto fonético
  fontSize: 13,
  height: 1.15,
  color: const Color(0xFF424242),
  textStyle: const TextStyle(overflow: TextOverflow.visible),
);

final wordStyle = const TextStyle( // Estilo para letras en general
  fontSize: 16,
  height: 1.15,
  color: Colors.black87,
);

extension L10nX on BuildContext { // Para recargar idioma en ejecución
  AppLocalizations get l10n => AppLocalizations.of(this);
}

Map<String, String> languages(BuildContext ctx) => {
  'auto': ctx.l10n.auto,
  'en': ctx.l10n.en,
  'es': ctx.l10n.es,
  'zh': ctx.l10n.zh,
  'ja': ctx.l10n.ja,
  'ko': ctx.l10n.ko,
};

Map<String, String> locales(BuildContext ctx) => {
  'en': ctx.l10n.en,
  'es': ctx.l10n.es,
  'zh': ctx.l10n.zh,
  'ja': ctx.l10n.ja,
  'ko': ctx.l10n.ko,
};

String ttsLocaleFor(String code) { // Convertir locales a compatibles con TTS
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
