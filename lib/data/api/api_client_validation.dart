import 'package:liuban/core/network/api_exception.dart';

/// 客戶端送出 HTTP 前之輸入長度檢查（與 [LiubanInputLimits] 對齊）。
void assertTextWithinLimit({
  required String text,
  required int maxLength,
  required String message,
  required String code,
}) {
  if (text.length > maxLength) {
    throw LiubanApiException(message: message, code: code);
  }
}
