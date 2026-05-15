import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_api_exception_snack_hint.dart';

void main() {
  test('uses default hint for server errors', () {
    final e = LiubanApiException(message: 'server', code: 'forbidden');
    expect(
      liubanApiExceptionSnackHint(e, defaultHint: 'default-hint'),
      'default-hint',
    );
  });

  test('uses clientTooLongHint for input_too_long', () {
    final e = LiubanApiException(
      message: 'too long',
      code: LiubanInputLimits.inputTooLongCode,
    );
    expect(
      liubanApiExceptionSnackHint(
        e,
        defaultHint: 'default-hint',
        clientTooLongHint: 'custom-too-long',
      ),
      'custom-too-long',
    );
  });

  test('falls back to generic client validation hint', () {
    final e = LiubanApiException(
      message: 'too long',
      code: LiubanInputLimits.messageTextTooLongCode,
    );
    expect(
      liubanApiExceptionSnackHint(e, defaultHint: 'default-hint'),
      ApiDevSemantics.clientValidationTooLongSnackHint,
    );
  });
}
