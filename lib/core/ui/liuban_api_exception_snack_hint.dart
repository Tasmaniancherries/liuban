import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';

/// 依 [LiubanApiException.code] 選擇 SnackBar 無障礙 hint；客戶端長度防禦時優先 [clientTooLongHint]。
String liubanApiExceptionSnackHint(
  LiubanApiException e, {
  required String defaultHint,
  String? clientTooLongHint,
}) {
  switch (e.code) {
    case LiubanInputLimits.inputTooLongCode:
    case LiubanInputLimits.messageTextTooLongCode:
    case LiubanInputLimits.reportReasonTooLongCode:
      return clientTooLongHint ??
          ApiDevSemantics.clientValidationTooLongSnackHint;
    default:
      return defaultHint;
  }
}
