import 'package:flutter/material.dart';
import '../helpers/word_cache.dart';

class TapWordText extends StatefulWidget {
  final String text;
  final String targetLang;
  final String sourceLang;

  final List<String>? romanizationPerWord;
  final List<String>? ipaPerWord;

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

  @override
  void didUpdateWidget(covariant TapWordText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // nada que limpiar ya que no guardamos recognizers ni cache local
  }

  bool _isLetter(int rune) {
    return (rune >= 0x0041 && rune <= 0x024F) || // Latin + extendido
           (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana/Katakana
           (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK
           (rune >= 0xAC00 && rune <= 0xD7AF);   // Hangul
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

  Future<void> _onTapWord(String token) async {
    if (translating) return;
    final trim = token.trim();
    if (trim.isEmpty) return;

    final effectiveTarget = widget.inverse ? widget.sourceLang : widget.targetLang;
    final effectiveOrigin = widget.inverse ? widget.targetLang : widget.sourceLang;

    try {
      setState(() => translating = true);
      final result = await WordCache.get(trim, effectiveOrigin, effectiveTarget);
      if (!mounted) return;

      final scheme = Theme.of(context).colorScheme;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('“$trim” → $effectiveTarget', style: TextStyle(color: scheme.onSurface)),
          content: Text(
            (result == null || result.isEmpty) ? '—' : result,
            style: TextStyle(color: scheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: scheme.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error traduciendo palabra')),
      );
    } finally {
      if (mounted) setState(() => translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (tokens, wordTokenIndexes) = _tokenize(widget.text);

    final base = DefaultTextStyle.of(context).style;
    final scheme = Theme.of(context).colorScheme;

    final wordStyle = widget.wordStyle ??
        base.copyWith(
          fontSize: 16,
          height: 1.15,
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        );

    final ipaStyle = widget.ipaStyle ??
        base.copyWith(
          fontSize: 13,
          height: 1.15,
          color: scheme.onSurfaceVariant,
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
        final ipaForThisWord = (wordCounter < ipa.length) ? ipa[wordCounter] : '';
        final romForThisWord = (wordCounter < rom.length) ? rom[wordCounter] : '';
        wordCounter++;

        final column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tk, style: wordStyle, textAlign: TextAlign.center),
            if (romForThisWord.isNotEmpty) ...[
              SizedBox(height: widget.gap),
              Text(
                romForThisWord,
                style: ipaStyle,
                textAlign: TextAlign.center,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ],
            if (ipaForThisWord.isNotEmpty) ...[
              SizedBox(height: widget.gap),
              Text(
                ipaForThisWord,
                style: ipaStyle,
                textAlign: TextAlign.center,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ],
          ],
        );

        wordBlocks.add(
          IntrinsicWidth(
            child: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _onTapWord(tk),
                  behavior: HitTestBehavior.opaque,
                  child: Tooltip(message: tk, child: column),
                ),
              ),
            ),
          ),
        );
      } else {
        // espacio visual para grupos de espacios
        if (tk.trim().isEmpty) {
          wordBlocks.add(const SizedBox(width: 6));
        } else {
          wordBlocks.add(Text(tk, style: base));
        }
      }
    }

    return Wrap(
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: widget.hSpacing,
      runSpacing: widget.vSpacing,
      children: wordBlocks,
    );
  }
}
