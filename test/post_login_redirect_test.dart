import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/navigation/post_login_redirect.dart';

void main() {
  test('allows in-app paths', () {
    expect(sanitizePostLoginRedirect('/dm/u1?custom=a'), '/dm/u1?custom=a');
    expect(sanitizePostLoginRedirect('%2Fpost%2Fx'), '/post/x');
  });

  test('rejects dangerous or external targets', () {
    expect(sanitizePostLoginRedirect(null), isNull);
    expect(sanitizePostLoginRedirect(''), isNull);
    expect(sanitizePostLoginRedirect('https://evil/phish'), isNull);
    expect(sanitizePostLoginRedirect('//evil.com'), isNull);
    expect(sanitizePostLoginRedirect('/login'), isNull);
    expect(sanitizePostLoginRedirect('/login?x=1'), isNull);
    expect(sanitizePostLoginRedirect('relative'), isNull);
  });
}
