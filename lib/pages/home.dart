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
    if (!isWindowsDesktop) _initSpeech(); // Iniciar en todos menos windows
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled.value = await _speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {});
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

  Future<void> _startListening() async {
    if (!mounted || !_speechEnabled.value) return;
    if (_speechToText.isListening) return;
    try {
      _speechListening = true;
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: ttsLocaleFor(sourceLang),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          partialResults: true,
          cancelOnError: true,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 10),
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
      await _speechToText.cancel();
    } catch (e) {
      if (!mounted) return;
      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _speechListening = false;
          _speechToText.cancel();
        });
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _controller.text = result.recognizedWords;
    if (result.finalResult) {
      _speechListening = false;
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
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.tertiary,
      centerTitle: true,
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
      tooltip: 'Theme',
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
            tooltip: !isWindowsDesktop
                ? _speechListening
                      ? t.stop
                      : t.start
                : t.feature_not_available_windows,
            icon: Icon(
              _speechListening ? Icons.mic_none : Icons.mic,
              color: isWindowsDesktop ? Colors.grey : null,
            ),
            onPressed: !_speechEnabled.value
                ? null
                : () async {
                    if (isWindowsDesktop) {
                      PopUp.showPopUp(
                        context,
                        t.feature_not_available,
                        t.feature_not_available_windows,
                      );
                      return;
                    }
                    _speechListening
                        ? await _stopListening()
                        : await _startListening();
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
    final isEmpty = _controller.text.trim().isEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FilledButton.icon(
            onPressed: _generar,
            icon: const Icon(Icons.play_arrow),
            label: Text(isEmpty ? t.generate_translation : t.translate),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                scheme.secondaryContainer,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _ocr,
            icon: const Icon(Icons.document_scanner),
            label: const Text('OCR'),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                scheme.secondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  NavigationBar bottomNavBar() {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return NavigationBar(
      backgroundColor: scheme.primary,
      selectedIndex: index,
      indicatorColor: Theme.of(context).colorScheme.onTertiary,
      onDestinationSelected: (i) {
        if (isWindowsDesktop && i == 1) {
          PopUp.showPopUp(
            context,
            t.feature_not_available,
            t.feature_not_available_windows,
          );
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
          selectedIcon: Icon(
            Icons.mic_sharp,
            color: isWindowsDesktop && !kIsWeb ? Colors.grey : null,
          ),
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
          style: TextStyle(color: Colors.white, fontSize: 24),
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
        final scheme = Theme.of(context).colorScheme;
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: scheme.onPrimary),
          );
        }
        if (snap.hasError) {
          final t = AppLocalizations.of(context);
          return SingleChildScrollView(
            child: _tileRich(
              context,
              t.error,
              const SizedBox.shrink(),
              errorText: t.error_translation('${snap.error}'),
              color: scheme.primary,
              onTts: () {},
              copyText: snap.error.toString(),
            ),
          );
        }
        if (!snap.hasData) {
          return _tileRich(
            context,
            t.error,
            foregroundColor: scheme.error,
            const SizedBox.shrink(),
            onTts: () {},
            copyText: '',
          );
        }
        final item = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _tileRich(
              context,
              '${t.original} (${item.detectedLanguage})',
              color: scheme.primary,
              TapWordText(
                text: item.originalText,
                targetLang: targetLang,
                sourceLang: item.detectedLanguage,
                ipaPerWord: item.originalIpa,
                wordStyle: wordStyle(context),
                ipaStyle: ipaStyle(context),
              ),
              onTts: () async {
                if (tts.getState() == true) {
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
              copyText: item.originalText,
            ),
            const SizedBox(height: 12),
            _tileRich(
              context,
              t.translation,
              color: scheme.primary,
              TapWordText(
                text: item.translatedText,
                targetLang: item.detectedLanguage,
                sourceLang: item.target,
                ipaPerWord: item.translatedIpa,
                wordStyle: wordStyle(context),
                ipaStyle: ipaStyle(context),
              ),
              onTts: () async {
                if (tts.getState() == true) {
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
    Color? foregroundColor,
    String? errorText,
    required VoidCallback onTts,
    required String copyText,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = color ?? scheme.surface;
    final fg = foregroundColor ?? scheme.onSurface;

    const railW = 48.0;
    const gap = 12.0;

    final t = AppLocalizations.of(context);

    final localTheme = theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: bg,
        displayColor: fg,
        decorationColor: fg,
      ),
    );

    return maxWidth(
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Theme(
          data: localTheme,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.05,
                        color: theme.colorScheme.onPrimary,
                      ),
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: true,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                    const SizedBox(height: gap),
                    body,
                    if (errorText != null) ...[
                      const SizedBox(height: gap),
                      Text(errorText, style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: gap),
              SizedBox(
                width: railW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton.filledTonal(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          tts.getState() ? Icons.stop : Icons.volume_up,
                          key: ValueKey(tts.getState()),
                        ),
                      ),
                      tooltip: tts.getState() ? t.stop : t.listen,
                      onPressed: onTts,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: railW,
                        height: railW,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 8),
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
                        width: railW,
                        height: railW,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Positioned rightButtons(
    AppLocalizations t,
    VoidCallback onTts,
    String copyText,
    BuildContext context,
  ) {
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
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
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
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget maxWidth({required Widget child}) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    ),
  );
}
