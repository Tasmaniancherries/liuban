import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/locale/app_locale_controller.dart';
import 'package:liuban/core/locale/app_locale_preference.dart';

void main() {
  test('AppLocaleController without persistence updates preference', () async {
    final c = AppLocaleController();
    expect(c.preference, AppLocalePreference.system);
    expect(c.resolvedLocale, isNull);
    var notifications = 0;
    c.addListener(() => notifications++);
    await c.setPreference(AppLocalePreference.zhHK);
    expect(c.preference, AppLocalePreference.zhHK);
    expect(c.resolvedLocale, isNotNull);
    expect(notifications, 1);
    await c.setPreference(AppLocalePreference.zhHK);
    expect(notifications, 1);
    await c.setPreference(AppLocalePreference.system);
    expect(c.resolvedLocale, isNull);
    expect(notifications, 2);
  });
}
