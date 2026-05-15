import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';

void main() {
  test('report other detail fits within total reason budget', () {
    const prefix = 'other — ';
    expect(
      prefix.length + LiubanInputLimits.feedReportOtherDetailMaxLength,
      lessThanOrEqualTo(LiubanInputLimits.feedReportReasonMaxTotalLength),
    );
  });

  test('login and change password share password max length', () {
    expect(LiubanInputLimits.passwordMaxLength, 128);
    expect(LiubanInputLimits.loginAccountMaxLength, greaterThan(32));
  });

  test('registration custom id matches add-friend limit', () {
    expect(LiubanInputLimits.customIdMaxLength, 32);
  });
}
