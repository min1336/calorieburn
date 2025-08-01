// lib/utils/custom_exceptions.dart

class LogMealException implements Exception {
  final String message;

  LogMealException(this.message);

  factory LogMealException.fromStatusCode(int statusCode, String context) {
    switch (statusCode) {
      case 401:
      case 403:
        return LogMealException('API 인증에 실패했습니다. API 토큰을 확인해주세요.');
      case 429:
        return LogMealException('API 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.');
      default:
        return LogMealException('API 오류가 발생했습니다. (코드: $statusCode, $context)');
    }
  }

  factory LogMealException.apiTokenMissing() {
    return LogMealException('.env 파일에 LOGMEAL_API_TOKEN이 설정되지 않았습니다.');
  }

  factory LogMealException.foodNotRecognized() {
    return LogMealException('사진에서 음식을 인식할 수 없습니다. 더 선명한 사진으로 다시 시도해주세요.');
  }

  factory LogMealException.nutritionInfoMissing() {
    return LogMealException('영양 정보를 가져올 수 없습니다. API 플랜의 한도 문제일 수 있습니다.');
  }

  factory LogMealException.networkError() {
    return LogMealException('네트워크 연결을 확인해주세요.');
  }

  factory LogMealException.unknownError(String error) {
    return LogMealException('알 수 없는 오류가 발생했습니다: $error');
  }

  @override
  String toString() => message;
}