import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/config/app_config.dart';

void main() {
  test('AppConfig compile-time defaults are sane', () {
    expect(AppConfig.apiBaseUrl, startsWith('https://'));
    expect(AppConfig.apiBaseUrl, isNotEmpty);
    expect(AppConfig.apiPrefix, startsWith('/'));
    expect(AppConfig.appVersion, isNotEmpty);
    expect(AppConfig.shareLinkOrigin, startsWith('https://'));
  });
}
