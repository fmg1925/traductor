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

  @override
  String speechNotInstalled(Object lang) {
    return '$lang の音声認識がインストールされていません。';
  }

  @override
  String get theme => 'テーマ';

  @override
  String get ipaPName => '無声両唇破裂音';

  @override
  String get ipaBName => '有声両唇破裂音';

  @override
  String get ipaTName => '無声歯茎破裂音';

  @override
  String get ipaDName => '有声歯茎破裂音';

  @override
  String get ipaKName => '無声軟口蓋破裂音';

  @override
  String get ipaGName => '有声軟口蓋破裂音';

  @override
  String get ipaTeshName => '無声後部歯茎破擦音';

  @override
  String get ipaDezhName => '有声後部歯茎破擦音';

  @override
  String get ipaFName => '無声唇歯摩擦音';

  @override
  String get ipaVName => '有声唇歯摩擦音';

  @override
  String get ipaThetaName => '無声歯摩擦音';

  @override
  String get ipaEthName => '有声歯摩擦音';

  @override
  String get ipaSName => '無声歯茎摩擦音';

  @override
  String get ipaZName => '有声歯茎摩擦音';

  @override
  String get ipaEshName => '無声後部歯茎摩擦音';

  @override
  String get ipaEzhName => '有声後部歯茎摩擦音';

  @override
  String get ipaHName => '無声音門摩擦音';

  @override
  String get ipaMName => '両唇鼻音';

  @override
  String get ipaNName => '歯茎鼻音';

  @override
  String get ipaEngName => '軟口蓋鼻音';

  @override
  String get ipaLName => '歯茎側面接近音';

  @override
  String get ipaTurnRName => '歯茎接近音';

  @override
  String get ipaJName => '硬口蓋接近音';

  @override
  String get ipaWName => '両唇軟口蓋接近音';

  @override
  String get ipaIName => '前舌狭母音（非円唇）';

  @override
  String get ipaSmallCapitalIName => '前舌ほぼ狭母音（非円唇）';

  @override
  String get ipaEName => '前舌半狭母音（非円唇）';

  @override
  String get ipaEpsilonName => '前舌半広母音（非円唇）';

  @override
  String get ipaAshName => '前舌ほぼ広母音（非円唇）';

  @override
  String get ipaScriptAName => '後舌広母音（非円唇）';

  @override
  String get ipaOpenOName => '後舌半広母音（円唇）';

  @override
  String get ipaOuDiphthongName => '二重母音';

  @override
  String get ipaUName => '後舌狭母音（円唇）';

  @override
  String get ipaUpsilonName => '後舌ほぼ狭母音（円唇）';

  @override
  String get ipaTurnedVName => '後舌半広母音（非円唇）';

  @override
  String get ipaSchwaName => '中舌中母音（シュワ）';

  @override
  String get ipaAiDiphthongName => '二重母音';

  @override
  String get ipaAuDiphthongName => '二重母音';

  @override
  String get ipaOpenOiDiphthongName => '二重母音';

  @override
  String get network_error => 'ネットワークエラーです。接続を確認してください。';

  @override
  String get timeout => 'リクエストがタイムアウトしました。';

  @override
  String get ssl_error => 'セキュア接続（SSL）に失敗しました。';

  @override
  String get canceled => 'リクエストはキャンセルされました。';

  @override
  String get bad_request => '不正なリクエストです。';

  @override
  String get unauthorized => '認証されていません。ログインしてください。';

  @override
  String get forbidden => 'アクセスが拒否されました。';

  @override
  String get not_found => 'サーバーオフライン／リソースが見つかりません。';

  @override
  String get method_not_allowed => '許可されていないメソッドです。';

  @override
  String get conflict => '競合が発生しました。';

  @override
  String get unprocessable_entity => '処理できないエンティティです。';

  @override
  String get too_many_requests => 'リクエストが多すぎます。後でもう一度お試しください。';

  @override
  String get server_error => 'サーバー内部エラーが発生しました。';

  @override
  String get bad_gateway => '不正なゲートウェイです。';

  @override
  String get service_unavailable => 'サービスを利用できません。';

  @override
  String get gateway_timeout => 'ゲートウェイのタイムアウトです。';

  @override
  String get unknown_error => '予期しないエラーです。';

  @override
  String get no_text_in_ocr => 'OCRで文字を検出できませんでした。';
}
