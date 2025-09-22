import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../helpers/word_cache.dart';

class TapWordText extends StatefulWidget {
  final String text;
  final String targetLang;
  final String sourceLang;
  final bool inverse;
  final TextStyle? style;

  const TapWordText({
    super.key,
    required this.text,
    required this.targetLang,
    required this.sourceLang,
    this.inverse = false,
    this.style,
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

  List<String> _tokenize(String input) {
    final runes = input.runes.toList();
    final tokens = <String>[];
    if (runes.isEmpty) return tokens;

    final sb = StringBuffer();
    bool inWord = _isLetter(runes.first);

    for (final r in runes) {
      final isWordChar = _isLetter(r);
      if (isWordChar == inWord) {
        sb.write(String.fromCharCode(r));
      } else {
        tokens.add(sb.toString());
        sb.clear();
        sb.write(String.fromCharCode(r));
        inWord = isWordChar;
      }
    }
    if (sb.isNotEmpty) tokens.add(sb.toString());
    return tokens;
  }

  bool translating = false;

  Future<void> _onTapWord(String token) async {
    if(translating) return;
    final trim = token.trim();
    if (trim.isEmpty) return;

    final effectiveTarget = widget.inverse ? widget.sourceLang : widget.targetLang;

    final result = await WordCache.get(trim, effectiveTarget);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('“$trim” → $effectiveTarget'),
        content: Text((result == null || result.isEmpty) ? '—' : result),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _tokenize(widget.text);
    final defaultStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final spans = <TextSpan>[];

    for (final tk in tokens) {
      final isWord = tk.runes.isNotEmpty && _isLetter(tk.runes.first);
      if (isWord) {
        final rec = TapGestureRecognizer()..onTap = () => _onTapWord(tk);
        _recognizers.add(rec);
        spans.add(TextSpan(
          text: tk,
          style: defaultStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          recognizer: rec,
        ));
      } else {
        spans.add(TextSpan(text: tk, style: defaultStyle));
      }
    }

    return RichText(
      text: TextSpan(style: defaultStyle, children: spans),
      softWrap: true,
      textAlign: TextAlign.start,
    );
  }
}
