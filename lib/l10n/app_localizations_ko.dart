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
  String get error_tts => 'TTS 초기화 중 오류가 발생했습니다';

  @override
  String get error_ocr => 'OCR 처리 중 오류가 발생했습니다';

  @override
  String get error_translation => '번역 중 오류가 발생했습니다';

  @override
  String get main_hint => '텍스트를 입력하거나 \"생성\"을 누르세요...';

  @override
  String get start => '시작';

  @override
  String get stop => '중지';

  @override
  String get listen => '듣기';

  @override
  String get generate_translation => '번역 생성';

  @override
  String get translate => '번역';

  @override
  String get translation => '번역';

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
}
