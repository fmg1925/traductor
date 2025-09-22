import 'package:flutter/material.dart';
import '../entities/translation.dart';
import 'package:traductor/domain/providers/data_provider.dart';
import '../partials/tap_word_text.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Colors.pinkAccent,
      body: Column(
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
                targetLang: targetLang),
            ),
          ),
        ],
      ),
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

  Padding languageDropdown() {
    return 
    Padding(
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
                    if(value != null) {
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
                )
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
  final String targetLang; // para traducir palabras al tocar
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
              Text('${snap.error}'),
              color: Colors.red.shade50,
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
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            _tileRich(
              'Traducción',
              TapWordText(
                text: t.translatedText,
                targetLang: 'en',
                sourceLang: t.detectedLanguage,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tileRich(String title, Widget content, {Color? color}) {
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
          content,
        ],
      ),
    );
  }
}
