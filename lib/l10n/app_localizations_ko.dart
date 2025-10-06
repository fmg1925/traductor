// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get error => '오류';

  @override
  String get error_tts => 'TTS 초기화 오류';

  @override
  String get error_ocr => 'OCR 처리 오류';

  @override
  String error_translation(Object log) {
    return '번역 중 오류가 발생했습니다. 오류 로그: $log';
  }

  @override
  String get main_hint => '무엇인가 입력하거나 \"생성\"을 누르세요...';

  @override
  String get start => '시작';

  @override
  String get stop => '정지';

  @override
  String get listen => '듣기';

  @override
  String get generate_translation => '번역 생성';

  @override
  String get translate => '번역';

  @override
  String get translation => '번역문';

  @override
  String get original => '원문';

  @override
  String get practice => '연습';

  @override
  String get dictionary => '사전';

  @override
  String get no_words => '사전에 저장된 단어가 없습니다';

  @override
  String get auto => '자동 감지';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사됨';

  @override
  String get en => '영어';

  @override
  String get es => '스페인어';

  @override
  String get zh => '중국어';

  @override
  String get ja => '일본어';

  @override
  String get ko => '한국어';

  @override
  String get generate => '생성';

  @override
  String get detected_words => '감지된 단어:';

  @override
  String get tap_to_stop => '탭하여 정지';

  @override
  String get repeat_this_phrase => '다음 문장을 따라 말하세요:';

  @override
  String error_function(Object fn, Object msg) {
    return '함수 $fn 에서 오류가 발생했습니다. 개발자에게 보고하세요: $msg';
  }

  @override
  String get listening => '청취 중';

  @override
  String error_stt(Object msg) {
    return '음성 인식(STT) 처리 중 오류: $msg';
  }

  @override
  String get accuracy => '정확도';

  @override
  String get feature_not_available => '기능을 사용할 수 없습니다';

  @override
  String get feature_not_available_windows => '이 기능은 Windows에서 사용할 수 없습니다';

  @override
  String missing_language(Object lang) {
    return '언어 음성 팩이 없습니다: $lang';
  }

  @override
  String language_not_installed(Object lang) {
    return '$lang 언어 음성 팩이 설치되지 않았습니다';
  }

  @override
  String get search => '검색…';

  @override
  String get delete => '삭제';

  @override
  String get no_mic_input => '마이크 입력이 감지되지 않았습니다';

  @override
  String no_match(String lang) {
    return '$lang 언어에서 일치하는 단어가 없습니다';
  }
}
