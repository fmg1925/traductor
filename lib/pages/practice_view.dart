import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:traductor/entities/translation.dart';
import 'package:traductor/helpers/popup.dart';
import 'package:traductor/main.dart';
import 'package:traductor/pages/home.dart' show tts;
import 'package:traductor/partials/tap_word_text.dart';
import '../domain/providers/data_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:universal_io/io.dart';

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

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

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

    if (isWindowsDesktop) _initSpeech();
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
        localeId: targetLang,
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
    if (!mounted || !_speechEnabled) return;
    if (!_speechToText.isListening) return;

    try {
      await _speechToText.stop().timeout(
        const Duration(seconds: 1),
        onTimeout: () async {
          try {
            await _speechToText.cancel();
            setState(() {});
          } catch (_) {}
        },
      );
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        PopUp.showPopUp(context, t.error, t.error_stt(e.toString()));
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
      _speechToText.cancel();
    } catch (_) {}
    super.dispose();
  }

  void _generar() {
    setState(() {
      translationFuture = fetchTranslation(provider, sourceLang, targetLang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
          ElevatedButton(onPressed: _generar, child: Text(t.generate)),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TranslationsArea(
                future: translationFuture,
                targetLang: targetLang,
                startListening: _startListening,
                stopListening: _stopListening,
                speechEnabled: _speechEnabled,
                speechListening: _speechToText.isListening,
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
}

class TranslationsArea extends StatelessWidget {
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            PopUp.showPopUp(context, t.error, t.error_translation(snap.error!));
          });
          return SingleChildScrollView(
            child: _tileRich(
              context,
              t.error,
              const SizedBox.shrink(),
              color: Colors.red.shade50,
              errorText: '${snap.error}',
              copyText: '${snap.error}',
            ),
          );
        }

        if (!snap.hasData) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: _tileRich(
              context,
              '',
              const SizedBox.shrink(),
              copyText: '',
            ),
          );
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
    return _tileRich(
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
      buttons: rightButtons(
        t,
        () async {
          if(tts.getState() == true) {
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
    );
  }

  Widget translatedText(
    BuildContext context,
    AppLocalizations t,
    Translation item,
  ) {
    return _tileRich(
      context,
      t.repeat_this_phrase,
      TapWordText(
        text: item.translatedText,
        targetLang: item.detectedLanguage,
        sourceLang: item.target,
        ipaPerWord: item.translatedIpa,
        wordStyle: wordStyle,
        ipaStyle: ipaStyle,
      ),
      copyText: item.translatedText,
      buttons: rightButtons(
        t,
        () async {
          if(tts.getState() == true) {
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
    final idleText = (listeningText.isNotEmpty)
        ? '$listeningText'
              '${lastAccuracy == null ? '' : '\n\n${t.accuracy}: ${lastAccuracy!.toStringAsFixed(1)}%'}'
        : t.start;

    return _tileRich(
      context,
      t.detected_words,
      Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: !speechEnabled
              ? null
              : () async {
                  if (speechListening) {
                    await stopListening();
                  } else {
                    await startListening();
                  }
                },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),

            // Both states use a Column: text + icon
            child: speechListening
                ? Column(
                    key: const ValueKey('state_listening'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${t.listening}\n\n$listeningText',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.stop_rounded, size: 48),
                    ],
                  )
                : Column(
                    key: const ValueKey('state_idle'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(idleText, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Icon(Icons.mic, size: 48),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _tileRich(
    BuildContext context,
    String title,
    Widget body, {
    Color? color,
    String? errorText,
    VoidCallback? onTts,
    String? copyText,
    Widget? buttons,
  }) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final bool showDefaultActions =
        (onTts != null && copyText != null && buttons == null);
    final double rightReserve = (buttons != null || showDefaultActions)
        ? 50.0
        : 0.0;

    final Widget? rightSide =
        buttons ??
        (showDefaultActions
            ? Positioned(
                top: 0,
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
                        width: 40,
                        height: 40,
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
                        width: 40,
                        height: 40,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              )
            : null);

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
                padding: EdgeInsets.only(right: rightReserve, top: 5),
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
                padding: EdgeInsets.only(right: rightReserve),
                child: body,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText, style: TextStyle(color: Colors.red.shade700)),
              ],
            ],
          ),
          if (rightSide != null) rightSide,
        ],
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
}
