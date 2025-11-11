import 'package:flutter/material.dart';
import '../helpers/word_cache.dart';

class TapWordText extends StatefulWidget {
  final String text;
  final String targetLang;
  final String sourceLang;

  final List<String>? romanizationPerWord;

  final List<String>? ipaPerWord;

  final bool showPerWordRomanization;

  final bool showPerWordIpa;

  final bool inverse;
  final TextStyle? wordStyle;
  final TextStyle? ipaStyle;

  final double gap;

  final double hSpacing;

  final double vSpacing;

  const TapWordText({
    super.key,
    required this.text,
    required this.targetLang,
    required this.sourceLang,
    this.romanizationPerWord,
    this.ipaPerWord,
    this.showPerWordRomanization = true,
    this.showPerWordIpa = true,
    this.inverse = false,
    this.wordStyle,
    this.ipaStyle,
    this.gap = 2,
    this.hSpacing = 10,
    this.vSpacing = 6,
  });

  @override
  State<TapWordText> createState() => _TapWordTextState();
}

class _TapWordTextState extends State<TapWordText> {
  bool translating = false;

  int? _loadingWordIndex;

  bool _isLetter(int rune) {
    return (rune >= 0x0041 && rune <= 0x024F) ||
        (rune >= 0x3040 && rune <= 0x30FF) ||
        (rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0xAC00 && rune <= 0xD7AF);
  }

  (List<String> tokens, List<int> wordTokenIndexes) _tokenize(String input) {
    final runes = input.runes.toList();
    final tokens = <String>[];
    final wordIdxs = <int>[];
    if (runes.isEmpty) return (tokens, wordIdxs);
    final sb = StringBuffer();
    bool inWord = _isLetter(runes.first);

    void flush(bool wasWord) {
      if (sb.isEmpty) return;
      tokens.add(sb.toString());
      if (wasWord) wordIdxs.add(tokens.length - 1);
      sb.clear();
    }

    for (final r in runes) {
      final isWordChar = _isLetter(r);
      if (isWordChar == inWord) {
        sb.writeCharCode(r);
      } else {
        flush(inWord);
        sb.writeCharCode(r);
        inWord = isWordChar;
      }
    }
    flush(inWord);
    return (tokens, wordIdxs);
  }

  Future<void> _onTapWord(String token, int wordIndex) async {
  if (_loadingWordIndex != null) return;
  final trim = token.trim();
  if (trim.isEmpty) return;

  final effectiveTarget = widget.inverse ? widget.sourceLang : widget.targetLang;
  final effectiveOrigin = widget.inverse ? widget.targetLang : widget.sourceLang;

  setState(() => _loadingWordIndex = wordIndex);
  try {
    final result = await WordCache.get(trim, effectiveOrigin, effectiveTarget);
    if (!mounted) return;

    final scheme = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (_) {
        String? localResult = result;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('“$trim” → $effectiveTarget', style: TextStyle(color: scheme.onPrimary)),
            content: Text(localResult!.isEmpty ? '—' : localResult, style: TextStyle(color: scheme.onPrimary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: scheme.secondary)),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    if (mounted) setState(() => _loadingWordIndex = null);
  }
}

  @override
  Widget build(BuildContext context) {
    final (tokens, wordTokenIndexes) = _tokenize(widget.text);
    final scheme = Theme.of(context).colorScheme; 
    final defaultStyle = DefaultTextStyle.of(context).style;
    final wordStyle =
        widget.wordStyle ??
        defaultStyle.copyWith(
          fontSize: 16,
          height: 1.15,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        );
    final ipaStyle =
        widget.ipaStyle ??
        defaultStyle.copyWith(
          fontSize: 13,
          height: 1.15,
          color: const Color(0xFF424242),
        );

    final ipa = widget.ipaPerWord ?? const <String>[];
    final rom = widget.romanizationPerWord ?? const <String>[];

    int wordCounter = 0;
final wordIndexSet = wordTokenIndexes.toSet();
final wordBlocks = <Widget>[];

for (int i = 0; i < tokens.length; i++) {
  final tk = tokens[i];
  final isWordToken = wordIndexSet.contains(i);

  if (isWordToken) {
    final myWordIndex = wordCounter;
    final ipaForThisWord = (widget.showPerWordIpa && wordCounter < ipa.length) ? ipa[wordCounter] : '';
    final romForThisWord = (widget.showPerWordRomanization && wordCounter < rom.length) ? rom[wordCounter] : '';
    wordCounter++;

    final baseColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tk, style: wordStyle, textAlign: TextAlign.center),
        if (romForThisWord.isNotEmpty) ...[
          SizedBox(height: widget.gap),
          Text(romForThisWord, style: ipaStyle, textAlign: TextAlign.center, softWrap: false, maxLines: 1),
        ],
        if (ipaForThisWord.isNotEmpty) ...[
          SizedBox(height: widget.gap),
          Text(ipaForThisWord, style: ipaStyle, textAlign: TextAlign.center, softWrap: false, maxLines: 1),
        ],
      ],
    );

    wordBlocks.add(
        Align(
          widthFactor: 1,
          heightFactor: 1,
          alignment: Alignment.topLeft,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _onTapWord(tk, myWordIndex),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  baseColumn,
                  if (_loadingWordIndex == myWordIndex)
                    Positioned(
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.secondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  } else {
    if (tk.trim().isEmpty) {
      wordBlocks.add(const SizedBox(width: 6));
    } else {
      wordBlocks.add(Text(tk, style: wordStyle, textAlign: TextAlign.start, softWrap: true, overflow: TextOverflow.clip, textWidthBasis: TextWidthBasis.parent,));
    }
  }
}

    final wrap = Wrap(
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: widget.hSpacing,
      runSpacing: widget.vSpacing,
      children: wordBlocks,
    );

    return wrap;
  }
}
