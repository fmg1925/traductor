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

  @override
  String get not_allowed => '마이크 권한이 없습니다';

  @override
  String get unsupported_browser => '지원되지 않는 브라우저';

  @override
  String get light => '라이트';

  @override
  String get dark => '다크';

  @override
  String get system => '시스템';

  @override
  String get generate_for_practice => '연습을 시작할 문구를 생성';

  @override
  String get frase => '구';

  @override
  String get sujeto => '주어';

  @override
  String get verbo => '동사';

  @override
  String get color => '색';

  @override
  String get familia => '가족';

  @override
  String get adjetivo => '형용사';

  @override
  String get direccion => '길찾기';

  @override
  String get retraducir => '다시 번역';

  @override
  String speechNotInstalled(Object lang) {
    return '$lang 음성 인식이 설치되어 있지 않습니다.';
  }

  @override
  String get theme => '테마';

  @override
  String get ipaPName => '무성 양순 파열음';

  @override
  String get ipaBName => '유성 양순 파열음';

  @override
  String get ipaTName => '무성 치조 파열음';

  @override
  String get ipaDName => '유성 치조 파열음';

  @override
  String get ipaKName => '무성 연구개 파열음';

  @override
  String get ipaGName => '유성 연구개 파열음';

  @override
  String get ipaTeshName => '무성 후치경 파찰음';

  @override
  String get ipaDezhName => '유성 후치경 파찰음';

  @override
  String get ipaFName => '무성 순치 마찰음';

  @override
  String get ipaVName => '유성 순치 마찰음';

  @override
  String get ipaThetaName => '무성 치간 마찰음';

  @override
  String get ipaEthName => '유성 치간 마찰음';

  @override
  String get ipaSName => '무성 치조 마찰음';

  @override
  String get ipaZName => '유성 치조 마찰음';

  @override
  String get ipaEshName => '무성 후치경 마찰음';

  @override
  String get ipaEzhName => '유성 후치경 마찰음';

  @override
  String get ipaHName => '무성 성문 마찰음';

  @override
  String get ipaMName => '양순 비음';

  @override
  String get ipaNName => '치조 비음';

  @override
  String get ipaEngName => '연구개 비음';

  @override
  String get ipaLName => '치조 설측 접근음';

  @override
  String get ipaTurnRName => '치조 접근음';

  @override
  String get ipaJName => '경구개 접근음';

  @override
  String get ipaWName => '양순-연구개 접근음';

  @override
  String get ipaIName => '전설 고모음 비원순';

  @override
  String get ipaSmallCapitalIName => '전설 근고모음 비원순';

  @override
  String get ipaEName => '전설 중고모음 비원순';

  @override
  String get ipaEpsilonName => '전설 중저모음 비원순';

  @override
  String get ipaAshName => '전설 근저모음 비원순';

  @override
  String get ipaScriptAName => '후설 저모음 비원순';

  @override
  String get ipaOpenOName => '후설 중저모음 원순';

  @override
  String get ipaOuDiphthongName => '이중모음';

  @override
  String get ipaUName => '후설 고모음 원순';

  @override
  String get ipaUpsilonName => '후설 근고모음 원순';

  @override
  String get ipaTurnedVName => '후설 중저모음 비원순';

  @override
  String get ipaSchwaName => '중설 중모음 (슈와)';

  @override
  String get ipaAiDiphthongName => '이중모음';

  @override
  String get ipaAuDiphthongName => '이중모음';

  @override
  String get ipaOpenOiDiphthongName => '이중모음';

  @override
  String get network_error => '네트워크 오류입니다. 연결을 확인하세요.';

  @override
  String get timeout => '요청 시간이 초과되었습니다.';

  @override
  String get ssl_error => '보안 연결(SSL)에 실패했습니다.';

  @override
  String get canceled => '요청이 취소되었습니다.';

  @override
  String get bad_request => '잘못된 요청입니다.';

  @override
  String get unauthorized => '인증되지 않았습니다. 로그인해 주세요.';

  @override
  String get forbidden => '접근이 거부되었습니다.';

  @override
  String get not_found => '서버 오프라인 / 리소스를 찾을 수 없음.';

  @override
  String get method_not_allowed => '허용되지 않은 메서드입니다.';

  @override
  String get conflict => '충돌이 발생했습니다.';

  @override
  String get unprocessable_entity => '처리할 수 없는 엔티티입니다.';

  @override
  String get too_many_requests => '요청이 너무 많습니다. 나중에 다시 시도하세요.';

  @override
  String get server_error => '서버 내부 오류입니다.';

  @override
  String get bad_gateway => '게이트웨이 오류입니다.';

  @override
  String get service_unavailable => '서비스를 사용할 수 없습니다.';

  @override
  String get gateway_timeout => '게이트웨이 시간 초과입니다.';

  @override
  String get unknown_error => '예기치 못한 오류입니다.';

  @override
  String get no_text_in_ocr => 'OCR에서 텍스트를 감지하지 못했습니다.';
}
