import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:traductor/entities/translation.dart';
import 'package:traductor/helpers/error_parser.dart' show ErrorParser;
import 'package:traductor/helpers/force_web_speech_lang.dart';
import 'package:traductor/helpers/popup.dart';
import 'package:traductor/main.dart';
import 'package:traductor/pages/home.dart' show tts;
import 'package:traductor/partials/tap_word_text.dart';
import 'package:traductor/partials/tile_rich.dart';
import '../domain/providers/data_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:universal_io/io.dart';

class PracticeView extends StatefulWidget {
  const PracticeView({
    super.key,
    required this.speechToText,
    this.provider,
    this.initialSourceLang = 'auto',
    this.initialTargetLang = 'es',
    required this.speechEnabled,
  });

  final SpeechToText speechToText;
  final DataProvider? provider;
  final String initialSourceLang;
  final String initialTargetLang;
  final ValueListenable<bool> speechEnabled;

  @override
  State<StatefulWidget> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  late final DataProvider provider;

  late String sourceLang;
  late String targetLang;
  String _listeningText = '';
  double? _lastAccuracy;

  Future<Translation>? translationFuture;

  final bool isWindowsDesktop = Platform.isWindows && !kIsWeb;

  @override
  void initState() {
    super.initState();
    provider = widget.provider ?? DataProvider();
    sourceLang = widget.initialSourceLang;
    targetLang = widget.initialTargetLang;
  }

  Future<void> _startListening() async {
    if (!mounted ||
        !widget.speechEnabled.value ||
        widget.speechToText.isListening) {
      return;
    }
    try {
      if (kIsWeb) forceWebSpeechLang(ttsLocaleFor(targetLang));
      await widget.speechToText.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          localeId: ttsLocaleFor(targetLang),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          cancelOnError: true,
        ),
      );
      setState(() {});
    } catch (_) {
      setState(() {});
    }
  }

  Future<void> _stopListening() async {
    if (!mounted || !widget.speechEnabled.value) return;
    if (!widget.speechToText.isListening) return;

    try {
      await widget.speechToText.stop().timeout(
        const Duration(seconds: 1),
        onTimeout: () async {
          try {
            await widget.speechToText.cancel();
            setState(() {});
          } catch (_) {}
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    _listeningText = result.recognizedWords;
    if (result.finalResult &&
        translationFuture != null &&
        _listeningText.isNotEmpty) {
      try {
        final tr = await translationFuture!;
        final ref = _norm(tr.translatedText);
        final hyp = _norm(_listeningText);
        final refWords = ref.split(' ').where((w) => w.isNotEmpty).toList();
        final hypWords = hyp.split(' ').where((w) => w.isNotEmpty).toList();
        final edits = _levWords(refWords, hypWords);
        final wer = refWords.isEmpty ? 1.0 : edits / refWords.length;
        _lastAccuracy = (1 - wer).clamp(0.0, 1.0) * 100.0;
      } catch (_) {
        _lastAccuracy = null;
      }
      if (mounted) setState(() {});
    }
    if (mounted) setState(() {});
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  int _levWords(List<String> a, List<String> b) {
    final m = a.length, n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    final dp = List.generate(m + 1, (i) => List<int>.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[m][n];
  }

  @override
  void dispose() {
    try {
      widget.speechToText.cancel();
    } catch (_) {}
    super.dispose();
  }

  void _generar() {
    setState(() {
    translationFuture = fetchTranslation(provider, sourceLang, targetLang, 'frase');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
          FilledButton.icon(
            onPressed: _generar,
            label: Text(t.generate),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                scheme.secondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TranslationsArea(
                future: translationFuture,
                targetLang: targetLang,
                startListening: _startListening,
                stopListening: _stopListening,
                speechEnabled: widget.speechEnabled.value,
                speechListening: widget.speechToText.isListening,
                listeningText: _listeningText,
                lastAccuracy: _lastAccuracy,
              ),
            ),
          ),
        ],
      ),
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

    final srcItems = languages(
      context,
    ).entries.where((e) => e.key != 'auto').toList();

    final tgtItems = languages(
      context,
    ).entries.where((e) => e.key != 'auto').toList();

    String displaySource;
    if (srcItems.any((e) => e.key == sourceLang)) {
      displaySource = sourceLang;
    } else if (sourceLang == 'auto') {
      // Fallback local para esta página (elige el que prefieras)
      displaySource = srcItems.any((e) => e.key == 'en')
          ? 'en'
          : srcItems.first.key;
    } else {
      // si viene algo inválido, usa el primero válido
      displaySource = srcItems.first.key;
    }

    final displayTarget = tgtItems.any((e) => e.key == targetLang)
        ? targetLang
        : (tgtItems.any((e) => e.key == 'es') ? 'es' : tgtItems.first.key);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: buildDrop(
              value: displaySource,
              onChanged: (v) {
                if (v != null) setState(() => sourceLang = v);
              },
              items: srcItems,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: buildDrop(
              value: displayTarget,
              onChanged: (v) {
                if (v != null) setState(() => targetLang = v);
              },
              items: tgtItems,
            ),
          ),
        ],
      ),
    );
  }
}

class TranslationsArea extends StatefulWidget {
  final Future<Translation>? future;
  final String targetLang;
  final Future<void> Function() startListening;
  final Future<void> Function() stopListening;
  final bool speechEnabled;
  final bool speechListening;
  final String listeningText;
  final double? lastAccuracy;

  const TranslationsArea({
    super.key,
    required this.future,
    required this.targetLang,
    required this.startListening,
    required this.stopListening,
    required this.speechEnabled,
    required this.speechListening,
    required this.listeningText,
    this.lastAccuracy,
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
          t.generate_for_practice,
          style: const TextStyle(color: Colors.white, fontSize: 24),
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

        if (snap.connectionState == ConnectionState.done && (snap.hasError || !snap.hasData)) {
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

        final item = snap.data as Translation;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            originalText(context, t, item),
            const SizedBox(height: 12),
            translatedText(context, t, item),
            const SizedBox(height: 12),
            voiceDetection(context, t),
          ],
        );
      },
    );
  }

  Widget originalText(
    BuildContext context,
    AppLocalizations t,
    Translation item,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return TileRich(
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
    );
  }

  Widget translatedText(
    BuildContext context,
    AppLocalizations t,
    Translation item,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return TileRich(
      title: t.repeat_this_phrase,
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
      copyText: item.translatedText,
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
    );
  }

  Widget voiceDetection(BuildContext context, AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    final idleText = (widget.listeningText.isNotEmpty)
        ? '${widget.listeningText}'
              '${widget.lastAccuracy == null ? '' : '\n\n${t.accuracy}: ${widget.lastAccuracy!.toStringAsFixed(1)}%'}'
        : t.start;

    return TileRich(
      title: t.detected_words,
      body: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: !widget.speechEnabled
              ? null
              : () async {
                  if (widget.speechListening) {
                    await widget.stopListening();
                  } else {
                    await widget.startListening();
                  }
                },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),

            child: widget.speechListening
                ? Column(
                    key: const ValueKey('state_listening'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${t.listening}\n\n${widget.listeningText}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.stop_rounded, size: 48),
                    ],
                  )
                : Column(
                    key: const ValueKey('state_idle'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        idleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.mic, size: 48),
                    ],
                  ),
          ),
        ),
      ),
      color: scheme.primary,
    );
  }

  Widget rightButtons(
    AppLocalizations t,
    VoidCallback onTts,
    String copyText,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ValueListenableBuilder(
          valueListenable: tts.speaking,
          builder: (context, isSpeaking, _) {
            return IconButton.filledTonal(
              icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
              tooltip: isSpeaking ? t.stop : t.listen,
              onPressed: onTts,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 50, height: 50),
              visualDensity: VisualDensity.compact,
            );
          }
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
    );
  }
}
