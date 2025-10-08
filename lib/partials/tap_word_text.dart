import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../helpers/word_cache.dart';

class TapWordText extends StatefulWidget {
  final String text;
  final String targetLang;
  final String sourceLang;

  final List<String>? ipaPerWord;

  final String originalIpa;
  final String translatedIpa;

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
    this.ipaPerWord,
    this.originalIpa = '',
    this.translatedIpa = '',
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
  final Map<String, String> _cache = {};
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant TapWordText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetLang != widget.targetLang ||
        oldWidget.inverse != widget.inverse ||
        oldWidget.sourceLang != widget.sourceLang) {
      _cache.clear();
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

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

  bool translating = false;

  Future<void> _onTapWord(String token) async {
    if (translating) return;
    final trim = token.trim();
    if (trim.isEmpty) return;

    final effectiveTarget = widget.inverse
        ? widget.sourceLang
        : widget.targetLang;

    final effectiveOrigin = widget.inverse
        ? widget.targetLang
        : widget.sourceLang;

    try {
      translating = true;
      final result = await WordCache.get(
        trim,
        effectiveOrigin,
        effectiveTarget,
      );
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            '“$trim” → $effectiveTarget',
            style: TextStyle(color: scheme.onPrimary),
          ),
          content: Text(
            (result == null || result.isEmpty) ? '—' : result,
            style: TextStyle(color: scheme.onPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: scheme.secondary)),
            ),
          ],
        ),
      );
      translating = false;
    } catch (e) {
      if (!mounted) return;
      translating = false;
      throw Exception("Error traduciendo palabra $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final (tokens, wordTokenIndexes) = _tokenize(widget.text);

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
    int wordCounter = 0;

    final children = <Widget>[];
    for (int i = 0; i < tokens.length; i++) {
      final tk = tokens[i];
      final isWordToken = wordTokenIndexes.contains(i);

      if (isWordToken) {
        final ipaForThisWord = (wordCounter < ipa.length)
            ? ipa[wordCounter]
            : '';
        wordCounter++;

        final rec = TapGestureRecognizer()..onTap = () => _onTapWord(tk);
        _recognizers.add(rec);

        final column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tk, style: wordStyle, textAlign: TextAlign.center),
            SizedBox(height: widget.gap),
            if (ipaForThisWord.isNotEmpty)
              Text(
                ipaForThisWord,
                style: ipaStyle,
                textAlign: TextAlign.center,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
          ],
        );

        children.add(
          IntrinsicWidth(
            child: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _onTapWord(tk),
                  behavior: HitTestBehavior.opaque,
                  child: column,
                ),
              ),
            ),
          ),
        );
      } else {
        if (tk.trim().isEmpty) {
          children.add(const SizedBox(width: 6));
        } else {
          children.add(Text(tk, style: defaultStyle));
        }
      }
    }

    return Wrap(
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: widget.hSpacing,
      runSpacing: widget.vSpacing,
      children: children,
    );
  }
}
