import 'package:flutter/foundation.dart';
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
import 'package:universal_io/io.dart' show Platform;

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

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechListening = false;

  final box = Hive.box<String>('prefs');
  late String selectedLocale = box.get('locale', defaultValue: 'en')!;

  final bool isWindowsDesktop = Platform.isWindows && !kIsWeb;

  @override
  void initState() {
    super.initState();
    tts.init(
      onStateChanged: (_) {
        if (mounted) setState(() {});
      },
    );
    if(!isWindowsDesktop) _initSpeech(); // Iniciar en todos menos windows
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {});
        },
        onError: (e) {
          if (!mounted) return;
          final t = AppLocalizations.of(context);
          PopUp.showPopUp(context, t.error, t.error_stt(e.errorMsg));
          setState(() {});
        },
      );
    } catch (_) {
      _speechEnabled = false;
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _startListening() async {
  if (!mounted || !_speechEnabled || _speechToText.isListening) return;
  try {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: sourceLang,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() {});
  } catch (_) {
    setState(() {});
  }
}

  Future<void> _stopListening() async {
    if (!mounted || !_speechEnabled || !_speechToText.isListening) return;
    try {
      await _speechToText.stop();
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        PopUp.showPopUp(context, t.error, t.error_stt(e.toString()));
        setState(() {
          _speechListening = false;
        });
      }
    } finally {
      setState(() {
        _speechListening = false;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _controller.text = result.recognizedWords;
    if(result.finalResult) {
      _speechListening = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    try { _speechToText.cancel(); } catch (_) {}
    try { tts.dispose(); } catch (_) {}
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
        final t = AppLocalizations.of(context);
        PopUp.showPopUp(
          context,
          t.error,
          '${t.error_ocr}: ${e.toString()}',
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
    final t = AppLocalizations.of(context);
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
            tooltip: !isWindowsDesktop ? _speechListening ? t.stop : t.start : t.feature_not_available_windows,
            icon: Icon(_speechListening ? Icons.mic_none : Icons.mic, color: isWindowsDesktop ? Colors.grey : null),
            onPressed: !_speechEnabled
                ? null
                : () async {
                  if(isWindowsDesktop) {
                    PopUp.showPopUp(context, t.feature_not_available, t.feature_not_available_windows);
                    return;
                  } 
                  _speechListening ? await _stopListening() : await _startListening(); },
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
              items: languages(context).entries
                  .where((e) => e.key != 'auto')
                  .map((e) {
                    return DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Padding generarButton() {
    final t = AppLocalizations.of(context);
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
    final t = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        if (isWindowsDesktop && i == 1) {
          PopUp.showPopUp(context, t.feature_not_available, t.feature_not_available_windows);
          return;
        }
        setState(() => index = i);
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.translate),
          selectedIcon: Icon(Icons.translate_outlined),
          label: t.translate,
        ),
        NavigationDestination(
          icon: Icon(Icons.mic, color: isWindowsDesktop ? Colors.grey : null),
          selectedIcon: Icon(Icons.mic_sharp, color: isWindowsDesktop && !kIsWeb ? Colors.grey : null),
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
              t.error,
              const SizedBox.shrink(),
              color: Colors.red.shade50,
              errorText: '${snap.error}',
              onTts: () {},
              copyText: snap.error.toString(),
            ),
          );
        }
        if(!snap.hasData) {
          return _tileRich(context, t.error, const SizedBox.shrink(), onTts: () {}, copyText: '');
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
              onTts: () async {
                if(tts.getState() == true) {
                  await tts.stop();
                  return;
                }
                final langs = languages(context);
                final langName = langs[item.detectedLanguage];

                final available = await tts.isLanguageAvailable(ttsLocaleFor(item.detectedLanguage));
                if (!context.mounted) return;

                if (available != true) {
                  PopUp.showPopUp(
                    context,
                    t.missing_language(langName!),
                    t.language_not_installed(langName),
                  );
                  return;
                }

                await tts.changeLanguage(ttsLocaleFor(item.detectedLanguage));
                await tts.speak(item.originalText);
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
              onTts: () async {
                if(tts.getState() == true) {
                  await tts.stop();
                  return;
                }
                final langs = languages(context);
                final langName = langs[item.target];

                final available = await tts.isLanguageAvailable(ttsLocaleFor(item.target));

                if (!context.mounted) return;

                if (available != true) {
                  PopUp.showPopUp(
                    context,
                    t.missing_language(langName!),
                    t.language_not_installed(langName),
                  );
                  return;
                }

                await tts.changeLanguage(ttsLocaleFor(item.target));
                await tts.speak(item.translatedText);
              },
              copyText: item.translatedText,
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
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.05),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: true,
                    applyHeightToLastDescent: false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(right: 50),
                child: body,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText, style: TextStyle(color: Colors.red.shade700)),
              ],
            ],
          ),
          rightButtons(t, onTts, copyText, context),
        ],
      ),
    );
  }

  Positioned rightButtons(AppLocalizations t, VoidCallback onTts, String copyText, BuildContext context) {
    return Positioned(
          top: -5,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                icon: Icon(tts.getState() ? Icons.stop : Icons.volume_up),
                tooltip: tts.getState() ? t.stop : t.listen,
                onPressed: onTts,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 50,
                  height: 50,
                ),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: 4),
              IconButton.filledTonal(
                icon: const Icon(Icons.copy_all),
                tooltip: t.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: copyText));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(t.copied)));
                },
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 50,
                  height: 50,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
  }
}
