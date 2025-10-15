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
  String get error_tts => 'TTS の初期化エラー';

  @override
  String get error_ocr => 'OCR の処理エラー';

  @override
  String error_translation(Object log) {
    return '翻訳中にエラーが発生しました。エラーログ: $log';
  }

  @override
  String get main_hint => '何か入力するか「生成」を押してください…';

  @override
  String get start => '開始';

  @override
  String get stop => '停止';

  @override
  String get listen => 'リッスン';

  @override
  String get generate_translation => '翻訳を生成';

  @override
  String get translate => '翻訳';

  @override
  String get translation => '訳文';

  @override
  String get original => '原文';

  @override
  String get practice => '練習';

  @override
  String get dictionary => '辞書';

  @override
  String get no_words => '辞書に保存された単語はありません';

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

  @override
  String get generate => '生成';

  @override
  String get detected_words => '検出された単語：';

  @override
  String get tap_to_stop => 'タップして停止';

  @override
  String get repeat_this_phrase => '次のフレーズを復唱してください：';

  @override
  String error_function(Object fn, Object msg) {
    return '関数 $fn でエラーが発生しました。開発者に報告してください: $msg';
  }

  @override
  String get listening => '聴取中';

  @override
  String error_stt(Object msg) {
    return '音声認識の処理中にエラーが発生しました: $msg';
  }

  @override
  String get accuracy => '正確度';

  @override
  String get feature_not_available => '機能は利用できません';

  @override
  String get feature_not_available_windows => 'この機能は Windows では利用できません';

  @override
  String missing_language(Object lang) {
    return '言語の音声パックがありません：$lang';
  }

  @override
  String language_not_installed(Object lang) {
    return '$lang の音声パックがインストールされていません';
  }

  @override
  String get search => '検索…';

  @override
  String get delete => '削除';

  @override
  String get no_mic_input => 'マイク入力が検出されませんでした';

  @override
  String no_match(String lang) {
    return '$langで一致する単語が見つかりません';
  }

  @override
  String get not_allowed => 'マイクの許可がありません';

  @override
  String get unsupported_browser => 'サポートされていないブラウザです';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get system => 'システム';

  @override
  String get generate_for_practice => '練習を始めるためのフレーズを生成';

  @override
  String get frase => 'フレーズ';

  @override
  String get sujeto => '主語';

  @override
  String get verbo => '動詞';

  @override
  String get color => '色';

  @override
  String get familia => '家族';

  @override
  String get adjetivo => '形容詞';

  @override
  String get direccion => '経路';

  @override
  String get retraducir => '再翻訳';
}
