import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traductor/helpers/tts.dart';
import '../entities/translation.dart';
import 'package:traductor/domain/providers/data_provider.dart';
import '../partials/tap_word_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../network/ocr_client.dart';

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

String _ttsLocaleFor(String code) {
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

final tts = Tts();

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
  void initState() {
    super.initState();
    tts.init(
      onStateChanged: (_) {
        if (mounted) setState(() {});
      },
    );
  }

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

  Future<XFile?> pickPhotoUniversal() async {
    final picker = ImagePicker();

    return picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
  }

  Future<void> _ocr() async {
    final x = await pickPhotoUniversal();
    if (x == null) return;

    try {
      final bytes = await x.readAsBytes();
      setState(() {
        translationFuture = ocrFromBytes(
          provider: provider,
          bytes: bytes,
          target: targetLang,
        );
      });
    } catch (e) {
      debugPrint('OCR error: $e');
      setState(() {
        translationFuture = Future.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Colors.pinkAccent,
      body: IndexedStack(
        index: index,
        children: [
          mainColumn(),
          PracticeView(
            provider: provider,
            initialSourceLang: sourceLang,
            initialTargetLang: targetLang,
          ),
          const DiccionarioView(),
        ],
      ),
      bottomNavigationBar: bottomNavBar(),
    );
  }

  NavigationBar bottomNavBar() {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.translate),
          selectedIcon: Icon(Icons.translate_outlined),
          label: 'Traducir',
        ),
        NavigationDestination(
          icon: Icon(Icons.mic),
          selectedIcon: Icon(Icons.mic_sharp),
          label: 'Practicar',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_outlined),
          label: 'Diccionario',
        ),
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
    final isEmpty = _controller.text.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _generar,
            icon: const Icon(Icons.play_arrow),
            label: Text(isEmpty ? 'Generar traducción' : 'Traducir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
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
              itemHeight: 60,
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
              items: languages.entries.where((e) => e.key != 'auto').map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
            ),
          ),
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
        onChanged: (_) => setState(() {}),
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
              context,
              'Error',
              const SizedBox.shrink(),
              color: Colors.red.shade50,
              errorText: '${snap.error}',
              onTts: () {},
            ),
          );
        }

        final t = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _tileRich(
              context,
              'Original (${t.detectedLanguage})',
              TapWordText(
                text: t.originalText,
                targetLang: targetLang,
                sourceLang: t.detectedLanguage,
                ipaPerWord: t.originalIpa,
                wordStyle: wordStyle,
                ipaStyle: ipaStyle,
              ),
              onTts: () {
                tts.changeLanguage(_ttsLocaleFor(t.detectedLanguage));
                tts.speak(t.originalText);
              },
            ),
            const SizedBox(height: 12),
            _tileRich(
              context,
              'Traducción',
              TapWordText(
                text: t.translatedText,
                targetLang: t.detectedLanguage,
                sourceLang: targetLang,
                ipaPerWord: t.translatedIpa,
                wordStyle: wordStyle,
                ipaStyle: ipaStyle,
              ),
              onTts: () {
                tts.changeLanguage(_ttsLocaleFor(targetLang));
                tts.speak(t.translatedText);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _tileRich(
    BuildContext context,
    String title,
    Widget body, {
    Color? color,
    String? errorText,
    required VoidCallback onTts, // ← nuevo
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                icon: Icon(tts.getState() ? Icons.stop : Icons.volume_up),
                tooltip: tts.getState() ? 'Detener' : 'Escuchar',
                onPressed: onTts,
              ),
            ],
          ),
          const SizedBox(height: 8),
          body,
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(errorText, style: TextStyle(color: Colors.red.shade700)),
          ],
        ],
      ),
    );
  }
}

class DiccionarioView extends StatelessWidget {
  const DiccionarioView({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<String>('word_cache');

    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: ValueListenableBuilder<Box<String>>(
        valueListenable: box.listenable(),
        builder: (context, b, _) {
          final palabras = Map<String, String>.from(b.toMap());

          palabras.removeWhere((key, _) {
            final p = key.split('::');
            return p.length != 3 || p[1] == p[2];
          });

          if (palabras.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                child: Text(
                  'Sin palabras en el diccionario',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            );
          }

          final entries = palabras.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              final parts = e.key.split('::');
              final word = parts[0];
              final path = '${parts[1]} -> ${parts[2]}';
              return ListTile(
                title: Text('$word = ${e.value}'),
                subtitle: Text(path),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => b.delete(e.key),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PracticeView extends StatefulWidget {
  const PracticeView({
    super.key,
    this.provider,
    this.initialSourceLang = 'auto',
    this.initialTargetLang = 'es',
  });

  final DataProvider? provider;
  final String initialSourceLang;
  final String initialTargetLang;

  @override
  State<StatefulWidget> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  late final DataProvider provider;
  late String sourceLang;
  late String targetLang;

  Future<Translation>? translationFuture;

  @override
  void initState() {
    super.initState();
    provider = widget.provider ?? DataProvider();
    sourceLang = widget.initialSourceLang;
    targetLang = widget.initialTargetLang;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _generar() {
    setState(() {
      translationFuture = fetchTranslation(provider, sourceLang, targetLang);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: Column(
        children: [
          languageDropdown(),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1F1617).withAlpha(50),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _generar, child: const Text('Generar')),
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
              itemHeight: 60,
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
              items: languages.entries.where((e) => e.key != 'auto').map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
