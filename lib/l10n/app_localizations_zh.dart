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

  @override
  String get no_mic_input => '未检测到麦克风输入';

  @override
  String no_match(String lang) {
    return '没有与$lang语言匹配的词语';
  }

  @override
  String get not_allowed => '没有麦克风权限';

  @override
  String get unsupported_browser => '不支持的浏览器';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get system => '系统';

  @override
  String get generate_for_practice => '生成一个用于开始练习的短语';

  @override
  String get frase => '短语';

  @override
  String get sujeto => '主语';

  @override
  String get verbo => '动词';

  @override
  String get color => '颜色';

  @override
  String get familia => '家庭';

  @override
  String get adjetivo => '形容词';

  @override
  String get direccion => '路线';

  @override
  String get retraducir => '重新翻译';

  @override
  String speechNotInstalled(Object lang) {
    return '未安装 $lang 语音识别功能。';
  }

  @override
  String get theme => '主题';

  @override
  String get ipaPName => '清双唇塞音';

  @override
  String get ipaBName => '浊双唇塞音';

  @override
  String get ipaTName => '清齿龈塞音';

  @override
  String get ipaDName => '浊齿龈塞音';

  @override
  String get ipaKName => '清软腭塞音';

  @override
  String get ipaGName => '浊软腭塞音';

  @override
  String get ipaTeshName => '清后齿龈塞擦音';

  @override
  String get ipaDezhName => '浊后齿龈塞擦音';

  @override
  String get ipaFName => '清唇齿擦音';

  @override
  String get ipaVName => '浊唇齿擦音';

  @override
  String get ipaThetaName => '清齿擦音';

  @override
  String get ipaEthName => '浊齿擦音';

  @override
  String get ipaSName => '清齿龈擦音';

  @override
  String get ipaZName => '浊齿龈擦音';

  @override
  String get ipaEshName => '清后齿龈擦音';

  @override
  String get ipaEzhName => '浊后齿龈擦音';

  @override
  String get ipaHName => '清声门擦音';

  @override
  String get ipaMName => '双唇鼻音';

  @override
  String get ipaNName => '齿龈鼻音';

  @override
  String get ipaEngName => '软腭鼻音';

  @override
  String get ipaLName => '齿龈边近音';

  @override
  String get ipaTurnRName => '齿龈近音';

  @override
  String get ipaJName => '硬腭近音';

  @override
  String get ipaWName => '双唇软腭近音';

  @override
  String get ipaIName => '前高不圆唇元音';

  @override
  String get ipaSmallCapitalIName => '近前近高不圆唇元音';

  @override
  String get ipaEName => '前次闭不圆唇元音';

  @override
  String get ipaEpsilonName => '前次开不圆唇元音';

  @override
  String get ipaAshName => '近前近低不圆唇元音';

  @override
  String get ipaScriptAName => '后低不圆唇元音';

  @override
  String get ipaOpenOName => '后次开圆唇元音';

  @override
  String get ipaOuDiphthongName => '双元音';

  @override
  String get ipaUName => '后高圆唇元音';

  @override
  String get ipaUpsilonName => '近后近高圆唇元音';

  @override
  String get ipaTurnedVName => '后次开不圆唇元音';

  @override
  String get ipaSchwaName => '中元音（央中元音，舒化）';

  @override
  String get ipaAiDiphthongName => '双元音';

  @override
  String get ipaAuDiphthongName => '双元音';

  @override
  String get ipaOpenOiDiphthongName => '双元音';
}
