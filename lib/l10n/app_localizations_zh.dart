// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get error => '错误';

  @override
  String get error_tts => '初始化 TTS 时出错';

  @override
  String get error_ocr => '处理 OCR 时出错';

  @override
  String error_translation(Object log) {
    return '翻译时发生错误，错误日志：$log';
  }

  @override
  String get main_hint => '写点内容或点击“生成”……';

  @override
  String get start => '开始';

  @override
  String get stop => '停止';

  @override
  String get listen => '收听';

  @override
  String get generate_translation => '生成翻译';

  @override
  String get translate => '翻译';

  @override
  String get translation => '译文';

  @override
  String get original => '原文';

  @override
  String get practice => '练习';

  @override
  String get dictionary => '词典';

  @override
  String get no_words => '词典中没有保存的单词';

  @override
  String get auto => '自动检测';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get en => '英语';

  @override
  String get es => '西班牙语';

  @override
  String get zh => '中文';

  @override
  String get ja => '日语';

  @override
  String get ko => '韩语';

  @override
  String get generate => '生成';

  @override
  String get detected_words => '识别到的单词：';

  @override
  String get tap_to_stop => '点击停止';

  @override
  String get repeat_this_phrase => '请复述这句话：';

  @override
  String error_function(Object fn, Object msg) {
    return '函数 $fn 出错，请向开发者反馈：$msg';
  }

  @override
  String get listening => '正在聆听';

  @override
  String error_stt(Object msg) {
    return '处理语音转文字时出错：$msg';
  }

  @override
  String get accuracy => '准确率';

  @override
  String get feature_not_available => '功能不可用';

  @override
  String get feature_not_available_windows => '此功能在 Windows 上不可用';

  @override
  String missing_language(Object lang) {
    return '缺少语言语音包：$lang';
  }

  @override
  String language_not_installed(Object lang) {
    return '你尚未安装 $lang 的语音包';
  }

  @override
  String get search => '搜索…';

  @override
  String get delete => '删除';
}
