// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get error => 'エラー';

  @override
  String get error_tts => 'TTS の初期化中にエラーが発生しました';

  @override
  String get error_ocr => 'OCR の処理中にエラーが発生しました';

  @override
  String get error_translation => '翻訳中にエラーが発生しました';

  @override
  String get main_hint => 'テキストを入力するか「生成」を押してください...';

  @override
  String get start => '開始';

  @override
  String get stop => '停止';

  @override
  String get listen => '聴く';

  @override
  String get generate_translation => '翻訳を生成';

  @override
  String get translate => '翻訳';

  @override
  String get translation => '翻訳';

  @override
  String get original => '原文';

  @override
  String get practice => '練習';

  @override
  String get dictionary => '辞書';

  @override
  String get no_words => '辞書に単語が保存されていません';

  @override
  String get auto => '自動検出';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get en => '英語';

  @override
  String get es => 'スペイン語';

  @override
  String get zh => '中国語';

  @override
  String get ja => '日本語';

  @override
  String get ko => '韓国語';
}
