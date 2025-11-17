import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traductor/helpers/error_parser.dart';
import 'package:traductor/helpers/force_web_speech_lang.dart';
import 'package:traductor/helpers/tts.dart';
import 'package:traductor/main.dart';
import 'package:traductor/pages/diccionario_view.dart';
import 'package:traductor/pages/ipa_grid.dart';
import 'package:traductor/pages/practice_view.dart';
import 'package:traductor/partials/tile_rich.dart';
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
String tipoGeneracion = "frase";
bool _ocrResult = false;

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

  late String lastTranslation;
  late String lastSourceLang;
  late String lastTargetLang;
  bool retranslateReady = false;

  int index = 0;

  final SpeechToText _speechToText = SpeechToText();
  final ValueNotifier<bool> _speechEnabled = ValueNotifier(false);
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
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled.value = await _speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;
        },
        onError: (e) {
          if (!mounted) return;
          final t = AppLocalizations.of(context);
          final langs = languages(context);
          final langName = langs[sourceLang];
          switch (e.errorMsg) {
            case 'not-allowed':
              PopUp.showPopUp(context, t.error, t.not_allowed);
              break;
            case 'network':
              PopUp.showPopUp(context, t.error, t.unsupported_browser);
              break;
            case 'no-speech':
              PopUp.showPopUp(context, t.error, t.no_mic_input);
              break;
            case 'no-match':
              PopUp.showPopUp(context, t.error, t.no_match(langName!));
              break;
            default:
              PopUp.showPopUp(context, t.error, t.error_stt(e));
              break;
          }
          setState(() {
            _speechListening = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _speechListening = false;
        _speechEnabled.value = false;
      });
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<bool> _isSpeechToTextLanguageInstalled(String language) async {
    final locales = await _speechToText.locales();
    language = language.substring(0, 2);
    for (var locale in locales) {
      if (locale.localeId.substring(0, 2) == language) return true;
    }
    return false;
  }

  Future<void> _startListening() async {
    if (!mounted || !_speechEnabled.value) return;
    if (_speechToText.isListening || _speechListening) return;
    try {
      _speechListening = true;
      forceWebSpeechLang(ttsLocaleFor(targetLang));
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          localeId: ttsLocaleFor(sourceLang),
          listenMode: ListenMode.confirmation,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          cancelOnError: true,
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechListening = false;
        });
      }
    }
  }

  Future<void> _stopListening() async {
    if (!mounted || !_speechEnabled.value) return;
    try {
      await _speechToText.stop();
    } catch (e) {
      if (!mounted) return;
      await _speechToText.cancel();
    } finally {
      if (mounted) {
        setState(() {
          _speechListening = false;
        });
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _controller.text = result.recognizedWords;
    if (isWindowsDesktop) {
      _speechListening = false;
      _speechToText.stop();
    }
    if (result.finalResult) {
      setState(() => _speechListening = false);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    try {
      _speechToText.cancel();
    } catch (_) {}
    try {
      tts.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _generar() {
  final text = _controller.text.trim();
  final future = text.isNotEmpty
      ? fetchTranslationFor(provider, text, sourceLang, targetLang)
      : fetchTranslation(provider, sourceLang, targetLang, tipoGeneracion);

  setState(() {
    translationFuture = future;    // Future<Translation>
    retranslateReady = false;      // no listo hasta completar
    lastSourceLang = sourceLang;
    lastTargetLang = targetLang;
  });

  future.then((res) {
    if (!mounted) return;
    setState(() {
      lastTranslation = res.originalText;
      lastSourceLang = res.detectedLanguage;
      lastTargetLang = res.target;
      retranslateReady = true;
    });
  }).catchError((_) {
    if (!mounted) return;
    setState(() => retranslateReady = false);
  });
}

  void _retraducir() {
    setState(() {
      translationFuture = retranslate(
        provider,
        lastTranslation,
        lastSourceLang,
        lastTargetLang,
      );
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
    _ocrResult = true;
    final x = await pickPhotoUniversal();
    if (x == null) return;

    try {
      final bytes = await x.readAsBytes();
      setState(() {
        translationFuture = ocrFromBytes(
          provider: provider,
          bytes: bytes,
          originalLanguage: sourceLang,
          target: targetLang,
        );
      });
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        PopUp.showPopUp(context, t.error, '${t.error_ocr}: ${e.toString()}');
        return;
      }
      setState(() {
        translationFuture = Future.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: appBar(),
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            mainColumn(),
            PracticeView(
              speechToText: _speechToText,
              provider: provider,
              initialSourceLang: sourceLang,
              initialTargetLang: targetLang,
              speechEnabled: _speechEnabled,
            ),
            const IpaGrid(),
            const DiccionarioView(),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavBar(),
    );
  }

  AppBar appBar() {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        'Trilingo',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(offset: Offset(-1, -1), color: Colors.black),
            Shadow(offset: Offset( 1, -1), color: Colors.black),
            Shadow(offset: Offset( 1,  1), color: Colors.black),
            Shadow(offset: Offset(-1,  1), color: Colors.black),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.tertiary,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      actions: [themeModeMenu(), const SizedBox(width: 8), localeDropdown()],
    );
  }

  Widget themeModeMenu() {
    final box = Hive.box<String>('prefs');
    final current = (box.get('themeMode') ?? 'system').toLowerCase();
    final isLight = current == 'light';
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: t.theme,
      color: scheme.primary,
      icon: Icon(Icons.brightness_6, color: isLight ? Colors.black87 : null),
      onSelected: (v) => box.put('themeMode', v),
      itemBuilder: (ctx) => [
        CheckedPopupMenuItem(
          value: 'system',
          checked: current == 'system',
          child: Text(t.system),
        ),
        CheckedPopupMenuItem(
          value: 'light',
          checked: current == 'light',
          child: Text(t.light),
        ),
        CheckedPopupMenuItem(
          value: 'dark',
          checked: current == 'dark',
          child: Text(t.dark),
        ),
      ],
    );
  }

  Padding localeDropdown() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 150,
            height: 35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLocale,
                    isExpanded: true,
                    itemHeight: 48,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: scheme.primary,
                    iconEnabledColor: scheme.onSurfaceVariant,
                    iconDisabledColor: theme.disabledColor,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                    // slightly denser
                    isDense: true,
                    menuMaxHeight: 320,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedLocale = value);
                      Hive.box<String>('prefs').put('locale', value);
                    },
                    items: locales(context).entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(
                          e.value,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Container mainBody() {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.15),
            blurRadius: 40,
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _generar(),
        style: TextStyle(color: scheme.onPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: scheme.tertiaryContainer,
          hintText: t.main_hint,
          counterStyle: TextStyle(
          color: scheme.tertiaryFixed, // color principal del texto
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(-0.25, -0.5), color: Colors.black),
            Shadow(offset: Offset( 0.25, -0.5), color: Colors.black),
            Shadow(offset: Offset( 0.25,  0.5), color: Colors.black),
            Shadow(offset: Offset(-0.25,  0.5), color: Colors.black),
          ],
        ),
          border: OutlineInputBorder(
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
            onPressed: !_speechEnabled.value
                ? null
                : () async {
                    if (_speechListening) {
                      await _stopListening();
                    } else {
                      if (!await _isSpeechToTextLanguageInstalled(
                        ttsLocaleFor(sourceLang),
                      )) {
                        if (!mounted) return;
                        final langs = languages(context);
                        final langName = langs[sourceLang];
                        PopUp.showPopUp(
                          context,
                          t.error,
                          t.language_not_installed(langName!),
                        );
                        setState(() {});
                      } else {
                        await _startListening();
                      }
                    }
                  },
          ),
        ),
        maxLength: 50,
        cursorColor: scheme.secondary,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget buildDrop({
      required String value,
      required void Function(String?) onChanged,
      required Iterable<MapEntry<String, String>> items,
    }) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            underline: const SizedBox.shrink(),
            dropdownColor: scheme.primary,
            iconEnabledColor: scheme.onSurfaceVariant,
            iconDisabledColor: theme.disabledColor,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
            items: items.map((e) {
              return DropdownMenuItem<String>(
                value: e.key,
                child: Text(
                  e.value,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: buildDrop(
              value: sourceLang,
              onChanged: (v) {
                if (v != null) setState(() => sourceLang = v);
              },
              items: languages(context).entries,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: buildDrop(
              value: targetLang,
              onChanged: (v) {
                if (v != null) setState(() => targetLang = v);
              },
              items: languages(context).entries.where((e) => e.key != 'auto'),
            ),
          ),
        ],
      ),
    );
  }

  Padding generarButton() {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 420;

          final ocrBtn = FilledButton.icon(
            onPressed: _ocr,
            icon: const Icon(Icons.document_scanner),
            label: const Text('OCR'),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                scheme.secondaryContainer,
              ),
            ),
          );

          if (!isNarrow) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              onPressed: _generar,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                _controller.text.isEmpty
                                    ? t.generate_translation
                                    : t.translate,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.secondaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    bottomLeft: Radius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              enabled: retranslateReady,
                              onSelected: (v) { if (v == 'retranslate') _retraducir(); },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'retranslate',
                                  child: ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.autorenew),
                                    title: Text(
                                      t.retraducir,
                                    ),
                                  ),
                                ),
                              ],
                              child: FilledButton(
                                onPressed: null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.secondaryContainer,
                                  foregroundColor: scheme.onSecondaryContainer,
                                  disabledBackgroundColor: retranslateReady ? scheme.secondaryContainer : scheme.onTertiaryContainer,
                                  disabledForegroundColor: scheme.onSecondaryContainer,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(40, 40),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(14), bottomRight: Radius.circular(14),
                                    ),
                                  ),
                                ),
                                child: Icon(Icons.arrow_drop_down, color: retranslateReady ? scheme.onPrimary : scheme.onInverseSurface),
                            ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 8),
                        tipoFraseDropdown(scheme, Theme.of(context), t),
                      ],
                    ),
                  ],
                ),
                ocrBtn,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _generar,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        _controller.text.isEmpty
                            ? t.generate_translation
                            : t.translate,
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          scheme.secondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  tipoFraseDropdown(scheme, Theme.of(context), t),
                ],
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: ocrBtn),
            ],
          );
        },
      ),
    );
  }

  Material tipoFraseDropdown(
    ColorScheme scheme,
    ThemeData theme,
    AppLocalizations t,
  ) {
    return Material(
      color: scheme.onTertiaryFixedVariant,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 5),
        child: DropdownButton<String>(
          isDense: true,
          value: tipoGeneracion,
          onChanged: (v) => setState(() => tipoGeneracion = v!),
          dropdownColor: scheme.primary,
          iconEnabledColor: scheme.onSurfaceVariant,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimary),
          items: [
            DropdownMenuItem(value: 'frase', child: Text(t.frase)),
            DropdownMenuItem(value: 'sujeto', child: Text(t.sujeto)),
            DropdownMenuItem(value: 'verbo', child: Text(t.verbo)),
            DropdownMenuItem(value: 'color', child: Text(t.color)),
            DropdownMenuItem(value: 'familia', child: Text(t.familia)),
            DropdownMenuItem(value: 'adjetivo', child: Text(t.adjetivo)),
            DropdownMenuItem(value: 'direccion', child: Text(t.direccion)),
          ],
        ),
      ),
    );
  }

  NavigationBar bottomNavBar() {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return NavigationBar(
      backgroundColor: scheme.primary,
      selectedIndex: index,
      indicatorColor: scheme.onTertiary,
      onDestinationSelected: (i) {
        isNavigating = true;
        setState(() => index = i);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            isNavigating = false;
          });
        });
      },
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
          icon: Icon(Icons.headphones),
          selectedIcon: Icon(Icons.headphones_sharp),
          label: 'IPA',
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

class TranslationsArea extends StatefulWidget {
  final Future<Translation>? future;
  final String targetLang;
  const TranslationsArea({
    super.key,
    required this.future,
    required this.targetLang,
  });

  @override
  State<TranslationsArea> createState() => _TranslationsAreaState();
}

class _TranslationsAreaState extends State<TranslationsArea> {
  bool _errorShown = false;
  Future<Translation>? _lastFuture;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (widget.future != _lastFuture) {
      _lastFuture = widget.future;
      _errorShown = false;
    }

    if (widget.future == null) {
      return Center(
        child: Text(
          t.main_hint,
          style: TextStyle(color: Colors.white, fontSize: 24),
          textAlign: TextAlign.center,
        ),
      );
    }

    return traducciones();
  }

  FutureBuilder<Translation> traducciones() {
    return FutureBuilder<Translation>(
      future: widget.future,
      builder: (context, snap) {
        final t = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: scheme.onPrimary),
          );
        }

        if (snap.hasData) {
          if (snap.connectionState == ConnectionState.done &&
              snap.data!.originalText.trim().isEmpty &&
              _ocrResult) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _ocrResult = false;
              PopUp.showPopUp(context, t.error, t.no_text_in_ocr);
            });
            return const SizedBox.shrink();
          }
        }

        if (snap.connectionState == ConnectionState.done &&
            (snap.hasError || !snap.hasData)) {
          if (!_errorShown) {
            _errorShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !isRebuilding && !isNavigating) {
                PopUp.showPopUp(
                  context,
                  t.error,
                  t.error_translation(
                    ErrorParser.parseError(snap.error.toString(), context),
                  ),
                );
              }
            });
          }
          return const SizedBox.shrink();
        }

        final item = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            TileRich(
              title: '${t.original} (${item.detectedLanguage})',
              body: TapWordText(
                text: item.originalText,
                targetLang: widget.targetLang,
                sourceLang: item.detectedLanguage,
                ipaPerWord: item.originalIpa,
                romanizationPerWord: item.originalRomanization,
                wordStyle: wordStyle(context),
                ipaStyle: ipaStyle(context),
              ),
              color: scheme.primary,
              buttons: rightButtons(
                t,
                () async {
                  if (tts.speaking.value) {
                    await tts.stop();
                    return;
                  }
                  final langs = languages(context);
                  final langName = langs[item.detectedLanguage];

                  final available = await tts.isLanguageAvailable(
                    ttsLocaleFor(item.detectedLanguage),
                  );

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
                item.originalText,
                context,
              ),
              copyText: item.originalText,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: tts.speaking,
              builder: (context, isListening, _) {
                return TileRich(
                  title: t.translation,
                  body: TapWordText(
                    text: item.translatedText,
                    targetLang: item.detectedLanguage,
                    sourceLang: item.target,
                    ipaPerWord: item.translatedIpa,
                    romanizationPerWord: item.translatedRomanization,
                    wordStyle: wordStyle(context),
                    ipaStyle: ipaStyle(context),
                  ),
                  color: scheme.primary,
                  buttons: rightButtons(
                    t,
                    () async {
                      if (tts.speaking.value) {
                        await tts.stop();
                        return;
                      }
                      final langs = languages(context);
                      final langName = langs[item.target];

                      final available = await tts.isLanguageAvailable(
                        ttsLocaleFor(item.target),
                      );

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
                    item.translatedText,
                    context,
                  ),
                  copyText: item.translatedText,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
