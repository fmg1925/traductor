import 'package:flutter/material.dart';
import 'package:traductor/l10n/app_localizations.dart';
import 'package:traductor/main.dart' show ttsLocaleFor;
import 'package:traductor/pages/home.dart' show tts;

class IpaGrid extends StatefulWidget {
  const IpaGrid({super.key});
  @override
  State<IpaGrid> createState() => _IpaGridState();
}

class _IpaGridState extends State<IpaGrid> {
  static const _symbols = <String>[
    "p","b","t","d","k","g",
    "tʃ","dʒ",
    "f","v","θ","ð","s","z","ʃ","ʒ","h",
    "m","n","ŋ",
    "l","ɹ","j","w",
    "i","ɪ","e","ɛ","æ","ɑ","ɔ","oʊ","u","ʊ","ʌ","ə","aɪ","aʊ","ɔɪ",
  ];

  static const _examplesEn = <String, String>{
    "p":"pin","b":"bat","t":"tea","d":"do","k":"cat","g":"go",
    "tʃ":"chip","dʒ":"jam",
    "f":"fan","v":"van","θ":"thin","ð":"this","s":"sip","z":"zoo","ʃ":"ship","ʒ":"vision","h":"hat",
    "m":"man","n":"no","ŋ":"sing",
    "l":"let","ɹ":"ray","j":"yes","w":"we",
    "i":"beet","ɪ":"bit","e":"café","ɛ":"bet","æ":"bat","ɑ":"spa","ɔ":"thought","oʊ":"go","u":"boot","ʊ":"book","ʌ":"strut","ə":"sofa","aɪ":"my","aʊ":"now","ɔɪ":"boy",
  };

  static const _exampleHighlight = <String, String>{
    "p":"p","b":"b","t":"t","d":"d","k":"c","g":"g",
    "tʃ":"ch","dʒ":"j",
    "f":"f","v":"v","θ":"th","ð":"th","s":"s","z":"z","ʃ":"sh","ʒ":"si","h":"h",
    "m":"m","n":"n","ŋ":"ng",
    "l":"l","ɹ":"r","j":"y","w":"w",
    "i":"ee","ɪ":"i","e":"é","ɛ":"e","æ":"a","ɑ":"a","ɔ":"ough","oʊ":"o","u":"oo","ʊ":"oo","ʌ":"u","ə":"a","aɪ":"y","aʊ":"ow","ɔɪ":"oy",
  };

  String _nameFor(AppLocalizations t, String s) {
    switch (s) {
      case "p": return t.ipaPName;
      case "b": return t.ipaBName;
      case "t": return t.ipaTName;
      case "d": return t.ipaDName;
      case "k": return t.ipaKName;
      case "g": return t.ipaGName;
      case "tʃ": return t.ipaTeshName;
      case "dʒ": return t.ipaDezhName;
      case "f": return t.ipaFName;
      case "v": return t.ipaVName;
      case "θ": return t.ipaThetaName;
      case "ð": return t.ipaEthName;
      case "s": return t.ipaSName;
      case "z": return t.ipaZName;
      case "ʃ": return t.ipaEshName;
      case "ʒ": return t.ipaEzhName;
      case "h": return t.ipaHName;
      case "m": return t.ipaMName;
      case "n": return t.ipaNName;
      case "ŋ": return t.ipaEngName;
      case "l": return t.ipaLName;
      case "ɹ": return t.ipaTurnRName;
      case "j": return t.ipaJName;
      case "w": return t.ipaWName;
      case "i": return t.ipaIName;
      case "ɪ": return t.ipaSmallCapitalIName;
      case "e": return t.ipaEName;
      case "ɛ": return t.ipaEpsilonName;
      case "æ": return t.ipaAshName;
      case "ɑ": return t.ipaScriptAName;
      case "ɔ": return t.ipaOpenOName;
      case "oʊ": return t.ipaOuDiphthongName;
      case "u": return t.ipaUName;
      case "ʊ": return t.ipaUpsilonName;
      case "ʌ": return t.ipaTurnedVName;
      case "ə": return t.ipaSchwaName;
      case "aɪ": return t.ipaAiDiphthongName;
      case "aʊ": return t.ipaAuDiphthongName;
      case "ɔɪ": return t.ipaOpenOiDiphthongName;
    }
    return s;
  }

  Widget _highlightedExample(String sym, String word, TextStyle base, TextStyle bold) {
    final h = _exampleHighlight[sym];
    if (h == null || h.isEmpty) return Text(word, textAlign: TextAlign.center, style: base);
    final lw = word.toLowerCase();
    final lh = h.toLowerCase();
    final idx = lw.indexOf(lh);
    if (idx < 0) return Text(word, textAlign: TextAlign.center, style: base);
    final pre = word.substring(0, idx);
    final mid = word.substring(idx, idx + h.length);
    final post = word.substring(idx + h.length);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: pre),
          TextSpan(text: mid.toUpperCase(), style: bold),
          TextSpan(text: post),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    const targetTileWidth = 180.0;
    final crossAxisCount = (width / targetTileWidth).floor().clamp(2, 6);

    final spacing = (width * 0.02).clamp(6.0, 16.0);

    final childAspectRatio = 0.9;

    return Scaffold(
      appBar: AppBar(
        title: Text('IPA', style: TextStyle(color: scheme.onPrimary)),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: _symbols.length,
        itemBuilder: (context, i) {
          final sym = _symbols[i];
          final name = _nameFor(t, sym);
          final example = _examplesEn[sym] ?? sym;

          return InkWell(
            onTap: () async {
              await tts.changeLanguage(ttsLocaleFor('en'));
              await tts.speak(example); },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: ValueListenableBuilder(
                        valueListenable: tts.speaking,
                        builder: (context, isSpeaking, _) {
                          return Icon(isSpeaking ? Icons.stop : Icons.volume_up, size: 20, color: scheme.secondary);
                        }
                      ),
                    ),
                    Text(
                      sym,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        letterSpacing: 0.5, color: scheme.onPrimary
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: scheme.onPrimary),
                        ),
                        const SizedBox(height: 6),
                        _highlightedExample(
                          sym,
                          example,
                          TextStyle(color: scheme.onPrimary),
                          TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
