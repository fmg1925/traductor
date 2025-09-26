import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../entities/translation.dart';
import 'package:traductor/domain/providers/data_provider.dart';
import '../partials/tap_word_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../network/ocr_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final provider = DataProvider();
  String sourceLang = 'auto';
  String targetLang = 'es';
  Future<Translation>? translationFuture;

  int index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generar() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        translationFuture = fetchTranslationFor(
          provider,
          _controller.text,
          sourceLang,
          targetLang,
        );
      } else {
        translationFuture = fetchTranslation(provider, sourceLang, targetLang);
      }
    });
  }

  bool _loading = false;

  Future<XFile?> pickPhotoUniversal() async {
  final picker = ImagePicker();

  final canUseCamera = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (canUseCamera) {
    return picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
  } else {
    return picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
  }
}

  Future<void> _ocr() async {
  final x = await pickPhotoUniversal();
  if (x == null) return;

  if (mounted) setState(() => _loading = true);
  try {
    final bytes = await x.readAsBytes();
    final traduccion = await ocrFromBytes(
      provider: provider,
      bytes: bytes,
      target: targetLang
    );
    debugPrint('OCR: ${traduccion.translatedText}');
  } catch (e) {
    debugPrint('OCR error: $e');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Colors.pinkAccent,
      body: IndexedStack(index: index, children: [
        mainColumn(),
        const DiccionarioView(),
      ]),
      bottomNavigationBar: bottomNavBar(),
    );
  }

  NavigationBar bottomNavBar() {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Traducir'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_outlined), label: 'Diccionario'),        
      ],
    );
  }

  Column mainColumn() {
    return Column(
      children: [
        mainBody(),
        languageDropdown(),
        const SizedBox(height: 12),
        generarButton(),
        ocrButton(),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TranslationsArea(
              future: translationFuture,
              targetLang: targetLang,
            ),
          ),
        ),
      ],
    );
  }

  Padding generarButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _generar,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Generar traducción'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Padding ocrButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _ocr,
            icon: const Icon(Icons.play_arrow),
            label: const Text('OCR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Padding languageDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: sourceLang,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() => sourceLang = value);
                }
              },
              items: languages.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: targetLang,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    targetLang = value;
                  });
                }
              },
              items: languages.entries
                  .where((e) => e.key != 'auto')
                  .map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Container mainBody() {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1F1617).withAlpha(50),
            blurRadius: 40,
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Escribe algo o pulsa "Generar"...',
          border: OutlineInputBorder(borderSide: BorderSide.none),
        ),
        onSubmitted: (_) => _generar(),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(
        'Trilingo',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color.fromARGB(50, 0, 0, 0),
      centerTitle: true,
      elevation: 0.0,
    );
  }
}

class _TranslationsArea extends StatelessWidget {
  final Future<Translation>? future;
  final String targetLang;
  const _TranslationsArea({required this.future, required this.targetLang});

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const Center(
        child: Text(
          'Escribe algo o presiona "Generar traducción".',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return traducciones();
  }

  FutureBuilder<Translation> traducciones() {
    return FutureBuilder<Translation>(
    future: future,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError) {
        return SingleChildScrollView(
          child: _tileRich(
            'Error',
            const SizedBox.shrink(),
            const [],
            color: Colors.red.shade50,
            errorText: '${snap.error}',
          ),
        );
      }

      final t = snap.data!;
      return ListView(
        children: [
          _tileRich(
            'Original (${t.detectedLanguage})',
            TapWordText(
              text: t.originalText,
              targetLang: targetLang,
              sourceLang: t.detectedLanguage,
              ipaPerWord: t.originalIpa,
              wordStyle: wordStyle,
              ipaStyle: ipaStyle,
            ),
            t.originalIpa,
          ),
          const SizedBox(height: 12),
          _tileRich(
            'Traducción',
            TapWordText(
              text: t.translatedText,
              targetLang: t.detectedLanguage,
              sourceLang: targetLang,
              ipaPerWord: t.translatedIpa,
              wordStyle: wordStyle,
              ipaStyle: ipaStyle,
            ),
            t.translatedIpa,
          ),
        ],
      );
    },
  );
  }

  Widget _tileRich(
    String title,
    Widget content,
    List<String> unused, {
    Color? color,
    String? errorText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1F1617).withAlpha(30),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          if (errorText != null && errorText.isNotEmpty)
            Text(errorText, style: const TextStyle(color: Colors.red))
          else
            content,
        ],
      ),
    );
  }
}

class DiccionarioView extends StatelessWidget {
  const DiccionarioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: wordList()
    );
  }

  Widget wordList() {
    final box = Hive.box('word_cache');
    final Map<String, String> palabras = box.toMap().cast<String, String>();
    palabras.removeWhere((key, _) {
      final p = key.split("::");
      if (p.length != 3) return true;
      return p[1] == p[2];
    });

    if(palabras.isEmpty) return const Text('Sin palabras');

    return ListView(
      children: palabras.entries.map((e) => 
      ListTile(title: Text('${e.key.substring(0, e.key.indexOf('::'))} = ${e.value}'), subtitle: Text(e.key.substring(e.key.indexOf("::") + 2, e.key.length).replaceAll('::', ' -> ')))
    ).toList()
    );
  }
}