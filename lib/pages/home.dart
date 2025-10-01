import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traductor/helpers/tts.dart';
import 'package:traductor/main.dart';
import 'package:traductor/pages/diccionario_view.dart';
import 'package:traductor/pages/practice_view.dart';
import '../entities/translation.dart';
import 'package:traductor/domain/providers/data_provider.dart';
import '../partials/tap_word_text.dart';
import '../network/ocr_client.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../helpers/popup.dart';
import 'package:traductor/l10n/app_localizations.dart';

final tts = Tts();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final provider = DataProvider();
  AppLocalizations get t => AppLocalizations.of(context);

  String sourceLang = 'auto';
  String targetLang = 'es';
  Future<Translation>? translationFuture;

  int index = 0;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechListening = false;

  final box = Hive.box<String>('prefs');
  late String selectedLocale = box.get('locale', defaultValue: 'en')!;

  @override
  void initState() {
    super.initState();
    tts.init(
      onStateChanged: (_) {
        if (mounted) setState(() {});
      },
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (s) {
        if (s == 'notListening') {
          _speechListening = false;
        }
      },
      onError: (e) => PopUp.showPopUp(
        context,
        'Error',
        'Error initializing TTS ${e.toString()}',
      ),
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechEnabled || _speechListening) return;

    _speechListening = true;
    if (mounted) setState(() {});

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: sourceLang,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
      pauseFor: const Duration(seconds: 5),
    );
    setState(() {});
  }

  Future<void> _stopListening() async {
    if (!_speechListening) return;
    await _speechToText.stop();
    _speechListening = false;
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _controller.text = result.recognizedWords;
    if (result.finalResult) _speechListening = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _speechToText.stop();
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
      if (mounted) {
        PopUp.showPopUp(
          context,
          'Error',
          'Error processing OCR: ${e.toString()}',
        );
      }
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
      actions: [localeDropdown()],
    );
  }

  Padding localeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 150,
            height: 35,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLocale,
                itemHeight: 48,
                padding: EdgeInsets.symmetric(horizontal: 20),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedLocale = value);
                  Hive.box<String>('prefs').put('locale', value);
                },
                items: locales(context).entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
        onSubmitted: (_) => _generar(),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: t.main_hint,
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: IconButton(
            tooltip: _speechListening ? t.stop : t.start,
            icon: Icon(_speechListening ? Icons.mic_none : Icons.mic),
            onPressed: !_speechEnabled
                ? null
                : () => _speechListening ? _stopListening() : _startListening(),
          ),
        ),
      ),
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
            child: TranslationsArea(
              future: translationFuture,
              targetLang: targetLang,
            ),
          ),
        ),
      ],
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
              items: languages(context).entries.map((e) {
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
              itemHeight: 60,
              items: languages(context).entries.where((e) => e.key != 'auto').map((e) {
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
            label: Text(isEmpty ? t.generate_translation : t.translate),
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

  NavigationBar bottomNavBar() {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.translate),
          selectedIcon: Icon(Icons.translate_outlined),
          label: t.translate,
        ),
        NavigationDestination(
          icon: Icon(Icons.mic),
          selectedIcon: Icon(Icons.mic_sharp),
          label: t.practice,
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_outlined),
          label: t.dictionary,
        ),
      ],
    );
  }
}

class TranslationsArea extends StatelessWidget {
  final Future<Translation>? future;
  final String targetLang;
  const TranslationsArea({
    super.key,
    required this.future,
    required this.targetLang,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (future == null) {
      return Center(
        child: Text(
          t.main_hint,
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
        final t = AppLocalizations.of(context);
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            PopUp.showPopUp(
              context,
              t.error,
              '${t.error_translation}: ${snap.error}',
            );
          });
          return SingleChildScrollView(
            child: _tileRich(
              context,
              'Error',
              const SizedBox.shrink(),
              color: Colors.red.shade50,
              errorText: '${snap.error}',
              onTts: () {},
              copyText: snap.error.toString(),
            ),
          );
        }

        final item = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _tileRich(
              context,
              '${t.original} (${item.detectedLanguage})',
              TapWordText(
                text: item.originalText,
                targetLang: targetLang,
                sourceLang: item.detectedLanguage,
                ipaPerWord: item.originalIpa,
                wordStyle: wordStyle,
                ipaStyle: ipaStyle,
              ),
              onTts: () {
                tts.changeLanguage(ttsLocaleFor(item.detectedLanguage));
                tts.speak(item.originalText);
              },
              copyText: item.originalText,
            ),
            const SizedBox(height: 12),
            _tileRich(
              context,
              t.translation,
              TapWordText(
                text: item.translatedText,
                targetLang: item.detectedLanguage,
                sourceLang: item.target,
                ipaPerWord: item.translatedIpa,
                wordStyle: wordStyle,
                ipaStyle: ipaStyle,
              ),
              onTts: () {
                tts.changeLanguage(ttsLocaleFor(item.target));
                tts.speak(item.translatedText);
              },
              copyText: item.translatedText
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
  required VoidCallback onTts,
  required String copyText,
}) {
  final t = AppLocalizations.of(context);
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
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton.filledTonal(
              icon: Icon(tts.getState() ? Icons.stop : Icons.volume_up),
              tooltip: tts.getState() ? t.stop : t.listen,
              onPressed: onTts,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyText));
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.copied)),
              );
            },
            icon: const Icon(Icons.copy_all),
            label: Text(t.copy),
          ),
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
