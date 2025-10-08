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

  ThemeMode _themeModeFrom(String? v) {
    switch ((v ?? 'system').toLowerCase()) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }

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
      valueListenable: box.listenable(keys: const ['locale', 'themeMode']),
      builder: (_, b, _) {
        final tag = b.get('locale', defaultValue: 'en')!;
        final loc = _parseLocaleTag(tag);
        final mode = b.get('themeMode', defaultValue: 'system');
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
          theme: appTheme(Brightness.light),
          darkTheme: appTheme(Brightness.dark),
          themeMode: _themeModeFrom(mode),
          home: const HomePage(),
        );
      },
    );
  }
}

TextStyle ipaStyle(BuildContext context) => GoogleFonts.notoSans( // Estilo para alfabeto fonético
  fontSize: 13,
  height: 1.15,
  color: Theme.of(context).colorScheme.onSecondary,
  textStyle: const TextStyle(overflow: TextOverflow.visible),
);

TextStyle wordStyle(BuildContext context) => TextStyle( // Estilo para letras en general
  fontSize: 16,
  height: 1.15,
  color: Theme.of(context).colorScheme.onSurface,
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

const _seed = Color.fromARGB(255, 190, 24, 93);
const _darkPink = Color(0xFFAD1457);
const _darkPinkContainer = Color.fromARGB(166, 163, 11, 64);

ThemeData appTheme(Brightness brightness) {
  final base = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final scheme = (brightness == Brightness.dark)
      ? base.copyWith(
          primary: Color.fromARGB(100, 0, 0, 0),
          onPrimary: Colors.white,
          secondary: _darkPink,
          onSecondary: Colors.white,
          primaryContainer: _darkPinkContainer,
          onPrimaryContainer: const Color.fromARGB(255, 217, 255, 246),
          secondaryContainer: const Color.fromARGB(145, 233, 30, 128),
          tertiary: const Color.from(alpha: 0, red: 0, green: 0, blue: 0),
          tertiaryContainer: const Color.fromARGB(0, 0, 0, 0),
          tertiaryFixed: Colors.white,
          onTertiary: Color(0xFF191113)
        )
      : base.copyWith(
          primary: const Color.fromARGB(255, 255, 255, 255),
          onPrimary: Colors.black,
          secondary: _darkPink,
          onSecondary: Colors.black,
          primaryContainer: const Color.fromARGB(207, 255, 255, 255),
          onPrimaryContainer: const Color(0xFF5A0018),
          secondaryContainer: const Color.fromARGB(255, 255, 255, 255),
          surface: _seed,
          tertiary: const Color.fromARGB(20, 0, 0, 0),
          tertiaryContainer: Colors.white,
          tertiaryFixed: Colors.white,
          onTertiary: Color(0xFFFF007F),
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: GoogleFonts.notoSansTextTheme(),
    fontFamily: 'Fira Code',
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}


