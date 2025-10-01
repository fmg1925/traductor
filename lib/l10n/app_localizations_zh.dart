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
  String get error_translation => '翻译时发生错误';

  @override
  String get main_hint => '输入内容或点击 \"生成\"...';

  @override
  String get start => '开始';

  @override
  String get stop => '停止';

  @override
  String get listen => '聆听';

  @override
  String get generate_translation => '生成翻译';

  @override
  String get translate => '翻译';

  @override
  String get translation => '翻译';

  @override
  String get original => '原文';

  @override
  String get practice => '练习';

  @override
  String get dictionary => '词典';

  @override
  String get no_words => '词典中没有保存任何单词';

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
}
